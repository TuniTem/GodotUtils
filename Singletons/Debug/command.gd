extends LineEdit

@export var console : RichTextLabel
@export var command_bg : Panel
@export var command_list : Node

const COMMAND_LIST_SCRIPT : Script = preload("res://GodotUtils/Singletons/Debug/command_list.gd") # if this errs please run the bat file located at GodotUtils/Singletons/Debug/CreateDebugCommandTemplates.bat

# history
const MAX_STORED_HISTORY = 10
var write_history : Array = []
var write_history_curr_index = 0

# autocomplete
var autocomplete_matches: Array = []
var autocomplete_matches_hist: Array = []

func _ready() -> void:
	command_list.set_script(COMMAND_LIST_SCRIPT)
	
	write_history = File.load_var("write_history", [])
	

func _process(delta):
	if has_focus():
		Debug.console_fade_timer = 0.0
		

func _input(event):
	if event.is_action_pressed("console"): 
		Util.set_input_group("console")
		Debug.show()
	
	if not Util.is_current_input_group("console"): return
	if event.is_action_pressed("console"):
		if not has_focus(): 
			command_bg.show()
			call_deferred("grab_focus")
		else:
			release_focus()
			Util.set_input_group("default")
			if text != "":
				command_bg.hide()
				process_input(text)
				clear()
	
	
	if has_focus():
		if write_history.size() > 0:
			if event.is_action_pressed("last_cmd"):
				write_history_curr_index -= 1
				if write_history_curr_index < 0:
					write_history_curr_index = write_history.size() - 1
				
				write(write_history[write_history_curr_index])
					
			elif event.is_action_pressed("next_cmd"):
				write_history_curr_index += 1
				if write_history_curr_index > write_history.size() - 1:
					write_history_curr_index = 0
				
				write(write_history[write_history_curr_index])
				
			elif event.is_action_pressed("autocomplete"):
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
			suggestions = command_list.commands_list
		
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
