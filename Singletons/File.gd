extends Node

const SAVE_PATH = "user://save_data/"

func _ready() -> void:
	verify_dir(SAVE_PATH.replace("user://", ""))

func verify_dir(path : String):
	var dir = DirAccess.open("user://")
	if not dir.dir_exists(path):
		var files : Array = path.split("/")
		var curr_dir = files.pop_front()
		for file in files:
			dir.make_dir(curr_dir)
			curr_dir = curr_dir + "/" + file
		
		#Debug.push("Created directory: " + path, Debug.INFO)
		

func save_var(file_name : String, variable : Variant):
	var file := FileAccess.open(SAVE_PATH + file_name + ".var", FileAccess.WRITE)
	file.store_var(variable)
	file.close()
	

func load_var(file_name : String, on_fail = null):
	var file := FileAccess.open(SAVE_PATH + file_name + ".var", FileAccess.READ)
	if file:
		var data = file.get_var()
		file.close()
		return data
	else:
		#Debug.push("requested file " + file_name + ".var does not exist, returning default")
		return on_fail
