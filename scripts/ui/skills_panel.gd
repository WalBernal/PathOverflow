class_name SkillsPanel
extends PanelContainer
## Menú de habilidades (K), rehecho en T229 con la propuesta «placa a placa» y el
## veredicto de «RAM primero» (docs/habilidades_ui_propuesta.md):
##   izquierda · las 6 placas de la barra (tocar = elegir);
##   centro    · la placa elegida en grande: cada ranura como tarjeta con su RAM y qué
##               hace, y botones visibles para quitar, cambiar de tecla, variante...;
##   derecha   · pestañas «Encajan aquí» (con su veredicto y «Instalar»), «Todas las
##               RAM» (en qué placas funciona cada una y cuánto mejora) y «Placas».
## Todo se hace con toques; en PC sigue funcionando arrastrar y soltar (y la bolsa de la
## derecha acepta lo que se suelte para desinstalarlo).

signal message(text: String)
signal drop_to_ground(location: Dictionary)
signal close_requested

const ATTRIBUTE_COLORS := {"str": Color("c84b4b"), "dex": Color("5cb85c"), "int": Color("4b8bd6")}
const STEPS := "1 · Elige una placa   2 · Toca una RAM que encaje   3 · Instalar"
const OK_COLOR := Color("8fe08a")
const BAD_COLOR := Color("e06c6c")
const SWAP_COLOR := Color("e0c060")

var character: CharacterData
var _tooltip: ItemTooltip
var _sel_board := 0
var _sel_slot := -1
var _selected_ram := -1   # índice en la bolsa de la RAM elegida
var _tab := "fits"        # fits | all | boards
var _left: VBoxContainer
var _center: VBoxContainer
var _right: VBoxContainer
var _help: Label
var _compact := false


static func _big() -> bool:
	return Touch.shown()


static func _tile() -> float:
	return 70.0 if _big() else 58.0


static func _btn_h() -> float:
	return 48.0 if _big() else 32.0


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
	_help = UiStyle.label(STEPS, 14, UiStyle.MUTED)
	box.add_child(_help)
	var body := HBoxContainer.new()
	body.add_theme_constant_override("separation", 12)
	_left = VBoxContainer.new()
	_left.add_theme_constant_override("separation", 6)
	_left.custom_minimum_size.x = 250
	body.add_child(_left)
	var center_card := PanelContainer.new()
	center_card.add_theme_stylebox_override("panel", UiStyle.inset_style())
	center_card.custom_minimum_size.x = 470
	body.add_child(center_card)
	_center = VBoxContainer.new()
	_center.add_theme_constant_override("separation", 10)
	center_card.add_child(_center)
	var right_card := _BagDropZone.new()
	right_card.panel = self
	right_card.custom_minimum_size.x = 330
	body.add_child(right_card)
	_right = VBoxContainer.new()
	_right.add_theme_constant_override("separation", 6)
	right_card.add_child(_right)
	var scroll := FitScroll.new(self)
	scroll.add_child(body)
	box.add_child(scroll)
	if character:
		_rebuild()


func _clear(c: Control) -> void:
	for ch in c.get_children():
		c.remove_child(ch)
		ch.queue_free()


func _rebuild() -> void:
	if _left == null or character == null:
		return
	if _selected_ram != -1 and not character.inventory.bag[_selected_ram] is RamModule:
		_selected_ram = -1
	var board := _board()
	if board == null or _sel_slot >= board.slots.size():
		_sel_slot = -1
	_clear(_left)
	_clear(_center)
	_clear(_right)
	# Sin sitio para las tres columnas (interfaz grande en PC), las placas van compactas.
	_compact = is_inside_tree() and get_parent_area_size().x > 0.0 and get_parent_area_size().x < 1250.0
	_left.custom_minimum_size.x = 104.0 if _compact else 250.0
	for i in Inventory.HOTBAR_SIZE:
		_left.add_child(_board_card(i))
	_build_center()
	_build_right()
	_update_help()


func _board() -> Motherboard:
	return character.inventory.boards[_sel_board]


func _selected() -> RamModule:
	return character.inventory.bag[_selected_ram] if _selected_ram != -1 else null


func _update_help() -> void:
	var ram := _selected()
	if _comparing:
		_help.text = "Comparar: toca dos placas (de la izquierda o de la pestaña «Placas»)."
		_help.add_theme_color_override("font_color", UiStyle.GOLD)
	elif ram:
		_help.text = "%s elegida: toca una ranura %s de la placa, o «Instalar» en la lista." % [ram.display_name(), ram.generation()]
		_help.add_theme_color_override("font_color", OK_COLOR)
	else:
		_help.text = STEPS + ("" if _big() else "      ·  PC: también puedes arrastrar y soltar")
		_help.add_theme_color_override("font_color", UiStyle.MUTED)


# --- Izquierda: las 6 placas ---

func _board_card(index: int) -> Control:
	var board: Motherboard = character.inventory.boards[index]
	var card := PanelContainer.new()
	var sel := index == _sel_board
	var accent: Color = ATTRIBUTE_COLORS.get(board.skill_def.get("attribute", ""), UiStyle.BORDER) if board else Color("2e2836")
	var style := UiStyle.inset_style(UiStyle.ACCENT if sel else accent.darkened(0.35))
	style.border_width_left = 4
	if sel:
		style.set_border_width_all(2)
		style.border_width_left = 5
		style.bg_color = style.bg_color.lightened(0.06)
	card.add_theme_stylebox_override("panel", style)
	card.mouse_filter = Control.MOUSE_FILTER_STOP
	card.gui_input.connect(func(e: InputEvent) -> void:
		if _tapped(e):
			_on_board_tapped(index))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(row)
	var key := UiStyle.label(Controls.key_label(SkillController.ACTIONS[index]) if not _big() else str(index + 1), 15, UiStyle.ACCENT)
	key.custom_minimum_size.x = 26
	key.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	key.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(key)
	var icon := _make_cell({"kind": "board", "index": index})
	icon.show_skill_icon = true
	icon.placeholder = "Vacía"
	icon.placeholder_icon = "motherboard"
	icon.custom_minimum_size = Vector2(_tile(), _tile())
	row.add_child(icon)
	var info := VBoxContainer.new()
	info.alignment = BoxContainer.ALIGNMENT_CENTER
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(info)
	if _compact:
		info.visible = false
		card.tooltip_text = board.skill_def["name"] if board else "Vacía"
	var name_label := UiStyle.label(board.skill_def["name"] if board else "Vacía", 14, UiStyle.TEXT if board else UiStyle.MUTED)
	name_label.clip_text = true
	name_label.custom_minimum_size.x = 130
	name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	info.add_child(name_label)
	if board:
		var dots := Control.new()
		dots.custom_minimum_size = Vector2(150, 14)
		dots.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var ram := _selected()
		var v := SkillAdvice.verdict(ram, board, character) if ram else {}
		dots.draw.connect(func() -> void:
			for k in board.slots.size():
				var c: Color = RamModule.GENERATION_COLORS[board.slots[k]]
				var r := Rect2(k * 18, 1, 13, 13)
				if board.rams[k] != null:
					dots.draw_rect(r, c)
				dots.draw_rect(r, c, false, 2.0)
			if not v.is_empty() and String(v["kind"]) != SkillAdvice.NONE:
				var good := SkillAdvice.good(v)
				dots.draw_string(get_theme_default_font(), Vector2(board.slots.size() * 18 + 4, 12), "✓" if good else "✕", HORIZONTAL_ALIGNMENT_LEFT, -1, 13,
					OK_COLOR if good else BAD_COLOR))
		info.add_child(dots)
	return card


func _on_board_tapped(index: int) -> void:
	var board: Motherboard = character.inventory.boards[index]
	if _comparing and board:
		_pick_compare(board)
		return
	_sel_board = index
	_sel_slot = -1
	_rebuild()


static func _tapped(e: InputEvent) -> bool:
	var mb := e as InputEventMouseButton
	if mb and mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT:
		return true
	var st := e as InputEventScreenTouch
	return st != null and st.pressed


# --- Centro: la placa elegida ---

func _build_center() -> void:
	var board := _board()
	var key_name := Controls.key_label(SkillController.ACTIONS[_sel_board]) if not _big() else "tecla %d" % (_sel_board + 1)
	if board == null:
		_center.add_child(UiStyle.label("La %s está vacía." % key_name, 20, UiStyle.ACCENT))
		var l := UiStyle.label("Elige una placa en la pestaña «Placas» de la derecha%s." % ("" if _big() else " (o arrástrala sobre la casilla de la izquierda)"), 14, UiStyle.MUTED)
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_center.add_child(l)
		return
	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", 14)
	_center.add_child(top)
	var icon := _make_cell({"kind": "board", "index": _sel_board})
	icon.show_skill_icon = true
	icon.custom_minimum_size = Vector2(92, 92)
	top.add_child(icon)
	var info := VBoxContainer.new()
	info.add_theme_constant_override("separation", 3)
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(info)
	info.add_child(UiStyle.label("%s  ·  nv. %d  ·  %s" % [board.skill_def["name"], board.level, key_name], 19, Motherboard.COLOR.lightened(0.25)))
	var xp := Control.new()
	xp.custom_minimum_size = Vector2(300, 6)
	xp.tooltip_text = "Experiencia de la placa: %d / %d (sube matando con ella instalada)" % [board.experience, board.experience_to_next()]
	xp.draw.connect(func() -> void:
		var frac: float = float(board.experience) / maxf(1.0, board.experience_to_next())
		xp.draw_rect(Rect2(Vector2.ZERO, xp.size), Color(0, 0, 0, 0.7))
		xp.draw_rect(Rect2(Vector2.ZERO, Vector2(xp.size.x * frac, xp.size.y)), Motherboard.COLOR))
	info.add_child(xp)
	var tags := RichTextLabel.new()
	tags.bbcode_enabled = true
	tags.fit_content = true
	tags.scroll_active = false
	tags.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tags.add_theme_font_size_override("normal_font_size", 12)
	tags.text = SkillTags.bbcode(board.skill_def.get("tags", []))
	info.add_child(tags)
	info.add_child(_stats_label(board))
	# Ranuras: cada una como tarjeta con su RAM y lo que hace.
	var slots := HFlowContainer.new()
	slots.add_theme_constant_override("h_separation", 8)
	slots.add_theme_constant_override("v_separation", 8)
	_center.add_child(slots)
	var ram_sel := _selected()
	for d in board.slots.size():
		slots.add_child(_slot_card(board, d, ram_sel))
	# Acciones de la placa, siempre a la vista.
	var actions := HFlowContainer.new()
	actions.add_theme_constant_override("h_separation", 6)
	actions.add_theme_constant_override("v_separation", 6)
	_center.add_child(actions)
	var has_ram := _sel_slot != -1 and board.rams[_sel_slot] != null
	actions.add_child(_action("Quitar RAM", func() -> void:
		drop_into_bag({"kind": "dimm", "board": _sel_board, "dimm": _sel_slot}), not has_ram,
		"Elige primero una ranura con RAM." if not has_ram else "Devuelve la RAM de la ranura %d a la bolsa." % (_sel_slot + 1)))
	actions.add_child(_action("◀ Tecla", _move_key.bind(-1), _sel_board == 0, "Cambia esta placa con la de la tecla anterior."))
	actions.add_child(_action("Tecla ▶", _move_key.bind(1), _sel_board == Inventory.HOTBAR_SIZE - 1, "Cambia esta placa con la de la tecla siguiente."))
	if not board.variants().is_empty():
		var v := board.active_variant()
		var locked: Array = board.variants().filter(func(x: Dictionary) -> bool: return board.level < int(x.get("min_level", 1)))
		var lines := PackedStringArray(["Cambia de variante."])
		for x in board.variants():
			lines.append("• %s (nv. %d de placa): %s" % [x["name"], int(x.get("min_level", 1)), x.get("description", "")])
		actions.add_child(_action("Variante: %s" % v.get("name", "Normal"), func() -> void:
			board.cycle_variant()
			character.recalculate()
			_rebuild(), locked.size() == board.variants().size(), "\n".join(lines)))
	actions.add_child(_action("Quitar placa", func() -> void: drop_into_bag({"kind": "board", "index": _sel_board}), false, "Devuelve la placa (con sus RAM) a la bolsa."))
	_compare_button = _action("Cancelar" if _comparing else "Comparar", _toggle_compare, false,
		"Toca aquí y luego dos placas: las ves lado a lado con su DPS, coste y área.")
	actions.add_child(_compare_button)
	actions.add_child(_action("Construcciones", _open_builds, false, "Guarda tu árbol pasivo y tu barra de habilidades, y cámbiate entre construcciones guardadas."))


func _action(text: String, cb: Callable, disabled := false, tip := "") -> Button:
	var b := UiStyle.button(text, cb)
	b.custom_minimum_size.y = _btn_h()
	b.disabled = disabled
	b.tooltip_text = tip
	return b


## Ancho de cada tarjeta de ranura: todas en una fila (hasta 7 ranuras) dentro del centro.
func _slot_w(board: Motherboard) -> float:
	return clampf((410.0 - 8.0 * (board.slots.size() - 1)) / board.slots.size(), 56.0, 108.0)


func _slot_card(board: Motherboard, d: int, ram_sel: RamModule) -> Control:
	var gen := String(board.slots[d])
	var col: Color = RamModule.GENERATION_COLORS[gen]
	var ram: RamModule = board.rams[d]
	var card := PanelContainer.new()
	var style := UiStyle.inset_style(col.darkened(0.2))
	style.bg_color = Color(col, 0.10)
	style.content_margin_left = 6   # el margen del recuadro no deja caber 5 ranuras en una fila
	style.content_margin_right = 6
	if d == _sel_slot:
		style.set_border_width_all(3)
		style.border_color = UiStyle.ACCENT
	card.add_theme_stylebox_override("panel", style)
	card.custom_minimum_size = Vector2(_slot_w(board), 0)
	var col_box := VBoxContainer.new()
	col_box.add_theme_constant_override("separation", 3)
	card.add_child(col_box)
	var head := UiStyle.label("%s · %d" % [gen, d + 1], 11, col.lightened(0.35))
	head.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col_box.add_child(head)
	var cell := _make_cell({"kind": "dimm", "board": _sel_board, "dimm": d})
	cell.slot_color = col
	cell.placeholder = gen
	cell.dimm_socket = true
	var tile := minf(_tile(), _slot_w(board) - 34.0)   # con muchas ranuras, casillas más chicas
	cell.custom_minimum_size = Vector2(tile, tile)
	cell.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	cell.selected = d == _sel_slot
	cell.warning = ram != null and not ram.supports(board.skill_def)
	if ram_sel != null and ram == null and ram_sel.generation() == gen:
		cell.selected = ram_sel.supports(board.skill_def)   # verde: aquí funciona
		cell.warning = not cell.selected                   # encaja pero no haría nada
	col_box.add_child(cell)
	var name_text := ram.display_name() if ram else "libre"
	var name_label := UiStyle.label(name_text.trim_suffix(" (%s)" % gen), 11, UiStyle.TEXT if ram else UiStyle.MUTED)
	name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.custom_minimum_size.x = card.custom_minimum_size.x - 12
	col_box.add_child(name_label)
	if ram:
		var eff := UiStyle.label(SkillAdvice.short_effect(ram) if ram.supports(board.skill_def) else "No funciona con esta habilidad.", 10,
			UiStyle.MUTED if ram.supports(board.skill_def) else BAD_COLOR)
		eff.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		eff.custom_minimum_size.x = card.custom_minimum_size.x - 12
		eff.max_lines_visible = 3
		col_box.add_child(eff)
	return card


## "DPS ~120 · maná 14 · 3 proyectiles · RAM activas 2/3" (y, con una RAM elegida, el cambio).
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
	var ram := _selected()
	if ram:
		var v := SkillAdvice.verdict(ram, board, character)
		text += "\nCon %s: %s" % [ram.def.get("name", "la RAM"), v["text"]]
		color = OK_COLOR if SkillAdvice.good(v) else (SWAP_COLOR if String(v["kind"]) == SkillAdvice.SWAP else BAD_COLOR)
	var l := UiStyle.label(text, 12, color)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART   # si no, ensancha la columna central
	l.custom_minimum_size.x = 320
	return l


static func _short(v: float) -> String:
	return "%.1fk" % (v / 1000.0) if v >= 10000.0 else str(roundi(v))


func _move_key(step: int) -> void:
	var to := clampi(_sel_board + step, 0, Inventory.HOTBAR_SIZE - 1)
	if to == _sel_board:
		return
	var problem := ItemTransfer.move(character, {"kind": "board", "index": _sel_board}, {"kind": "board", "index": to})
	if problem != "":
		message.emit(problem)
		return
	_sel_board = to
	_rebuild()


# --- Derecha: RAM y placas de la bolsa ---

func _build_right() -> void:
	var tabs := HBoxContainer.new()
	tabs.add_theme_constant_override("separation", 6)
	_right.add_child(tabs)
	for t in [["fits", "Encajan aquí"], ["all", "Todas las RAM"], ["boards", "Placas"]]:
		var b := UiStyle.button(t[1], func() -> void:
			_tab = t[0]
			_rebuild())
		b.custom_minimum_size.y = _btn_h()
		b.modulate = Color(1, 1, 1, 1.0 if _tab == t[0] else 0.55)
		tabs.add_child(b)
	var sort := UiStyle.button("Ordenar", _sort_bag)
	sort.custom_minimum_size.y = _btn_h()
	sort.tooltip_text = "Ordena las placas y las RAM de la bolsa."
	tabs.add_child(sort)
	var list := VBoxContainer.new()
	list.add_theme_constant_override("separation", 5)
	_right.add_child(list)
	var bag := character.inventory.bag
	var board := _board()
	var shown := 0
	for i in Inventory.BAG_SIZE:
		var it: Item = bag[i]
		match _tab:
			"fits":
				if it is RamModule and board and (it as RamModule).supports(board.skill_def):
					list.add_child(_ram_row(i, it, board))
					shown += 1
			"all":
				if it is RamModule:
					list.add_child(_ram_row(i, it, board))
					if i == _selected_ram:
						list.add_child(_verdicts_for(it))
					shown += 1
			"boards":
				if it is Motherboard:
					list.add_child(_board_row(i, it))
					shown += 1
	if shown == 0:
		var empty := UiStyle.label({"fits": "Ninguna RAM de tu bolsa le sirve a esta placa." if board else "Elige primero una placa.",
			"all": "No tienes RAM sueltas. Mata cosas; algo caerá.", "boards": "No tienes placas sueltas."}[_tab], 13, UiStyle.MUTED)
		empty.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		empty.custom_minimum_size.x = 300
		list.add_child(empty)
	if not _big():
		var tip := UiStyle.label("Suelta aquí una placa o RAM para devolverla a la bolsa.", 11, UiStyle.MUTED)
		_right.add_child(tip)


func _row_card(selected: bool) -> PanelContainer:
	var card := PanelContainer.new()
	var style := UiStyle.inset_style(UiStyle.ACCENT if selected else UiStyle.BORDER)
	if selected:
		style.set_border_width_all(2)
	card.add_theme_stylebox_override("panel", style)
	return card


func _ram_row(bag_index: int, ram: RamModule, board: Motherboard) -> Control:
	var card := _row_card(bag_index == _selected_ram)
	card.mouse_filter = Control.MOUSE_FILTER_STOP
	card.gui_input.connect(func(e: InputEvent) -> void:
		if _tapped(e):
			_on_bag_clicked(bag_index))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(row)
	var cell := _make_bag_cell(bag_index)
	cell.custom_minimum_size = Vector2(_tile() - 8, _tile() - 8)
	row.add_child(cell)
	var info := VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(info)
	var title := UiStyle.label(ram.display_name(), 13, RamModule.GENERATION_COLORS[ram.generation()].lightened(0.35))
	title.clip_text = true
	title.custom_minimum_size.x = 170
	info.add_child(title)
	var v := SkillAdvice.verdict(ram, board, character)
	var kind := String(v["kind"])
	var line := UiStyle.label(String(v["text"]) if kind != SkillAdvice.NONE else SkillAdvice.short_effect(ram), 11,
		OK_COLOR if SkillAdvice.good(v) else (SWAP_COLOR if kind == SkillAdvice.SWAP else (BAD_COLOR if kind != SkillAdvice.NONE else UiStyle.MUTED)))
	line.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	line.custom_minimum_size.x = 170
	info.add_child(line)
	if kind == SkillAdvice.FREE or kind == SkillAdvice.SWAP:
		var b := _action("Instalar" if kind == SkillAdvice.FREE else "Cambiar", _install.bind(bag_index, _sel_board, int(v["slot"])), false,
			"Ponerla en la ranura %d de %s." % [int(v["slot"]) + 1, board.skill_def["name"]])
		b.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		row.add_child(b)
	return card


## «RAM primero» (B): en qué placa funciona la RAM elegida y cuánto mejora, con «Instalar».
func _verdicts_for(ram: RamModule) -> Control:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 4)
	for i in Inventory.HOTBAR_SIZE:
		var board: Motherboard = character.inventory.boards[i]
		if board == null:
			continue
		var v := SkillAdvice.verdict(ram, board, character)
		var kind := String(v["kind"])
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 6)
		var key := Controls.key_label(SkillController.ACTIONS[i]) if not _big() else str(i + 1)
		var l := UiStyle.label("%s %s · %s: %s" % ["✓" if SkillAdvice.good(v) else "✕", key, board.skill_def["name"], v["text"]], 11,
			OK_COLOR if SkillAdvice.good(v) else (SWAP_COLOR if kind == SkillAdvice.SWAP else BAD_COLOR))
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		l.custom_minimum_size.x = 200
		row.add_child(l)
		if kind == SkillAdvice.FREE or kind == SkillAdvice.SWAP:
			var b := _action("Instalar", _install.bind(_selected_ram, i, int(v["slot"])))
			b.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			row.add_child(b)
		box.add_child(row)
	return box


func _board_row(bag_index: int, board: Motherboard) -> Control:
	var card := _row_card(false)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	card.add_child(row)
	var cell := _make_bag_cell(bag_index)
	cell.custom_minimum_size = Vector2(_tile() - 8, _tile() - 8)
	row.add_child(cell)
	var info := VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(info)
	var title := UiStyle.label("%s  ·  nv. %d" % [board.skill_def["name"], board.level], 13, Motherboard.COLOR.lightened(0.25))
	title.clip_text = true
	title.custom_minimum_size.x = 160
	info.add_child(title)
	var dps: float = SkillCalc.compute(board, character)["dps"]
	info.add_child(UiStyle.label("%d ranuras%s" % [board.slots.size(), "  ·  DPS ~%s" % _short(dps) if dps > 0.0 else ""], 11, UiStyle.MUTED))
	var key := Controls.key_label(SkillController.ACTIONS[_sel_board]) if not _big() else "tecla %d" % (_sel_board + 1)
	var b := _action("Poner en %s" % key, func() -> void:
		var problem := ItemTransfer.move(character, {"kind": "bag", "index": bag_index}, {"kind": "board", "index": _sel_board})
		if problem != "":
			message.emit(problem)
		_rebuild(), false, "La pone en la placa elegida a la izquierda (la que hubiera vuelve a la bolsa).")
	b.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(b)
	if _comparing:
		row.add_child(_action("Comparar", func() -> void: _pick_compare(board)))
	return card


func _install(bag_index: int, board_index: int, slot: int) -> void:
	var problem := ItemTransfer.move(character, {"kind": "bag", "index": bag_index}, {"kind": "dimm", "board": board_index, "dimm": slot})
	if problem != "":
		message.emit(problem)
		return
	_selected_ram = -1
	_sel_board = board_index
	_sel_slot = slot
	_rebuild()


func _sort_bag() -> void:
	_selected_ram = -1
	character.inventory.sort_skill_items()


# --- Celdas (arrastrar y soltar en PC, tooltip) ---

func _make_bag_cell(bag_index: int) -> ItemCell:
	var cell := _make_cell({"kind": "bag", "index": bag_index})
	cell.custom_minimum_size = Vector2(44, 44)
	cell.show_skill_icon = true
	cell.selected = bag_index == _selected_ram
	return cell


func _make_cell(location: Dictionary) -> ItemCell:
	var cell := ItemCell.new()
	cell.location = location
	cell.set_item(ItemTransfer.get_at(character.inventory, location))
	cell.clicked.connect(_on_cell_clicked)
	cell.hovered.connect(func(c: ItemCell, inside: bool) -> void:
		if inside and c.item and not _big():
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


## A la bolsa (al primer hueco libre).
func drop_into_bag(from: Dictionary) -> void:
	if from.get("kind", "") == "bag":
		return
	var free := character.inventory.free_bag_index()
	if free == -1:
		message.emit("Inventario lleno. Como tu backlog.")
		return
	_sel_slot = -1
	_move(from, {"kind": "bag", "index": free})


func _on_cell_clicked(cell: ItemCell, button: MouseButton) -> void:
	var loc := cell.location
	if button == MOUSE_BUTTON_RIGHT and cell.item and loc["kind"] != "bag":
		drop_into_bag(loc)   # atajo de PC: clic derecho = quitar
		return
	if button != MOUSE_BUTTON_LEFT:
		return
	match loc["kind"]:
		"bag":
			if cell.item is RamModule:
				_on_bag_clicked(loc["index"])
			elif cell.item is Motherboard and _comparing:
				_pick_compare(cell.item)
		"board":
			_on_board_tapped(loc["index"])
		"dimm":
			if _selected_ram != -1:
				_install(_selected_ram, loc["board"], loc["dimm"])
			elif cell.item:
				_sel_slot = -1 if _sel_slot == loc["dimm"] else int(loc["dimm"])
				_rebuild()
			else:
				message.emit("Ranura libre: toca una RAM %s de la derecha y luego esta ranura (o «Instalar»)." % _board().slots[loc["dimm"]])


## Tocar una RAM de la bolsa: la elige (o la suelta si ya estaba elegida).
func _on_bag_clicked(bag_index: int) -> void:
	var item: Item = character.inventory.bag[bag_index]
	if item is RamModule:
		_selected_ram = -1 if _selected_ram == bag_index else bag_index
		_rebuild()
	elif item is Motherboard:
		_tab = "boards"
		_rebuild()


# --- Comparador de placas ---

var _compare_button: Button
var _comparing := false
var _compare_pick: Array[Motherboard] = []


func _toggle_compare() -> void:
	_comparing = not _comparing
	_compare_pick.clear()
	_rebuild()


func _pick_compare(board: Motherboard) -> void:
	if _compare_pick.has(board):
		return
	_compare_pick.append(board)
	if _compare_pick.size() < 2:
		message.emit("%s elegida: ahora la otra." % board.skill_def["name"])
		return
	var a := _compare_pick[0]
	var b := _compare_pick[1]
	_toggle_compare()
	_show_comparison(a, b)


func _show_comparison(a: Motherboard, b: Motherboard) -> void:
	var rows := Builds.compare_boards(SkillCalc.compute(a, character), SkillCalc.compute(b, character))
	var grid := GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 18)
	grid.add_theme_constant_override("v_separation", 4)
	grid.add_child(UiStyle.label("", 13))
	for board in [a, b]:
		grid.add_child(UiStyle.label("%s (nv %d)" % [board.skill_def["name"], board.level], 14, UiStyle.GOLD))
	for r in rows:
		grid.add_child(UiStyle.label(r["label"], 13, UiStyle.MUTED))
		for k in 2:
			var color := OK_COLOR if r["better"] == k else (Color("e0a060") if r["better"] == 1 - k else UiStyle.TEXT)
			grid.add_child(UiStyle.label(r[["a", "b"][k]], 13, color))
	_popup("Comparar placas", grid)


func _popup(title: String, content: Control) -> void:
	var win := AcceptDialog.new()
	win.title = title
	win.ok_button_text = "Cerrar"
	win.theme = theme
	win.add_child(content)
	win.close_requested.connect(win.queue_free)
	win.confirmed.connect(win.queue_free)
	add_child(win)
	GameUI.show_popup(win)


# --- Construcciones guardadas ---

var _builds_box: VBoxContainer
var _builds_win: AcceptDialog


func _open_builds() -> void:
	_builds_box = VBoxContainer.new()
	_builds_box.add_theme_constant_override("separation", 6)
	_builds_box.custom_minimum_size.x = 420
	_builds_win = AcceptDialog.new()
	_builds_win.title = "Construcciones"
	_builds_win.ok_button_text = "Cerrar"
	_builds_win.theme = theme
	_builds_win.add_child(_builds_box)
	_builds_win.close_requested.connect(_builds_win.queue_free)
	_builds_win.confirmed.connect(_builds_win.queue_free)
	add_child(_builds_win)
	_fill_builds()
	GameUI.show_popup(_builds_win)


func _fill_builds() -> void:
	for ch in _builds_box.get_children():
		_builds_box.remove_child(ch)
		ch.queue_free()
	_builds_box.add_child(UiStyle.label("Árbol pasivo (nodos y maestrías) y barra de habilidades. Cambiar es gratis.", 12, UiStyle.MUTED))
	for build in Builds.list(character):
		var row := HBoxContainer.new()
		var name_label := UiStyle.label("%s  ·  %d puntos" % [build["name"], build["passives"].size()], 13)
		name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(name_label)
		row.add_child(UiStyle.button("Cargar", _load_build.bind(build)))
		row.add_child(UiStyle.button("Borrar", func() -> void:
			Builds.delete(character, build["name"])
			_fill_builds()))
		_builds_box.add_child(row)
	var save_row := HBoxContainer.new()
	var edit := LineEdit.new()
	edit.placeholder_text = "Nombre (p. ej. «Jefes» o «Farmeo»)"
	edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	save_row.add_child(edit)
	save_row.add_child(UiStyle.button("Guardar actual", func() -> void:
		var problem := Builds.save(character, edit.text)
		if problem != "":
			message.emit(problem)
		_fill_builds()))
	_builds_box.add_child(save_row)


func _load_build(build: Dictionary) -> void:
	var r := Builds.apply(character, build)
	if r["error"] != "":
		message.emit(r["error"])
		return
	if not r["missing_skills"].is_empty():
		message.emit("Cargada «%s». No tienes placa de: %s." % [build["name"], ", ".join(PackedStringArray(r["missing_skills"].map(_skill_name)))])
	else:
		message.emit("Cargada «%s»." % build["name"])
	_builds_win.queue_free()


static func _skill_name(id: String) -> String:
	return String(GameData.items.skills.skills.get(id, {}).get("name", id))


## Columna derecha: acepta lo que se suelte encima (para desinstalarlo).
class _BagDropZone extends PanelContainer:
	var panel: SkillsPanel

	func _ready() -> void:
		add_theme_stylebox_override("panel", UiStyle.inset_style())

	func _can_drop_data(_at: Vector2, data: Variant) -> bool:
		return data is Dictionary and data.has("from") and data["from"].get("kind", "") != "bag"

	func _drop_data(_at: Vector2, data: Variant) -> void:
		panel.drop_into_bag(data["from"])
