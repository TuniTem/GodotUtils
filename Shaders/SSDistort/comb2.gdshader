shader_type canvas_item;

uniform float brightness : hint_range(0.0, 10.0, 0.01);
uniform float contrast : hint_range(0.0, 10.0, 0.01);
uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_linear_mipmap;

uniform float intensity : hint_range(0, 1) = 0.5;
uniform float edge_width : hint_range(0, 1.0) = 0.2;
uniform float noise_ammount : hint_range(0.0, 10.0, 0.01);


void fragment() {
	
	//---------------------------------------------------
	vec2 uv = SCREEN_UV;
	
	// Calculate distance from the center
	vec2 center = vec2(0.5);
	float dist = distance(uv, center);
	
	// Calculate edge factor
	float edge_factor = smoothstep(1.0 - edge_width, 1.0, dist);
	
	// Apply sine distortion based on edge factor
	float wave = sin(uv.x * 20.0 + TIME * 5.0) * sin(uv.y * 20.0 + TIME * 3.0);
	
	// Add noise to the edges
	float noise = fract(sin(dot(uv.xy * edge_factor*TIME, vec2(12.9898, 78.233))) * 43758.5453);
	noise = mix(0.0, noise, noise_ammount);
	// Combine effects for distortion
	float distortion = wave * 0.5 + noise * 0.5;
	uv += vec2(distortion * intensity * edge_factor);
	
	// Swirl effect near the edges
	float angle = atan(uv.y - 0.5, uv.x - 0.5);
	float radius = length(uv - center);
	uv.x += sin(angle + TIME) * radius * edge_factor * intensity;
	uv.y += cos(angle + TIME) * radius * edge_factor * intensity;
	
	// Fetch the original texture color
	
	vec4 pixelColor = texture(SCREEN_TEXTURE, uv);
	pixelColor.rgb *= brightness;
	pixelColor.rgb = pow(pixelColor.rgb, vec3(contrast));
	if(distance(pixelColor.rgb,(vec3(0.0f))) > 0.01){
		COLOR = pixelColor;
	} else {
		COLOR = vec4(0.0f);
	}
	
}
