class_name StashPanel
extends PanelContainer
## Alijo compartido por la cuenta (todos tus personajes ven lo mismo).
## Pestañas de 60 casillas. Arrastrar entre el alijo y la bolsa; click en el
## alijo: pasarlo a la bolsa; click en la bolsa (con el alijo abierto): guardarlo.

signal message(text: String)
signal close_requested
signal drop_to_ground(location: Dictionary)

const CELL := 44.0
const COLUMNS := 10

var character: CharacterData
var stash: Stash
var tab := 0
var _tooltip: ItemTooltip
var _cells: Array[ItemCell] = []
var _tab_buttons: Array[Button] = []
var _count_label: Label
## Búsqueda (T80): resalta lo que coincide en la pestaña y cuenta las coincidencias de cada una.
var query := ""
var _search: LineEdit
var _edit_row: HBoxContainer
var _name_edit: LineEdit
var _patches_label: RichTextLabel


func setup(p_character: CharacterData, p_stash: Stash, tooltip: ItemTooltip) -> void:
	character = p_character
	stash = p_stash
	_tooltip = tooltip
	stash.changed.connect(_refresh)
	_refresh()


func _ready() -> void:
	theme = UiStyle.make_theme()
	UiStyle.decorate_window(self)
	visible = false
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	add_child(box)
	box.add_child(UiStyle.window_header("Alijo (NAS compartido)", "Lo ven todos tus personajes  ·  Esc para cerrar",
		func() -> void: close_requested.emit()))
	# Búsqueda por texto (nombre, base o afijo) y botón para editar la pestaña.
	var search_row := HBoxContainer.new()
	search_row.add_theme_constant_override("separation", 6)
	box.add_child(search_row)
	_search = LineEdit.new()
	_search.placeholder_text = "Buscar en el alijo (nombre, base o afijo: «vida», «anillo», «fuego»…)"
	_search.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_search.clear_button_enabled = true
	_search.text_changed.connect(set_query)
	search_row.add_child(_search)
	var edit_button := UiStyle.button("Editar pestaña", func() -> void:
		_edit_row.visible = not _edit_row.visible
		_name_edit.text = stash.tab_name(tab) if stash else "", 0)
	search_row.add_child(edit_button)
	var tabs := HBoxContainer.new()
	tabs.add_theme_constant_override("separation", 4)
	box.add_child(tabs)
	for t in Stash.TABS:
		var b := Button.new()
		b.text = Stash.TAB_NAMES[t]
		b.toggle_mode = true
		b.focus_mode = Control.FOCUS_NONE
		b.pressed.connect(func() -> void:
			tab = t
			if _edit_row.visible:
				_name_edit.text = stash.tab_name(tab)
			_refresh())
		tabs.add_child(b)
		_tab_buttons.append(b)
	# Editar la pestaña: nombre y color.
	_edit_row = HBoxContainer.new()
	_edit_row.add_theme_constant_override("separation", 4)
	_edit_row.visible = false
	box.add_child(_edit_row)
	_name_edit = LineEdit.new()
	_name_edit.max_length = Stash.NAME_MAX
	_name_edit.custom_minimum_size.x = 200
	_name_edit.text_submitted.connect(func(t: String) -> void: rename_tab(t))
	_name_edit.focus_exited.connect(func() -> void: rename_tab(_name_edit.text))
	_edit_row.add_child(_name_edit)
	for k in Stash.TAB_COLORS.size():
		var swatch := Button.new()
		swatch.custom_minimum_size = Vector2(26, 26)
		swatch.focus_mode = Control.FOCUS_NONE
		var sb := StyleBoxFlat.new()
		sb.bg_color = Stash.TAB_COLORS[k]
		sb.set_corner_radius_all(4)
		for state in ["normal", "hover", "pressed"]:
			swatch.add_theme_stylebox_override(state, sb)
		swatch.pressed.connect(func() -> void:
			stash.set_color(tab, k)
			stash.save())
		_edit_row.add_child(swatch)
	# Parches de crafteo (son contadores del personaje): se ven en la pestaña de materiales.
	_patches_label = RichTextLabel.new()
	_patches_label.bbcode_enabled = true
	_patches_label.fit_content = true
	_patches_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(_patches_label)
	var grid := GridContainer.new()
	grid.columns = COLUMNS
	grid.add_theme_constant_override("h_separation", 2)
	grid.add_theme_constant_override("v_separation", 2)
	box.add_child(grid)
	for i in Stash.TAB_SIZE:
		var cell := ItemCell.new()
		cell.custom_minimum_size = Vector2(CELL, CELL)
		cell.clicked.connect(_on_cell_clicked)
		cell.hovered.connect(_on_cell_hovered)
		cell.dropped.connect(_on_cell_dropped)
		cell.released_outside.connect(func(c: ItemCell) -> void: drop_to_ground.emit(c.location))
		grid.add_child(cell)
		_cells.append(cell)
	_count_label = UiStyle.label("", 12, UiStyle.MUTED)
	box.add_child(_count_label)
	box.add_child(UiStyle.label("Arrastra entre el alijo y la bolsa  ·  Click: pasar a la bolsa / guardar desde la bolsa", 11, UiStyle.MUTED))


func _refresh() -> void:
	if stash == null or _cells.is_empty():
		return
	var searching := query.strip_edges() != ""
	for i in _cells.size():
		_cells[i].location = {"kind": "stash", "tab": tab, "index": i}
		var it := stash.get_item(tab, i)
		_cells[i].highlight = 0 if not searching or it == null else (1 if Stash.matches(it, query) else -1)
		_cells[i].set_item(it)
		_cells[i].queue_redraw()
	for t in _tab_buttons.size():
		var b := _tab_buttons[t]
		b.button_pressed = t == tab
		var hits := stash.match_count(t, query) if searching else 0
		b.text = stash.tab_name(t) + ("  (%d)" % hits if hits > 0 else "")
		b.add_theme_color_override("font_color", stash.tab_color(t))
		b.add_theme_color_override("font_pressed_color", stash.tab_color(t).lightened(0.3))
		b.add_theme_color_override("font_hover_color", stash.tab_color(t).lightened(0.2))
	_count_label.text = "%d objetos guardados en total" % stash.count() + ("  ·  %d coinciden en esta pestaña" % stash.match_count(tab, query) if searching else "")
	_patches_label.visible = tab == Stash.MATERIALS_TAB and character != null
	if _patches_label.visible:
		var parts := PackedStringArray()
		for kind in Crafting.KINDS:
			parts.append("[color=#d9a441]%s[/color] ×%d" % [Crafting.NAMES[kind], Crafting.count(character, kind)])
		_patches_label.text = "[color=#8a8293]Tus parches (van con el personaje):[/color]  " + "   ".join(parts)


## Búsqueda: resalta lo que coincide en la pestaña y cuenta las de las demás.
func set_query(text: String) -> void:
	query = text
	_refresh()


func rename_tab(new_name: String) -> void:
	if stash == null:
		return
	stash.rename(tab, new_name)
	stash.save()


## Guarda en el alijo lo que hay en la bolsa (click con el alijo abierto).
func store_from_bag(bag_index: int) -> void:
	var item: Item = character.inventory.bag[bag_index]
	if item == null:
		return
	var target := tab
	if Stash.is_material(item) and tab != Stash.MATERIALS_TAB and stash.free_index(Stash.MATERIALS_TAB) != -1:
		target = Stash.MATERIALS_TAB   # los chips, a la pestaña de materiales
	elif Stash.refusal(tab, item) != "":
		message.emit(Stash.refusal(tab, item))
		return
	var i := stash.free_index(target)
	if i == -1:
		message.emit("Esta pestaña está llena. Prueba otra.")
		return
	var problem := ItemTransfer.move(character, {"kind": "bag", "index": bag_index}, {"kind": "stash", "tab": target, "index": i})
	if problem != "":
		message.emit(problem)
	elif target != tab:
		message.emit("Guardado en «%s»." % stash.tab_name(target))


func _on_cell_clicked(cell: ItemCell, button: MouseButton) -> void:
	if button != MOUSE_BUTTON_LEFT or cell.item == null:
		return
	var free := character.inventory.free_bag_index()
	if free == -1:
		message.emit("Inventario lleno. Como tu backlog.")
		return
	ItemTransfer.move(character, cell.location, {"kind": "bag", "index": free})
	_tooltip.hide()


func _on_cell_dropped(target: ItemCell, payload: Dictionary) -> void:
	var problem := ItemTransfer.move(character, payload["from"], target.location)
	if problem != "":
		message.emit(problem)
	_on_cell_hovered(target, true)


func _on_cell_hovered(cell: ItemCell, inside: bool) -> void:
	if not inside or cell.item == null:
		_tooltip.hide()
		return
	_tooltip.show_item(cell.item, character, cell.item.is_equipment())
