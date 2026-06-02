extends AnimationPlayer
class_name ParallelAnimationPlayer
## Needs testing

var animation_nodes : Dictionary[String, AnimationPlayer]


func _ready() -> void:
	for animation : String in get_animation_list():
		var inst : AnimationPlayer = self.duplicate()
		inst.set_script("")
		inst.name = animation
		animation_nodes[animation] = inst
		
		add_child(inst)

func _call_parallel(anim_name : String, function : String, args : Array):
	animation_nodes[anim_name].callv(function, args)

@warning_ignore("native_method_override")
func play(anim_name: StringName = &"", custom_blend: float = -1, custom_speed: float = 1.0, from_end: bool = false):
	_call_parallel(anim_name, "play", [anim_name, custom_blend, custom_speed, from_end])

@warning_ignore("native_method_override")
func play_backwards(anim_name: StringName = &"", custom_blend: float = -1):
	_call_parallel(anim_name, "play_backwards", [anim_name, custom_blend])

func stop_animation(anim_name: StringName = &"", keep_state: bool = false):
	_call_parallel(anim_name, "stop", [keep_state])

@warning_ignore("native_method_override")
func stop(keep_state: bool = false):
	for key : String in animation_nodes.keys():
		animation_nodes[key].stop(keep_state)

@warning_ignore("native_method_override")
func is_playing() -> bool:
	for key : String in animation_nodes.keys():
		if animation_nodes[key].is_playing():
			return true
		
	return false
