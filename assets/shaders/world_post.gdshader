shader_type canvas_item;
// Filtro del mundo en dos pasadas (ver scripts/game/world_post.gd):
// - Pasada de pixel art (justo después de la zona): suelo, decorado y puertas en
//   bloques de `pixel` px, con paleta reducida y tramado ordenado (Bayer 4×4).
//   Lo que se dibuja después (jugador, enemigos, botín, textos) queda nítido.
// - Pasada de luz (encima de todo menos el botín y los textos): gradación de la
//   zona, viñeta en escalones y oscuridad con luz alrededor del jugador.

uniform sampler2D screen_tex : hint_screen_texture, filter_nearest;
uniform float pixel = 2.0;
uniform bool posterize = true;
uniform float levels = 20.0;
uniform vec4 tint : source_color = vec4(1.0);
uniform float tint_amount = 0.0;
uniform float saturation = 1.0;
uniform float vignette = 0.0;
uniform float darkness = 0.0;
uniform vec2 light_pos = vec2(0.0);
uniform float light_radius = 420.0;
// Luces dinámicas (proyectiles, explosiones, antorchas...): xy = posición en
// pantalla, z = radio, w = intensidad; y su color. Solo en la pasada de luz.
const int MAX_LIGHTS = 32;
uniform vec4 lights[MAX_LIGHTS];
uniform vec4 light_colors[MAX_LIGHTS] : source_color;
uniform int light_count = 0;
// Cuánto tiñen las luces de color en zonas sin oscuridad (en las oscuras, más).
uniform float glow_base = 0.06;
// T98 (solo en la pasada de luz, según la calidad gráfica):
// - bloom: halo suave alrededor de las luces (aparte de los escalones de pixel art).
// - heat: distorsión de calor sobre el fuego (xy, radio, fuerza).
// - shocks: ondas de choque de los golpes grandes (xy, radio actual, fuerza).
uniform float bloom = 0.0;
const int MAX_HEAT = 8;
uniform vec4 heat[MAX_HEAT];
uniform int heat_count = 0;
const int MAX_SHOCKS = 6;
uniform vec4 shocks[MAX_SHOCKS];
uniform int shock_count = 0;

float bayer4(vec2 p) {
	int x = int(mod(p.x, 4.0));
	int y = int(mod(p.y, 4.0));
	int idx = x + y * 4;
	float m[16] = float[16](0.0, 8.0, 2.0, 10.0, 12.0, 4.0, 14.0, 6.0, 3.0, 11.0, 1.0, 9.0, 15.0, 7.0, 13.0, 5.0);
	return m[idx] / 16.0 - 0.5;
}

void fragment() {
	vec2 cell = floor(FRAGCOORD.xy / pixel);
	vec2 center = (cell + 0.5) * pixel;
	// Distorsiones (calor y ondas de choque): se muestrea la pantalla algo desplazada.
	vec2 offs = vec2(0.0);
	for (int k = 0; k < heat_count; k++) {
		vec4 H = heat[k];
		float f = (1.0 - clamp(distance(FRAGCOORD.xy, H.xy) / H.z, 0.0, 1.0)) * H.w;
		offs += vec2(sin(FRAGCOORD.y * 0.09 + TIME * 7.0), cos(FRAGCOORD.x * 0.07 + TIME * 5.0) * 0.6) * f * 2.6;
	}
	for (int k = 0; k < shock_count; k++) {
		vec4 S = shocks[k];
		vec2 to = FRAGCOORD.xy - S.xy;
		float d = length(to);
		float ring = 1.0 - clamp(abs(d - S.z) / 20.0, 0.0, 1.0);
		offs += (d > 0.001 ? to / d : vec2(0.0)) * ring * S.w * 12.0;
	}
	vec3 col = texture(screen_tex, (center + offs) * SCREEN_PIXEL_SIZE).rgb;
	float luma = dot(col, vec3(0.299, 0.587, 0.114));
	col = mix(vec3(luma), col, saturation);
	col = mix(col, col * tint.rgb * 1.25, tint_amount);
	vec2 uv = center * SCREEN_PIXEL_SIZE;
	if (vignette > 0.0) {
		float d = length((uv - 0.5) * vec2(1.0, 0.8));
		float v = floor(smoothstep(0.38, 0.78, d) * 3.0) / 3.0;
		col *= 1.0 - v * vignette;
	}
	// Luces dinámicas: en escalones (como la del jugador) para que sigan siendo pixel art.
	float dyn = 0.0;
	vec3 glow = vec3(0.0);
	vec3 halo = vec3(0.0);
	for (int k = 0; k < light_count; k++) {
		vec4 L = lights[k];
		float a = 1.0 - clamp(distance(center, L.xy) / L.z, 0.0, 1.0);
		halo += light_colors[k].rgb * a * a * a * L.w;   // bloom: suave, sin escalones
		a = floor(a * 4.0 + 0.5) / 4.0 * L.w;
		dyn = max(dyn, a);
		glow += light_colors[k].rgb * a;
	}
	if (darkness > 0.0) {
		float l = 1.0 - clamp(distance(FRAGCOORD.xy, light_pos) / light_radius, 0.0, 1.0);
		l = floor(l * 4.0 + 0.5) / 4.0;
		col *= mix(1.0 - darkness, 1.0, max(l, dyn));
	}
	glow = min(glow, vec3(1.5));
	col = col * (vec3(1.0) + glow * (glow_base + 1.1 * darkness)) + glow * (0.02 + 0.12 * darkness);
	col += min(halo, vec3(1.2)) * 0.16 * bloom;
	if (posterize) {
		col = floor(col * levels + 0.5 + bayer4(cell) * 0.9) / levels;
	}
	COLOR = vec4(clamp(col, 0.0, 1.0), 1.0);
}
