extends SceneTree
## Genera assets/sprites/ui/ui_atlas.png: las piezas de interfaz de UiAtlas (marcos
## de ventana, botones, casillas por rareza, barras, pestañas, separador, placa de
## la barra de habilidades, aro de orbe...). Dibujadas a resolución final con
## degradados y bordes suavizados (no pixel art), para ir hacia un acabado más pulido.
## Para arte propio, sustituye el PNG con la misma cuadrícula.
##
## Uso:  Godot_v4.7.2-stable_win64_console.exe --headless --path . -s res://tools/generate_ui_atlas.gd

const C := UiAtlas.CELL   # píxeles por celda
const OUT := "res://assets/sprites/ui/ui_atlas.png"

const INK := Color("050407")
const GOLD := Color("b8924e")
const GOLD_LIGHT := Color("ecd08e")
const GOLD_DARK := Color("4e3a20")
const BRONZE := Color("3b2d1e")
const BRONZE_DARK := Color("1c150e")
const BORDER := Color("443b50")

var img: Image
var ox := 0
var oy := 0


func _initialize() -> void:
	img = Image.create_empty(C * UiAtlas.COLUMNS, C * (UiAtlas.ROWS + UiAtlas.BIG_ROWS), false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var painters := {
		"window": _window, "panel": _panel, "inset": _inset, "tooltip": _tooltip,
		"button_normal": _button.bind(Color("2a2531"), Color("1a1720"), BORDER, false),
		"button_hover": _button.bind(Color("3a3243"), Color("241f2b"), GOLD, false),
		"button_pressed": _button.bind(Color("1d1912"), Color("33291b"), GOLD_LIGHT, true),
		"button_disabled": _button.bind(Color("19161d"), Color("141117"), Color("2c2733"), false),
		"slot_normal": _slot.bind(Color("77727f")), "slot_magic": _slot.bind(Color("6f82ee")),
		"slot_rare": _slot.bind(Color("e6d265")), "slot_unique": _slot.bind(Color("d0803a")),
		"bar_frame": _bar_frame, "tab_active": _tab.bind(true), "tab_inactive": _tab.bind(false), "separator": _separator,
		"hotbar_plate": _hotbar_plate, "flask_frame": _flask_frame, "line_edit": _line_edit,
	}
	for piece in UiAtlas.PIECES:
		var cell: Vector2i = UiAtlas.PIECES[piece]
		ox = cell.x * C
		oy = cell.y * C
		painters[piece].call()
	_orb_frame(UiAtlas.BIG_PIECES["orb_frame"])
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT.get_base_dir()))
	img.save_png(OUT)
	print("atlas de interfaz: %s (%d piezas)" % [OUT, UiAtlas.PIECES.size() + UiAtlas.BIG_PIECES.size()])
	quit()


## Mezcla `col` (con su alfa por `cover`) encima del píxel (x, y) de la celda.
func _blend(x: int, y: int, col: Color, cover: float) -> void:
	if cover <= 0.0 or x < 0 or y < 0 or x >= C or y >= C:
		return
	var c := Color(col, col.a * clampf(cover, 0.0, 1.0))
	img.set_pixel(ox + x, oy + y, img.get_pixel(ox + x, oy + y).blend(c))


## Distancia con signo a un rectángulo redondeado (negativa dentro).
static func _sd(p: Vector2, rect: Rect2, radius: float) -> float:
	var half := rect.size / 2.0
	var q := (p - rect.get_center()).abs() - (half - Vector2(radius, radius))
	return Vector2(maxf(q.x, 0.0), maxf(q.y, 0.0)).length() + minf(maxf(q.x, q.y), 0.0) - radius


## Caja redondeada con borde: relleno en degradado vertical (arriba → abajo), borde
## que pasa de claro arriba a oscuro abajo, filo de tinta por fuera y un brillo
## interior arriba. Bordes suavizados por cobertura.
func _box(rect: Rect2, radius: float, fill_top: Color, fill_bottom: Color, border_w: float,
		border_top: Color, border_bottom: Color, ink := true, gloss := 0.06) -> void:
	for y in C:
		for x in C:
			var p := Vector2(x + 0.5, y + 0.5)
			var d := _sd(p, rect, radius)
			if d > 1.0:
				continue
			var t := clampf((p.y - rect.position.y) / maxf(1.0, rect.size.y), 0.0, 1.0)
			var outer := clampf(0.5 - d, 0.0, 1.0)
			if ink:
				_blend(x, y, INK, outer)
			var inner_rect := rect.grow(-1.0) if ink else rect
			var di := _sd(p, inner_rect, maxf(0.0, radius - 1.0))
			var cover := clampf(0.5 - di, 0.0, 1.0)
			if cover <= 0.0:
				continue
			# Borde: entre el filo y border_w hacia dentro.
			var b := clampf(0.5 - (-di - border_w), 0.0, 1.0)
			var fill := fill_top.lerp(fill_bottom, t)
			var edge := border_top.lerp(border_bottom, t)
			_blend(x, y, fill.lerp(edge, b), cover)
			# Brillo interior: una línea tenue justo dentro del borde, más fuerte arriba.
			var g := clampf(1.0 - absf(-di - border_w - 0.8), 0.0, 1.0) * (1.0 - t)
			if gloss > 0.0 and g > 0.0:
				_blend(x, y, Color(1, 1, 1, gloss * 3.0), g)


func _cell() -> Rect2:
	return Rect2(0, 0, C, C)


func _window() -> void:
	_box(_cell(), 7.0, Color("1a1620"), Color("0e0c12"), 3.0, GOLD_LIGHT.darkened(0.15), GOLD_DARK, true, 0.05)
	# Filete interior dorado, fino y translúcido.
	for y in C:
		for x in C:
			var d := _sd(Vector2(x + 0.5, y + 0.5), _cell().grow(-8.0), 3.0)
			_blend(x, y, Color(GOLD, 0.28), clampf(1.0 - absf(d), 0.0, 1.0))


func _panel() -> void:
	_box(_cell(), 6.0, Color("1c1922"), Color("121016"), 1.5, BORDER.lightened(0.25), BORDER.darkened(0.3))


func _inset() -> void:
	_box(_cell(), 4.0, Color("100d14"), Color("1b1822"), 1.0, Color("2a2533"), Color("332d3d"), false, 0.0)


func _tooltip() -> void:
	_box(_cell(), 5.0, Color(0.07, 0.06, 0.09, 0.97), Color(0.04, 0.035, 0.05, 0.97), 1.5, GOLD.darkened(0.2), GOLD_DARK, true, 0.04)


## Botón: degradado suave, borde con luz arriba; pulsado, el degradado al revés.
func _button(top: Color, bottom: Color, border: Color, pressed: bool) -> void:
	_box(_cell(), 5.0, top, bottom, 1.5, border.lightened(0.15) if not pressed else border.darkened(0.2), border.darkened(0.35) if not pressed else border,
		true, 0.0 if pressed else 0.07)


## Casilla de objeto: hundida (más oscura arriba), borde del color de la rareza y un
## resplandor tenue de ese color por dentro.
func _slot(rarity: Color) -> void:
	_box(_cell(), 3.0, Color("09080c"), Color("15121a"), 1.5, rarity.darkened(0.15), rarity.darkened(0.5), true, 0.0)
	for y in C:
		for x in C:
			var d := -_sd(Vector2(x + 0.5, y + 0.5), _cell().grow(-2.5), 2.0)
			if d > 0.0:
				_blend(x, y, Color(rarity, 0.16), clampf(1.0 - d / 6.0, 0.0, 1.0))


func _bar_frame() -> void:
	_box(_cell(), 4.0, Color("060508"), Color("0e0c11"), 2.0, GOLD.darkened(0.1), GOLD_DARK, true, 0.0)


## Pestaña: esquinas redondeadas solo arriba (la caja sigue por debajo de la celda).
func _tab(active: bool) -> void:
	var rect := Rect2(0, 0, C, C + 10)
	if active:
		_box(rect, 6.0, Color("2a2531"), Color("1c1922"), 1.5, GOLD_LIGHT.darkened(0.1), GOLD.darkened(0.3), true, 0.07)
	else:
		_box(rect, 6.0, Color("17141b"), Color("110f14"), 1.5, BORDER, BORDER.darkened(0.3), true, 0.03)


## Separador: línea dorada que se desvanece hacia los lados.
func _separator() -> void:
	var y := C / 2
	for x in C:
		var fade := 1.0 - absf(x - C / 2.0) / (C / 2.0) * 0.6
		_blend(x, y, Color(GOLD, 0.7 * fade), 1.0)
		_blend(x, y + 1, Color(0, 0, 0, 0.5 * fade), 1.0)


## Placa de la barra de habilidades: metal de bronce con un veteado horizontal muy
## suave, borde dorado y brillo arriba.
func _hotbar_plate() -> void:
	_box(_cell(), 8.0, BRONZE.lightened(0.08), BRONZE_DARK, 3.0, GOLD_LIGHT.darkened(0.1), GOLD_DARK, true, 0.08)
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	for y in range(5, C - 5):
		var streak := rng.randf_range(-0.035, 0.035)
		for x in range(5, C - 5):
			_blend(x, y, Color(1, 1, 1, absf(streak)) if streak > 0.0 else Color(0, 0, 0, -streak), 1.0)


func _flask_frame() -> void:
	_box(_cell(), 5.0, Color("0c0a0f"), Color("141118"), 2.0, GOLD.darkened(0.25), BRONZE.lightened(0.1), true, 0.0)


func _line_edit() -> void:
	_box(_cell(), 4.0, Color("08070a"), Color("110f14"), 1.0, BORDER.darkened(0.1), BORDER.lightened(0.1), false, 0.0)


## Aro de orbe (pieza grande): anillo de metal dorado con bisel suave (luz arriba a la
## izquierda), filos oscuros por dentro y por fuera y cuatro gemas; centro transparente.
func _orb_frame(area: Rect2) -> void:
	var half := area.size.x / 2.0
	var c := area.get_center()
	var inner := half * UiAtlas.ORB_INNER
	var mid := (inner + half) / 2.0
	var width := half - inner
	for y in int(area.size.y):
		for x in int(area.size.x):
			var p := area.position + Vector2(x + 0.5, y + 0.5)
			var d := p.distance_to(c)
			var cover := clampf(half - 0.5 - d, 0.0, 1.0) * clampf(d - inner + 0.5, 0.0, 1.0)
			if cover <= 0.0:
				continue
			var n := (p - c) / maxf(d, 0.001)
			var light := n.dot(Vector2(-0.6, -0.8))   # 1 = arriba a la izquierda
			var across := (d - mid) / (width / 2.0)    # -1 dentro, 1 fuera
			var bevel := 1.0 - across * across          # más claro en el centro del aro
			var col := GOLD_DARK.lerp(GOLD, 0.35 + 0.65 * bevel).lerp(GOLD_LIGHT, clampf(light, 0.0, 1.0) * bevel * 0.6)
			col = col.darkened(clampf(-light, 0.0, 1.0) * 0.35)
			var rim := maxf(clampf(1.4 - (half - d), 0.0, 1.0), clampf(1.4 - (d - inner), 0.0, 1.0))
			col = col.lerp(INK, rim * 0.9)
			var px := Vector2i(p)
			img.set_pixelv(px, img.get_pixelv(px).blend(Color(col, cover)))
	for k in 4:
		var stud := c + Vector2.from_angle(-PI / 2.0 + TAU * k / 4.0) * mid
		for yy in range(-6, 7):
			for xx in range(-6, 7):
				var q := Vector2(xx + 0.5, yy + 0.5)
				var r := q.length()
				var cover := clampf(4.6 - r, 0.0, 1.0)
				if cover <= 0.0:
					continue
				var col := INK if r > 3.6 else GOLD_LIGHT.lerp(GOLD_DARK, clampf((q.y + 3.0) / 6.0, 0.0, 1.0))
				var px := Vector2i(stud + q)
				img.set_pixelv(px, img.get_pixelv(px).blend(Color(col, cover)))
