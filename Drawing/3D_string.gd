extends MeshInstance3D
class_name MeshInstanceString

const TRANSPARENCY_TRANSSITION_SPEED = 1.0

var points : Array = [Vector3.ZERO, Vector3.ZERO]

const TARGET_SPEED = 3.0
var goal = Vector3.ZERO
var goal_target = Vector3.ZERO

@export var experimental_physics : bool = false
@export var goal_relitive = Vector3.ONE*6
@export var track_to : Node3D 
@export var max_angle_degrees = 30.0
@export var distance : float = 10.0
@export var division_length := 0.1
@export var gravity_effect = -0.2
@export var goal_effect = 0.3

@export var grav_modifier_curve : Curve
@export var grav_modifier_effect : float = 0.1

func _ready():
	var count = round(distance / division_length)
	for i in range(count):
		points.append(Vector3(0.0, 0.0, i * division_length))
	
	

func _process(delta: float):
	get_active_material(0).albedo_color.a = lerp(get_active_material(0).albedo_color.a, float(Global.player.is_chirping), delta * TRANSPARENCY_TRANSSITION_SPEED)



func _physics_process(delta: float):
	goal = goal.lerp(goal_relitive, delta * TARGET_SPEED)
	
	mesh.clear_surfaces()
	mesh.surface_begin(Mesh.PRIMITIVE_LINE_STRIP)
	#var base = Global.player.position + Global.player.get_node("trail").position.rotated(Vector3.UP, Global.player.position)
	var base = to_local(Global.player.get_node("trail").global_position)
	points[0] = base
	
	
	for i in range(1, points.size()):
		var prev_point = points[i]
		points[i] = points[i-1] + (
			(points[i-1].direction_to(points[i]) + (
				Vector3(0.0, gravity_effect + grav_modifier_effect * (grav_modifier_curve.sample(float(i) / float(points.size()))), 0.0)
			) + (
				points[i-1].direction_to(track_to.position + goal) * goal_effect 
			)
			).normalized() * division_length)
		if i != 1:
			var vec1 : Vector3 = points[i-2] - points[i-1]
			var vec2 : Vector3 = points[i-1] - points[i]
			var difference = (vec1).angle_to(vec2) - deg_to_rad(max_angle_degrees)
			if difference > 0.0: 
				points[i] = (points[i] - points[i-1]).rotated(vec1.cross(vec2).normalized(), -difference) + points[i-1]
		
		if experimental_physics:
			var pp = PhysicsRayQueryParameters3D.new()
			pp.to = to_global(points[i])
			pp.from = to_global(points[i-1])
			#if player_RID:
				#pp.exclude = [player_RID]
			var collision = get_world_3d().direct_space_state.intersect_ray(pp)
			if collision:
				points[i] = prev_point
				points[i] = points[i-1] + points[i-1].direction_to(points[i]) * division_length
				
			draw_line(points[i-1], points[i])
	
	mesh.surface_end()

func draw_line(from_point : Vector3, to_point : Vector3):
	mesh.surface_add_vertex(from_point)
	mesh.surface_add_vertex(to_point)
	
