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
