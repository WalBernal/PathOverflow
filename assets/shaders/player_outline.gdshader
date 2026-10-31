// Contorno del personaje (T157, PlayerSprite): la silueta de una capa en un color
// oscuro. Solo lo bien opaco: la sombra de los pies (semitransparente) no se contornea.
shader_type canvas_item;

uniform vec4 outline_color : source_color = vec4(0.04, 0.03, 0.06, 0.85);

void fragment() {
	float a = texture(TEXTURE, UV).a;
	COLOR = vec4(outline_color.rgb, a > 0.6 ? outline_color.a : 0.0);
}
