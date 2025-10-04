extends Node
# Optional Singleton, please set the correct directories and extentions you want in the constants below, and create the directories manually

const DB_EXT : String = ".db"
const DB_PATH : String = "user://data/"
const BACKUPS_PATH : String = "user://data/backups/"

func list(db : String, idx : int = -1) -> Array:
	var file = FileAccess.open(DB_PATH + db + ".db", FileAccess.READ)
	if not file or file.get_error() != 0:
		printerr("List failed with error code " + str(file.get_error() if file else null)) 
		return []
		
	var data : Array = file.get_var()
	file.close()
	if idx == -1:
		return data
	
	else:
		var out : Array = []
		for entry in data: 
			out.append(entry[idx])
		
		return out
	

func size(db: String):
	return list(db).size()

func find(db: String, key: Variant):
	var data : Array = list(db)
	var search : int = _find_entry_index(data, key)
	if search != -1:
		return data[search]

func remove(db: String, key: Variant):
	var data : Array = list(db)
	var search : int = _find_entry_index(data, key)
	if search != -1:
		data.remove_at(search)
		_store(db, data)

func update(db: String, key: Variant, new : Variant, index : int = -10, custom_backup_interval : int = 10):
	var data : Array = list(db)
	var search : int = _find_entry_index(data, key)
	#prints("search result", search)
	if search != -1:
		if index != -10: data[search][index] = new
		else: data[search] = new
		_store(db, data)
		
	else:
		append(db, new, custom_backup_interval)

func append(db : String, content : Variant, custom_backup_interval : int = 10):
	var data : Array = list(db)
	data.append(content)
	_store(db, data)
	
	if size(db) % custom_backup_interval == 1:
		backup(db)

func delete_DB(db : String):
	var dir = DirAccess.open(DB_PATH)
	#print(DirAccess.get_open_error())
	dir.remove(db + DB_EXT)

func _store(db: String, data : Array):
	var file = FileAccess.open(DB_PATH + db + DB_EXT, FileAccess.WRITE)
	file.store_var(data)
	file.close()

func replace(db: String, data : Array, backup : bool = true, mark_start : bool = false):
	if backup: backup(db, mark_start)
	_store(db, data)

func _find_entry_index(data_array : Array, key : Variant):
	return data_array.find_custom(
		func find_key(entry): 
			#prints("entry", entry[0], "key", key)
			return entry[0] == key
	)



func backup(db : String, mark_start : bool = false, max_backups : int = 100):
	var path = BACKUPS_PATH + db + "/"
	if not DirAccess.dir_exists_absolute(ProjectSettings.globalize_path(path)):
		DirAccess.make_dir_absolute(ProjectSettings.globalize_path(path))
		
	var dir = DirAccess.open(path)
	dir.copy_absolute(
		ProjectSettings.globalize_path(DB_PATH + db + DB_EXT), 
		ProjectSettings.globalize_path(path + ("STARTUP " if mark_start else "") + Time.get_datetime_string_from_system().replace(":", "-") + DB_EXT)
	)
	
	if dir.get_files().size() > max_backups:
		var oldest_file = ""
		var oldest_time = INF
		var file_name = dir.get_next()
		dir.list_dir_begin()
		for file in dir.get_files():
			var mod_time = FileAccess.get_modified_time(path + file)
			if mod_time < oldest_time:
				oldest_time = mod_time
				oldest_file = file
		dir.list_dir_end()
		dir.remove(oldest_file)
