extends AudioStreamPlayer
class_name AlphabeticalVoice

@export var streams : Dictionary[String, AudioStream] = {
	"a" : null,
	"b" : null,
	"c" : null,
	"d" : null,
	"e" : null,
	"f" : null,
	"g" : null,
	"h" : null,
	"i" : null,
	"j" : null,
	"k" : null,
	"l" : null,
	"m" : null,
	"n" : null,
	"o" : null,
	"p" : null,
	"q" : null,
	"r" : null,
	"s" : null,
	"t" : null,
	"u" : null,
	"v" : null,
	"w" : null,
	"x" : null,
	"y" : null,
	"z" : null,
	" " : null
}

@export_range(0.0, 1.0) var pitch_variation = 0.0

var players : Dictionary[String, AudioStreamPlayer] = {}

var default_pitch : float = 1.0 

func _init() -> void:
	default_pitch = pitch_scale

#func _ready() -> void:
	#for letter : String in streams.keys():
		#var player : AudioStreamPlayer = AudioStreamPlayer.new()
		#player.max_polyphony = 3
		#player.bus = "SFX"
		#player.volume_db = volume_db
		#player.stream = streams[letter]
		#player.name = letter
		#players[letter] = player
		#add_child(player)

func play_letter(letter : String):
	#var player : AudioStreamPlayer = players[letter]
	pitch_scale = default_pitch + randf_range(-pitch_variation, pitch_variation)
	stream = streams[letter]
	play()
