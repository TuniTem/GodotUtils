extends LineEdit

@export var console : RichTextLabel
@export var command_bg : Panel
@export var command_list : Node

# history
const MAX_STORED_HISTORY = 10
var write_history : Array = []
var write_history_curr_index = 0

# autocomplete
var autocomplete_matches: Array = []
var autocomplete_matches_hist: Array = []

func _ready() -> void:
	if not Debug.debug_mode: return

	Debug.console_fade_timer = 0.0
	Debug.push("Debug mode enabled", Debug.INFO)
	var file_location : String = File.load_var("debug_file_location", "")
	
	if file_location == "" or not FileAccess.file_exists(file_location):
		file_location = Util.find_file_at_dir("res://", "command_list.gd")
		if file_location != "":
			File.save_var("debug_file_location", file_location)
		else:
			var file := FileAccess.open(DEFAULT_COMMAND_LIST_LOCATION, FileAccess.WRITE)
			file.store_string(COMMAND_LIST_SCRIPT)
			file.close()
			print("Created command_list.gd file at \"res://command_list.gd\", you can edit it to add custom commands to the debugger, you may also move it to any location after running this project again")
			get_tree().quit()
	
	command_list.set_script(load(file_location))
	
	write_history = File.load_var("write_history", [])
	

func _process(delta):
	if has_focus():
		Debug.console_fade_timer = 0.0
		

func _input(event : InputEvent):
	if not Debug.debug_mode or not event is InputEventKey or not event.is_pressed(): return
	if event.keycode == KEY_ENTER and event.keyci: 
		Util.set_input_group("console")
		Debug.console_fade_timer = 0.0
		Debug.set_game_pause(true)
		Debug.show()
	
	if not Util.is_current_input_group("console"): return
	if event.keycode == KEY_ENTER:
		if not has_focus(): 
			command_bg.show()
			call_deferred("grab_focus")
		else:
			release_focus()
			Util.set_input_group("default")
			if text != "":
				command_bg.hide()
				Debug.set_game_pause(false)
				process_input(text)
				clear()
	
	
	if has_focus():
		if write_history.size() > 0:
			if event.keycode == KEY_UP:
				write_history_curr_index -= 1
				if write_history_curr_index < 0:
					write_history_curr_index = write_history.size() - 1
				
				write(write_history[write_history_curr_index])
					
			elif event.keycode == KEY_DOWN:
				write_history_curr_index += 1
				if write_history_curr_index > write_history.size() - 1:
					write_history_curr_index = 0
				
				write(write_history[write_history_curr_index])
				
			elif event.keycode == KEY_TAB:
				autocomplete()
			
			elif event is InputEventKey and event.pressed:
				autocomplete_matches = []
				write_history_curr_index = 0

func write(str : String):
	clear()
	call_deferred("insert_text_at_caret", str)

func process_input(input : String):
	if (write_history.size() > 0 and input != write_history[-1]) or write_history.size() == 0:
		write_history.append(input)
		
	while write_history.size() > MAX_STORED_HISTORY:
		write_history.pop_front()
	File.save_var("write_history", write_history)
	var args = input.split(" ")
	
	if command_list.list.has(args[0]):
		run_cmd(args)
	
	else:
		Debug.push(input, Debug.NONE)

func invalid_arguments(): Debug.push("Invalid arguments", Debug.ALERT)
func run_cmd(cmd : Array):
	var command_header = cmd.pop_front()
	command_list.commands[command_header]["execute"].call(cmd)
	
	

func autocomplete():
	var words = text.split(" ")
	var suggestions: Array
	if autocomplete_matches == []:
		if words.size() > 1:
			if command_list.list.has(words[0]):
				suggestions = command_list.commands[words[0]]["autocomplete"].call(words[-1])
			else:
				suggestions = []
		else:
			suggestions = command_list.list
		
		if words[-1] != "":
			autocomplete_matches = suggestions.filter(func(s): return s.to_lower().find(words[-1].to_lower()) >= 0).duplicate()
		else:
			autocomplete_matches = suggestions.duplicate()
		
		autocomplete_matches_hist = autocomplete_matches.duplicate()
	print("--")
	var complete = autocomplete_matches.pop_front()
	if autocomplete_matches == []: autocomplete_matches = autocomplete_matches_hist.duplicate()
	if complete: words[-1] = complete
	var out = ""
	for word in words:
		if word != words[-1]: out += word + " "
		else: out += word
	
	write(out)


const COMMAND_LIST_SCRIPT : String = """
extends Object

var list : Array[String]:
	get(): return commands.keys()

var commands : Dictionary[String, Dictionary] = {
	"help" : {
		"execute" : 
			func(_args : Array):
				Debug.push("List of avalable commands:", Debug.INFO)
				for command in list:
					Debug.push("\\t"+command, Debug.INFO)
,
		"autocomplete": 
			func(_last_word : String):
				match _last_word:
					#"item": return Global.ITEM_LIST
					_: return []
,
	}
}

"""
const DEFAULT_COMMAND_LIST_LOCATION = "res://command_list.gd"
