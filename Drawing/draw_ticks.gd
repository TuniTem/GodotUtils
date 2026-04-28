@tool
extends Node2D
class_name DrawTicks

@export var COLOR : Color = Color(1.0, 1.0, 1.0, 1.0): 
	set(val): 
		COLOR = val
		queue_redraw()

@export var RADIUS : float = 400: 
	set(val): 
		RADIUS = val
		queue_redraw()

@export var MAX_LENGTH : float = 20: 
	set(val): 
		MAX_LENGTH = val
		queue_redraw()

@export var LINE_MULT : Array = [1.0, 0.75, 0.3]: 
	set(val): 
		LINE_MULT = val
		queue_redraw()

@export var ARC : Array = [PI, PI + PI / 2.0]: 
	set(val): 
		ARC = val
		queue_redraw()

@export var NUM_LARGE_TICKS : int = 5: 
	set(val): 
		NUM_LARGE_TICKS = val
		queue_redraw()


func _draw() -> void:
	var arc_size : float = ARC[0] - ARC[1]
	var delta_angle : float = arc_size / (NUM_LARGE_TICKS * 10 + 1)
	var count : int = 0
	for i in range(NUM_LARGE_TICKS * 10 + 1):
		var theta : float = ARC[0] + delta_angle * i
		draw_line(Vector2.from_angle(theta) * RADIUS, Vector2.from_angle(theta) * (RADIUS - MAX_LENGTH * LINE_MULT[0 if count % 10 == 0 else (1 if count % 5 == 0 else 2)]), COLOR, -3, true)
		count += 1
	
	
