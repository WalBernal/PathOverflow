class_name SkillFx
## Firma visual de cada habilidad (T74): forma del proyectil, estela, destello al
## lanzar y estallido al golpear, en la rejilla de 2 px. Las habilidades sin firma
## propia usan la de su tipo de daño, así que de lejos ya se distingue un ping
## (rayo en zigzag) de un paquete (rectángulo con cabecera) o de una bola de fuego.
## Las partículas las pone ImpactFx (respeta «Menos destellos» y su tope); con
## muchos enemigos en pantalla, versión ligera: sin estelas y formas simples.

const GRID := 2.0
## Por tipo de daño: proyectil, estela, lanzamiento e impacto.
const BY_TYPE := {
	"fire": {"projectile": "fireball", "trail": "embers", "cast": "flare", "impact": "splash"},
	"cold": {"projectile": "shard", "trail": "frost", "cast": "frost", "impact": "shatter"},
	"lightning": {"projectile": "bolt", "trail": "sparks", "cast": "spark", "impact": "zapburst"},
	"chaos": {"projectile": "glob", "trail": "drips", "cast": "glitch", "impact": "splat"},
	"physical": {"projectile": "orb", "trail": "bits", "cast": "flick", "impact": "shards"},
}
## Las que tienen forma propia (lo que no ponen, lo toman de su tipo de daño).
const SIGNATURES := {
	"rafaga_de_paquetes": {"projectile": "packet"},
	"paquete_rastreador": {"projectile": "tracker", "trail": "dots"},
	"corrupcion_datos": {"projectile": "glitch"},
	# Ping Letal (T194): un punto con arcos de radar y, al golpear, su tiempo de respuesta.
	"ping_letal": {"projectile": "sonar", "cast": "spark", "hit_fx": "ping_letal_hit"},
	"torreta_ci": {"projectile": "bolt"},
	"cascada_css": {"projectile": "shard"},
}
## Cada cuánto suelta una partícula de estela un proyectil (s).
const TRAIL_EVERY := 0.035


## Firma de la habilidad del perfil `p`: {projectile, trail, cast, impact}.
static func signature(p: Dictionary) -> Dictionary:
	var dtype := String(p.get("damage_type", "physical"))
	var sig: Dictionary = BY_TYPE.get(dtype, BY_TYPE["physical"]).duplicate()
	sig.merge(SIGNATURES.get(String(p.get("id", "")), {}), true)
	return sig


static func _snap(v: Vector2) -> Vector2:
	return v.snapped(Vector2(GRID, GRID))


## Dibuja un proyectil con su forma. `light`: versión simple (muchos enemigos);
## `dim`: sin núcleos blancos (Menos destellos).
static func draw_projectile(ci: CanvasItem, pos: Vector2, dir: Vector2, color: Color, shape: String, time: float, light := false, dim := false) -> void:
	var at := _snap(pos)
	var core := color.lightened(0.25) if dim else color.lightened(0.6)
	if light:
		ci.draw_line(at - dir * 14.0, at, Color(color, 0.5), 4.0)
		ci.draw_rect(Rect2(at - Vector2(3, 3), Vector2(6, 6)), color)
		return
	var side := dir.orthogonal()
	match shape:
		"fireball":
			# Núcleo y llamitas de píxeles que tiemblan detrás.
			for k in 4:
				var jitter := Vector2(sin(time * 31.0 + k * 1.7), cos(time * 27.0 + k * 2.3)) * 2.5
				var q := _snap(at - dir * (4.0 + k * 4.0) + side * jitter.x + Vector2(0, jitter.y))
				var s := 6.0 - k
				ci.draw_rect(Rect2(q - Vector2(s, s) * 0.5, Vector2(s, s)), Color("ff8a2a" if k % 2 == 0 else "e0452f", 0.9 - k * 0.18))
			ci.draw_circle(at, 6.0, color)
			ci.draw_circle(at, 3.0, core)
		"shard":
			# Esquirla de hielo alargada con el filo claro.
			var tip := at + dir * 9.0
			var tail := at - dir * 9.0
			ci.draw_colored_polygon(PackedVector2Array([tip, at + side * 4.0, tail, at - side * 4.0]), color)
			ci.draw_line(tail, tip, Color(core, 0.9), 1.5)
			ci.draw_line(tail - dir * 6.0, tail, Color(color, 0.35), 3.0)
		"bolt":
			# Chispazo en zigzag que cambia de forma cada pocos cuadros.
			var pts := PackedVector2Array([at])
			var step := int(time * 30.0)
			for k in range(1, 5):
				var wob := sin(float(step + k) * 12.9898) * 5.0
				pts.append(_snap(at - dir * k * 6.0 + side * wob))
			ci.draw_polyline(pts, Color(color, 0.45), 5.0)
			ci.draw_polyline(pts, core, 2.0)
			ci.draw_rect(Rect2(at - Vector2(3, 3), Vector2(6, 6)), core)
		"glob":
			# Gota de caos que escurre.
			ci.draw_circle(at, 7.0, Color(color, 0.55))
			ci.draw_circle(at - dir * 2.0, 4.0, color)
			for k in 2:
				var drip := fmod(time * 2.0 + k * 0.5, 1.0)
				ci.draw_rect(Rect2(_snap(at + Vector2(-3 + k * 4, 4 + drip * 8.0)), Vector2(2, 2 + 2 * (1.0 - drip))), Color(color, 1.0 - drip))
		"glitch":
			ci.draw_circle(at, 7.0, Color(color, 0.6))
			ci.draw_rect(Rect2(at - Vector2(5, 2) + side * sin(time * 50.0) * 3.0, Vector2(10, 4)), Color(0.3, 1.0, 0.6, 0.7))
		"packet", "tracker":
			# Paquete: rectángulo en la dirección del vuelo con la cabecera más clara.
			# (Puntos girados a mano: sin draw_set_transform, que pisaría la transformación de quien dibuja.)
			var local := func(x: float, y: float) -> Vector2: return at + dir * x + side * y
			var quad := func(x0: float, x1: float, y0: float, y1: float) -> PackedVector2Array:
				return PackedVector2Array([local.call(x0, y0), local.call(x1, y0), local.call(x1, y1), local.call(x0, y1)])
			ci.draw_line(local.call(-22, 0), local.call(-6, 0), Color(color, 0.35), 3.0)
			ci.draw_colored_polygon(quad.call(-6, 6, -4, 4), color.darkened(0.2))
			ci.draw_colored_polygon(quad.call(2, 6, -4, 4), core)
			if shape == "tracker" and fmod(time * 4.0, 1.0) < 0.5:
				ci.draw_colored_polygon(quad.call(-4, -2, -8, -4), Color("ff6a6a"))   # la antena que parpadea
		"sonar":
			# Ping (T194): un punto con dos arcos de radar delante que se redibujan cada 0,1 s.
			var pulse := 0.0 if dim else float(int(time * 10.0) % 2) * 2.0
			var ang := dir.angle()
			ci.draw_line(at - dir * 12.0, at, Color(color, 0.4), 2.0)
			for k in 2:
				ci.draw_arc(at, 8.0 + 6.0 * k + pulse, ang - PI / 6.0, ang + PI / 6.0, 6, Color(color, 0.9 - 0.3 * k), 2.0)
			ci.draw_rect(Rect2(at - Vector2(2, 2), Vector2(4, 4)), core if dim else Color.WHITE)
		_:
			ci.draw_line(at - dir * 18.0, at, Color(color, 0.5), 4.0, true)
			ci.draw_circle(at, 5.0, color)


# --- Firmas de cuerpo a cuerpo y movimiento (T193) ---
# Las ocho que tenían el efecto genérico de su kind (anillo, estela, cono, salto,
# zigzag o charco) se dibujan según la ficha de T191 (docs/habilidades_y_ram.md).
# SkillController mete en _effects un {"type": "firma", "firma": id, ...} (move_fx)
# y aquí se dibuja con draw_move_fx; la zona de Git Revert, con draw_revert_zone.
# `light` (muchos enemigos): sin partículas ni texto. `dim` (Menos destellos): sin
# blancos puros ni parpadeos.

## Duración (s) del efecto de cada una.
const MOVE_FX := {
	"barrido": 0.5, "deploy_continuo": 0.55, "reinicio_forzado": 0.7, "force_push": 0.5,
	"fuzzing": 0.3, "teleport_tcp": 0.6, "tunel_ssh": 0.5, "git_revert": 0.3,
}
## Enemigos marcados como mucho por efecto (llaves, ✓, «0x»...).
const MAX_MARKS := 10
const TOKEN_GREY := Color("8a8f99")
const PIPE_YELLOW := Color("e8d070")
const NET_CYAN := Color("4ec9e0")
const COMMIT_ORANGE := Color("f0883e")
const BSOD_BLUE := Color("2b4fd8")
const LOCK_YELLOW := Color("e8c050")
## Los cuatro colores al azar de los tajos de Fuzzing.
const FUZZ_COLORS := [Color("e8d9b0"), Color("7fb8e0"), Color("e8d070"), Color("b04ad9")]
## Tamaño de la fuente de píxel: 1× y 2×.
const TEXT_1X := 10
const TEXT_2X := 20


static func has_move_fx(id: String) -> bool:
	return MOVE_FX.has(id)


## Si la habilidad tiene firma propia (de cuerpo a cuerpo y movimiento, de hechizo o de
## buff, grito o barrera; las auras se dibujan aparte, con draw_aura).
static func has_fx(id: String) -> bool:
	return MOVE_FX.has(id) or SPELL_IDS.has(id) or BUFF_IDS.has(id)


## Efecto «firma» para SkillController._effects. `marks`: dónde estaban los enemigos
## golpeados; `ok`/`err`: verde y rojo (los del modo daltónico si está puesto). `extra`
## puede cambiar la firma (p. ej. «ping_letal_hit», el golpe) y la duración.
static func move_fx(id: String, pos: Vector2, end: Vector2, dir: Vector2, radius: float, color: Color,
		marks := PackedVector2Array(), extra := {}) -> Dictionary:
	var key := String(extra.get("firma", id))
	var e := {"type": "firma", "firma": key, "pos": pos, "end": end, "dir": dir, "radius": radius, "time": 0.0,
		"duration": float(MOVE_FX.get(key, SPELL_FX.get(key, BUFF_FX.get(key, 0.4)))), "color": color, "marks": marks, "seed": randi() % 100000,
		"ok": Color("5cb85c"), "err": Color("d9534f")}
	e.merge(extra, true)
	return e


## Número fijo 0..1 para cada (semilla, k): lo «al azar» de un efecto no cambia de un
## fotograma al siguiente y no hace falta guardar arrays.
static func hash01(sd: int, k: int) -> float:
	return fposmod(sin(float(sd % 9973) * 12.9898 + float(k) * 78.233) * 43758.5453, 1.0)


## Rampa 0..1 entre los segundos `from` y `to`.
static func ramp(s: float, from: float, to: float) -> float:
	return clampf((s - from) / maxf(0.001, to - from), 0.0, 1.0)


## Texto centrado en `at`; `w`: ancho de la caja (los de 2× largos necesitan más).
static func _label(ci: CanvasItem, font: Font, at: Vector2, text: String, size: int, col: Color, w := 60.0) -> void:
	ci.draw_string(font, _snap(at) - Vector2(w * 0.5, 0), text, HORIZONTAL_ALIGNMENT_CENTER, w, size, col)


static func draw_move_fx(ci: CanvasItem, e: Dictionary, font: Font, light := false, dim := false) -> void:
	var s: float = e["time"]
	match String(e["firma"]):
		"barrido":
			_fx_barrido(ci, e, s, light, dim)
		"deploy_continuo":
			_fx_deploy(ci, e, s, light)
		"reinicio_forzado":
			_fx_reboot(ci, e, s, font, light, dim)
		"force_push":
			_fx_force_push(ci, e, s, font, light)
		"fuzzing":
			_fx_fuzzing(ci, e, s, font, light, dim)
		"teleport_tcp":
			_fx_tcp(ci, e, s, font, light, dim)
		"tunel_ssh":
			_fx_ssh(ci, e, s, light, dim)
		"git_revert":
			_fx_revert_jump(ci, e, s)
		"ping_letal":
			_fx_ping_cast(ci, e, s, font, light, dim)
		"ping_letal_hit":
			_fx_ping_hit(ci, e, s, font, light)
		"fork_bomb":
			_fx_fork_bomb(ci, e, s, light, dim)
		"stack_overflow":
			_fx_stack(ci, e, s, light, dim)
		"flamewar":
			_fx_flamewar(ci, e, s, font, light, dim)
		"rayo_produccion":
			_fx_rayo_charge(ci, e, s, font, light)
		"rayo_produccion_fire":
			_fx_rayo_fire(ci, e, s, font, light, dim)
		"deadlock":
			_fx_deadlock(ci, e, s, light, dim)
		"excepcion_en_cadena":
			_fx_exception(ci, e, s, font, light, dim)
		"fuga_de_memoria":
			_fx_leak_drop(ci, e, s)
		"core_dump":
			_fx_core_dump(ci, e, s, font, light, dim)
		"firewall_personal":
			_fx_firewall(ci, e, s, font, light, dim)
		"modo_seguro":
			_fx_safe_mode(ci, e, s, font, light, dim)
		"hiperthreading":
			_fx_hyperthreading(ci, e, s, light)
		"esta_en_produccion":
			_fx_prod(ci, e, s, font, light, dim)
		"daily_standup":
			_fx_daily(ci, e, s, font, light)
		"rollback_grito":
			_fx_rollback(ci, e, s, font, light)
		"aura_off":
			_fx_aura_off(ci, e, s)


## Barrido: tres arcos que barren 360° desde el cursor, tokens que saltan y una
## llave { } que se abre en cada enemigo («refactorizar a la vieja escuela»).
static func _fx_barrido(ci: CanvasItem, e: Dictionary, s: float, light: bool, dim: bool) -> void:
	var at := _snap(e["pos"])
	var r: float = e["radius"]
	var c: Color = e["color"]
	var a0: float = (e["dir"] as Vector2).angle()
	var head := a0 + TAU * ramp(s, 0.0, 0.18)
	var fade := 1.0 - ramp(s, 0.2, 0.42)
	if fade > 0.0:
		for k in 3:
			var rr := r * (0.6 + 0.2 * k)
			var col := c if k < 2 else (c.lightened(0.25) if dim else c.lightened(0.75))   # el exterior, casi blanco
			ci.draw_arc(at, rr, a0, head, 32, Color(col, 0.2 * fade), 4.0 - k)   # lo ya barrido
			ci.draw_arc(at, rr, maxf(a0, head - 1.6), head, 12, Color(col, 0.9 * fade), 4.0 - k)
	if light:
		return
	var tk := ramp(s, 0.12, 0.42)
	if tk > 0.0 and tk < 1.0:
		for k in 8:
			var d := Vector2.from_angle(a0 + TAU * k / 8.0 + hash01(e["seed"], k) * 0.5)
			var q := _snap(at + d * (r * 0.85 + 20.0 * tk))
			ci.draw_rect(Rect2(q - Vector2(2, 1), Vector2(4, 2)), Color(TOKEN_GREY, 1.0 - tk))
	var open := ramp(s, 0.05, 0.2)
	var alpha := 1.0 - ramp(s, 0.32, 0.5)
	for m in e["marks"]:
		_braces(ci, _snap(m + Vector2(0, -16)), 4.0 * open, Color(c.lightened(0.45), alpha))


## Una llave { } de 6×10 px; `gap` separa las dos mitades.
static func _braces(ci: CanvasItem, at: Vector2, gap: float, col: Color) -> void:
	for sgn in [-1.0, 1.0]:
		var x: float = sgn * (2.0 + gap * 0.5)
		ci.draw_polyline(PackedVector2Array([at + Vector2(x - sgn * 2.0, -5), at + Vector2(x, -4), at + Vector2(x, -1),
			at + Vector2(x + sgn * 2.0, 0), at + Vector2(x, 1), at + Vector2(x, 4), at + Vector2(x - sgn * 2.0, 5)]), col, 2.0)


## Despliegue Continuo: las etapas del pipeline en el origen, una cinta de casillas
## que pasan de amarillo a verde y un ✓ (o, uno de cada cuatro, una ✗) por enemigo.
static func _fx_deploy(ci: CanvasItem, e: Dictionary, s: float, light: bool) -> void:
	var a: Vector2 = e["pos"]
	var b: Vector2 = e["end"]
	var dir: Vector2 = e["dir"]
	var side := dir.orthogonal()
	var ok: Color = e["ok"]
	var fade := 1.0 - ramp(s, 0.35, 0.55)
	for k in 3:
		var lit := s >= 0.033 * k
		var col := (ok if k == 2 else TOKEN_GREY) if lit else Color("2a2e36")
		var q := _snap(a - dir * 16.0 + side * (k - 1) * 8.0)
		ci.draw_rect(Rect2(q - Vector2(3, 3), Vector2(6, 6)), Color(col, fade))
	var n := mini(int(a.distance_to(b) / 12.0), 40)
	if n > 0:
		ci.draw_line(_snap(a), _snap(b), Color(TOKEN_GREY, 0.35 * fade), 2.0)
	for k in n:
		var f := (k + 0.5) / float(n)
		var col := PIPE_YELLOW.lerp(ok, ramp(s, 0.3 * f, 0.3 * f + 0.06))
		var q := _snap(a.lerp(b, f))
		ci.draw_rect(Rect2(q - Vector2(3, 3), Vector2(6, 6)), Color(col, fade))
	if light:
		return
	var rise := ramp(s, 0.05, 0.45)
	var alpha := 1.0 - ramp(s, 0.35, 0.5)
	var marks: PackedVector2Array = e["marks"]
	for k in marks.size():
		var q := _snap(marks[k] + Vector2(0, -18.0 - 10.0 * rise))
		if hash01(e["seed"], k) < 0.25:
			var err: Color = e["err"]
			ci.draw_line(q + Vector2(-3, -3), q + Vector2(3, 3), Color(err, alpha), 2.0)
			ci.draw_line(q + Vector2(3, -3), q + Vector2(-3, 3), Color(err, alpha), 2.0)
		else:
			ci.draw_polyline(PackedVector2Array([q + Vector2(-4, 0), q + Vector2(-1, 3), q + Vector2(4, -4)]), Color(ok, alpha), 2.0)


## Silueta del jugador (los pies en `feet`), para fantasmas y copias.
static func _silhouette(ci: CanvasItem, feet: Vector2, col: Color) -> void:
	var p := _snap(feet)
	ci.draw_rect(Rect2(p + Vector2(-5, -12), Vector2(4, 12)), col)
	ci.draw_rect(Rect2(p + Vector2(1, -12), Vector2(4, 12)), col)
	ci.draw_rect(Rect2(p + Vector2(-6, -28), Vector2(12, 16)), col)
	ci.draw_rect(Rect2(p + Vector2(-4, -38), Vector2(8, 10)), col)


## Sombra elíptica en el suelo (sin draw_set_transform: un polígono de 10 puntos).
static func _shadow(ci: CanvasItem, at: Vector2, rx: float, col: Color) -> void:
	if rx < 1.0:
		return
	var pts := PackedVector2Array()
	for k in 10:
		pts.append(at + Vector2.from_angle(TAU * k / 10.0) * Vector2(rx, rx * 0.4))
	ci.draw_colored_polygon(pts, col)


## Reinicio Forzado: el botón de encendido, tres copias fantasma por la parábola y,
## al caer, una «pantalla azul» que se agrieta con su «:(».
static func _fx_reboot(ci: CanvasItem, e: Dictionary, s: float, font: Font, light: bool, dim: bool) -> void:
	var a: Vector2 = e["pos"]
	var b: Vector2 = e["end"]
	var r: float = e["radius"]
	var c: Color = e["color"]
	# Pantalla azul local donde cae (debajo de todo lo demás).
	var bs := 1.0 - ramp(s, 0.15, 0.55)
	if bs > 0.0:
		var half := Vector2(r * 0.8, r * 0.8 * 0.6)
		var center := _snap(b)
		ci.draw_rect(Rect2(center - half, half * 2.0), Color(BSOD_BLUE, 0.35 * bs))
		var crack := ramp(s, 0.0, 0.2)
		for k in 6:
			var d := Vector2.from_angle(TAU * k / 6.0 + hash01(e["seed"], k) * 0.6) * half * 0.95
			ci.draw_line(center, center + d * crack, Color(Color.WHITE if not dim else c.lightened(0.25), 0.8 * bs), 2.0)
		if not light and s < 0.3:
			_label(ci, font, center + Vector2(0, 7), ":(", TEXT_2X, Color(Color.WHITE if not dim else c.lightened(0.25), 0.9 *(1.0 - ramp(s, 0.2, 0.3))))
	# Copias fantasma por la parábola, con su sombra que se encoge en el punto alto.
	var ghost := 1.0 - ramp(s, 0.0, 0.35)
	if ghost > 0.0 and a.distance_to(b) > 8.0:
		var alphas := [0.1, 0.25, 0.4]
		for k in 3:
			var f := 0.25 * (k + 1)
			var ground := a.lerp(b, f)
			var hop := sin(f * PI) * 60.0
			_shadow(ci, _snap(ground), 8.0 * (1.0 - 0.5 * sin(f * PI)), Color(0, 0, 0, 0.4 * ghost))
			_silhouette(ci, ground + Vector2(0, -hop), Color(c.lightened(0.3), alphas[k] * ghost))
	# El símbolo de encendido sobre el jugador, que parpadea dos veces al lanzar.
	if s < 0.12 and (dim or int(s / 0.03) % 2 == 0):
		var top := _snap(a + Vector2(0, -50))
		var col := c.lightened(0.25) if dim else Color.WHITE
		ci.draw_arc(top, 8.0, -PI / 2.0 + deg_to_rad(30.0), -PI / 2.0 + deg_to_rad(330.0), 16, col, 2.0)
		ci.draw_line(top + Vector2(0, -10), top + Vector2(0, -2), col, 2.0)


## Force Push: la flecha de commit con «-f» delante, el historial tachado detrás y,
## si arrolla a alguien, un frente de onda y la estela de los empujados.
static func _fx_force_push(ci: CanvasItem, e: Dictionary, s: float, font: Font, light: bool) -> void:
	var a: Vector2 = e["pos"]
	var b: Vector2 = e["end"]
	var dir: Vector2 = e["dir"]
	var side := dir.orthogonal()
	var err: Color = e["err"]
	var travel := ramp(s, 0.0, 0.15)
	var fade := 1.0 - ramp(s, 0.3, 0.5)
	var at := a.lerp(b, travel)
	ci.draw_line(_snap(a), _snap(at), Color(TOKEN_GREY, 0.6 * fade), 2.0)
	for k in 3:
		var f := (k + 1) / 4.0
		var q := _snap(a.lerp(b, f))
		ci.draw_circle(q, 4.0, Color(TOKEN_GREY, fade))
		ci.draw_circle(q, 2.0, Color("1e2229", fade))
		if travel >= f:
			ci.draw_line(q + Vector2(-4, -4), q + Vector2(4, 4), Color(err, fade), 2.0)
			ci.draw_line(q + Vector2(4, -4), q + Vector2(-4, 4), Color(err, fade), 2.0)
	var tip := _snap(at + dir * 22.0)
	ci.draw_colored_polygon(PackedVector2Array([tip, tip - dir * 12.0 + side * 5.0, tip - dir * 12.0 - side * 5.0]), Color(COMMIT_ORANGE, fade))
	if not light:
		_label(ci, font, tip + Vector2(0, -10), "-f", TEXT_1X, Color(COMMIT_ORANGE.lightened(0.3), fade))
	if not bool(e.get("hit", false)):
		return
	var w := ramp(s, 0.12, 0.37)
	if w > 0.0 and w < 1.0:
		var r: float = e["radius"]
		for k in 4:
			var mid := _snap(b + dir * (r * 0.3 + 30.0 * w + 6.0 * k))
			var half := side * r * (1.0 - 0.15 * k)
			ci.draw_line(mid - half, mid + half, Color(COMMIT_ORANGE.lightened(0.2), 0.8 * (1.0 - w)), 2.0)
	if light:
		return
	var tr := 1.0 - ramp(s, 0.1, 0.45)
	for m in e["marks"]:
		var d: Vector2 = (m - b).normalized() if m.distance_to(b) > 1.0 else dir
		for k in 3:
			ci.draw_rect(Rect2(_snap(m + d * (8.0 + 10.0 * k)) - Vector2(2, 2), Vector2(4, 4)), Color(COMMIT_ORANGE, tr * (1.0 - k * 0.3)))


## Fuzzing: cada tajo, una línea rota de un color al azar, con caracteres basura en
## el cono y «0x» en cada enemigo (y un bicho rojo si sangra).
static func _fx_fuzzing(ci: CanvasItem, e: Dictionary, s: float, font: Font, light: bool, dim: bool) -> void:
	var o: Vector2 = e["pos"]
	var dir: Vector2 = e["dir"]
	var r: float = e["radius"]
	var half: float = e.get("half", 0.7)
	var sd: int = e["seed"]
	var col: Color = FUZZ_COLORS[sd % FUZZ_COLORS.size()]
	var drawn := ramp(s, 0.0, 0.08)
	var fade := 1.0 - ramp(s, 0.1, 0.26)
	var pts := PackedVector2Array()
	for k in 6:
		if k > int(drawn * 5.0 + 0.999):
			break
		var ang := lerpf(-half, half, k / 5.0) + (hash01(sd, k) - 0.5) * deg_to_rad(30.0)
		pts.append(_snap(o + dir.rotated(ang) * r * (0.55 + 0.3 * hash01(sd, k + 10))))
	if pts.size() >= 2:
		ci.draw_polyline(pts, Color(col, 0.9 * fade), 3.0)
		if not dim:
			ci.draw_polyline(pts, Color(col.lightened(0.6), 0.7 * fade), 1.0)
	if light:
		return
	for k in 6:
		var born := 0.02 + 0.03 * k
		if s < born or s > born + 0.2:
			continue
		var q := _snap(o + dir.rotated(lerpf(-half, half, hash01(sd, k + 20))) * r * (0.3 + 0.7 * hash01(sd, k + 30)))
		var sz := Vector2(2.0 + 2.0 * float(int(hash01(sd, k + 40) * 2.0)), 4.0)
		ci.draw_rect(Rect2(q, sz), Color(FUZZ_COLORS[int(hash01(sd, k + 50) * 4.0) % 4], 0.85))
	var alpha := 1.0 - ramp(s, 0.18, 0.3)
	var marks: PackedVector2Array = e["marks"]
	var bleed: float = e.get("bleed", 0.0)
	var err: Color = e["err"]
	for k in marks.size():
		var q := marks[k] + Vector2(12, -20)
		_label(ci, font, q, "0x", TEXT_1X, Color(col.lightened(0.4), alpha))
		ci.draw_rect(Rect2(_snap(q + Vector2(8, -6)), Vector2(2, 2)), Color(FUZZ_COLORS[(sd + k) % 4], alpha))
		ci.draw_rect(Rect2(_snap(q + Vector2(10, -4)), Vector2(2, 2)), Color(FUZZ_COLORS[(sd + k + 2) % 4], alpha))
		if hash01(sd, k + 60) < bleed:
			_bug(ci, _snap(marks[k] + Vector2(-10, -6 + 6.0 * ramp(s, 0.05, 0.3))), Color(err, alpha))


## Un bicho de 6×4: cuerpo y cuatro patas.
static func _bug(ci: CanvasItem, at: Vector2, col: Color) -> void:
	ci.draw_rect(Rect2(at + Vector2(-2, -2), Vector2(4, 4)), col)
	for k in 2:
		ci.draw_rect(Rect2(at + Vector2(-4, -2 + 2 * k), Vector2(2, 1)), col)
		ci.draw_rect(Rect2(at + Vector2(2, -2 + 2 * k), Vector2(2, 1)), col)


## Teletransporte TCP: SYN en el origen (el jugador se empaqueta), el paquete que viaja
## y ACK en el destino.
static func _fx_tcp(ci: CanvasItem, e: Dictionary, s: float, font: Font, light: bool, dim: bool) -> void:
	var a: Vector2 = e["pos"]
	var b: Vector2 = e["end"]
	var ok: Color = e["ok"]
	var dir := (b - a).normalized() if b != a else Vector2.RIGHT
	if s < 0.2:
		var sz := lerpf(8.0, 2.0, ramp(s, 0.0, 0.12))
		var at := _snap(a + Vector2(0, -20))
		ci.draw_rect(Rect2(at - Vector2(sz, sz) * 0.5, Vector2(sz, sz)), Color(NET_CYAN, 1.0 - ramp(s, 0.12, 0.2)))
		if not light:
			_label(ci, font, a + Vector2(0, -34), "SYN", TEXT_1X, Color(NET_CYAN, 1.0 - ramp(s, 0.12, 0.2)))
	var go := ramp(s, 0.1, 0.25)
	if go > 0.0 and go < 1.0:
		var at := a.lerp(b, go) + Vector2(0, -20)
		draw_projectile(ci, at, dir, NET_CYAN, "packet", s, false, dim)
		if not light:
			for k in 3:
				ci.draw_rect(Rect2(_snap(at - dir * (28.0 + 8.0 * k)) - Vector2(1, 1), Vector2(2, 2)), Color(NET_CYAN, 0.6 - 0.15 * k))
	var ack := ramp(s, 0.25, 0.35)
	if ack > 0.0:
		var out := 1.0 - ramp(s, 0.45, 0.6)
		var sz := lerpf(2.0, 12.0, ack)
		var at := _snap(b + Vector2(0, -20))
		ci.draw_rect(Rect2(at - Vector2(sz, sz) * 0.5, Vector2(sz, sz)), Color(NET_CYAN, 0.5 * out), false, 2.0)
		ci.draw_arc(_snap(b), 40.0 * (0.7 + 0.3 * ack), 0.0, TAU, 32, Color(NET_CYAN, 0.6 * out), 1.0)
		if not light:
			_label(ci, font, b + Vector2(0, -36 - 8.0 * ramp(s, 0.25, 0.6)), "ACK", TEXT_1X, Color(ok, out))


## Candado de 8×10: arco y cuerpo. `drop` baja el arco (cerrado); `open` lo levanta y gira.
static func _padlock(ci: CanvasItem, at: Vector2, col: Color, drop: float, open := 0.0) -> void:
	ci.draw_rect(Rect2(at + Vector2(-4, -2), Vector2(8, 6)), col)
	var top := at + Vector2(0, -2 - 2.0 * (1.0 - drop) - 2.0 * open)
	ci.draw_arc(top + Vector2(-2.0 * open, 0), 3.0, PI, TAU, 8, col, 2.0)


## Seis zigzags radiales del centro al radio (la descarga del handshake).
static func _radial_zaps(ci: CanvasItem, center: Vector2, r: float, col: Color, sd: int, flicker: int) -> void:
	for k in 6:
		var d := Vector2.from_angle(TAU * k / 6.0 + hash01(sd, k) * 0.5)
		var side := d.orthogonal()
		var pts := PackedVector2Array([_snap(center + d * 10.0)])
		for j in range(1, 5):
			pts.append(_snap(center + d * (10.0 + (r - 10.0) * j / 4.0) + side * (hash01(sd + flicker, k * 5 + j) - 0.5) * 12.0))
		ci.draw_polyline(pts, col, 2.0)


## Túnel SSH: candado que se cierra y descarga al salir, un tubo con asteriscos que
## corren por dentro, y en el destino el candado abierto con su llave y otra descarga.
static func _fx_ssh(ci: CanvasItem, e: Dictionary, s: float, light: bool, dim: bool) -> void:
	var a: Vector2 = e["pos"]
	var b: Vector2 = e["end"]
	var r: float = e["radius"]
	var c: Color = e["color"]
	var sd: int = e["seed"]
	var flicker := 0 if dim else int(s * 30.0)
	var z0 := 1.0 - ramp(s, 0.05, 0.3)
	if z0 > 0.0:
		_radial_zaps(ci, a, r, Color(c, 0.9 * z0), sd, flicker)
	var z1 := ramp(s, 0.15, 0.17) * (1.0 - ramp(s, 0.25, 0.48))
	if z1 > 0.0:
		_radial_zaps(ci, b, r, Color(c, 0.9 * z1), sd + 7, flicker)
	var tube := 1.0 - ramp(s, 0.3, 0.5)
	var dir := (b - a).normalized() if b != a else Vector2.RIGHT
	var side := dir.orthogonal() * 5.0
	var lift := Vector2(0, -16)
	ci.draw_line(_snap(a + lift + side), _snap(b + lift + side), Color(c, 0.6 * tube), 2.0)
	ci.draw_line(_snap(a + lift - side), _snap(b + lift - side), Color(c, 0.6 * tube), 2.0)
	if not light:
		var run := ramp(s, 0.03, 0.23)
		if run > 0.0 and run < 1.0:
			for k in 4:
				var q := _snap(a.lerp(b, clampf(run - k * 0.08, 0.0, 1.0)) + lift)
				ci.draw_line(q + Vector2(-2, 0), q + Vector2(2, 0), c.lightened(0.5), 2.0)
				ci.draw_line(q + Vector2(0, -2), q + Vector2(0, 2), c.lightened(0.5), 2.0)
	var lock_a := 1.0 - ramp(s, 0.25, 0.4)
	if lock_a > 0.0:
		_padlock(ci, _snap(a + Vector2(0, -44)), Color(LOCK_YELLOW, lock_a), ramp(s, 0.0, 0.1))
	var lock_b := ramp(s, 0.15, 0.2) * (1.0 - ramp(s, 0.4, 0.5))
	if lock_b > 0.0:
		var at := _snap(b + Vector2(0, -44))
		_padlock(ci, at, Color(LOCK_YELLOW, lock_b), 1.0, 1.0)
		var turn := ramp(s, 0.2, 0.35) * PI / 2.0
		var kd := Vector2.from_angle(turn)
		var key_at := at + Vector2(10, 2)
		ci.draw_line(key_at - kd * 5.0, key_at + kd * 5.0, Color(LOCK_YELLOW, lock_b), 2.0)
		ci.draw_rect(Rect2(_snap(key_at - kd * 5.0) - Vector2(2, 2), Vector2(4, 4)), Color(LOCK_YELLOW, lock_b))


## Git Revert, el salto: el arco hacia atrás y una flecha curva sobre la cabeza.
static func _fx_revert_jump(ci: CanvasItem, e: Dictionary, s: float) -> void:
	var a: Vector2 = e["pos"]
	var b: Vector2 = e["end"]
	var c: Color = e["color"]
	var t := ramp(s, 0.0, 0.3)
	var pts := PackedVector2Array()
	for k in 9:
		var f := k / 8.0
		pts.append(_snap(a.lerp(b, f) + Vector2(0, -sin(f * PI) * 40.0)))
	ci.draw_polyline(pts, Color(c, 0.5 * (1.0 - t)), 2.0)
	var head := _snap(b + Vector2(0, -52))
	var alpha := 1.0 - ramp(s, 0.15, 0.3)
	ci.draw_arc(head, 8.0, PI, TAU, 12, Color(c.lightened(0.3), alpha), 2.0)
	var tip := head + Vector2(-8, 0)
	ci.draw_colored_polygon(PackedVector2Array([tip + Vector2(-4, -2), tip + Vector2(4, -2), tip + Vector2(0, 4)]), Color(c.lightened(0.3), alpha))


## Zona de Git Revert: un rectángulo de diff (rayas rojas de lo quitado y celestes de
## lo añadido, que se congela) con escarcha en el borde, y el fantasma del jugador
## donde estaba. `life`: segundos que le quedan; `fade`: 0..1 al apagarse.
static func draw_revert_zone(ci: CanvasItem, pos: Vector2, r: float, col: Color, err: Color, sd: int, life: float, fade: float, light := false, dim := false) -> void:
	var half := Vector2(r, r * 0.7)
	var top := _snap(pos - half)
	var rows := int(half.y * 2.0 / 6.0)
	for k in rows:
		ci.draw_rect(Rect2(top + Vector2(0, 6 * k), Vector2(half.x * 2.0, 2)), Color(err if k % 2 == 0 else col, (0.35 if k % 2 == 0 else 0.5) * fade))
	ci.draw_rect(Rect2(top, half * 2.0), Color(col, 0.6 * fade), false, 2.0)
	if not light:
		for k in 14:
			var f := hash01(sd, k)
			var edge := k % 4
			var q := top + (Vector2(f * half.x * 2.0, 0.0 if edge == 0 else half.y * 2.0) if edge < 2 else Vector2(0.0 if edge == 2 else half.x * 2.0, f * half.y * 2.0))
			ci.draw_rect(Rect2(_snap(q) - Vector2(1, 1), Vector2(2, 2)), Color(Color.WHITE if not dim else col.lightened(0.4), 0.8 * fade))
	# El fantasma: parpadea cada 0,5 s (fijo con Menos destellos).
	var blink := 0.5 if dim or fmod(life, 1.0) < 0.5 else 0.3
	_silhouette(ci, pos, Color(col.lightened(0.3), blink * fade))


# --- Firmas de hechizos y proyectiles (T194) ---
# Las nueve de la ficha de T191 que compartían la forma de su tipo de daño o el efecto
# genérico de su kind (anillo, cono, rayo, zigzag, marcador o charco). Van por el mismo
# camino que las de T193: un {"type": "firma"} en SkillController._effects que se dibuja
# con draw_move_fx; el charco de Fuga de Memoria, con draw_leak_zone. Algunas tienen un
# segundo efecto para el golpe («ping_letal_hit», «rayo_produccion_fire»).

## Las habilidades con firma de hechizo.
const SPELL_IDS := ["ping_letal", "fork_bomb", "stack_overflow", "flamewar", "rayo_produccion",
	"deadlock", "excepcion_en_cadena", "fuga_de_memoria", "core_dump"]
## Duración (s) de cada efecto; las de retardo, aturdimiento o saltos la cambian al lanzarse.
const SPELL_FX := {
	"ping_letal": 0.3, "ping_letal_hit": 0.5, "fork_bomb": 0.95, "stack_overflow": 0.75, "flamewar": 0.42,
	"rayo_produccion": 0.45, "rayo_produccion_fire": 0.35, "deadlock": 1.75, "excepcion_en_cadena": 0.5,
	"fuga_de_memoria": 0.25, "core_dump": 0.62,
}
const FLAME_YELLOW := Color("ffc04a")
const DUMP_GREY := Color("c8ccd4")
const BUBBLE_DARK := Color("1e2229")
## Separación de las celdas de memoria del charco de Fuga de Memoria (celdas de 6×6).
const LEAK_PITCH := 10.0


## Rectángulo girado: x a lo largo de `dir`, y a lo ancho.
static func _oriented(at: Vector2, dir: Vector2, x0: float, x1: float, y0: float, y1: float) -> PackedVector2Array:
	var side := dir.orthogonal()
	return PackedVector2Array([at + dir * x0 + side * y0, at + dir * x1 + side * y0, at + dir * x1 + side * y1, at + dir * x0 + side * y1])


## Bocadillo de comentario (rectángulo y piquito) con su texto; `w` es el ancho.
static func _speech(ci: CanvasItem, font: Font, at: Vector2, text: String, w: float, col: Color, text_col: Color, size := TEXT_1X) -> void:
	var q := _snap(at)
	var half := Vector2(_snap(Vector2(w * 0.5, 0)).x, 6)
	ci.draw_rect(Rect2(q - half, half * 2.0), Color(BUBBLE_DARK, 0.85 * col.a))
	ci.draw_rect(Rect2(q - half, half * 2.0), col, false, 2.0)
	ci.draw_colored_polygon(PackedVector2Array([q + Vector2(-4, 6), q + Vector2(2, 6), q + Vector2(-4, 10)]), col)
	if text != "":
		_label(ci, font, q + Vector2(0, 4), text, size, text_col)


## Un «!» de 2 px de ancho (barra y punto).
static func _bang(ci: CanvasItem, at: Vector2, col: Color) -> void:
	ci.draw_rect(Rect2(at + Vector2(-1, -4), Vector2(2, 4)), col)
	ci.draw_rect(Rect2(at + Vector2(-1, 2), Vector2(2, 2)), col)


## Ping Letal al lanzar: «64 bytes» sobre el jugador y un destello cuadrado en la mano.
static func _fx_ping_cast(ci: CanvasItem, e: Dictionary, s: float, font: Font, light: bool, dim: bool) -> void:
	var a: Vector2 = e["pos"]
	var dir: Vector2 = e["dir"]
	var c: Color = e["color"]
	var flash := 1.0 - ramp(s, 0.0, 0.12)
	if flash > 0.0:
		var q := _snap(a + dir * 16.0 + Vector2(0, -24))
		ci.draw_rect(Rect2(q - Vector2(3, 3), Vector2(6, 6)), Color(c.lightened(0.25) if dim else Color.WHITE, flash))
	if not light:
		_label(ci, font, a + Vector2(0, -50.0 - 10.0 * ramp(s, 0.0, 0.3)), "64 bytes", TEXT_1X, Color(c, 1.0 - ramp(s, 0.2, 0.3)))


## Ping Letal en cada enemigo: su tiempo de respuesta y, en el último, el eco.
static func _fx_ping_hit(ci: CanvasItem, e: Dictionary, s: float, font: Font, light: bool) -> void:
	var at: Vector2 = e["pos"]
	var c: Color = e["color"]
	if bool(e.get("echo", false)):
		var g := ramp(s, 0.0, 0.35)
		ci.draw_arc(_snap(at), 2.0 + 22.0 * g, 0.0, TAU, 24, Color(c, 0.8 * (1.0 - g)), 2.0)
	if not light:
		_label(ci, font, at + Vector2(16, -28.0 - 8.0 * ramp(s, 0.0, 0.5)), "%dms" % int(e.get("ms", 12)), TEXT_1X,
			Color(c.lightened(0.3), 1.0 - ramp(s, 0.35, 0.5)))


## Dónde acaba la copia k (0..15) de Fork Bomb: repartidas por el radio en espiral; la 0, en el centro.
static func _fork_spot(e: Dictionary, k: int) -> Vector2:
	if k == 0:
		return e["pos"]
	var r: float = e["radius"]
	return e["pos"] + Vector2.from_angle(2.39996 * k + hash01(e["seed"], 0) * TAU) * r * 0.85 * sqrt((k + 0.5) / 16.0)


## Fork Bomb: el cuadrado se divide en 2, 4, 8 y 16 copias durante el retardo (cada
## una se aparta de su madre) y las 16 estallan a la vez, con el anillo y el humo.
static func _fx_fork_bomb(ci: CanvasItem, e: Dictionary, s: float, light: bool, dim: bool) -> void:
	var at := _snap(e["pos"])
	var r: float = e["radius"]
	var c: Color = e["color"]
	var core := c.lightened(0.3 if dim else 0.6)
	var delay := maxf(0.05, float(e.get("delay", 0.45)))
	var q := delay / 4.0
	if s < delay:
		ci.draw_arc(at, r, 0.0, TAU, 40, Color(c, 0.2 + 0.25 * ramp(s, 0.0, delay)), 2.0)
		var lvl := mini(int(s / q), 3)
		var n := 1 << (lvl + 1)   # 2, 4, 8 y 16
		var stride := 16 / n
		var f := ramp(s, 0.04, q * 0.7) if lvl == 0 else ramp(s - lvl * q, 0.0, q * 0.7)
		for j in n:
			if lvl == 0 and j == 1 and s < 0.04:
				break   # al lanzar, un solo cuadrado
			var k := j * stride
			var to := _fork_spot(e, k)
			var from := _fork_spot(e, k - stride) if j % 2 == 1 else to   # la copia nueva sale de su madre
			var p := _snap(from.lerp(to, f))
			ci.draw_rect(Rect2(p - Vector2(3, 3), Vector2(6, 6)), c)
			ci.draw_rect(Rect2(p - Vector2(1, 1), Vector2(2, 2)), core)
		return
	var u := s - delay
	var boom := ramp(u, 0.0, 0.12)
	var out := 1.0 - ramp(u, 0.12, 0.3)
	if out > 0.0:
		for k in 16:
			var p := _snap(_fork_spot(e, k))
			ci.draw_circle(p, lerpf(4.0, 10.0, boom), Color(c, 0.85 * out))
			ci.draw_circle(p, lerpf(2.0, 5.0, boom), Color(core, 0.9 * out))
	var ring := ramp(u, 0.08, 0.35)
	if ring > 0.0 and ring < 1.0:
		ci.draw_arc(at, r * (0.75 + 0.25 * ring), 0.0, TAU, 48, Color(c.lightened(0.2), 0.9 * (1.0 - ring)), 3.0)
	if light:
		return
	for k in 3:
		var sm := ramp(u, 0.1 + 0.04 * k, 0.5)
		if sm > 0.0 and sm < 1.0:
			ci.draw_circle(_snap(_fork_spot(e, 3 + 5 * k) + Vector2(0, -16.0 * sm)), 5.0 + 8.0 * sm, Color(TOKEN_GREY, 0.45 * (1.0 - sm)))


## Stack Overflow: cinco bloques se apilan sobre el jugador (el último, rojo), la pila se
## derrumba en ocho bloques que se deslizan hasta el radio dejando escarcha, y cada
## enemigo queda un momento en un cuadro de hielo.
static func _fx_stack(ci: CanvasItem, e: Dictionary, s: float, light: bool, dim: bool) -> void:
	var at := _snap(e["pos"])
	var r: float = e["radius"]
	var c: Color = e["color"]
	var err: Color = e["err"]
	var frost := c.lightened(0.4) if dim else Color.WHITE
	if s < 0.22:
		var gone := 1.0 - ramp(s, 0.16, 0.22)
		for k in 5:
			if s < 0.03 * k:
				break
			ci.draw_rect(Rect2(at + Vector2(-8, -46 - 6 * k), Vector2(16, 4)), Color(err if k == 4 else c, gone))
	var go := ramp(s, 0.16, 0.41)
	var fade := 1.0 - ramp(s, 0.41, 0.58)
	var mid := at + Vector2(0, -12)
	if go > 0.0 and fade > 0.0:
		for k in 8:
			var d := Vector2.from_angle(TAU * k / 8.0)
			ci.draw_rect(Rect2(_snap(mid + d * r * go) - Vector2(8, 2), Vector2(16, 4)), Color(err if k == 0 else c, fade))
			if light:
				continue
			for j in 3:
				var f := 0.25 * (j + 1)
				if go >= f:
					var q := _snap(mid + d * r * f + d.orthogonal() * (hash01(e["seed"], k * 3 + j) - 0.5) * 8.0)
					ci.draw_rect(Rect2(q - Vector2(1, 1), Vector2(2, 2)), Color(frost, 0.8 * fade))
	for m in e["marks"]:
		var reach := 0.16 + 0.25 * clampf(m.distance_to(e["pos"]) / maxf(1.0, r), 0.0, 1.0)
		var box := ramp(s, reach, reach + 0.04) * (1.0 - ramp(s, reach + 0.26, reach + 0.32))
		if box > 0.0:
			var rect := Rect2(_snap(m) + Vector2(-14, -34), Vector2(28, 38))
			ci.draw_rect(rect, Color(c, 0.22 * box))
			ci.draw_rect(rect, Color(c.lightened(0.35), 0.9 * box), false, 2.0)


## Desplazamiento de ±2 px de una llama (fijo con Menos destellos).
static func _jit(sd: int, k: int) -> float:
	return (hash01(sd, k) - 0.5) * 4.0


## Hasta dónde tiene que haber llegado el cono para dibujar las lenguas (más cortas, sus
## puntos se juntan en la rejilla y el polígono no se triangula).
const FLAME_MIN_REACH := 40.0


## Una lengua de llama de largo `ln` y medio ancho `w` en la dirección `d`: seis puntos
## que tiemblan ±2 px. Los medios anchos no bajan de 6 y 4 px, así los dos lados nunca se
## cruzan ni coinciden al pegarse a la rejilla (si no, «triangulation failed»).
static func _flame_tongue(o: Vector2, d: Vector2, ln: float, w: float, sd: int, k: int) -> PackedVector2Array:
	var side := d.orthogonal()
	var w1 := maxf(6.0, w + _jit(sd, k * 9 + 1))
	var w2 := maxf(4.0, w * 0.55 + _jit(sd, k * 9 + 2))
	var w4 := maxf(4.0, w * 0.55 + _jit(sd, k * 9 + 4))
	var w5 := maxf(6.0, w + _jit(sd, k * 9 + 5))
	return PackedVector2Array([
		_snap(o + d * 4.0),
		_snap(o + d * maxf(ln * 0.4, 12.0) + side * w1),
		_snap(o + d * maxf(ln * 0.75, 22.0) + side * w2),
		_snap(o + d * maxf(ln, 32.0) + side * _jit(sd, k * 9 + 3)),
		_snap(o + d * maxf(ln * 0.75, 22.0) - side * w4),
		_snap(o + d * maxf(ln * 0.4, 12.0) - side * w5),
	])


## Flamewar: los bocadillos «TAB» y «SPC» en los bordes del cono, tres lenguas de llama
## que avanzan hasta el radio con brasas «!», y un «>:(» que arde en cada enemigo.
static func _fx_flamewar(ci: CanvasItem, e: Dictionary, s: float, font: Font, light: bool, dim: bool) -> void:
	var o: Vector2 = e["pos"]
	var dir: Vector2 = e["dir"]
	var r: float = e["radius"]
	var half: float = e.get("half", 0.6)
	var c: Color = e["color"]
	var err: Color = e["err"]
	var sd: int = e["seed"] + (0 if dim else int(s * 30.0))
	var reach := r * ramp(s, 0.0, 0.25)
	var fade := 1.0 - ramp(s, 0.27, 0.4)
	if fade > 0.0 and reach > FLAME_MIN_REACH:
		var w := maxf(6.0, reach * sin(half) * 0.4)
		for k in 3:
			var d := dir.rotated(lerpf(-half, half, k / 2.0) * 0.66)
			for layer in 2:
				var pts := _flame_tongue(o, d, reach * (1.0 if layer == 0 else 0.8), w * (1.0 if layer == 0 else 0.55), sd, k)
				ci.draw_colored_polygon(pts, Color(c if layer == 0 else FLAME_YELLOW, (0.7 if layer == 0 else 0.85) * fade))
	if light:
		return
	var ba := 1.0 - ramp(s, 0.28, 0.38)
	if ba > 0.0:
		for k in 2:
			var q := o + dir.rotated(half if k == 1 else -half) * r * 0.45 + Vector2(0, -18)
			_speech(ci, font, q, "TAB" if k == 0 else "SPC", 26.0, Color(c.lightened(0.3), ba), Color(FLAME_YELLOW, ba))
	for k in 5:
		var age := ramp(s, 0.05 + 0.04 * k, 0.3 + 0.04 * k)
		if age > 0.0 and age < 1.0:
			var q := o + dir.rotated(lerpf(-half, half, hash01(e["seed"], k + 20))) * reach * (0.3 + 0.6 * hash01(e["seed"], k + 30))
			_bang(ci, _snap(q + Vector2(0, -14.0 * age)), Color(err, 1.0 - age))
	var burn := ramp(s, 0.08, 0.12) * (1.0 - ramp(s, 0.32, 0.42))
	if burn > 0.0:
		var shrink := ramp(s, 0.12, 0.42)
		for m in e["marks"]:
			_speech(ci, font, m + Vector2(16, -32), ">:(" if shrink < 0.6 else "", lerpf(24.0, 10.0, shrink),
				Color(c.lerp(err, shrink), burn), Color(FLAME_YELLOW, burn), TEXT_1X if shrink < 0.3 else 8)


## Rayo de Producción, la carga: la franja que va a barrer, una línea discontinua con
## «main» cada 60 px y una barra de progreso que se llena sobre el jugador.
static func _fx_rayo_charge(ci: CanvasItem, e: Dictionary, s: float, font: Font, light: bool) -> void:
	var a: Vector2 = e["pos"]
	var dir: Vector2 = e["dir"]
	var length: float = e.get("length", 600.0)
	var c: Color = e["color"]
	var t := ramp(s, 0.0, e["duration"])
	ci.draw_line(a, a + dir * length, Color(c, 0.08 + 0.1 * t), e["radius"])
	for k in mini(int(length / 16.0), 80):
		ci.draw_line(_snap(a + dir * 16.0 * k), _snap(a + dir * (16.0 * k + 10.0)), Color(c, 0.5 + 0.4 * t), 2.0)
	if not light:
		for k in range(1, mini(int(length / 60.0), 16) + 1):
			_label(ci, font, a + dir * 60.0 * k + Vector2(0, -8), "main", TEXT_1X, Color(c.lightened(0.3), 0.75))
	var bar := _snap(a + Vector2(-10, -56))
	ci.draw_rect(Rect2(bar - Vector2(2, 2), Vector2(24, 8)), Color(BUBBLE_DARK, 0.85))
	ci.draw_rect(Rect2(bar, Vector2(_snap(Vector2(20.0 * t, 0)).x, 4)), c)


## Rayo de Producción, el disparo: núcleo y halo con tres franjas de alarma que corren
## a lo largo, un «500» al final y chispas en cada enemigo golpeado.
static func _fx_rayo_fire(ci: CanvasItem, e: Dictionary, s: float, font: Font, light: bool, dim: bool) -> void:
	var a: Vector2 = e["pos"]
	var b: Vector2 = e["end"]
	var dir: Vector2 = e["dir"]
	var w: float = e["radius"]
	var c: Color = e["color"]
	var err: Color = e["err"]
	var on := 1.0 - ramp(s, 0.2, 0.3)
	if on > 0.0:
		ci.draw_line(a, b, Color(c, 0.55 * on), w * (1.0 + 0.3 * ramp(s, 0.0, 0.3)))
		ci.draw_line(a, b, Color(c.lightened(0.3) if dim else Color.WHITE, 0.95 * on), 4.0)
		var length := a.distance_to(b)
		for k in 3:
			var mid := a + dir * length * fmod(ramp(s, 0.0, 0.25) * 1.2 + k / 3.0, 1.0)
			for j in 4:
				var x := 6.0 * (j - 2)
				ci.draw_colored_polygon(_oriented(mid, dir, x, x + 6.0, -w * 0.3, w * 0.3), Color(err if j % 2 == 0 else PIPE_YELLOW, 0.8 * on))
	if light:
		return
	_label(ci, font, b + Vector2(0, -24.0 + 10.0 * ramp(s, 0.0, 0.35)), "500", TEXT_2X, Color(err, 1.0 - ramp(s, 0.25, 0.35)))
	if s < 0.25:
		for m in e["marks"]:
			for k in 4:
				var q := _snap(m + Vector2(0, -14) + Vector2(hash01(e["seed"], k) - 0.5, hash01(e["seed"], k + 4) - 0.5) * 20.0)
				ci.draw_rect(Rect2(q, Vector2(2, 2)), Color(PIPE_YELLOW, 1.0 - ramp(s, 0.15, 0.25)))


## Reloj de arena de 6×8 girado `angle` alrededor de `at`.
static func _hourglass(ci: CanvasItem, at: Vector2, angle: float, col: Color) -> void:
	var top := PackedVector2Array([Vector2(-3, -4), Vector2(3, -4), Vector2(0, 0)])
	var bottom := PackedVector2Array([Vector2(0, 0), Vector2(3, 4), Vector2(-3, 4)])
	for k in 3:
		top[k] = at + top[k].rotated(angle)
		bottom[k] = at + bottom[k].rotated(angle)
	ci.draw_colored_polygon(top, col)
	ci.draw_colored_polygon(bottom, col)


## Deadlock: dos candados y dos flechas que se persiguen en círculo, un anillo de cadena
## que se expande hasta el radio, y un reloj de arena que gira sobre cada aturdido.
static func _fx_deadlock(ci: CanvasItem, e: Dictionary, s: float, light: bool, dim: bool) -> void:
	var at := _snap(e["pos"])
	var r: float = e["radius"]
	var c: Color = e["color"]
	var cast := 1.0 - ramp(s, 0.45, 0.6)
	if cast > 0.0:
		for sgn in [-1.0, 1.0]:
			_padlock(ci, at + Vector2(18.0 * sgn, -30), Color(LOCK_YELLOW, cast), 1.0)
		var spin := TAU * ramp(s, 0.0, 0.6)
		var rr := r * 0.5
		for k in 2:
			var a0 := spin + PI * k - PI / 2.0
			ci.draw_arc(at, rr, a0 - 1.2, a0, 10, Color(c.lightened(0.3), cast), 2.0)
			var tip := at + Vector2.from_angle(a0) * rr
			var tang := Vector2.from_angle(a0 + PI / 2.0)
			var rad := Vector2.from_angle(a0)
			ci.draw_colored_polygon(PackedVector2Array([tip + tang * 6.0, tip + rad * 4.0, tip - rad * 4.0]), Color(c.lightened(0.3), cast))
	var grow := ramp(s, 0.0, 0.2)
	var fade := 1.0 - ramp(s, 0.3, 0.55)
	if grow > 0.0 and fade > 0.0:
		var R := r * grow
		var n := clampi(int(TAU * R / 12.0), 6, 72)
		for k in n:
			var ang := TAU * k / n
			var tang := Vector2.from_angle(ang + PI / 2.0)
			var p := at + Vector2.from_angle(ang) * R
			var link := _oriented(p, tang, -3, 3, -1.5, 1.5) if k % 2 == 0 else _oriented(p, tang, -1.5, 1.5, -3, 3)
			ci.draw_colored_polygon(link, Color(c.lightened(0.2), 0.9 * fade))
	var stun: float = e.get("stun", 1.0)
	var on := ramp(s, 0.12, 0.2) * (1.0 - ramp(s, stun - 0.15, stun + 0.1))
	if on <= 0.0:
		return
	# El reloj se da la vuelta cada 0,5 s.
	var flip := PI * (int(s / 0.5) + ramp(fmod(s, 0.5), 0.35, 0.5))
	var frost := c.lightened(0.4) if dim else Color.WHITE
	var marks: PackedVector2Array = e["marks"]
	for k in marks.size():
		var q := _snap(marks[k] + Vector2(0, -46))
		_hourglass(ci, q, flip, Color(c.lightened(0.45), on))
		if light:
			continue
		for j in 4:
			var d := Vector2.from_angle(TAU * j / 4.0 + hash01(e["seed"], k * 4 + j))
			ci.draw_rect(Rect2(_snap(marks[k] + Vector2(0, -14) + d * 14.0) - Vector2(1, 1), Vector2(2, 2)), Color(frost, 0.7 * on))


## Triángulo de aviso de 12×10 con su «!».
static func _warning(ci: CanvasItem, at: Vector2, fill: Color, mark: Color) -> void:
	ci.draw_colored_polygon(PackedVector2Array([at + Vector2(0, -6), at + Vector2(6, 4), at + Vector2(-6, 4)]), fill)
	ci.draw_rect(Rect2(at + Vector2(-1, -3), Vector2(2, 4)), mark)
	ci.draw_rect(Rect2(at + Vector2(-1, 2), Vector2(2, 2)), mark)


## Excepción en Cadena: «throw» sobre el jugador; cada salto, un zigzag que adelgaza con
## una tira de stack trace por encima; un aviso «!» en cada enemigo y «Uncaught» en el último.
static func _fx_exception(ci: CanvasItem, e: Dictionary, s: float, font: Font, light: bool, dim: bool) -> void:
	var hops: PackedVector2Array = e["hops"]
	var c: Color = e["color"]
	var err: Color = e["err"]
	var sd: int = e["seed"]
	var flicker := 0 if dim else int(s * 30.0)
	var miss: bool = e.get("miss", false)
	if not light:
		_label(ci, font, e["pos"] + Vector2(0, -50.0 - 8.0 * ramp(s, 0.0, 0.4)), "throw", TEXT_1X, Color(COMMIT_ORANGE, 1.0 - ramp(s, 0.3, 0.4)))
	for k in hops.size() - 1:
		var u := s - 0.06 * k
		if u < 0.0:
			break
		if u > 0.5:
			continue
		var a := hops[k]
		var b := hops[k + 1]
		var fade := 1.0 - ramp(u, 0.18, 0.3)
		if fade > 0.0:
			var side := (b - a).orthogonal().normalized()
			var pts := PackedVector2Array([_snap(a)])
			for j in range(1, 6):
				pts.append(_snap(a.lerp(b, j / 6.0) + side * (hash01(sd + flicker, k * 8 + j) - 0.5) * 16.0))
			pts.append(_snap(b))
			ci.draw_polyline(pts, Color(c, fade), maxf(2.0, 4.0 - k))
			if not light:
				var f := ramp(u, 0.0, 0.2)
				for j in 3:
					var q := _snap(a.lerp(b, clampf(f - 0.08 * j, 0.0, 1.0)) + Vector2(0, -8))
					ci.draw_rect(Rect2(q - Vector2(2, 1), Vector2(4, 2)), Color(DUMP_GREY, fade))
		if miss:
			continue
		var warn := ramp(u, 0.02, 0.06) * (1.0 - ramp(u, 0.32, 0.4))
		if warn > 0.0:
			_warning(ci, _snap(b + Vector2(16, -30)), Color(PIPE_YELLOW, warn), Color(err, warn))
		if k == hops.size() - 2 and not light:
			_label(ci, font, b + Vector2(0, -48.0 - 8.0 * ramp(u, 0.0, 0.5)), "Uncaught", TEXT_1X, Color(err, 1.0 - ramp(u, 0.4, 0.5)))


## Fuga de Memoria al lanzar: una gota morada cae del jugador al punto.
static func _fx_leak_drop(ci: CanvasItem, e: Dictionary, s: float) -> void:
	var a: Vector2 = e["pos"] + Vector2(0, -24)
	var b: Vector2 = e["end"]
	var c: Color = e["color"]
	var f := ramp(s, 0.0, 0.15)
	if f < 1.0:
		var q := _snap(a.lerp(b, f) + Vector2(0, -sin(f * PI) * 30.0))
		ci.draw_rect(Rect2(q + Vector2(-3, -2), Vector2(6, 6)), c)
		ci.draw_rect(Rect2(q + Vector2(-1, -4), Vector2(2, 2)), c)
	else:
		var g := ramp(s, 0.15, 0.25)
		ci.draw_arc(_snap(b), 4.0 + 10.0 * g, 0.0, TAU, 12, Color(c.lightened(0.3), 1.0 - g), 2.0)


## Charco de Fuga de Memoria: una rejilla de celdas de memoria que se encienden una a una
## y no se apagan, y crece del 60 % al 100 % del radio a lo largo de su duración. Sobre
## quien lo pisa suben burbujas con «MB» (`bubbles`, de hace `bubble_age` s).
static func draw_leak_zone(ci: CanvasItem, pos: Vector2, r: float, col: Color, sd: int, elapsed: float, total: float,
		fade: float, bubbles: PackedVector2Array, bubble_age: float, font: Font, light := false) -> void:
	var at := _snap(pos)
	var grow := r * lerpf(0.6, 1.0, clampf(elapsed / maxf(0.1, total), 0.0, 1.0))
	var pts := PackedVector2Array()
	for k in 24:
		pts.append(at + Vector2.from_angle(TAU * k / 24.0) * Vector2(grow, grow * 0.7))
	ci.draw_colored_polygon(pts, Color(col, 0.14 * fade))
	if light:
		return
	var lit_upto := 0.2 + 0.8 * clampf(elapsed / maxf(0.1, total * 0.7), 0.0, 1.0)
	var border := Color(col.lightened(0.35), 0.6 * fade)
	var inner := Color(col, 0.55 * fade)
	var nx := int(grow / LEAK_PITCH)
	var ny := int(grow * 0.7 / LEAK_PITCH)
	for gy in range(-ny, ny + 1):
		for gx in range(-nx, nx + 1):
			var off := Vector2(gx * LEAK_PITCH, gy * LEAK_PITCH)
			if Vector2(off.x, off.y / 0.7).length() > grow - 3.0 or hash01(sd, (gx + 64) * 131 + gy + 64) > lit_upto:
				continue
			ci.draw_rect(Rect2(at + off - Vector2(3, 3), Vector2(6, 6)), border)
			ci.draw_rect(Rect2(at + off - Vector2(2, 2), Vector2(4, 4)), inner)
	if bubble_age >= 0.5:
		return
	var alpha := (1.0 - ramp(bubble_age, 0.35, 0.5)) * fade
	for k in bubbles.size():
		var q := _snap(bubbles[k] + Vector2(-8.0 + 4.0 * (k % 3), -26.0 - 14.0 * ramp(bubble_age, 0.0, 0.5)))
		ci.draw_arc(q, 4.0, 0.0, TAU, 10, Color(col.lightened(0.45), alpha), 2.0)
		_label(ci, font, q + Vector2(16, 4), "MB", TEXT_1X, Color(col.lightened(0.45), alpha))


## Anillo de 16 bloques cuadrados de `size` px a `R` del centro (`phase` gira medio bloque).
static func _block_ring(ci: CanvasItem, at: Vector2, R: float, size: float, col: Color, phase := 0.0) -> void:
	if R < 2.0 or col.a <= 0.0:
		return
	for k in 16:
		var q := _snap(at + Vector2.from_angle(TAU * (k + phase) / 16.0) * R)
		ci.draw_rect(Rect2(q - Vector2(size, size) * 0.5, Vector2(size, size)), col)


## Core Dump: un volcado hexadecimal que sale en espiral, un anillo de bloques y otro por
## cada tipo de carga gastado (sin cargas, un anillo fino gris), y «core» en cada enemigo.
static func _fx_core_dump(ci: CanvasItem, e: Dictionary, s: float, font: Font, light: bool, dim: bool) -> void:
	var at := _snap(e["pos"])
	var r: float = e["radius"]
	var c: Color = e["color"]
	var rings: Array = e.get("rings", [])
	if not light:
		var sp := ramp(s, 0.0, 0.2)
		var sa := 1.0 - ramp(s, 0.2, 0.32)
		if sa > 0.0:
			for k in 12:
				var q := _snap(at + Vector2(0, -20) + Vector2.from_angle(k * 0.52 + sp * 2.4) * (6.0 + sp * (14.0 + 3.0 * k)))
				ci.draw_rect(Rect2(q - Vector2(2, 1), Vector2(4, 2)), Color(DUMP_GREY, sa))
	if rings.is_empty():
		var g := ramp(s, 0.0, 0.25)
		var fade := 1.0 - ramp(s, 0.3, 0.45)
		_block_ring(ci, at, r * g, 4.0, Color(TOKEN_GREY, 0.8 * fade))
		if g > 0.0:
			ci.draw_arc(at, r * g, 0.0, TAU, 40, Color(TOKEN_GREY, 0.5 * fade), 1.0)
	else:
		_block_ring(ci, at, r * ramp(s, 0.0, 0.25), 6.0, Color(c, 0.9 * (1.0 - ramp(s, 0.3, 0.45))))
		for i in rings.size():
			var d := 0.05 * (i + 1)
			_block_ring(ci, at, r * ramp(s, d, d + 0.25) * (1.0 - 0.08 * (i + 1)), 6.0,
				Color(rings[i], 0.9 * (1.0 - ramp(s, 0.3 + d, 0.45 + d))), 0.5 * (i + 1))
	var alpha := ramp(s, 0.1, 0.14) * (1.0 - ramp(s, 0.4, 0.5))
	if alpha <= 0.0:
		return
	var crit := bool(e.get("crit", false)) and s >= 0.1 and s < 0.2
	for m in e["marks"]:
		if crit:
			ci.draw_rect(Rect2(_snap(m) + Vector2(-5, -19), Vector2(10, 10)), Color(c.lightened(0.25), 0.6) if dim else Color.WHITE)
		if not light:
			_label(ci, font, m + Vector2(16, -26), "core", TEXT_1X, Color(c.lightened(0.3), alpha))


# --- Firmas de buffs, gritos, barrera y auras (T195) ---
# Las seis de buff, grito y barrera son un efecto «firma» que sigue al jugador
# ("live": SkillController le pone su posición cada fotograma) y dura lo que el buff
# o la barrera: «al lanzar» son sus primeros `cast` s; luego queda lo que se ve
# mientras dura, y al acabarse (`end`) se apaga. Lo que va sobre cada invocación lo
# dibuja draw_buff_ally. Las auras no son efectos: SkillController las dibuja con
# draw_aura (anillo con su motivo), draw_aura_ally y draw_aura_enemy; al apagarse,
# un efecto «aura_off» desdibuja el anillo.

## Las habilidades con firma de buff, grito o barrera.
const BUFF_IDS := ["firewall_personal", "modo_seguro", "hiperthreading", "esta_en_produccion", "daily_standup", "rollback_grito"]
## Duración (s) de lo que se ve al lanzar; las que siguen al jugador la alargan a lo que dura el buff.
const BUFF_FX := {
	"firewall_personal": 0.3, "modo_seguro": 0.6, "hiperthreading": 0.4, "esta_en_produccion": 0.8,
	"daily_standup": 0.6, "rollback_grito": 0.6, "aura_off": 0.2,
}
## Las que siguen al jugador mientras dura el buff (Rollback solo tiene lo del lanzamiento).
const BUFF_LIVE := ["firewall_personal", "modo_seguro", "hiperthreading", "esta_en_produccion", "daily_standup"]
## Lo que tarda en apagarse lo que sigue al jugador cuando se acaba el buff.
const BUFF_FADE := 0.25
const BRICK := Color("a04a3a")
const SIREN_BLUE := Color("5a8fd8")
## Huellas de prisa de Daily que se recuerdan (una cada 0,1 s).
const DAILY_STEPS := 6
## Estilo de cada aura: su color y, para el modo daltónico, el tipo de daño cuyo color
## seguro toma (Accessibility.aura_color), para que tampoco ahí se vean iguales.
const AURA_STYLE := {
	"aura_overclock": {"color": Color("ff8a2a"), "cb": "fire"},
	"aura_blindaje": {"color": Color("a0a8b8"), "cb": "physical"},
	"aura_mantenimiento": {"color": Color("5cb85c"), "cb": "none"},
	"aura_mando": {"color": Color("ffc04a"), "cb": "lightning"},
	"aura_throttling": {"color": Color("5a8fd8"), "cb": "cold"},
	"aura_exposicion": {"color": Color("d9534f"), "cb": "chaos"},
}
## El anillo de las auras va aplastado en el suelo, como el alcance de siempre.
const AURA_SQUASH := 0.62
## Las auras marcan como mucho estos enemigos de dentro (reloj de arena, «CVE»).
const AURA_MARKS := 10


static func is_live(id: String) -> bool:
	return BUFF_LIVE.has(id)


## Color de un aura (el seguro del modo daltónico si está puesto); `fallback`, si no tiene estilo.
static func aura_tint(id: String, fallback: Color) -> Color:
	if not AURA_STYLE.has(id):
		return fallback
	return Accessibility.aura_color(String(AURA_STYLE[id]["cb"]), AURA_STYLE[id]["color"])


## Cuánto queda de lo que sigue al jugador: 1 mientras dura el buff y baja al acabarse.
static func _live_fade(e: Dictionary, s: float) -> float:
	var end := float(e.get("end", -1.0))
	return 1.0 if end < 0.0 else 1.0 - ramp(s, end, end + BUFF_FADE)


## Firewall Personal: 12 ladrillos que se colocan en anillo; mientras dura la barrera,
## el muro tenue con una llamita que lo recorre; al absorber un golpe, el ladrillo de ese
## lado destella con «DENY»; al acabarse, los ladrillos caen y se apagan.
static func _fx_firewall(ci: CanvasItem, e: Dictionary, s: float, font: Font, light: bool, dim: bool) -> void:
	var at := _snap(e["pos"] + Vector2(0, -14))
	var cast := float(e.get("cast", 0.3))
	var end := float(e.get("end", -1.0))
	var down := ramp(s, end, end + 0.3) if end >= 0.0 else 0.0
	var since_hit := s - float(e.get("hit", -9.0))
	var hit_dir: Vector2 = e.get("hit_dir", Vector2.RIGHT)
	var hit_k := posmod(roundi(hit_dir.angle() / TAU * 12.0), 12) if since_hit < 0.12 else -1
	var settle := lerpf(1.0, 0.35, ramp(s, cast, cast + 0.2))
	for k in 12:
		var appear := ramp(s, 0.02 * k, 0.02 * k + 0.06)
		if appear <= 0.0:
			continue
		var q := _snap(at + Vector2.from_angle(TAU * k / 12.0) * 26.0 + Vector2(0, -4.0 * (1.0 - appear) + 6.0 * down))
		var alpha := settle * (1.0 - down)
		var fill := BRICK
		if k == hit_k:
			fill = BRICK.lightened(0.5) if dim else Color.WHITE
			alpha = 0.95
		ci.draw_rect(Rect2(q - Vector2(4, 2), Vector2(8, 4)), Color(fill, alpha))
		ci.draw_rect(Rect2(q - Vector2(4, 2), Vector2(8, 4)), Color(TOKEN_GREY, alpha), false, 1.0)
	if s >= cast and down <= 0.0 and not light:
		# La llamita que recorre el muro (una vuelta por segundo).
		var q := _snap(at + Vector2.from_angle(s * TAU) * 26.0 + Vector2(0, -4))
		var flick := 0.0 if dim else float(int(s * 12.0) % 2) * 2.0
		ci.draw_rect(Rect2(q - Vector2(2, 2), Vector2(4, 4)), Color("e0652f"))
		ci.draw_rect(Rect2(q + Vector2(-1, -4 - flick), Vector2(2, 2 + flick)), FLAME_YELLOW)
	if since_hit < 0.5 and not light:
		var err: Color = e["err"]
		_label(ci, font, at + hit_dir * 26.0 + Vector2(0, -14.0 - 10.0 * ramp(since_hit, 0.0, 0.5)), "DENY", TEXT_1X,
			Color(err, 1.0 - ramp(since_hit, 0.35, 0.5)))


## Modo Seguro: el velo negro con «Modo seguro» en las cuatro esquinas al lanzar; luego,
## un hexágono gris sin brillo alrededor del jugador y una sombra cuadrada más ancha (va
## pesado). Al recibir un golpe, el hexágono destella en gris.
static func _fx_safe_mode(ci: CanvasItem, e: Dictionary, s: float, font: Font, light: bool, dim: bool) -> void:
	var p := _snap(e["pos"])
	var veil := 1.0 - ramp(s, 0.45, 0.6)
	if veil > 0.0:
		ci.draw_rect(Rect2(p + Vector2(-80, -76), Vector2(160, 120)), Color(0, 0, 0, 0.4 * veil))
		if not light:
			for corner in [Vector2(-40, -64), Vector2(40, -64), Vector2(-40, 40), Vector2(40, 40)]:
				_label(ci, font, p + corner, "Modo seguro", TEXT_1X, Color(DUMP_GREY, veil), 76.0)
	var fade := _live_fade(e, s) * ramp(s, 0.1, 0.25)
	if fade <= 0.0:
		return
	ci.draw_rect(Rect2(p + Vector2(-14, 2), Vector2(28, 6)), Color(0, 0, 0, 0.3 * fade))
	var center := p + Vector2(0, -16)
	var hexagon := PackedVector2Array()
	for k in 7:
		hexagon.append(_snap(center + Vector2.from_angle(TAU * k / 6.0 + PI / 6.0) * 24.0))
	if s - float(e.get("hit", -9.0)) < 0.1:
		ci.draw_colored_polygon(hexagon.slice(0, 6), Color(DUMP_GREY, 0.35 * fade))
	ci.draw_polyline(hexagon, Color(DUMP_GREY, 0.8 * fade), 2.0)


## Hiperthreading: dos hélices de puntos (amarillo y cian) que se trenzan de los pies a la
## cabeza; luego, el segundo hilo: un doble tenue que sigue al jugador con retraso.
static func _fx_hyperthreading(ci: CanvasItem, e: Dictionary, s: float, light: bool) -> void:
	var p := _snap(e["pos"])
	var cast := 1.0 - ramp(s, 0.4, 0.55)
	if cast > 0.0 and not light:
		var up := ramp(s, 0.0, 0.4)
		for j in 12:
			var f := j / 11.0
			if f > up:
				break
			for h in 2:
				var q := _snap(p + Vector2(sin(f * TAU * 1.5 + s * 10.0 + PI * h) * 12.0, -2.0 - 40.0 * f))
				ci.draw_rect(Rect2(q - Vector2(1, 1), Vector2(2, 2)), Color(PIPE_YELLOW if h == 0 else NET_CYAN, cast))
	var fade := _live_fade(e, s) * ramp(s, 0.2, 0.4)
	if fade > 0.0:
		var lag: Vector2 = e.get("lag", e["pos"])
		var back: Vector2 = e.get("back", Vector2(-4, 0))
		_silhouette(ci, lag + back, Color(NET_CYAN, 0.25 * fade))


## ¡Está en producción!: tres anillos rojos hacia fuera, «¡PROD!» que tiembla y una
## sirena (cúpula roja y azul con su haz que gira) sobre la cabeza.
static func _fx_prod(ci: CanvasItem, e: Dictionary, s: float, font: Font, light: bool, dim: bool) -> void:
	var p := _snap(e["pos"])
	var err: Color = e["err"]
	for k in 3:
		var g := ramp(s, 0.08 * k, 0.08 * k + 0.32)
		if g > 0.0 and g < 1.0:
			ci.draw_arc(p + Vector2(0, -14), 120.0 * g, 0.0, TAU, 40, Color(err, 0.9 * (1.0 - g)), 2.0)
	var on := 1.0 - ramp(s, 0.65, 0.8)
	if on <= 0.0:
		return
	var head := p + Vector2(0, -48)
	var red := dim or int(s / 0.1) % 2 == 0
	var beam := Vector2.from_angle(s * TAU * 3.0)
	ci.draw_line(head + Vector2(0, -2), head + Vector2(0, -2) + beam * 16.0, Color(err if red else SIREN_BLUE, 0.4 * on), 3.0)
	ci.draw_rect(Rect2(head + Vector2(-4, 0), Vector2(8, 2)), Color(TOKEN_GREY, on))
	ci.draw_arc(head, 2.0, PI, TAU, 6, Color(err if red else SIREN_BLUE, on), 4.0)
	if not light:
		var jit := Vector2.ZERO if dim else Vector2(roundf(hash01(e["seed"], int(s * 30.0)) * 2.0 - 1.0), roundf(hash01(e["seed"] + 1, int(s * 30.0)) * 2.0 - 1.0))
		_label(ci, font, p + Vector2(0, -60) + jit, "¡PROD!", TEXT_2X, Color(err, on), 100.0)


## ¡Daily en cinco minutos!: un anillo de reloj amarillo con sus 12 marcas y una aguja que
## da la vuelta mientras crece, «¡DAILY!»; luego, las huellas de prisa del jugador.
static func _fx_daily(ci: CanvasItem, e: Dictionary, s: float, font: Font, light: bool) -> void:
	var p := _snap(e["pos"])
	var center := p + Vector2(0, -14)
	var g := ramp(s, 0.0, 0.5)
	var fade := 1.0 - ramp(s, 0.45, 0.6)
	if fade > 0.0 and g > 0.0:
		var R := 120.0 * g
		ci.draw_arc(center, R, 0.0, TAU, 40, Color(PIPE_YELLOW, 0.85 * fade), 2.0)
		if R > 10.0:
			for k in 12:
				var d := Vector2.from_angle(TAU * k / 12.0)
				ci.draw_line(_snap(center + d * (R - 6.0)), _snap(center + d * R), Color(PIPE_YELLOW, fade), 2.0)
		ci.draw_line(center, center + Vector2.from_angle(-PI / 2.0 + TAU * g) * R * 0.8, Color(PIPE_YELLOW, fade), 2.0)
		if not light:
			_label(ci, font, p + Vector2(0, -60), "¡DAILY!", TEXT_2X, Color(PIPE_YELLOW, fade), 100.0)
	if light:
		return
	var steps: PackedVector2Array = e.get("steps", PackedVector2Array())
	var times: PackedFloat32Array = e.get("step_times", PackedFloat32Array())
	var live := _live_fade(e, s)
	for k in steps.size():
		var age := s - times[k]
		if age < 0.6:
			ci.draw_rect(Rect2(_snap(steps[k]) - Vector2(1, 1), Vector2(2, 2)), Color(PIPE_YELLOW, 0.7 * (1.0 - age / 0.6) * live))


## ¡Rollback!: tres anillos verdes que se cierran hacia el jugador (al revés que los otros
## gritos), «¡ROLLBACK!» con su flecha curva, y un «+» verde que sube de cada invocación curada.
static func _fx_rollback(ci: CanvasItem, e: Dictionary, s: float, font: Font, light: bool) -> void:
	var p := _snap(e["pos"])
	var ok: Color = e["ok"]
	for k in 3:
		var g := ramp(s, 0.08 * k, 0.08 * k + 0.32)
		if g > 0.0 and g < 1.0:
			ci.draw_arc(p + Vector2(0, -14), 120.0 * (1.0 - g), 0.0, TAU, 40, Color(ok, 0.3 + 0.6 * g), 2.0)
	var fade := 1.0 - ramp(s, 0.45, 0.6)
	if fade > 0.0:
		var arrow := p + Vector2(-66, -66)
		ci.draw_arc(arrow, 6.0, -PI * 0.25, PI * 1.25, 10, Color(ok, fade), 2.0)
		var tip := arrow + Vector2.from_angle(-PI * 0.25) * 6.0
		ci.draw_colored_polygon(PackedVector2Array([tip + Vector2(-4, -3), tip + Vector2(3, -3), tip + Vector2(0, 3)]), Color(ok, fade))
		if not light:
			_label(ci, font, p + Vector2(0, -60), "¡ROLLBACK!", TEXT_2X, Color(ok, fade), 120.0)
	var rise := ramp(s, 0.0, 0.6)
	var alpha := 1.0 - ramp(s, 0.4, 0.6)
	for m in e["marks"]:
		_plus(ci, _snap(m + Vector2(0, -30.0 - 12.0 * rise)), Color(ok, alpha))


## Un «+» de 4 px (dos barras de 2 px).
static func _plus(ci: CanvasItem, at: Vector2, col: Color) -> void:
	ci.draw_rect(Rect2(at + Vector2(-2, -1), Vector2(4, 2)), col)
	ci.draw_rect(Rect2(at + Vector2(-1, -2), Vector2(2, 4)), col)


## Lo que lleva cada invocación (`at`, los pies; `r`, su radio) mientras dura un grito:
## un «!» rojo que parpadea (Producción) o un relojito (Daily). `k`: su número, para desfasar.
static func draw_buff_ally(ci: CanvasItem, e: Dictionary, at: Vector2, r: float, k: int, dim: bool) -> void:
	var s: float = e["time"]
	var fade := _live_fade(e, s) * ramp(s, 0.2, 0.35)
	if fade <= 0.0:
		return
	var top := _snap(at + Vector2(0, -r * 2.0 - 12.0))
	match String(e["firma"]):
		"esta_en_produccion":
			if dim or fmod(s + k * 0.13, 0.5) < 0.3:
				_bang(ci, top, Color(e["err"], fade))
		"daily_standup":
			ci.draw_arc(top, 3.0, 0.0, TAU, 10, Color(PIPE_YELLOW, fade), 2.0)
			ci.draw_line(top, top + Vector2.from_angle(s * TAU + k) * 3.0, Color(PIPE_YELLOW, fade), 1.0)


## Arco de la elipse del aura de `a0` a `a1` (radianes).
static func _ell_arc(ci: CanvasItem, c: Vector2, R: float, a0: float, a1: float, col: Color, w := 2.0) -> void:
	var n := maxi(3, int(64.0 * absf(a1 - a0) / TAU))
	var pts := PackedVector2Array()
	for k in n + 1:
		pts.append(_ell(c, R, lerpf(a0, a1, float(k) / n)))
	ci.draw_polyline(pts, col, w)


static func _ell(c: Vector2, R: float, a: float) -> Vector2:
	return c + Vector2(cos(a) * R, sin(a) * R * AURA_SQUASH)


## Engranaje: círculo de 6 px con 4 dientes, girado `rot`.
static func _gear(ci: CanvasItem, at: Vector2, rot: float, col: Color) -> void:
	ci.draw_circle(at, 3.0, col)
	for j in 4:
		var d := Vector2.from_angle(rot + PI * 0.5 * j)
		ci.draw_line(at + d * 2.0, at + d * 5.0, col, 2.0)
	ci.draw_rect(Rect2(at - Vector2(1, 1), Vector2(2, 2)), Color(BUBBLE_DARK, col.a))


## Placa de 10×6 con dos remaches; `shine`, el brillo que la recorre.
static func _plate(ci: CanvasItem, at: Vector2, col: Color, shine: bool) -> void:
	var r := Rect2(at - Vector2(5, 3), Vector2(10, 6))
	ci.draw_rect(r, col.darkened(0.25) if not shine else col.lightened(0.35))
	ci.draw_rect(r, Color(col.lightened(0.2), col.a), false, 1.0)
	for x in [-3.0, 1.0]:
		ci.draw_rect(Rect2(at + Vector2(x, -1), Vector2(2, 2)), Color(BUBBLE_DARK, col.a))


## Llave inglesa de 10×4 con la cabeza abierta, girada hacia `d`.
static func _wrench(ci: CanvasItem, at: Vector2, d: Vector2, col: Color) -> void:
	var side := d.orthogonal()
	ci.draw_line(at - d * 5.0, at + d * 2.0, col, 2.0)
	for sgn in [-1.0, 1.0]:
		ci.draw_line(at + d * 2.0 + side * 2.0 * sgn, at + d * 5.0 + side * 2.0 * sgn, col, 2.0)


## Banderita: palo de 2×10 y triángulo de 6 px que ondea `wave` px.
static func _flag(ci: CanvasItem, at: Vector2, col: Color, wave: float) -> void:
	ci.draw_rect(Rect2(at + Vector2(-1, -10), Vector2(2, 10)), Color(TOKEN_GREY, col.a))
	ci.draw_colored_polygon(PackedVector2Array([at + Vector2(1, -10), at + Vector2(7, -8 + wave), at + Vector2(1, -5)]), col)


## Estrella de 4 px (más grande y clara si `bright`).
static func _star(ci: CanvasItem, at: Vector2, col: Color, bright: bool) -> void:
	var r := 3.0 if bright else 2.0
	var c := col.lightened(0.4) if bright else col
	ci.draw_rect(Rect2(at + Vector2(-r, -1), Vector2(r * 2.0, 2)), c)
	ci.draw_rect(Rect2(at + Vector2(-1, -r), Vector2(2, r * 2.0)), c)


## Un aura activa: su anillo en el suelo con el motivo en el borde. `on_t`: segundos
## desde que se activó (para cómo aparece); `tt`: reloj para lo que gira u ondea.
static func draw_aura(ci: CanvasItem, id: String, center: Vector2, R: float, col: Color, on_t: float, tt: float, hostile: bool) -> void:
	var c := _snap(center)
	var fill := PackedVector2Array()
	for k in 32:
		fill.append(_ell(c, R, TAU * k / 32.0))
	ci.draw_colored_polygon(fill, Color(col, 0.035 if hostile else 0.02))
	var top := -PI / 2.0
	match id:
		"aura_overclock":
			# El anillo naranja se dibuja en 0,3 s; 8 engranajes lo recorren girando.
			var sweep := TAU * ramp(on_t, 0.0, 0.3)
			_ell_arc(ci, c, R, top, top + sweep, Color(col, 0.45))
			for k in 8:
				var a := TAU * k / 8.0 + tt * TAU / 12.0
				if fposmod(a, TAU) > sweep:
					continue
				_gear(ci, _snap(_ell(c, R, top + a)), tt * TAU / 3.0 + k, Color(col, 0.9))
		"aura_blindaje":
			# Gris acero; 6 placas que caen en su sitio una a una y un brillo que las recorre.
			_ell_arc(ci, c, R, 0.0, TAU, Color(col, 0.45 * ramp(on_t, 0.0, 0.15)))
			for k in 6:
				var drop := ramp(on_t, 0.05 * k, 0.05 * k + 0.06)
				if drop <= 0.0:
					continue
				var at := _snap(_ell(c, R, top + TAU * k / 6.0) + Vector2(0, -10.0 * (1.0 - drop)))
				_plate(ci, at, Color(col, drop), fposmod(tt - k * 0.12, 2.0) < 0.15)
		"aura_mantenimiento":
			# El anillo verde en 0,3 s y 4 llaves inglesas que caen y orbitan despacio.
			var sweep := TAU * ramp(on_t, 0.0, 0.3)
			_ell_arc(ci, c, R, top, top + sweep, Color(col, 0.45))
			for k in 4:
				var drop := ramp(on_t, 0.1 + 0.05 * k, 0.2 + 0.05 * k)
				if drop <= 0.0:
					continue
				var at := _snap(_ell(c, R, top + TAU * k / 4.0 + tt * TAU / 5.0) + Vector2(0, -14.0 * (1.0 - drop)))
				_wrench(ci, at, Vector2.from_angle(tt * TAU / 2.0 + k), Color(col, drop))
		"aura_mando":
			# Dorado; 4 banderitas que se clavan en los puntos cardinales y ondean.
			_ell_arc(ci, c, R, 0.0, TAU, Color(col, 0.45 * ramp(on_t, 0.0, 0.15)))
			for k in 4:
				var drop := ramp(on_t, 0.06 * k, 0.06 * k + 0.1)
				if drop <= 0.0:
					continue
				var at := _snap(_ell(c, R, top + TAU * k / 4.0) + Vector2(0, -20.0 * (1.0 - drop)))
				_flag(ci, at, Color(col, drop), roundf(sin(tt * TAU * 4.0 + k)))
		"aura_throttling":
			# Azul, 8 trazos con hueco que giran hacia atrás (una vuelta cada 6 s).
			for k in 8:
				var a0 := top - tt * TAU / 6.0 + TAU * k / 8.0
				_ell_arc(ci, c, R, a0, a0 + TAU / 8.0 * 0.6, Color(col, 0.75), 2.0)
		"aura_exposicion":
			# Rojo, con dientes de sierra hacia dentro (de 4 px, cada 16 px).
			var n := clampi(int(TAU * R * (1.0 + AURA_SQUASH) * 0.5 / 16.0), 16, 200)
			var saw := PackedVector2Array()
			for k in n:
				saw.append(_ell(c, R, TAU * k / n))
				saw.append(_ell(c, R - 6.0, TAU * (k + 0.5) / n))
			saw.append(saw[0])
			ci.draw_polyline(saw, Color(col, 0.6), 2.0)
		_:
			_ell_arc(ci, c, R, 0.0, TAU, Color(col, 0.28), 1.5)


## Al apagar un aura, su anillo se desdibuja en sentido contrario en 0,2 s.
static func _fx_aura_off(ci: CanvasItem, e: Dictionary, s: float) -> void:
	var left := 1.0 - ramp(s, 0.0, 0.2)
	if left > 0.0:
		var top := -PI / 2.0
		_ell_arc(ci, _snap(e["pos"]), e["radius"], top, top + TAU * left, Color(e["color"], 0.6), 2.0)


## Lo que se ve en cada aliado dentro de un aura de apoyo (`at`, los pies; `r`, su radio;
## `k`, su número, para desfasar): chispas (Overclock), contorno gris (Blindaje), un «+»
## que sube cada segundo (Mantenimiento) o una estrella que brilla (Mando).
static func draw_aura_ally(ci: CanvasItem, id: String, at: Vector2, r: float, k: int, tt: float, col: Color, dim := false) -> void:
	match id:
		"aura_overclock":
			var ph := fposmod(tt * 2.0 + k * 0.37, 1.0)
			if ph < 0.6:
				var q := _snap(at + Vector2(float(k * 5 % 9) - 4.0, -r * 2.0 - 4.0 - 10.0 * ph))
				ci.draw_rect(Rect2(q - Vector2(1, 1), Vector2(2, 2)), Color(PIPE_YELLOW, 1.0 - ph / 0.6))
		"aura_blindaje":
			ci.draw_arc(_snap(at + Vector2(0, -r)), r * 1.1 + 2.0, 0.0, TAU, 16, Color(col, 0.7), 2.0)
		"aura_mantenimiento":
			var ph := fposmod(tt + k * 0.29, 1.0)
			_plus(ci, _snap(at + Vector2(6, -r * 2.0 - 6.0 - 12.0 * ph)), Color(col, 1.0 - ph))
		"aura_mando":
			_star(ci, _snap(at + Vector2(0, -r * 2.0 - 10.0)), Color(col, 0.9), not dim and fposmod(tt * 0.7 + k * 0.41, 1.0) < 0.12)


## Lo que se ve en cada enemigo dentro de un aura hostil (`at`, su posición; `h`, cuánto
## sube su cabeza; `since_in`, segundos desde que entró): Throttling, un reloj de arena y
## «429» al entrar; Exposición, «CVE» fijo y la mira si `aimed`.
static func draw_aura_enemy(ci: CanvasItem, id: String, at: Vector2, h: float, since_in: float, tt: float, col: Color,
		aimed: bool, font: Font, light: bool) -> void:
	var top := _snap(at + Vector2(0, -h))
	match id:
		"aura_throttling":
			_hourglass(ci, top, PI * (int(tt / 0.75) + ramp(fmod(tt, 0.75), 0.6, 0.75)), Color(col.lightened(0.35), 0.9))
			if since_in < 0.6 and not light:
				_label(ci, font, at + Vector2(16, -h + 4.0 - 10.0 * ramp(since_in, 0.0, 0.6)), "429", TEXT_1X,
					Color(col.lightened(0.35), 1.0 - ramp(since_in, 0.45, 0.6)))
		"aura_exposicion":
			if not light:
				_label(ci, font, at + Vector2(16, -h + 4.0), "CVE", TEXT_1X, Color(col, 0.9))
			if aimed:
				var mid := _snap(at + Vector2(0, -h * 0.45))
				var pop := 3.0 * (1.0 - ramp(fmod(tt, 0.5), 0.0, 0.1))
				ci.draw_arc(mid, 5.0 + pop, 0.0, TAU, 12, col, 2.0)
				for d in [Vector2.RIGHT, Vector2.LEFT, Vector2.UP, Vector2.DOWN]:
					ci.draw_line(mid + d * (3.0 + pop), mid + d * (8.0 + pop), col, 2.0)