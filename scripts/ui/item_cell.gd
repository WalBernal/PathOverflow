class_name ItemCell
extends Control
## Una casilla con un objeto: bolsa, equipo, barra de habilidades o ranura DIMM.
## Muestra el icono del objeto con el color de su rareza y admite arrastrar y
## soltar: `location` dice dónde está (ver ItemTransfer) y el panel que la crea
## decide qué hacer al soltar (dropped) o al soltarla fuera (released_outside).

signal clicked(cell: ItemCell, button: MouseButton)
signal hovered(cell: ItemCell, inside: bool)
signal dropped(target: ItemCell, payload: Dictionary)
signal released_outside(cell: ItemCell)

const BG := Color("16131b")
const BORDER := Color("3a3442")
const DRAG_PREVIEW_SIZE := Vector2(48, 48)

var item: Item
## Dónde está esta casilla (ItemTransfer): {"kind": "bag", "index": 3}, etc.
var location: Dictionary = {}
var placeholder := ""
## Color del hueco vacío (p. ej. la generación de una ranura DIMM).
var slot_color := Color(0, 0, 0, 0)
## Resaltado (p. ej. la RAM seleccionada en el menú de habilidades).
var selected := false
## Para habilidades: dibuja el icono de la habilidad en vez del de la placa.
var show_skill_icon := false
## Marca en rojo (p. ej. una RAM instalada que no afecta a su habilidad).
var warning := false

var _dragging := false


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	mouse_entered.connect(func() -> void: hovered.emit(self, true))
	mouse_exited.connect(func() -> void: hovered.emit(self, false))


func set_item(p_item: Item) -> void:
	item = p_item
	queue_redraw()


func _gui_input(event: InputEvent) -> void:
	var mb := event as InputEventMouseButton
	# Al soltar, para no confundir un click con el inicio de un arrastre.
	if mb and not mb.pressed and (mb.button_index == MOUSE_BUTTON_LEFT or mb.button_index == MOUSE_BUTTON_RIGHT):
		if not _dragging:
			clicked.emit(self, mb.button_index)
		accept_event()


# --- Arrastrar y soltar ---

func _get_drag_data(_at_position: Vector2) -> Variant:
	if item == null:
		return null
	_dragging = true
	var preview := _DragPreview.new()
	preview.item = item
	preview.size = DRAG_PREVIEW_SIZE
	preview.position = -DRAG_PREVIEW_SIZE / 2.0
	var holder := Control.new()  # el preview se centra en el cursor
	holder.add_child(preview)
	set_drag_preview(holder)
	hovered.emit(self, false)
	return {"item": item, "from": location, "origin": self}


func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	return data is Dictionary and data.has("item") and not location.is_empty()


func _drop_data(_at_position: Vector2, data: Variant) -> void:
	dropped.emit(self, data)


func _notification(what: int) -> void:
	if what == NOTIFICATION_DRAG_END and _dragging:
		_dragging = false
		if not get_viewport().gui_is_drag_successful():
			released_outside.emit(self)


# --- Dibujo ---

func _draw() -> void:
	var rect := Rect2(Vector2.ZERO, size)
	draw_rect(rect, BG)
	if slot_color.a > 0.0:
		draw_rect(rect, Color(slot_color, 0.15 if item == null else 0.3))
	var font := get_theme_default_font()
	if item == null:
		draw_rect(rect, slot_color.darkened(0.2) if slot_color.a > 0.0 else BORDER, false, 1.0)
		if placeholder != "":
			var y := size.y / 2.0 + font.get_ascent(11) / 2.0 - 1.0
			draw_string(font, Vector2(0, y), placeholder, HORIZONTAL_ALIGNMENT_CENTER, size.x, 11,
				slot_color.lightened(0.2) if slot_color.a > 0.0 else Color("4a4352"))
		if selected:
			draw_rect(rect, UiStyle.ACCENT, false, 3.0)
		return
	var color := item.display_color()
	draw_rect(rect.grow(-1.0), Color(color, 0.12))
	var board := item as Motherboard
	if board and show_skill_icon:
		SkillIcon.draw(self, rect.grow(-3.0), board.skill_def)
	else:
		ItemIcons.draw_item(self, rect.grow(-3.0), item)
	draw_rect(rect, color.darkened(0.2), false, 2.0 if item.rarity >= Rarity.Item.RARE else 1.0)
	if warning:
		draw_line(Vector2(3, 3), size - Vector2(3, 3), Color("e06c6c"), 2.0)
		draw_rect(rect, Color("e06c6c"), false, 2.0)
	if selected:
		draw_rect(rect, UiStyle.ACCENT, false, 3.0)


## Lo que se ve bajo el cursor al arrastrar.
class _DragPreview extends Control:
	var item: Item

	func _draw() -> void:
		draw_rect(Rect2(Vector2.ZERO, size), Color(0, 0, 0, 0.5))
		ItemIcons.draw_item(self, Rect2(Vector2.ZERO, size), item, Color(1, 1, 1, 0.9))
		draw_rect(Rect2(Vector2.ZERO, size), item.display_color(), false, 2.0)
