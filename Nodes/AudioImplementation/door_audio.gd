extends Node
class_name DoorAudio
# Physicalized door audio implementation
# Parent me to a door, set to editable children, and add audio! Play with the exports

const MIN_VELOCITY = 0.1

@export var VOLUME_VARIANCE = [0.05, 0.25] # each door gets randomized
@export var MAX_MAGNITUDE = 5.0 # max movement to play the loudest volume the door will go

@onready var parent : RigidBody3D = get_parent()

var playable := true
var initial_pos := Vector3.ZERO

var squeek : AudioStreamPlayer
var bump : AudioStreamPlayer
var max_volume : float = 1.0

func _ready():
	for child in get_children():
		child.bus = "SFX"
	
	initial_pos = parent.global_position
	parent.contact_monitor = true
	parent.max_contacts_reported = 5
	parent.add_to_group("bumpables")
	
	#different doors different sounds
	bump = [$Bump1, $Bump2].pick_random()
	bump.volume_db = linear_to_db(bump.vol_modifier)
	
	if randi_range(1, 5) >= 4: squeek = $SqueekSet1
	else: squeek = $SqueekSet2
	
	max_volume = randf_range(VOLUME_VARIANCE[0], VOLUME_VARIANCE[1])
	squeek.volume_db = -INF

var prev_locked = false
var prev_magnitude = 0.0

# I love how these keep getting simpiler LOL
# Door Audio Attempt 3:
func _process(delta):
	var magnitude : float = parent.linear_velocity.length()
	if abs(magnitude - prev_magnitude) > MIN_VELOCITY * 2 and not bump.playing:
		playable = true
		bump.volume_db = linear_to_db(clamp(abs(magnitude - prev_magnitude) / MAX_MAGNITUDE * bump.vol_modifier, 0.0, 1.0))
		#bump.pitch_scale = 1.0 + randf_range(0.3, 0.5)
		bump.play()
	
	if magnitude > MIN_VELOCITY * 10 and not squeek.playing and playable:
		playable = false
		#squeek.pitch_scale = 1.0 + randf_range(-0.1, 0.3)
		squeek.play()
	
	if magnitude < MIN_VELOCITY:
		squeek.stop()
	
	elif squeek.playing:
		squeek.volume_db = linear_to_db(clamp(max_volume * (magnitude / MAX_MAGNITUDE) * squeek.vol_modifier, 0.0, 1.0))
	
	prev_magnitude = magnitude

# Door Audio Attempt 2:

#	var magnitude : float = parent.linear_velocity.length()
#	if parent.global_position.distance_to(initpos) > 0.1 and playable:
#		playable = false
#		var sound = [$SlowSqueek, $FastSqueek].pick_random()
#		sound.pitch_scale = 1.0 + randf_range(-0.1,0.3)
#		sound.play()
#
#	if prev_magnitude-magnitude > MIN_VELOCITY:
#		for sound in [$SlowSqueek, $FastSqueek]:
#			sound.stop()
#
#	if magnitude < MIN_VELOCITY/2.0:
#		initpos = parent.global_position
#		playable = true
#
#	prev_magnitude = magnitude

# Door Audio Attempt 1:

#	if parent.get_node("../../").get("locked") != null:
#		if prev_locked and not parent.get_node("../../").get("locked"):
#			$Unlock.play()
#
#	var velocity : Vector3 = parent.linear_velocity
#	var magnitude : float = velocity.length()
#	if $FastSqueek.playing: $FastSqueek.volume_db = linear_to_db(clamp(magnitude/MAX, 0.0, 1.0)*$FastSqueek.vol_modifier)
#	elif $SlowSqueek.playing: $SlowSqueek.volume_db = linear_to_db(clamp(magnitude/FAST_THRESHOLD, 0.0, 1.0)*$SlowSqueek.vol_modifier)
#
#
#	if magnitude > MIN_VELOCITY/8.0:
#		var is_locked = parent.get_node("../../").get("locked")
#		if is_locked != null and is_locked and not $Locked.playing:
#			$Locked.play()
#
#
#	if magnitude > MIN_VELOCITY and not ($SlowSqueek.playing or $FastSqueek.playing):
#		if magnitude > FAST_THRESHOLD:
#			$FastSqueek.volume_db = linear_to_db(clamp(magnitude/MAX, 0.0, 1.0)*$FastSqueek.vol_modifier)
##			$FastSqueek.pitch_scale = clamp(magnitude/MAX, 0.0, 1.0)/5.0+0.9
#			$FastSqueek.play()
#			$SlowSqueek.stop()
#		else:
#			print(parent.get_parent().name)
#			$SlowSqueek.volume_db = linear_to_db(clamp(magnitude/FAST_THRESHOLD, 0.0, 1.0)*$SlowSqueek.vol_modifier)
#			$SlowSqueek.pitch_scale = 1.0 + randf_range(-0.1,0.3)
##			$SlowSqueek.pitch_scale = clamp(magnitude/FAST_THRESHOLD, 0.1, 1.0)
#			$SlowSqueek.play()
#
#	if abs(magnitude-prev_magnitude) > MIN_VELOCITY*2 and magnitude < MIN_VELOCITY:
#		$SlowSqueek.stop()
#		$FastSqueek.stop()
#		$Bump.pitch_scale = 1.0 + randf_range(-0.2,0.2)
#		$Bump.volume_db = linear_to_db($Bump.vol_modifier)
#		$Bump.play()
#
#	prev_locked = parent.get_node("../../").get("locked")
#	prev_magnitude = magnitude
