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
const HAIR_NAMES := ["Rapado", "Corto", "Largo", "Cresta", "Moño", "Hacia atrás", "Afro", "Coleta", "Rapado lateral", "Melena con flequillo", "Entradas",
	"Ondulado", "Dos coletas", "Trenzas", "Flequillo lateral", "Rizos"]
## El oficinista (prólogo, retratos, NPC por capas) dibuja los 11 primeros; los que
## llegaron con el alumno (T180) usan el más parecido de ellos.
const OFFICE_HAIR_COUNT := 11
const OFFICE_HAIR := {11: 9, 12: 7, 13: 2, 14: 9, 15: 6}


static func office_hair(style: int) -> int:
	return int(OFFICE_HAIR.get(style, style)) if style >= OFFICE_HAIR_COUNT else style
const BEARD_NAMES := ["Sin barba", "Barba de tres días", "Barba completa", "Bigote", "Candado"]
## (T180: sin gorra ni gorro de lana; lo de la cabeza lo pone el equipo. Los guardados
## que los llevaban, 4 y 5, cargan sin accesorio.)
const ACCESSORY_NAMES := ["Nada", "Lentes", "Lentes de sol", "Audífonos"]
const HEIGHT_NAMES := ["Baja", "Media", "Alta"]
const HEIGHT_VALUES := [0.9, 1.0, 1.08]
## Opcionales (sobre todo para NPCs): "height" (0,8-1,15, estatura) y
## "hair_streaks" (color de las canas o mechas).
const MIN_HEIGHT := 0.8
const MAX_HEIGHT := 1.15
const DARK := Color(0.08, 0.06, 0.06)
## Cabeza en la figura (T160): radio y altura del centro sobre los pies, a escala 1.
const HEAD_R := 8.6
const HEAD_Y := -32.0
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
	var acc := int(d.get("accessory", 0))
	result["accessory"] = acc if acc >= 0 and acc < ACCESSORY_NAMES.size() else 0
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
	if GEARS.has(String(d.get("gear", ""))):   # equipo de la clase (T161)
		result["gear"] = String(d["gear"])
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
## `pose` (T72; solo el jugador lo pasa): {state, t (0..1 de la acción), time (s),
## weapon (tipo: "sword", "axe", "mace", "dagger" o ""), glow (Color de las manos al
## lanzar)}. Estados: "idle" (respira), "walk", "run" (zancada y balanceo mayores),
## "attack" (golpe según el arma), "shoot" (lanza hacia delante), "cast" (sube las
## manos), "channel" (manos delante, brillando), "hurt" (retrocede), "dodge" (se
## agacha y rueda) y "dead" (cae de lado). Sin pose, la figura de siempre.
static func draw(ci: CanvasItem, feet: Vector2, scale: float, a: Dictionary,
		facing := Vector2.DOWN, tint := Color(0, 0, 0, 0), walk_phase := -1.0, pose := {}) -> void:
	var state := String(pose.get("state", ""))
	var t := clampf(float(pose.get("t", 0.0)), 0.0, 1.0)
	var xf := pose_transform(state, t, facing, scale)
	if not xf.is_empty():
		# Estados que mueven la figura entera: se dibuja girada / aplastada sobre los pies.
		if state == "dead":
			var k := absf(float(xf[1])) / (PI * 0.5)
			_ellipse(ci, feet + Vector2(-signf(facing.x if facing.x != 0.0 else 1.0) * 15.0 * scale * k, 0.0),
				lerpf(11.0, 20.0, k) * scale, 4.4 * scale, Color(0, 0, 0, 0.4))
		ci.draw_set_transform(feet + xf[0], xf[1], xf[2])
		var inner := pose.duplicate()
		inner["state"] = "limp" if state == "dead" else ""
		draw(ci, Vector2.ZERO, scale, a, facing, tint, -1.0, inner)
		ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		return
	var skin := _tinted(Color(a["skin_tone"]), tint)
	var outfit := _tinted(Color(a["outfit_color"]), tint)
	var accent := _tinted(Color(a.get("accent_color", outfit.darkened(0.55).to_html(false))), tint)
	var width: float = BODY_WIDTH[int(a["body"])]
	var back := facing.y < -0.5
	var look := clampf(facing.x, -1.0, 1.0)
	var profile := absf(look) > 0.6 and absf(facing.y) < 0.75   # de perfil

	var walking := walk_phase >= 0.0
	var run_k := 1.45 if state == "run" else 1.0
	var swing := sin(walk_phase) * run_k if walking else 0.0          # -1..1, pierna izquierda delante
	var bob := absf(cos(walk_phase)) * 1.3 * run_k if walking else 0.0  # el cuerpo sube entre pisadas
	if state == "idle":
		bob = (sin(float(pose.get("time", 0.0)) * 2.4) * 0.5 + 0.5) * 0.7   # respira
	# Brazo que golpea (el del lado al que mira) y si los dos brazos posan (hechizos).
	var side := 1.0 if look >= 0.0 else -1.0
	var weapon := String(pose.get("weapon", ""))
	# Con qué gesto mueve el brazo al atacar (T102a): "swing" (tajo) o "thrust" (estocada);
	# sin él, el del arma que lleva. Así se hornean las hojas con cualquier arma.
	var arm_weapon := weapon
	match String(pose.get("weapon_class", "")):
		"swing":
			arm_weapon = "sword"
		"thrust":
			arm_weapon = "dagger"
	var posing := state in ["attack", "shoot", "cast", "channel", "type"]
	var both_arms := state in ["cast", "channel", "type"]
	# Estatura: escala las alturas (la cabeza mantiene su tamaño).
	var hs := float(a.get("height", 1.0))
	var p := func(x: float, y: float) -> Vector2: return feet + Vector2(x, y * hs) * scale
	# Parte superior del cuerpo, desplazada por el balanceo.
	var u := func(x: float, y: float) -> Vector2: return feet + Vector2(x, (y - bob) * hs) * scale

	# Sombra (se encoge un poco cuando el cuerpo sube).
	var shadow_r := (11.0 - bob * 0.6) * scale * width
	if state != "limp":   # tumbado, la sombra la pone quien lo gira
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
		ci.draw_rect(Rect2(p.call(x + 2.6 * width, y_top), Vector2(1.4 * width, length * hs) * scale), legs.darkened(0.25))   # (T160) sombra
		ci.draw_rect(Rect2(p.call(x - 0.3, y_top + length - 1.6), Vector2(4.6 * width, 1.8) * scale), accent.darkened(0.3))

	# Brazos (detrás del torso), en oposición a las piernas.
	var arm_color := outfit.darkened(0.2)
	var carry_hand := Vector2.INF   # dónde lleva el arma si no está golpeando
	var side_hand := Vector2.INF    # la mano del lado al que mira, en la pose que tenga (T162: objetos en la mano)
	for arm: float in [-1.0, 1.0]:
		if posing and (both_arms or arm == side):
			continue   # este brazo se dibuja en su pose, delante del torso
		var arm_swing := -swing * arm * (2.2 if not profile else 0.0)
		var ax := (-10.5 if arm < 0.0 else 7.0) * width
		var hand_x := (-8.75 if arm < 0.0 else 8.75) * width
		if profile:
			ax = -1.75 * width + swing * arm * 3.0 * signf(look)
			hand_x = ax + 1.75 * width
		if state == "limp":
			arm_swing = 0.0
		ci.draw_rect(Rect2(u.call(ax, -23.0 + arm_swing * 0.4), Vector2(3.5 * width, 12.0 * hs) * scale), arm_color)
		var hand: Vector2 = u.call(hand_x, -10.5 + arm_swing)
		ci.draw_circle(hand, 1.9 * scale * width, skin)
		if arm == side:
			carry_hand = hand
			side_hand = hand
	# Arma en reposo: en la mano, apuntando hacia arriba y hacia fuera (de espaldas, detrás del torso).
	var carry := weapon != "" and carry_hand != Vector2.INF and state != "limp"
	if carry and back:
		draw_weapon(ci, carry_hand, Vector2(side * 0.45, -0.9).normalized(), weapon, scale, tint)

	# Torso: trapecio de hombros a cintura (más estrecho de perfil), con cuello y cinturón.
	var tw := width * (0.75 if profile else 1.0)
	var lean := 0.8 * signf(look) * run_k * run_k if profile and walking else 0.0
	ci.draw_colored_polygon(PackedVector2Array([
		u.call(-8.0 * tw + lean, -24.0), u.call(8.0 * tw + lean, -24.0),
		u.call(6.0 * tw, -8.0), u.call(-6.0 * tw, -8.0)]), outfit)
	# Tres tonos (T160, como la referencia chibi): sombra en el lado derecho y abajo,
	# brillo en el hombro izquierdo.
	ci.draw_colored_polygon(PackedVector2Array([
		u.call(3.5 * tw + lean, -24.0), u.call(8.0 * tw + lean, -24.0),
		u.call(6.0 * tw, -8.0), u.call(2.5 * tw, -8.0)]), outfit.darkened(0.22))
	ci.draw_colored_polygon(PackedVector2Array([
		u.call(-6.0 * tw, -12.0), u.call(6.0 * tw, -12.0), u.call(6.0 * tw, -8.0), u.call(-6.0 * tw, -8.0)]), outfit.darkened(0.32))
	ci.draw_colored_polygon(PackedVector2Array([
		u.call(-7.4 * tw + lean, -23.4), u.call(-3.5 * tw + lean, -23.4), u.call(-5.4 * tw, -19.0)]), outfit.lightened(0.28))
	if not back and not profile:
		var shirt := _tinted(Color(a["shirt_color"]), tint) if a.has("shirt_color") else accent
		ci.draw_colored_polygon(PackedVector2Array([u.call(-3.0 + lean, -24.0), u.call(3.0 + lean, -24.0), u.call(lean, -19.0)]), shirt)
	ci.draw_rect(Rect2(u.call(-6.0 * tw, -11.0), Vector2(12.0 * tw, 2.0 * hs) * scale), accent)

	if carry and not back:
		draw_weapon(ci, carry_hand, Vector2(side * 0.45, -0.9).normalized(), weapon, scale, tint)
		ci.draw_circle(carry_hand, 1.9 * scale * width, skin)   # la mano, encima del mango
	# Brazos en pose (golpe, lanzamiento, hechizo): del hombro a la mano, con el arma o el brillo.
	if posing:
		var time := float(pose.get("time", 0.0))
		for arm: float in ([-1.0, 1.0] if both_arms else [side]):
			var out := signf(look) if profile else arm
			if state == "type" and not profile:
				out = -arm * 0.6   # teclear (T162): las manos al frente, hacia el centro
			var shoulder: Vector2 = u.call((lean if profile else 7.5 * arm * tw), -22.0)
			var ang := arm_angle(state, arm_weapon, t, time) * (0.85 if both_arms and arm != side else 1.0)
			var d := Vector2(sin(ang) * out, cos(ang))
			var hand := shoulder + d * 12.0 * hs * scale * arm_reach(state, arm_weapon, t)
			if arm == side:
				side_hand = hand
			ci.draw_line(shoulder, hand, arm_color, 3.5 * width * scale)
			if state in ["attack", "shoot"] and weapon != "":
				draw_weapon(ci, hand, d, weapon, scale, tint)
			ci.draw_circle(hand, 1.9 * scale * width, skin)
			if pose.has("glow") and state in ["cast", "channel"]:
				var g: Color = pose["glow"]
				var pulse := 0.75 + 0.25 * sin(time * 9.0) if state == "channel" else minf(1.0, t * 2.5)
				ci.draw_circle(hand, 4.5 * scale * pulse, Color(g, 0.35))
				ci.draw_circle(hand, 2.4 * scale * pulse, Color(g.lightened(0.4), 0.8))

	# Cabeza: grande, chibi (T160, como la referencia del usuario; antes radio 7 en -31).
	var head: Vector2 = u.call(lean, HEAD_Y)
	draw_head(ci, head, HEAD_R * scale, a, {"back": back, "look": Vector2(look, 0.0), "tint": tint, "profile": profile})
	if GEARS.has(String(a.get("gear", ""))):
		if side_hand == Vector2.INF:
			side_hand = u.call(side * 8.75 * width, -10.5)
		_draw_gear(ci, String(a["gear"]), u, head, HEAD_R * scale, tw, lean, back, profile, side, scale, tint, side_hand)


## Equipo de oficio de cada clase (T161), encima de la figura: lo que la distingue
## de lejos. Colores fijos (no se tiñen con los del creador). Detrás, los objetos
## propios de los NPC (T162, `gear` en su apariencia de npcs.json).
const CLASS_GEARS := ["guerrero", "duelista", "exploradora", "hacker", "hechicero", "templario", "full_stack"]
const NPC_PROPS := ["cafe", "monitor", "laptop", "maleta", "pantalla", "mapa", "tablas", "tablero", "bolsa", "cartel",
	"planos", "rosa", "pila"]
const GEARS := CLASS_GEARS + NPC_PROPS


## Apariencia con el equipo de la clase `class_id` (si tiene).
static func with_gear(a: Dictionary, class_id: String) -> Dictionary:
	var out := a.duplicate()
	if GEARS.has(class_id):
		out["gear"] = class_id
	return out


static func _draw_gear(ci: CanvasItem, gear: String, u: Callable, head: Vector2, r: float, tw: float, lean: float,
		back: bool, profile: bool, side: float, scale: float, tint: Color, hand: Vector2) -> void:
	var c := func(html: String, alpha := 1.0) -> Color: return Color(_tinted(Color(html), tint), alpha)
	var front := not back and not profile
	var box := func(center: Vector2, size: Vector2, color: Color) -> void:
		ci.draw_rect(Rect2(center - size * scale * 0.5, size * scale), color)
	match gear:
		# --- Objetos de los NPC (T162) ---
		"cafe":   # Aida: su taza de café (en la mano; se la lleva a la boca)
			box.call(hand + Vector2(0, -1.6) * scale, Vector2(3.4, 3.8), c.call("f4f1ea"))
			box.call(hand + Vector2(0, -3.2) * scale, Vector2(3.0, 0.8), c.call("5a3a22"))
			ci.draw_arc(hand + Vector2(side * 2.1, -1.6) * scale, 1.1 * scale, -PI * 0.5, PI * 0.5, 6, c.call("f4f1ea"), 0.7 * scale)
		"monitor":   # Mario: cargando un monitor
			if back:
				box.call(u.call(0.0, -15.5), Vector2(11.0, 8.0), c.call("2b2f3a"))
			else:
				box.call(u.call(lean, -15.5), Vector2(11.0, 8.0), c.call("2b2f3a"))
				box.call(u.call(lean, -15.8), Vector2(9.2, 6.2), c.call("3f8fd6"))
				box.call(u.call(lean - 1.5, -16.8), Vector2(4.0, 0.8), c.call("bfe6ff"))
		"laptop":   # Rafa: tecleando en una laptop
			if not back:
				var at: Vector2 = u.call(lean + (side * 3.0 if profile else 0.0), -14.0)
				box.call(at + Vector2(0, 2.4) * scale, Vector2(11.0, 1.6), c.call("8a8f99"))
				box.call(at - Vector2(0, 1.8) * scale, Vector2(10.0, 6.6), c.call("22262e"))
				for k in 3:
					box.call(at + Vector2(-1.2 + k * 0.6, -3.6 + k * 1.6) * scale, Vector2(5.0 - k * 1.2, 0.7), c.call("5dff7a"))
		"maleta":   # Nacho: maleta abierta llena de RAM
			var m := hand + Vector2(0, 2.6) * scale
			box.call(m, Vector2(8.0, 5.4), c.call("6b4a2b"))
			for k in 3:
				box.call(m + Vector2(-2.5 + k * 2.5, -0.6) * scale, Vector2(1.6, 3.4), c.call("2b8a5a"))
				box.call(m + Vector2(-2.5 + k * 2.5, 1.0) * scale, Vector2(1.6, 0.6), c.call("e6c34a"))
		"pantalla":   # B.O.B.: la cabeza es una pantalla con cara
			box.call(head, Vector2(2.4, 2.0) * r / scale, c.call("2b2f3a"))
			if not back:
				box.call(head, Vector2(2.0, 1.6) * r / scale, c.call("10343f"))
				for s in [-1.0, 1.0]:
					box.call(head + Vector2(s * 0.42, -0.15) * r, Vector2(0.32, 0.36) * r / scale, c.call("4fe0ff"))
				ci.draw_arc(head + Vector2(0, 0.15) * r, 0.36 * r, PI * 0.2, PI * 0.8, 8, c.call("4fe0ff"), maxf(1.0, 0.12 * r))
			ci.draw_line(head + Vector2(0, -1.0) * r, head + Vector2(0, -1.5) * r, c.call("8a8f99"), maxf(1.0, 0.1 * r))
			ci.draw_circle(head + Vector2(0, -1.55) * r, 0.14 * r, c.call("ff5a5a"))
		"mapa":   # Iris: un mapa desplegado, perdida
			var p := hand + Vector2(0, -2.0) * scale
			box.call(p, Vector2(7.0, 5.4), c.call("e8dcb0"))
			ci.draw_line(p + Vector2(-2.6, 1.6) * scale, p + Vector2(0.4, -0.6) * scale, c.call("d64a4a"), 0.7 * scale)
			ci.draw_line(p + Vector2(0.4, -0.6) * scale, p + Vector2(2.4, 1.2) * scale, c.call("d64a4a"), 0.7 * scale)
		"tablas":   # Fantasma del DBA: tablas flotando a su alrededor
			for k in 2:
				var t := head + Vector2((k * 2 - 1) * 1.9, -0.6 + k * 1.4) * r
				ci.draw_rect(Rect2(t - Vector2(3.5, 2.5) * scale, Vector2(7.0, 5.0) * scale), c.call("9fe6ff", 0.75), false, 0.7 * scale)
				ci.draw_line(t + Vector2(-3.5, -0.8) * scale, t + Vector2(3.5, -0.8) * scale, c.call("9fe6ff", 0.75), 0.6 * scale)
				ci.draw_line(t + Vector2(-0.5, -2.5) * scale, t + Vector2(-0.5, 2.5) * scale, c.call("9fe6ff", 0.75), 0.6 * scale)
		"tablero":   # Clara: portapapeles con los incidentes abiertos
			var p := hand + Vector2(side * 1.0, -3.0) * scale
			box.call(p, Vector2(5.6, 7.2), c.call("8a6d3b"))
			box.call(p + Vector2(0, 0.4) * scale, Vector2(4.6, 5.8), c.call("f4f6f8"))
			for k in 3:
				ci.draw_circle(p + Vector2(-1.4, -1.6 + k * 1.7) * scale, 0.5 * scale, c.call("e04848" if k < 2 else "4fb36b"))
		"bolsa":   # El Recolector: bolsa de basura al hombro
			var p: Vector2 = u.call(-side * 7.5 * tw + lean, -27.0)
			ci.draw_circle(p, 5.2 * scale, c.call("2b2f3a"))
			ci.draw_circle(p + Vector2(-1.4, -1.6) * scale, 1.4 * scale, c.call("4a5060"))
			ci.draw_line(p + Vector2(side * 3.0, 2.0) * scale, hand, c.call("2b2f3a"), 1.0 * scale)
		"cartel":   # Sindicato de Huérfanos: cartel de protesta «404»
			var top := hand + Vector2(0, -16.0) * scale
			ci.draw_line(hand, top, c.call("6b4a2b"), 1.0 * scale)
			box.call(top + Vector2(0, -2.5) * scale, Vector2(11.0, 6.4), c.call("f4f1ea"))
			for k in 3:   # «4 0 4» con palotes
				var x := (-3.4 + k * 3.4) * scale
				box.call(top + Vector2(x, -2.5 * scale), Vector2(1.6, 3.6), c.call("d64a4a"))
		"planos":   # M. Páez: planos enrollados bajo el brazo
			var p := hand + Vector2(0, -3.0) * scale
			ci.draw_line(p + Vector2(-side * 5.0, -2.0) * scale, p + Vector2(side * 2.0, 1.0) * scale, c.call("3b6fd6"), 2.4 * scale)
			ci.draw_circle(p + Vector2(side * 2.0, 1.0) * scale, 1.2 * scale, c.call("dfe8ff"))
		"rosa":   # Eugenio: una rosa
			ci.draw_line(hand, hand + Vector2(side * 1.0, -5.0) * scale, c.call("3a8a3a"), 0.7 * scale)
			ci.draw_circle(hand + Vector2(side * 1.0, -5.6) * scale, 1.5 * scale, c.call("d62e4a"))
			ci.draw_circle(hand + Vector2(side * 0.6, -6.0) * scale, 0.6 * scale, c.call("ff7088"))
		"pila":   # Berta: la pila CR2032 que es ella
			var p: Vector2 = u.call(-side * 8.0 * tw, -18.0)
			ci.draw_circle(p, 4.6 * scale, c.call("9aa0aa"))
			ci.draw_circle(p, 3.8 * scale, c.call("d2d6de"))
			ci.draw_line(p + Vector2(-1.4, 0) * scale, p + Vector2(1.4, 0) * scale, c.call("4a5060"), 0.7 * scale)
			ci.draw_line(p + Vector2(0, -1.4) * scale, p + Vector2(0, 1.4) * scale, c.call("4a5060"), 0.7 * scale)
		# --- Equipo de las clases (T161) ---
		"guerrero":   # Técnico de Soporte: chaleco reflectante y gafete
			var vest: Color = c.call("f08a24")
			if front:
				for s in [-1.0, 1.0]:
					ci.draw_colored_polygon(PackedVector2Array([u.call(s * 8.2 * tw + lean, -24.0), u.call(s * 3.0 * tw + lean, -24.0),
						u.call(s * 2.6 * tw, -9.0), u.call(s * 6.4 * tw, -9.0)]), vest)
					ci.draw_rect(Rect2(u.call((-7.6 * tw if s < 0.0 else 2.8 * tw), -16.5), Vector2(4.8 * tw, 1.6) * scale), c.call("e8eef2"))
				ci.draw_line(u.call(-1.5 * tw, -24.0), u.call(1.2 * tw, -18.5), c.call("2b6cb0"), 0.8 * scale)
				ci.draw_rect(Rect2(u.call(0.2 * tw, -18.8), Vector2(2.8, 3.4) * scale), c.call("f4f6f8"))
				ci.draw_rect(Rect2(u.call(0.2 * tw, -18.8), Vector2(2.8, 1.1) * scale), c.call("2b6cb0"))
			else:
				ci.draw_colored_polygon(PackedVector2Array([u.call(-8.2 * tw + lean, -24.0), u.call(8.2 * tw + lean, -24.0),
					u.call(6.4 * tw, -9.0), u.call(-6.4 * tw, -9.0)]), vest)
				ci.draw_rect(Rect2(u.call(-7.6 * tw, -16.5), Vector2(15.2 * tw, 1.6) * scale), c.call("e8eef2"))
		"duelista":   # Tester QA: bata blanca larga, etiqueta de bug y lupa al cinto
			var coat: Color = c.call("eef1f4")
			if front:
				for s in [-1.0, 1.0]:
					ci.draw_colored_polygon(PackedVector2Array([u.call(s * 8.6 * tw + lean, -24.0), u.call(s * 3.4 * tw + lean, -24.0),
						u.call(s * 3.6 * tw, -2.5), u.call(s * 8.0 * tw, -2.5)]), coat)
					ci.draw_line(u.call(s * 3.4 * tw + lean, -24.0), u.call(s * 3.6 * tw, -2.5), c.call("c3c9d2"), 0.8 * scale)
				ci.draw_circle(u.call(-6.0 * tw, -19.0), 1.3 * scale, c.call("e04848"))
			else:
				ci.draw_colored_polygon(PackedVector2Array([u.call(-8.6 * tw + lean, -24.0), u.call(8.6 * tw + lean, -24.0),
					u.call(8.0 * tw, -2.5), u.call(-8.0 * tw, -2.5)]), coat)
				ci.draw_line(u.call(0.0, -12.0), u.call(0.0, -2.5), c.call("c3c9d2"), 0.8 * scale)
			var lens: Vector2 = u.call(side * 8.4 * tw, -6.5)
			ci.draw_line(lens + Vector2(0, -2.0) * scale, lens + Vector2(0, -4.6) * scale, c.call("6b4a2b"), 1.0 * scale)
			ci.draw_circle(lens, 2.0 * scale, c.call("8a8f99"))
			ci.draw_circle(lens, 1.3 * scale, c.call("bfe6ff"))
		"exploradora":   # Frontend: capucha de sudadera y paleta de colores flotando
			var hood: Color = c.call("7a5cc4")
			ci.draw_colored_polygon(PackedVector2Array([u.call(-8.4 * tw + lean, -25.5), u.call(8.4 * tw + lean, -25.5),
				u.call(6.0 * tw + lean, -21.5), u.call(-6.0 * tw + lean, -21.5)]), hood)
			if front:
				ci.draw_line(u.call(-1.2 * tw, -21.5), u.call(-1.4 * tw, -16.0), c.call("f4f6f8"), 0.8 * scale)
				ci.draw_line(u.call(1.2 * tw, -21.5), u.call(1.4 * tw, -16.0), c.call("f4f6f8"), 0.8 * scale)
			var pal: Vector2 = u.call(-side * 13.5, -31.0)
			var swatches := ["e05a5a", "f2c230", "4fb36b", "4b8bd6"]
			for k in swatches.size():
				var at := pal + Vector2((k % 2) * 3.2, (k / 2) * 3.2) * scale
				ci.draw_rect(Rect2(at, Vector2(2.8, 2.8) * scale), c.call(swatches[k]))
		"hacker":   # Ingeniera de Prompts: audífonos de neón y un globo de texto
			var neon: Color = c.call("2fe0b0")
			ci.draw_arc(head, 1.14 * r, PI * 1.08, PI * 1.92, 18, neon, maxf(1.0, r * 0.2), true)
			for s in ([-1.0, 1.0] if not profile else [side]):
				ci.draw_circle(head + Vector2(s * 1.02, 0.05) * r, 0.34 * r, c.call("22262e"))
				ci.draw_circle(head + Vector2(s * 1.02, 0.05) * r, 0.2 * r, neon)
			var bubble: Vector2 = head + Vector2(side * 1.45, -1.55) * r
			ci.draw_rect(Rect2(bubble - Vector2(5.0, 3.2) * scale, Vector2(10.0, 6.4) * scale), c.call("f4f6f8"))
			ci.draw_colored_polygon(PackedVector2Array([bubble + Vector2(-side * 2.5, 3.0) * scale, bubble + Vector2(-side * 0.5, 3.0) * scale,
				bubble + Vector2(-side * 4.5, 5.6) * scale]), c.call("f4f6f8"))
			for k in 3:
				ci.draw_circle(bubble + Vector2(-2.6 + k * 2.6, 0.0) * scale, 0.75 * scale, c.call("2b2f3a"))
		"hechicero":   # Científico de Datos: tableta holográfica con una gráfica
			var o: Vector2 = u.call(side * 12.0, -25.0)
			var w := 9.0 * scale
			var h := 7.0 * scale
			var panel := Rect2(o + Vector2(0.0 if side > 0.0 else -w, 0.0), Vector2(w, h))
			ci.draw_rect(panel, c.call("4fc8ff", 0.4))
			ci.draw_rect(panel, c.call("9fe6ff"), false, 0.8 * scale)
			for k in 3:
				var bh: float = [2.5, 4.5, 3.5][k] * scale
				ci.draw_rect(Rect2(panel.position + Vector2((1.4 + k * 2.6) * scale, h - 1.0 * scale - bh), Vector2(1.6 * scale, bh)), c.call("dff7ff"))
		"templario":   # DevOps: casco de obra con un LED de estado y un cable al hombro
			var hat: Color = c.call("f2c230")
			var dome := PackedVector2Array()
			for i in 13:
				var t := PI + PI * i / 12.0
				dome.append(head + Vector2(cos(t) * 1.16, sin(t) * 1.16 - 0.12) * r)
			ci.draw_colored_polygon(dome, hat)
			ci.draw_rect(Rect2(head + Vector2(-1.36, -0.22) * r, Vector2(2.72, 0.24) * r), hat.darkened(0.2))
			ci.draw_arc(head + Vector2(0, -0.12) * r, 0.8 * r, PI * 1.2, PI * 1.4, 6, hat.lightened(0.45), maxf(1.0, r * 0.14), true)
			if not back:
				ci.draw_circle(head + Vector2(0.0 if not profile else side * 0.7, -0.75) * r, 0.17 * r, c.call("5dff7a"))
			var sh: Vector2 = u.call(-side * 7.5 * tw + lean, -23.0)
			ci.draw_arc(sh + Vector2(0, 4.0) * scale, 4.0 * scale, -PI * 0.9, PI * 0.4, 10, c.call("2b2f3a"), 1.2 * scale, true)
		"full_stack":   # Full Stack: mochila con laptop y stickers
			var pack: Color = c.call("3b4252")
			if back:
				ci.draw_rect(Rect2(u.call(-6.0 * tw, -23.0), Vector2(12.0 * tw, 12.5) * scale), pack)
				ci.draw_rect(Rect2(u.call(-5.0 * tw, -25.5), Vector2(10.0 * tw, 2.6) * scale), c.call("c0c6d0"))
				ci.draw_circle(u.call(-2.5 * tw, -18.0), 1.2 * scale, c.call("e05a5a"))
				ci.draw_circle(u.call(2.0 * tw, -15.0), 1.2 * scale, c.call("f2c230"))
				ci.draw_rect(Rect2(u.call(-1.0 * tw, -20.5), Vector2(2.2, 2.2) * scale), c.call("4fb36b"))
			elif profile:
				ci.draw_rect(Rect2(u.call(-side * 4.0 * tw - (4.5 * tw if side > 0.0 else 0.0), -23.0), Vector2(4.5 * tw, 12.0) * scale), pack)
				ci.draw_rect(Rect2(u.call(-side * 4.0 * tw - (4.5 * tw if side > 0.0 else 0.0), -25.5), Vector2(3.5 * tw, 2.6) * scale), c.call("c0c6d0"))
			else:
				for s in [-1.0, 1.0]:
					ci.draw_line(u.call(s * 5.0 * tw + lean, -24.0), u.call(s * 4.4 * tw, -12.0), c.call("2b2f3a"), 1.4 * scale)
				ci.draw_rect(Rect2(u.call(-7.4 * tw, -26.5), Vector2(14.8 * tw, 2.4) * scale), pack)


## Transformación de la figura entera para los estados que la mueven toda:
## [desplazamiento, giro, escala], o [] si no hace falta.
static func pose_transform(state: String, t: float, facing: Vector2, scale: float) -> Array:
	var side := 1.0 if facing.x >= 0.0 else -1.0
	match state:
		"dead":
			var k := 1.0 - pow(1.0 - t, 3.0)   # cae rápido y se asienta
			return [Vector2(-side * 3.0 * scale * k, 0.0), -side * PI * 0.5 * k, Vector2.ONE]
		"dodge":
			return [Vector2.ZERO, side * 0.45 * sin(PI * t), Vector2(1.1, 0.62 + 0.38 * absf(2.0 * t - 1.0) * 0.5)]
		"hurt":
			var back := -facing.normalized() if facing != Vector2.ZERO else Vector2.UP
			return [back * 3.0 * scale * (1.0 - t), -side * 0.18 * (1.0 - t), Vector2.ONE]
	return []


## Ángulo del brazo en pose (0 = colgando, PI/2 = estirado hacia fuera, PI = arriba).
static func arm_angle(state: String, weapon: String, t: float, time := 0.0) -> float:
	match state:
		"attack":
			if weapon in ["sword", "axe", "mace"]:
				# Arriba y atrás, golpe hacia abajo y delante, vuelve un poco.
				if t < 0.35:
					return lerpf(0.5, 2.7, t / 0.35)
				if t < 0.55:
					return lerpf(2.7, 0.35, (t - 0.35) / 0.2)
				return lerpf(0.35, 0.6, (t - 0.55) / 0.45)
			# Daga o puño: estocada recta.
			return lerpf(1.1, 1.55, t / 0.3) if t < 0.3 else 1.55
		"shoot":
			return lerpf(0.6, 2.4, t / 0.35) if t < 0.35 else lerpf(2.4, 1.4, minf(1.0, (t - 0.35) / 0.25))
		"cast":
			return lerpf(0.3, 1.9, 1.0 - pow(1.0 - minf(1.0, t / 0.4), 2.0))
		"channel":
			return 1.5 + sin(time * 8.0) * 0.08
		"type":   # teclear: las manos suben y bajan un poco, alternando (T162)
			return 0.62 + 0.12 * cos(time * TAU)
	return 0.0


## En qué punto de la acción (0..1) llega el golpe (T72b): cuando el arma pasa por
## delante en el arco, cuando la estocada llega al final o cuando se suelta lo lanzado.
static func impact_fraction(state: String, weapon: String) -> float:
	match state:
		"attack":
			return 0.47 if weapon in ["sword", "axe", "mace"] else 0.3
		"shoot":
			return 0.38
	return 0.0


## Cuánto se estira el brazo (1 = normal): la estocada lo alarga.
static func arm_reach(state: String, weapon: String, t: float) -> float:
	if state == "attack" and not (weapon in ["sword", "axe", "mace"]):
		return lerpf(0.6, 1.25, minf(1.0, t / 0.3)) if t < 0.6 else lerpf(1.25, 0.9, (t - 0.6) / 0.4)
	return 1.0


## Arma en la mano `hand`, apuntando hacia `dir`, según su tipo.
static func draw_weapon(ci: CanvasItem, hand: Vector2, dir: Vector2, kind: String, scale: float, tint := Color(0, 0, 0, 0)) -> void:
	var metal := _tinted(Color("c8ccd6"), tint)
	var wood := _tinted(Color("6b4a2b"), tint)
	var perp := Vector2(-dir.y, dir.x)
	match kind:
		"sword":
			ci.draw_line(hand - dir * 3.0 * scale, hand + dir * 1.5 * scale, wood, 1.8 * scale)
			ci.draw_line(hand + dir * 1.5 * scale - perp * 3.0 * scale, hand + dir * 1.5 * scale + perp * 3.0 * scale, _tinted(Color("8a6d3b"), tint), 1.6 * scale)
			ci.draw_line(hand + dir * 2.0 * scale, hand + dir * 15.0 * scale, metal, 2.2 * scale)
			ci.draw_line(hand + dir * 2.0 * scale, hand + dir * 14.0 * scale, metal.lightened(0.35), 0.7 * scale)
		"axe":
			ci.draw_line(hand - dir * 3.0 * scale, hand + dir * 12.0 * scale, wood, 1.7 * scale)
			var tip := hand + dir * 11.0 * scale
			ci.draw_colored_polygon(PackedVector2Array([tip - dir * 3.0 * scale, tip + dir * 1.5 * scale,
				tip + dir * 3.0 * scale + perp * 5.0 * scale, tip - dir * 4.5 * scale + perp * 5.0 * scale]), metal)
		"mace":
			ci.draw_line(hand - dir * 3.0 * scale, hand + dir * 10.0 * scale, wood, 1.7 * scale)
			var head := hand + dir * 11.5 * scale
			for k in 6:
				var sp := Vector2.from_angle(TAU * k / 6.0)
				ci.draw_line(head, head + sp * 4.2 * scale, metal.darkened(0.3), 1.2 * scale)
			ci.draw_circle(head, 3.0 * scale, metal.darkened(0.15))
		"dagger":
			ci.draw_line(hand - dir * 2.0 * scale, hand + dir * 1.0 * scale, wood, 1.6 * scale)
			ci.draw_line(hand + dir * 1.0 * scale, hand + dir * 8.0 * scale, metal, 1.6 * scale)


## Tipo de arma para dibujarla, por las etiquetas de su base ("" si no se dibuja).
static func weapon_kind(item: Item) -> String:
	if item == null:
		return ""
	for k in ["sword", "axe", "mace", "dagger"]:
		if item.base.get("tags", []).has(k):
			return k
	return ""


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
	var style := office_hair(int(a["hair"]))
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

	# Piel en dos tonos (T160): sombra abajo a la derecha y la luz de arriba a la izquierda.
	ci.draw_circle(head, r, skin.darkened(0.2))
	ci.draw_circle(head + Vector2(-0.1, -0.1) * r, r * 0.86, skin)

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
	# Brillo arriba a la izquierda (T160: sombreado de la referencia chibi).
	ci.draw_arc(head, r * k * 0.72, PI * 1.18, PI * 1.45, 8, color.lightened(0.4), maxf(1.0, r * 0.16), true)


static func _draw_face(ci: CanvasItem, head: Vector2, r: float, a: Dictionary, opts: Dictionary,
		look: Vector2, detail: bool, lw: float, hair: Color) -> void:
	var blink: bool = opts.get("blink", false)
	var eye_color := Color(a.get("eye_color", "3a2414"))
	var shift := look * r * (0.12 if detail else 0.23)
	for side in [-1.0, 1.0]:
		var eye := head + Vector2(side * 0.37, 0.07) * r + Vector2(shift.x, 0)
		if not detail:
			# Ojo chibi (T160): grande y oscuro, con un brillo cuando hay sitio para él; algo
			# más abajo, porque en las hojas el pelo va encima de la cara y lo cortaba.
			var e := eye + Vector2(0, 0.14) * r
			ci.draw_circle(e, maxf(0.9, 0.18 * r), DARK)
			if r >= 10.0:
				ci.draw_circle(e + Vector2(-0.06, -0.06) * r, 0.065 * r, Color(1, 1, 1, 0.95))
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
