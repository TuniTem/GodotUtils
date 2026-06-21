extends ScrollContainer
class_name SmoothScrollContainer
## Scroll container, now smoot!

@export var smooth_enabled: bool = true
@export_range(1.0, 30.0, 0.001, "or_greater") var follow_speed: float = 10.0
@export_range(1, 512, 1, "or_greater") var scroll_step: int = 80
@export_range(0.1, 4.0, 0.001) var snap_threshold: float = 0.5

var target_vertical: float = 0.0
var actual_vertical: float = 0.0:
	set(val):
		actual_vertical = val
		var offset : float = val - roundf(val)
		scroll_vertical = roundi(val)
		actual_vertical = scroll_vertical + offset

#var target_horizontal: float = 0.0

func _input(event: InputEvent) -> void:
	if not smooth_enabled or not is_visible_in_tree(): return
	if event is InputEventMouseButton and event.is_pressed():
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			target_vertical -= scroll_step
			usable = false
			clamp_target()
		
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			target_vertical += scroll_step
			usable = false
			clamp_target()

var usable : bool = true
func _process(delta: float) -> void:
	if not smooth_enabled: return
	if not usable:
		actual_vertical = lerpf(actual_vertical, target_vertical, delta * follow_speed)
		if Util.fequal(target_vertical, actual_vertical, 0):
			
			usable = true
	
	else: 
		target_vertical = scroll_vertical
		actual_vertical = scroll_vertical

func jump_to(to: int) -> void:
	scroll_vertical = to
	target_vertical = to 

func scroll_to_child(node: Control, duration : float = 0.5) -> void:
	if not is_ancestor_of(node):
		push_warning("Tried to scroll to node \"" + node.name + "\" that isnt a child of this container")
		return
	
	var tween : Tween = create_tween()
	tween.tween_property(self, "target_vertical", node.position.y + node.size.y, duration).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	

func clamp_target() -> void:
	var scroll_bar : VScrollBar = get_v_scroll_bar() 
	if is_instance_valid(scroll_bar):
		target_vertical = clamp(target_vertical, scroll_bar.min_value, scroll_bar.max_value -scroll_bar.size.y)
