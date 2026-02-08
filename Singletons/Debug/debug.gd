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

var line_count = 0
var console_fade_timer = 0.0

var debug_mode : bool = false

var TAGS = [
	[DEFAULT, Color(1,1,1,0.5).to_html()], 
	[WARN, Color(1,1,0).to_html()], 
	[ALERT, Color(1,0,0).to_html()],
	[NONE, Color(1,1,1).to_html()],
	[INFO, Color(0,1,1).to_html()]]

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


const DEBUG_VECTOR_MATERIAL = preload("res://GodotUtils/Singletons/Debug/debug_vector_material.tres")
@export var debug_vector_holder: Node3D
var debug_vector3 : Dictionary[Array, MeshInstance3D]


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
		new_mesh.set_material_override(DEBUG_VECTOR_MATERIAL.duplicate())
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
	
	

func clean_vector3(parent : Object, identifier : Variant = ""):
	if debug_vector3.has([parent, identifier]):
		var mesh : MeshInstance3D= debug_vector3[[parent, identifier]]
		if is_instance_valid(mesh): mesh.queue_free()
		debug_vector3.erase([parent, identifier])

func clean_all_vectors():
	debug_vector3.clear()
	for child in debug_vector_holder.get_children():
		child.queue_free()

func set_game_pause(to : bool):
	get_tree().paused = to

var camera : FreeLookCamera 

func set_freecam(to : bool):
	if to:
		Debug.push("enabled freecam", Debug.INFO)
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
		Debug.push("disabled freecam", Debug.INFO)
		if is_instance_valid(camera):
			camera.queue_free()
			camera = null
			
		set_game_pause(false)
		
		


func _input(event: InputEvent) -> void:
	if not Debug.debug_mode: return
	
	if event is InputEventKey and event.is_pressed():
		match event.keycode:
			KEY_BRACERIGHT:
				clean_all_vectors()
			KEY_BACKSLASH:
				set_freecam(not is_instance_valid(camera))
					
