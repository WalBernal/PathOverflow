class_name LootFilterPanel
extends Control
## Ventana del filtro de botín (Pausa → Filtro de botín, o el botón del
## inventario). Una fila por categoría con «gemas» de rareza: se pulsa la rareza
## mínima y se encienden de ahí hacia arriba; lo de abajo queda apagado y
## tachado. El hardware (placas, RAM, pociones) se muestra u oculta. Abajo, desde
## qué rareza sale el haz de luz, y a la derecha una vista previa de las
## etiquetas tal como se verán en el suelo o las reglas finas (una u otra, para
## que la ventana mida como las demás). Todo se guarda al momento. Si no cabe en
## alto (interfaz grande en el celular), las filas se desplazan (T133).

signal close_requested

## Gemas de 32 px de alto: 44 con la interfaz al 140 % del celular.
const GEM := Vector2(92, 32)
## Margen libre arriba y abajo de la ventana.
const SCREEN_MARGIN := 24.0

var _loot: LootManager
var _rows: Array[Control] = []
var _preview_box: VBoxContainer
var _preview: Control
var _ground_label: Label
var _extra: VBoxContainer
var _panel: PanelContainer
var _scroll: ScrollContainer
var _tab_buttons: Array[Button] = []


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
	_panel = PanelContainer.new()
	_panel.theme = UiStyle.make_theme()
	UiStyle.decorate_window(_panel)
	center.add_child(_panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	_panel.add_child(box)
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
	_scroll = ScrollContainer.new()
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	columns.add_child(_scroll)
	var left := VBoxContainer.new()
	left.add_theme_constant_override("separation", 6)
	_scroll.add_child(left)
	left.minimum_size_changed.connect(_fit.call_deferred)
	left.add_child(UiStyle.section_header("Equipo: rareza mínima para verse"))
	for cat in LootFilter.GEAR:
		left.add_child(_gem_row(cat, LootFilter.STEPS))
	left.add_child(UiStyle.section_header("Hardware y consumibles"))
	for cat in LootFilter.TOGGLES:
		left.add_child(_gem_row(cat, ["normal", "hidden"]))
	left.add_child(UiStyle.section_header("Haz de luz y sonido desde"))
	left.add_child(_gem_row("beam", ["magic", "rare", "ultra", "unique_only"]))
	# A la derecha: la vista previa o las reglas finas, con dos pestañas.
	var right := VBoxContainer.new()
	right.add_theme_constant_override("separation", 6)
	right.custom_minimum_size.x = 300
	columns.add_child(right)
	var tabs := HBoxContainer.new()
	tabs.add_theme_constant_override("separation", 6)
	right.add_child(tabs)
	for t in [["Vista previa", 0], ["Reglas finas", 1]]:
		var b := UiStyle.button(t[0], func() -> void: _show_tab(t[1]), 147)
		b.toggle_mode = true
		tabs.add_child(b)
		_tab_buttons.append(b)
	_preview_box = VBoxContainer.new()
	_preview_box.add_theme_constant_override("separation", 6)
	right.add_child(_preview_box)
	_preview_box.add_child(UiStyle.section_header("Así se verá en el suelo"))
	_preview = Control.new()
	_preview.custom_minimum_size = Vector2(300, 330)
	_preview.draw.connect(_draw_preview)
	_preview_box.add_child(_preview)
	_ground_label = UiStyle.label("", 12, UiStyle.MUTED)
	_preview_box.add_child(_ground_label)
	# Reglas finas y filtros con nombre (se rehace al cambiar algo).
	_extra = VBoxContainer.new()
	_extra.add_theme_constant_override("separation", 6)
	_extra.custom_minimum_size.x = 300
	right.add_child(_extra)
	_show_tab(0)
	var hint := UiStyle.label("Los únicos, los de conjunto y los objetos clave se ven siempre.\nMantén Shift en el juego: lo oculto aparece atenuado.", 12, UiStyle.MUTED)
	box.add_child(hint)
	resized.connect(_fit)


func open() -> void:
	visible = true
	_refresh()
	_fit.call_deferred()


func _show_tab(index: int) -> void:
	_preview_box.visible = index == 0
	_extra.visible = index == 1
	for k in _tab_buttons.size():
		_tab_buttons[k].set_pressed_no_signal(k == index)


## Alto de las filas: enteras si caben; si no, lo que deja la pantalla, con desplazamiento.
func _fit() -> void:
	if _scroll == null or not visible:
		return
	var content := _scroll.get_child(0) as Control
	var full := content.get_combined_minimum_size()
	var overhead := _panel.get_combined_minimum_size().y - _scroll.get_combined_minimum_size().y
	var h := clampf(size.y - 2.0 * SCREEN_MARGIN - overhead, 120.0, full.y)
	if not is_equal_approx(_scroll.custom_minimum_size.y, h):
		_scroll.custom_minimum_size = Vector2(full.x, h)
		_panel.reset_size()


func _refresh() -> void:
	_build_extra()
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


## Columna de la derecha: nivel de objeto mínimo, bases buenas, afijos buscados
## y filtros guardados.
func _build_extra() -> void:
	if _extra == null:
		return
	for child in _extra.get_children():
		_extra.remove_child(child)
		child.queue_free()
	var r := LootFilter.rules()
	_extra.add_child(UiStyle.section_header("Reglas finas"))
	var ilvl := HBoxContainer.new()
	var min_ilvl := int(r["min_ilvl"])
	ilvl.add_child(UiStyle.label("Nivel de objeto mínimo: %s" % (str(min_ilvl) if min_ilvl > 0 else "sin mínimo"), 13))
	ilvl.add_child(UiStyle.button("−", func() -> void: _change(func() -> void: LootFilter.set_min_ilvl(min_ilvl - 5)), 36))
	ilvl.add_child(UiStyle.button("+", func() -> void: _change(func() -> void: LootFilter.set_min_ilvl(min_ilvl + 5)), 36))
	_extra.add_child(ilvl)
	_extra.add_child(_list_editor("bases", "Bases buenas (siempre visibles, con estrella)", _base_options()))
	_extra.add_child(_list_editor("stats", "Afijos buscados (siempre visibles, con estrella)", _stat_options()))
	_extra.add_child(UiStyle.section_header("Filtros guardados"))
	var save_row := HBoxContainer.new()
	var name_edit := LineEdit.new()
	name_edit.placeholder_text = "Nombre del filtro"
	name_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	save_row.add_child(name_edit)
	save_row.add_child(UiStyle.button("Guardar", func() -> void:
		if name_edit.text.strip_edges() != "":
			_change(func() -> void: LootFilter.save_profile(name_edit.text)), 90))
	_extra.add_child(save_row)
	for p in LootFilter.profiles():
		var row := HBoxContainer.new()
		var l := UiStyle.label(p, 13, UiStyle.TEXT)
		l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(l)
		row.add_child(UiStyle.button("Cargar", func() -> void: _change(func() -> void: LootFilter.load_profile(p)), 80))
		row.add_child(UiStyle.button("Borrar", func() -> void: _change(func() -> void: LootFilter.delete_profile(p)), 80))
		_extra.add_child(row)


## Lista editable (bases o afijos): un desplegable para añadir y una fila por elegido.
func _list_editor(kind: String, title: String, options: Array) -> Control:
	var box := VBoxContainer.new()
	box.add_child(UiStyle.label(title, 13, UiStyle.GOLD))
	var pick := OptionButton.new()
	pick.add_item("Añadir...")
	var names := {}
	for o in options:
		names[o[0]] = o[1]
		pick.add_item(o[1])
	pick.item_selected.connect(func(i: int) -> void:
		if i > 0 and not (LootFilter.rules()[kind] as Array).has(options[i - 1][0]):
			_change(func() -> void: LootFilter.toggle_listed(kind, options[i - 1][0])))
	box.add_child(pick)
	for id in LootFilter.rules()[kind]:
		box.add_child(UiStyle.button("x  " + String(names.get(id, id)), func() -> void: _change(func() -> void: LootFilter.toggle_listed(kind, id)), 300))
	return box


func _change(action: Callable) -> void:
	action.call()
	Sfx.play("pickup", -10.0, 1.2)
	_refresh.call_deferred()   # se rehace la columna desde la que se llamó


## [id, nombre] de las bases de equipo, por nombre.
func _base_options() -> Array:
	var out: Array = []
	var db: ItemDatabase = GameData.items
	for id in db.bases:
		var b: Dictionary = db.bases[id]
		if b.has("slot") and String(b["slot"]) != "chip":
			out.append([String(id), String(b.get("name", id))])
	out.sort_custom(func(a: Array, b: Array) -> bool: return a[1] < b[1])
	return out


## [stat, nombre] de los afijos que pueden salir en el equipo.
func _stat_options() -> Array:
	var seen := {}
	for a in GameData.items.affixes:
		var st := String(a.get("stat", ""))
		if st != "" and not seen.has(st):
			seen[st] = Stat.display_name(StringName(st))
	var out: Array = []
	for st in seen:
		out.append([st, seen[st]])
	out.sort_custom(func(a: Array, b: Array) -> bool: return a[1] < b[1])
	return out


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
		row.draw_string(font, r.position + Vector2(0, 21), label, HORIZONTAL_ALIGNMENT_CENTER, r.size.x, 12,
			col.lightened(0.2) if lit else Color(col, 0.45))
		if not lit and step != "hidden" and steps.size() > 2:
			row.draw_line(r.position + Vector2(8, r.size.y / 2.0), Vector2(r.end.x - 8, r.position.y + r.size.y / 2.0), Color(col, 0.4), 1.0)


## Iconitos de las categorías (pixel art con formas).
func _draw_category_icon(ci: CanvasItem, r: Rect2, key: String) -> void:
	var c := r.get_center()
	var gold := UiStyle.ACCENT
	ci.draw_rect(r, Color(0.1, 0.08, 0.12))
	ci.draw_rect(r, UiStyle.BORDER, false, 1.0)
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
			ci.draw_rect(Rect2(c - Vector2(3, 9), Vector2(6, 5)), UiStyle.MUTED)
		_:
			for k in 4:
				ci.draw_rect(Rect2(c.x - 2.0 + k - 1.5, r.position.y + 2 + k * 6, 4, 6), Color(1, 1, 0.7, 0.3 + 0.15 * k))


## Muestras de etiquetas: cómo se ve cada rareza y tipo con las reglas actuales.
func _draw_preview() -> void:
	var font := _preview.get_theme_default_font()
	_preview.draw_rect(Rect2(Vector2.ZERO, _preview.size), Color("0c0b0f"))
	_preview.draw_rect(Rect2(Vector2.ZERO, _preview.size), UiStyle.BORDER, false, 1.0)
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
