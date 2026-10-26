extends SceneTree
## Genera assets/sprites/ui/ui_atlas.png: las piezas de interfaz de UiAtlas (marcos
## de ventana, botones, casillas por rareza, barras, pestañas, separador, placa de
## la barra de habilidades, aro de orbe...). Pixel art procedural a 24×24 píxeles de
## arte por celda, escalado ×2. Para arte propio, sustituye el PNG con la misma cuadrícula.
##
## Uso:  Godot_v4.7.2-stable_win64_console.exe --headless --path . -s res://tools/generate_ui_atlas.gd

const A := 24   # píxeles de arte por celda
const M := 6    # margen de 9 partes en píxeles de arte (UiAtlas.MARGIN / 2)
const OUT := "res://assets/sprites/ui/ui_atlas.png"

const INK := Color("07060a")
const GOLD := Color("b08a4a")
const GOLD_LIGHT := Color("e0c07a")
const GOLD_DARK := Color("5a4426")
const BRONZE := Color("3a2c1c")
const PANEL := Color("16131b")
const PANEL_LIGHT := Color("221e29")
const WINDOW_BG := Color("120f17")
const BORDER := Color("3d3547")

var img: Image
var ox := 0
var oy := 0


func _initialize() -> void:
	img = Image.create_empty(A * UiAtlas.COLUMNS, A * UiAtlas.ROWS, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var painters := {
		"window": _window, "panel": _panel, "inset": _inset, "tooltip": _tooltip,
		"button_normal": _button.bind(PANEL_LIGHT, BORDER, false), "button_hover": _button.bind(Color("2e2836"), GOLD, false),
		"button_pressed": _button.bind(Color("3a2f22"), GOLD_LIGHT, true), "button_disabled": _button.bind(PANEL, Color("2a2530"), false),
		"slot_normal": _slot.bind(Color("8a8a8a")), "slot_magic": _slot.bind(Color("6f7fe0")),
		"slot_rare": _slot.bind(Color("e0d060")), "slot_unique": _slot.bind(Color("c07030")),
		"bar_frame": _bar_frame, "tab_active": _tab.bind(true), "tab_inactive": _tab.bind(false), "separator": _separator,
		"hotbar_plate": _hotbar_plate, "flask_frame": _flask_frame, "line_edit": _line_edit,
	}
	for piece in UiAtlas.PIECES:
		var cell: Vector2i = UiAtlas.PIECES[piece]
		ox = cell.x * A
		oy = cell.y * A
		painters[piece].call()
	img.resize(img.get_width() * 2, img.get_height() * 2, Image.INTERPOLATE_NEAREST)
	# Piezas grandes, a resolución final debajo de la cuadrícula.
	var full := Image.create_empty(img.get_width(), img.get_height() + UiAtlas.BIG_ROWS * UiAtlas.CELL, false, Image.FORMAT_RGBA8)
	full.fill(Color(0, 0, 0, 0))
	full.blit_rect(img, Rect2i(Vector2i.ZERO, img.get_size()), Vector2i.ZERO)
	img = full
	_orb_frame(UiAtlas.BIG_PIECES["orb_frame"])
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT.get_base_dir()))
	img.save_png(OUT)
	print("atlas de interfaz: %s (%d piezas)" % [OUT, UiAtlas.PIECES.size()])
	quit()


func _px(x: int, y: int, c: Color) -> void:
	if x >= 0 and y >= 0 and x < A and y < A:
		img.set_pixel(ox + x, oy + y, c)


func _rect(x: int, y: int, w: int, h: int, c: Color) -> void:
	for yy in h:
		for xx in w:
			_px(x + xx, y + yy, c)


## Borde de 1 px alrededor del rectángulo (x, y, w, h).
func _outline(x: int, y: int, w: int, h: int, c: Color) -> void:
	_rect(x, y, w, 1, c)
	_rect(x, y + h - 1, w, 1, c)
	_rect(x, y, 1, h, c)
	_rect(x + w - 1, y, 1, h, c)


## Marco básico: tinta fuera, borde de color con luz arriba y sombra abajo, fondo dentro.
func _frame(bg: Color, border: Color, width := 1) -> void:
	_rect(1, 1, A - 2, A - 2, bg)
	_outline(0, 0, A, A, INK)
	for k in width:
		_outline(1 + k, 1 + k, A - 2 - 2 * k, A - 2 - 2 * k, border)
	_rect(2, 1, A - 4, 1, border.lightened(0.3))
	_rect(2, A - 2, A - 4, 1, border.darkened(0.35))
	_px(1, 1, INK)
	_px(A - 2, 1, INK)
	_px(1, A - 2, INK)
	_px(A - 2, A - 2, INK)


## Cantonera dorada en las cuatro esquinas: escuadra con un remache.
func _corners(c: Color) -> void:
	for corner in [Vector2i(0, 0), Vector2i(1, 0), Vector2i(0, 1), Vector2i(1, 1)]:
		var sx := 1 if corner.x == 0 else -1
		var sy := 1 if corner.y == 0 else -1
		var bx := 1 if corner.x == 0 else A - 2
		var by := 1 if corner.y == 0 else A - 2
		for k in 5:
			_px(bx + sx * k, by, c)
			_px(bx, by + sy * k, c)
		_px(bx + sx * 2, by + sy * 2, GOLD_LIGHT)
		_px(bx + sx * 3, by + sy * 2, c.darkened(0.3))
		_px(bx + sx * 2, by + sy * 3, c.darkened(0.3))


func _window() -> void:
	_frame(WINDOW_BG, GOLD_DARK, 2)
	_outline(4, 4, A - 8, A - 8, Color(GOLD, 0.35))
	_corners(GOLD)


func _panel() -> void:
	_frame(PANEL, BORDER)
	_px(3, 3, BORDER.lightened(0.2))
	_px(A - 4, 3, BORDER.lightened(0.2))


func _inset() -> void:
	_rect(1, 1, A - 2, A - 2, Color("1a1620"))
	_outline(0, 0, A, A, Color("2e2836"))
	_rect(1, 1, A - 2, 1, Color("0d0b10"))   # sombra interior arriba
	_rect(1, 1, 1, A - 2, Color("110e15"))


func _tooltip() -> void:
	_rect(1, 1, A - 2, A - 2, Color(0.05, 0.04, 0.06, 0.96))
	_outline(0, 0, A, A, GOLD_DARK)
	_outline(1, 1, A - 2, A - 2, Color(GOLD, 0.25))
	for p in [Vector2i(0, 0), Vector2i(A - 1, 0), Vector2i(0, A - 1), Vector2i(A - 1, A - 1)]:
		_px(p.x, p.y, GOLD)


## Botón como una tecla: luz arriba, borde inferior grueso; pulsado, al revés.
func _button(bg: Color, border: Color, pressed: bool) -> void:
	_rect(1, 1, A - 2, A - 2, bg)
	_outline(0, 0, A, A, INK)
	_outline(1, 1, A - 2, A - 2, border)
	if pressed:
		_rect(2, 2, A - 4, 2, bg.darkened(0.45))
		_rect(2, A - 3, A - 4, 1, bg.lightened(0.12))
	else:
		_rect(2, 2, A - 4, 1, bg.lightened(0.25))
		_rect(2, A - 4, A - 4, 2, bg.darkened(0.5))
	_px(1, 1, INK)
	_px(A - 2, 1, INK)
	_px(1, A - 2, INK)
	_px(A - 2, A - 2, INK)


## Casilla de objeto: hundida, con el borde del color de la rareza y brillo en las esquinas.
func _slot(rarity: Color) -> void:
	_rect(1, 1, A - 2, A - 2, Color("0f0c13"))
	_outline(0, 0, A, A, INK)
	_outline(1, 1, A - 2, A - 2, rarity.darkened(0.35))
	_rect(2, 2, A - 4, 1, Color("08060a"))
	for p in [Vector2i(1, 1), Vector2i(A - 2, 1), Vector2i(1, A - 2), Vector2i(A - 2, A - 2)]:
		_px(p.x, p.y, rarity.lightened(0.1))


func _bar_frame() -> void:
	_rect(1, 1, A - 2, A - 2, Color("0a080c"))
	_outline(0, 0, A, A, INK)
	_outline(1, 1, A - 2, A - 2, GOLD_DARK)
	_rect(2, 1, A - 4, 1, GOLD.darkened(0.2))


## Pestaña: la activa, del color del panel con borde dorado arriba; la otra, más oscura.
func _tab(active: bool) -> void:
	var bg := PANEL_LIGHT if active else Color("100d14")
	_rect(1, 1, A - 2, A - 1, bg)
	_rect(0, 1, 1, A - 1, INK)
	_rect(A - 1, 1, 1, A - 1, INK)
	_rect(1, 0, A - 2, 1, INK)
	_rect(1, 1, A - 2, 2 if active else 1, GOLD if active else BORDER)
	if not active:
		_rect(0, A - 1, A, 1, BORDER)


func _separator() -> void:
	var y := A / 2
	_rect(0, y, A, 1, Color(GOLD, 0.6))
	_rect(0, y + 1, A, 1, Color(0, 0, 0, 0.5))
	var mid := A / 2
	for k in 4:
		_rect(mid - k, y - 3 + k, 1 + 2 * k, 1, GOLD)
		_rect(mid - k, y + 3 - k, 1 + 2 * k, 1, GOLD)
	_px(mid, y - 2, GOLD_LIGHT)


## Placa de la barra de habilidades: bronce con borde dorado grueso y remaches.
func _hotbar_plate() -> void:
	_frame(BRONZE, GOLD_DARK, 2)
	_rect(3, 3, A - 6, 1, BRONZE.lightened(0.15))
	for p in [Vector2i(3, 3), Vector2i(A - 4, 3), Vector2i(3, A - 4), Vector2i(A - 4, A - 4)]:
		_px(p.x, p.y, GOLD_LIGHT)
		_px(p.x + 1, p.y + 1, INK)
	_corners(GOLD)


## Aro de orbe (pieza grande, a resolución final): anillo de metal dorado con luz arriba,
## filo de tinta por dentro y por fuera y cuatro tachuelas; el centro, transparente.
func _orb_frame(area: Rect2) -> void:
	var half := area.size.x / 2.0
	var c := area.position + Vector2(half - 0.5, half - 0.5)
	var inner := half * UiAtlas.ORB_INNER
	for y in int(area.size.y):
		for x in int(area.size.x):
			var p := area.position + Vector2(x, y)
			var d := p.distance_to(c)
			var col := Color(0, 0, 0, 0)
			if d >= half - 0.5 or d < inner:
				continue   # fuera del aro o en el hueco del orbe
			elif d >= half - 2.0 or d < inner + 1.0:
				col = INK
			else:
				# Bisel: más claro arriba a la izquierda, más oscuro abajo; bandas de 2 px (pixel art).
				var light := -((p - c).normalized().dot(Vector2(-0.6, -0.8)))
				var band := int((d - inner) / 2.0) % 2
				col = GOLD.lerp(GOLD_LIGHT, clampf(-light, 0.0, 1.0) * 0.7).lerp(GOLD_DARK, clampf(light, 0.0, 1.0) * 0.8)
				if band == 1:
					col = col.darkened(0.12)
			if col.a > 0.0:
				img.set_pixelv(Vector2i(p), col)
	for k in 4:
		var dir := Vector2.from_angle(-PI / 2.0 + TAU * k / 4.0)
		var stud := c + dir * (inner + (half - inner) / 2.0)
		for yy in range(-3, 4):
			for xx in range(-3, 4):
				var q := Vector2(xx, yy)
				if q.length() <= 3.2:
					img.set_pixelv(Vector2i(stud + q), INK if q.length() > 2.2 else (GOLD_LIGHT if q.y < 0 else GOLD))


func _flask_frame() -> void:
	_frame(Color("0d0a10"), BRONZE.lightened(0.3))
	_rect(2, A - 3, A - 4, 1, GOLD_DARK)


func _line_edit() -> void:
	_rect(1, 1, A - 2, A - 2, Color("0a080c"))
	_outline(0, 0, A, A, BORDER)
	_rect(1, 1, A - 2, 1, INK)
