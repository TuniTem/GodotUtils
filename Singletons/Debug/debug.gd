extends Control

const MAX_LINE_COUNT = 19
const CONSOLE_FADE_TIME = [3.0, 5.0]

enum {
	DEFAULT,
	ALERT,
	WARN,
	NONE,
	INFO
}

@export var container : VBoxContainer
@export var console: RichTextLabel
@export var console_container: VBoxContainer
@export var command: LineEdit
@export var track_container: MarginContainer

var line_count = 0
var console_fade_timer = 0.0

var debug_mode : bool = true

var TAGS = [
	[DEFAULT, Color(1,1,1,0.5).to_html()], 
	[WARN, Color(1,1,0).to_html()], 
	[ALERT, Color(1,0,0).to_html()],
	[NONE, Color(1,1,1).to_html()],
	[INFO, Color(0,1,1).to_html()]]

const DEFAULT_DEBUG_COLORS = [Color.RED, Color("fff299"), Color.GREEN, Color.BLUE, Color.MEDIUM_PURPLE, Color.PALE_VIOLET_RED]

var tracked_values : Array = [
	{
		"tag": "FPS",
		"label": null,
		"is_function": true,
		"object": Engine,
		"parameter": "",
		"callable": Callable(Engine, "get_frames_per_second"),
		"print": false
	}
]
# tracked values format
# 0 [display tag : String, 
# 1 label object pointer : Label, 
# 2 value from function : bool, 
# 3 Callable func or object : Callable or Node,
# 4 param name in case of non-Callable : String]

var tracked_collision_shapes : Array[CollisionShape3D]
var prev_collision_shape_dimentions : Dictionary[CollisionShape3D, Array]
var tracked_collision_shape_colors : Dictionary[CollisionShape3D, Color]
var all_collision_draws_active : bool = false
var game_display_shortcuts : bool = false
var window_drag_pos : Vector2i = -Vector2i.ONE
var window_offset : Vector2i

const DEBUG_DRAW_MATERIAL = preload("res://GodotUtils/Singletons/Debug/debug_vector_material.tres")

@onready var debug_vector_holder: Node3D = %DebugVectorHolder
@onready var debug_shape_holder: Node3D = %DebugShapeHolder

var debug_vector3 : Dictionary[Array, MeshInstance3D]
var debug_shapes : Dictionary[Array, MeshInstance3D]


func _init() -> void:
	debug_mode = not OS.has_feature("standalone")

func _ready():
	Debug.process_mode = Node.PROCESS_MODE_ALWAYS
	_update_list()
	hide()
	
func _process(delta: float):
	console_fade_timer += delta
	console_container.modulate.a = 1.0 - clamp((console_fade_timer - CONSOLE_FADE_TIME[0]) / (CONSOLE_FADE_TIME[1] - CONSOLE_FADE_TIME[0]), 0.0, 1.0)
	if visible:
		_update()
	
	#if all_collision_draws_active and Util.cooldown("all_collision_draws_active", 1.0):
		#debug_all_collision_shapes(true)
	
	_update_tracked_collision_shapes()
	
	if game_display_shortcuts and window_drag_pos != -Vector2i.ONE:
		var window : Window = get_window()
		window.position = window_drag_pos + DisplayServer.mouse_get_position() - window_offset

func _update():
	for value in tracked_values:
		if not value["object"]:
			tracked_values.erase(value)
		else:
			var label = value["label"]
			if label:
				if value["is_function"]:
					label.text = value["tag"] + ": " + str(value["callable"].call())
					if value["print"]: print(str(value["callable"].call()))
					
				else:
					label.text = value["object"].name + " - " + value["tag"] + ": " + str(value["object"].get(value["parameter"]))
					if value["print"]: print(value["object"].name + " - " + value["tag"] + ": " + str(value["object"].get(value["parameter"])))
					
			else: print("aa im missing my label this is the worst day of my short computer life...")

func _update_list():
	for child in container.get_children():
		child.queue_free()
	
	for value in tracked_values:
		var label = Label.new()
		label.text = value["tag"] + ": "
		container.add_child(label)
		tracked_values[tracked_values.find(value)]["label"] = container.get_child(container.get_child_count()-1)
	
	_update()
		

func set_track_scale(to : float):
	track_container.scale = Vector2.ONE * to



func track(object : Node, track_string : String, print : bool = false, tag : String = "", is_func = false):
	var out = {
		"tag": "",
		"label": null,
		"is_function": is_func,
		"object": null,
		"parameter": "",
		"callable": null,
		"print": print
	}
	
	if tag != "": out["tag"] = tag
	else: out["tag"] = track_string
	
	if is_func: 
		out["callable"] = Callable(object, track_string)
	else: 
		out["object"] = object
		out["parameter"] = track_string
	
	tracked_values.append(out)
	_update_list()



func push(item, tag := DEFAULT):
	var time = Time.get_time_dict_from_system()
	var out = ""
	
	item = str(item)
	for i in TAGS: if i[0] == tag: out += "[color=" + i[1] + "]"
	if tag == DEFAULT: out += "[i]"
	if tag != INFO: out += "[%02d:%02d:%02d] " % [time.hour, time.minute, time.second]
	if tag == ALERT: out += "ALERT: "
	if tag == WARN: out += "WARNING: "
	if tag == DEFAULT: out += "[/i]"
	out += item + "[/color]\n"
	
	line_count = console.get_line_count()
	if line_count > MAX_LINE_COUNT:
		console.text = console.text.split("\n", true, 1)[1] + out
	else:
		console.text = console.text + out
	
	if tag != ALERT: print("[%02d:%02d:%02d] " % [time.hour, time.minute, time.second], item)
	else: printerr("[%02d:%02d:%02d] ALERT: " % [time.hour, time.minute, time.second], item)
	
	console_fade_timer = 0.0



func draw_vector3(end : Vector3, start : Vector3 = Vector3.ZERO, node : Node = self, identifier : Variant = "", color : Color = Color.RED):
	if not debug_mode: return
	var mesh : ImmediateMesh
	if debug_vector3.has([node, identifier]) and not identifier == "":
		mesh = debug_vector3[[node, identifier]].mesh
		
	else:
		var new_mesh = MeshInstance3D.new()
		new_mesh.mesh = ImmediateMesh.new()
		new_mesh.set_material_override(DEBUG_DRAW_MATERIAL.duplicate())
		new_mesh.material_override.albedo_color = color
		debug_vector_holder.add_child(new_mesh)
		#print("create new vector: ", identifier, " " , end)
		
		mesh = new_mesh.mesh
		debug_vector3[[node, identifier]] = new_mesh
		
	
	mesh.clear_surfaces()
	mesh.surface_begin(Mesh.PRIMITIVE_LINE_STRIP)
	mesh.surface_add_vertex(start)
	mesh.surface_add_vertex(start + end)
	mesh.surface_end()

const BOX_DRAW_ORDER : Array = [
		Vector3(1, 1, 1),
		Vector3(0, 1, 1),
		Vector3(0, 1, 0),
		Vector3(1, 1, 0),
		Vector3(1, 1, 1),
		Vector3(1, 0, 1),
		Vector3(0, 0, 1),
		Vector3(0, 1, 1),
		Vector3(0, 0, 1),
		Vector3(0, 0, 0),
		Vector3(0, 1, 0),
		Vector3(0, 0, 0),
		Vector3(1, 0, 0),
		Vector3(1, 1, 0),
		Vector3(1, 0, 0),
		Vector3(1, 0, 1),
	]

func draw_shape(shape : Shape3D, transform : Transform3D, node : Node = self, identifier : Variant = "", color : Color = Color.RED):
	if not debug_mode: return
	var mesh : MeshInstance3D
	if debug_shapes.has([node, identifier]) and not identifier == "":
		mesh = debug_shapes[[node, identifier]]
		
	else:
		var new_mesh = MeshInstance3D.new()
		new_mesh.set_material_override(DEBUG_DRAW_MATERIAL.duplicate())
		
		new_mesh.material_override.albedo_color = color
		debug_shape_holder.add_child(new_mesh)
		#print("create new vector: ", identifier, " " , end)
		
		mesh = new_mesh
		debug_shapes[[node, identifier]] = new_mesh
		
	
	mesh.mesh = shape.get_debug_mesh()
	mesh.global_transform = transform
	
	#mesh.clear_surfaces()
	#mesh.surface_begin(Mesh.PRIMITIVE_LINE_STRIP)
	#
	#var half_size : Vector3 = size * 0.5
	#for line : Vector3 in BOX_DRAW_ORDER:
		#mesh.surface_add_vertex(center + half_size * line)
	#
	#mesh.surface_end()

func track_collision_shape(collision_shape : CollisionShape3D, custom_color : Color = Color(0.1, 0.1, 0.1), add : bool = true):
	if add and not tracked_collision_shapes.has(collision_shape):
		tracked_collision_shapes.append(collision_shape)
		prev_collision_shape_dimentions[collision_shape] = [Transform3D.IDENTITY, 0.0]
		tracked_collision_shape_colors[collision_shape] = DEFAULT_DEBUG_COLORS[hash(collision_shape.get_parent().name) % DEFAULT_DEBUG_COLORS.size()] if custom_color == Color(0.1,0.1,0.1) else custom_color
		
	elif not add and tracked_collision_shapes.has(collision_shape):
		tracked_collision_shapes.erase(collision_shape)
		prev_collision_shape_dimentions.erase(collision_shape)
		tracked_collision_shape_colors.erase(collision_shape)



func debug_all_collision_shapes(enable : bool):
	get_tree().debug_collisions_hint = enable
	for child in Util.get_all_children(get_tree().root):
		if child is CollisionShape3D:
			child.queue_redraw()
			track_collision_shape(child)
	#print("b ", enable)
	#if enable:
		#for child in Util.get_all_children(get_tree().root):
			#if child is CollisionShape3D:
				#print(child.name)
				#track_collision_shape(child)
	#else:
		#clean_all_shapes()
	
# from https://github.com/godotengine/godot-proposals/issues/2072#issuecomment-1890114615
func toggle_collision_shape_visibility(visible : bool) -> void:
	print("Set show_debug_collisions_hint: ", visible)
	var tree: SceneTree = get_tree()
	# https://github.com/godotengine/godot-proposals/issues/2072
	tree.debug_collisions_hint = visible

	# Traverse tree to call toggle collision visibility
	var node_stack: Array[Node] = [tree.get_root()]
	while not node_stack.is_empty():
		var node: Node = node_stack.pop_back()
		if is_instance_valid(node):
			if   node is CollisionShape2D \
				or node is CollisionPolygon2D \
				or node is CollisionObject2D:
				# queue_redraw on instances of
				node.queue_redraw()
			elif node is TileMap:
				# use visibility mode to force redraw
				node.collision_visibility_mode = TileMap.VISIBILITY_MODE_FORCE_HIDE
				node.collision_visibility_mode = TileMap.VISIBILITY_MODE_DEFAULT
			elif node is RayCast3D \
				or node is CollisionShape3D \
				or node is CollisionPolygon3D \
				or node is CollisionObject3D \
				or node is GPUParticlesCollision3D \
				or node is GPUParticlesCollisionBox3D \
				or node is GPUParticlesCollisionHeightField3D \
				or node is GPUParticlesCollisionSDF3D \
				or node is GPUParticlesCollisionSphere3D:
				# remove and re-add the node to the tree to force a redraw
				# https://github.com/godotengine/godot/blob/26b1fd0d842fa3c2f090ead47e8ea7cd2d6515e1/scene/3d/collision_object_3d.cpp#L39
				var parent: Node = node.get_parent()
				if parent:
					parent.remove_child(node)
					parent.add_child(node)
			node_stack.append_array(node.get_children())

func _update_tracked_collision_shapes():
	for collision_shape : CollisionShape3D in tracked_collision_shapes:
		if not is_instance_valid(collision_shape):
			tracked_collision_shapes.erase(collision_shape)
			continue
		
		var shape : Shape3D = collision_shape.shape
		
		var curr_size : float = (
			shape.size.length() if shape is BoxShape3D else\
			shape.radius if shape is SphereShape3D else\
			shape.height + shape.radius if shape is CylinderShape3D else\
			0.0
		)
		
		
		var still : bool = collision_shape.global_transform == prev_collision_shape_dimentions[collision_shape][0]
		var same_size : bool = curr_size == prev_collision_shape_dimentions[collision_shape][1]
		
		prev_collision_shape_dimentions[collision_shape] = [collision_shape.global_transform, curr_size] 
		
		if still and same_size:
			continue
		
		draw_shape(collision_shape.shape, collision_shape.global_transform, collision_shape, "debug", tracked_collision_shape_colors[collision_shape])
		
		
		

func clean_vector3(parent : Object, identifier : Variant = ""):
	if debug_vector3.has([parent, identifier]):
		var mesh : MeshInstance3D= debug_vector3[[parent, identifier]]
		if is_instance_valid(mesh): mesh.queue_free()
		debug_vector3.erase([parent, identifier])

func clean_shapes(parent : Object, identifier : Variant = ""):
	if debug_shapes.has([parent, identifier]):
		var mesh : MeshInstance3D = debug_shapes[[parent, identifier]]
		if is_instance_valid(mesh): mesh.queue_free()
		debug_shapes.erase([parent, identifier])

func clean_all_vectors():
	debug_vector3.clear()
	for child in debug_vector_holder.get_children():
		child.queue_free()

func clean_all_shapes():
	debug_shapes.clear()
	tracked_collision_shapes.clear()
	tracked_collision_shape_colors.clear()
	prev_collision_shape_dimentions.clear()
	for child in debug_shape_holder.get_children():
		child.queue_free()

func set_game_pause(to : bool):
	get_tree().paused = to

var camera : FreeLookCamera 

func set_freecam(to : bool):
	if to:
		Debug.push("Enabled freecam", Debug.INFO)
		var old_camera : Camera3D = get_viewport().get_camera_3d()
		var pos : Vector3 = old_camera.global_position
		var rot : Vector3 = old_camera.global_rotation
		var fov : float = old_camera.fov
		camera = FreeLookCamera.new()
		
		set_game_pause(true)
		add_child(camera)
		camera.global_position = pos
		#camera.global_rotation = rot
		camera.fov = fov
		camera.current = true
	
	else:
		Debug.push("Disabled freecam", Debug.INFO)
		if is_instance_valid(camera):
			camera.queue_free()
			camera = null
			
		set_game_pause(false)

func set_game_display_shortcuts(to : bool):
	game_display_shortcuts = to

func _input(event: InputEvent) -> void:
	if not Debug.debug_mode: return
	
	if event is InputEventKey and event.is_pressed():
		match event.keycode:
			KEY_BRACKETRIGHT:
				push("Cleared all debug vectors", INFO)
				clean_all_vectors()
			KEY_BRACKETLEFT:
				
				all_collision_draws_active = not all_collision_draws_active
				toggle_collision_shape_visibility(all_collision_draws_active)
				push("Toggled all collision shape drawing", INFO)
				#debug_all_collision_shapes(all_collision_draws_active)
			
			KEY_BACKSLASH:
				set_freecam(not is_instance_valid(camera))
				
			KEY_F11:
				if game_display_shortcuts:
					Util.toggle_fullscreen(true)
			
	elif event is InputEventMouseButton and event.is_pressed():
		match event.button_index:
			MOUSE_BUTTON_LEFT:
				if DisplayServer.mouse_get_mode() == DisplayServer.MOUSE_MODE_VISIBLE and game_display_shortcuts and Input.is_key_pressed(KEY_SHIFT):
					window_drag_pos = get_window().position
					window_offset = DisplayServer.mouse_get_position()
	
	elif event is InputEventMouseButton and not event.is_pressed():
		match event.button_index:
			MOUSE_BUTTON_LEFT:
				if window_drag_pos != -Vector2i.ONE:
					window_drag_pos = -Vector2i.ONE
