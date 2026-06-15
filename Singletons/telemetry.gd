extends Node

const TELEMETRY_PATH = "user://telemetry/"
const FILE_MARKER = "!! IMPORTANT: Send File in Discord"

var data : Dictionary[String, Variant]
var feedback : Array[Dictionary]

var tracked_level : String = "no_level"
var tracked_position : Vector3
var current_flags : Array[String]
var current_milestone : String = "start"

var performance_interval : int = 0
var track_avg_fps : bool = true
var avg_fps_entries : int = 1
var average_fps : float = 60.0

var sesion_timer : float = -1.0
var rounded_sesion_time : float:
	get(): return Util.round_to(sesion_timer, 0.01)

var active_session : bool = false
var current_session : String = ""
var zip_location : String:
	get(): return TELEMETRY_PATH + current_session + ".zip"
var active : bool = false


func _process(delta: float) -> void:
	if sesion_timer >= 0.0 and active:
		sesion_timer += delta
		if performance_interval != 0 and roundi(sesion_timer) % performance_interval == 0 and roundi(sesion_timer - delta) % performance_interval != 0:
			log_performance_data()
		
		if track_avg_fps and roundi(sesion_timer) != roundi(sesion_timer - delta):
			avg_fps_entries += 1
			average_fps = average_fps * ((avg_fps_entries - 1) / average_fps) + Engine.get_frames_per_second() * (1 / average_fps)
			record("avg_fps", average_fps)

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST and active and active_session:
		get_tree().set_auto_accept_quit(false)
		stop_session()
		get_tree().quit()

func start_session(title : String = ""):
	if not active: return
	if active_session:
		stop_session()
	
	current_session = Util.validate_filename(FILE_MARKER + " " + title + (" " if not title.is_empty() else "") + Time.get_datetime_string_from_system(true))
	active_session = true
	sesion_timer = 0.0
	
	File.create_new_zip_file(zip_location)

func stop_session():
	if not active: return
	record("time", rounded_sesion_time)
	
	active_session = false
	sesion_timer = -1.0
	var dir : DirAccess = DirAccess.open(TELEMETRY_PATH)
	
	if dir.get_files().size() > 0 and dir.get_files()[0].begins_with(FILE_MARKER):
		dir.remove(dir.get_files()[0])
	
	File.append_file_to_zip(zip_location, data, "telemetry.var")
	
	var feeback_array : Array[String]
	for index : int in range(feedback.size()):
		feeback_array.append(feedback[index]["written"])
		if feedback[index]["image"] != null:
			print("a")
			var image : Image = feedback[index]["image"]
			File.append_file_to_zip(zip_location, image, str(index) + ".jpg", [0.5])
	
	File.append_file_to_zip(zip_location, feeback_array, "feedback.var")
	
	Util.open_explorer_to_file(zip_location)

func set_position(player_position : Vector3):
	tracked_position = player_position

func set_location(level : String):
	tracked_level = level

func achieve_milestone(new_milestone : String):
	record("milestones", {"milestone" : new_milestone, "time" : rounded_sesion_time})
	current_milestone = new_milestone

func event(event_tag : String, extra_data : Dictionary = {}):
	record("events", {
		"event" : event_tag,
		"session_time" : rounded_sesion_time, 
		"data" : extra_data
	}, true)

func info_flag_add(flag : String):
	if not current_flags.has(flag): current_flags.append(flag)

func info_flag_remove(flag : String):
	current_flags.erase(flag)

func info_flag_clear():
	current_flags.clear()

func log_performance_data():
	var rd : RenderingDevice = RenderingServer.get_rendering_device()
	record("performance", {
		"fps" :  Engine.get_frames_per_second(),
		"memory_usage" : rd.get_memory_usage(RenderingDevice.MEMORY_TOTAL),
		"graphics_card_usage" : roundi(float(Performance.get_monitor(Performance.RENDER_VIDEO_MEM_USED)) / 1024.0 / 1024.0),
		"location" : {
			"level" : tracked_level,
			"position" : tracked_position,
			"flags" : current_flags.duplicate()
		}
	}, true)

func init(game_build_version : String = "unknown", system_info : bool = true, locale_info : bool = true, avg_fps : bool = true, performance_log_interval : int = 60):
	File.verify_dir(TELEMETRY_PATH)
	active = true
	record("version", game_build_version)
	if system_info:
		record("system_info", 
			{
				"id" : OS.get_unique_id().replace("{", "").replace("}", ""),
				"operating_system" : OS.get_name(),
				"device_name" : OS.get_environment("USERNAME"),
				"processor" : OS.get_processor_name(),
				"processor_cores" : OS.get_processor_count(),
				"graphics_card" : RenderingServer.get_video_adapter_name(),
				"graphics_manufacturer": RenderingServer.get_video_adapter_vendor(),
				"memory" : roundi(float(OS.get_memory_info()["physical"]) / 1024.0 / 1024.0 / 1024.0 + 0.2),
				"memory_free" : roundi(float(OS.get_memory_info()["free"]) / 1024.0 / 1024.0 / 1024.0), 
				"motherboard" : OS.get_model_name(),
				"number_of_monitors" : DisplayServer.get_screen_count(),
				"primary_screen_resolution" : DisplayServer.screen_get_size(),
				"primary_screen_refresh_rate" : roundi(DisplayServer.screen_get_refresh_rate())
			}
		)
	
	if locale_info:
		record("locale", OS.get_locale())
	
	track_avg_fps = avg_fps
	performance_interval = performance_log_interval

func recursive_convert(dat : Variant) -> Variant:
	var iter_array : Array
	match typeof(dat):
		TYPE_DICTIONARY:
			iter_array = dat.keys()
		
		TYPE_ARRAY:
			iter_array = range(iter_array.size())
		
		TYPE_VECTOR2, TYPE_VECTOR2I:
			dat = convert_vec2(dat)
		
		TYPE_VECTOR3, TYPE_VECTOR3I:
			dat = convert_vec3(dat)
	
	for idx in iter_array:
		match typeof(dat[idx]):
			TYPE_VECTOR3, TYPE_VECTOR3I:
				dat[idx] = convert_vec3(dat[idx])
			
			TYPE_VECTOR2, TYPE_VECTOR2I:
				dat[idx] = convert_vec2(dat[idx])
			
			TYPE_DICTIONARY:
				dat[idx] = recursive_convert(dat[idx])
	
	return dat

func convert_vec3(vec : Vector3) -> Dictionary:
	return {"x" : vec.x, "y" : vec.y, "z" : vec.z}
	
func convert_vec2(vec : Vector2) -> Dictionary:
	return {"x" : vec.x, "y" : vec.y}

func submit_feedback(new_feedback: String, image : Image = null):
	feedback.append({
		"written" : new_feedback,
		"image" : image
	})
	

func record(tag : String, new_data : Variant, append : bool = false):
	if not active: return
	new_data = recursive_convert(new_data)
	
	if append:
		if not data.has(tag): data[tag] = []
		data[tag].append(new_data)
	
	else:
		data[tag] = new_data
	
	
