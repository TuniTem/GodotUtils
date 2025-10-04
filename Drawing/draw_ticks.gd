@tool
extends Node2D

@export var COLOR : Color = Color(1.0, 1.0, 1.0, 1.0)
@export var RADIUS : float = 400
@export var MAX_LENGTH : float = 20
@export var LINE_MULT : Array = [1.0, 0.75, 0.3]
@export var ARC : Array = [PI, PI + PI / 2.0]
@export var NUM_LARGE_TICKS : int = 5

func _process(delta: float) -> void:
	queue_redraw()

func _draw() -> void:
	var arc_size : float = ARC[0] - ARC[1]
	var delta_angle : float = arc_size / (NUM_LARGE_TICKS * 10 + 1)
	var count : int = 0
	for i in range(NUM_LARGE_TICKS * 10 + 1):
		var theta : float = ARC[0] + delta_angle * i
		draw_line(Vector2.from_angle(theta) * RADIUS, Vector2.from_angle(theta) * (RADIUS - MAX_LENGTH * LINE_MULT[0 if count % 10 == 0 else (1 if count % 5 == 0 else 2)]), COLOR, -3, true)
		count += 1
	
	
