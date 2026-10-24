class_name LootFilterPanel
extends Control
## Ventana del filtro de botín (Pausa → Filtro de botín, o el botón del
## inventario). Una fila por categoría con «gemas» de rareza: se pulsa la rareza
## mínima y se encienden de ahí hacia arriba; lo de abajo queda apagado y
## tachado. El hardware (placas, RAM, pociones) se muestra u oculta. Abajo, desde
## qué rareza sale el haz de luz, y a la derecha una vista previa de las
## etiquetas tal como se verán en el suelo. Todo se guarda al momento.

signal close_requested

const GEM := Vector2(92, 30)

var _loot: LootManager
var _rows: Array[Control] = []
var _preview: Control
var _ground_label: Label


func setup(loot: LootManager) -> void:
	_loot = loot
	mouse_filter = Control.MOUSE_FILTER_STOP
	visible = false
	var overlay := ColorRect.new()
	overlay.color = Color(0, 0, 0, 0.6)
	add_child(overlay)
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var center := CenterContainer.new()
	add_child(center)
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var panel := PanelContainer.new()
	panel.theme = UiStyle.make_theme()
	UiStyle.decorate_window(panel)
	center.add_child(panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	panel.add_child(box)
	box.add_child(UiStyle.window_header("Filtro de botín",
		"Lo que no pasa el filtro no existe. Hasta que mantienes Shift.", func() -> void: close_requested.emit()))
	# Atajos.
	var presets := HBoxContainer.new()
	presets.add_theme_constant_override("separation", 8)
	box.add_child(presets)
	presets.add_child(UiStyle.label("Atajos:", 14, UiStyle.MUTED))
	for p in LootFilter.PRESETS:
		var b := UiStyle.button(LootFilter.PRESET_NAMES[p], func() -> void:
			LootFilter.apply_preset(p)
			_refresh(), 140)
		presets.add_child(b)
	var columns := HBoxContainer.new()
	columns.add_theme_constant_override("separation", 18)
	box.add_child(columns)
	var left := VBoxContainer.new()
	left.add_theme_constant_override("separation", 6)
	columns.add_child(left)
	left.add_child(UiStyle.section_header("Equipo: rareza mínima para verse"))
	for cat in LootFilter.GEAR:
		left.add_child(_gem_row(cat, LootFilter.STEPS))
	left.add_child(UiStyle.section_header("Hardware y consumibles"))
	for cat in LootFilter.TOGGLES:
		left.add_child(_gem_row(cat, ["normal", "hidden"]))
	left.add_child(UiStyle.section_header("Haz de luz y sonido desde"))
	left.add_child(_gem_row("beam", ["magic", "rare", "ultra", "unique_only"]))
	# Vista previa.
	var right := VBoxContainer.new()
	right.add_theme_constant_override("separation", 6)
	columns.add_child(right)
	right.add_child(UiStyle.section_header("Así se verá en el suelo"))
	_preview = Control.new()
	_preview.custom_minimum_size = Vector2(300, 330)
	_preview.draw.connect(_draw_preview)
	right.add_child(_preview)
	_ground_label = UiStyle.label("", 12, UiStyle.MUTED)
	right.add_child(_ground_label)
	var hint := UiStyle.label("Los únicos, los de conjunto y los objetos clave se ven siempre.\nMantén Shift en el juego: lo oculto aparece atenuado.", 12, UiStyle.MUTED)
	box.add_child(hint)


func open() -> void:
	visible = true
	_refresh()


func _refresh() -> void:
	for r in _rows:
		r.queue_redraw()
	if _preview:
		_preview.queue_redraw()
	if _loot:
		var hidden := 0
		for d in _loot.drops:
			if not LootFilter.passes(d["item"]):
				hidden += 1
		_ground_label.text = "En el suelo ahora: %d visibles · %d ocultos" % [_loot.drops.size() - hidden, hidden]
		_loot.queue_redraw()


## Fila: icono y nombre de la categoría y una gema por escalón.
func _gem_row(key: String, steps: Array) -> Control:
	var row := Control.new()
	row.custom_minimum_size = Vector2(190.0 + steps.size() * (GEM.x + 4.0), GEM.y + 6.0)
	row.mouse_filter = Control.MOUSE_FILTER_STOP
	_rows.append(row)
	row.draw.connect(func() -> void: _draw_row(row, key, steps))
	row.gui_input.connect(func(ev: InputEvent) -> void:
		if ev is InputEventMouseMotion:
			row.queue_redraw()   # resalta la gema bajo el ratón
		var mb := ev as InputEventMouseButton
		if mb and mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT:
			var k := int((mb.position.x - 190.0) / (GEM.x + 4.0))
			if mb.position.x >= 190.0 and k >= 0 and k < steps.size():
				LootFilter.set_rule(key, steps[k])
				Sfx.play("pickup", -10.0, 1.2)
				_refresh())
	row.mouse_exited.connect(row.queue_redraw)
	return row


func _draw_row(row: Control, key: String, steps: Array) -> void:
	var font := row.get_theme_default_font()
	var current := String(LootFilter.rules().get(key, "normal"))
	var cur_index := steps.find(current)
	_draw_category_icon(row, Rect2(4, 4, 26, 26), key)
	var title: String = LootFilter.NAMES.get(key, "Haz de luz")
	row.draw_string(font, Vector2(38, 23), title, HORIZONTAL_ALIGNMENT_LEFT, 150, 14, UiStyle.TEXT)
	var mouse := row.get_local_mouse_position()
	for k in steps.size():
		var step: String = steps[k]
		var r := Rect2(190.0 + k * (GEM.x + 4.0), 3.0, GEM.x, GEM.y)
		var col: Color = LootFilter.STEP_COLORS[step]
		var label: String = LootFilter.STEP_NAMES[step]
		if steps.size() == 2:   # mostrar / ocultar
			label = "Mostrar" if step == "normal" else "Ocultar"
			col = Color("6fd36b") if step == "normal" else Color("e06c6c")
		# Encendida: la elegida y las de más rareza (salvo «Oculto», que solo se enciende sola).
		var lit := (k == cur_index) if (step == "hidden" or steps.size() == 2) else (k >= cur_index and current != "hidden")
		var hover := r.has_point(mouse)
		row.draw_rect(r.grow(1.0), Color(0, 0, 0, 0.9))
		row.draw_rect(r, Color(col, 0.30 if lit else 0.06))
		row.draw_rect(Rect2(r.position, Vector2(r.size.x, r.size.y * 0.45)), Color(1, 1, 1, 0.10 if lit else 0.03))
		row.draw_rect(r, col if lit else Color(col, 0.35), false, 2.0 if k == cur_index else 1.0)
		if k == cur_index:
			# La elegida: esquinas talladas en dorado.
			for c in [r.position, Vector2(r.end.x - 6, r.position.y), Vector2(r.position.x, r.end.y - 6), r.end - Vector2(6, 6)]:
				row.draw_rect(Rect2(c, Vector2(6, 6)), UiStyle.ACCENT)
		if hover:
			row.draw_rect(r.grow(2.0), Color(1, 1, 1, 0.35), false, 1.0)
		row.draw_string(font, r.position + Vector2(0, 20), label, HORIZONTAL_ALIGNMENT_CENTER, r.size.x, 12,
			col.lightened(0.2) if lit else Color(col, 0.45))
		if not lit and step != "hidden" and steps.size() > 2:
			row.draw_line(r.position + Vector2(8, r.size.y / 2.0), Vector2(r.end.x - 8, r.position.y + r.size.y / 2.0), Color(col, 0.4), 1.0)


## Iconitos de las categorías (pixel art con formas).
func _draw_category_icon(ci: CanvasItem, r: Rect2, key: String) -> void:
	var c := r.get_center()
	var gold := UiStyle.ACCENT
	ci.draw_rect(r, Color(0.1, 0.08, 0.12))
	ci.draw_rect(r, Color("3a3442"), false, 1.0)
	match key:
		"weapon":
			ci.draw_line(c + Vector2(-8, 8), c + Vector2(8, -8), Color("c8c8c8"), 3.0)
			ci.draw_line(c + Vector2(-9, 3), c + Vector2(-3, 9), gold, 2.0)
		"armour":
			ci.draw_colored_polygon(PackedVector2Array([c + Vector2(-8, -7), c + Vector2(8, -7), c + Vector2(7, 3), c + Vector2(0, 9), c + Vector2(-7, 3)]), Color("8a8a96"))
		"jewelry":
			ci.draw_arc(c + Vector2(0, 2), 6.0, 0.0, TAU, 14, gold, 2.0)
			ci.draw_rect(Rect2(c + Vector2(-2, -9), Vector2(4, 4)), Color("af6025"))
		"chip":
			var hexa := PackedVector2Array()
			for k in 6:
				hexa.append(c + Vector2.from_angle(TAU * k / 6.0) * 9.0)
			ci.draw_colored_polygon(hexa, Color("5a4a7a"))
			ci.draw_circle(c, 3.0, Color("c08aff"))
		"board":
			ci.draw_rect(Rect2(c - Vector2(9, 7), Vector2(18, 14)), Color("2a6a3a"))
			for k in 3:
				ci.draw_rect(Rect2(c + Vector2(-7 + k * 5, -5), Vector2(3, 10)), Color("e0b050"))
		"ram":
			ci.draw_rect(Rect2(c - Vector2(10, 4), Vector2(20, 8)), Color("4b8bd6"))
			for k in 4:
				ci.draw_rect(Rect2(c + Vector2(-8 + k * 5, -2), Vector2(3, 4)), Color("1a1e28"))
		"flask":
			ci.draw_rect(Rect2(c - Vector2(5, 4), Vector2(10, 12)), Color("c8894a"))
			ci.draw_rect(Rect2(c - Vector2(3, 9), Vector2(6, 5)), Color("8a8293"))
		_:
			for k in 4:
				ci.draw_rect(Rect2(c.x - 2.0 + k - 1.5, r.position.y + 2 + k * 6, 4, 6), Color(1, 1, 0.7, 0.3 + 0.15 * k))


## Muestras de etiquetas: cómo se ve cada rareza y tipo con las reglas actuales.
func _draw_preview() -> void:
	var font := _preview.get_theme_default_font()
	_preview.draw_rect(Rect2(Vector2.ZERO, _preview.size), Color("0c0b0f"))
	_preview.draw_rect(Rect2(Vector2.ZERO, _preview.size), Color("3a3442"), false, 1.0)
	var samples := [
		["Espada oxidada", "weapon", Rarity.Item.NORMAL], ["Hacha de los Bugs", "weapon", Rarity.Item.MAGIC],
		["Grito de la Pila", "armour", Rarity.Item.RARE], ["Anillo del Kernel", "jewelry", Rarity.Item.ULTRA_RARE],
		["El Último Commit", "weapon", Rarity.Item.UNIQUE], ["Chip de expansión", "chip", Rarity.Item.MAGIC],
		["Placa: Ping Letal", "board", -1], ["RAM Multicanal", "ram", -1], ["Café de máquina", "flask", -1],
	]
	var y := 16.0
	for s in samples:
		var cat: String = s[1]
		var rarity: int = s[2]
		var shown := _sample_passes(cat, rarity)
		var beam := shown and rarity >= 0 and cat != "chip" and (rarity == Rarity.Item.UNIQUE \
			or LootFilter.step_of(rarity) >= LootFilter.STEPS.find(String(LootFilter.rules().get("beam", "rare"))))
		var col: Color = Rarity.item_color(rarity) if rarity >= 0 else {"board": Motherboard.COLOR, "ram": Color("5cb85c"), "flask": Color("c8894a")}[cat]
		var w := font.get_string_size(s[0], HORIZONTAL_ALIGNMENT_LEFT, -1, 13).x + 12.0
		var rect := Rect2(Vector2((_preview.size.x - w) / 2.0, y), Vector2(w, 22))
		if beam:
			for k in 4:
				_preview.draw_rect(Rect2(rect.position.x - 8 - k * 3, rect.position.y + 4, 3, 14), Color(col, 0.15 + 0.15 * k))
				_preview.draw_rect(Rect2(rect.end.x + 5 + k * 3, rect.position.y + 4, 3, 14), Color(col, 0.15 + 0.15 * k))
		_preview.draw_rect(rect, Color(0, 0, 0, 0.85 if shown else 0.4))
		if rarity == Rarity.Item.UNIQUE or rarity < 0:
			_preview.draw_rect(rect, Color(col, 1.0 if shown else 0.3), false, 1.5)
		_preview.draw_string(font, rect.position + Vector2(6, 16), s[0], HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color(col, 1.0 if shown else 0.3))
		if not shown:
			_preview.draw_line(rect.position + Vector2(4, 11), Vector2(rect.end.x - 4, rect.position.y + 11), Color("e06c6c", 0.7), 1.5)
			_preview.draw_string(font, Vector2(rect.end.x + 6, y + 16), "oculto", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color("e06c6c", 0.8))
		y += 34.0


func _sample_passes(cat: String, rarity: int) -> bool:
	if rarity == Rarity.Item.UNIQUE:
		return true
	var step := LootFilter.STEPS.find(String(LootFilter.rules().get(cat, "normal")))
	if rarity < 0:
		return step < LootFilter.STEPS.size() - 1
	return LootFilter.step_of(rarity) >= step and step < LootFilter.STEPS.size() - 1
