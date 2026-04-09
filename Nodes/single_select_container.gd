extends BoxContainer
class_name SingleSelectContainer

## Any buttons found outside the children of this node 

@export var default_pressed_id : String
@export var external_buttons : Array[Control]
@export var only_use_external_buttons : bool = false
@export var allow_none_selected : bool = false
@export var update_id : String = ""
#@export_category("Persistance")
#@export var persistant : bool = false
#@export var persistant_id : String


var buttons : Array[Control]
var last_selected_node : Control
var last_selected_id : String:
	get():
		if last_selected_node != null:
			return last_selected_node.name.to_lower()
		else:
			return ""

signal selection_updated(active_button_id : String, update_id : String)

func _ready() -> void:
	#if persistant_id == "": 
		#persistant_id = name
	
	#var persistant_button_id : String = File.load_var(persistant_id, "") if persistant else ""
	var children_buttons : Array[Control]
	if not only_use_external_buttons:
		for child in Util.get_all_children(self):
			if child is Button or child is ImageButton:
				children_buttons.append(child)
	
	
	for button : Control in external_buttons + children_buttons:
		assert(button is Button or button is ImageButton)
		button.toggle_mode = true
		buttons.append(button)
		if (button.name.to_lower() == default_pressed_id): # and persistant_button_id == "") or (persistant and persistant_button_id == button.name):
			button.button_pressed = true
			last_selected_node = button
			
		button.pressed.connect(_on_any_button_pressed.bind(button))
	
	#selection_updated.emit(last_selected_id, update_id)

func update_button_state(to_id : String, on : bool = true):
	for button in buttons:
		if button.name.to_lower() == to_id:
			button.button_pressed = on
		elif on:
			button.button_pressed = false

func _on_any_button_pressed(button : Control):
	for test_button : Control in buttons:
		if button == test_button:
			button.button_pressed = not allow_none_selected or button != last_selected_node
			if button.button_pressed:
				last_selected_node = button
			else:
				last_selected_node = null
			
			#if persistant:
				#File.save_var(persistant_id, last_selected_id)
			
			selection_updated.emit(last_selected_id, update_id)
				
		else: test_button.button_pressed = false
		
