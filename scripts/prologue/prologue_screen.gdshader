shader_type canvas_item;
// Pantalla del prólogo: el mundo real descolorido (calor, sol de Mazatlán) y,
// en la caída a producción, pixelado, glitch y tinte digital verde.

uniform vec2 src_size = vec2(400.0, 225.0);
uniform float desat : hint_range(0.0, 1.0) = 0.5;
uniform vec3 tint = vec3(1.06, 1.0, 0.88);
uniform float pixelate = 1.0;
uniform float glitch : hint_range(0.0, 2.0) = 0.0;
uniform float digital : hint_range(0.0, 1.0) = 0.0;
uniform float flash : hint_range(0.0, 1.0) = 0.0;
uniform float heat : hint_range(0.0, 1.0) = 0.0;
uniform float time = 0.0;

float hash(float n) {
	return fract(sin(n) * 43758.5453);
}

void fragment() {
	vec2 uv = UV;
	if (pixelate > 1.0) {
		vec2 cells = src_size / pixelate;
		uv = (floor(uv * cells) + 0.5) / cells;
	}
	// Calor: el aire tiembla sobre el pavimento (mitad de abajo).
	uv.x += sin(uv.y * 90.0 + time * 6.0) * 0.0015 * heat * smoothstep(0.5, 1.0, uv.y);
	if (glitch > 0.0) {
		float row = floor(uv.y * 45.0);
		float t = floor(time * 18.0);
		float on = step(0.72, hash(row * 3.1 + t));
		uv.x += (hash(row + t * 1.7) - 0.5) * 0.12 * glitch * on;
	}
	vec4 c = texture(TEXTURE, uv);
	if (glitch > 0.0) {
		// Separación de canales.
		float shift = 0.004 * glitch;
		c.r = texture(TEXTURE, uv + vec2(shift, 0.0)).r;
		c.b = texture(TEXTURE, uv - vec2(shift, 0.0)).b;
	}
	float gray = dot(c.rgb, vec3(0.299, 0.587, 0.114));
	vec3 col = mix(c.rgb, vec3(gray), desat) * tint;
	// Mundo digital: negativo de terminal (lo claro se apaga, lo oscuro brilla en verde).
	vec3 term = vec3(0.06, 0.95, 0.42) * pow(1.0 - gray, 1.6) * 1.2 + vec3(0.0, 0.03, 0.02);
	col = mix(col, term, digital);
	col = mix(col, vec3(1.0), flash);
	COLOR = vec4(col, 1.0);
}
