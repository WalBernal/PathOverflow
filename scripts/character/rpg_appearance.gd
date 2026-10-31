class_name RpgAppearance
## Los héroes de RPG (T175): el personaje dentro del servidor, desde el acto I. En el
## prólogo y en el creador sigue el oficinista de CharacterAppearance; al entrar al
## servidor se compila como el arquetipo de su clase (que ya está en su id):
## guerrero (caballero), duelista (espadachín), exploradora, hacker (pícara),
## hechicero (mago), templario (paladín) y full_stack (caballero-mago).
## Mismo contrato que CharacterAppearance.draw (pies en `feet`, `facing`, `tint`,
## `walk_phase`, `pose`) y la misma lógica de poses, así se hornea con la misma
## cuadrícula (PlayerSheet). La clase va en `a["rpg"]`.
## Colores: el atuendo del creador tiñe las telas (capa, tabardo, túnica, capucha),
## los detalles los adornos, y piel, pelo y ojos se ven donde el casco lo deja. El
## metal, el cuero y las runas son fijos. Las runas y gemas cian («LEDs») cuentan
## que todo esto son datos.

const CLASSES := ["guerrero", "duelista", "exploradora", "hacker", "hechicero", "templario", "full_stack"]
## Fijos (en el pase de identificación del horneado se dibujan grises: así nunca se
## confunden con un color de capa; ver `_fixed`).
const STEEL := "aeb6c4"
const GOLD := "e2b84a"
const LEATHER := "7a5232"
const DARK_LEATHER := "3a2c26"
const CLOTH_WHITE := "e8e4da"
const RUNE := "4fe0ff"
const HEAD_R := 7.6
const HEAD_Y := -30.5
const CAPES := {"guerrero": 1.0, "templario": 1.0, "duelista": 0.55, "exploradora": 1.0, "full_stack": 0.9}


static func draw(ci: CanvasItem, feet: Vector2, scale: float, a: Dictionary,
		facing := Vector2.DOWN, tint := Color(0, 0, 0, 0), walk_phase := -1.0, pose := {}) -> void:
	var state := String(pose.get("state", ""))
	var t := clampf(float(pose.get("t", 0.0)), 0.0, 1.0)
	var xf := CharacterAppearance.pose_transform(state, t, facing, scale)
	if not xf.is_empty():
		if state == "dead":
			var k := absf(float(xf[1])) / (PI * 0.5)
			CharacterAppearance._ellipse(ci, feet + Vector2(-signf(facing.x if facing.x != 0.0 else 1.0) * 15.0 * scale * k, 0.0),
				lerpf(11.0, 20.0, k) * scale, 4.4 * scale, Color(0, 0, 0, 0.4))
		ci.draw_set_transform(feet + xf[0], xf[1], xf[2])
		var inner := pose.duplicate()
		inner["state"] = "limp" if state == "dead" else ""
		draw(ci, Vector2.ZERO, scale, a, facing, tint, -1.0, inner)
		ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		return
	var cls := String(a.get("rpg", "guerrero"))
	var id_pass := bool(a.get("_id_pass", false))
	var fx := func(html: String) -> Color: return _fixed(html, tint, id_pass)
	var outfit := CharacterAppearance._tinted(Color(a["outfit_color"]), tint)
	var accent := CharacterAppearance._tinted(Color(a.get("accent_color", "2a2a30")), tint)
	var skin := CharacterAppearance._tinted(Color(a["skin_tone"]), tint)
	var width: float = CharacterAppearance.BODY_WIDTH[int(a["body"])]
	var back := facing.y < -0.5
	var look := clampf(facing.x, -1.0, 1.0)
	var profile := absf(look) > 0.6 and absf(facing.y) < 0.75
	var side := 1.0 if look >= 0.0 else -1.0
	var walking := walk_phase >= 0.0
	var run_k := 1.45 if state == "run" else 1.0
	var swing := sin(walk_phase) * run_k if walking else 0.0
	var bob := absf(cos(walk_phase)) * 1.3 * run_k if walking else 0.0
	if state == "idle":
		bob = (sin(float(pose.get("time", 0.0)) * 2.4) * 0.5 + 0.5) * 0.7
	var weapon := String(pose.get("weapon", ""))
	var arm_weapon := weapon
	match String(pose.get("weapon_class", "")):
		"swing":
			arm_weapon = "sword"
		"thrust":
			arm_weapon = "dagger"
	var posing := state in ["attack", "shoot", "cast", "channel", "type"]
	var both_arms := state in ["cast", "channel", "type"]
	var hs := float(a.get("height", 1.0))
	var p := func(x: float, y: float) -> Vector2: return feet + Vector2(x, y * hs) * scale
	var u := func(x: float, y: float) -> Vector2: return feet + Vector2(x, (y - bob) * hs) * scale
	var tw := width * (0.72 if profile else 1.0)
	var lean := 0.8 * signf(look) * run_k * run_k if profile and walking else 0.0
	var poly := func(points: Array, color: Color) -> void:
		var pts := PackedVector2Array()
		for q in points:
			pts.append(u.call(q.x, q.y))
		ci.draw_colored_polygon(pts, color)

	# Sombra.
	var shadow_r := (11.5 - bob * 0.6) * scale * width
	if state != "limp":
		CharacterAppearance._ellipse(ci, feet, shadow_r, shadow_r * 0.4, Color(0, 0, 0, 0.4))

	# Capa por detrás (de frente asoma por los lados; de espaldas va encima del torso, más abajo).
	var cape_len: float = CAPES.get(cls, 0.0)
	if cape_len > 0.0 and not back:
		_cape(ci, u, outfit, accent, cape_len, tw, lean, swing, profile, side, fx, false)

	# Piernas y botas (debajo de una túnica larga no se ven).
	var robe := cls == "hechicero"
	var pants: Color = outfit.darkened(0.45) if cls in ["duelista", "exploradora", "hacker", "full_stack"] else fx.call(STEEL).darkened(0.15)
	var boots: Color = fx.call(DARK_LEATHER) if not cls in ["guerrero", "templario"] else fx.call(GOLD if cls == "templario" else STEEL).darkened(0.3)
	for leg: float in [-1.0, 1.0]:
		var phase := swing * leg
		var lift := maxf(0.0, phase) * 2.6 if walking else 0.0
		var x := (-5.0 if leg < 0.0 else 1.0) * width
		if profile:
			x = -2.0 * width + phase * 3.2 * signf(look)
		var y_top := -10.0 - bob
		var length := 10.0 + bob - lift
		ci.draw_rect(Rect2(p.call(x, y_top), Vector2(4.0 * width, length * hs) * scale), pants)
		ci.draw_rect(Rect2(p.call(x + 2.7 * width, y_top), Vector2(1.3 * width, length * hs) * scale), pants.darkened(0.25))
		ci.draw_rect(Rect2(p.call(x - 0.4, -4.0 - lift), Vector2(4.8 * width, 4.0 - 0.3) * scale), boots)
		ci.draw_rect(Rect2(p.call(x - 0.4, -4.0 - lift), Vector2(4.8 * width, 0.9) * scale), boots.lightened(0.25))

	# Brazos de atrás (los que no posan).
	var sleeve: Color = _sleeve(cls, outfit, fx)
	var glove: Color = fx.call(LEATHER) if cls != "hechicero" else skin
	var carry_hand := Vector2.INF
	for arm: float in [-1.0, 1.0]:
		if posing and (both_arms or arm == side):
			continue
		var arm_swing := -swing * arm * (2.2 if not profile else 0.0)
		var ax := (-11.0 if arm < 0.0 else 7.2) * width
		var hand_x := (-9.0 if arm < 0.0 else 9.0) * width
		if profile:
			ax = -1.75 * width + swing * arm * 3.0 * signf(look)
			hand_x = ax + 1.9 * width
		if state == "limp":
			arm_swing = 0.0
		ci.draw_rect(Rect2(u.call(ax, -23.0 + arm_swing * 0.4), Vector2(3.8 * width, 12.0 * hs) * scale), sleeve)
		var hand: Vector2 = u.call(hand_x, -10.5 + arm_swing)
		ci.draw_circle(hand, 2.1 * scale * width, glove)
		if arm == side:
			carry_hand = hand
	var carry := weapon != "" and carry_hand != Vector2.INF and state != "limp"
	if carry and back:
		CharacterAppearance.draw_weapon(ci, carry_hand, Vector2(side * 0.45, -0.9).normalized(), weapon, scale, tint)

	# Torso según la clase.
	_torso(ci, cls, poly, u, outfit, accent, fx, tw, lean, back, profile, robe, swing)
	if cape_len > 0.0 and back:
		_cape(ci, u, outfit, accent, cape_len, tw, lean, swing, profile, side, fx, true)
	if carry and not back:
		CharacterAppearance.draw_weapon(ci, carry_hand, Vector2(side * 0.45, -0.9).normalized(), weapon, scale, tint)
		ci.draw_circle(carry_hand, 2.1 * scale * width, glove)

	# Brazos en pose.
	if posing:
		var time := float(pose.get("time", 0.0))
		for arm: float in ([-1.0, 1.0] if both_arms else [side]):
			var out := signf(look) if profile else arm
			if state == "type" and not profile:
				out = -arm * 0.6
			var shoulder: Vector2 = u.call((lean if profile else 7.6 * arm * tw), -22.0)
			var ang := CharacterAppearance.arm_angle(state, arm_weapon, t, time) * (0.85 if both_arms and arm != side else 1.0)
			var d := Vector2(sin(ang) * out, cos(ang))
			var hand := shoulder + d * 12.0 * hs * scale * CharacterAppearance.arm_reach(state, arm_weapon, t)
			ci.draw_line(shoulder, hand, sleeve, 3.8 * width * scale)
			if state in ["attack", "shoot"] and weapon != "":
				CharacterAppearance.draw_weapon(ci, hand, d, weapon, scale, tint)
			ci.draw_circle(hand, 2.1 * scale * width, glove)
			if pose.has("glow") and state in ["cast", "channel"]:
				var g: Color = pose["glow"]
				var pulse := 0.75 + 0.25 * sin(time * 9.0) if state == "channel" else minf(1.0, t * 2.5)
				ci.draw_circle(hand, 4.5 * scale * pulse, Color(g, 0.35))
				ci.draw_circle(hand, 2.4 * scale * pulse, Color(g.lightened(0.4), 0.8))
	# Hombreras encima de los brazos.
	_pauldrons(ci, cls, u, outfit, fx, tw, lean, back, profile, side, scale)

	# Cabeza y lo que lleva en ella.
	var head: Vector2 = u.call(lean, HEAD_Y)
	_head(ci, cls, head, HEAD_R * scale, a, outfit, accent, fx, back, profile, look, side, tint, scale)


## Color fijo (metal, cuero, runas). En el pase de identificación, gris: así no se
## clasifica como piel, atuendo, pelo... (el dorado o el marrón lo harían).
static func _fixed(html: String, tint: Color, id_pass: bool) -> Color:
	if id_pass:
		return Color(0.55, 0.55, 0.58)
	return CharacterAppearance._tinted(Color(html), tint)


static func _sleeve(cls: String, outfit: Color, fx: Callable) -> Color:
	match cls:
		"guerrero", "full_stack":
			return fx.call(STEEL).darkened(0.1)
		"templario":
			return fx.call(GOLD).darkened(0.12)
		"duelista":
			return fx.call(CLOTH_WHITE)
		"hacker":
			return fx.call(DARK_LEATHER)
	return outfit.darkened(0.12)


static func _cape(ci: CanvasItem, u: Callable, outfit: Color, accent: Color, length: float, tw: float, lean: float,
		swing: float, profile: bool, side: float, fx: Callable, over: bool) -> void:
	var s: float = (u.call(1.0, 0.0) as Vector2).x - (u.call(0.0, 0.0) as Vector2).x   # píxeles por unidad
	var bottom := -24.0 + 20.0 * length
	var flap := swing * 1.6
	var pts := PackedVector2Array()
	if profile:
		var bx := -side * 4.5 * tw
		pts = PackedVector2Array([u.call(lean, -24.0), u.call(-side * 2.0 * tw + lean, -24.0),
			u.call(bx - side * 2.5 + flap, bottom), u.call(bx * 0.2 + flap, bottom + 0.5)])
	else:
		var w := 9.4 * tw if over else 10.2 * tw
		pts = PackedVector2Array([u.call(-8.0 * tw + lean, -24.0), u.call(8.0 * tw + lean, -24.0),
			u.call(w + flap, bottom), u.call(-w + flap, bottom)])
	var cloth := outfit.darkened(0.15) if not over else outfit
	ci.draw_colored_polygon(pts, cloth)
	if over:
		# Pliegues, borde de los detalles y un circuito de runas en el bajo.
		for k in [-1.0, 1.0]:
			ci.draw_line(u.call(k * 3.0 * tw, -22.0), u.call(k * 4.6 * tw + flap, bottom - 0.5), outfit.darkened(0.22), 1.0 * s)
		ci.draw_line(u.call(-9.2 * tw + flap, bottom - 0.6), u.call(9.2 * tw + flap, bottom - 0.6), accent, 1.6 * s)
		for k in 3:
			ci.draw_rect(Rect2(u.call((-4.0 + k * 4.0) * tw + flap, bottom - 2.6), Vector2(1.2, 1.2) * s), fx.call(RUNE))


static func _torso(ci: CanvasItem, cls: String, poly: Callable, u: Callable, outfit: Color, accent: Color, fx: Callable,
		tw: float, lean: float, back: bool, profile: bool, robe: bool, swing: float) -> void:
	var s: float = (u.call(1.0, 0.0) as Vector2).x - (u.call(0.0, 0.0) as Vector2).x   # píxeles por unidad
	var sh := 8.6 * tw   # media anchura de hombros
	var wa := 6.2 * tw   # media anchura de cintura
	var front := not back and not profile
	match cls:
		"guerrero", "templario":
			var metal: Color = fx.call(STEEL if cls == "guerrero" else GOLD)
			poly.call([Vector2(-sh + lean, -24.0), Vector2(sh + lean, -24.0), Vector2(wa, -10.0), Vector2(-wa, -10.0)], metal)
			poly.call([Vector2(2.6 * tw + lean, -24.0), Vector2(sh + lean, -24.0), Vector2(wa, -10.0), Vector2(2.0 * tw, -10.0)], metal.darkened(0.2))
			poly.call([Vector2(-sh * 0.8 + lean, -23.2), Vector2(-3.0 * tw + lean, -23.2), Vector2(-5.0 * tw, -15.0)], metal.lightened(0.35))
			# Tabardo de su color (con el emblema de los detalles) que cuelga bajo el cinturón.
			if not back:
				var tx := 2.4 * tw
				poly.call([Vector2(-tx + lean, -21.0), Vector2(tx + lean, -21.0), Vector2(tx, -3.5), Vector2(0.0, -2.0), Vector2(-tx, -3.5)], outfit)
				poly.call([Vector2(tx * 0.25 + lean, -21.0), Vector2(tx + lean, -21.0), Vector2(tx, -3.5), Vector2(0.0, -2.0)], outfit.darkened(0.2))
				if front:
					var c: Vector2 = u.call(lean * 0.5, -15.0)
					ci.draw_line(c + Vector2(0, -3.0) * s, c + Vector2(0, 3.0) * s, accent, 1.2 * s)
					ci.draw_line(c + Vector2(-2.0, -0.8) * s, c + Vector2(2.0, -0.8) * s, accent, 1.2 * s)
			ci.draw_rect(Rect2(u.call(-wa, -11.5), Vector2(wa * 2.0, 2.0) * s), fx.call(LEATHER))
			if front and cls == "guerrero":   # una línea de runas en el peto
				for k in 3:
					ci.draw_rect(Rect2(u.call(-5.2 * tw + k * 1.6, -19.0 + k * 0.6), Vector2(1.0, 1.0) * s), fx.call(RUNE))
		"duelista":
			poly.call([Vector2(-sh + lean, -24.0), Vector2(sh + lean, -24.0), Vector2(wa, -9.5), Vector2(-wa, -9.5)], fx.call(CLOTH_WHITE))
			# Chaleco abierto de su color y una banda cruzada de los detalles.
			if front:
				poly.call([Vector2(-sh + lean, -24.0), Vector2(-1.6 * tw + lean, -24.0), Vector2(-1.4 * tw, -9.5), Vector2(-wa, -9.5)], outfit)
				poly.call([Vector2(1.6 * tw + lean, -24.0), Vector2(sh + lean, -24.0), Vector2(wa, -9.5), Vector2(1.4 * tw, -9.5)], outfit.darkened(0.18))
				poly.call([Vector2(-sh + lean, -21.0), Vector2(-sh + 2.0 + lean, -22.5), Vector2(wa, -11.0), Vector2(wa - 1.5, -9.8)], accent)
			else:
				poly.call([Vector2(-sh + lean, -24.0), Vector2(sh + lean, -24.0), Vector2(wa, -9.5), Vector2(-wa, -9.5)], outfit)
			ci.draw_rect(Rect2(u.call(-wa, -11.0), Vector2(wa * 2.0, 1.8) * s), fx.call(DARK_LEATHER))
		"exploradora":
			poly.call([Vector2(-sh + lean, -24.0), Vector2(sh + lean, -24.0), Vector2(wa + 0.8, -6.0), Vector2(-wa - 0.8, -6.0)], outfit)
			poly.call([Vector2(2.4 * tw + lean, -24.0), Vector2(sh + lean, -24.0), Vector2(wa + 0.8, -6.0), Vector2(2.0 * tw, -6.0)], outfit.darkened(0.2))
			ci.draw_rect(Rect2(u.call(-wa, -11.5), Vector2(wa * 2.0, 1.8) * s), fx.call(LEATHER))
			# Correa del carcaj en diagonal y el carcaj (con flechas) a la espalda.
			if not back:
				ci.draw_line(u.call(-sh * 0.8 + lean, -23.5), u.call(wa * 0.9, -11.5), fx.call(LEATHER), 1.6 * s)
				for k in 3:
					ci.draw_line(u.call(5.0 * tw + k * 1.2, -26.0 - k * 0.6), u.call(5.6 * tw + k * 1.2, -29.5 - k * 0.6), fx.call(CLOTH_WHITE), 1.0 * s)
			else:
				ci.draw_rect(Rect2(u.call(1.5 * tw, -25.0), Vector2(3.8 * tw, 12.0) * s), fx.call(LEATHER))
				for k in 3:
					ci.draw_line(u.call(2.0 * tw + k * 1.2, -25.0), u.call(2.2 * tw + k * 1.2, -29.0), fx.call(CLOTH_WHITE), 1.0 * s)
			if front:
				ci.draw_rect(Rect2(u.call(-4.4 * tw, -10.0), Vector2(2.4, 2.4) * s), fx.call(LEATHER).darkened(0.2))   # bolsa
		"hacker":
			var lea: Color = fx.call(DARK_LEATHER)
			poly.call([Vector2(-sh + lean, -24.0), Vector2(sh + lean, -24.0), Vector2(wa, -8.5), Vector2(-wa, -8.5)], outfit.darkened(0.35))
			poly.call([Vector2(2.4 * tw + lean, -24.0), Vector2(sh + lean, -24.0), Vector2(wa, -8.5), Vector2(2.0 * tw, -8.5)], outfit.darkened(0.5))
			if front:   # correas cruzadas con hebillas de los detalles
				ci.draw_line(u.call(-sh * 0.8 + lean, -23.0), u.call(wa * 0.8, -11.0), lea, 1.5 * s)
				ci.draw_line(u.call(sh * 0.8 + lean, -23.0), u.call(-wa * 0.8, -11.0), lea, 1.5 * s)
				ci.draw_rect(Rect2(u.call(-0.8, -17.8), Vector2(1.8, 1.8) * s), accent)
			ci.draw_rect(Rect2(u.call(-wa, -11.0), Vector2(wa * 2.0, 1.8) * s), lea)
			if not back:   # bufanda que ondea
				poly.call([Vector2(-4.0 * tw + lean, -24.5), Vector2(4.0 * tw + lean, -24.5), Vector2(3.0 * tw, -21.5), Vector2(-3.0 * tw, -21.5)], accent)
		"hechicero":
			# Túnica hasta los pies, con el ruedo y la franja de los detalles y runas.
			var hem := -0.5
			var flare := 9.0 * tw + absf(swing) * 0.8
			poly.call([Vector2(-sh * 0.92 + lean, -24.0), Vector2(sh * 0.92 + lean, -24.0), Vector2(flare + swing * 0.8, hem), Vector2(-flare + swing * 0.8, hem)], outfit)
			poly.call([Vector2(2.6 * tw + lean, -24.0), Vector2(sh * 0.92 + lean, -24.0), Vector2(flare + swing * 0.8, hem), Vector2(2.8 * tw + swing * 0.8, hem)], outfit.darkened(0.22))
			ci.draw_line(u.call(-flare + swing * 0.8, hem - 0.7), u.call(flare + swing * 0.8, hem - 0.7), accent, 1.6 * s)
			if front:
				ci.draw_line(u.call(lean, -22.0), u.call(swing * 0.8, hem), accent, 1.4 * s)
				for k in 4:
					ci.draw_rect(Rect2(u.call(1.2 + swing * 0.2 * k, -18.0 + k * 4.0), Vector2(1.0, 1.0) * s), fx.call(RUNE))
			ci.draw_rect(Rect2(u.call(-wa, -15.0), Vector2(wa * 2.0, 1.6) * s), accent.darkened(0.25))   # cordón
		"full_stack":
			# Abrigo largo de su color con un peto pequeño de acero y cinturón con gema.
			poly.call([Vector2(-sh + lean, -24.0), Vector2(sh + lean, -24.0), Vector2(wa + 1.6, -4.0), Vector2(-wa - 1.6, -4.0)], outfit)
			poly.call([Vector2(2.4 * tw + lean, -24.0), Vector2(sh + lean, -24.0), Vector2(wa + 1.6, -4.0), Vector2(2.0 * tw, -4.0)], outfit.darkened(0.2))
			if front:
				poly.call([Vector2(-3.6 * tw + lean, -22.5), Vector2(3.6 * tw + lean, -22.5), Vector2(3.0 * tw, -14.0), Vector2(-3.0 * tw, -14.0)], fx.call(STEEL))
				poly.call([Vector2(-3.0 * tw + lean, -22.0), Vector2(-1.0 * tw + lean, -22.0), Vector2(-2.0 * tw, -16.0)], fx.call(STEEL).lightened(0.35))
			ci.draw_rect(Rect2(u.call(-wa, -11.5), Vector2(wa * 2.0, 1.8) * s), fx.call(DARK_LEATHER))
			if not back:
				ci.draw_rect(Rect2(u.call(-0.9, -11.9), Vector2(1.8, 2.4) * s), fx.call(RUNE))
			ci.draw_line(u.call(-wa - 1.6 + 0.5, -4.6), u.call(wa + 1.6 - 0.5, -4.6), accent, 1.3 * s)


static func _pauldrons(ci: CanvasItem, cls: String, u: Callable, outfit: Color, fx: Callable, tw: float, lean: float,
		back: bool, profile: bool, side: float, scale: float) -> void:
	var metal: Color
	match cls:
		"guerrero":
			metal = fx.call(STEEL)
		"templario":
			metal = fx.call(GOLD)
		"full_stack":
			metal = fx.call(STEEL)
		_:
			return
	var sides: Array = [-1.0, 1.0] if not profile else [side]
	if cls == "full_stack" and not profile:
		sides = [-1.0]   # una sola hombrera
	for s: float in sides:
		var c: Vector2 = u.call(s * 8.2 * tw + lean if not profile else lean, -22.6)
		ci.draw_circle(c, 3.9 * scale, metal.darkened(0.25))
		ci.draw_circle(c + Vector2(0, -0.4) * scale, 3.4 * scale, metal)
		ci.draw_circle(c + Vector2(-1.0, -1.4) * scale, 1.2 * scale, metal.lightened(0.45))


static func _head(ci: CanvasItem, cls: String, head: Vector2, r: float, a: Dictionary, outfit: Color, accent: Color,
		fx: Callable, back: bool, profile: bool, look: float, side: float, tint: Color, scale: float) -> void:
	var opts := {"back": back, "look": Vector2(look, 0.0), "tint": tint, "profile": profile}
	var face := a.duplicate()
	var steel: Color = fx.call(STEEL)
	match cls:
		"guerrero":
			# Yelmo cerrado: cúpula de acero, rendija oscura y una cresta de los detalles.
			ci.draw_circle(head, r * 1.08, steel.darkened(0.25))
			ci.draw_circle(head + Vector2(-0.1, -0.12) * r, r * 0.95, steel)
			ci.draw_rect(Rect2(head + Vector2(-1.0, 0.55) * r, Vector2(2.0, 0.45) * r), steel.darkened(0.25))
			if not back:
				var off := look * 0.35 * r
				ci.draw_rect(Rect2(head + Vector2(-0.68 * r + off, -0.02 * r), Vector2(1.36, 0.22) * r), fx.call("14161c"))
				ci.draw_line(head + Vector2(off, 0.3 * r), head + Vector2(off, 0.85 * r), fx.call("14161c"), maxf(1.0, 0.12 * r))
			ci.draw_arc(head + Vector2(-0.15, -0.2) * r, r * 0.7, PI * 1.15, PI * 1.45, 8, steel.lightened(0.5), maxf(1.0, 0.15 * r))
			_crest(ci, head, r, accent, profile, side)
		"templario":
			face["hair"] = 0
			face["accessory"] = 0
			CharacterAppearance.draw_head(ci, head, r, face, opts)
			# Yelmo abierto dorado con carrilleras y un penacho de los detalles.
			var gold: Color = fx.call(GOLD)
			_dome(ci, head, r, 1.12, gold)
			ci.draw_arc(head + Vector2(-0.15, -0.25) * r, r * 0.75, PI * 1.15, PI * 1.45, 8, gold.lightened(0.45), maxf(1.0, 0.15 * r))
			if not back:
				for s in ([-1.0, 1.0] if not profile else [-side]):
					ci.draw_rect(Rect2(head + Vector2(s * 1.0 - 0.18, -0.1) * r, Vector2(0.36, 0.8) * r), gold.darkened(0.15))
			_crest(ci, head, r, accent, profile, side)
		"duelista":
			face["accessory"] = 0
			CharacterAppearance.draw_head(ci, head, r, face, opts)
			# Sombrero de ala ancha de su color, cinta de los detalles y pluma.
			CharacterAppearance._ellipse(ci, head + Vector2(0, -0.55) * r, r * 1.75, r * 0.42, outfit.darkened(0.2))
			_dome(ci, head + Vector2(0, -0.6) * r, r * 0.82, 1.0, outfit)
			ci.draw_rect(Rect2(head + Vector2(-0.82, -0.82) * r, Vector2(1.64, 0.22) * r), accent)
			var fp := head + Vector2(-side * 0.55, -1.25) * r
			ci.draw_line(fp, fp + Vector2(-side * 0.9, -0.9) * r, fx.call(CLOTH_WHITE), maxf(1.0, 0.22 * r))
		"exploradora", "hacker":
			# Capucha de su color (más oscura la de la pícara) con la cara en sombra; la
			# pícara, además, máscara hasta la nariz.
			var hood := outfit if cls == "exploradora" else outfit.darkened(0.4)
			ci.draw_circle(head + Vector2(0, -0.05) * r, r * 1.2, hood.darkened(0.15))
			if back:
				ci.draw_colored_polygon(PackedVector2Array([head + Vector2(-0.5, 0.6) * r, head + Vector2(0.5, 0.6) * r, head + Vector2(0, 1.6) * r]), hood.darkened(0.15))
				_dome(ci, head, r, 1.15, hood)
			else:
				face["hair"] = 0
				face["accessory"] = 0 if int(face.get("accessory", 0)) > 2 else face.get("accessory", 0)
				CharacterAppearance.draw_head(ci, head + Vector2(look * 0.15 * r, 0.1 * r), r * 0.86, face, opts)
				# El borde de la capucha baja hasta las cejas: la frente queda en sombra.
				_dome(ci, head + Vector2(0, 0.06) * r, r, 1.04, hood)
				ci.draw_arc(head + Vector2(0, -0.05) * r, r * 1.06, PI * 0.95, PI * 2.05, 18, hood, maxf(1.0, 0.3 * r))
				ci.draw_arc(head + Vector2(-0.1, -0.15) * r, r * 0.82, PI * 1.15, PI * 1.45, 8, hood.lightened(0.3), maxf(1.0, 0.14 * r))
				if cls == "hacker":
					var mask: Color = fx.call("1d1b24")
					ci.draw_rect(Rect2(head + Vector2(-0.82 + look * 0.15, 0.22) * r, Vector2(1.64, 0.62) * r), mask)
					for s in [-1.0, 1.0]:   # ojos que brillan como LEDs
						ci.draw_rect(Rect2(head + Vector2(s * 0.34 - 0.08 + look * 0.2, 0.02) * r, Vector2(0.16, 0.12) * r), fx.call(RUNE))
		"hechicero":
			face["accessory"] = 0 if int(face.get("accessory", 0)) > 2 else face.get("accessory", 0)
			CharacterAppearance.draw_head(ci, head, r, face, opts)
			# Sombrero de punta de su color, doblado, con cinta de los detalles y una runa.
			CharacterAppearance._ellipse(ci, head + Vector2(0, -0.62) * r, r * 1.45, r * 0.36, outfit.darkened(0.2))
			ci.draw_colored_polygon(PackedVector2Array([head + Vector2(-0.95 * side, -0.7) * r, head + Vector2(0.95 * side, -0.7) * r,
				head + Vector2(side * 0.55, -1.9) * r, head + Vector2(side * 1.3, -2.5) * r, head + Vector2(side * 0.15, -2.05) * r]), outfit)
			ci.draw_rect(Rect2(head + Vector2(-0.92, -0.98) * r, Vector2(1.84, 0.26) * r), accent)
			ci.draw_rect(Rect2(head + Vector2(-0.1, -1.6) * r, Vector2(0.22, 0.22) * r), fx.call(RUNE))
		"full_stack":
			CharacterAppearance.draw_head(ci, head, r, face, opts)
			# Diadema de acero con una gema que parpadea como un LED.
			ci.draw_arc(head + Vector2(0, -0.05) * r, r * 0.98, PI * 1.08, PI * 1.92, 16, steel, maxf(1.0, 0.16 * r))
			if not back:
				ci.draw_circle(head + Vector2(look * 0.3, -0.92) * r, 0.2 * r, fx.call(RUNE))
		_:
			CharacterAppearance.draw_head(ci, head, r, face, opts)


## Media cúpula (yelmo, copa de sombrero, capucha de espaldas).
static func _dome(ci: CanvasItem, head: Vector2, r: float, k: float, color: Color) -> void:
	var pts := PackedVector2Array()
	for i in 17:
		var t := PI + PI * i / 16.0
		pts.append(head + Vector2(cos(t), sin(t)) * r * k)
	pts.append(head + Vector2(r * k, 0.1 * r))
	pts.append(head + Vector2(-r * k, 0.1 * r))
	ci.draw_colored_polygon(pts, color)


## Cresta o penacho sobre el casco, del color de los detalles.
static func _crest(ci: CanvasItem, head: Vector2, r: float, accent: Color, profile: bool, side: float) -> void:
	if profile:
		ci.draw_colored_polygon(PackedVector2Array([head + Vector2(-side * 0.2, -1.0) * r, head + Vector2(side * 0.3, -1.05) * r,
			head + Vector2(-side * 1.3, -0.4) * r]), accent)
	else:
		ci.draw_rect(Rect2(head + Vector2(-0.16, -1.42) * r, Vector2(0.32, 0.5) * r), accent)
		ci.draw_rect(Rect2(head + Vector2(-0.16, -1.42) * r, Vector2(0.12, 0.5) * r), accent.lightened(0.3))
