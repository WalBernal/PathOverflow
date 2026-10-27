class_name FxArt
## Dibujo de estados y avisos de ataque (T99), compartido por jugador y enemigos:
## llamas que suben, burbujas de veneno, gotas de sangrado, escarcha que crece al
## helarse, y los avisos del suelo con textura (borde de trazos que avanza, ondas
## que se cierran hacia el centro y flechas que marcan hacia dónde va el golpe).

## Trazos del borde animado y cuánto tarda en dar una vuelta.
const DASHES := 16
const DASH_FILL := 0.6
const MARCH_SPEED := 0.35


## Tramos [desde, hasta] (radianes) de un borde de trazos girado `phase` vueltas.
static func dash_spans(phase: float, dashes := DASHES, fill := DASH_FILL) -> Array:
	var out := []
	var step := TAU / dashes
	for k in dashes:
		var a0 := fposmod(phase, 1.0) * TAU + k * step
		out.append([a0, a0 + step * fill])
	return out


## Cuánto cubre la escarcha según los segundos que llevas helado: crece del 35 % al
## 100 % en el primer medio segundo.
static func frost_growth(elapsed: float) -> float:
	return clampf(0.35 + elapsed / 0.5 * 0.65, 0.35, 1.0)


## Distancias de las flechas a lo largo de un aviso de `length`, separadas `spacing`
## y avanzando con `phase` (0..1 = una separación).
static func chevron_offsets(length: float, spacing: float, phase: float) -> Array:
	var out := []
	var d := fposmod(phase, 1.0) * spacing
	while d < length - spacing * 0.3:
		out.append(d)
		d += spacing
	return out


## Borde de trazos que gira (avisos redondos).
static func marching_ring(ci: CanvasItem, center: Vector2, radius: float, tt: float, color: Color, width := 3.0) -> void:
	for span in dash_spans(tt * MARCH_SPEED):
		ci.draw_arc(center, radius, span[0], span[1], 6, color, width, true)


## Ondas que se cierran hacia el centro: el golpe va a caer ahí.
static func closing_ripples(ci: CanvasItem, center: Vector2, radius: float, tt: float, color: Color) -> void:
	for k in 2:
		var ph := fposmod(tt * 1.2 + k * 0.5, 1.0)
		ci.draw_arc(center, radius * (1.0 - ph * 0.85), 0.0, TAU, 28, Color(color, color.a * ph), 2.0, true)


## Flechas a lo largo de una dirección (conos y cargas), avanzando.
static func chevrons(ci: CanvasItem, origin: Vector2, dir: Vector2, length: float, half_width: float, tt: float, color: Color) -> void:
	var side := dir.orthogonal() * half_width
	for d in chevron_offsets(length, 46.0, tt * 1.6):
		var tip: Vector2 = origin + dir * (float(d) + 14.0)
		var back: Vector2 = origin + dir * float(d)
		var fade := 1.0 - float(d) / maxf(1.0, length)
		ci.draw_polyline(PackedVector2Array([back + side, tip, back - side]), Color(color, color.a * (0.35 + 0.65 * fade)), 3.0, true)


## Lenguas de fuego que suben (quemado).
static func flames(ci: CanvasItem, base: Vector2, r: float, tt: float, jitter: float) -> void:
	for k in 4:
		var ph := fposmod(tt * 1.8 + k / 4.0 + jitter, 1.0)
		var q := base + Vector2((k - 1.5) * r * 0.45 + sin(tt * 6.0 + k) * 1.5, -ph * r * 1.6)
		var s := (1.0 - ph) * r * 0.28
		if s < 0.5:
			continue   # casi apagada: un polígono tan pequeño no se puede triangular
		ci.draw_colored_polygon(PackedVector2Array([q + Vector2(-s, 0), q + Vector2(0, -s * 2.2), q + Vector2(s, 0), q + Vector2(0, s * 0.6)]),
			Color(1.0, 0.45 + 0.4 * ph, 0.1, 0.85 * (1.0 - ph)))


## Burbujas que suben y revientan (veneno, corrupción).
static func bubbles(ci: CanvasItem, base: Vector2, r: float, tt: float, jitter: float, color: Color) -> void:
	for k in 3:
		var ph := fmod(tt + k / 3.0 + jitter, 1.0)
		var q := base + Vector2((k - 1) * r * 0.6 + sin(tt * 3.0 + k) * 2.0, -ph * r * 1.3)
		ci.draw_circle(q, 2.0 + ph * 2.0, Color(color, 0.75 * (1.0 - ph)))
		if ph > 0.85:
			ci.draw_arc(q, 4.0 + (ph - 0.85) * 30.0, 0.0, TAU, 10, Color(color.lightened(0.3), (1.0 - ph) * 4.0), 1.0, true)


## Gotas que caen (sangrado).
static func drops(ci: CanvasItem, base: Vector2, r: float, tt: float, jitter: float) -> void:
	for k in 2:
		var ph := fmod(tt * 1.4 + k * 0.5 + jitter, 1.0)
		var q := base + Vector2((k - 0.5) * r * 0.8, ph * r * 1.1)
		var s := 2.4 * (1.0 - ph * 0.4)
		ci.draw_colored_polygon(PackedVector2Array([q + Vector2(0, -s * 1.8), q + Vector2(s, 0), q + Vector2(0, s), q + Vector2(-s, 0)]),
			Color(0.8, 0.08, 0.1, 0.9 * (1.0 - ph)))
