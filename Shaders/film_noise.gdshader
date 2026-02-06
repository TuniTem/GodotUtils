shader_type canvas_item;
// set max strength to your liking here=20.0, step_size=0.1
uniform float strength: hint_range(0, 20.0, 0.01)=16;
uniform float blur_amount : hint_range(0.0, 50.0) = 1.0;
uniform float mix_amount : hint_range(0.0, 1.0) = 0.5;
uniform sampler2D screen_texture : hint_screen_texture;

void fragment() {
	//// blur-ish
    //vec2 texel_size = vec2(1.0) / vec2(textureSize(screen_texture, 0));
    //vec4 color = vec4(0.0);
    //vec3 avg_color = vec3(0.0);
//
    //for (float x = -1.0; x <= 1.0; x++) {
        //for (float y = -1.0; y <= 1.0; y++) {
            //if (mod(x + y, 2.0) == 0.0) {
                //color += texture(screen_texture, SCREEN_UV + vec2(x, y) * texel_size * blur_amount);
                //avg_color += texture(screen_texture, SCREEN_UV + vec2(x, y) * texel_size).rgb;
            //}
        //}
    //}
	//




	// Screen Color
    vec4 screen = texture(TEXTURE, SCREEN_UV);
	vec2 iResolution = 1.0 / SCREEN_PIXEL_SIZE;
	vec2 uv = FRAGCOORD.xy / iResolution.xy;

	// Random noise
    float x = (uv.x + 4.0 ) * (uv.y + 4.0 ) * (TIME * 10.0);
	// Add grain to Screen
	screen = screen+vec4(mod((mod(x, 13.0) ) * (mod(x, 123.0) ), 0.01)-0.005) * strength;
	//screen *= vec4(0.0, 0.0, 0.0, 1.0);

    screen = 1.0 - screen;

	COLOR = screen;
	//COLOR = color;

}