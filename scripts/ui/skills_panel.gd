class_name SkillsPanel
extends PanelContainer
## Menú de habilidades (K): las 6 placas base de la barra con sus ranuras DIMM,
## y las placas y módulos RAM que hay en la bolsa.
##
## Arrastrar y soltar: placas a la barra (o entre filas para cambiar la tecla),
## RAM a una ranura de su generación, y cualquier cosa de vuelta a la bolsa.
## También con clicks: placa de la bolsa → primera fila libre; RAM → seleccionar
## y click en una ranura (doble click: primera ranura compatible); RAM instalada
## → a la bolsa; click derecho en una placa instalada → a la bolsa.

signal message(text: String)
signal drop_to_ground(location: Dictionary)
signal close_requested

const DIMM_SIZE := Vector2(34, 50)
const ROW_HEIGHT := 58.0
const ATTRIBUTE_COLORS := {"str": Color("c84b4b"), "dex": Color("5cb85c"), "int": Color("4b8bd6")}

var character: CharacterData
var _tooltip: ItemTooltip
var _rows: VBoxContainer
var _bag_box: VBoxContainer
var _hint: Label
var _filter: OptionButton
var _selected_ram := -1  # índice en la bolsa de la RAM seleccionada

const FILTERS := ["Todo", "Ataques", "Hechizos", "Invocaciones", "Auras", "RAM que encajan"]

const HINT := "Arrastra placas a la barra y RAM a una ranura de su color; a la bolsa para quitar. Click en una RAM: se marcan en verde las ranuras donde funciona (doble click: a la primera)."


func setup(p_character: CharacterData, tooltip: ItemTooltip) -> void:
	character = p_character
	_tooltip = tooltip
	character.inventory.changed.connect(_rebuild)
	_rebuild()


func _ready() -> void:
	theme = UiStyle.make_theme()
	UiStyle.decorate_window(self)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	add_child(box)
	box.add_child(UiStyle.window_header("Habilidades", "Placas base (habilidades) y módulos RAM (soportes)  ·  K para cerrar",
		func() -> void: close_requested.emit()))
	_hint = UiStyle.label(HINT, 11, UiStyle.MUTED)
	_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_hint.custom_minimum_size.x = 640
	box.add_child(_hint)
	_rows = VBoxContainer.new()
	_rows.add_theme_constant_override("separation", 6)
	# Las 6 placas se desplazan si la ventana no cabe (interfaz grande).
	var rows_scroll := FitScroll.new(self)
	box.add_child(rows_scroll)
	rows_scroll.add_child(_rows)
	var bag_title := HBoxContainer.new()
	box.add_child(bag_title)
	var header := UiStyle.section_header("En la bolsa  (suelta aquí para desinstalar)")
	header.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bag_title.add_child(header)
	_filter = OptionButton.new()
	for f in FILTERS:
		_filter.add_item(f)
	_filter.focus_mode = Control.FOCUS_NONE
	_filter.custom_minimum_size = Vector2(170, 28)
	_filter.tooltip_text = "Qué se ve en la bolsa: por tipo de habilidad, o solo las RAM que funcionan con alguna placa instalada."
	_filter.item_selected.connect(func(_i: int) -> void: _rebuild())
	bag_title.add_child(_filter)
	var sort := UiStyle.button("Ordenar", _sort_bag)
	sort.custom_minimum_size = Vector2(90, 28)
	sort.tooltip_text = "Ordena las placas y las RAM de la bolsa: placas por nombre y nivel; RAM por generación, tipo y grado."
	bag_title.add_child(sort)
	var bag_drop := _BagDropZone.new()
	bag_drop.panel = self
	bag_drop.custom_minimum_size = Vector2(640, 52)
	box.add_child(bag_drop)
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(640, 110)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.mouse_filter = Control.MOUSE_FILTER_PASS
	bag_drop.add_child(scroll)
	_bag_box = VBoxContainer.new()
	_bag_box.add_theme_constant_override("separation", 4)
	_bag_box.mouse_filter = Control.MOUSE_FILTER_PASS
	_bag_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(_bag_box)
	if character:
		_rebuild()


func _rebuild() -> void:
	if _rows == null or character == null:
		return
	for c in _rows.get_children() + _bag_box.get_children():
		c.get_parent().remove_child(c)
		c.queue_free()
	if _selected_ram != -1 and not character.inventory.bag[_selected_ram] is RamModule:
		_selected_ram = -1
	for i in Inventory.HOTBAR_SIZE:
		_rows.add_child(_make_row(i))
	# Bolsa agrupada: placas, y RAM por generación (cada grupo ordenado).
	var groups := {"Placas base": [], "RAM DDR3": [], "RAM DDR4": [], "RAM DDR5": []}
	for i in Inventory.BAG_SIZE:
		var item: Item = character.inventory.bag[i]
		if not _passes_filter(item):
			continue
		if item is Motherboard:
			groups["Placas base"].append(i)
		elif item is RamModule:
			groups["RAM " + (item as RamModule).generation()].append(i)
	var any := false
	for title in groups:
		var ids: Array = groups[title]
		if ids.is_empty():
			continue
		any = true
		ids.sort_custom(func(a: int, b: int) -> bool:
			return Inventory.skill_item_key(character.inventory.bag[a]) < Inventory.skill_item_key(character.inventory.bag[b]))
		var line := HBoxContainer.new()
		line.add_theme_constant_override("separation", 8)
		line.mouse_filter = Control.MOUSE_FILTER_PASS
		var gen: String = String(title).trim_prefix("RAM ")
		var label := UiStyle.label("%s (%d)" % [title, ids.size()], 12, RamModule.GENERATION_COLORS.get(gen, Motherboard.COLOR).lightened(0.2))
		label.custom_minimum_size.x = 104
		label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		line.add_child(label)
		var flow := HFlowContainer.new()
		flow.add_theme_constant_override("h_separation", 4)
		flow.add_theme_constant_override("v_separation", 4)
		flow.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		flow.mouse_filter = Control.MOUSE_FILTER_PASS
		for i in ids:
			flow.add_child(_make_bag_cell(i))
		line.add_child(flow)
		_bag_box.add_child(line)
	if not any:
		var empty := UiStyle.label("No tienes placas ni RAM sueltas. Mata cosas; algo caerá.", 13, UiStyle.MUTED)
		empty.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_bag_box.add_child(empty)
	_update_hint()


## Filtro de la bolsa (ver FILTERS). Lo que no es placa ni RAM nunca se muestra.
func _passes_filter(item: Item) -> bool:
	if not (item is Motherboard or item is RamModule):
		return false
	var f: String = FILTERS[_filter.selected] if _filter and _filter.selected >= 0 else "Todo"
	if f == "Todo":
		return true
	if f == "RAM que encajan":
		if not item is RamModule:
			return false
		for b in character.inventory.boards:
			if b and (item as RamModule).supports(b.skill_def):
				return true
		return false
	if not item is Motherboard:
		return true   # los filtros por tipo de habilidad dejan ver todas las RAM
	var def: Dictionary = (item as Motherboard).skill_def
	var tags: Array = def.get("tags", [])
	match f:
		"Ataques":
			return tags.has("attack") and not def["kind"] in ["unit", "aura"]
		"Hechizos":
			return tags.has("spell") and not def["kind"] in ["unit", "aura", "minion", "drones"]
		"Invocaciones":
			return def["kind"] in ["unit", "minion", "drones"] or tags.has("totem")
		"Auras":
			return def["kind"] == "aura"
	return true


func _sort_bag() -> void:
	_selected_ram = -1
	character.inventory.sort_skill_items()


## Con una RAM seleccionada, el texto de ayuda dice en qué placas funciona.
func _update_hint() -> void:
	if _hint == null:
		return
	var ram: RamModule = character.inventory.bag[_selected_ram] if _selected_ram != -1 else null
	if ram == null:
		_hint.text = HINT
		_hint.add_theme_color_override("font_color", UiStyle.MUTED)
		return
	var fits := PackedStringArray()
	for b in character.inventory.boards:
		if b and ram.supports(b.skill_def):
			fits.append(b.skill_def["name"])
	_hint.text = "%s: %s" % [ram.display_name(), ("funciona con " + ", ".join(fits)) if not fits.is_empty() else "no funciona con ninguna de tus placas instaladas"]
	_hint.add_theme_color_override("font_color", Color("8fe08a") if not fits.is_empty() else Color("e06c6c"))


func _make_row(index: int) -> Control:
	var board: Motherboard = character.inventory.boards[index]
	var card := PanelContainer.new()
	var accent: Color = ATTRIBUTE_COLORS.get(board.skill_def.get("attribute", ""), UiStyle.BORDER) if board else Color("2e2836")
	var style := UiStyle.inset_style(accent.darkened(0.35) if board else Color("2a2530"))
	style.border_width_left = 4 if board else 1
	style.content_margin_top = 4
	style.content_margin_bottom = 4
	card.add_theme_stylebox_override("panel", style)
	var row := HBoxContainer.new()
	row.custom_minimum_size.y = ROW_HEIGHT
	row.add_theme_constant_override("separation", 8)
	card.add_child(row)

	var key := UiStyle.label(SkillController.KEY_LABELS[index], 15, UiStyle.ACCENT)
	key.custom_minimum_size.x = 34
	key.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	row.add_child(key)

	var icon := _make_cell({"kind": "board", "index": index})
	icon.show_skill_icon = true
	icon.placeholder = "Vacía"
	icon.placeholder_icon = "motherboard"
	icon.custom_minimum_size = Vector2(ROW_HEIGHT, ROW_HEIGHT)
	row.add_child(icon)

	# Nombre, nivel, experiencia y etiquetas.
	var info := VBoxContainer.new()
	info.custom_minimum_size.x = 230
	info.add_theme_constant_override("separation", 1)
	row.add_child(info)
	if board:
		var title := UiStyle.label("%s  ·  nv. %d" % [board.skill_def["name"], board.level], 15, Motherboard.COLOR.lightened(0.2))
		title.clip_text = true
		info.add_child(title)
		var xp := Control.new()
		xp.custom_minimum_size = Vector2(220, 6)
		xp.tooltip_text = "Experiencia de la placa: %d / %d (sube matando con ella instalada)" % [board.experience, board.experience_to_next()]
		xp.mouse_filter = Control.MOUSE_FILTER_PASS
		xp.draw.connect(func() -> void:
			var frac: float = float(board.experience) / maxf(1.0, board.experience_to_next())
			xp.draw_rect(Rect2(Vector2.ZERO, xp.size), Color(0, 0, 0, 0.7))
			xp.draw_rect(Rect2(Vector2.ZERO, Vector2(xp.size.x * frac, xp.size.y)), Motherboard.COLOR)
			xp.draw_rect(Rect2(Vector2.ZERO, xp.size), Color(UiStyle.GOLD, 0.4), false, 1.0))
		info.add_child(xp)
		var tags := RichTextLabel.new()
		tags.bbcode_enabled = true
		tags.fit_content = true
		tags.scroll_active = false
		tags.custom_minimum_size.x = 230
		tags.mouse_filter = Control.MOUSE_FILTER_IGNORE
		tags.add_theme_font_size_override("normal_font_size", 11)
		tags.text = SkillTags.bbcode(board.skill_def.get("tags", []))
		info.add_child(tags)
		info.add_child(_stats_label(board))
		# Variantes: botón que alterna entre la normal y las desbloqueadas por nivel de placa.
		if not board.variants().is_empty():
			var v := board.active_variant()
			var next_locked: Array = board.variants().filter(func(x: Dictionary) -> bool: return board.level < int(x.get("min_level", 1)))
			var vb := UiStyle.button("Variante: %s" % v.get("name", "Normal"), func() -> void:
				board.cycle_variant()
				character.recalculate()
				_rebuild(), 230)
			vb.custom_minimum_size.y = 22
			vb.add_theme_font_size_override("font_size", 11)
			var lines := PackedStringArray(["Click: cambiar de variante."])
			for x in board.variants():
				lines.append("• %s (nv. %d de placa): %s" % [x["name"], int(x.get("min_level", 1)), x.get("description", "")])
			vb.tooltip_text = "\n".join(lines)
			vb.disabled = next_locked.size() == board.variants().size()
			info.add_child(vb)
	else:
		info.alignment = BoxContainer.ALIGNMENT_CENTER
		info.add_child(UiStyle.label("Arrastra aquí una placa base", 13, UiStyle.MUTED))

	if board:
		for d in board.slots.size():
			var dimm := _make_cell({"kind": "dimm", "board": index, "dimm": d})
			dimm.slot_color = RamModule.GENERATION_COLORS[board.slots[d]]
			dimm.placeholder = board.slots[d]
			dimm.dimm_socket = true
			dimm.custom_minimum_size = DIMM_SIZE
			var ram: RamModule = board.rams[d]
			dimm.warning = ram != null and not ram.supports(board.skill_def)
			if dimm.warning:
				dimm.tooltip_text = "Esta RAM no funciona con %s: está instalada pero no hace nada." % board.skill_def["name"]
			var selected: RamModule = character.inventory.bag[_selected_ram] if _selected_ram != -1 else null
			if selected != null and ram == null and selected.generation() == board.slots[d]:
				# Verde: aquí funciona. Rojo: encaja (mismo color) pero no haría nada.
				dimm.selected = selected.supports(board.skill_def)
				dimm.warning = not dimm.selected
			row.add_child(dimm)
	return card


## "DPS ~120 · maná 14 · 3 proyectiles · RAM activas 2/3" bajo las etiquetas.
func _stats_label(board: Motherboard) -> Label:
	var p := SkillCalc.compute(board, character)
	var parts := PackedStringArray()
	if p["dps"] > 0.0:
		parts.append("DPS ~%s" % _short(p["dps"]))
	if p["kind"] in SkillController.CHANNEL_KINDS:
		parts.append("maná %d/s" % int(p["mana_cost"]))
	else:
		parts.append("maná %d" % int(p["mana_cost"]) if p["kind"] not in ["unit", "aura"] else "reserva %d %%" % roundi(p["reserve"]))
	if p["projectiles"] > 1:
		parts.append("%d proyectiles%s" % [p["projectiles"], " teledirigidos" if p["homing"] else ""])
	var installed := 0
	for ram in board.rams:
		if ram != null:
			installed += 1
	if installed > 0:
		parts.append("RAM activas %d/%d" % [board.active_supports().size(), installed])
	var text := "  ·  ".join(parts)
	if SkillController.trigger_text(p) != "":
		text += "\nAUTO: se lanza sola " + SkillController.trigger_text(p)
	var color := Color("b8ab90")
	# Comparación: con una RAM seleccionada, cuánto cambiaría el DPS al instalarla.
	var ram: RamModule = character.inventory.bag[_selected_ram] if _selected_ram != -1 else null
	if ram and ram.supports(board.skill_def) and p["dps"] > 0.0:
		var slot := board.free_slot_for(ram)
		if slot == -1:
			text += "\nCon %s: no hay ranura %s libre" % [ram.def.get("name", "la RAM"), ram.generation()]
		else:
			var trial := Motherboard.new(board.skill_def, board.level, board.slots)
			trial.rams = board.rams.duplicate()
			trial.install(ram, slot)
			var after: float = SkillCalc.compute(trial, character)["dps"]
			var delta: float = (after / float(p["dps"]) - 1.0) * 100.0
			text += "\nCon %s: DPS ~%s → ~%s (%+.0f %%)" % [ram.def.get("name", "la RAM"), _short(p["dps"]), _short(after), delta]
			color = Color("8fe08a") if delta >= 0.0 else Color("e0a060")
	var l := UiStyle.label(text, 11, color)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l


static func _short(v: float) -> String:
	return "%.1fk" % (v / 1000.0) if v >= 10000.0 else str(roundi(v))

func _make_bag_cell(bag_index: int) -> ItemCell:
	var cell := _make_cell({"kind": "bag", "index": bag_index})
	cell.custom_minimum_size = Vector2(44, 44)
	cell.show_skill_icon = true   # las placas, con el icono de su habilidad
	cell.selected = bag_index == _selected_ram
	return cell


func _make_cell(location: Dictionary) -> ItemCell:
	var cell := ItemCell.new()
	cell.location = location
	cell.set_item(ItemTransfer.get_at(character.inventory, location))
	cell.clicked.connect(_on_cell_clicked)
	cell.hovered.connect(func(c: ItemCell, inside: bool) -> void:
		if inside and c.item:
			_tooltip.show_item(c.item, character, false)
		else:
			_tooltip.hide())
	cell.dropped.connect(func(target: ItemCell, payload: Dictionary) -> void: _move(payload["from"], target.location))
	cell.released_outside.connect(func(c: ItemCell) -> void: drop_to_ground.emit(c.location))
	return cell


func _move(from: Dictionary, to: Dictionary) -> void:
	_tooltip.hide()
	var problem := ItemTransfer.move(character, from, to)
	if problem != "":
		message.emit(problem)
	else:
		_selected_ram = -1
		_rebuild()


## Soltar en la zona de la bolsa: al primer hueco libre.
func drop_into_bag(from: Dictionary) -> void:
	if from.get("kind", "") == "bag":
		return
	var free := character.inventory.free_bag_index()
	if free == -1:
		message.emit("Inventario lleno. Como tu backlog.")
		return
	_move(from, {"kind": "bag", "index": free})


func _on_cell_clicked(cell: ItemCell, button: MouseButton) -> void:
	var loc := cell.location
	match loc["kind"]:
		"bag":
			if button == MOUSE_BUTTON_LEFT and cell.item:
				_on_bag_clicked(loc["index"])
		"board":
			if button == MOUSE_BUTTON_RIGHT and cell.item:
				drop_into_bag(loc)
		"dimm":
			if button != MOUSE_BUTTON_LEFT:
				return
			if cell.item:
				drop_into_bag(loc)
			elif _selected_ram == -1:
				message.emit("Selecciona primero un módulo RAM de la bolsa (o arrástralo aquí).")
			else:
				_move({"kind": "bag", "index": _selected_ram}, loc)


func _on_bag_clicked(bag_index: int) -> void:
	var item: Item = character.inventory.bag[bag_index]
	if item is Motherboard:
		if not character.inventory.install_board(bag_index):
			message.emit("La barra está llena. Arrastra la placa sobre otra para cambiarlas.")
	elif item is RamModule:
		if _selected_ram == bag_index:
			# Segundo click: a la primera ranura compatible de cualquier placa.
			for i in Inventory.HOTBAR_SIZE:
				if character.inventory.boards[i] and character.inventory.boards[i].free_slot_for(item) != -1:
					character.inventory.install_ram(bag_index, i)
					_selected_ram = -1
					return
			message.emit("Ninguna placa tiene ranuras %s libres." % (item as RamModule).generation())
		else:
			_selected_ram = bag_index
			_rebuild()


## Zona de la bolsa que acepta lo que se suelte encima (para desinstalar).
class _BagDropZone extends PanelContainer:
	var panel: SkillsPanel

	func _ready() -> void:
		var style := StyleBoxFlat.new()
		style.bg_color = Color(0, 0, 0, 0.25)
		style.border_color = UiStyle.BORDER
		style.set_border_width_all(1)
		add_theme_stylebox_override("panel", style)

	func _can_drop_data(_at: Vector2, data: Variant) -> bool:
		return data is Dictionary and data.has("from") and data["from"].get("kind", "") != "bag"

	func _drop_data(_at: Vector2, data: Variant) -> void:
		panel.drop_into_bag(data["from"])
