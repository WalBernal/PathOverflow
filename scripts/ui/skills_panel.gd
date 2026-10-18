class_name SkillsPanel
extends PanelContainer
## Menú de habilidades (K): las 6 placas base de la barra con sus ranuras DIMM,
## y las placas y módulos RAM que hay en la bolsa.
##
## - Click en una placa de la bolsa: instalarla en la primera ranura libre.
## - Click en una RAM de la bolsa: seleccionarla; luego click en una ranura DIMM
##   de su generación para instalarla (o doble click: primera ranura compatible).
## - Click en una RAM instalada: quitarla. Click der. en una placa: quitarla.

signal message(text: String)

const DIMM_SIZE := Vector2(62, 30)
const ROW_HEIGHT := 58.0

var character: CharacterData
var _tooltip: ItemTooltip
var _rows: VBoxContainer
var _bag_box: HFlowContainer
var _selected_ram := -1  # índice en la bolsa de la RAM seleccionada


func setup(p_character: CharacterData, tooltip: ItemTooltip) -> void:
	character = p_character
	_tooltip = tooltip
	character.inventory.changed.connect(_rebuild)
	_rebuild()


func _ready() -> void:
	add_theme_stylebox_override("panel", UiStyle.panel_style())
	theme = UiStyle.make_theme()
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	add_child(box)
	box.add_child(UiStyle.label("Habilidades: placas base y RAM", 20, UiStyle.ACCENT))
	var hint := UiStyle.label("Click en una placa de la bolsa: instalarla.  Click en una RAM y después en una ranura de su color.\nClick en una RAM instalada: quitarla.  Click derecho en una placa instalada: desinstalarla.", 12, UiStyle.MUTED)
	box.add_child(hint)
	_rows = VBoxContainer.new()
	_rows.add_theme_constant_override("separation", 6)
	box.add_child(_rows)
	box.add_child(UiStyle.label("En la bolsa", 16, UiStyle.ACCENT))
	_bag_box = HFlowContainer.new()
	_bag_box.add_theme_constant_override("h_separation", 4)
	_bag_box.add_theme_constant_override("v_separation", 4)
	_bag_box.custom_minimum_size = Vector2(700, 0)
	box.add_child(_bag_box)
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
	var any := false
	for i in Inventory.BAG_SIZE:
		var item: Item = character.inventory.bag[i]
		if item is Motherboard or item is RamModule:
			_bag_box.add_child(_make_bag_cell(i, item))
			any = true
	if not any:
		_bag_box.add_child(UiStyle.label("No tienes placas ni RAM sueltas. Mata cosas; algo caerá.", 13, UiStyle.MUTED))


func _make_row(index: int) -> Control:
	var board: Motherboard = character.inventory.boards[index]
	var row := HBoxContainer.new()
	row.custom_minimum_size.y = ROW_HEIGHT
	row.add_theme_constant_override("separation", 8)

	var key := UiStyle.label(SkillController.KEY_LABELS[index], 14, UiStyle.ACCENT)
	key.custom_minimum_size.x = 36
	key.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	row.add_child(key)

	var icon := _IconBox.new()
	icon.board = board
	icon.custom_minimum_size = Vector2(ROW_HEIGHT - 6.0, ROW_HEIGHT - 6.0)
	icon.gui_input.connect(_on_board_input.bind(index))
	icon.mouse_entered.connect(func() -> void: _show_tooltip(board))
	icon.mouse_exited.connect(_tooltip.hide)
	row.add_child(icon)

	var name_label := UiStyle.label("%s  (nv. %d)" % [board.skill_def["name"], board.level] if board else "Ranura vacía", 15,
		Motherboard.COLOR if board else UiStyle.MUTED)
	name_label.custom_minimum_size.x = 210
	name_label.clip_text = true
	row.add_child(name_label)

	if board:
		for d in board.slots.size():
			row.add_child(_make_dimm(index, d, board))
		var up := Button.new()
		up.text = "Subir"
		up.focus_mode = Control.FOCUS_NONE
		up.disabled = index == 0
		up.pressed.connect(func() -> void: character.inventory.swap_boards(index, index - 1))
		row.add_child(up)
		var down := Button.new()
		down.text = "Bajar"
		down.focus_mode = Control.FOCUS_NONE
		down.disabled = index == Inventory.HOTBAR_SIZE - 1
		down.pressed.connect(func() -> void: character.inventory.swap_boards(index, index + 1))
		row.add_child(down)
	return row


func _make_dimm(board_index: int, dimm_index: int, board: Motherboard) -> Control:
	var cell := _DimmSlot.new()
	cell.generation = board.slots[dimm_index]
	cell.ram = board.rams[dimm_index]
	cell.active = cell.ram != null and cell.ram.supports(board.skill_def)
	var selected: RamModule = character.inventory.bag[_selected_ram] if _selected_ram != -1 else null
	cell.highlight = selected != null and cell.ram == null and selected.generation() == cell.generation
	cell.custom_minimum_size = DIMM_SIZE
	cell.gui_input.connect(func(event: InputEvent) -> void:
		var mb := event as InputEventMouseButton
		if mb and mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT:
			_on_dimm_clicked(board_index, dimm_index))
	cell.mouse_entered.connect(func() -> void: _show_tooltip(cell.ram))
	cell.mouse_exited.connect(_tooltip.hide)
	return cell


func _make_bag_cell(bag_index: int, item: Item) -> Control:
	var cell := ItemCell.new()
	cell.bag_index = bag_index
	cell.custom_minimum_size = Vector2(82, 40)
	cell.set_item(item)
	cell.selected = bag_index == _selected_ram
	cell.clicked.connect(func(_c: ItemCell, button: MouseButton) -> void:
		if button == MOUSE_BUTTON_LEFT:
			_on_bag_clicked(bag_index))
	cell.hovered.connect(func(_c: ItemCell, inside: bool) -> void:
		if inside:
			_show_tooltip(item)
		else:
			_tooltip.hide())
	return cell


func _show_tooltip(item: Item) -> void:
	if item:
		_tooltip.show_item(item, character, false)
	else:
		_tooltip.hide()


func _on_bag_clicked(bag_index: int) -> void:
	var item: Item = character.inventory.bag[bag_index]
	if item is Motherboard:
		if not character.inventory.install_board(bag_index):
			message.emit("La barra está llena. Quita una placa primero (click derecho).")
	elif item is RamModule:
		if _selected_ram == bag_index:
			# Segundo click: a la primera ranura compatible de cualquier placa.
			for i in Inventory.HOTBAR_SIZE:
				if character.inventory.boards[i] and character.inventory.boards[i].free_slot_for(item) != -1:
					character.inventory.install_ram(bag_index, i)
					_selected_ram = -1
					return
			message.emit("Ninguna placa tiene ranuras %s libres." % item.generation())
		else:
			_selected_ram = bag_index
			_rebuild()


func _on_dimm_clicked(board_index: int, dimm_index: int) -> void:
	var board: Motherboard = character.inventory.boards[board_index]
	if board.rams[dimm_index] != null:
		if not character.inventory.remove_ram(board_index, dimm_index):
			message.emit("Inventario lleno: no hay dónde guardar ese módulo.")
		return
	if _selected_ram == -1:
		message.emit("Selecciona primero un módulo RAM de la bolsa.")
		return
	var problem := character.inventory.install_ram(_selected_ram, board_index, dimm_index)
	if problem != "":
		message.emit(problem)
	else:
		_selected_ram = -1
		_rebuild()


func _on_board_input(event: InputEvent, index: int) -> void:
	var mb := event as InputEventMouseButton
	if mb and mb.pressed and mb.button_index == MOUSE_BUTTON_RIGHT and character.inventory.boards[index]:
		if not character.inventory.uninstall_board(index):
			message.emit("Inventario lleno: no hay dónde guardar esa placa.")
		_tooltip.hide()


## Icono de la habilidad de una fila.
class _IconBox extends Control:
	var board: Motherboard

	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_STOP

	func _draw() -> void:
		draw_rect(Rect2(Vector2.ZERO, size), Color(0, 0, 0, 0.6))
		if board:
			SkillIcon.draw(self, Rect2(Vector2.ZERO, size).grow(-3.0), board.skill_def)
			draw_rect(Rect2(Vector2.ZERO, size), Motherboard.COLOR.darkened(0.2), false, 1.5)
		else:
			draw_rect(Rect2(Vector2.ZERO, size), UiStyle.BORDER, false, 1.0)


## Una ranura DIMM: color de su generación y la RAM instalada (si hay).
class _DimmSlot extends Control:
	var generation := "DDR3"
	var ram: RamModule
	var active := false
	var highlight := false

	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_STOP

	func _draw() -> void:
		var color: Color = RamModule.GENERATION_COLORS[generation]
		var rect := Rect2(Vector2.ZERO, size)
		draw_rect(rect, Color(color, 0.12 if ram == null else 0.35))
		draw_rect(rect, UiStyle.ACCENT if highlight else color.darkened(0.2), false, 3.0 if highlight else 1.5)
		var font := get_theme_default_font()
		var text: String = generation if ram == null else ram.def["name"].split(" ")[-1]
		var text_color := color.lightened(0.3) if ram == null or active else Color("e06c6c")
		draw_string(font, Vector2(0, size.y / 2.0 + 5.0), text.substr(0, 10), HORIZONTAL_ALIGNMENT_CENTER, size.x, 12, text_color)
		# Pines de la ranura, por estética.
		for k in 6:
			draw_rect(Rect2(Vector2(6 + k * (size.x - 12) / 6.0, size.y - 4), Vector2(3, 3)), color.darkened(0.3))
