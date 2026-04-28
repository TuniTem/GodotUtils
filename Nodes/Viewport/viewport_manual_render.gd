@tool
extends SubViewport
class_name ManualViewport

@export_tool_button("Render Viewport", "ArrowRight") var render_action : Callable = render

func _ready() -> void:
	render_target_update_mode = SubViewport.UPDATE_ONCE

func render():
	if render_target_update_mode == SubViewport.UPDATE_ALWAYS: return
	render_target_update_mode = SubViewport.UPDATE_ALWAYS
	await get_tree().process_frame
	render_target_update_mode = SubViewport.UPDATE_DISABLED
