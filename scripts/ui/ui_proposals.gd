class_name UiProposals
extends Control
## T165: las dos propuestas de interfaz de ingeniería, dibujadas como maqueta (inventario,
## descripción de un objeto, diálogo y HUD) para que el usuario elija o mezcle. No cambia la
## interfaz del juego: la elegida pasa a UiStyle en T166. Guía: docs/estilo_visual.md.
## Los colores de rareza, de daño y del modo daltónico son los del juego (no cambian).

const PALETTES := {
	"a": {"name": "A · Terminal/IDE", "bg": "0b1020", "panel": "111a2e", "panel2": "17223b", "border": "26345a",
		"accent": "3ad1e6", "ok": "7ee787", "ai": "c678dd", "warn": "e3b341", "danger": "ff7b72",
		"text": "dfe7f5", "muted": "8592b0"},
	"b": {"name": "B · Panel de monitoreo/datos", "bg": "0e1116", "panel": "161b22", "panel2": "1d2430", "border": "2d3646",
		"accent": "2dd4bf", "ok": "3fb950", "ai": "a371f7", "warn": "f59e0b", "danger": "f85149",
		"text": "e6edf3", "muted": "8b949e"},
}
## Rarezas del juego (Rarity): normal, mágico, raro, único, ultra-raro.
const RARE := {"normal": "c8c8c8", "magic": "8888ff", "rare": "ffff77", "unique": "af6025", "ultra": "ff5ac8"}
const ITEMS := [["Teclado mecánico de la Pila", "rare", "arma"], ["Capucha de cuero", "magic", "casco"],
	["Cota de placas", "normal", "cuerpo"], ["Botas de seguridad", "magic", "botas"],
	["Sable de fibra óptica", "unique", "bolsa"], ["Navaja multiherramienta", "ultra", "bolsa"]]
const AFFIXES := [["+38 % de daño físico", "magic"], ["+12 % de velocidad de ataque", "magic"], ["+54 de vida", "magic"],
	["+18 % de resistencia al rayo", "magic"]]
const DIALOGUE := "¿Otra vez tú? Bien. El servidor no se depura solo. Tómate un café y luego baja a los racks: algo se está comiendo la memoria."
const OPTIONS := ["¿Qué hay en los racks?", "Dame ese café.", "Adiós."]
const LOG := [["INFO", "Recogiste: Botas de seguridad"], ["WARN", "Memoria al 18 %"], ["OK", "Zona limpia: 14/14"], ["INFO", "Aida quiere hablar contigo"]]

var variant := "a":
	set(value):
		variant = value
		queue_redraw()

var _mono: SystemFont
var _sans: Font


func _ready() -> void:
	_mono = SystemFont.new()
	_mono.font_names = PackedStringArray(["Cascadia Mono", "Consolas", "DejaVu Sans Mono", "monospace"])
	_sans = ThemeDB.fallback_font


static func color(v: String, key: String) -> Color:
	return Color(PALETTES[v][key])


## Contraste WCAG entre dos colores (para la prueba de legibilidad).
static func contrast(a: Color, b: Color) -> float:
	var la := _luminance(a)
	var lb := _luminance(b)
	return (maxf(la, lb) + 0.05) / (minf(la, lb) + 0.05)


static func _luminance(c: Color) -> float:
	var f := func(x: float) -> float: return x / 12.92 if x <= 0.03928 else pow((x + 0.055) / 1.055, 2.4)
	return 0.2126 * f.call(c.r) + 0.7152 * f.call(c.g) + 0.0722 * f.call(c.b)


func _c(key: String) -> Color:
	return color(variant, key)


func _txt(pos: Vector2, s: String, size := 15, col := Color.WHITE, mono := true, width := -1.0) -> void:
	draw_string(_mono if mono else _sans, pos, s, HORIZONTAL_ALIGNMENT_LEFT, width, size, col)


func _box(r: Rect2, fill: Color, border := Color(0, 0, 0, 0), radius := 0, bw := 1) -> void:
	var sb := StyleBoxFlat.new()
	sb.bg_color = fill
	sb.set_corner_radius_all(radius)
	if border.a > 0.0:
		sb.border_color = border
		sb.set_border_width_all(bw)
	draw_style_box(sb, r)


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), _c("bg"))
	if variant == "a":
		_txt(Vector2(40, 30), "// propuesta " + String(PALETTES[variant]["name"]), 14, _c("muted"))
		_inventory_a(Rect2(40, 44, 740, 520))
		_tooltip_a(Rect2(800, 44, 380, 290))
		_minimap_a(Rect2(1200, 44, 360, 290))
		_dialogue_a(Rect2(800, 350, 760, 214))
		_hud_a(Rect2(40, 586, 1520, 290))
	else:
		for y in range(0, int(size.y), 24):   # rejilla de puntos
			for x in range(0, int(size.x), 24):
				draw_circle(Vector2(x, y), 1.0, Color(_c("border"), 0.7))
		_txt(Vector2(40, 30), String(PALETTES[variant]["name"]), 15, _c("muted"), false)
		_inventory_b(Rect2(40, 44, 740, 520))
		_tooltip_b(Rect2(800, 44, 380, 290))
		_minimap_b(Rect2(1200, 44, 360, 290))
		_dialogue_b(Rect2(800, 350, 760, 214))
		_hud_b(Rect2(40, 586, 1520, 290))


# --- A · Terminal/IDE -------------------------------------------------------------------

## Ventana tipo editor: pestañas arriba («nombre ×»), los tres puntos y el contenido.
func _window_a(r: Rect2, tabs: Array) -> Rect2:
	_box(r, _c("panel"), _c("border"))
	draw_rect(Rect2(r.position, Vector2(r.size.x, 30)), _c("bg"))
	var x := r.position.x
	for k in tabs.size():
		var w := 22.0 + String(tabs[k]).length() * 8.6 + 20.0
		if k == 0:
			draw_rect(Rect2(x, r.position.y, w, 30), _c("panel"))
			draw_rect(Rect2(x, r.position.y, w, 2), _c("accent"))
		_txt(Vector2(x + 12, r.position.y + 20), String(tabs[k]), 14, _c("text") if k == 0 else _c("muted"))
		_txt(Vector2(x + w - 18, r.position.y + 20), "×", 14, _c("muted"))
		x += w
	for k in 3:
		draw_circle(Vector2(r.end.x - 16 - k * 12, r.position.y + 15), 3.0, _c("muted"))
	return Rect2(r.position + Vector2(0, 30), r.size - Vector2(0, 30))


func _inventory_a(r: Rect2) -> void:
	var body := _window_a(r, ["inventario.json", "equipo.yaml"])
	var y := body.position.y + 26
	var lines := [["{", ""]]
	for it in ITEMS:
		if it[2] != "bolsa":
			lines.append(['  "%s": ' % it[2], it[0], it[1]])
	lines.append(["}", ""])
	for k in lines.size():
		var l: Array = lines[k]
		_txt(Vector2(body.position.x + 10, y), "%2d" % (k + 1), 14, Color(_c("muted"), 0.6))
		_txt(Vector2(body.position.x + 44, y), l[0], 15, _c("ai") if l.size() > 2 else _c("text"))
		if l.size() > 2:
			_txt(Vector2(body.position.x + 44 + String(l[0]).length() * 9.0, y), '"%s",' % l[1], 15, Color(RARE[l[2]]))
		y += 24
	# La bolsa: una rejilla de casillas con borde del color de la rareza.
	_txt(Vector2(body.position.x + 44, y + 14), "// bolsa  18/40", 14, Color(_c("ok"), 0.8))
	var grid := Vector2(body.position.x + 44, y + 28)
	for i in 40:
		var cell := Rect2(grid + Vector2((i % 10) * 64, (i / 10) * 52), Vector2(58, 46))
		var rar: String = ["rare", "unique", "magic", "ultra", "normal", "magic", "rare"][i] if i < 7 else ""
		draw_rect(cell, _c("panel2"))
		draw_rect(cell, Color(RARE[rar]) if rar != "" else _c("border"), false, 1.0)
		if rar != "":
			draw_rect(cell.grow(-14), Color(RARE[rar], 0.35))
	# Barra de estado, como la de un editor.
	var bar := Rect2(r.position.x, r.end.y - 24, r.size.x, 24)
	draw_rect(bar, Color(_c("accent"), 0.85))
	_txt(bar.position + Vector2(10, 17), "⎇ main   UTF-8   Ln 4, Col 12        oro: 1 284   peso: 18/40", 13, _c("bg"))


func _tooltip_a(r: Rect2) -> void:
	var body := _window_a(r, ["teclado.md"])
	var x := body.position.x + 14
	_txt(Vector2(x, body.position.y + 28), "## Teclado mecánico de la Pila", 16, Color(RARE["rare"]))
	_txt(Vector2(x, body.position.y + 50), "maza · una mano · nivel 24", 13, _c("muted"))
	draw_rect(Rect2(x, body.position.y + 60, r.size.x - 28, 1), _c("border"))
	_txt(Vector2(x, body.position.y + 84), "base.daño = 41–63", 14, _c("text"))
	for k in AFFIXES.size():
		var y := body.position.y + 110 + k * 24
		_txt(Vector2(x, y), "%d" % (k + 1), 13, Color(_c("muted"), 0.6))
		_txt(Vector2(x + 22, y), AFFIXES[k][0], 14, Color(RARE[AFFIXES[k][1]]))
	_txt(Vector2(x, body.end.y - 18), "// vender: 312 oro", 13, Color(_c("ok"), 0.8))


func _minimap_a(r: Rect2) -> void:
	var body := _window_a(r, ["mapa.svg"])
	for gx in range(int(body.position.x), int(body.end.x), 20):
		draw_line(Vector2(gx, body.position.y), Vector2(gx, body.end.y), Color(_c("border"), 0.5))
	for gy in range(int(body.position.y), int(body.end.y), 20):
		draw_line(Vector2(body.position.x, gy), Vector2(body.end.x, gy), Color(_c("border"), 0.5))
	var o := body.get_center()
	var pts := PackedVector2Array([o + Vector2(-140, 60), o + Vector2(-60, 40), o + Vector2(0, -20), o + Vector2(90, -60), o + Vector2(140, 10)])
	draw_polyline(pts, Color(_c("accent"), 0.6), 6.0)
	draw_circle(o + Vector2(0, -20), 5.0, _c("ok"))
	for e in [Vector2(80, -50), Vector2(110, -20), Vector2(-90, 50)]:
		draw_circle(o + e, 3.5, _c("danger"))
	_txt(body.position + Vector2(10, body.size.y - 10), "x: 812  y: -240   racks/03", 12, _c("muted"))


func _dialogue_a(r: Rect2) -> void:
	var body := _window_a(r, ["tty — aida@campamento"])
	var x := body.position.x + 14
	_txt(Vector2(x, body.position.y + 24), "$ cat aida.txt", 14, _c("muted"))
	_txt(Vector2(x, body.position.y + 48), "aida>", 15, _c("accent"))
	draw_multiline_string(_mono, Vector2(x + 58, body.position.y + 48), DIALOGUE, HORIZONTAL_ALIGNMENT_LEFT, r.size.x - 90, 15, -1, _c("text"))
	for k in OPTIONS.size():
		_txt(Vector2(x + 260 * k, body.end.y - 40), "[%d] %s" % [k + 1, OPTIONS[k]], 14, _c("ok"))
	_txt(Vector2(x, body.end.y - 14), ">", 15, _c("accent"))
	draw_rect(Rect2(x + 14, body.end.y - 28, 9, 17), _c("accent"))   # el cursor que parpadea


## Barra segmentada «nombre [████░░] 72 %».
func _bar_a(pos: Vector2, label: String, f: float, col: Color, w := 340.0) -> void:
	_txt(pos, label, 14, _c("muted"))
	var x0 := pos.x + 110
	_txt(Vector2(x0, pos.y), "[", 15, _c("muted"))
	var n := 20
	for k in n:
		draw_rect(Rect2(x0 + 12 + k * (w / n), pos.y - 13, w / n - 3, 16), col if k < roundi(f * n) else Color(col, 0.15))
	_txt(Vector2(x0 + w + 14, pos.y), "] %d %%" % roundi(f * 100), 15, _c("text"))


func _keycap(r: Rect2, key: String, glyph: String, col: Color, cooldown := 0.0) -> void:
	_box(Rect2(r.position + Vector2(0, 4), r.size), _c("bg"), Color(0, 0, 0, 0), 6)
	_box(r, _c("panel2"), _c("border"), 6)
	_txt(r.position + Vector2(8, 18), key, 12, _c("muted"))
	_txt(r.position + Vector2(r.size.x / 2 - 10, r.size.y / 2 + 10), glyph, 24, col)
	if cooldown > 0.0:   # el barrido de enfriamiento
		var c := r.get_center()
		var pts := PackedVector2Array([c])
		for k in 25:
			var a := -PI / 2 + TAU * cooldown * k / 24.0
			pts.append(c + Vector2(cos(a), sin(a)) * r.size.x)
		draw_set_transform(Vector2.ZERO)
		var clip := Geometry2D.intersect_polygons(pts, PackedVector2Array([r.position, Vector2(r.end.x, r.position.y), r.end, Vector2(r.position.x, r.end.y)]))
		for poly in clip:
			draw_colored_polygon(poly, Color(0, 0, 0, 0.55))


func _hud_a(r: Rect2) -> void:
	_box(r, Color(_c("panel"), 0.92), _c("border"))
	var x := r.position.x + 20
	_txt(Vector2(x, r.position.y + 28), "proceso.alumno  pid 2048", 14, _c("accent"))
	_bar_a(Vector2(x, r.position.y + 62), "integridad", 0.72, _c("danger"))
	_bar_a(Vector2(x, r.position.y + 92), "memoria", 0.55, _c("accent"))
	_txt(Vector2(x, r.position.y + 136), "TODO.md", 14, _c("accent"))
	for k in 3:
		var done := k == 0
		_txt(Vector2(x, r.position.y + 162 + k * 24), "- [%s] %s" % ["x" if done else " ", ["Habla con Aida", "Limpia la zona  9/14", "Baja a los racks"][k]],
			14, _c("muted") if done else _c("text"))
	# Teclas de habilidad.
	var kx := r.position.x + 560
	for k in 6:
		_keycap(Rect2(kx + k * 76, r.position.y + 30, 66, 66), ["Q", "W", "E", "R", "1", "2"][k], ["⌁", "{}", "⚡", "∑", "♥", "◆"][k],
			[_c("accent"), _c("ai"), _c("warn"), _c("ok"), _c("danger"), _c("accent")][k], 0.35 if k == 2 else 0.0)
	_txt(Vector2(kx, r.position.y + 130), "compilando nivel 24", 14, _c("muted"))
	draw_rect(Rect2(kx, r.position.y + 140, 446, 10), _c("panel2"))
	draw_rect(Rect2(kx, r.position.y + 140, 446 * 0.63, 10), _c("ok"))
	_txt(Vector2(kx + 400, r.position.y + 130), "63 %", 14, _c("text"))
	# Consola de sucesos.
	var cx := r.position.x + 1060
	_box(Rect2(cx, r.position.y + 16, 440, r.size.y - 32), _c("bg"), _c("border"))
	for k in LOG.size():
		var lv: String = LOG[k][0]
		var col: Color = {"INFO": _c("accent"), "WARN": _c("warn"), "OK": _c("ok")}[lv]
		var y := r.position.y + 44 + k * 26
		_txt(Vector2(cx + 10, y), "12:0%d" % (k + 1), 13, _c("muted"))
		_txt(Vector2(cx + 62, y), "[%s]" % lv, 13, col)
		_txt(Vector2(cx + 122, y), LOG[k][1], 13, _c("text"))


# --- B · Panel de monitoreo/datos -------------------------------------------------------

## Tarjeta plana con título y un motivo de grafo (tres nodos unidos) en la esquina.
func _card_b(r: Rect2, title: String, subtitle := "") -> Rect2:
	_box(r, _c("panel"), _c("border"), 10)
	_txt(r.position + Vector2(18, 30), title, 17, _c("text"), false)
	if subtitle != "":
		_txt(r.position + Vector2(18, 50), subtitle, 13, _c("muted"), false)
	var n := [r.end + Vector2(-70, -r.size.y + 20), r.end + Vector2(-44, -r.size.y + 34), r.end + Vector2(-20, -r.size.y + 18)]
	draw_line(n[0], n[1], Color(_c("accent"), 0.5), 1.5)
	draw_line(n[1], n[2], Color(_c("accent"), 0.5), 1.5)
	for p in n:
		draw_circle(p, 3.5, _c("accent"))
	return Rect2(r.position + Vector2(18, 62), r.size - Vector2(36, 76))


## Separador con capas de una red neuronal en el centro.
func _separator_b(a: Vector2, b: Vector2) -> void:
	var mid := (a + b) / 2.0
	draw_line(a, mid - Vector2(40, 0), _c("border"), 1.0)
	draw_line(mid + Vector2(40, 0), b, _c("border"), 1.0)
	var layers := [[-8.0, 8.0], [-12.0, 0.0, 12.0], [-8.0, 8.0]]
	for li in layers.size():
		for yi in layers[li]:
			var p: Vector2 = mid + Vector2(-26 + li * 26, yi)
			if li < 2:
				for yj in layers[li + 1]:
					draw_line(p, mid + Vector2(-26 + (li + 1) * 26, yj), Color(_c("ai"), 0.4), 1.0)
			draw_circle(p, 2.5, _c("ai"))


func _sparkline(r: Rect2, values: Array, col: Color) -> void:
	var pts := PackedVector2Array()
	for k in values.size():
		pts.append(r.position + Vector2(r.size.x * k / float(values.size() - 1), r.size.y * (1.0 - float(values[k]))))
	var fill := pts.duplicate()
	fill.append(r.end)
	fill.append(Vector2(r.position.x, r.end.y))
	draw_colored_polygon(fill, Color(col, 0.15))
	draw_polyline(pts, col, 2.0, true)


func _inventory_b(r: Rect2) -> void:
	var body := _card_b(r, "Inventario", "6 objetos · bolsa 18/40 · 1 284 oro")
	var k := 0
	for it in ITEMS:
		if it[2] == "bolsa":
			continue
		var cr := Rect2(body.position + Vector2((k % 2) * 356, (k / 2) * 86), Vector2(344, 76))
		_box(cr, _c("panel2"), Color(0, 0, 0, 0), 8)
		draw_rect(Rect2(cr.position, Vector2(4, cr.size.y)), Color(RARE[it[1]]))
		_txt(cr.position + Vector2(16, 22), String(it[2]).to_upper(), 11, _c("muted"), false)
		_txt(cr.position + Vector2(16, 44), it[0], 15, Color(RARE[it[1]]), false)
		_sparkline(Rect2(cr.position + Vector2(220, 48), Vector2(110, 20)), [0.2, 0.4, 0.35, 0.6, 0.55, 0.8, 0.7], _c("accent"))
		k += 1
	_separator_b(Vector2(body.position.x, body.position.y + 188), Vector2(body.end.x, body.position.y + 188))
	var grid := body.position + Vector2(0, 208)
	for i in 30:
		var cell := Rect2(grid + Vector2((i % 10) * 70.4, (i / 10) * 66), Vector2(62, 58))
		var rar: String = ["rare", "unique", "magic", "ultra", "normal", "magic", "rare"][i] if i < 7 else ""
		_box(cell, _c("panel2") if rar != "" else Color(_c("panel2"), 0.4), Color(RARE[rar], 0.8) if rar != "" else Color(0, 0, 0, 0), 8)
		if rar != "":
			draw_circle(cell.get_center(), 12.0, Color(RARE[rar], 0.4))


func _tooltip_b(r: Rect2) -> void:
	_box(r, _c("panel"), Color(RARE["rare"], 0.6), 10)
	_box(Rect2(r.position, Vector2(r.size.x, 56)), Color(RARE["rare"], 0.14), Color(0, 0, 0, 0), 10)
	_txt(r.position + Vector2(18, 26), "Teclado mecánico de la Pila", 17, Color(RARE["rare"]), false)
	_txt(r.position + Vector2(18, 46), "Maza · una mano · nivel 24 · raro", 12, _c("muted"), false)
	_txt(r.position + Vector2(18, 86), "Daño 41–63", 15, _c("text"), false)
	_sparkline(Rect2(r.position + Vector2(220, 70), Vector2(140, 22)), [0.3, 0.45, 0.4, 0.7, 0.9], _c("warn"))
	for k in AFFIXES.size():
		var y := r.position.y + 122 + k * 34
		_txt(Vector2(r.position.x + 18, y), AFFIXES[k][0], 14, Color(RARE[AFFIXES[k][1]]), false)
		draw_rect(Rect2(r.position.x + 18, y + 8, 340, 4), _c("panel2"))
		draw_rect(Rect2(r.position.x + 18, y + 8, 340 * [0.8, 0.45, 0.6, 0.3][k], 4), Color(RARE[AFFIXES[k][1]], 0.7))


func _minimap_b(r: Rect2) -> void:
	var body := _card_b(r, "Radar", "racks / 03")
	var o := body.get_center() + Vector2(0, 6)
	for k in 3:
		draw_arc(o, 34.0 + k * 34.0, 0, TAU, 64, Color(_c("accent"), 0.25), 1.0)
	draw_line(o - Vector2(110, 0), o + Vector2(110, 0), Color(_c("accent"), 0.2))
	draw_line(o - Vector2(0, 104), o + Vector2(0, 104), Color(_c("accent"), 0.2))
	var sweep := PackedVector2Array([o])
	for k in 13:
		var a := -0.9 + k * 0.05
		sweep.append(o + Vector2(cos(a), sin(a)) * 102.0)
	draw_colored_polygon(sweep, Color(_c("accent"), 0.18))
	draw_circle(o, 5.0, _c("ok"))
	for e in [Vector2(60, -40), Vector2(80, -10), Vector2(-50, 60)]:
		draw_circle(o + e, 4.0, _c("danger"))


func _dialogue_b(r: Rect2) -> void:
	_box(r, _c("panel"), _c("border"), 10)
	# El retrato: Aida en pixel art (T178) en un círculo.
	var face := Vector2(r.position.x + 70, r.position.y + 78)
	draw_circle(face, 52.0, _c("panel2"))
	draw_arc(face, 52.0, 0, TAU, 64, _c("accent"), 2.0)
	if StudentHero.available():
		var db: Dictionary = Zone.npc_database().get("npcs", {})
		if db.has("ada"):
			var nl: Array = StudentHero.npc_look(db["ada"])
			var tex := StudentHero.texture(nl[0], nl[1])
			var cell := Vector2(StudentHero.CELL)
			draw_texture_rect_region(tex, Rect2(face - Vector2(cell.x, cell.y * 1.08), cell * 2.0), Rect2(Vector2.ZERO, cell))
	_txt(Vector2(r.position.x + 140, r.position.y + 34), "Aida, la Senior", 18, _c("text"), false)
	_box(Rect2(r.position.x + 290, r.position.y + 18, 86, 22), Color(_c("ai"), 0.2), Color(0, 0, 0, 0), 11)
	_txt(Vector2(r.position.x + 302, r.position.y + 34), "mentora", 13, _c("ai"), false)
	draw_multiline_string(_sans, Vector2(r.position.x + 140, r.position.y + 66), DIALOGUE, HORIZONTAL_ALIGNMENT_LEFT, r.size.x - 170, 16, -1, _c("text"))
	var x := r.position.x + 140
	for k in OPTIONS.size():
		var w := 26.0 + String(OPTIONS[k]).length() * 8.0
		_box(Rect2(x, r.end.y - 50, w, 34), Color(_c("accent"), 0.12) if k == 0 else _c("panel2"), _c("accent") if k == 0 else _c("border"), 17)
		_txt(Vector2(x + 13, r.end.y - 28), OPTIONS[k], 14, _c("text"), false)
		x += w + 12


## Medidor circular con marcas: el arco lleno es la fracción.
func _gauge_b(c: Vector2, radius: float, f: float, col: Color, label: String) -> void:
	for k in 31:
		var a := deg_to_rad(135.0 + 270.0 * k / 30.0)
		var d := Vector2(cos(a), sin(a))
		draw_line(c + d * (radius + 6), c + d * (radius + (12 if k % 5 == 0 else 9)), Color(_c("muted"), 0.6), 1.5)
	draw_arc(c, radius, deg_to_rad(135), deg_to_rad(405), 64, _c("panel2"), 12.0)
	draw_arc(c, radius, deg_to_rad(135), deg_to_rad(135 + 270 * f), 64, col, 12.0)
	var pct := "%d%%" % roundi(f * 100)
	draw_string(_sans, c + Vector2(-radius, 8), pct, HORIZONTAL_ALIGNMENT_CENTER, radius * 2, 26, _c("text"))
	draw_string(_sans, c + Vector2(-radius, 30), label, HORIZONTAL_ALIGNMENT_CENTER, radius * 2, 12, _c("muted"))


func _hud_b(r: Rect2) -> void:
	_box(Rect2(r.position, Vector2(420, r.size.y)), _c("panel"), _c("border"), 10)
	_gauge_b(r.position + Vector2(110, 120), 62.0, 0.72, _c("danger"), "integridad")
	_gauge_b(r.position + Vector2(310, 120), 62.0, 0.55, _c("accent"), "memoria")
	_txt(r.position + Vector2(20, 236), "DPS · últimos 30 s", 12, _c("muted"), false)
	_sparkline(Rect2(r.position + Vector2(20, 246), Vector2(380, 30)), [0.3, 0.5, 0.4, 0.8, 0.6, 0.9, 0.7, 0.95, 0.6], _c("warn"))
	# Habilidades y experiencia.
	var mid := Rect2(r.position + Vector2(440, 0), Vector2(580, r.size.y))
	_box(mid, _c("panel"), _c("border"), 10)
	for k in 6:
		var cr := Rect2(mid.position + Vector2(20 + k * 92, 24), Vector2(80, 80))
		var col: Color = [_c("accent"), _c("ai"), _c("warn"), _c("ok"), _c("danger"), _c("accent")][k]
		_box(cr, _c("panel2"), Color(col, 0.6), 12)
		_txt(cr.position + Vector2(cr.size.x / 2 - 12, 52), ["⌁", "{}", "⚡", "∑", "♥", "◆"][k], 26, col)
		_txt(cr.position + Vector2(8, 18), ["Q", "W", "E", "R", "1", "2"][k], 12, _c("muted"), false)
		if k == 2:
			draw_arc(cr.get_center(), 30.0, -PI / 2, -PI / 2 + TAU * 0.35, 32, Color(0, 0, 0, 0.6), 8.0)
	_txt(mid.position + Vector2(20, 140), "Nivel 24", 15, _c("text"), false)
	_txt(mid.position + Vector2(500, 140), "63 %", 15, _c("ok"), false)
	_box(Rect2(mid.position + Vector2(20, 152), Vector2(540, 10)), _c("panel2"), Color(0, 0, 0, 0), 5)
	_box(Rect2(mid.position + Vector2(20, 152), Vector2(540 * 0.63, 10)), _c("ok"), Color(0, 0, 0, 0), 5)
	_txt(mid.position + Vector2(20, 196), "Misiones", 14, _c("muted"), false)
	for k in 3:
		var p := mid.position + Vector2(20 + k * 186, 214)
		_box(Rect2(p, Vector2(16, 16)), _c("ok") if k == 0 else Color(0, 0, 0, 0), _c("ok") if k == 0 else _c("muted"), 4)
		_txt(p + Vector2(24, 13), ["Habla con Aida", "Zona 9/14", "Baja a los racks"][k], 13, _c("muted") if k == 0 else _c("text"), false)
	# Sucesos como tarjetas con un punto de color.
	var ev := Rect2(r.position + Vector2(1040, 0), Vector2(480, r.size.y))
	_card_b(ev, "Sucesos")
	for k in LOG.size():
		var lv: String = LOG[k][0]
		var col: Color = {"INFO": _c("accent"), "WARN": _c("warn"), "OK": _c("ok")}[lv]
		var y := ev.position.y + 84 + k * 46
		_box(Rect2(ev.position.x + 18, y - 22, 444, 38), _c("panel2"), Color(0, 0, 0, 0), 8)
		draw_circle(Vector2(ev.position.x + 36, y - 3), 5.0, col)
		_txt(Vector2(ev.position.x + 52, y + 2), LOG[k][1], 14, _c("text"), false)
		_txt(Vector2(ev.position.x + 408, y + 2), "12:0%d" % (k + 1), 12, _c("muted"), false)
