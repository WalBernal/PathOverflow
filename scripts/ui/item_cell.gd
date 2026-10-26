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
## Silueta tenue de lo que va en la ranura vacía (id de icono de ItemIcons).
var placeholder_icon := ""
## Ranura DIMM: se dibuja como un zócalo de memoria.
var dimm_socket := false
## Búsqueda del alijo (T80): 1 = coincide (borde dorado), -1 = no coincide (apagado), 0 = sin búsqueda.
var highlight := 0

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
	var font := get_theme_default_font()
	# Fondo con relieve: más oscuro abajo a la derecha, filo claro arriba a la izquierda.
	draw_rect(rect, BG)
	draw_rect(Rect2(rect.position, Vector2(rect.size.x, rect.size.y * 0.5)), Color(1, 1, 1, 0.025))
	if slot_color.a > 0.0:
		draw_rect(rect, Color(slot_color, 0.12 if item == null else 0.25))
	draw_line(Vector2(1, 1), Vector2(size.x - 1, 1), Color(1, 1, 1, 0.06), 1.0)
	draw_line(Vector2(1, 1), Vector2(1, size.y - 1), Color(1, 1, 1, 0.06), 1.0)
	draw_line(Vector2(1, size.y - 1), Vector2(size.x - 1, size.y - 1), Color(0, 0, 0, 0.5), 1.0)
	if item == null:
		if dimm_socket:
			_draw_dimm_socket(rect)
		elif placeholder_icon != "":
			ItemIcons.draw(self, rect.grow(-maxf(6.0, minf(size.x, size.y) * 0.18)), placeholder_icon, Color(1, 1, 1, 0.10), false)
		draw_rect(rect, slot_color.darkened(0.2) if slot_color.a > 0.0 else BORDER, false, 1.0)
		if placeholder != "" and not dimm_socket:
			var y := size.y - 5.0 if placeholder_icon != "" else size.y / 2.0 + font.get_ascent(11) / 2.0 - 1.0
			draw_string(font, Vector2(0, y), placeholder, HORIZONTAL_ALIGNMENT_CENTER, size.x, 10 if placeholder_icon != "" else 11,
				slot_color.lightened(0.2) if slot_color.a > 0.0 else Color("5a5363"))
		if selected:
			draw_rect(rect, UiStyle.ACCENT, false, 3.0)
		return
	var color := item.display_color()
	# Brillo de rareza: más intenso cuanto más raro.
	var glow := 0.10 + 0.05 * clampi(item.rarity, 0, 4)
	draw_rect(rect.grow(-1.0), Color(color, glow))
	var board := item as Motherboard
	if board and show_skill_icon:
		SkillIcon.draw(self, rect.grow(-3.0), board.skill_def)
		RamIcon.draw_board_column(self, rect.grow(-3.0), board, 3.0)
	else:
		ItemIcons.draw_item(self, rect.grow(-3.0), item)
	var ram := item as RamModule
	if ram:
		# Símbolo de su familia abajo a la derecha: así se distinguen en la bolsa.
		var s := clampf(size.x * 0.36, 10.0, 18.0)
		RamIcon.draw_badge(self, Rect2(size - Vector2(s + 3.0, s + 3.0), Vector2(s, s)), ram)
	draw_rect(rect, color.darkened(0.15), false, 2.0 if item.rarity >= Rarity.Item.RARE else 1.0)
	if item.rarity >= Rarity.Item.UNIQUE and not item is Flask and not item is KeyItem:
		draw_rect(rect.grow(-3.0), Color(color, 0.35), false, 1.0)
	if warning:
		draw_line(Vector2(3, 3), size - Vector2(3, 3), Color("e06c6c"), 2.0)
		draw_rect(rect, Color("e06c6c"), false, 2.0)
	_draw_marks()
	if highlight < 0:
		draw_rect(rect, Color(0.03, 0.02, 0.05, 0.7))
	elif highlight > 0:
		draw_rect(rect.grow(-1.0), Color("ffd84a"), false, 3.0)
	if selected:
		draw_rect(rect, UiStyle.ACCENT, false, 3.0)


## Marcas del jugador (T79): candado arriba a la izquierda (bloqueado) o el objeto
## apagado con una papelera (basura).
func _draw_marks() -> void:
	if item.junk:
		draw_rect(Rect2(Vector2.ZERO, size), Color(0.05, 0.03, 0.03, 0.55))
		var p := Vector2(3, 3)
		draw_rect(Rect2(p + Vector2(1, 3), Vector2(8, 9)), Color("c06060"))
		draw_rect(Rect2(p + Vector2(0, 1), Vector2(10, 2)), Color("e08080"))
		for k in 3:
			draw_line(p + Vector2(2.5 + k * 2.5, 5), p + Vector2(2.5 + k * 2.5, 10), Color("5a2020"), 1.0)
	elif item.locked:
		var p := Vector2(3, 4)
		draw_arc(p + Vector2(5, 4), 3.0, PI, TAU, 8, Color("f2c14e"), 1.5)
		draw_rect(Rect2(p + Vector2(1, 4), Vector2(8, 7)), Color("f2c14e"))
		draw_rect(Rect2(p + Vector2(4, 6), Vector2(2, 3)), Color("2a2010"))


## Zócalo DIMM vacío: ranura con contactos dorados y una muesca, del color de su generación.
func _draw_dimm_socket(rect: Rect2) -> void:
	var c := slot_color if slot_color.a > 0.0 else Color("5a5363")
	var slot := Rect2(rect.position + Vector2(size.x * 0.3, 4), Vector2(size.x * 0.4, size.y - 8))
	draw_rect(slot, Color(0, 0, 0, 0.6))
	draw_rect(slot, Color(c, 0.8), false, 1.0)
	for k in 5:
		var y := slot.position.y + 4 + k * (slot.size.y - 8) / 5.0
		draw_line(Vector2(slot.position.x + 2, y), Vector2(slot.end.x - 2, y), Color("8a6d3b"), 1.0)
	draw_rect(Rect2(slot.position.x - 2, slot.get_center().y - 2, slot.size.x + 4, 4), BG)   # muesca
	var font := get_theme_default_font()
	draw_string(font, Vector2(0, size.y - 1), placeholder, HORIZONTAL_ALIGNMENT_CENTER, size.x, 9, c.lightened(0.2))

## Lo que se ve bajo el cursor al arrastrar.
class _DragPreview extends Control:
	var item: Item

	func _draw() -> void:
		draw_rect(Rect2(Vector2.ZERO, size), Color(0, 0, 0, 0.5))
		ItemIcons.draw_item(self, Rect2(Vector2.ZERO, size), item, Color(1, 1, 1, 0.9))
		draw_rect(Rect2(Vector2.ZERO, size), item.display_color(), false, 2.0)
