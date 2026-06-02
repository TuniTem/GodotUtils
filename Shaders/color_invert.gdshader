shader_type canvas_item;

uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_linear_mipmap;
uniform vec3 invert_color : source_color;
uniform vec3 invert_test_color : source_color;
uniform float distance_threshold : hint_range(0.0, 1.0, 0.001);

void fragment() {
	float dist = distance(invert_test_color, texture(SCREEN_TEXTURE, SCREEN_UV).rgb);
	if (dist < distance_threshold) {
		COLOR.rgb = invert_color;
	}
}
