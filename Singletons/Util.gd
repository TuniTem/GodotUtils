@tool
extends Node
## Singleton used to extend godot's features

const COARSE_EPSILON : float = 0.01
const EPSILON : float  = 0.001
const FINE_EPSILON : float  = 0.00001
const FINEST_EPSILON : float  = 0.000000001
const _EPSILON_ARR : Array = [COARSE_EPSILON, EPSILON, FINE_EPSILON, FINEST_EPSILON]

enum BreatheMode {
	ADD,
	MULTIPLY
}

signal input_group_changed(to : String)

var TIME : float = 0.0
var active_promises : Array[Promise]
var input_group : String = "default"


var _breathe_properties : Dictionary[Array, Dictionary] = {}
var _breathe_methods : Dictionary[Callable, Dictionary] = {}
var _breathe_enabled : bool = false
var _run_every_counts : Dictionary[Array, int]


# [Object, property] : {
#    "init" : float
#    "wavelength_seconds" : float
#    "amplitude" : float
#    "min" : float
#    "max" : float
#    "mode" : breatheMode 
#}


func _process(delta: float) -> void:
	TIME += delta
	if _breathe_enabled:
		_sim_breathe()
		
	

# General Utility
## Returns a [Rect2] initialized from a [param position], and [param size]
func rect_from_center(position : Vector2, size : Vector2) -> Rect2:
	return Rect2(
		position + size / 2.0,
		size
	)

## Recursively returns all children of the specified node, the [param data] parameter is used for recursion and should not be set
func get_all_children(node : Node, data : Array = []):
	data.push_back(node)
	for child in node.get_children():
		data = get_all_children(child, data)
	
	return data

## Preforms a serach on an [Array] of [Array]s or [Dictionary]s, [param index] is the index to search in the sub-array/dictionary, [param key] is the value it's checking for.[br][br]
## Returns the array dictionary that has [param key] at [param index], or [param on_fail] if nothing is found.[br][br]
## If [param sub_key] is set, instead the value at [param sub_key] in the found sub array is returned.
func search(array : Array, index : Variant, key : Variant, duplicate : bool = false, on_fail : Variant = null, sub_index : Variant = -1):
	for item in array:
		if item[index] == key:
			if sub_index == -1:
				return item.duplicate() if duplicate else item
			else:
				return item[sub_index]
	
	return on_fail

## Checks if [param value] is between [param lower] and [param upper].
func between(value : Variant, lower : Variant, upper : Variant) -> bool:
	return value > lower and value < upper

## Pauses the function it is called in for a set amount of [param time], must be called with [code]await[/code]
func wait(time : float):
	await get_tree().create_timer(time).timeout
	return

## Combines an [Array] of [Signal]s into a single signal using a [Promise].[br][br]
## The returned signal emits when the specified [param mode] condition is met (when any or all signals complete).  
## Useful for awaiting multiple events simultaneously.
func compound_signal(signals : Array[Signal], mode : Promise.Mode = Promise.Mode.ANY) -> Signal:
	return Promise.new(signals, mode).completed

## Opens a file dialog and returns the selected file path and name in the format [b]\[path, file\][/b].[br][br]  
## Supports custom file modes, extensions, directories, and titles.[br]
## Remembers the last used directory via the [File] singleton.[br]
## Returns [code]["", ""][/code] if canceled or no valid file is selected.
func open_file_dialog(parent : Node, type : FileDialog.FileMode = FileDialog.FileMode.FILE_MODE_OPEN_FILE, extentions : PackedStringArray = [], directory : String = "last", title : String = ""):
	var dialog : FileDialog = FileDialog.new()
	dialog.access =FileDialog.ACCESS_FILESYSTEM
	if directory == "last": 
		dialog.current_path = File.load_var("last_dir", "C:/")
	else :
		dialog.current_path = directory
	#print(dialog.current_path)
	dialog.use_native_dialog = true
	var new_extentions : PackedStringArray
	for ext : String in extentions:
		new_extentions.append("*" + ext)
	
	dialog.filters = new_extentions
	dialog.file_mode = type
	if title != "":
		dialog.title = title
	
	parent.add_child(dialog)
	dialog.show()
	await compound_signal([dialog.file_selected, dialog.canceled])
	File.save_var("last_dir", dialog.current_path)
	if not dialog.current_path.contains("."):
		dialog.queue_free()
		return ["", ""]
	else:
		var out = [dialog.current_path, dialog.current_file]
		dialog.queue_free()
		return out

## Executes an action once every [param num_runs] calls for a given [param parent].[br]
## Returns [code]true[/code] if the interval is reached, otherwise [code]false[/code].[br][br]
## [param identifier] needs to be unique per [param node]
## Useful for periodically triggering behavior in _process().
func run_every(num_runs : int = 10, parent : Node = self, identifier : String = "default") -> bool:
	var key : Array = [parent, identifier]
	if not _run_every_counts.has(key):
		_run_every_counts[key] = -1
	
	_run_every_counts[key] += 1
	if _run_every_counts[key] > num_runs:
		_run_every_counts[key] = 0
		return true
	
	return false
		

# Input Groups
func set_input_group(to : String):
	input_group = to
	input_group_changed.emit(to)

func is_current_input_group(_input_group : String):
	return input_group == _input_group


# Breathing variables

## Returns a sine or cosine “breathing” oscillation based on [param wavelength_seconds], [param amplitude], and optional [param phase].[br][br]
## The oscillation continuously changes over time, useful for animating a breathing motion quickly or dynamically through code.
func breathe(wavelength_seconds : float, amplitude : float, use_sin : bool = true, phase : float = 0.0) -> float:
	if use_sin:
		return sin((TIME - phase) * wavelength_seconds * TAU ) * amplitude
	else:
		return cos((TIME - phase) * wavelength_seconds * TAU) * amplitude

## Returns a sine or cosine “breathing” oscillation based on [param wavelength_seconds], [param amplitude], and optional [param phase].[br][br]
## The oscillation will travel between [param min] and [param max][br][br]
## The oscillation continuously changes over time, useful for animating a breathing motion quickly or dynamically through code.
func breathe_remap(wavelength_seconds : float, min : float, max : float, use_sin : bool = true, phase : float = 0.0) -> float:
	return remap(breathe(wavelength_seconds, 1.0, use_sin, phase), -1.0, 1.0, min, max)

## Registers a property on an object to “breathe” automatically, called only once per property.[br][br]
## The property will add or multiply the inital value depending on [param mode].
func breathe_property(object : Object, property : StringName, wavelength_seconds : float, amplitude : float, mode : BreatheMode, phase : float = TIME, use_amplitude : bool = true, min : float = 0.0, max : float = 1.0, use_sin : bool = true):
	_breathe_enabled = true
	_breathe_properties[[object, property]] = {
		"init" : object.get(property) if not _breathe_properties.has([object, property]) else _breathe_properties[[object, property]]["init"],
		"wavelength_seconds" : wavelength_seconds,
		"min" : min if not use_amplitude else object.get(property) - amplitude,
		"max" : max if not use_amplitude else object.get(property) + amplitude,
		"use_sin" : use_sin,
		"phase" : phase,
		"mode" : mode,
		"subscribed" : true
	}

## Registers a method to “breathe” automatically, called only once per method.[br][br]
## The method is called every frame with the updated value, similar to [method breathe_property] but for callables.
## The property will add or multiply the inital value depending on [param mode].
func breathe_method(method : Callable, inital_value : float, wavelength_seconds : float, amplitude : float, mode : BreatheMode, phase : float = TIME, use_amplitude : bool = true, min : float = 0.0, max : float = 1.0, use_sin : bool = true):
	_breathe_enabled = true
	_breathe_methods[method] = {
		"init" : inital_value,
		"wavelength_seconds" : wavelength_seconds,
		"min" : min if not use_amplitude else inital_value - amplitude,
		"max" : max if not use_amplitude else inital_value + amplitude,
		"use_sin" : use_sin,
		"phase" : phase,
		"mode" : mode,
		"subscribed" : true
	}

## Enables or disables breathing for a specific property.
## If [param delete] is true, removes it entirely from tracking.  
## When unsubscribed, the property is reset to its initial value.
func set_breathe_property_subscribe(object : Object, property : StringName, subscribed : bool, delete : bool = false):
	if delete: 
		object.set(property, _breathe_properties[[object, property]]["init"])
		_breathe_properties.erase([object, property])
	elif _breathe_properties.has([object, property]):
		_breathe_properties[[object, property]]["subscribed"] = subscribed
		if not subscribed: object.set(property, _breathe_properties[[object, property]]["init"])
	else:
		printerr("Breathe property not found: " + str([object, property]))

## Enables or disables breathing for a specific method.  
## If [param delete] is true, removes it entirely from tracking.  
## When unsubscribed, the callable is invoked with its initial value.
func set_breathe_method_subscribe(method : Callable, subscribed : bool, delete : bool = false):
	if delete: 
		method.call(_breathe_methods[method]["init"])
		_breathe_methods.erase(method)
	elif _breathe_methods.has(method):
		_breathe_methods[method]["subscribed"] = subscribed
		if not subscribed: method.call(_breathe_methods[method]["init"])
	else:
		printerr("Breathe method not found: " + str(method))

func _sim_breathe():
	for property : Array in _breathe_properties.keys():
		var data : Dictionary = _breathe_properties[property]
		if data["subscribed"]:
			match data["mode"]:
				BreatheMode.ADD:
					property[0].set(property[1],
						data["init"] + breathe_remap(data["wavelength_seconds"], data["min"], data["max"], data["use_sin"])
					)
				BreatheMode.MULTIPLY:
					property[0].set(property[1],
						data["init"] * breathe_remap(data["wavelength_seconds"], data["min"], data["max"], data["use_sin"])
					)
	
	for property : Callable in _breathe_methods.keys():
		var data : Dictionary = _breathe_methods[property]
		if data["subscribed"]:
			match data["mode"]:
				BreatheMode.ADD:
					property.call(data["init"] + breathe_remap(data["wavelength_seconds"], data["min"], data["max"], data["use_sin"]))
				BreatheMode.MULTIPLY:
					property.call(data["init"] * breathe_remap(data["wavelength_seconds"], data["min"], data["max"], data["use_sin"]))

# Bus Managment

## Sets mute to [param mute] on the specified [param bus]
func set_mute_bus(bus : String, on : bool):
	var idx : int = AudioServer.get_bus_index(bus)
	AudioServer.set_bus_mute(idx, on)

## Toggles mute on the specified [param bus]
func toggle_mute_bus(bus : String):
	var idx : int = AudioServer.get_bus_index(bus)
	AudioServer.set_bus_mute(idx, not AudioServer.is_bus_mute(idx))

## Sets the [param volume] of the specified [param bus][br][br]
## If [param linear] is true, [param volume] is a linear volume, rather than in decibels
func set_bus_volume(bus : String, volume : float, linear : bool = true):
	var idx : int = AudioServer.get_bus_index(bus)
	if linear: AudioServer.set_bus_volume_linear(idx, volume)
	else: AudioServer.set_bus_volume_db(idx, volume)

## Returns the volume of the specified [param bus][br][br]
## If [param linear] is true, the returned volume is linear, rather than in decibel
func get_bus_volume(bus : String, linear : bool = true):
	var idx : int = AudioServer.get_bus_index(bus)
	if linear: AudioServer.get_bus_volume_linear(idx)
	else: AudioServer.get_bus_volume_db(idx)

## Adjusts the linear volume of the [param bus] by [param change] and clamps it between [param clamp_min] and [param clamp_max].[br] 
## Returns the new volume.
func change_bus_volume_linear(bus: String, change : float, clamp_min : float = 0.0, clamp_max : float = 1.0) -> float:
	var idx : int = AudioServer.get_bus_index(bus)
	var set_vol : float = AudioServer.get_bus_volume_linear(idx) + change
	set_vol = clampf(set_vol, clamp_min, clamp_max)
	AudioServer.set_bus_volume_linear(AudioServer.get_bus_index(bus), set_vol)
	return set_vol


# Float comparason
# Note: these funcs don't use each other in order to run quicker
## checks if [param a] == [param b], accounting for a customizable [param epsilon] index
func fequal(a : float, b : float, epsilon : int = 1) -> bool: 
	return absf(a - b) < _EPSILON_ARR[epsilon]

## checks if [param a] < [param b], accounting for a customizable [param epsilon] index
func fless(a : float, b : float, epsilon : int = 1) -> bool: 
	return a < b and not absf(a - b) < _EPSILON_ARR[epsilon]

## checks if [param a] > [param b], accounting for a customizable [param epsilon] index
func fgreat(a : float, b : float, epsilon : int = 1) -> bool:
	return a > b and not absf(a - b) < _EPSILON_ARR[epsilon]

## checks if [param a] <= [param b], accounting for a customizable [param epsilon] index
func fless_equal(a : float, b : float, epsilon : int = 1) -> bool:
	return a < b or absf(a - b) < _EPSILON_ARR[epsilon]

## checks if [param a] <= [param b], accounting for a customizable [param epsilon] index
func fgreat_equal(a : float, b : float, epsilon : int = 1) -> bool:
	return a > b or absf(a - b) < _EPSILON_ARR[epsilon]

## checks if [param a] == 0.0, accounting for a customizable [param epsilon] index
func fzero(a : float, epsilon : int = 1) -> bool:
	return absf(a) < _EPSILON_ARR[epsilon]
