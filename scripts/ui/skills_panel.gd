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

const DIMM_SIZE := Vector2(40, 40)
const ROW_HEIGHT := 50.0

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
	box.add_child(UiStyle.label("Arrastra placas a la barra y RAM a una ranura de su color. Arrastra a la bolsa para quitar.\nTambién con clicks: click en la RAM y luego en la ranura; doble click la coloca sola.", 12, UiStyle.MUTED))
	_rows = VBoxContainer.new()
	_rows.add_theme_constant_override("separation", 6)
	box.add_child(_rows)
	box.add_child(UiStyle.label("En la bolsa (suelta aquí para desinstalar)", 16, UiStyle.ACCENT))
	var bag_drop := _BagDropZone.new()
	bag_drop.panel = self
	bag_drop.custom_minimum_size = Vector2(640, 52)
	box.add_child(bag_drop)
	_bag_box = HFlowContainer.new()
	_bag_box.add_theme_constant_override("h_separation", 4)
	_bag_box.add_theme_constant_override("v_separation", 4)
	_bag_box.mouse_filter = Control.MOUSE_FILTER_PASS
	bag_drop.add_child(_bag_box)
	_bag_box.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE, 4)
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
			_bag_box.add_child(_make_bag_cell(i))
			any = true
	if not any:
		var empty := UiStyle.label("No tienes placas ni RAM sueltas. Mata cosas; algo caerá.", 13, UiStyle.MUTED)
		empty.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_bag_box.add_child(empty)


func _make_row(index: int) -> Control:
	var board: Motherboard = character.inventory.boards[index]
	var row := HBoxContainer.new()
	row.custom_minimum_size.y = ROW_HEIGHT
	row.add_theme_constant_override("separation", 6)

	var key := UiStyle.label(SkillController.KEY_LABELS[index], 14, UiStyle.ACCENT)
	key.custom_minimum_size.x = 34
	key.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	row.add_child(key)

	var icon := _make_cell({"kind": "board", "index": index})
	icon.show_skill_icon = true
	icon.placeholder = "Vacía"
	icon.custom_minimum_size = Vector2(ROW_HEIGHT, ROW_HEIGHT)
	row.add_child(icon)

	var name_label := UiStyle.label("%s  (nv. %d)" % [board.skill_def["name"], board.level] if board else "Arrastra aquí una placa", 14,
		Motherboard.COLOR if board else UiStyle.MUTED)
	name_label.custom_minimum_size.x = 200
	name_label.clip_text = true
	row.add_child(name_label)

	if board:
		for d in board.slots.size():
			var dimm := _make_cell({"kind": "dimm", "board": index, "dimm": d})
			dimm.slot_color = RamModule.GENERATION_COLORS[board.slots[d]]
			dimm.placeholder = board.slots[d]
			dimm.custom_minimum_size = DIMM_SIZE
			var ram: RamModule = board.rams[d]
			dimm.warning = ram != null and not ram.supports(board.skill_def)
			var selected: RamModule = character.inventory.bag[_selected_ram] if _selected_ram != -1 else null
			dimm.selected = selected != null and ram == null and selected.generation() == board.slots[d]
			row.add_child(dimm)
	return row


func _make_bag_cell(bag_index: int) -> ItemCell:
	var cell := _make_cell({"kind": "bag", "index": bag_index})
	cell.custom_minimum_size = Vector2(44, 44)
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
