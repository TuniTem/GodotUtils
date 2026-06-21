extends Node

enum Controller {
	KEYBOARD,
	MOUSE,
	GENERIC,
	GAMECUBE,
	SWITCH,
	SWITCH2,
	WII,
	WIIU,
	PLAYDATE,
	PLAYSTATION,
	STEAM_CONTROLLER,
	STEAM_DECK,
	MOBILE,
	XBOX
}

const UNKNOWN_GROUP_NAME : String = "unknown"
const IGNORE_GROUP_NAME : String = "ignore"
const ICON_FOLDER : String = "res://GodotUtils/Art/ButtonIcons/"
const CONTROLLER_BUTTON_LOCATIONS : Dictionary[Controller, String] = {
	Controller.KEYBOARD : "Keyboard/",
	Controller.MOUSE : "Mouse/",
	Controller.GENERIC : "Controller/Generic/",
	Controller.PLAYSTATION : "Controller/PlayStation/",
	Controller.XBOX : "Controller/XboxSeries/",
	Controller.SWITCH : "Controller/NintendoSwitch/",
	Controller.SWITCH2 : "Controller/NintendoSwitch2/",
	Controller.STEAM_CONTROLLER : "Controller/SteamController/",
	Controller.STEAM_DECK : "Controller/SteamDeck/",
	Controller.MOBILE : "Controller/Mobile/",
	
	# others
	Controller.GAMECUBE : "Controller/NintendoGamecube/",
	Controller.WII : "Controller/NintendoWii/",
	Controller.WIIU : "Controller/NintendoWiiU/",
	Controller.PLAYDATE : "Controller/Playdate/",
}

const CONTROLLER_ALIASES : Dictionary[String, Controller] = {
	"k" : Controller.KEYBOARD,
	"kb" : Controller.KEYBOARD,
	"m" : Controller.MOUSE,
	"g" : Controller.GENERIC,
	"ps" : Controller.PLAYSTATION,
	"xb" : Controller.XBOX,
	"s" : Controller.SWITCH,
	"s2" : Controller.SWITCH2,
	"sc" : Controller.STEAM_CONTROLLER,
	"sd" : Controller.STEAM_DECK,
	"mo" : Controller.MOBILE,
	
	# others
	"gc" : Controller.GAMECUBE,
	"w" : Controller.WII,
	"wu" : Controller.WIIU,
	"pd" : Controller.PLAYDATE,
}

const UNKNOWN_BUTTON_TEXTURE : Texture2D = preload("res://GodotUtils/Art/ButtonIcons/Keyboard/question.png")

signal new_hold_action(action_id : String)
signal hold_action_finished

var _hold_actions : Dictionary[String, Dictionary] = {}
var _double_tap_actions : Dictionary[String, Dictionary] = {}
var is_awaiting_input : bool = false
var _new_input : InputEvent

var starting_bindings : Dictionary
var current_controller : Controller = Controller.KEYBOARD # TODO : Add support for other input types
var concurrent_actions : Array = []
var action_groups : Dictionary
var action_aliases : Dictionary

func _ready() -> void:
	for action : String in InputMap.get_actions():
		starting_bindings[action] = InputMap.action_get_events(action)
	
	load_bindings()

func _process(delta: float) -> void:
	#get_viewport().set_input_as_handled()
	check_hold_actions()

func reset_controls():
	for action : String in InputMap.get_actions():
		InputMap.action_erase_events(action)
		for bind : InputEvent in starting_bindings[action]:
			InputMap.action_add_event(action, bind)
	
	save_bindings()

func init_rebinding(groups_dict : Dictionary, ignored_actions_array : Array, concurrent_action_array : Array, aliases_dict : Dictionary, ignore_unused_ui_actions : bool = true):
	set_action_groups(groups_dict.duplicate(true))
	ignored_actions_array = ignored_actions_array.duplicate(true)
	if ignore_unused_ui_actions:
		for action : String in action_groups[UNKNOWN_GROUP_NAME]:
			if action.begins_with("ui_"):
				ignored_actions_array.append(action)
		
	set_ignored_actions(ignored_actions_array)
	set_concurrent_actions(concurrent_action_array.duplicate(true))
	add_action_aliases(aliases_dict.duplicate(true))

func set_concurrent_actions(to : Array):
	concurrent_actions = to

func set_action_groups(to : Dictionary):
	action_groups = to
	action_groups[UNKNOWN_GROUP_NAME] = get_all_ungrouped_actions()
	
func set_ignored_actions(actions : Array):
	action_groups[IGNORE_GROUP_NAME] = actions
	action_groups[UNKNOWN_GROUP_NAME] = get_all_ungrouped_actions()

func add_action_aliases(aliases : Dictionary):
	for alias : String in aliases.keys():
		action_aliases[alias] = aliases[alias] 

func get_action_alias(action : String) -> String:
	if action_aliases.has(action):
		return action_aliases[action].capitalize()
	else:
		return action.capitalize()
	
func get_actions_in_group(group : String) -> Array:
	if action_groups.has(group): 
		return action_groups[group]
	
	return []

func get_all_ungrouped_actions() -> Array:
	var all_action_groups : Array = get_action_groups()
	all_action_groups.erase(UNKNOWN_GROUP_NAME)
	var all_grouped_actions : Array
	var out : Array
	
	for group : String in all_action_groups:
		all_grouped_actions.append_array(get_actions_in_group(group))
	
	all_grouped_actions.append_array(get_actions_in_group(IGNORE_GROUP_NAME))
	
	for action : String in InputMap.get_actions():
		if not action in all_grouped_actions:
			out.append(action)
	
	return out

func get_action_groups() -> Array:
	var all_action_groups : Array = action_groups.keys()
	if action_groups.has(UNKNOWN_GROUP_NAME) and action_groups[UNKNOWN_GROUP_NAME].size() == 0:
		all_action_groups.erase(UNKNOWN_GROUP_NAME)
	
	all_action_groups.erase(IGNORE_GROUP_NAME)
	return all_action_groups

func get_concurrent_actions_to(action : String) -> Array:
	for concurrent_action_arr : Array in concurrent_actions:
		if concurrent_action_arr.has(action):
			var out : Array = concurrent_action_arr.duplicate()
			out.erase(action)
			return out
	
	return []

func get_icon(icon : String, controller : Controller = Controller.KEYBOARD, outline : bool = false) -> Texture2D:
	var location : String = ICON_FOLDER + CONTROLLER_BUTTON_LOCATIONS[controller] + icon
	var out : Texture2D = UNKNOWN_BUTTON_TEXTURE
	
	if outline and FileAccess.file_exists(location + "_outline.png"):
		out = load(location + "_outline.png")
	
	elif FileAccess.file_exists(location + ".png"):
		out = load(location + ".png")
	
	return out

func get_icon_string(string : String) -> Texture2D:
	var split = string.split(" ")
	var controller_id : String = split[0]
	assert(CONTROLLER_ALIASES.has(controller_id), "No controller binding found for \"" + controller_id + "\"")
	
	var key : String = split[1]
	var outline : bool = false
	if split.size() > 2 and split[2] == "o": outline = true
	
	return get_icon(key, CONTROLLER_ALIASES[controller_id], outline)

func get_event_icon(event : InputEvent, outline : bool = false) -> Texture2D:
	var icon : String = ""
	match current_controller:
		Controller.KEYBOARD:
			if event is InputEventKey:
				icon = event.as_text_physical_keycode().to_lower()
				if icon in ["up", "down", "left", "right"]:
					icon = "arrow_" + icon
				
				return get_icon(icon, Controller.KEYBOARD, outline)
			
			elif event is InputEventMouseButton:
				icon = event.as_text().to_lower()
				var convert_dict : Dictionary[String, String] = {
					"left mouse button" : "left",
					"right mouse button" : "right",
					"middle mouse button" : "middle",
					"mouse thumb button 1" : "horizontal",
					"mouse thumb button 2" : "horizontal",
					"mouse wheel up" : "scroll_up",
					"mouse wheel down" : "scroll_down"
				}
				icon = convert_dict[icon] if icon in convert_dict.keys() else ""
				return get_icon(icon, Controller.MOUSE, outline)
			
	return Util.BLANK_TEXTURE256 # get_icon(icon, Controller.KEYBOARD, outline) 

func get_last_hold_action_progress() -> float:
	if _hold_actions.keys().size() != 0:
		return get_hold_action_progress(_hold_actions.keys()[-1])
	else: return -1.0

func get_hold_action_progress(action_id : String) -> float:
	if _hold_actions.has(action_id):
		var info : Dictionary = _hold_actions[action_id]
		return clamp((Util.TIME - info["start_time"]) / info["confirm_time"], 0.0, 1.0)
	
	else:
		return -1.0

func check_hold_actions():
	for action : String in _hold_actions.keys():
		var info : Dictionary = _hold_actions[action]
		if Util.TIME - info["start_time"] > info["confirm_time"]:
			info["callback"].call()
			_hold_actions.erase(action)

func stop_hold_action(action_id : String) -> bool:
	if _hold_actions.has(action_id): 
		_hold_actions.erase(action_id)
		return true
	
	return false

func start_hold_action(action_id : String, confirm_time : float, callback : Callable):
	_hold_actions[action_id] = {"start_time": Util.TIME, "confirm_time": confirm_time, "callback": callback}
	new_hold_action.emit(action_id)

func check_double_tap(action_id : String, confirm_time : float = Global.double_click_time) -> bool:
	if _double_tap_actions.has(action_id) and abs(Util.TIME - _double_tap_actions[action_id]["start_time"]) <= _double_tap_actions[action_id]["confirm_time"]:
		_double_tap_actions.erase(action_id)
		return true
	
	_double_tap_actions[action_id] = {"start_time": Util.TIME, "confirm_time": confirm_time}
	return false

func rebind(action : String, index : int = 0):
	var new_input : InputEvent = await get_next_input()
	if new_input.is_action_pressed("exit"): return
	var prev_input : InputEvent = null
	var current_events : Array[InputEvent] = InputMap.action_get_events(action)
	if index < current_events.size():
		prev_input = current_events[index]
		current_events[index] = new_input
		
	else:
		current_events.append(new_input)
	
	for concurrent_action : String in get_concurrent_actions_to(action):
		var concurrent_actions : Array[InputEvent] = InputMap.action_get_events(concurrent_action)
		for bind_idx : int in range(InputMap.action_get_events(concurrent_action).size()): 
			if concurrent_actions[bind_idx].as_text() == new_input.as_text():
				InputMap.action_erase_event(concurrent_action, concurrent_actions[bind_idx])
				if prev_input != null: InputMap.action_add_event(concurrent_action, prev_input)
	
	InputMap.action_erase_events(action)
	for event : InputEvent in current_events:
		InputMap.action_add_event(action, event)
	
	save_bindings()
	

func save_bindings():
	var bindings : Dictionary
	for action : String in InputMap.get_actions():
		bindings[action] = InputMap.action_get_events(action)
	
	File.save_var("bindings",  bindings)

func load_bindings():
	var bindings : Dictionary = File.load_var("bindings", {})
	if bindings == {}:
		save_bindings()
		return
	
	for action : String in bindings.keys():
		InputMap.action_erase_events(action)
		for event : InputEvent in bindings[action]:
			InputMap.action_add_event(action, event) 

func get_next_input() -> InputEvent:
	is_awaiting_input = true
	_new_input = null
	while _new_input == null: 
		await get_tree().process_frame
	
	is_awaiting_input = false
	return _new_input


func _input(event: InputEvent) -> void:
	if is_awaiting_input and (event is InputEventKey or event is InputEventMouseButton):
		_new_input = event
	
