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

func _process(delta: float) -> void:
	check_hold_actions()

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

func stop_hold_action(action_id : String):
	if _hold_actions.has(action_id): 
		_hold_actions.erase(action_id)

func start_hold_action(action_id : String, confirm_time : float, callback : Callable):
	_hold_actions[action_id] = {"start_time": Util.TIME, "confirm_time": confirm_time, "callback": callback}
	new_hold_action.emit(action_id)
