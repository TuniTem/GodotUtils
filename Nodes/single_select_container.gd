extends BoxContainer
class_name SingleSelectContainer

## Any buttons found outside the children of this node 
@export var external_buttons : Array[Control]
@export var only_use_external_buttons : bool = false

@export var default_pressed : Control
@export var allow_none_selected : bool = false


var buttons : Array[Control]
var last_selected_node : Control
var last_selected_id : String:
	get():
		if last_selected_node != null:
			return last_selected_node.name
		else:
			return ""

signal selection_updated(id : String)


func _ready() -> void:
	var children_buttons : Array[Control]
	if not only_use_external_buttons:
		for child in Util.get_all_children(self)
	
	for button : Control in external_buttons:
		assert(button is Button or button is ImageButton)
		button.toggle_mode = true
		if button == default_pressed:
			button.button_pressed = true
			last_selected_node = button
			
		button.pressed.connect(_on_any_button_pressed.bind(button))

func _on_any_button_pressed(button : Control):
	for test_button : Control in buttons:
		if button == test_button:
			button.button_pressed = not allow_none_selected or button != last_selected_node
			if button.button_pressed:
				last_selected_node = button
			else:
				last_selected_node = null
			
			selection_updated.emit(last_selected_id)
				
		else: test_button.button_pressed = false
		
