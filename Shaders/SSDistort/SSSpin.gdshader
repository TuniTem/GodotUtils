shader_type canvas_item;
uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_linear_mipmap;
uniform float max_blend : hint_range(0,1) = 0.5;
uniform float rotation_offset = 0;
uniform float intensity : hint_range(0, 10);
uniform bool invert = false;
uniform vec2 rel_rect_size = vec2(1024, 600);
uniform float safe;
uniform sampler2D noise : hint_default_black;

float distFromCen(vec2 p) {
    // Get the screen size (aspect ratio correction)
    vec2 screen_size = vec2(1920, 1080);
    // Normalize the coordinates to the center
    vec2 normalized_coords = p - 0.5; // Move the coordinates to the center
    normalized_coords.y *= screen_size.y / screen_size.x; // Adjust x based on aspect ratio

    return length(normalized_coords) * 2.0;
}
//rotates by angle radians
vec2 rotate(vec2 p, float angle){
	return vec2(cos(angle)*p.x-sin(angle)*p.y, sin(angle)*p.x + cos(angle)*p.y);
	}

void fragment() {
	vec4 c = COLOR;
	
	float distMod = invert ? distFromCen(UV) : 0.5 - distFromCen(UV);
	
	float mod_intensity = intensity * pow(2.0, distFromCen(UV));
	float angle = intensity * distMod * 6.28318 + rotation_offset + TIME/4.0*10.0;
	vec2 newp = rotate(UV-vec2(0.5), angle) + vec2(0.5);
	vec2 disp = (newp - UV) * rel_rect_size * SCREEN_PIXEL_SIZE;
	disp.y = -disp.y; // for some reason UV and SCEEN_UV are inveresed
	//COLOR = mix(texture(SCREEN_TEXTURE, SCREEN_UV + disp), c, max_blend * 2.0 * (0.5-distFromCen(UV)));
	//COLOR = c;
	//Doesn'[t apply effect outside of circle]
	// + mix(texture(SCREEN_TEXTURE, SCREEN_UV + disp), c, max_blend * 2.0 * (0.5-distFromCen(UV))) * distFromCen(UV) 
	// texture(SCREEN_TEXTURE, SCREEN_UV)
	float balance = distFromCen(UV);
	//if balance >
	COLOR = mix(texture(SCREEN_TEXTURE, SCREEN_UV + disp), c, max_blend) * balance * 1.5 + texture(SCREEN_TEXTURE, SCREEN_UV);
}