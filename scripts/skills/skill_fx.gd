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
	"ping_letal": {"projectile": "bolt", "cast": "spark"},
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


## Efecto «firma» para SkillController._effects. `marks`: dónde estaban los enemigos
## golpeados; `ok`/`err`: verde y rojo (los del modo daltónico si está puesto).
static func move_fx(id: String, pos: Vector2, end: Vector2, dir: Vector2, radius: float, color: Color,
		marks := PackedVector2Array(), extra := {}) -> Dictionary:
	var e := {"type": "firma", "firma": id, "pos": pos, "end": end, "dir": dir, "radius": radius, "time": 0.0,
		"duration": float(MOVE_FX.get(id, 0.4)), "color": color, "marks": marks, "seed": randi() % 100000,
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


static func _label(ci: CanvasItem, font: Font, at: Vector2, text: String, size: int, col: Color) -> void:
	ci.draw_string(font, _snap(at) - Vector2(30, 0), text, HORIZONTAL_ALIGNMENT_CENTER, 60, size, col)


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
