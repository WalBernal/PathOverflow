class_name CatalogPanel
extends Control
## Catálogo de hardware (B), al estilo de un bestiario: todas las placas base
## (habilidades) y los módulos RAM (soportes) del juego. A la izquierda la
## rejilla con sus iconos (las que aún no has encontrado, apagadas); a la
## derecha la ficha: icono grande, descripción, cifras con tu personaje,
## etiquetas, requisitos, nivel desde el que caen, qué clase la trae de serie,
## variantes y, en las RAM, con qué placas funcionan.
## Lo encontrado se guarda en el personaje (flags "catalog_seen").

signal close_requested

const CELL := Vector2(92, 112)

var character: CharacterData
var _db: SkillDatabase
var _tab := "boards"
var _selected := ""
var _search: LineEdit
var _only_seen: CheckBox
var _gen_filter: OptionButton
var _grid: GridContainer
var _detail: RichTextLabel
var _big_icon: Control
var _tab_buttons := {}
var _count_label: Label


func setup(p_character: CharacterData, db: SkillDatabase) -> void:
	character = p_character
	_db = db
	mouse_filter = Control.MOUSE_FILTER_STOP
	var overlay := ColorRect.new()
	overlay.color = Color(0, 0, 0, 0.55)
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
	box.add_child(UiStyle.window_header("Catálogo de hardware",
		"Todo lo que el servidor puede soltarte. Lo que ya encontraste brilla; lo demás, de momento, es rumor de foro.",
		func() -> void: close_requested.emit()))
	# Pestañas, búsqueda y filtros.
	var bar := HBoxContainer.new()
	bar.add_theme_constant_override("separation", 8)
	box.add_child(bar)
	for t in [["boards", "Placas base"], ["rams", "Módulos RAM"]]:
		var b := UiStyle.button(t[1], func() -> void: _set_tab(t[0]), 150)
		b.toggle_mode = true
		bar.add_child(b)
		_tab_buttons[t[0]] = b
	_search = LineEdit.new()
	_search.placeholder_text = "Buscar (nombre, etiqueta, efecto)..."
	_search.custom_minimum_size = Vector2(260, 0)
	_search.text_changed.connect(func(_t: String) -> void: _rebuild())
	bar.add_child(_search)
	_gen_filter = OptionButton.new()
	for g in ["Toda generación", "DDR3", "DDR4", "DDR5"]:
		_gen_filter.add_item(g)
	_gen_filter.item_selected.connect(func(_i: int) -> void: _rebuild())
	bar.add_child(_gen_filter)
	_only_seen = CheckBox.new()
	_only_seen.text = "Solo encontradas"
	_only_seen.toggled.connect(func(_on: bool) -> void: _rebuild())
	bar.add_child(_only_seen)
	_count_label = UiStyle.label("", 12, UiStyle.MUTED)
	_count_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_count_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	bar.add_child(_count_label)
	# Rejilla | ficha.
	var split := HBoxContainer.new()
	split.add_theme_constant_override("separation", 12)
	box.add_child(split)
	var left := ScrollContainer.new()
	left.custom_minimum_size = Vector2(CELL.x * 5 + 40, 470)
	left.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	split.add_child(left)
	_grid = GridContainer.new()
	_grid.columns = 5
	_grid.add_theme_constant_override("h_separation", 6)
	_grid.add_theme_constant_override("v_separation", 6)
	left.add_child(_grid)
	var right_panel := PanelContainer.new()
	right_panel.add_theme_stylebox_override("panel", UiStyle.inset_style())
	right_panel.custom_minimum_size = Vector2(440, 470)
	split.add_child(right_panel)
	var right := VBoxContainer.new()
	right.add_theme_constant_override("separation", 6)
	right_panel.add_child(right)
	_big_icon = Control.new()
	_big_icon.custom_minimum_size = Vector2(96, 96)
	_big_icon.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_big_icon.draw.connect(_draw_big_icon)
	right.add_child(_big_icon)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	right.add_child(scroll)
	_detail = RichTextLabel.new()
	_detail.bbcode_enabled = true
	_detail.fit_content = true
	_detail.custom_minimum_size = Vector2(420, 0)
	_detail.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(_detail)
	visible = false
	_set_tab("boards")


func open() -> void:
	note_inventory(character)
	visible = true
	_rebuild()


# --- Lo encontrado ---

## Marca como encontrado (placa o RAM) lo que haya en el inventario, la barra y las ranuras.
static func note_inventory(c: CharacterData) -> void:
	if c == null:
		return
	for it in c.inventory.bag:
		note_item(c, it)
	for b in c.inventory.boards:
		note_item(c, b)
		if b:
			for r in (b as Motherboard).rams:
				note_item(c, r)


static func note_item(c: CharacterData, it: Variant) -> void:
	var id := ""
	if it is Motherboard:
		id = String((it as Motherboard).skill_def.get("id", ""))
	elif it is RamModule:
		id = String((it as RamModule).def.get("id", ""))
	if id == "":
		return
	if not c.flags.has("catalog_seen") or not (c.flags["catalog_seen"] is Dictionary):
		c.flags["catalog_seen"] = {}
	c.flags["catalog_seen"][id] = true


func is_seen(id: String) -> bool:
	if character == null:
		return false
	var seen = character.flags.get("catalog_seen", {})
	return seen is Dictionary and (seen as Dictionary).has(id)


# --- Lista ---

func _set_tab(tab: String) -> void:
	_tab = tab
	for k in _tab_buttons:
		_tab_buttons[k].button_pressed = k == tab
	_gen_filter.visible = tab == "rams"
	_selected = ""
	_rebuild()


## Ids de la pestaña actual que pasan la búsqueda y los filtros, en orden.
func entries() -> Array[String]:
	var source: Dictionary = _db.skills if _tab == "boards" else _db.rams
	var q := _search.text.strip_edges().to_lower() if _search else ""
	var out: Array[String] = []
	for id in source:
		var def: Dictionary = source[id]
		if _only_seen and _only_seen.button_pressed and not is_seen(id):
			continue
		if _tab == "rams" and _gen_filter and _gen_filter.selected > 0 and String(def.get("generation", "")) != _gen_filter.get_item_text(_gen_filter.selected):
			continue
		if q != "":
			var tag_text := " ".join(PackedStringArray(def.get("tags", [])))
			var hay: String = (String(def.get("name", "")) + " " + String(def.get("description", "")) + " " + tag_text + " " + id).to_lower()
			if _tab == "boards":
				hay += " " + SkillTags.plain(def.get("tags", [])).to_lower()
			if not hay.contains(q):
				continue
		out.append(id)
	if _tab == "rams":
		out.sort_custom(func(a: String, b: String) -> bool:
			var ga := String(source[a].get("generation", ""))
			var gb := String(source[b].get("generation", ""))
			return ga < gb if ga != gb else String(source[a]["name"]) < String(source[b]["name"]))
	else:
		out.sort_custom(func(a: String, b: String) -> bool: return String(source[a]["name"]) < String(source[b]["name"]))
	return out


func _rebuild() -> void:
	if _grid == null or _db == null:
		return
	for ch in _grid.get_children():
		ch.queue_free()
	var list := entries()
	var source: Dictionary = _db.skills if _tab == "boards" else _db.rams
	var seen := 0
	for id in source:
		if is_seen(id):
			seen += 1
	_count_label.text = "Encontradas: %d / %d" % [seen, source.size()]
	if _selected == "" or not list.has(_selected):
		_selected = list[0] if not list.is_empty() else ""
	for id in list:
		_grid.add_child(_make_cell(id, source[id]))
	_show_detail()


func _make_cell(id: String, def: Dictionary) -> Control:
	var b := Button.new()
	b.custom_minimum_size = CELL
	b.focus_mode = Control.FOCUS_NONE
	b.flat = true
	b.tooltip_text = String(def.get("name", id))
	b.pressed.connect(func() -> void:
		_selected = id
		for ch in _grid.get_children():
			ch.queue_redraw()
		_show_detail())
	b.draw.connect(func() -> void:
		var found := is_seen(id)
		var sel := id == _selected
		var r := Rect2(Vector2.ZERO, b.size)
		b.draw_rect(r, Color(0.16, 0.13, 0.2) if sel else Color(0.08, 0.07, 0.1))
		b.draw_rect(r, UiStyle.ACCENT if sel else Color("3a3442"), false, 2.0 if sel else 1.0)
		var icon := Rect2(Vector2((r.size.x - 56.0) / 2.0, 6.0), Vector2(56, 56))
		if _tab == "boards":
			SkillIcon.draw(b, icon, def, not found)
		else:
			RamIcon.draw_badge(b, icon.grow(-6.0), RamModule.new(def), found)
		var font := b.get_theme_default_font()
		var name_text := String(def.get("name", id))
		b.draw_multiline_string(font, Vector2(3, 74), name_text, HORIZONTAL_ALIGNMENT_CENTER, r.size.x - 6.0, 10, 2,
			UiStyle.TEXT if found else UiStyle.MUTED)
		if _tab == "rams":
			b.draw_string(font, Vector2(2, 108), String(def.get("generation", "")), HORIZONTAL_ALIGNMENT_CENTER, r.size.x - 4.0, 10,
				RamModule.GENERATION_COLORS.get(def.get("generation", ""), UiStyle.MUTED))
		if found:
			b.draw_string(font, Vector2(r.size.x - 14.0, 14.0), "✔", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color("6fd36b")))
	return b


# --- Ficha ---

func _draw_big_icon() -> void:
	if _selected == "":
		return
	var r := Rect2(Vector2.ZERO, _big_icon.size)
	if _tab == "boards":
		SkillIcon.draw(_big_icon, r, _db.skills[_selected], not is_seen(_selected))
	else:
		RamIcon.draw_badge(_big_icon, r.grow(-14.0), RamModule.new(_db.rams[_selected]), is_seen(_selected))


func _show_detail() -> void:
	_big_icon.queue_redraw()
	if _selected == "":
		_detail.text = "[center][color=#8a8293]Nada coincide con la búsqueda.[/color][/center]"
		return
	_detail.text = detail_text(_selected)


## Texto de la ficha (BBCode). Público para las pruebas.
func detail_text(id: String) -> String:
	var found := is_seen(id)
	var status := "[color=#6fd36b]✔ Encontrada[/color]" if found else "[color=#8a8293]Aún no encontrada[/color]"
	var t := ""
	if _tab == "boards":
		var def: Dictionary = _db.skills[id]
		var board := Motherboard.new(def, 1, [])
		t = ItemTooltip.build_text(board, character, false)
		var extra := PackedStringArray([status])
		extra.append("Tipo: [color=#e8d9b0]%s[/color]  ·  Daño: [color=#e8d9b0]%s[/color]" % [_kind_name(String(def.get("kind", ""))),
			RamModule.DAMAGE_TYPE_NAMES.get(def.get("damage_type", "none"), "sin daño").trim_prefix("de ")])
		extra.append("Cae desde el nivel de zona [color=#e8d9b0]%d[/color]" % int(def.get("min_level", def.get("level", 1))))
		var kits := _kits_with(id)
		if not kits.is_empty():
			extra.append("De serie con: [color=#d9a441]%s[/color]" % ", ".join(kits))
		var variants: Array = def.get("variants", [])
		if not variants.is_empty():
			var names := PackedStringArray()
			for v in variants:
				names.append("%s (nv. %d)" % [v.get("name", v.get("id", "")), int(v.get("level", 10))])
			extra.append("Variantes (menú K): " + ", ".join(names))
		var compatible := 0
		for rid in _db.rams:
			if RamModule.new(_db.rams[rid]).supports(def):
				compatible += 1
		extra.append("RAM compatibles: [color=#e8d9b0]%d[/color] de %d" % [compatible, _db.rams.size()])
		t += "\n[color=#3a3442]────────────────────[/color]\n" + "\n".join(extra)
	else:
		var def: Dictionary = _db.rams[id]
		var ram := RamModule.new(def)
		t = ItemTooltip.build_text(ram, character, false)
		var extra := PackedStringArray([status])
		extra.append("Grado: [color=#e8d9b0]%s[/color]  ·  Cae desde el nivel [color=#e8d9b0]%d[/color]" % [
			["", "menor", "normal", "mayor"][clampi(ram.tier(), 1, 3)], int(def.get("min_level", 1))])
		var works := PackedStringArray()
		for sid in _db.skills:
			if ram.supports(_db.skills[sid]):
				works.append(String(_db.skills[sid]["name"]))
		works.sort()
		extra.append("Funciona con %d placas: [color=#8a8293]%s[/color]" % [works.size(), ", ".join(works)])
		t += "\n[color=#3a3442]────────────────────[/color]\n" + "\n".join(extra)
	return t


func _kits_with(skill_id: String) -> PackedStringArray:
	var out := PackedStringArray()
	var data = DataLoader.load_json("res://data/classes.json")
	for c in (data.get("classes", []) if data is Dictionary else []):
		if skill_id in c.get("starter_skills", []):
			out.append(String(c.get("name", c.get("id", ""))))
	return out


static func _kind_name(kind: String) -> String:
	return {"projectile": "proyectil", "chain": "cadena", "nova": "nova", "ground_aoe": "área en el suelo", "melee_area": "cuerpo a cuerpo",
		"minion": "esbirros", "trap": "trampa", "drones": "drones", "aura": "aura", "unit": "invocación persistente", "buff": "potenciador",
		"barrier": "barrera", "blink": "movimiento", "dash": "carga", "leap_slam": "salto", "spin": "giro", "rain": "lluvia",
		"beam": "rayo", "boomerang": "bumerán", "homing": "teledirigido", "cone": "cono", "degen_area": "charco",
		"curse_area": "maldición", "dot_projectile": "proyectil degenerativo",
		"ssh": "teletransporte con descarga", "charge": "carga con empuje", "backflip": "salto atrás"}.get(kind, kind)
