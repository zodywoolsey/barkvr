shader_type spatial;
render_mode unshaded;

uniform vec2 size = vec2(32.0, 28.0);
uniform sampler2D screen_tex :hint_screen_texture, repeat_disable, filter_nearest;

void vertex() {
	POSITION = vec4(VERTEX, 1.0);
}

void fragment() {
	vec2 norm_size = size;
	bool half = mod(SCREEN_UV.y / 2.0, norm_size.y) / norm_size.y < 0.5;
	vec2 uv = SCREEN_UV + vec2(norm_size.x * 0.5 * float(half), 0.0);
	vec2 center_uv = floor(uv / norm_size) * norm_size;
	vec2 norm_uv = mod(uv, norm_size) / norm_size;
	ALBEDO = texture(screen_tex,SCREEN_UV).rgb;
}

//void light() {
	// Called for every pixel for every light affecting the CanvasItem.
	// Uncomment to replace the default light processing function with this one.
//}
