shader_type canvas_item;

void fragment() {
	COLOR = abs(texture(TEXTURE,UV)-1.0);
	COLOR.a = texture(TEXTURE,UV).a;
}
