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
## Resaltado (p. ej. la RAM seleccionada en el menú de habilidades).
var selected := false


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
	var color := item.display_color()
	draw_rect(rect.grow(-1.0), Color(color, 0.12))
	draw_rect(rect, color.darkened(0.2), false, 2.0 if item.rarity >= Rarity.Item.RARE else 1.0)
	var board := item as Motherboard
	var ram := item as RamModule
	if board:
		SkillIcon.draw(self, Rect2(Vector2(2, 2), Vector2(size.y - 4, size.y - 4)), board.skill_def)
		var skill_word: String = board.skill_def["name"].split(" ")[0]
		_draw_centered(font, skill_word.substr(0, 8), font_size, color, size.y * 0.5 if size.x > size.y * 1.5 else 0.0)
	elif ram:
		var ram_word: String = ram.def["name"].split(" ")[-1]
		_draw_centered(font, ram.generation(), font_size - 1, color, 0.0, -6.0)
		_draw_centered(font, ram_word.substr(0, 9), font_size, color, 0.0, 7.0)
	else:
		var short_name: String = item.base["name"].split(" ")[0]
		_draw_centered(font, short_name.substr(0, 9), font_size, color)
	if selected:
		draw_rect(rect, UiStyle.ACCENT, false, 3.0)


func _draw_centered(font: Font, text: String, font_size: int, color: Color, x_offset := 0.0, y_offset := 0.0) -> void:
	var y := size.y / 2.0 + font.get_ascent(font_size) / 2.0 - 1.0 + y_offset
	draw_string(font, Vector2(x_offset, y), text, HORIZONTAL_ALIGNMENT_CENTER, size.x - x_offset, font_size, color)
