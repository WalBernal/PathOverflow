// Héroe en pixel art (T176, HeroSprite): `tint` mezcla todo hacia un color (golpe,
// muerte), como el shader de las capas del oficinista.
shader_type canvas_item;

uniform vec4 tint = vec4(0.0);

void fragment() {
	vec4 c = texture(TEXTURE, UV);
	COLOR = vec4(mix(c.rgb, tint.rgb, tint.a), c.a);
}
