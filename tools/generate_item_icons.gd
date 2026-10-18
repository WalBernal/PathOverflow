extends SceneTree
## Genera assets/sprites/items/items.png (iconos de 32×32) y data/item_icons.json
## (id → índice en el atlas). Pixel art procedural, "arte de programador":
## para usar iconos dibujados a mano, sustituye el PNG manteniendo la cuadrícula.
##
## Uso:  Godot_v4.7.2-stable_win64_console.exe --headless --path . -s res://tools/generate_item_icons.gd

const S := 32
const COLUMNS := 8
const OUT_PNG := "res://assets/sprites/items/items.png"
const OUT_JSON := "res://data/item_icons.json"
const OUTLINE := Color("0d0b10")

const STEEL := Color("b8bcc4")
const IRON := Color("7d8088")
const RUST := Color("b07a4a")
const WOOD := Color("7a5230")
const LEATHER := Color("8a5a32")
const GOLD := Color("d9a441")
const SILK := Color("7a4bb0")

var img: Image
var ox := 0
var oy := 0


func _initialize() -> void:
	var icons := [
		["espada_oxidada", _sword.bind(RUST, 20, WOOD)],
		["espada_bastarda", _sword.bind(STEEL, 25, GOLD)],
		["estoque_del_compilador", _rapier],
		["hacha_de_lenador", _axe.bind(false)],
		["hacha_de_guerra", _axe.bind(true)],
		["maza_de_depuracion", _mace],
		["casco_de_hierro", _helmet],
		["capucha_de_cuero", _hood],
		["diadema_de_seda", _circlet],
		["cota_de_placas", _body.bind(IRON, "plate")],
		["chaleco_de_cuero", _body.bind(LEATHER, "vest")],
		["tunica_de_seda", _body.bind(SILK, "robe")],
		["sudadera_con_capucha", _hoodie],
		["guanteletes_de_hierro", _glove.bind(IRON, false)],
		["guantes_de_cuero", _glove.bind(LEATHER, false)],
		["mitones_sin_dedos", _glove.bind(SILK, true)],
		["botas_de_hierro", _boot.bind(IRON, Color("4a4d55"))],
		["botas_de_cuero", _boot.bind(LEATHER, Color("4a3020"))],
		["zapatillas_de_seda", _boot.bind(SILK, Color("e8e8e8"))],
		["amuleto_de_ambar", _amulet.bind(Color("e09030"))],
		["amuleto_de_jade", _amulet.bind(Color("4caf50"))],
		["amuleto_de_lapislazuli", _amulet.bind(Color("2f5fd0"))],
		["anillo_de_rubi", _ring.bind(GOLD, Color("d0303a"))],
		["anillo_de_zafiro", _ring.bind(GOLD, Color("3060d8"))],
		["anillo_de_topacio", _ring.bind(GOLD, Color("f0d040"))],
		["anillo_de_hierro", _ring.bind(IRON, Color(0, 0, 0, 0))],
		["cinturon_de_cuero", _belt.bind(LEATHER, GOLD)],
		["faja_de_tela", _belt.bind(SILK, Color("c0a0e0"))],
		["motherboard", _motherboard],
		["ram_DDR3", _ram.bind(Color("8a2f2f"))],
		["ram_DDR4", _ram.bind(Color("2f7a3f"))],
		["ram_DDR5", _ram.bind(Color("2f4f9a"))],
		["flask_coffee", _coffee],
		["flask_energy", _energy_drink],
		["unknown", _unknown],
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
	if x < 0 or y < 0 or x >= S or y >= S or c.a <= 0.0:
		return
	img.set_pixel(ox + x, oy + y, c)


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


func _line(x0: int, y0: int, x1: int, y1: int, c: Color, width := 1) -> void:
	var steps := maxi(absi(x1 - x0), absi(y1 - y0))
	for i in steps + 1:
		var t := float(i) / maxf(1.0, steps)
		var x := roundi(lerpf(x0, x1, t))
		var y := roundi(lerpf(y0, y1, t))
		for w in width:
			_px(x + w, y, c)
			_px(x, y - w, c)


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


# --- Armas (en diagonal, empuñadura abajo a la izquierda) ---

func _sword(blade: Color, length: int, guard: Color) -> void:
	var tip := 6 + length
	_line(6, 25, 8, 23, WOOD.darkened(0.2), 2)                    # empuñadura
	_line(4, 20, 11, 27, guard, 2)                                # guarda
	_line(9, 22, tip - 4, 26 - length + 4, blade, 3)              # hoja
	_line(10, 21, tip - 4, 25 - length + 4, blade.lightened(0.3))  # filo
	_px(5, 27, GOLD)


func _rapier() -> void:
	_line(6, 25, 8, 23, WOOD.darkened(0.3), 2)
	_ellipse(9, 22, 3.5, 3.5, GOLD)
	_ellipse(9, 22, 1.5, 1.5, Color("3cff6a"))
	_line(11, 20, 28, 3, Color("a8c8e8"), 1)
	_line(12, 20, 28, 4, Color("e0f0ff"))


func _axe(double: bool) -> void:
	_line(6, 28, 22, 6, WOOD, 2)
	var head := Color("8a8d95") if double else Color("9aa0a8")
	_ellipse(22, 8, 6, 5, head)
	_rect(17, 6, 21, 10, head.darkened(0.15))
	if double:
		_ellipse(13, 15, 5, 4, head)
	_line(26, 4, 27, 11, head.lightened(0.35))


func _mace() -> void:
	_line(6, 28, 17, 14, WOOD, 2)
	_ellipse(20, 11, 6.5, 6.5, Color("6a6d75"))
	for d in [Vector2i(0, -8), Vector2i(8, 0), Vector2i(0, 8), Vector2i(-8, 0), Vector2i(6, -6), Vector2i(-6, 6), Vector2i(6, 6), Vector2i(-6, -6)]:
		_px(20 + d.x, 11 + d.y, STEEL)
	_px(18, 10, Color("ff4040"))  # ojitos de bug
	_px(22, 10, Color("ff4040"))


# --- Armaduras ---

func _helmet() -> void:
	_ellipse(16, 15, 10, 10, IRON)
	_rect(6, 15, 26, 22, IRON)
	_rect(9, 15, 23, 17, Color("1a1a1e"))  # visera
	_line(16, 5, 16, 13, IRON.lightened(0.3))
	_ellipse(12, 10, 2, 2, IRON.lightened(0.4))


func _hood() -> void:
	_ellipse(16, 15, 11, 12, LEATHER)
	_rect(5, 15, 27, 26, LEATHER)
	_ellipse(16, 18, 6, 7, Color("1a120c"))
	_line(16, 3, 16, 8, LEATHER.lightened(0.2))


func _circlet() -> void:
	_ellipse(16, 17, 11, 5, GOLD)
	_ellipse(16, 17, 9, 3, Color(0, 0, 0, 0))
	for y in range(15, 20):
		for x in range(8, 25):
			var dx := (x + 0.5 - 16) / 9.0
			var dy := (y + 0.5 - 17) / 3.0
			if dx * dx + dy * dy <= 1.0:
				img.set_pixel(ox + x, oy + y, Color(0, 0, 0, 0))
	_ellipse(16, 12, 3, 3.5, Color("b04ad9"))
	_px(15, 11, Color("e8b0ff"))


func _body(c: Color, style: String) -> void:
	_rect(7, 7, 25, 27, c)
	_rect(3, 7, 7, 17, c.darkened(0.1))      # hombros/mangas
	_rect(25, 7, 29, 17, c.darkened(0.1))
	_rect(12, 5, 20, 8, Color(0, 0, 0, 0))   # cuello
	for x in range(12, 21):
		for y in range(5, 9):
			img.set_pixel(ox + x, oy + y, Color(0, 0, 0, 0))
	match style:
		"plate":
			_line(16, 9, 16, 26, c.lightened(0.3))
			_ellipse(12, 13, 3, 3, c.lightened(0.25))
			_ellipse(20, 13, 3, 3, c.lightened(0.25))
		"vest":
			_line(16, 9, 16, 27, Color("3a2414"))
			for y in range(11, 26, 4):
				_px(15, y, Color("e0c080"))
				_px(17, y, Color("e0c080"))
		"robe":
			_rect(7, 25, 25, 28, c.darkened(0.2))
			_line(16, 9, 16, 28, GOLD)
			_line(7, 7, 7, 28, GOLD)
			_line(25, 7, 25, 28, GOLD)


func _hoodie() -> void:
	var c := Color("3a3d48")
	_rect(7, 9, 25, 28, c)
	_rect(3, 9, 7, 24, c.darkened(0.1))
	_rect(25, 9, 29, 24, c.darkened(0.1))
	_ellipse(16, 8, 8, 5, c.lightened(0.1))   # capucha
	_ellipse(16, 9, 4, 3, Color("1a1c22"))
	_line(14, 12, 14, 18, Color("d0d0d0"))     # cordones
	_line(18, 12, 18, 18, Color("d0d0d0"))
	_rect(11, 21, 21, 25, c.darkened(0.25))    # bolsillo canguro
	_px(15, 15, Color("3cff6a"))               # logo "</>"
	_px(17, 15, Color("3cff6a"))


func _glove(c: Color, fingerless: bool) -> void:
	_rect(9, 16, 22, 28, c)                    # puño
	_rect(9, 14, 22, 16, c.darkened(0.3))
	for i in 4:
		var x := 9 + i * 3 + (1 if i > 0 else 0)
		var top := 4 + (2 if i == 0 or i == 3 else 0)
		_rect(x, top, x + 2, 14, c if not fingerless else c)
		if fingerless:
			_rect(x, top, x + 2, top + 3, Color("e0ac8a"))
	_rect(22, 10, 25, 18, c)                   # pulgar
	_line(10, 22, 21, 22, c.lightened(0.25))


func _boot(c: Color, sole: Color) -> void:
	_rect(10, 4, 19, 22, c)
	_rect(10, 20, 27, 26, c)
	_rect(9, 26, 28, 28, sole)
	_line(11, 8, 18, 8, c.lightened(0.3))
	_ellipse(25, 23, 3, 3, c.lightened(0.15))


# --- Joyería ---

func _amulet(gem: Color) -> void:
	_line(6, 3, 16, 18, GOLD)
	_line(26, 3, 16, 18, GOLD)
	_ellipse(16, 22, 6, 7, GOLD)
	_ellipse(16, 22, 4, 5, gem)
	_px(14, 19, gem.lightened(0.6))
	_px(15, 20, gem.lightened(0.4))


func _ring(band: Color, gem: Color) -> void:
	_ellipse(16, 20, 10, 9, band)
	for y in range(13, 28):
		for x in range(9, 24):
			var dx := (x + 0.5 - 16) / 6.5
			var dy := (y + 0.5 - 20) / 5.5
			if dx * dx + dy * dy <= 1.0:
				img.set_pixel(ox + x, oy + y, Color(0, 0, 0, 0))
	_px(10, 17, band.lightened(0.4))
	if gem.a > 0.0:
		_ellipse(16, 10, 5, 5, gem)
		_px(14, 8, gem.lightened(0.6))


func _belt(c: Color, buckle: Color) -> void:
	_rect(2, 13, 29, 19, c)
	_line(2, 14, 29, 14, c.lightened(0.2))
	_rect(12, 11, 20, 21, buckle)
	_rect(14, 13, 18, 19, c.darkened(0.3))
	for x in range(23, 29, 3):
		_px(x, 16, c.darkened(0.5))


# --- Hardware ---

func _motherboard() -> void:
	var pcb := Color("1f6b3a")
	_rect(3, 4, 28, 27, pcb)
	_rect(6, 7, 14, 15, Color("2a2a2e"))       # CPU
	_rect(8, 9, 12, 13, Color("8a8d95"))
	for i in 4:                                 # ranuras DIMM
		_rect(17 + i * 3, 6, 18 + i * 3, 25, Color("101012"))
		_px(17 + i * 3, 6, GOLD)
	_rect(6, 19, 13, 24, Color("2a2a2e"))       # chipset
	for i in 6:
		_line(4 + i * 2, 27, 4 + i * 2, 25, GOLD)
	_line(14, 11, 17, 11, Color("d9c070"))
	_line(13, 21, 17, 21, Color("d9c070"))


func _ram(pcb: Color) -> void:
	_rect(2, 10, 29, 22, pcb)
	for i in 4:
		_rect(4 + i * 6, 12, 8 + i * 6, 18, Color("1a1a1e"))
	for x in range(3, 29, 2):
		_px(x, 22, GOLD)
	_px(15, 22, Color(0, 0, 0, 0))
	_rect(15, 21, 16, 22, Color(0, 0, 0, 0))    # muesca
	img.set_pixel(ox + 15, oy + 22, Color(0, 0, 0, 0))
	img.set_pixel(ox + 16, oy + 22, Color(0, 0, 0, 0))
	_line(3, 10, 28, 10, pcb.lightened(0.3))


# --- Pociones ---

func _coffee() -> void:
	var mug := Color("ece4d8")
	_rect(7, 10, 22, 27, mug)
	_rect(8, 27, 21, 28, mug.darkened(0.2))
	_ellipse(14.5, 10, 7.5, 2.5, Color("5a3418"))  # café
	_ellipse(13, 9.5, 2, 0.8, Color("8a5a32"))
	for y in range(13, 23):                         # asa
		_px(23, y, mug)
		_px(26, y, mug)
	_rect(23, 13, 26, 14, mug)
	_rect(23, 21, 26, 22, mug)
	_line(10, 18, 12, 16, Color("2f6bd0"))          # "</>"
	_line(10, 18, 12, 20, Color("2f6bd0"))
	_line(17, 16, 19, 18, Color("2f6bd0"))
	_line(17, 20, 19, 18, Color("2f6bd0"))
	_line(13, 21, 16, 15, Color("2f6bd0"))


func _energy_drink() -> void:
	var can := Color("1c3a8a")
	_rect(10, 5, 21, 28, can)
	_rect(11, 3, 20, 5, Color("c0c4cc"))
	_rect(11, 28, 20, 29, Color("c0c4cc"))
	_line(10, 6, 10, 27, can.lightened(0.3))
	var bolt := Color("f0e040")
	_line(17, 8, 13, 16, bolt, 2)
	_line(13, 16, 18, 16, bolt, 2)
	_line(18, 16, 14, 25, bolt, 2)


func _unknown() -> void:
	_rect(8, 6, 23, 26, Color("4a4352"))
	_line(13, 11, 18, 11, Color.WHITE)
	_line(18, 11, 18, 15, Color.WHITE)
	_line(18, 15, 15, 17, Color.WHITE)
	_px(15, 21, Color.WHITE)
