@tool
extends Control
class_name DrawRadialProgress

@export_range(0.0, 1.0, 0.001) var value : float = 1.0

@export_range(0.0, 360.0, 0.001, "radians_as_degrees") var rotation_offset : float
@export_range(0.01, 180.0, 0.001, "radians_as_degrees") var arc : float = PI

@export var steps : int = -1

@export_category("Line")
@export var color : Color = Color.LIGHT_GREEN
@export var gradient : Gradient
@export_range(-1, 200, 1) var width : int = 50
@export_range(-1, 2000, 1) var radius : int = 200

func _process(delta: float) -> void:
	queue_redraw()

func _draw() -> void:
	var modified_value : float = value
	if steps > 0:
		modified_value = snappedf(value, 1.0 / steps)
	
	draw_arc(
		Vector2.ZERO, 
		radius, 
		rotation_offset - arc, 
		lerpf(rotation_offset - arc, rotation_offset + arc, modified_value), 
		128, gradient.sample(modified_value) if gradient != null else color, 
		width, true
	)
