extends Node
class_name RigidbodyAudio
# Audio simulation scrpit for dynamic rigidbodies, tries to emulate the physicality of real objects
# Meant to be used for rigidbodies, could work for other moving objects maybe though!
# Just attatch this to a moving node, set editable children, add the audio and play with the settings
# See https://youtu.be/2dovlGf-QlQ

const MIN_VELOCITY = 0.5
const DRAG_BUFFER = 0.2 
const DRAG_DISABLE_DISTANCE = 10.0
const DRAG_DISABLE_TIME = 0.6

@export var max_slide_velocity : float = 5.0 # the velcity an object needs to be sliding at to play hte slide at the loudest set volume
@export var heavy_threshold = 5.0
@export var max_magnitude = 10.0

@onready var parent : = get_parent()
@onready var heavy_fall: AudioStreamPlayer = $HeavyFall
@onready var light_fall: AudioStreamPlayer = $LightFall
@onready var drag: AudioStreamPlayer = $Drag
@onready var light_bump: AudioStreamPlayer = $LightBump
@onready var heavy_bump: AudioStreamPlayer = $HeavyBump

var prev_y_vel = 0.0
var prev_collided := []

var rng = RandomNumberGenerator.new()
var dragging := false 
var bump_disabled = true

var drag_timeout = 0.2
var drag_time = 0.0

func _ready():
	for child in get_children():
		child.bus = "SFX"
	
	if parent.name == "root": free()
	randomize()
	parent.contact_monitor = true
	parent.max_contacts_reported = 5
	parent.add_to_group("bumpables")
	await get_tree().create_timer(1.0).timeout
	bump_disabled = false

var prev_bump_disabled = false
func _process(delta):
	var velocity : Vector3 = parent.linear_velocity
	var magnitude : float = velocity.length()
	var y_vel : float = abs(velocity.y)
	if not bump_disabled and prev_bump_disabled:
		for child in get_children():
			if child.name != "AudioStreamPlayer":
				child.volume_db = linear_to_db(child.vol_modifier)
	
	#fall sounds
	if magnitude > MIN_VELOCITY:
		if prev_y_vel > MIN_VELOCITY/2.0 and prev_y_vel - y_vel > MIN_VELOCITY / 2.0 and not bump_disabled:
			if prev_y_vel > heavy_threshold and not heavy_fall.playing:
				heavy_fall.volume_db = linear_to_db(clamp(prev_y_vel / max_magnitude, 0.0, 1.0) * heavy_fall.vol_modifier)
				heavy_fall.pitch_scale = 1 + rng.randf_range(-0.15, 0.15)
				heavy_fall.play()
			
			elif not light_fall.playing:
				light_fall.volume_db = linear_to_db(clamp(prev_y_vel / heavy_threshold, 0.0, 1.0) * light_fall.vol_modifier)
				light_fall.pitch_scale = 1 + rng.randf_range(-0.15, 0.15)
				light_fall.play()

		elif y_vel < MIN_VELOCITY / 2.0 and not dragging and not bump_disabled:
			dragging = true
			drag_time = 0.0
			drag_timeout = DRAG_BUFFER
			drag.play()

		var bodies = parent.get_colliding_bodies()
		var temp = []
		for body in bodies:
			if body.is_in_group("bumpables") and not prev_collided.has(body) and not bump_disabled:
				temp.append(body)
				var combined_mag = magnitude + body.linear_velocity.length()
				if combined_mag > heavy_threshold and not heavy_bump.playing and not dragging:
					heavy_bump.volume_db = linear_to_db(clamp(combined_mag / max_magnitude, 0.0, 1.0) * heavy_bump.vol_modifier)
					heavy_bump.pitch_scale = 1 + rng.randf_range(-0.15, 0.15)
					heavy_bump.play()
				
				elif not light_bump.playing and not dragging:
					light_bump.volume_db = linear_to_db(clamp(combined_mag / heavy_threshold, 0.0, 1.0) * light_bump.vol_modifier)
					light_bump.pitch_scale = 1 + rng.randf_range(-0.15, 0.15)
					light_bump.play()
		
		prev_collided = temp
	
	if drag_timeout > 0.0:
		drag_timeout -= delta
	
	if dragging and not bump_disabled:
		drag_time += delta
		if parent.is_in_group("bugged") and drag_time > DRAG_DISABLE_TIME and parent.global_position.distance_to(Global.player.global_position) > DRAG_DISABLE_DISTANCE: 
			parent.linear_velocity = Vector3.ZERO
		
		drag.volume_db = linear_to_db(clamp((magnitude - MIN_VELOCITY) / max_slide_velocity, 0.0, 1.0) * drag.vol_modifier)
		
		if not drag.playing: 
			drag.play()
		
		if ((magnitude < MIN_VELOCITY or y_vel > MIN_VELOCITY / 2.0) and drag_timeout < 0.0):
			dragging = false
			drag.stop()
	
	if bump_disabled:
		for child in get_children():
			child.volume_db = -INF
	
	prev_y_vel = y_vel
	prev_bump_disabled = bump_disabled

func set_bump(on : bool):
	bump_disabled = !on
		
