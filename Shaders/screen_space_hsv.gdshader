shader_type canvas_item;

uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_linear_mipmap;
uniform float hue_shift : hint_range(0.0, 1.0) = 0.0; 
uniform float saturation_mult : hint_range(0.0, 5.0) = 1.0; 
uniform float value_mult : hint_range(0.0, 5.0) = 1.0;
uniform float contrast : hint_range(0.25, 4.0) = 1.0;
uniform bool keep_dark = false;

vec3 rgb2hsv(vec3 c) {
	float c_max = max(max(c.r, c.g), c.b);
	float c_min = min(min(c.r, c.g), c.b);
	float delta = c_max - c_min;

	float h = 0.0;
	if (delta > 0.00001) {
		if (c_max == c.r) {
			h = mod((c.g - c.b) / delta, 6.0);
		} else if (c_max == c.g) {
			h = ((c.b - c.r) / delta) + 2.0;
		} else {
			h = ((c.r - c.g) / delta) + 4.0;
		}
		h /= 6.0;
		if (h < 0.0) h += 1.0;
	}

	float s = (c_max <= 0.0) ? 0.0 : delta / c_max;
	float v = c_max;

	return vec3(h, s, v);
}

vec3 hsv2rgb(vec3 c) {
	float h = c.x * 6.0;
	float s = c.y;
	float v = c.z;

	int i = int(floor(h));
	float f = h - float(i);
	float p = v * (1.0 - s);
	float q = v * (1.0 - f * s);
	float t = v * (1.0 - (1.0 - f) * s);

	if (i == 0) return vec3(v, t, p);
	if (i == 1) return vec3(q, v, p);
	if (i == 2) return vec3(p, v, t);
	if (i == 3) return vec3(p, q, v);
	if (i == 4) return vec3(t, p, v);
	return vec3(v, p, q);
}

void fragment() {
	vec4 pixelColor = texture(SCREEN_TEXTURE, SCREEN_UV);
	if (!keep_dark || (keep_dark && pixelColor.r > 0.1)){
		vec3 hsv = rgb2hsv(pixelColor.rgb);
		hsv.x = mod(hsv.x + hue_shift, 1.0);
		hsv.y *= saturation_mult;
		hsv.z *= value_mult; 
		pixelColor.rgb = hsv2rgb(hsv);
	}
	pixelColor = pow(pixelColor * contrast, vec4(contrast));
	
	COLOR = pixelColor;
}
