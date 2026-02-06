class_name ImageButton
extends TextureRect

@export var pressed_color_mult : Color = Color.GRAY
@export var toggle_mode : bool = false
@export var toggle_mode_default : bool = false
@onready var button: Button = $Button

var original_color : Color
var toggled : bool 

signal button_down
signal button_up
signal pressed

func _ready() -> void:
	if not toggle_mode:
		button.button_down.connect(_update.bind(true))
		button.button_up.connect(_update.bind(false))
	else:
		toggled = toggle_mode_default
		#_update(toggled)
	
	button.pressed.connect(_on_button_pressed)
	original_color = self_modulate

func _on_button_pressed():
	pressed.emit()
	if toggle_mode:
		toggled = not toggled
		_update(toggled)

func _update(on : bool):
	if on: 
		self_modulate = pressed_color_mult * original_color
		button_down.emit()
	else: 
		self_modulate = original_color
		button_up.emit()
