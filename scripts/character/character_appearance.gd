class_name CharacterAppearance
## Apariencia del personaje y su dibujo provisional (formas simples), hasta que
## existan sprites por capas. El diccionario guardado ya tiene la forma que
## usarán los sprites: índices de estilo + colores, así que el formato de
## guardado no tendrá que cambiar.
##
## draw() dibuja la figura entera (creador, lista, jugador y NPCs en el mundo) y
## draw_head() la cabeza a cualquier tamaño (retratos de la hoja de personaje y
## de los diálogos): todo sale del mismo código, así que lo que eliges es lo que ves.

const SKIN_TONES := ["f6dcc6", "f1d2b6", "e0ac8a", "c99a7a", "a8714f", "8d5a3b", "7c4a2d", "4b2e1e"]
const HAIR_COLORS := ["0f0d0c", "2b2118", "6b4423", "b5651d", "d9b26a", "e8e0c8", "c8c8c8", "7d2b2b", "3d5a80", "6b3d80", "2f7a5a", "d96a9a"]
const OUTFIT_COLORS := ["6b2b2b", "2b4a6b", "2b6b45", "5a3b6b", "6b5a2b", "3a3a3a", "8a6d3b", "1f1f2e", "1d5a66", "7a3a1a", "c8c8c0", "4a5a2a"]
const ACCENT_COLORS := ["2a2a30", "d9a441", "c8c8c8", "8a2b2b", "2b5a8a", "2b8a5a", "e06c6c", "0f0d0c", "f2f2f2", "b05ad9"]
const EYE_COLORS := ["3a2414", "6b4423", "2e6b8a", "3d7a3d", "5a5a6a", "8a6d3b", "1a1414", "9a3a6a"]
const BODY_NAMES := ["Delgada", "Media", "Robusta"]
const BODY_WIDTH := [0.82, 1.0, 1.22]
const HAIR_NAMES := ["Rapado", "Corto", "Largo", "Cresta", "Moño", "Hacia atrás", "Afro", "Coleta", "Rapado lateral", "Melena con flequillo", "Entradas"]
const BEARD_NAMES := ["Sin barba", "Barba de tres días", "Barba completa", "Bigote", "Candado"]
const ACCESSORY_NAMES := ["Nada", "Lentes", "Lentes de sol", "Audífonos", "Gorra", "Gorro de lana"]
const HEIGHT_NAMES := ["Baja", "Media", "Alta"]
const HEIGHT_VALUES := [0.9, 1.0, 1.08]
## Opcionales (sobre todo para NPCs): "height" (0,8-1,15, estatura) y
## "hair_streaks" (color de las canas o mechas).
const MIN_HEIGHT := 0.8
const MAX_HEIGHT := 1.15
const DARK := Color(0.08, 0.06, 0.06)
const MOUTH := Color("3a1a1a")


static func default() -> Dictionary:
	return {
		"body": 1,
		"hair": 1,
		"beard": 0,
		"accessory": 0,
		"skin_tone": SKIN_TONES[3],
		"hair_color": HAIR_COLORS[1],
		"outfit_color": OUTFIT_COLORS[0],
		"accent_color": ACCENT_COLORS[0],
		"eye_color": EYE_COLORS[0],
	}


static func random(rng: RandomNumberGenerator) -> Dictionary:
	var pick := func(list: Array) -> String: return list[rng.randi_range(0, list.size() - 1)]
	return {
		"body": rng.randi_range(0, BODY_NAMES.size() - 1),
		"hair": rng.randi_range(0, HAIR_NAMES.size() - 1),
		"beard": rng.randi_range(0, BEARD_NAMES.size() - 1) if rng.randf() < 0.4 else 0,
		"accessory": rng.randi_range(0, ACCESSORY_NAMES.size() - 1) if rng.randf() < 0.5 else 0,
		"skin_tone": pick.call(SKIN_TONES),
		"hair_color": pick.call(HAIR_COLORS),
		"outfit_color": pick.call(OUTFIT_COLORS),
		"accent_color": pick.call(ACCENT_COLORS),
		"eye_color": pick.call(EYE_COLORS),
		"height": HEIGHT_VALUES[rng.randi_range(0, HEIGHT_VALUES.size() - 1)],
	}


## Rellena claves que falten y corrige valores fuera de rango (guardados viejos
## o editados a mano).
static func sanitize(d: Dictionary) -> Dictionary:
	var result := default()
	result["body"] = clampi(int(d.get("body", result["body"])), 0, BODY_NAMES.size() - 1)
	result["hair"] = clampi(int(d.get("hair", result["hair"])), 0, HAIR_NAMES.size() - 1)
	result["beard"] = clampi(int(d.get("beard", 0)), 0, BEARD_NAMES.size() - 1)
	result["accessory"] = clampi(int(d.get("accessory", 0)), 0, ACCESSORY_NAMES.size() - 1)
	for key in ["skin_tone", "hair_color", "outfit_color", "eye_color"]:
		var value := String(d.get(key, ""))
		if Color.html_is_valid(value):
			result[key] = value
	# Guardados de antes: los detalles eran el atuendo oscurecido.
	var accent := String(d.get("accent_color", ""))
	result["accent_color"] = accent if Color.html_is_valid(accent) else Color(result["outfit_color"]).darkened(0.55).to_html(false)
	if d.has("height"):
		result["height"] = clampf(float(d["height"]), MIN_HEIGHT, MAX_HEIGHT)
	if Color.html_is_valid(String(d.get("hair_streaks", ""))):
		result["hair_streaks"] = String(d["hair_streaks"])
	# Opcionales (NPC): color propio de la barba y de la camisa, canas en la barba y sonrisa fija.
	for key in ["beard_color", "shirt_color"]:
		if Color.html_is_valid(String(d.get(key, ""))):
			result[key] = String(d[key])
	if d.get("beard_streaks", false):
		result["beard_streaks"] = true
	if d.has("smile"):
		result["smile"] = clampf(float(d["smile"]), -1.0, 1.0)
	return result


## Índice de HEIGHT_VALUES más cercano a la estatura guardada (para el creador).
static func height_index(a: Dictionary) -> int:
	var h := float(a.get("height", 1.0))
	var best := 1
	for i in HEIGHT_VALUES.size():
		if absf(HEIGHT_VALUES[i] - h) < absf(HEIGHT_VALUES[best] - h):
			best = i
	return best


## Elipse rellena como polígono. No usa draw_set_transform: así respeta la
## transformación que tenga quien dibuja (p. ej. la cámara del prólogo; antes la
## dejaba en cero y el personaje se iba de la pantalla al moverse la cámara).
static func _ellipse(ci: CanvasItem, c: Vector2, rx: float, ry: float, color: Color) -> void:
	if rx <= 0.0 or ry <= 0.0:
		return
	var pts := PackedVector2Array()
	for k in 16:
		var a := TAU * k / 16.0
		pts.append(c + Vector2(cos(a) * rx, sin(a) * ry))
	ci.draw_colored_polygon(pts, color)


## Dibuja la figura con los pies en `feet`. A escala 1 mide unos 40 px de alto.
## `facing`: hacia dónde mira (si mira hacia arriba, se ve de espaldas).
## `tint`: si su alfa > 0, tiñe toda la figura (daño, muerte).
## `walk_phase`: fase del ciclo de paso en radianes (< 0 = quieto). Un ciclo
## completo (TAU) son dos pasos: piernas alternas, brazos opuestos y el cuerpo
## sube y baja con cada pisada, así que los pies no "patinan".
static func draw(ci: CanvasItem, feet: Vector2, scale: float, a: Dictionary,
		facing := Vector2.DOWN, tint := Color(0, 0, 0, 0), walk_phase := -1.0) -> void:
	var skin := _tinted(Color(a["skin_tone"]), tint)
	var outfit := _tinted(Color(a["outfit_color"]), tint)
	var accent := _tinted(Color(a.get("accent_color", outfit.darkened(0.55).to_html(false))), tint)
	var width: float = BODY_WIDTH[int(a["body"])]
	var back := facing.y < -0.5
	var look := clampf(facing.x, -1.0, 1.0)
	var profile := absf(look) > 0.6 and absf(facing.y) < 0.75   # de perfil

	var walking := walk_phase >= 0.0
	var swing := sin(walk_phase) if walking else 0.0          # -1..1, pierna izquierda delante
	var bob := absf(cos(walk_phase)) * 1.3 if walking else 0.0  # el cuerpo sube entre pisadas
	# Estatura: escala las alturas (la cabeza mantiene su tamaño).
	var hs := float(a.get("height", 1.0))
	var p := func(x: float, y: float) -> Vector2: return feet + Vector2(x, y * hs) * scale
	# Parte superior del cuerpo, desplazada por el balanceo.
	var u := func(x: float, y: float) -> Vector2: return feet + Vector2(x, (y - bob) * hs) * scale

	# Sombra (se encoge un poco cuando el cuerpo sube).
	var shadow_r := (11.0 - bob * 0.6) * scale * width
	_ellipse(ci, feet, shadow_r, shadow_r * 0.4, Color(0, 0, 0, 0.4))

	# Piernas: cada una se levanta en su fase; de perfil, además, avanzan y retroceden.
	var legs := outfit.darkened(0.35)
	for leg: float in [-1.0, 1.0]:
		var phase := swing * leg                      # > 0: esta pierna va por delante
		var lift := maxf(0.0, phase) * 2.6 if walking else 0.0
		var x := (-5.0 if leg < 0.0 else 1.0) * width
		var y_top := -9.0 - bob
		if profile:
			x = -2.0 * width + phase * 3.2 * signf(look)
		var length := 9.0 + bob - lift
		ci.draw_rect(Rect2(p.call(x, y_top), Vector2(4.0 * width, length * hs) * scale), legs)
		ci.draw_rect(Rect2(p.call(x - 0.3, y_top + length - 1.6), Vector2(4.6 * width, 1.8) * scale), accent.darkened(0.3))

	# Brazos (detrás del torso), en oposición a las piernas.
	var arm_color := outfit.darkened(0.2)
	for arm: float in [-1.0, 1.0]:
		var arm_swing := -swing * arm * (2.2 if not profile else 0.0)
		var ax := (-10.5 if arm < 0.0 else 7.0) * width
		var hand_x := (-8.75 if arm < 0.0 else 8.75) * width
		if profile:
			ax = -1.75 * width + swing * arm * 3.0 * signf(look)
			hand_x = ax + 1.75 * width
		ci.draw_rect(Rect2(u.call(ax, -23.0 + arm_swing * 0.4), Vector2(3.5 * width, 12.0 * hs) * scale), arm_color)
		ci.draw_circle(u.call(hand_x, -10.5 + arm_swing), 1.9 * scale * width, skin)

	# Torso: trapecio de hombros a cintura (más estrecho de perfil), con cuello y cinturón.
	var tw := width * (0.75 if profile else 1.0)
	var lean := 0.8 * signf(look) if profile and walking else 0.0
	ci.draw_colored_polygon(PackedVector2Array([
		u.call(-8.0 * tw + lean, -24.0), u.call(8.0 * tw + lean, -24.0),
		u.call(6.0 * tw, -8.0), u.call(-6.0 * tw, -8.0)]), outfit)
	if not back and not profile:
		var shirt := _tinted(Color(a["shirt_color"]), tint) if a.has("shirt_color") else accent
		ci.draw_colored_polygon(PackedVector2Array([u.call(-3.0 + lean, -24.0), u.call(3.0 + lean, -24.0), u.call(lean, -19.0)]), shirt)
	ci.draw_rect(Rect2(u.call(-6.0 * tw, -11.0), Vector2(12.0 * tw, 2.0 * hs) * scale), accent)

	# Cabeza.
	var head: Vector2 = u.call(lean, -31.0)
	draw_head(ci, head, 7.0 * scale, a, {"back": back, "look": Vector2(look, 0.0), "tint": tint, "profile": profile})


## Dibuja la cabeza de radio `r` centrada en `head`. Opciones:
##   back (de espaldas), look (Vector2 -1..1: hacia dónde mira), blink (ojos cerrados),
##   mouth (0..1: boca abierta, para hablar; -1 = sin boca), smile (-1..1),
##   tint (Color), time (para pequeñas animaciones), profile.
## Con r grande (retratos) añade detalles: blanco de los ojos, iris, cejas y boca.
static func draw_head(ci: CanvasItem, head: Vector2, r: float, a: Dictionary, opts := {}) -> void:
	if a.has("smile"):
		# Sonrisa fija del personaje: gana a la expresión del retrato si ésta es menor.
		opts = opts.duplicate()
		opts["smile"] = maxf(float(opts.get("smile", 0.0)), float(a["smile"]))
	var tint: Color = opts.get("tint", Color(0, 0, 0, 0))
	var skin := _tinted(Color(a["skin_tone"]), tint)
	var hair := _tinted(Color(a["hair_color"]), tint)
	var accent := _tinted(Color(a.get("accent_color", "2a2a30")), tint)
	var streaks := _tinted(Color(a["hair_streaks"]), tint) if a.has("hair_streaks") else Color(0, 0, 0, 0)
	var style := int(a["hair"])
	var beard := int(a.get("beard", 0))
	var acc := int(a.get("accessory", 0))
	var back: bool = opts.get("back", false)
	var look: Vector2 = opts.get("look", Vector2.ZERO)
	var detail := r >= 18.0
	var lw := maxf(1.0, r * 0.09)   # grosor de línea proporcional

	# Capa de pelo por detrás de la cabeza.
	match style:
		2:  # largo
			_hair_back(ci, head, r, 1.14, 1.8, hair)
		5:  # hacia atrás, semilargo hasta la nuca
			_hair_back(ci, head, r, 1.2, 0.92, hair)
		6:  # afro
			ci.draw_circle(head + Vector2(0, -0.32) * r, 1.42 * r, hair)
			for k in 10:
				ci.draw_circle(head + Vector2(0, -0.32) * r + Vector2.from_angle(TAU * k / 10.0) * 1.3 * r, 0.3 * r, hair)
		7:  # coleta: se ve asomando por un lado
			if not back:
				var sway := sin(float(opts.get("time", 0.0)) * 2.0) * 0.08
				ci.draw_circle(head + Vector2(1.05 + sway, 0.15) * r, 0.42 * r, hair)
				ci.draw_circle(head + Vector2(1.15 + sway, 0.6) * r, 0.32 * r, hair)
		9:  # melena
			_hair_back(ci, head, r, 1.15, 1.05, hair)
	if acc == 3:   # audífonos: la diadema pasa por detrás si va de espaldas
		ci.draw_arc(head, 1.12 * r, PI * 1.05, PI * 1.95, 18, Color("2a2a30"), maxf(1.0, r * 0.16), true)

	ci.draw_circle(head, r, skin)

	if back:
		if style != 0:
			ci.draw_circle(head, r * 1.08, hair)
		if style == 5:
			ci.draw_circle(head + Vector2(0.0, -0.21) * r, r * 1.23, hair)
			if streaks.a > 0.0:
				for k in 2:
					var x := -0.64 + k * 1.28
					ci.draw_line(head + Vector2(x, -0.86) * r, head + Vector2(x * 0.9, 0.57) * r, Color(streaks, 0.7), lw * 0.9)
		elif style == 7:   # coleta colgando
			ci.draw_rect(Rect2(head + Vector2(-0.22, 0.2) * r, Vector2(0.44, 1.5) * r), hair)
			ci.draw_rect(Rect2(head + Vector2(-0.3, 0.3) * r, Vector2(0.6, 0.18) * r), accent)
		elif style == 8:
			ci.draw_circle(head, r * 1.08, hair.darkened(0.25))
			ci.draw_rect(Rect2(head + Vector2(-0.7, -1.08) * r, Vector2(1.4, 0.8) * r), hair)
	else:
		_draw_hair_front(ci, head, r, style, hair, streaks, lw)
		_draw_face(ci, head, r, a, opts, look, detail, lw, hair)
		var beard_hair := _tinted(Color(a["beard_color"]), tint) if a.has("beard_color") else hair
		_draw_beard(ci, head, r, beard, beard_hair, opts, detail, lw)
		if a.has("beard_streaks") and beard in [1, 2]:
			for k in 5:
				var x := -0.55 + k * 0.275
				ci.draw_line(head + Vector2(x, 0.62 + 0.18 * absf(x)) * r, head + Vector2(x * 1.05, 0.95 + 0.1 * absf(x)) * r, Color("c8c4bc", 0.55), maxf(1.0, lw * 0.8))
		if float(opts.get("smile", 0.0)) >= 0.5:
			_draw_big_smile(ci, head, r, float(opts.get("mouth", 0.0)), detail, lw)

	# Lo que se ve desde cualquier ángulo.
	if style == 3:   # cresta
		ci.draw_colored_polygon(PackedVector2Array([
			head + Vector2(-0.28, -0.71) * r, head + Vector2(0.0, -2.0) * r, head + Vector2(0.28, -0.71) * r]), hair)
	elif style == 4:   # moño
		ci.draw_circle(head + Vector2(0.0, -1.21) * r, 0.46 * r, hair)
	_draw_accessory(ci, head, r, acc, accent, back, look, lw)


static func _draw_hair_front(ci: CanvasItem, head: Vector2, r: float, style: int, hair: Color, streaks: Color, lw: float) -> void:
	match style:
		0:  # rapado: una sombra fina
			ci.draw_arc(head, r * 0.93, PI * 1.05, PI * 1.95, 18, Color(hair, 0.85), lw * 1.6, true)
		1, 2, 4, 7:  # gorro de pelo sobre la mitad superior
			_cap(ci, head, r, 1.11, hair)
		3:  # cresta: laterales rapados
			ci.draw_arc(head, r * 0.93, PI * 1.05, PI * 1.95, 18, hair.darkened(0.3), lw * 1.4, true)
		5:  # hacia atrás: frente despejada, volumen arriba, canas en las sienes
			var points := PackedVector2Array()
			for k in 17:
				var t := PI + PI * k / 16.0
				points.append(head + Vector2(cos(t) * 1.14, sin(t) * 1.34 - 0.086) * r)
			for q in [Vector2(0.99, -0.07), Vector2(0.8, -0.49), Vector2(0.36, -0.66), Vector2(-0.36, -0.66), Vector2(-0.8, -0.49), Vector2(-0.99, -0.07)]:
				points.append(head + q * r)
			ci.draw_colored_polygon(points, hair)
			for k in 4:
				var x0 := -0.6 + k * 0.4
				ci.draw_line(head + Vector2(x0, -0.66) * r, head + Vector2(x0 * 0.7, -1.29) * r, hair.lightened(0.12), lw * 0.7)
			if streaks.a > 0.0:
				for side in [-1.0, 1.0]:
					ci.draw_line(head + Vector2(side * 0.99, -0.14) * r, head + Vector2(side * 0.89, -0.71) * r, streaks, lw * 1.2)
				ci.draw_line(head + Vector2(0.29, -0.69) * r, head + Vector2(0.23, -1.23) * r, Color(streaks, 0.8), lw * 0.8)
		10:  # entradas: pelo corto con la frente despejada y un pico al centro
			var pts := PackedVector2Array()
			for k in 17:
				var t := PI + PI * k / 16.0
				pts.append(head + Vector2(cos(t), sin(t)) * r * 1.11)
			for q in [Vector2(1.0, -0.05), Vector2(0.86, -0.3), Vector2(0.6, -0.5), Vector2(0.28, -0.74), Vector2(0.0, -0.66),
					Vector2(-0.28, -0.74), Vector2(-0.6, -0.5), Vector2(-0.86, -0.3), Vector2(-1.0, -0.05)]:
				pts.append(head + q * r)
			ci.draw_colored_polygon(pts, hair)
		6:  # afro: el frente con forma redondeada
			_cap(ci, head, r, 1.15, hair)
			ci.draw_circle(head + Vector2(-0.95, -0.15) * r, 0.32 * r, hair)
			ci.draw_circle(head + Vector2(0.95, -0.15) * r, 0.32 * r, hair)
		8:  # rapado lateral con tupé hacia un lado
			ci.draw_arc(head, r * 0.93, PI * 1.0, PI * 2.0, 18, hair.darkened(0.3), lw * 1.6, true)
			ci.draw_colored_polygon(PackedVector2Array([head + Vector2(-0.75, -0.55) * r, head + Vector2(-0.45, -1.2) * r,
				head + Vector2(0.4, -1.3) * r, head + Vector2(0.95, -0.85) * r, head + Vector2(0.75, -0.35) * r,
				head + Vector2(0.1, -0.6) * r]), hair)
		9:  # melena con flequillo recto
			_cap(ci, head, r, 1.12, hair)
			ci.draw_rect(Rect2(head + Vector2(-0.95, -0.75) * r, Vector2(1.9, 0.42) * r), hair)
			for side in [-1.0, 1.0]:
				ci.draw_rect(Rect2(head + Vector2(side * 1.0 - 0.17, -0.4) * r, Vector2(0.34, 1.0) * r), hair)


## Melena por detrás de la cabeza: cúpula arriba, caída por los lados hasta
## `bottom` (en radios bajo el centro) y puntas onduladas.
static func _hair_back(ci: CanvasItem, head: Vector2, r: float, width: float, bottom: float, hair: Color) -> void:
	var pts := PackedVector2Array()
	for i in 13:
		var t := PI + PI * i / 12.0
		pts.append(head + Vector2(cos(t) * width, sin(t) * width * 1.02 - 0.05) * r)
	pts.append(head + Vector2(width * 1.02, bottom - 0.15) * r)
	for i in 7:
		var x := width * (1.0 - i / 3.0)
		pts.append(head + Vector2(x, bottom + (0.12 if i % 2 == 0 else -0.04)) * r)
	pts.append(head + Vector2(-width * 1.02, bottom - 0.15) * r)
	ci.draw_colored_polygon(pts, hair)


## Media cúpula de pelo (o de gorro) sobre la cabeza.
static func _cap(ci: CanvasItem, head: Vector2, r: float, k: float, color: Color) -> void:
	var points := PackedVector2Array()
	for i in 17:
		var t := PI + PI * i / 16.0
		points.append(head + Vector2(cos(t), sin(t)) * r * k)
	ci.draw_colored_polygon(points, color)


static func _draw_face(ci: CanvasItem, head: Vector2, r: float, a: Dictionary, opts: Dictionary,
		look: Vector2, detail: bool, lw: float, hair: Color) -> void:
	var blink: bool = opts.get("blink", false)
	var eye_color := Color(a.get("eye_color", "3a2414"))
	var shift := look * r * (0.12 if detail else 0.23)
	for side in [-1.0, 1.0]:
		var eye := head + Vector2(side * 0.37, 0.07) * r + Vector2(shift.x, 0)
		if not detail:
			ci.draw_circle(eye, maxf(0.9, 0.157 * r), DARK)
			continue
		if blink:
			ci.draw_line(eye - Vector2(0.14 * r, 0), eye + Vector2(0.14 * r, 0), DARK, lw)
		else:
			ci.draw_circle(eye, 0.15 * r, Color("f6f2ea"))
			ci.draw_circle(eye + shift * 0.6 + Vector2(0, shift.y * 0.6), 0.09 * r, eye_color)
			ci.draw_circle(eye + shift * 0.6 + Vector2(0, shift.y * 0.6), 0.045 * r, DARK)
			ci.draw_circle(eye + Vector2(-0.03, -0.04) * r + shift * 0.6, 0.022 * r, Color(1, 1, 1, 0.9))
	if not detail:
		return
	var brow: float = opts.get("brow", 0.0)
	for side in [-1.0, 1.0]:
		var b := head + Vector2(side * 0.37, -0.2) * r + Vector2(shift.x * 0.5, 0)
		ci.draw_line(b + Vector2(-0.16 * r, side * brow * r), b + Vector2(0.16 * r, -side * brow * r), hair.darkened(0.25), lw * 1.2)
	# Nariz y mejillas.
	ci.draw_line(head + Vector2(0.02, 0.18) * r + Vector2(shift.x * 0.4, 0), head + Vector2(0.07, 0.3) * r + Vector2(shift.x * 0.4, 0), Color(0, 0, 0, 0.18), lw)
	for side in [-1.0, 1.0]:
		ci.draw_circle(head + Vector2(side * 0.55, 0.32) * r, 0.11 * r, Color(1.0, 0.45, 0.45, 0.12))
	var mouth: float = opts.get("mouth", 0.0)
	if mouth < 0.0 or float(opts.get("smile", 0.0)) >= 0.5:
		return
	var m := head + Vector2(0.0, 0.52) * r + Vector2(shift.x * 0.4, 0)
	var smile: float = opts.get("smile", 0.0)
	if mouth > 0.05:
		_ellipse(ci, m, 0.13 * r, 0.13 * r * (0.35 + mouth * 0.65), MOUTH)
	elif absf(smile) > 0.1:
		var from := PI * 0.15 if smile > 0.0 else PI * 1.15
		ci.draw_arc(m - Vector2(0, 0.1 * r * signf(smile)), 0.2 * r, from, from + PI * 0.7, 12, MOUTH, lw)
	else:
		ci.draw_line(m - Vector2(0.14 * r, 0), m + Vector2(0.14 * r, 0), MOUTH, lw)


## Sonrisa ancha con dientes. En sprites pequeños (sin detalle) es una cuña clara
## bajo la nariz; en retratos, media luna con dientes y contorno.
static func _draw_big_smile(ci: CanvasItem, head: Vector2, r: float, mouth: float, detail: bool, lw: float) -> void:
	var m := head + Vector2(0.0, 0.5) * r
	var half := 0.36 * r
	var depth := (0.2 + 0.25 * clampf(mouth, 0.0, 1.0)) * r
	var pts := PackedVector2Array()
	for k in 11:
		var t := PI * k / 10.0
		pts.append(m + Vector2(cos(t) * half, sin(t) * depth))
	ci.draw_colored_polygon(pts, Color("f4efe6") if detail or r > 5.0 else Color("f4efe6"))
	if detail:
		ci.draw_line(m + Vector2(-half * 0.92, depth * 0.35), m + Vector2(half * 0.92, depth * 0.35), Color(0, 0, 0, 0.18), maxf(1.0, lw * 0.6))
		ci.draw_polyline(pts, MOUTH, lw, true)
		ci.draw_line(m + Vector2(-half, 0), m + Vector2(half, 0), MOUTH, lw)
	else:
		ci.draw_line(m + Vector2(-half, 0), m + Vector2(half, 0), MOUTH, maxf(1.0, lw))


static func _draw_beard(ci: CanvasItem, head: Vector2, r: float, beard: int, hair: Color, opts: Dictionary, detail: bool, lw: float) -> void:
	if beard == 0:
		return
	# Mandíbula: arco por debajo de la cara y un borde superior a la altura de las mejillas.
	var jaw := PackedVector2Array()
	for i in 11:
		var t := 0.12 + (PI - 0.24) * i / 10.0
		jaw.append(head + Vector2(cos(t) * 0.99, sin(t) * 1.12 + 0.08) * r)
	jaw.append(head + Vector2(-0.7, 0.3) * r)
	jaw.append(head + Vector2(0.0, 0.38) * r)
	jaw.append(head + Vector2(0.7, 0.3) * r)
	match beard:
		1:  # barba de tres días
			ci.draw_colored_polygon(jaw, Color(hair, 0.3))
		2:  # completa (deja ver la boca)
			ci.draw_colored_polygon(jaw, hair)
			if detail and float(opts.get("smile", 0.0)) < 0.5:
				var mouth: float = opts.get("mouth", 0.0)
				var m := head + Vector2(0.0, 0.52) * r
				_ellipse(ci, m, 0.15 * r, 0.15 * r * (0.35 + maxf(0.0, mouth) * 0.65), MOUTH)
		3, 4:  # bigote (y candado: bigote + perilla)
			ci.draw_colored_polygon(PackedVector2Array([head + Vector2(-0.36, 0.44) * r, head + Vector2(0.0, 0.36) * r,
				head + Vector2(0.36, 0.44) * r, head + Vector2(0.3, 0.52) * r, head + Vector2(0.0, 0.45) * r,
				head + Vector2(-0.3, 0.52) * r]), hair)
			if beard == 4:
				ci.draw_colored_polygon(PackedVector2Array([head + Vector2(-0.22, 0.68) * r, head + Vector2(0.22, 0.68) * r,
					head + Vector2(0.12, 1.08) * r, head + Vector2(-0.12, 1.08) * r]), hair)


static func _draw_accessory(ci: CanvasItem, head: Vector2, r: float, acc: int, accent: Color, back: bool, look: Vector2, lw: float) -> void:
	var shift := Vector2(look.x * r * 0.12, 0)
	match acc:
		1, 2:  # lentes / lentes de sol
			if back:
				ci.draw_line(head + Vector2(-1.0, 0.02) * r, head + Vector2(1.0, 0.02) * r, DARK, lw)
				return
			var frame := Color("1a1620")
			for side in [-1.0, 1.0]:
				var c := head + Vector2(side * 0.37, 0.07) * r + shift
				var box := Rect2(c - Vector2(0.24, 0.17) * r, Vector2(0.48, 0.34) * r)
				if acc == 2:
					ci.draw_rect(box, Color("0d0d10"))
					ci.draw_line(box.position + Vector2(0.08, 0.08) * r, box.position + Vector2(0.18, 0.08) * r, Color(1, 1, 1, 0.55), lw * 0.8)
				else:
					ci.draw_rect(box, Color(0.75, 0.9, 1.0, 0.12))
					ci.draw_rect(box, frame, false, maxf(1.0, lw * 0.9))
			ci.draw_line(head + Vector2(-0.13, 0.04) * r + shift, head + Vector2(0.13, 0.04) * r + shift, frame, maxf(1.0, lw * 0.8))
		3:  # audífonos: almohadillas a los lados
			for side in [-1.0, 1.0]:
				ci.draw_rect(Rect2(head + Vector2(side * 1.05 - 0.2, -0.3) * r, Vector2(0.4, 0.62) * r), accent)
				ci.draw_rect(Rect2(head + Vector2(side * 1.05 - 0.2, -0.3) * r, Vector2(0.4, 0.62) * r), Color("1a1620"), false, maxf(1.0, lw * 0.6))
		4:  # gorra
			_cap(ci, head + Vector2(0, -0.05) * r, r, 1.13, accent)
			if back:
				ci.draw_rect(Rect2(head + Vector2(-0.3, -0.2) * r, Vector2(0.6, 0.14) * r), accent.darkened(0.3))
			else:
				ci.draw_colored_polygon(PackedVector2Array([head + Vector2(-1.1, -0.18) * r, head + Vector2(1.1, -0.18) * r,
					head + Vector2(1.0 + look.x * 0.4, 0.0) * r, head + Vector2(-1.0 + look.x * 0.4, 0.0) * r]), accent.darkened(0.25))
			ci.draw_circle(head + Vector2(0, -1.15) * r, 0.1 * r, accent.lightened(0.2))
		5:  # gorro de lana con pompón
			_cap(ci, head + Vector2(0, -0.08) * r, r, 1.16, accent)
			ci.draw_rect(Rect2(head + Vector2(-1.14, -0.42) * r, Vector2(2.28, 0.3) * r), accent.darkened(0.25))
			for k in 6:
				var x := -0.95 + k * 0.38
				ci.draw_line(head + Vector2(x, -0.42) * r, head + Vector2(x, -0.12) * r, accent.darkened(0.45), maxf(1.0, lw * 0.5))
			ci.draw_circle(head + Vector2(0, -1.32) * r, 0.24 * r, accent.lightened(0.35))


static func _tinted(c: Color, tint: Color) -> Color:
	return c.lerp(Color(tint, 1.0), 0.6) if tint.a > 0.0 else c
