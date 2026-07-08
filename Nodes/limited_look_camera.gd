extends Camera3D
class_name LimitedLookCamera

@export var active : bool = true: 
	set(val):
		current = val
		active = val
		if val: 
			prev_mouse_moude = Input.mouse_mode
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED  
		else:
			Input.mouse_mode = prev_mouse_moude

@export_range(0.1, 40.0, 0.001) var ease_strength : float = 1.0
@export_range(0.1, 40.0, 0.001) var pull_strength : float = 1.0
@export_range(0.1, 3.0, 0.001) var pan_distance : float = 1.0
@export_range(0.1, 5.0, 0.001) var sensitivity : float = 1.0
const SENSITIVITY_MULT = 0.005

@export_category("Allowed Angles")
@export_range(0.0, 180.0, 0.001, "radians_as_degrees", "exp") var y_deadzone : float = 0.0
@export_range(0.0, 180.0, 0.001, "radians_as_degrees", "exp") var x_deadzone : float = 0.0
@export_range(0.001, 180.0, 0.001, "radians_as_degrees", "exp") var y_limit : float = 0.0
@export_range(0.001, 180.0, 0.001, "radians_as_degrees", "exp") var x_limit : float = 0.0

var start_angle : Vector3
var start_position : Vector3
var vertical : Vector3
var horizontal : Vector3

var targ_pos : Vector3
var targ_rot : Vector3
var look : Vector2
var limit_deadzone_ratio : Vector2
var prev_mouse_moude : Input.MouseMode

func _ready() -> void:
	start_angle = rotation
	start_position = position
	
	# basis? I hardly know sis
	var _basis : Basis = Basis.from_euler(start_angle)
	vertical = _basis.y.normalized()
	horizontal = _basis.x.normalized()
	
	limit_deadzone_ratio = Vector2(x_deadzone / (x_deadzone + x_limit), y_deadzone / (y_deadzone + y_limit))

func _process(delta: float) -> void:
	if not active: return
	
	prev_mouse_moude = Input.mouse_mode
	#print(limit_deadzone_ratio)
	look.x = clamp(look.x, -1.0, 1.0)
	look.y = clamp(look.y, -1.0, 1.0)
	#print(limit_deadzone_ratio.x * sign(look.x))
	if abs(look.x) > limit_deadzone_ratio.x: look.x = lerp(look.x, limit_deadzone_ratio.x * sign(look.x), delta * look.x * pull_strength * sign(look.x))
	if abs(look.y) > limit_deadzone_ratio.y: look.y = lerp(look.y, limit_deadzone_ratio.y * sign(look.y), delta * look.y * pull_strength * sign(look.y))
	#print(look)
	
	var x : Vector3 = look.x * horizontal * pan_distance 
	var y : Vector3 = -look.y * vertical * pan_distance
	targ_pos = start_position + x + y
	
	targ_rot.y = start_angle.y + -look.x * x_limit
	targ_rot.x = start_angle.x + -look.y * y_limit
	
	position = lerp(position, targ_pos, delta * ease_strength)
	rotation = lerp(rotation, targ_rot, delta * ease_strength)

func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		look += event.relative * sensitivity * SENSITIVITY_MULT
		
