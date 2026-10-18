class_name ItemCell
extends Control
## Una casilla del inventario o del equipo. Sin iconos todavía: muestra el
## nombre corto de la base, con el color y el borde de la rareza.

signal clicked(cell: ItemCell, button: MouseButton)
signal hovered(cell: ItemCell, inside: bool)

const BG := Color("16131b")
const BORDER := Color("3a3442")

var item: Item
## Ranura de equipo ("weapon"...) o "" si es una casilla de la bolsa.
var slot_key := ""
var bag_index := -1
var placeholder := ""


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	mouse_entered.connect(func() -> void: hovered.emit(self, true))
	mouse_exited.connect(func() -> void: hovered.emit(self, false))


func set_item(p_item: Item) -> void:
	item = p_item
	queue_redraw()


func _gui_input(event: InputEvent) -> void:
	var mb := event as InputEventMouseButton
	if mb and mb.pressed and (mb.button_index == MOUSE_BUTTON_LEFT or mb.button_index == MOUSE_BUTTON_RIGHT):
		clicked.emit(self, mb.button_index)
		accept_event()


func _draw() -> void:
	var rect := Rect2(Vector2.ZERO, size)
	draw_rect(rect, BG)
	var font := get_theme_default_font()
	var font_size := 11
	if item == null:
		draw_rect(rect, BORDER, false, 1.0)
		if placeholder != "":
			_draw_centered(font, placeholder, font_size, Color("4a4352"))
		return
	var color := Rarity.item_color(item.rarity)
	draw_rect(rect.grow(-1.0), Color(color, 0.12))
	draw_rect(rect, color.darkened(0.2), false, 2.0 if item.rarity >= Rarity.Item.RARE else 1.0)
	var short_name: String = item.base["name"].split(" ")[0]
	_draw_centered(font, short_name.substr(0, 9), font_size, color)


func _draw_centered(font: Font, text: String, font_size: int, color: Color) -> void:
	var y := size.y / 2.0 + font.get_ascent(font_size) / 2.0 - 1.0
	draw_string(font, Vector2(0, y), text, HORIZONTAL_ALIGNMENT_CENTER, size.x, font_size, color)
