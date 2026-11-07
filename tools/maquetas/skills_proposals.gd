extends Control
## Maquetas de la pantalla nueva de habilidades y RAM (T228). Solo para capturas:
## dibujan con datos reales (placas y RAM del personaje de prueba) pero no hacen nada.
##   A · «Placa a placa»: eliges una placa y ves sus ranuras en grande, con las RAM
##       que encajan al lado y botones para instalar y quitar.
##   B · «RAM primero»: eliges una RAM de la bolsa y una hoja te dice en qué placas
##       y ranuras funciona (y cuánto mejora), con un botón para instalarla en cada una.

var variant := "a"
var touch := false
var boards: Array = []      # Motherboard o null (las 6 de la barra)
var bag: Array = []         # RamModule y Motherboard sueltos
const KEYS := ["Q", "W", "E", "R", "T", "Y"]
const GEN := {"DDR3": Color("c0504d"), "DDR4": Color("4c9a5a"), "DDR5": Color("4b7fc6")}
const BG := Color("0d1117")
const CARD := Color("161b22")
const LINE := Color("30363d")


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), BG)
	if variant == "a":
		_draw_a()
	else:
		_draw_b()


# --- Utilidades ---

func _f() -> Font:
	return get_theme_default_font()


func _t(p: Vector2, text: String, fs: int, col := UiStyle.TEXT, w := -1.0, align := HORIZONTAL_ALIGNMENT_LEFT) -> void:
	draw_string(_f(), p, text, align, w, int(fs * (1.25 if touch else 1.0)), col)


func _card(r: Rect2, border := LINE, fill := CARD, width := 1.5) -> void:
	draw_rect(r, fill)
	draw_rect(r, border, false, width)


func _button(r: Rect2, text: String, primary := false) -> void:
	_card(r, UiStyle.ACCENT if primary else LINE, UiStyle.ACCENT.darkened(0.6) if primary else Color("21262d"))
	_t(Vector2(r.position.x, r.get_center().y + 6), text, 15, Color.WHITE if primary else UiStyle.TEXT, r.size.x, HORIZONTAL_ALIGNMENT_CENTER)


func _ram_name(ram: RamModule) -> String:
	return String(ram.def.get("name", "RAM"))


func _ram_line(ram: RamModule) -> String:
	var d := String(ram.def.get("description", ""))
	var cut := d.find(".")
	return d.substr(0, cut + 1) if cut > 0 and cut < 70 else d.left(68) + "…"


func _header(title: String, sub: String) -> void:
	_t(Vector2(32, 52), title, 30, UiStyle.ACCENT)
	_t(Vector2(32, 82), sub, 14, UiStyle.MUTED)
	_button(Rect2(size.x - 80, 26, 48, 48), "✕")


# --- A · Placa a placa ---

func _draw_a() -> void:
	_header("Habilidades", "1 · Elige una placa   2 · Toca una RAM que encaje   3 · Instalar  —  Propuesta A: placa a placa")
	var rh := 92.0 if touch else 86.0
	var sel := 0
	# Columna izquierda: las 6 placas, compactas.
	for i in 6:
		var r := Rect2(24, 104 + i * (rh + 8), 330, rh)
		var b: Motherboard = boards[i] if i < boards.size() else null
		_card(r, UiStyle.ACCENT if i == sel else LINE, CARD.lightened(0.06) if i == sel else CARD, 2.5 if i == sel else 1.5)
		_t(r.position + Vector2(12, rh / 2 + 7), KEYS[i], 20, UiStyle.ACCENT if not touch else UiStyle.MUTED)
		if b == null:
			_t(r.position + Vector2(52, rh / 2 + 6), "Vacía · toca para poner una placa", 13, UiStyle.MUTED)
			continue
		SkillIcon.draw(self, Rect2(r.position + Vector2(40, 10), Vector2(rh - 20, rh - 20)), b.skill_def)
		_t(r.position + Vector2(rh + 30, 30), String(b.skill_def["name"]), 15)
		var x := r.position.x + rh + 30
		for k in b.rams.size():
			var gen := String(b.slots[k]) if k < b.slots.size() else "DDR3"
			var dot := Rect2(x + k * 22, r.position.y + 46, 16, 16)
			draw_rect(dot, GEN.get(gen, LINE) if b.rams[k] != null else Color(0, 0, 0, 0))
			draw_rect(dot, GEN.get(gen, LINE), false, 2.0)
	# Centro: la placa elegida, en grande.
	var b0: Motherboard = boards[sel]
	var c := Rect2(372, 104, 700, size.y - 200)
	_card(c)
	SkillIcon.draw(self, Rect2(c.position + Vector2(20, 20), Vector2(96, 96)), b0.skill_def)
	_t(c.position + Vector2(132, 52), "%s · nv. %d" % [b0.skill_def["name"], b0.level], 24, UiStyle.ACCENT)
	_t(c.position + Vector2(132, 82), "DPS ~81  ·  maná 57  ·  8 proyectiles  ·  tecla Q", 15, UiStyle.MUTED)
	_t(c.position + Vector2(132, 106), "Toca una ranura para ver su RAM o quitarla.", 13, UiStyle.MUTED)
	var sw := (c.size.x - 40 - 12 * 4) / 5.0
	for k in mini(5, b0.rams.size()):
		var ram: RamModule = b0.rams[k]
		var gen := String(b0.slots[k])
		var s := Rect2(c.position.x + 20 + k * (sw + 12), c.position.y + 140, sw, 230)
		_card(s, GEN[gen], Color(GEN[gen], 0.12), 2.0 if k != 4 else 3.5)
		draw_rect(Rect2(s.position, Vector2(s.size.x, 26)), GEN[gen])
		_t(Vector2(s.position.x, s.position.y + 19), "%s · ranura %d" % [gen, k + 1], 12, Color.WHITE, s.size.x, HORIZONTAL_ALIGNMENT_CENTER)
		if ram == null:
			_t(Vector2(s.position.x, s.get_center().y), "+ libre", 18, UiStyle.MUTED, s.size.x, HORIZONTAL_ALIGNMENT_CENTER)
			continue
		RamIcon.draw_badge(self, Rect2(s.get_center().x - 26, s.position.y + 40, 52, 52), ram)
		_t(Vector2(s.position.x + 6, s.position.y + 118), _ram_name(ram), 13, UiStyle.TEXT, s.size.x - 12, HORIZONTAL_ALIGNMENT_CENTER)
		var words := _ram_line(ram).split(" ")
		var line := ""
		var y := s.position.y + 140
		for wd in words:
			if _f().get_string_size(line + wd, HORIZONTAL_ALIGNMENT_LEFT, -1, int(11 * (1.25 if touch else 1.0))).x > s.size.x - 14:
				_t(Vector2(s.position.x + 7, y), line, 11, UiStyle.MUTED)
				y += 16
				line = ""
			line += wd + " "
		_t(Vector2(s.position.x + 7, y), line, 11, UiStyle.MUTED)
		if k == 4:
			_button(Rect2(s.position.x + 8, s.end.y - 44, s.size.x - 16, 36), "Quitar")
	# Barra de acciones de la placa.
	var ay := c.position.y + 400
	var labels := ["Cambiar tecla", "Comparar", "Variante: Normal", "Quitar placa"]
	for k in labels.size():
		_button(Rect2(c.position.x + 20 + k * 168, ay, 156, 48), labels[k])
	_t(c.position + Vector2(20, ay - c.position.y + 90), "Ranura 5 elegida: «Quitar» la devuelve a la bolsa. Las RAM de la derecha que encajan aquí están resaltadas.", 13, UiStyle.MUTED, c.size.x - 40)
	# Derecha: RAM que encajan en esta placa.
	var rx := Rect2(1090, 104, size.x - 1114, size.y - 200)
	_card(rx)
	_t(rx.position + Vector2(16, 34), "RAM que encajan aquí", 18, UiStyle.ACCENT)
	var chips := ["Encajan aquí", "Todas", "Placas"]
	for k in chips.size():
		_button(Rect2(rx.position.x + 16 + k * 150, rx.position.y + 50, 140, 36), chips[k], k == 0)
	var y2 := rx.position.y + 100
	var n := 0
	for it in bag:
		if not it is RamModule or n >= 5:
			continue
		var ram := it as RamModule
		var fits := ram.supports(b0.skill_def)
		var row := Rect2(rx.position.x + 12, y2, rx.size.x - 24, 88 if touch else 80)
		_card(row, UiStyle.ACCENT if n == 0 else LINE, CARD.lightened(0.05))
		RamIcon.draw_badge(self, Rect2(row.position + Vector2(10, 14), Vector2(46, 46)), ram, fits)
		_t(row.position + Vector2(68, 28), "%s  ·  %s" % [_ram_name(ram), ram.def.get("generation", "")], 13)
		_t(row.position + Vector2(68, 50), ["+9 % DPS", "+1 proyectil", "−12 % maná", "quema", "+15 % área"][n % 5], 13, Color("6fb36b"))
		if n == 0:
			_button(Rect2(row.end.x - 128, row.position.y + 16, 116, 44), "Instalar", true)
		y2 += row.size.y + 8
		n += 1
	# Pie: bolsa y atajos (en PC).
	_t(Vector2(32, size.y - 24), "PC: arrastra y suelta como siempre · clic derecho = quitar · 1-6 elige placa" if not touch else "Todo se hace con toques: sin arrastrar, sin doble toque, sin pulsación larga.", 13, UiStyle.MUTED)


# --- B · RAM primero ---

func _draw_b() -> void:
	_header("Habilidades", "Toca una RAM de la bolsa: te decimos dónde funciona y cuánto mejora  —  Propuesta B: RAM primero")
	# Arriba: las 6 placas como columnas compactas.
	var cw := (size.x - 48 - 5 * 10) / 6.0
	var picked: RamModule = null
	for it in bag:
		if it is RamModule:
			picked = it
			break
	for i in 6:
		var b: Motherboard = boards[i] if i < boards.size() else null
		var r := Rect2(24 + i * (cw + 10), 104, cw, 250 if touch else 230)
		var fits := b != null and picked != null and picked.supports(b.skill_def)
		var free := false
		if b != null and picked != null:
			for k in b.rams.size():
				if b.rams[k] == null and String(b.slots[k]) == String(picked.def.get("generation", "")):
					free = true
		var good := fits and (free or i == 0)
		_card(r, UiStyle.ACCENT if good else LINE, CARD.lightened(0.05) if good else CARD.darkened(0.2), 2.5 if good else 1.5)
		if b == null:
			continue
		_t(Vector2(r.position.x, r.position.y + 26), KEYS[i] + " · " + String(b.skill_def["name"]), 13, UiStyle.TEXT if good else UiStyle.MUTED, r.size.x, HORIZONTAL_ALIGNMENT_CENTER)
		SkillIcon.draw(self, Rect2(r.get_center().x - 34, r.position.y + 38, 68, 68), b.skill_def, not good)
		for k in b.rams.size():
			var gen := String(b.slots[k]) if k < b.slots.size() else "DDR3"
			var s := Rect2(r.position.x + 10 + k * ((r.size.x - 20) / b.rams.size()), r.position.y + 118, (r.size.x - 20) / b.rams.size() - 4, 34)
			draw_rect(s, Color(GEN.get(gen, LINE), 0.35 if b.rams[k] != null else 0.1))
			draw_rect(s, GEN.get(gen, LINE), false, 1.5)
			if b.rams[k] != null:
				RamIcon.draw_badge(self, Rect2(s.get_center() - Vector2(9, 9), Vector2(18, 18)), b.rams[k])
		var verdict := "✓ ranura libre · +9 % DPS" if good and free else ("✓ cambiar por otra · +4 %" if good else ("sin ranura " + String(picked.def.get("generation", "")) + " libre" if fits else "no le sirve"))
		_t(Vector2(r.position.x, r.position.y + 180), verdict, 12, Color("6fb36b") if good else Color("e06c6c").darkened(0.1), r.size.x, HORIZONTAL_ALIGNMENT_CENTER)
		if good:
			_button(Rect2(r.position.x + 12, r.end.y - 48, r.size.x - 24, 40), "Instalar aquí", true)
	# Hoja de la RAM elegida.
	var sheet := Rect2(24, 372 if not touch else 372, size.x * 0.42, size.y - 410)
	_card(sheet, UiStyle.ACCENT)
	if picked:
		RamIcon.draw_badge(self, Rect2(sheet.position + Vector2(18, 18), Vector2(72, 72)), picked)
		_t(sheet.position + Vector2(108, 44), _ram_name(picked), 22, UiStyle.ACCENT)
		_t(sheet.position + Vector2(108, 72), "%s  ·  soporte" % picked.def.get("generation", ""), 14, UiStyle.MUTED)
		var words := String(picked.def.get("description", "")).split(" ")
		var line := ""
		var y := sheet.position.y + 120
		for wd in words:
			if _f().get_string_size(line + wd, HORIZONTAL_ALIGNMENT_LEFT, -1, int(15 * (1.25 if touch else 1.0))).x > sheet.size.x - 40:
				_t(Vector2(sheet.position.x + 20, y), line, 15)
				y += 24
				line = ""
			line += wd + " "
		_t(Vector2(sheet.position.x + 20, y), line, 15)
		_t(Vector2(sheet.position.x + 20, sheet.end.y - 20), "Las placas de arriba que se iluminan pueden usarla. Toca «Instalar aquí».", 13, UiStyle.MUTED, sheet.size.x - 40)
	# Bolsa: casillas grandes con nombre.
	var bx := Rect2(sheet.end.x + 16, sheet.position.y, size.x - sheet.end.x - 40, sheet.size.y)
	_card(bx)
	_t(bx.position + Vector2(16, 30), "Bolsa", 18, UiStyle.ACCENT)
	var tile := 110.0 if touch else 96.0
	var cols := int((bx.size.x - 24) / (tile + 8))
	var k2 := 0
	for it in bag:
		var p := bx.position + Vector2(12 + (k2 % cols) * (tile + 8), 46 + (k2 / cols) * (tile + 30))
		if p.y + tile > bx.end.y:
			break
		var r := Rect2(p, Vector2(tile, tile))
		_card(r, UiStyle.ACCENT if it == picked else LINE, CARD.lightened(0.05), 3.0 if it == picked else 1.5)
		if it is RamModule:
			RamIcon.draw_badge(self, r.grow(-22), it)
			_t(Vector2(r.position.x, r.end.y + 18), _ram_name(it).split(" ")[0], 12, UiStyle.MUTED, r.size.x, HORIZONTAL_ALIGNMENT_CENTER)
		elif it is Motherboard:
			SkillIcon.draw(self, r.grow(-14), (it as Motherboard).skill_def)
			_t(Vector2(r.position.x, r.end.y + 18), String((it as Motherboard).skill_def["name"]).split(" ")[0], 12, UiStyle.MUTED, r.size.x, HORIZONTAL_ALIGNMENT_CENTER)
		k2 += 1
