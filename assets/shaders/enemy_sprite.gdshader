// Enemigos dibujados con MultiMesh: un único atlas (columnas = fotogramas,
// filas = tipos). Datos por instancia:
//   INSTANCE_CUSTOM.x = fila del tipo, .y = desfase de animación,
//   .z = 1 si mira a la izquierda, .w = destello al recibir daño (0..1)
//   COLOR (color de instancia) = color de la rareza; alfa 0 = sin contorno.
shader_type canvas_item;

uniform vec2 grid = vec2(4.0, 5.0);
uniform float fps = 7.0;

varying vec4 v_custom;
varying vec4 v_rarity;

void vertex() {
	v_custom = INSTANCE_CUSTOM;
	v_rarity = COLOR;
}

void fragment() {
	vec2 uv = vec2(UV.x, 1.0 - UV.y);  // el QuadMesh llega invertido en 2D
	if (v_custom.z > 0.5) {
		uv.x = 1.0 - uv.x;
	}
	float frame = mod(floor(TIME * fps + v_custom.y), grid.x);
	vec2 cell_uv = (vec2(frame, v_custom.x) + uv) / grid;
	vec4 c = texture(TEXTURE, cell_uv);

	// Contorno del color de la rareza (mágico azul, élite amarillo, único naranja).
	if (c.a < 0.5 && v_rarity.a > 0.0) {
		vec2 px = TEXTURE_PIXEL_SIZE;
		float n = texture(TEXTURE, cell_uv + vec2(px.x, 0.0)).a
			+ texture(TEXTURE, cell_uv - vec2(px.x, 0.0)).a
			+ texture(TEXTURE, cell_uv + vec2(0.0, px.y)).a
			+ texture(TEXTURE, cell_uv - vec2(0.0, px.y)).a;
		if (n > 1.5) {
			c = vec4(v_rarity.rgb, v_rarity.a);
		}
	}
	c.rgb = mix(c.rgb, vec3(1.0), v_custom.w * step(0.5, c.a));
	COLOR = c;
}
