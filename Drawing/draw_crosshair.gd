@tool
class_name DrawCrosshair extends Node2D

@onready var crosshair_anims: AnimationPlayer = $CrosshairAnims

@export_category("toggle")
@export var crosshair : bool 
@export var square : bool 
@export var circle : bool 
@export var dot : bool 

@export_category("general")
@export var AUTO_CENTER : bool = false
@export var COLOR : Color = Color(1.0, 1.0, 1.0, 1.0)
@export var FLASH_COLOR : Color = Color(1.0, 1.0, 1.0, 1.0)
@export var FLASH_SPEED : float = 1.0
@export_range(0.0, 360.0, 22.5) var ROTATION : float = 0.0:
	set(val):
		if FREE_ROTATION != val: FREE_ROTATION = val
		ROTATION = val
		rotation_degrees = ROTATION
@export_range(0.0, 360.0) var FREE_ROTATION : float = 0.0:
	set(val):
		FREE_ROTATION = val
		if ROTATION != val: ROTATION = val
		rotation_degrees = ROTATION
@export var LINE_THICKNESS : int = -1
@export var TRANSITION_SPEED : float = 1.0
@export var TRANSITION_CURVE : Curve
@export var run_anims : bool = true

@export_category("crosshair")
@export var CROSS_RADIUS : float = 400
@export_range(0.0, 200.0) var CROSS_MAX_LENGTH : float = 20
@export var CROSS_ALL_MAX : bool = false
@export var CROSS_LINE_MULT : Array[float] = [1.0, 0.75, 0.3]
@export var CROSS_IGNORE_FLASH : bool = false

@export_category("square")
@export var SQUARE_SEPERATED : bool = true
@export var SQUARE_DASHED : bool = false
@export var SQUARE_DASHED_AMOUNT : int = 20
@export_range(10.0, 400.0) var SQUARE_SIZE : float = 200.0
@export_range(0.0, 200.0) var SQUARE_DRAW_DIST : float = 20.0
@export_range(0.0, 0.25) var SQUARE_TRANS_DELAY : float = 0.1
@export_range(-10.0, 10.0) var SQUARE_TRANS_EASE_AMMOUNT : float = 4.0
@export var SQUARE_TRANS_DIST : float = 50.0
@export var SQUARE_IGNORE_FLASH : bool = false

@export_category("circle")
@export_range(1.0, 400.0) var CIRCLE_RADIUS : float = 400.0
@export_range(1, 10) var CIRCLE_ITERATIONS : int = 1
@export var CIRCLE_ITERATION_COLOR_MULT : Color = Color(1.0, 1.0, 1.0, 1.0)
@export_range(0.0, 3.0) var CIRCLE_ITERATION_OFFSET : float = 1.0
@export var CIRCLE_IGNORE_FLASH : bool = false

@export_category("dot")
@export var DOT_SIZE : float = 10.0
@export_range(0.0, 1.0) var DOT_ALPHA : float = 1.0
@export var DOT_IGNORE_FLASH : bool = false

var transitions : Dictionary = {
	"crosshair" : 0.0,
	"square" : 0.0,
	"circle" : 0.0,
	"dot" : 0.0
}

var curr_color : Color = Color.WHITE

func _process(delta: float) -> void:
	for key in transitions.keys():
		if transitions[key] != float(get(key)):
			transitions[key] = lerp(transitions[key], float(get(key)), delta * TRANSITION_SPEED)
			if abs(transitions[key] - float(get(key))) < Util.EPSILON:
				transitions[key] = float(get(key))
	
	if AUTO_CENTER:
		position = get_viewport_rect().size / 2.0
	else:
		position = Vector2.ZERO
	
	curr_color = curr_color.lerp(COLOR, delta * FLASH_SPEED)
	queue_redraw()

func _draw() -> void:
	if transitions["crosshair"] != 0.0:
		var num_lines : int = pow(2, CROSS_LINE_MULT.size())
		var delta_angle : float = TAU / float(num_lines)
		var idx : Array = crosshair_pattern(CROSS_LINE_MULT.size())
		
		for i in range(num_lines):
			var theta : float = delta_angle * i
			draw_line(Vector2.from_angle(theta) * CROSS_RADIUS, Vector2.from_angle(theta) * (CROSS_RADIUS - CROSS_MAX_LENGTH * (CROSS_LINE_MULT[idx[i]] if not CROSS_ALL_MAX else 1.0) * transitions["crosshair"]), COLOR if CROSS_IGNORE_FLASH else curr_color, LINE_THICKNESS, false)
	
	if transitions["square"] != 0.0:
		if SQUARE_SEPERATED:
			var bb : Vector2 = Vector2.ONE * SQUARE_SIZE
			var dd : float = SQUARE_DRAW_DIST
			var lines : Array[Array] = [ 
				[bb, bb + Vector2(0.0, -dd), 0], [bb, bb + Vector2(-dd, 0.0), 0],
				[bb * Vector2(-1.0, 1.0), bb * Vector2(-1.0, 1.0) + Vector2(0.0, -dd), 1], [bb * Vector2(-1.0, 1.0), bb * Vector2(-1.0, 1.0) + Vector2(dd, 0.0), 1],
				[bb * Vector2(-1.0, -1.0), bb * Vector2(-1.0, -1.0) + Vector2(0.0, dd), 2], [bb * Vector2(-1.0, -1.0), bb * Vector2(-1.0, -1.0) + Vector2(dd, 0.0), 2],
				[bb * Vector2(1.0, -1.0), bb * Vector2(1.0, -1.0) + Vector2(0.0, dd), 3], [bb * Vector2(1.0, -1.0), bb * Vector2(1.0, -1.0) + Vector2(-dd, 0.0), 3]
			]
			
			var trans_dist_ratio : float = (SQUARE_SIZE - SQUARE_TRANS_DIST) / SQUARE_SIZE
			for line : Array in lines:
				var start : float = SQUARE_TRANS_DELAY * (line[2])
				var end : float = SQUARE_TRANS_DELAY * (line[2] + 1)
				var trans_curve_adjusted : float = clamp(remap(transitions["square"], start, end, 0.0, 1.0), 0.0, 1.0)
				#var trans_adjusted : float = remap(pow(trans_curve_adjusted, SQUARE_TRANS_EASE_AMMOUNT), 0.0, 1.0, trans_dist_ratio, 1.0)
				if SQUARE_DASHED:
					draw_dashed_line(line[0] * (1.25 - 0.25 * transitions["square"]), line[1] * (1.25 - 0.25 * transitions["square"]), (COLOR * transitions["square"]) if SQUARE_IGNORE_FLASH else (curr_color * transitions["square"]), LINE_THICKNESS, SQUARE_DASHED_AMOUNT)
				
				else:
					draw_line(line[0] * (1.25 - 0.25 * transitions["square"]), line[1] * (1.25 - 0.25 * transitions["square"]), (COLOR * transitions["square"]) if SQUARE_IGNORE_FLASH else (curr_color * transitions["square"]), LINE_THICKNESS)
				
		
		else:
			var bb : Vector2 = Vector2.ONE * SQUARE_SIZE
			var lines : Array[Array] = [ 
				[bb, bb * Vector2(1.0, -1.0)], [bb * Vector2(1.0, -1.0), bb * Vector2(-1.0, -1.0)],
				[bb * Vector2(-1.0, -1.0), bb * Vector2(-1.0, 1.0)], [bb * Vector2(-1.0, 1.0), bb],
			]
			
			var trans_dist_ratio : float = (SQUARE_SIZE - SQUARE_TRANS_DIST) / SQUARE_SIZE
			for line : Array in lines:
				var trans_adjusted : float = clamp(remap(pow(transitions["square"], SQUARE_TRANS_EASE_AMMOUNT), 0.0, 1.0, trans_dist_ratio, 1.0), trans_dist_ratio, 1.0)
				if SQUARE_DASHED:
					draw_dashed_line(line[0] * trans_adjusted, line[1] * trans_adjusted, (COLOR * TRANSITION_CURVE.sample(transitions["square"])) if SQUARE_IGNORE_FLASH else (curr_color * TRANSITION_CURVE.sample(transitions["square"])), LINE_THICKNESS, SQUARE_DASHED_AMOUNT)
				
				else:
					draw_line(line[0] * trans_adjusted, line[1] * trans_adjusted, (COLOR * TRANSITION_CURVE.sample(transitions["square"])) if SQUARE_IGNORE_FLASH else (curr_color * TRANSITION_CURVE.sample(transitions["square"])), LINE_THICKNESS)
				
			
			
		
	
	if transitions["circle"] != 0.0:
		var curr_clr : Color = COLOR if SQUARE_IGNORE_FLASH else curr_color
		var curr_rad : float = CIRCLE_RADIUS
		for i in range(CIRCLE_ITERATIONS):
			draw_circle(Vector2.ZERO, curr_rad * transitions["circle"], curr_clr * transitions["circle"], false, LINE_THICKNESS)
			curr_clr *= CIRCLE_ITERATION_COLOR_MULT
			curr_rad *= CIRCLE_ITERATION_OFFSET
	
	if transitions["dot"] != 0.0:
		draw_circle(Vector2.ZERO, DOT_SIZE * transitions["dot"], Color(COLOR, COLOR.a * DOT_ALPHA) if DOT_IGNORE_FLASH else Color(curr_color, curr_color.a * DOT_ALPHA), true, -1, true)

func flash(intensity : float = 1.0, color : Color = FLASH_COLOR):
	curr_color = color * intensity

func switch_anim(to : String, blend : float = 0.0):
	crosshair_anims.play(to)
	match to:
		"idle":
			await get_tree().create_timer(0.1).timeout
			#flash(0.3)
		"focus":
			await get_tree().create_timer(0.1).timeout
			flash(1.0, Color("fff299"))
		"select":
			await get_tree().create_timer(0.2).timeout
			flash(20.0)
			#await get_tree().create_timer(0.1).timeout
			#flash(0.1)
			#await get_tree().create_timer(0.05).timeout
			#flash(1.5)
		

func crosshair_pattern(n: int) -> Array:
	if n <= 0:
		return []
	
	var block := [0] 
	for k in range(2, n + 1):
		var tail := []
		for i in range(1, block.size()):
			tail.append(block[i])
		block = block + [k - 1] + tail
	
	return block + block

#var prev_breathe : Dictionary[String, Array] = {}
#func update_breathe():
	#for key : String in breathe.keys():
		#if prev_breathe == {} or breathe[key] != prev_breathe[key]:
			#var info : Array = breathe[key]
			#if info.size() == 3:
				#if not info[0]:
					#Util.set_breathe_property_subscribe(self, key, false, true)
				#else:
					#Util.breathe_property(self, key, info[1], info[2], Util.BreatheMode.MULTIPLY, randf() * info[1])
			#elif info.size() == 4:
				#if not info[0]:
					#Util.set_breathe_method_subscribe(breathe_array, false, true)
				#else:
					#Util.breathe_method(breathe_array, CROSS_LINE_MULT[breathe["CROSS_LINE_MULT"][3]], info[1], info[2], Util.BreatheMode.MULTIPLY)
				#
				#
	#
	#prev_breathe = breathe
#
#
#func breathe_array(value):
	#CROSS_LINE_MULT[breathe["CROSS_LINE_MULT"][3]] = value
