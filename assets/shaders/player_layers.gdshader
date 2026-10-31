// Capas del personaje (T102a, PlayerSheet/PlayerSprite). En las máscaras, R = luz
// y G = capa de color (×8): se tiñe con el color del creador de esa capa. Las capas
// fijas (mask = false) traen su color real. `tint` mezcla todo hacia un color (golpe,
// muerte), como el dibujo de siempre.
shader_type canvas_item;

uniform bool mask = true;
uniform vec4 skin : source_color = vec4(1.0);
uniform vec4 outfit : source_color = vec4(1.0);
uniform vec4 accent : source_color = vec4(1.0);
uniform vec4 hair : source_color = vec4(1.0);
uniform vec4 eyes : source_color = vec4(1.0);
uniform vec4 tint = vec4(0.0);
// T160: la luz se hornea en gris (PlayerSheet.LUM_GRAY); 1 / ese gris = el color base,
// y lo más claro (brillos) pasa de él.
uniform float light_gain = 1.0;

void fragment() {
	vec4 m = texture(TEXTURE, UV);
	vec3 col = m.rgb;
	if (mask) {
		int layer = int(round(m.g * 8.0));
		vec3 base = vec3(1.0);
		if (layer == 1) { base = skin.rgb; }
		else if (layer == 2) { base = outfit.rgb; }
		else if (layer == 3) { base = accent.rgb; }
		else if (layer == 4) { base = hair.rgb; }
		else if (layer == 5) { base = eyes.rgb; }
		col = min(base * m.r * light_gain, vec3(1.0));
	}
	col = mix(col, tint.rgb, tint.a);
	COLOR = vec4(col, m.a);
}
