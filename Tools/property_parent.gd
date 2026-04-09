@tool
extends Node
class_name PropertyParent

const DEFAULT_PROPERTY : Dictionary = {
	"remote_property" : "",
	"local_property" : "",
	"offset" : 0.0,
	"multiplier" : 1.0,
	"valid" : false
}


@export var target : Node

@export_category("Properties")
@export_tool_button("Add New Property", "Add") var new_property_action : Callable = Callable(add_property)
@export var properties : Array[Dictionary] = []#:
	#set(val):
		#properties = val
		#for property : Dictionary in properties:
			#property["valid"] = false


func add_property():
	
	properties.append(DEFAULT_PROPERTY.duplicate())
	

func _process(delta: float) -> void:
	var parent : Node = get_parent()
	if target:
		for property : Dictionary in properties:
			var remote_property : String = property["remote_property"]
			var local_property : String = property["local_property"]
			var offset : Variant = property["offset"]
			var multiplier : float = property["multiplier"]
			var valid : bool = property["valid"]
			if valid:
				parent.set_indexed(local_property, (target.get_indexed(remote_property) + offset) * multiplier )
			
			elif parent.get_indexed(local_property) != null and target.get_indexed(remote_property) != null:
				property["valid"] = true
				
				
		
