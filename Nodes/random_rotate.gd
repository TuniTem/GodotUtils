@tool
extends Node3D
class_name RandomRotate

const AMPLITUDE_RANGE = [0.2, 1.5]
const PERIOD_RANGE = [0.2, 1.0]
const PHASE_RANGE = [0.0, TAU]
const OFFSET_RANGE = [2.0, -2.0]

@export_range(0.0, 10.0, 0.01) var speed : float = 1.0
@export_range(0.0, 10.0, 0.01) var acceleration : float = 1.0
var delta_rotate : Vector3 = Vector3.ZERO
var rot_speeds : Array[Dictionary]
var time : float = 0.0

func _ready() -> void:
	rot_speeds.clear()
	for i in range(3):
		rot_speeds.append({
			"amplitude" : randf_array(AMPLITUDE_RANGE),
			"period" : randf_array(PERIOD_RANGE),
			"phase" : randf_array(PHASE_RANGE),
			"offset" : randf_array(OFFSET_RANGE)
		})

func _process(delta: float) -> void:
	time += delta
	#print(rot_speeds)
	delta_rotate = Vector3(
		sin(time * rot_speeds[0]["period"] * acceleration + rot_speeds[0]["phase"]) * rot_speeds[0]["amplitude"] + rot_speeds[0]["offset"],
		sin(time * rot_speeds[1]["period"] * acceleration + rot_speeds[1]["phase"]) * rot_speeds[1]["amplitude"] + rot_speeds[1]["offset"],
		sin(time * rot_speeds[2]["period"] * acceleration + rot_speeds[2]["phase"]) * rot_speeds[2]["amplitude"] + rot_speeds[2]["offset"]
	)
	
	rotate_x(delta_rotate.x * delta * speed)
	rotate_y(delta_rotate.y * delta * speed)
	rotate_z(delta_rotate.z * delta * speed)
	#print(rotation)
	

func randf_array(betwixt : Array):
	return randf_range(betwixt[0], betwixt[1])
