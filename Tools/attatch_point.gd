extends Marker2D

@export var hooked_node : Node
@export var offset : Vector2

func _process(delta: float) -> void:
	hooked_node.global_position = global_position + offset
