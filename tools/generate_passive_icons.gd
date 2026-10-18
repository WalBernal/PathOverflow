extends SceneTree
## Genera assets/sprites/passives/passives.png (iconos de 32×32 para notables y
## piedras angulares) y data/passive_icons.json (id → índice). Pixel art
## procedural; para usar arte propio, sustituye el PNG respetando la cuadrícula.
##
## Uso:  Godot_v4.7.2-stable_win64_console.exe --headless --path . -s res://tools/generate_passive_icons.gd

const S := 32
const COLUMNS := 8
const OUT_PNG := "res://assets/sprites/passives/passives.png"
const OUT_JSON := "res://data/passive_icons.json"
const OUTLINE := Color("0d0b10")

var img: Image
var ox := 0
var oy := 0


func _initialize() -> void:
	var icons := [
		["vida", _heart], ["armadura", _shield], ["fisico", _hammer], ["evasion", _feather],
		["proyectiles", _arrow], ["velocidad_ataque", _stopwatch], ["critico", _crosshair],
		["escudo", _bubble], ["mana", _mana_drop], ["fuego", _flame], ["frio", _snowflake],
		["rayo", _bolt], ["lanzamiento", _spellbook], ["caos", _skull], ["area", _explosion],
		["resistencias", _prism], ["robo_vida", _fangs], ["atributos", _gear],
		["ks_guerrero", _tower], ["ks_duelista", _git_branch], ["ks_exploradora", _bomb],
		["ks_hechicero", _alarm_clock], ["ks_templario", _monitor],
		["versatil", _layers], ["tiempos", _hourglass], ["movilidad", _boot],
		["ks_hacker", _key], ["ks_full_stack", _tower_of_stacks],
	]
	var rows := ceili(float(icons.size()) / COLUMNS)
	img = Image.create_empty(S * COLUMNS, S * rows, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var mapping := {}
	for i in icons.size():
		ox = (i % COLUMNS) * S
		oy = (i / COLUMNS) * S
		icons[i][1].call()
		_outline()
		mapping[icons[i][0]] = i
	img.save_png(ProjectSettings.globalize_path(OUT_PNG))
	var f := FileAccess.open(OUT_JSON, FileAccess.WRITE)
	f.store_string(JSON.stringify({"columns": COLUMNS, "size": S, "icons": mapping}, "\t"))
	f.close()
	print("Escritos %s y %s (%d iconos)" % [OUT_PNG, OUT_JSON, icons.size()])
	quit()


# --- Primitivas ---

func _px(x: int, y: int, c: Color) -> void:
	if x >= 0 and y >= 0 and x < S and y < S and c.a > 0.0:
		img.set_pixel(ox + x, oy + y, c)


func _clear(x: int, y: int) -> void:
	if x >= 0 and y >= 0 and x < S and y < S:
		img.set_pixel(ox + x, oy + y, Color(0, 0, 0, 0))


func _rect(x0: int, y0: int, x1: int, y1: int, c: Color) -> void:
	for y in range(y0, y1 + 1):
		for x in range(x0, x1 + 1):
			_px(x, y, c)


func _ellipse(cx: float, cy: float, rx: float, ry: float, c: Color) -> void:
	for y in range(int(cy - ry) - 1, int(cy + ry) + 2):
		for x in range(int(cx - rx) - 1, int(cx + rx) + 2):
			var dx := (x + 0.5 - cx) / rx
			var dy := (y + 0.5 - cy) / ry
			if dx * dx + dy * dy <= 1.0:
				_px(x, y, c)


func _ring(cx: float, cy: float, r: float, width: float, c: Color) -> void:
	for y in range(int(cy - r) - 1, int(cy + r) + 2):
		for x in range(int(cx - r) - 1, int(cx + r) + 2):
			var d := Vector2(x + 0.5 - cx, y + 0.5 - cy).length()
			if d <= r and d >= r - width:
				_px(x, y, c)


func _line(x0: int, y0: int, x1: int, y1: int, c: Color, width := 1) -> void:
	var steps := maxi(absi(x1 - x0), absi(y1 - y0))
	for i in steps + 1:
		var t := float(i) / maxf(1.0, steps)
		var x := roundi(lerpf(x0, x1, t))
		var y := roundi(lerpf(y0, y1, t))
		for w in width:
			_px(x + w, y, c)
			_px(x, y + w, c)


func _poly(points: Array, c: Color) -> void:
	var pts := PackedVector2Array(points)
	for y in S:
		for x in S:
			if Geometry2D.is_point_in_polygon(Vector2(x + 0.5, y + 0.5), pts):
				_px(x, y, c)


func _outline() -> void:
	var solid := {}
	for y in S:
		for x in S:
			if img.get_pixel(ox + x, oy + y).a >= 0.5:
				solid[Vector2i(x, y)] = true
	for y in S:
		for x in S:
			if solid.has(Vector2i(x, y)):
				continue
			for d in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
				if solid.has(Vector2i(x, y) + d):
					img.set_pixel(ox + x, oy + y, OUTLINE)
					break


# --- Temáticas ---

func _heart() -> void:
	var c := Color("d0303a")
	_ellipse(11, 12, 6.5, 6.5, c)
	_ellipse(21, 12, 6.5, 6.5, c)
	_poly([Vector2(4.5, 14), Vector2(27.5, 14), Vector2(16, 27)], c)
	_ellipse(10, 10, 2, 2, Color("ff9090"))


func _shield() -> void:
	var c := Color("9aa0a8")
	_poly([Vector2(6, 5), Vector2(26, 5), Vector2(26, 15), Vector2(16, 28), Vector2(6, 15)], c)
	_poly([Vector2(16, 5), Vector2(26, 5), Vector2(26, 15), Vector2(16, 28)], c.darkened(0.2))
	for p in [Vector2i(9, 8), Vector2i(23, 8), Vector2i(9, 15), Vector2i(23, 15)]:
		_px(p.x, p.y, Color("e0e4ea"))


func _hammer() -> void:
	_line(8, 27, 19, 12, Color("7a5230"), 2)
	_poly([Vector2(13, 6), Vector2(22, 3), Vector2(29, 12), Vector2(20, 15)], Color("8a8d95"))
	_line(22, 4, 28, 11, Color("c8ccd4"))


func _feather() -> void:
	var c := Color("5cb85c")
	_poly([Vector2(26, 3), Vector2(29, 7), Vector2(12, 24), Vector2(8, 22)], c)
	_poly([Vector2(26, 3), Vector2(22, 4), Vector2(9, 20), Vector2(12, 24)], c.lightened(0.25))
	_line(26, 4, 5, 28, Color("e8f0e0"))


func _arrow() -> void:
	_line(6, 26, 24, 8, Color("8a6d3b"), 2)
	_poly([Vector2(27, 3), Vector2(29, 12), Vector2(20, 6)], Color("c8ccd4"))
	_line(4, 24, 8, 28, Color("e8e8e8"), 2)
	_line(4, 28, 8, 24, Color("e8e8e8"), 2)


func _stopwatch() -> void:
	_ellipse(16, 18, 11, 11, Color("e8d9b0"))
	_ellipse(16, 18, 8.5, 8.5, Color("2a2a30"))
	_rect(14, 3, 18, 6, Color("d9a441"))
	_line(16, 18, 16, 11, Color("ff6a6a"), 1)
	_line(16, 18, 21, 20, Color("e8d9b0"), 1)
	_line(4, 10, 8, 10, Color("d9a441"))
	_line(3, 14, 7, 14, Color("d9a441"))


func _crosshair() -> void:
	_ring(16, 16, 12, 2.5, Color("ff6a6a"))
	_rect(15, 2, 16, 10, Color("ff6a6a"))
	_rect(15, 22, 16, 30, Color("ff6a6a"))
	_rect(2, 15, 10, 16, Color("ff6a6a"))
	_rect(22, 15, 30, 16, Color("ff6a6a"))
	_ellipse(16, 16, 2.5, 2.5, Color("ffe070"))


func _bubble() -> void:
	_ellipse(16, 16, 12, 12, Color("7fb8e0"))
	_ellipse(16, 16, 9.5, 9.5, Color("2a5a8a"))
	_ellipse(12, 12, 3, 2.5, Color("e0f4ff"))
	_px(20, 21, Color("e0f4ff"))


func _mana_drop() -> void:
	var c := Color("3a7bd5")
	_poly([Vector2(16, 3), Vector2(25, 18), Vector2(7, 18)], c)
	_ellipse(16, 20, 9, 8, c)
	_ellipse(13, 19, 2.5, 3.5, Color("a0c8ff"))


func _flame() -> void:
	_poly([Vector2(16, 2), Vector2(26, 18), Vector2(23, 28), Vector2(9, 28), Vector2(6, 18), Vector2(11, 10)], Color("e0652f"))
	_poly([Vector2(17, 10), Vector2(22, 21), Vector2(20, 27), Vector2(12, 27), Vector2(10, 21)], Color("f0a030"))
	_ellipse(16, 23, 3, 4, Color("ffe070"))


func _snowflake() -> void:
	var c := Color("a0d8f0")
	for k in 3:
		var a := PI / 3.0 * k
		var d := Vector2(cos(a), sin(a)) * 12.0
		_line(roundi(16 - d.x), roundi(16 - d.y), roundi(16 + d.x), roundi(16 + d.y), c, 2)
	for k in 6:
		var a := PI / 3.0 * k
		var tip := Vector2(16, 16) + Vector2(cos(a), sin(a)) * 9.0
		_px(roundi(tip.x + cos(a + 1.2) * 3.0), roundi(tip.y + sin(a + 1.2) * 3.0), c)
		_px(roundi(tip.x + cos(a - 1.2) * 3.0), roundi(tip.y + sin(a - 1.2) * 3.0), c)
	_ellipse(16, 16, 2, 2, Color.WHITE)


func _bolt() -> void:
	_poly([Vector2(19, 2), Vector2(8, 18), Vector2(15, 18), Vector2(12, 30), Vector2(25, 12), Vector2(17, 12)], Color("e8d070"))
	_line(18, 4, 11, 16, Color("fff4b0"))


func _spellbook() -> void:
	_poly([Vector2(3, 8), Vector2(16, 11), Vector2(16, 27), Vector2(3, 24)], Color("8a4fc0"))
	_poly([Vector2(29, 8), Vector2(16, 11), Vector2(16, 27), Vector2(29, 24)], Color("b04ad9"))
	for k in 3:
		_line(6, 13 + k * 3, 13, 15 + k * 3, Color("e8d0ff"))
		_line(19, 15 + k * 3, 26, 13 + k * 3, Color("e8d0ff"))
	_ellipse(16, 6, 2, 2, Color("ffe070"))


func _skull() -> void:
	var c := Color("b98ae0")
	_ellipse(16, 13, 10, 9, c)
	_rect(10, 18, 22, 25, c)
	_ellipse(12, 14, 2.5, 3, Color("2a1040"))
	_ellipse(20, 14, 2.5, 3, Color("2a1040"))
	_rect(15, 18, 16, 20, Color("2a1040"))
	for x in [12, 15, 18, 21]:
		_rect(x, 24, x, 26, Color("2a1040"))


func _explosion() -> void:
	var pts: Array = []
	for k in 16:
		var r := 13.0 if k % 2 == 0 else 6.0
		pts.append(Vector2(16, 16) + Vector2.from_angle(TAU * k / 16.0) * r)
	_poly(pts, Color("f0a030"))
	_ellipse(16, 16, 5, 5, Color("ffe070"))


func _prism() -> void:
	_poly([Vector2(16, 3), Vector2(29, 27), Vector2(3, 27)], Color("e0e0ff"))
	_poly([Vector2(16, 9), Vector2(10, 20), Vector2(22, 20)], Color("9a9aff"))
	_line(5, 25, 12, 25, Color("e06c6c"), 2)
	_line(13, 25, 19, 25, Color("7fb8e0"), 2)
	_line(20, 25, 27, 25, Color("e8d070"), 2)


func _fangs() -> void:
	var c := Color("a02040")
	_poly([Vector2(16, 4), Vector2(24, 18), Vector2(8, 18)], c)
	_ellipse(16, 20, 8, 7, c)
	_poly([Vector2(9, 3), Vector2(13, 3), Vector2(11, 11)], Color.WHITE)
	_poly([Vector2(19, 3), Vector2(23, 3), Vector2(21, 11)], Color.WHITE)
	_ellipse(13, 20, 2, 3, Color("e06080"))


func _gear() -> void:
	var c := Color("c0c0c0")
	for k in 8:
		var p := Vector2(16, 16) + Vector2.from_angle(TAU * k / 8.0) * 11.0
		_rect(roundi(p.x) - 2, roundi(p.y) - 2, roundi(p.x) + 2, roundi(p.y) + 2, c)
	_ellipse(16, 16, 10, 10, c)
	_ellipse(16, 16, 4, 4, Color("3a3442"))


# --- Piedras angulares ---

func _tower() -> void:
	var c := Color("8a8478")
	_rect(9, 6, 23, 29, c)
	for x in [9, 13, 17, 21]:
		_rect(x, 3, x + 2, 6, c)
	_rect(14, 22, 18, 29, Color("2a2420"))
	_rect(12, 11, 13, 14, Color("2a2420"))
	_rect(19, 11, 20, 14, Color("2a2420"))
	_line(10, 18, 22, 18, c.darkened(0.3))


func _git_branch() -> void:
	var c := Color("e0652f")
	_line(10, 5, 10, 27, c, 2)
	_line(10, 20, 22, 10, c, 2)
	_ellipse(10, 6, 3.5, 3.5, Color("e8d9b0"))
	_ellipse(10, 26, 3.5, 3.5, Color("e8d9b0"))
	_ellipse(22, 10, 3.5, 3.5, Color("ff4040"))


func _bomb() -> void:
	_ellipse(15, 19, 10, 10, Color("2a2a30"))
	_ellipse(11, 15, 3, 2.5, Color("5a5a66"))
	_rect(19, 7, 22, 10, Color("4a4a52"))
	_line(21, 7, 25, 3, Color("8a6d3b"), 1)
	_ellipse(26, 3, 2, 2, Color("ffcc00"))


func _alarm_clock() -> void:
	_ellipse(16, 18, 11, 11, Color("d0303a"))
	_ellipse(16, 18, 8, 8, Color("f0e8e0"))
	_ellipse(8, 7, 4, 3.5, Color("d0303a"))
	_ellipse(24, 7, 4, 3.5, Color("d0303a"))
	_line(16, 18, 16, 12, Color("2a2a30"))
	_line(16, 18, 20, 18, Color("2a2a30"))
	_line(9, 28, 7, 30, Color("2a2a30"), 2)
	_line(23, 28, 25, 30, Color("2a2a30"), 2)


func _monitor() -> void:
	_rect(4, 5, 28, 22, Color("b8b8b0"))
	_rect(6, 7, 26, 20, Color("10200f"))
	_line(9, 13, 12, 16, Color("3cff6a"), 1)   # check ✓
	_line(12, 16, 18, 10, Color("3cff6a"), 1)
	_rect(14, 22, 18, 25, Color("8a8a80"))
	_rect(10, 26, 22, 27, Color("8a8a80"))


## Versatilidad: capas de una pila (front, back, base de datos).
func _layers() -> void:
	var colors := [Color("c84b4b"), Color("5cb85c"), Color("4b8bd6")]
	for k in 3:
		var y := 7 + k * 7
		_poly([Vector2(16, y), Vector2(28, y + 4), Vector2(16, y + 8), Vector2(4, y + 4)], colors[k])
		_line(4, y + 4, 16, y + 8, colors[k].lightened(0.3))


## Enfriamientos y duración: reloj de arena.
func _hourglass() -> void:
	var glass := Color("6fd3c8")
	_rect(7, 3, 25, 5, Color("8a6d3b"))
	_rect(7, 27, 25, 29, Color("8a6d3b"))
	_poly([Vector2(9, 6), Vector2(23, 6), Vector2(17, 16), Vector2(15, 16)], Color(glass, 0.6))
	_poly([Vector2(15, 16), Vector2(17, 16), Vector2(23, 26), Vector2(9, 26)], Color(glass, 0.6))
	_poly([Vector2(12, 22), Vector2(20, 22), Vector2(22, 26), Vector2(10, 26)], Color("e8d070"))
	_line(16, 14, 16, 22, Color("e8d070"))


## Movilidad: bota con alas.
func _boot() -> void:
	var leather := Color("9ad06a").darkened(0.4)
	_rect(10, 6, 17, 22, leather)
	_rect(10, 20, 26, 26, leather)
	_rect(10, 26, 26, 27, Color("2a2a30"))
	_line(4, 10, 10, 13, Color("e8e8e8"), 2)
	_line(3, 14, 10, 16, Color("e8e8e8"), 2)
	_line(5, 18, 10, 19, Color("e8e8e8"), 2)


## Root Sin Contraseña: llave.
func _key() -> void:
	var gold := Color("e0b040")
	_ring(10, 12, 6.5, 3.0, gold)
	_line(15, 16, 27, 27, gold, 2)
	_line(22, 22, 25, 19, gold, 2)
	_line(25, 25, 28, 22, gold, 2)


## Hola Mundo en 40 Lenguajes: torre de llaves {} de colores.
func _tower_of_stacks() -> void:
	for k in 5:
		var c := Color.from_hsv(k / 5.0, 0.6, 0.95)
		_rect(8 + k, 26 - k * 5, 24 - k, 29 - k * 5, c)
		_px(9 + k, 27 - k * 5, Color.WHITE)
