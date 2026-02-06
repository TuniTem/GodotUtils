extends Node
class_name ProgressAudio

# Experimental audio implementation, emulates a record scratching effect, where the player can run audio backwards and forwards on the record.
# Was origingally made to be hooked up to player position between two set points,
# but really could be used in anything if you turn on manual_progress!

# Created May 10, 2023, used in The Abstraction 
# (kinda) Refactored and commented Feb 6, 2026

@export var disable_threshold : float = 0.99 # when the progress auido will automatically cutout to prevent a clip
@export var manual_progress : bool = false # using the [progress] property
@export var track_object : Node # object to track the progress of between start and end, does nothing if manual progress is enabled

# enable edited children, add all audio and set start and end:
@onready var forward: AudioStreamPlayer = $forward # see https://youtu.be/e8-_I8EL1xI
@onready var backward: AudioStreamPlayer = $backwards # reversed, seperately exported version of forward, see https://youtu.be/GFRY62iHYkA
@onready var hum: AudioStreamPlayer = $hum # a constant hum that plays while enabled, used to make a good base for the sound, so theres not complete silence ever
@onready var ambient: AudioStreamPlayer = $ambient # Something that plays with the hum to add more life to the enviroment, but cuts out when forward/backward are playing
@onready var start: Marker3D = $start # 3D position where the beginning of the forward track should play
@onready var end: Marker3D = $end # 3D position where the end of the forward track should play

var progress : float = 0.0
var prev_progress : float = 0.0

var audio_length : float = 10.0
var ambient_volume : float = 0.0
var disable : bool = false

func _ready():
	ambient_volume = ambient.volume_db
	audio_length = forward.stream.get_length()

func _physics_process(delta):
	if not disable:
		if not manual_progress:
			var start_dist : float = start.global_position.distance_to(Global.player.global_position)
			var end_dist : float = end.global_position.distance_to(Global.player.global_position)
			var length : float = start.global_position.distance_to(end.global_position)
			var distance_difference_normalized = (start_dist - end_dist) / length
			progress = distance_difference_normalized / 2.0 + 0.5
		
		if progress == prev_progress:
			forward.stop()
			backward.stop()
			ambient.volume_db = ambient_volume
			
		else: 
			ambient.volume_db = -INF
		
		if progress > prev_progress and not forward.playing:
			backward.stop()
			forward.play(audio_length * progress)
		
		if progress < prev_progress and not backward.playing:
			forward.stop()
			backward.play(audio_length * (1.0 - progress))
		
		if progress > disable_threshold:
			disable = true
			
			
		var audio_start = audio_length * progress
		var delta_progress = progress - prev_progress
		var audio_end = audio_length * (progress + delta_progress)
		forward.pitch_scale = clamp((audio_end - audio_start) / delta, 0.01, 5.0)
		
		audio_start = audio_length * progress
		delta_progress = progress - prev_progress
		end = audio_length * (progress - delta_progress)
		backward.pitch_scale = clamp((audio_end - audio_start) / delta, 0.01, 5.0)
		
		prev_progress = progress
		
	else:
		for child in get_children():
			if child is AudioStreamPlayer:
				if child.volume_db > -20.0:
					child.volume_db = clamp(linear_to_db(db_to_linear(child.volume_db) - delta * 2), -20, 6)
					
				else: 
					child.volume_db = -INF

func update_progress(to : float):
	assert(to < 1.0 and to > 0.0)
	progress = to
