shader_type canvas_item;
uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_linear_mipmap;

void vertex() {
	// Called for every vertex the material is visible on.
}

void fragment() {
	vec4 pixelColor = texture(SCREEN_TEXTURE, SCREEN_UV);
	vec4 original = pixelColor;
	pixelColor = texture(SCREEN_TEXTURE, vec2(SCREEN_UV.x + sin(TIME)*pixelColor.g, SCREEN_UV.y + cos(TIME)/2.0*pixelColor.r));
	
	//pixelColor *= 2.0;
	//original *= 2.0;
	//COLOR = (pixelColor * (length(SCREEN_UV - vec2(0.5, 0.5))+2.0) + original * (1.0-length(SCREEN_UV - vec2(0.5, 0.5)))/2.0);
	COLOR = pixelColor * 2.0 - original;
	float balance = (sin(TIME*1.1)+1.0)/2.0;
	balance = balance / 1.5 + 0.25;
	COLOR = pixelColor * balance + original * (1.0-balance);
}

//void light() {
	// Called for every pixel for every light affecting the CanvasItem.
	// Uncomment to replace the default light processing function with this one.
//}
