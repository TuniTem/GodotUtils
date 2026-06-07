extends Node

const SAVE_PATH = "user://local_data/"
const WORLD_SAVE_PATH = "user://worlds/"

func _ready() -> void:
	verify_dir(SAVE_PATH)
	verify_dir(WORLD_SAVE_PATH)

func verify_dir(path : String):
	path = ProjectSettings.globalize_path(path)
	DirAccess.make_dir_recursive_absolute(path)

func save_var(file_name : String, variable : Variant):
	var file := FileAccess.open(SAVE_PATH + file_name + ".var", FileAccess.WRITE)
	file.store_var(variable, true)
	file.close()
	

func load_var(file_name : String, on_fail = null):
	var file := FileAccess.open(SAVE_PATH + file_name + ".var", FileAccess.READ)
	if file:
		var data = file.get_var(true)
		file.close()
		return data
	else:
		#Debug.push("requested file " + file_name + ".var does not exist, returning default")
		return on_fail

func save_node(file_name : String, node : Node):
	var packed : PackedScene = PackedScene.new()
	packed.pack(node)
	ResourceSaver.save(packed, SAVE_PATH + file_name + ".tscn")

func load_node(file_name : String, on_fail : PackedScene = PackedScene.new()):
	var path : String = SAVE_PATH + file_name + ".tscn"
	if not FileAccess.file_exists(path):
		return on_fail.instantiate()
	
	var scene : PackedScene = ResourceLoader.load(path, "PackedScene")
	return scene.instantiate()
	

func world_save_var(world : String, section : String, file_name : String, variable : Variant):
	var full_path : String = WORLD_SAVE_PATH + world.validate_filename() + "/" + section + "/"
	verify_dir(full_path)
	
	var file := FileAccess.open(full_path + file_name + ".var", FileAccess.WRITE)
	file.store_var(variable, true)
	file.close()

func world_load_var(world : String, section : String, file_name : String, on_fail = null):
	var full_path : String = WORLD_SAVE_PATH + world.validate_filename() + "/" + section + "/"
	var file := FileAccess.open(full_path + file_name + ".var", FileAccess.READ)
	print(full_path + " file err ", file.get_error())
	if file.get_error() == Error.OK:
		var data = file.get_var(true)
		file.close()
		print("data: ", data)
		return data
	else:
		Debug.push("requested file " + file_name + ".var does not exist, returning default")
		return on_fail

func world_save_node(world : String, section : String, file_name : String, node : Node):
	var full_path : String = WORLD_SAVE_PATH + world.validate_filename() + "/" + section + "/"
	verify_dir(full_path)
	
	var packed : PackedScene = PackedScene.new()
	packed.pack(node)
	ResourceSaver.save(packed, full_path + file_name + ".tscn")

func world_load_node(world : String, section : String, file_name : String, on_fail : PackedScene = PackedScene.new()):
	var full_path : String = WORLD_SAVE_PATH + world.validate_filename() + "/" + section + "/" + file_name + ".tscn"
	if not FileAccess.file_exists(full_path): return on_fail.instantiate()
	
	var scene : PackedScene = ResourceLoader.load(full_path, "PackedScene")
	if not scene: return on_fail.instantiate()
	return scene.instantiate()

# Modified from the docs
## Extract all files from a ZIP archive, preserving the directories within.
## This acts like the "Extract all" functionality from most archive managers.
func extract_all_from_zip(archive_path : String, output_directory_path : String, silent : bool = true):
	#if archive_path.contains("user://") or archive_path.contains("res://"):
		#archive_path = ProjectSettings.globalize_path(archive_path)
		#
	#if output_directory_path.contains("user://") or output_directory_path.contains("res://"):
		#output_directory_path = ProjectSettings.globalize_path(output_directory_path)
	
	if not silent: print("Extracting " + archive_path + " to " + output_directory_path)
	
	var reader = ZIPReader.new()
	reader.open(archive_path)

	# Destination directory for the extracted files (this folder must exist before extraction).
	# Not all ZIP archives put everything in a single root folder,
	# which means several files/folders may be created in `root_dir` after extraction.
	var root_dir = DirAccess.open(output_directory_path)

	var files = reader.get_files()
	for file_path in files:
		# If the current entry is a directory.
		if file_path.ends_with("/"):
			root_dir.make_dir_recursive(file_path)
			continue

		# Write file contents, creating folders automatically when needed.
		# Not all ZIP archives are strictly ordered, so we need to do this in case
		# the file entry comes before the folder entry.
		root_dir.make_dir_recursive(root_dir.get_current_dir().path_join(file_path).get_base_dir())
		var file = FileAccess.open(root_dir.get_current_dir().path_join(file_path), FileAccess.WRITE)
		var buffer = reader.read_file(file_path)
		file.store_buffer(buffer)

## Read a single file from a ZIP archive.
func read_zip_file_bytes(archive_path : String, file_relitive_path : String):
	var reader = ZIPReader.new()
	var err = reader.open(archive_path)
	if err != OK:
		printerr("ZIP read error @ " + archive_path)
		return PackedByteArray()
	
	var res = reader.read_file(file_relitive_path)
	reader.close()
	return res
