@tool
extends SubViewport
class_name FPSViewport

@export var fps : int = -1:
	set(val):
		fps = val
		if fps <= 0: return
		if spf == (1.0 / float(fps)): return
		spf = 1.0 / float(fps)

@export var spf : float = -1.0:
	set(val):
		spf = val
		if spf <= 0: return
		if fps == round(1.0 / spf): return
		fps = round(1.0 / spf)

func _ready() -> void:
	render_target_update_mode = SubViewport.UPDATE_ONCE

var fps_timer : float = 0.0
func _process(delta: float) -> void:
	if spf > 0:
		fps_timer += delta
		if fps_timer > spf:
			fps_timer -= spf
			render_target_update_mode = SubViewport.UPDATE_ALWAYS
		
		else:
			render_target_update_mode = SubViewport.UPDATE_DISABLED
		
	else:
		render_target_update_mode = SubViewport.UPDATE_ALWAYS
