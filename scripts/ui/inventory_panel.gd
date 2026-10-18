class_name InventoryPanel
extends PanelContainer
## Panel de inventario (tecla I): equipo en forma de "muñeco" + bolsa.
## Click izq. en la bolsa: equipar · Click izq. en el equipo: quitar ·
## Click der. en la bolsa: destruir el objeto.

signal message(text: String)
signal item_equipped

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
var _summary: RichTextLabel
var _tooltip: ItemTooltip


func setup(p_character: CharacterData, tooltip: ItemTooltip) -> void:
	character = p_character
	_tooltip = tooltip
	character.inventory.changed.connect(_refresh)
	character.stats_changed.connect(_refresh_summary)
	_refresh()


func _ready() -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = Color("16131bf2")
	style.border_color = Color("3a3442")
	style.set_border_width_all(1)
	style.set_content_margin_all(14)
	add_theme_stylebox_override("panel", style)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	add_child(box)

	var title := Label.new()
	title.text = "Inventario"
	title.add_theme_font_size_override("font_size", 20)
	title.add_theme_color_override("font_color", Color("e8d9b0"))
	box.add_child(title)

	var doll := Control.new()
	doll.custom_minimum_size = Vector2(CELL * BAG_COLUMNS, CELL * 5.3)
	box.add_child(doll)
	# Centra el muñeco (8.2 celdas de ancho) dentro del ancho de la bolsa.
	var doll_offset := Vector2((BAG_COLUMNS - 8.2) * CELL / 2.0, 0.0)
	for slot in EQUIP_LAYOUT:
		var r: Rect2 = EQUIP_LAYOUT[slot]
		var cell := _make_cell()
		cell.slot_key = slot
		cell.placeholder = Inventory.SLOT_NAMES[slot]
		cell.position = doll_offset + r.position * CELL
		cell.size = r.size * CELL - Vector2(4, 4)
		doll.add_child(cell)
		_equip_cells[slot] = cell

	_summary = RichTextLabel.new()
	_summary.bbcode_enabled = true
	_summary.fit_content = true
	_summary.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(_summary)

	var grid := GridContainer.new()
	grid.columns = BAG_COLUMNS
	grid.add_theme_constant_override("h_separation", 2)
	grid.add_theme_constant_override("v_separation", 2)
	box.add_child(grid)
	for i in Inventory.BAG_SIZE:
		var cell := _make_cell()
		cell.bag_index = i
		cell.custom_minimum_size = Vector2(CELL - 2.0, CELL - 2.0)
		grid.add_child(cell)
		_bag_cells.append(cell)

	var hint := Label.new()
	hint.text = "Click izq.: equipar / quitar   ·   Click der.: destruir (rm -rf)"
	hint.add_theme_font_size_override("font_size", 12)
	hint.add_theme_color_override("font_color", Color("8a8293"))
	box.add_child(hint)


func _make_cell() -> ItemCell:
	var cell := ItemCell.new()
	cell.clicked.connect(_on_cell_clicked)
	cell.hovered.connect(_on_cell_hovered)
	return cell


func _refresh() -> void:
	if character == null or _bag_cells.is_empty():
		return
	for slot in _equip_cells:
		_equip_cells[slot].set_item(character.inventory.equipped(slot))
	for i in _bag_cells.size():
		_bag_cells[i].set_item(character.inventory.bag[i])
	_refresh_summary()


func _refresh_summary() -> void:
	if _summary == null or character == null:
		return
	var p := character.attack_profile()
	var s := character.stats
	_summary.text = "[color=#8a8293]DPS[/color] [color=#e8d9b0]%.1f[/color]   [color=#8a8293]Daño[/color] [color=#e8d9b0]%d-%d[/color]   [color=#8a8293]APS[/color] [color=#e8d9b0]%.2f[/color]   [color=#8a8293]Crít.[/color] [color=#e8d9b0]%.1f%%[/color]\n[color=#8a8293]Vida[/color] [color=#e8d9b0]%d[/color]   [color=#8a8293]ES[/color] [color=#e8d9b0]%d[/color]   [color=#8a8293]Armadura[/color] [color=#e8d9b0]%d[/color]   [color=#8a8293]Evasión[/color] [color=#e8d9b0]%d[/color]\n[color=#8a8293]Res.[/color] [color=#e06c6c]%d%%[/color] / [color=#7fb8e0]%d%%[/color] / [color=#e8d070]%d%%[/color] / [color=#b04ad9]%d%%[/color]" % [
		p.dps, p.min_damage, p.max_damage, p.attacks_per_second, p.crit_chance,
		s.get_value(Stat.LIFE), s.get_value(Stat.ENERGY_SHIELD), s.get_value(Stat.ARMOUR), s.get_value(Stat.EVASION),
		minf(Stat.RESISTANCE_CAP, s.get_value(Stat.FIRE_RES)), minf(Stat.RESISTANCE_CAP, s.get_value(Stat.COLD_RES)),
		minf(Stat.RESISTANCE_CAP, s.get_value(Stat.LIGHTNING_RES)), minf(Stat.RESISTANCE_CAP, s.get_value(Stat.CHAOS_RES)),
	]


func _on_cell_clicked(cell: ItemCell, button: MouseButton) -> void:
	var inv := character.inventory
	if cell.item == null:
		return
	if cell.bag_index >= 0:
		if button == MOUSE_BUTTON_LEFT:
			if not cell.item.is_equipment():
				message.emit("Las placas base y la RAM se instalan en el menú de habilidades (K).")
				return
			if not character.can_equip(cell.item):
				message.emit("Requiere nivel %d. Vuelve cuando seas senior." % cell.item.required_level())
				return
			if inv.equip_from_bag(cell.bag_index):
				item_equipped.emit()
		else:
			var destroyed := inv.remove_bag_item(cell.bag_index)
			message.emit("%s eliminado. No hay papelera de reciclaje." % destroyed.display_name())
	elif button == MOUSE_BUTTON_LEFT and not inv.unequip(cell.slot_key):
		message.emit("Inventario lleno. Como tu backlog.")
	_on_cell_hovered(cell, true)


func _on_cell_hovered(cell: ItemCell, inside: bool) -> void:
	if not inside or cell.item == null:
		_tooltip.hide()
		return
	_tooltip.show_item(cell.item, character, cell.bag_index >= 0 and cell.item.is_equipment())
