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

# Modified from the docs
## Extract all files from a ZIP archive, preserving the directories within.
## This acts like the "Extract all" functionality from most archive managers.
func extract_all_from_zip(archive_path : String, output_directory_path : String):
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
