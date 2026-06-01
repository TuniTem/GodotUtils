extends RichTextEffect
class_name CurveEffect
var bbcode := "curve"
# Format: [spacefloat amp=8 rot_amp=6 min_speed=0.4 max_speed=1.2]
func _process_custom_fx(char_fx: CharFXTransform) -> bool:
	var idx: int = char_fx.relative_index

	var amplitude: float = float(char_fx.env.get("amp", 1.0))
	var length: float = float(char_fx.env.get("len", 5)) # effect mult
	
	char_fx.offset = Vector2.from_angle(idx / length) * amplitude
	
	return true
