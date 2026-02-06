shader_type canvas_item;

uniform vec4 bright : source_color;
uniform vec4 medium : source_color;
uniform vec4 dark : source_color;

uniform float bright_thresh : hint_range(0.0, 1.0) = 0.6;
uniform float medium_thresh : hint_range(0.0, 1.0) = 0.3;

uniform int pixel_size : hint_range(1, 64) = 2;

uniform float alpha : hint_range(0.0, 1.0) = 1.0;
uniform float brightness : hint_range(0.0, 1.0) = 1.0;
uniform float red_bias : hint_range(0.0, 10.0) = 0.0;


void fragment() {
	vec2 screenUV = UV;
	vec2 resolution = vec2(textureSize(TEXTURE, 0));
	vec2 pixelUV = floor(screenUV * resolution / float(pixel_size)) * float(pixel_size) / resolution;
	
	
	vec4 pixelColor = texture(TEXTURE, pixelUV);
	pixelColor *= brightness;
	pixelColor.r = (pixelColor.g + pixelColor.b + pixelColor.r * (1.0 + red_bias)) / (3.0 + red_bias);
	if (pixelColor.r > bright_thresh){
		pixelColor = bright;
	} else if (pixelColor.r > medium_thresh){
		pixelColor = medium;
	} else {
		pixelColor = dark;
	}
	pixelColor.a = alpha;
	COLOR = pixelColor;
}

//void light() {
//	// Called for every pixel for every light affecting the CanvasItem.
//	// Uncomment to replace the default light processing function with this one.
//}
