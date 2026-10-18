class_name CharacterAppearance
## Apariencia del personaje y su dibujo provisional (formas simples), hasta que
## existan sprites por capas. El diccionario guardado ya tiene la forma que
## usarán los sprites: índices de estilo + colores, así que el formato de
## guardado no tendrá que cambiar.
##
## draw() la usan tanto el creador de personaje (grande) como el jugador en el
## mundo (pequeño), para que lo que eliges sea lo que ves.

const SKIN_TONES := ["f1d2b6", "e0ac8a", "c99a7a", "a8714f", "7c4a2d", "4b2e1e"]
const HAIR_COLORS := ["0f0d0c", "2b2118", "6b4423", "b5651d", "d9b26a", "c8c8c8", "7d2b2b", "3d5a80"]
const OUTFIT_COLORS := ["6b2b2b", "2b4a6b", "2b6b45", "5a3b6b", "6b5a2b", "3a3a3a", "8a6d3b", "1f1f2e"]
const BODY_NAMES := ["Delgada", "Media", "Robusta"]
const BODY_WIDTH := [0.82, 1.0, 1.22]
const HAIR_NAMES := ["Rapado", "Corto", "Largo", "Cresta", "Moño"]


static func default() -> Dictionary:
	return {
		"body": 1,
		"hair": 1,
		"skin_tone": SKIN_TONES[2],
		"hair_color": HAIR_COLORS[1],
		"outfit_color": OUTFIT_COLORS[0],
	}


static func random(rng: RandomNumberGenerator) -> Dictionary:
	return {
		"body": rng.randi_range(0, BODY_NAMES.size() - 1),
		"hair": rng.randi_range(0, HAIR_NAMES.size() - 1),
		"skin_tone": SKIN_TONES[rng.randi_range(0, SKIN_TONES.size() - 1)],
		"hair_color": HAIR_COLORS[rng.randi_range(0, HAIR_COLORS.size() - 1)],
		"outfit_color": OUTFIT_COLORS[rng.randi_range(0, OUTFIT_COLORS.size() - 1)],
	}


## Rellena claves que falten y corrige valores fuera de rango (guardados viejos
## o editados a mano).
static func sanitize(d: Dictionary) -> Dictionary:
	var result := default()
	result["body"] = clampi(int(d.get("body", result["body"])), 0, BODY_NAMES.size() - 1)
	result["hair"] = clampi(int(d.get("hair", result["hair"])), 0, HAIR_NAMES.size() - 1)
	for key in ["skin_tone", "hair_color", "outfit_color"]:
		var value := String(d.get(key, ""))
		if Color.html_is_valid(value):
			result[key] = value
	return result


## Dibuja la figura con los pies en `feet`. A escala 1 mide unos 40 px de alto.
## `facing`: hacia dónde mira (si mira hacia arriba, se ve de espaldas).
## `tint`: si su alfa > 0, tiñe toda la figura (daño, muerte).
## `walk_phase`: fase del ciclo de paso en radianes (< 0 = quieto). Un ciclo
## completo (TAU) son dos pasos: piernas alternas, brazos opuestos y el cuerpo
## sube y baja con cada pisada, así que los pies no "patinan".
static func draw(ci: CanvasItem, feet: Vector2, scale: float, a: Dictionary,
		facing := Vector2.DOWN, tint := Color(0, 0, 0, 0), walk_phase := -1.0) -> void:
	var skin := _tinted(Color(a["skin_tone"]), tint)
	var hair := _tinted(Color(a["hair_color"]), tint)
	var outfit := _tinted(Color(a["outfit_color"]), tint)
	var width: float = BODY_WIDTH[int(a["body"])]
	var back := facing.y < -0.5
	var look := clampf(facing.x, -1.0, 1.0)
	var profile := absf(look) > 0.6 and absf(facing.y) < 0.75   # de perfil

	var walking := walk_phase >= 0.0
	var swing := sin(walk_phase) if walking else 0.0          # -1..1, pierna izquierda delante
	var bob := absf(cos(walk_phase)) * 1.3 if walking else 0.0  # el cuerpo sube entre pisadas
	var p := func(x: float, y: float) -> Vector2: return feet + Vector2(x, y) * scale
	# Parte superior del cuerpo, desplazada por el balanceo.
	var u := func(x: float, y: float) -> Vector2: return feet + Vector2(x, y - bob) * scale

	# Sombra (se encoge un poco cuando el cuerpo sube).
	ci.draw_set_transform(feet, 0.0, Vector2(1.0, 0.4))
	ci.draw_circle(Vector2.ZERO, (11.0 - bob * 0.6) * scale * width, Color(0, 0, 0, 0.4))
	ci.draw_set_transform(Vector2.ZERO)

	# Piernas: cada una se levanta en su fase; de perfil, además, avanzan y retroceden.
	var legs := outfit.darkened(0.35)
	var shoes := outfit.darkened(0.6)
	for leg: float in [-1.0, 1.0]:
		var phase := swing * leg                      # > 0: esta pierna va por delante
		var lift := maxf(0.0, phase) * 2.6 if walking else 0.0
		var x := (-5.0 if leg < 0.0 else 1.0) * width
		var y_top := -9.0 - bob
		if profile:
			x = -2.0 * width + phase * 3.2 * signf(look)
		var length := 9.0 + bob - lift
		ci.draw_rect(Rect2(p.call(x, y_top), Vector2(4.0 * width, length) * scale), legs)
		ci.draw_rect(Rect2(p.call(x - 0.3, y_top + length - 1.6), Vector2(4.6 * width, 1.8) * scale), shoes)

	# Brazos (detrás del torso), en oposición a las piernas.
	var arm_color := outfit.darkened(0.2)
	for arm: float in [-1.0, 1.0]:
		var arm_swing := -swing * arm * (2.2 if not profile else 0.0)
		var ax := (-10.5 if arm < 0.0 else 7.0) * width
		var hand_x := (-8.75 if arm < 0.0 else 8.75) * width
		if profile:
			ax = -1.75 * width + swing * arm * 3.0 * signf(look)
			hand_x = ax + 1.75 * width
		ci.draw_rect(Rect2(u.call(ax, -23.0 + arm_swing * 0.4), Vector2(3.5 * width, 12.0) * scale), arm_color)
		ci.draw_circle(u.call(hand_x, -10.5 + arm_swing), 1.9 * scale * width, skin)

	# Torso: trapecio de hombros a cintura (más estrecho de perfil).
	var tw := width * (0.75 if profile else 1.0)
	var lean := 0.8 * signf(look) if profile and walking else 0.0
	ci.draw_colored_polygon(PackedVector2Array([
		u.call(-8.0 * tw + lean, -24.0), u.call(8.0 * tw + lean, -24.0),
		u.call(6.0 * tw, -8.0), u.call(-6.0 * tw, -8.0)]), outfit)
	ci.draw_rect(Rect2(u.call(-6.0 * tw, -11.0), Vector2(12.0 * tw, 2.0) * scale), outfit.darkened(0.5))

	# Cabeza.
	var head: Vector2 = u.call(lean, -31.0)
	var r := 7.0 * scale
	var style := int(a["hair"])
	if style == 2:  # pelo largo: por detrás de la cabeza
		ci.draw_rect(Rect2(u.call(lean - 8.0, -33.0), Vector2(16.0, 15.0) * scale), hair)
	ci.draw_circle(head, r, skin)
	if back:
		if style != 0:
			ci.draw_circle(head, r + 0.6 * scale, hair)
	else:
		_draw_hair(ci, head, r, scale, style, hair)
		for side in [-1.0, 1.0]:
			ci.draw_circle(head + Vector2(side * 2.6 + look * 1.6, 0.5) * scale, 1.1 * scale, Color(0.08, 0.06, 0.06))
	if style == 3:  # la cresta se ve desde todos los ángulos
		ci.draw_colored_polygon(PackedVector2Array([
			head + Vector2(-2.0, -5.0) * scale, head + Vector2(0.0, -14.0) * scale,
			head + Vector2(2.0, -5.0) * scale]), hair)
	elif style == 4:
		ci.draw_circle(head + Vector2(0.0, -8.5) * scale, 3.2 * scale, hair)


static func _draw_hair(ci: CanvasItem, head: Vector2, r: float, scale: float, style: int, hair: Color) -> void:
	match style:
		0:  # rapado: una sombra fina
			ci.draw_arc(head, r - 0.5 * scale, PI * 1.05, PI * 1.95, 16, hair, 1.6 * scale, true)
		1, 2, 4:  # gorro de pelo sobre la mitad superior
			var points := PackedVector2Array()
			for k in 17:
				var t := PI + PI * k / 16.0
				points.append(head + Vector2(cos(t), sin(t)) * (r + 0.8 * scale))
			ci.draw_colored_polygon(points, hair)
		3:  # cresta: laterales rapados
			ci.draw_arc(head, r - 0.5 * scale, PI * 1.05, PI * 1.95, 16, hair.darkened(0.3), 1.4 * scale, true)


static func _tinted(c: Color, tint: Color) -> Color:
	return c.lerp(Color(tint, 1.0), 0.6) if tint.a > 0.0 else c
