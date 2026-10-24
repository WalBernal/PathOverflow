class_name InventoryPanel
extends PanelContainer
## Panel de inventario (tecla I): equipo en forma de "muñeco", cinturón de
## pociones (teclas 1-5), tokens y bolsa. Las cifras del personaje están en la hoja (C).
## Arrastrar y soltar: mover entre la bolsa y el equipo (intercambia si hace
## falta). Soltar fuera de los paneles: tirarlo al suelo.
## Click: equipar (desde la bolsa) o quitar (desde el equipo).

signal message(text: String)
signal item_equipped
signal drop_to_ground(location: Dictionary)
signal close_requested
## Click en la bolsa con el alijo abierto: guardar ahí (lo conecta GameUI).
var bag_click_override: Callable

const CELL := 46.0
const BAG_COLUMNS := 10
## Posición y tamaño de cada ranura de equipo (en múltiplos de CELL).
const EQUIP_LAYOUT := {
	"weapon": Rect2(0.0, 0.5, 1.6, 3.0),
	"helmet": Rect2(3.2, 0.0, 1.6, 1.4),
	"amulet": Rect2(5.2, 0.6, 1.0, 1.0),
	"ring_left": Rect2(2.0, 2.2, 1.0, 1.0),
	"body": Rect2(3.2, 1.6, 1.6, 2.4),
	"ring_right": Rect2(5.2, 2.2, 1.0, 1.0),
	"gloves": Rect2(0.0, 3.8, 1.6, 1.4),
	"belt": Rect2(3.2, 4.2, 1.6, 0.8),
	"boots": Rect2(6.6, 3.8, 1.6, 1.4),
}

var character: CharacterData
var _equip_cells: Dictionary = {}   # ranura -> ItemCell
var _bag_cells: Array[ItemCell] = []
var _flask_cells: Array[ItemCell] = []
var _summary: RichTextLabel
var _silhouette: AppearancePreview
var _bag_header: Control
var _scroll: ScrollContainer
var _content: VBoxContainer
var _box: VBoxContainer
## Silueta de lo que va en cada ranura vacía.
const SLOT_ICONS := {
	"weapon": "espada_oxidada", "helmet": "casco_de_hierro", "body": "cota_de_placas", "gloves": "guantes_de_cuero",
	"boots": "botas_de_cuero", "amulet": "amuleto_de_ambar", "ring_left": "anillo_de_hierro", "ring_right": "anillo_de_hierro",
	"belt": "cinturon_de_cuero",
}
var _tooltip: ItemTooltip


func setup(p_character: CharacterData, tooltip: ItemTooltip) -> void:
	character = p_character
	_tooltip = tooltip
	character.inventory.changed.connect(_refresh)
	character.tokens_changed.connect(func(_t: int) -> void: _refresh_summary())
	_refresh()


func _ready() -> void:
	theme = UiStyle.make_theme()
	UiStyle.decorate_window(self)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	add_child(box)
	box.add_child(UiStyle.window_header("Inventario", "Equipo, pociones y bolsa  ·  I para cerrar",
		func() -> void: close_requested.emit()))
	# El resto va en un área con desplazamiento: con la interfaz grande en una
	# pantalla baja, la bolsa no se sale por abajo (ver fit_height).
	_scroll = ScrollContainer.new()
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	box.add_child(_scroll)
	var header_box := box
	box = VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	_scroll.add_child(box)
	_content = box
	_box = header_box
	visibility_changed.connect(fit_height)
	get_viewport().size_changed.connect(fit_height.call_deferred)

	# Muñeco: silueta del personaje detrás de las ranuras de equipo.
	var doll := Control.new()
	doll.custom_minimum_size = Vector2(CELL * BAG_COLUMNS, CELL * 5.3)
	box.add_child(doll)
	var doll_offset := Vector2((BAG_COLUMNS - 8.2) * CELL / 2.0, 0.0)
	_silhouette = AppearancePreview.new()
	_silhouette.modulate = Color(1, 1, 1, 0.13)
	_silhouette.position = doll_offset + Vector2(2.2 * CELL, -0.2 * CELL)
	_silhouette.size = Vector2(3.6 * CELL, 5.6 * CELL)
	doll.add_child(_silhouette)
	doll.draw.connect(func() -> void:
		var center := doll_offset + Vector2(4.1 * CELL, 2.6 * CELL)
		doll.draw_circle(center, 2.4 * CELL, Color(0.6, 0.45, 0.2, 0.05))
		doll.draw_arc(center, 2.4 * CELL, 0.0, TAU, 64, Color(UiStyle.GOLD, 0.15), 1.0, true))
	for slot in EQUIP_LAYOUT:
		var r: Rect2 = EQUIP_LAYOUT[slot]
		var cell := _make_cell({"kind": "equip", "slot": slot})
		cell.placeholder = Inventory.SLOT_NAMES[slot]
		cell.placeholder_icon = SLOT_ICONS.get(slot, "")
		cell.position = doll_offset + r.position * CELL
		cell.size = r.size * CELL - Vector2(4, 4)
		doll.add_child(cell)
		_equip_cells[slot] = cell

	# Cinturón de pociones.
	box.add_child(UiStyle.section_header("Pociones  (teclas 1-5)"))
	var belt := HBoxContainer.new()
	belt.add_theme_constant_override("separation", 6)
	belt.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_child(belt)
	for i in Inventory.FLASK_SLOTS:
		var cell := _make_cell({"kind": "flask", "index": i})
		cell.placeholder = str(i + 1)
		cell.placeholder_icon = "flask_coffee" if i == 0 else ("flask_energy" if i == 1 else "")
		cell.custom_minimum_size = Vector2(CELL * 1.1, CELL * 1.3)
		belt.add_child(cell)
		_flask_cells.append(cell)

	# Resumen de cifras en una caja.
	var summary_box := PanelContainer.new()
	summary_box.add_theme_stylebox_override("panel", UiStyle.inset_style())
	box.add_child(summary_box)
	_summary = RichTextLabel.new()
	_summary.bbcode_enabled = true
	_summary.fit_content = true
	_summary.mouse_filter = Control.MOUSE_FILTER_IGNORE
	summary_box.add_child(_summary)

	_bag_header = UiStyle.section_header("Bolsa")
	box.add_child(_bag_header)
	var grid := GridContainer.new()
	grid.columns = BAG_COLUMNS
	grid.add_theme_constant_override("h_separation", 2)
	grid.add_theme_constant_override("v_separation", 2)
	box.add_child(grid)
	for i in Inventory.BAG_SIZE:
		var cell := _make_cell({"kind": "bag", "index": i})
		cell.custom_minimum_size = Vector2(CELL - 2.0, CELL - 2.0)
		grid.add_child(cell)
		_bag_cells.append(cell)

	box.add_child(UiStyle.label("Arrastra para mover o equipar  ·  Click: equipar / quitar (también pociones)  ·  Arrastra fuera para tirar", 11, UiStyle.MUTED))
	fit_height.call_deferred()


## Ajusta el alto del área con desplazamiento a lo que queda de pantalla (todo
## el contenido si cabe).
func fit_height() -> void:
	var parent := get_parent_control()
	if _scroll == null or parent == null:
		return
	var full := _content.get_combined_minimum_size().y
	var overhead := _box.get_combined_minimum_size().y - _scroll.get_combined_minimum_size().y
	overhead += get_theme_stylebox("panel").get_minimum_size().y
	var avail := parent.size.y - offset_top - 10.0 - overhead
	_scroll.custom_minimum_size = Vector2(_content.get_combined_minimum_size().x, clampf(avail, 160.0, full))
	reset_size()

func _make_cell(location: Dictionary) -> ItemCell:
	var cell := ItemCell.new()
	cell.location = location
	cell.clicked.connect(_on_cell_clicked)
	cell.hovered.connect(_on_cell_hovered)
	cell.dropped.connect(_on_cell_dropped)
	cell.released_outside.connect(func(c: ItemCell) -> void: drop_to_ground.emit(c.location))
	return cell


func _refresh() -> void:
	if character == null or _bag_cells.is_empty():
		return
	for slot in _equip_cells:
		_equip_cells[slot].set_item(character.inventory.equipped(slot))
	for i in _bag_cells.size():
		_bag_cells[i].set_item(character.inventory.bag[i])
	for i in _flask_cells.size():
		_flask_cells[i].set_item(character.inventory.flasks[i])
	if _silhouette:
		_silhouette.appearance = character.appearance
	if _bag_header:
		var used := character.inventory.bag.filter(func(it) -> bool: return it != null).size()
		(_bag_header.get_child(1) as Label).text = "Bolsa  (%d / %d)" % [used, Inventory.BAG_SIZE]
	_refresh_summary()


func _refresh_summary() -> void:
	if _summary == null or character == null:
		return
	# Solo la moneda: vida, daño y resistencias están en la hoja de personaje (C).
	_summary.text = "[color=#f2c14e]●[/color] [color=#8a8293]%s[/color] [color=#f2c14e][b]%d[/b][/color]     [color=#5a5363]Las cifras del personaje: tecla C[/color]" % [
		Economy.CURRENCY, character.tokens]


func _on_cell_dropped(target: ItemCell, payload: Dictionary) -> void:
	var problem := ItemTransfer.move(character, payload["from"], target.location)
	if problem != "":
		message.emit(problem)
	elif target.location["kind"] == "equip" or payload["from"].get("kind", "") == "equip":
		item_equipped.emit()
	_on_cell_hovered(target, true)


func _on_cell_clicked(cell: ItemCell, button: MouseButton) -> void:
	if cell.item == null or button != MOUSE_BUTTON_LEFT:
		return
	var inv := character.inventory
	if cell.location["kind"] == "flask":
		if not inv.unequip_flask(cell.location["index"]):
			message.emit("Inventario lleno. Como tu backlog.")
		_on_cell_hovered(cell, true)
		return
	if cell.location["kind"] == "bag" and bag_click_override.is_valid():
		bag_click_override.call(int(cell.location["index"]))
		_tooltip.hide()
		return
	if cell.location["kind"] == "bag" and cell.item is Flask:
		if character.level < cell.item.required_level():
			message.emit("Requiere nivel %d. Este café es demasiado fuerte para ti." % cell.item.required_level())
		elif not inv.equip_flask(cell.location["index"]):
			message.emit("El cinturón está lleno: arrastra la poción encima de otra para cambiarlas.")
		_on_cell_hovered(cell, true)
		return
	if cell.location["kind"] == "bag" and cell.item is KeyItem:
		message.emit("Objeto clave: se usa solo al llegar a lo que abre.")
		return
	if cell.location["kind"] == "bag":
		if cell.item is ExpansionChip:
			message.emit("Los chips de expansión se engastan en el árbol pasivo (P): click en una ranura hexagonal asignada.")
			return
		if not cell.item.is_equipment():
			message.emit("Las placas base y la RAM se instalan en el menú de habilidades (K).")
			return
		if not character.can_equip(cell.item):
			message.emit(ItemTransfer.equip_refusal(character, cell.item))
			return
		if inv.equip_from_bag(cell.location["index"]):
			item_equipped.emit()
	elif not inv.unequip(cell.location["slot"]):
		message.emit("Inventario lleno. Como tu backlog.")
	_on_cell_hovered(cell, true)


func _on_cell_hovered(cell: ItemCell, inside: bool) -> void:
	if not inside or cell.item == null:
		_tooltip.hide()
		return
	_tooltip.show_item(cell.item, character, cell.location["kind"] == "bag" and cell.item.is_equipment())
