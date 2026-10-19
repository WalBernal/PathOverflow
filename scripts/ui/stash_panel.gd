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
			_refresh())
		tabs.add_child(b)
		_tab_buttons.append(b)
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
	for i in _cells.size():
		_cells[i].location = {"kind": "stash", "tab": tab, "index": i}
		_cells[i].set_item(stash.get_item(tab, i))
	for t in _tab_buttons.size():
		_tab_buttons[t].button_pressed = t == tab
	_count_label.text = "%d objetos guardados en total" % stash.count()


## Guarda en el alijo lo que hay en la bolsa (click con el alijo abierto).
func store_from_bag(bag_index: int) -> void:
	var item: Item = character.inventory.bag[bag_index]
	if item == null:
		return
	var i := stash.free_index(tab)
	if i == -1:
		message.emit("Esta pestaña está llena. Prueba otra.")
		return
	var problem := ItemTransfer.move(character, {"kind": "bag", "index": bag_index}, {"kind": "stash", "tab": tab, "index": i})
	if problem != "":
		message.emit(problem)


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
