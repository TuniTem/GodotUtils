@tool
extends AudioStreamPlayer
class_name TogglePlayer

@export_tool_button("Toggle and Play", "AudioStreamPlayer") var toggle_and_play : Callable = toggle_play
@export var toggled : bool = false

@export_category("On")
@export_tool_button("Play", "Play") var on_play : Callable = _play_audio.bind(true)
@export var on_stream : AudioStream = AudioStreamRandomizer.new()
@export_range(0.01, 4.0, 0.001, "or_greater") var on_pitch : float = 1.0
@export_range(-80.0, 24.0, 0.001, "suffix:dB", "exp") var on_volume : float = 0.0

@export_category("Off")
@export_tool_button("Play", "Play") var off_play : Callable = _play_audio.bind(false)
@export var off_stream : AudioStream = AudioStreamRandomizer.new()
@export_range(0.01, 4.0, 0.001, "or_greater") var off_pitch : float = 1.0
@export_range(-80.0, 24.0, 0.001, "suffix:dB", "exp") var off_volume : float = 0.0

func play_set_toggle(toggle : bool):
	toggled = toggle
	_play_audio(toggle)

func toggle_play():
	toggled = not toggled
	_play_audio(toggled)

func _play_audio(toggle : bool):
	stream = on_stream if toggle else off_stream
	pitch_scale = on_pitch if toggle else off_pitch
	volume_db = on_volume if toggle else off_volume
	
	play()
