class_name LootManager
extends Node2D
## Objetos en el suelo, dibujados como etiquetas de texto al estilo del filtro
## de botín de PoE. Click en una etiqueta: el jugador camina hasta ella y la recoge.

signal hovered_item_changed(item: Item)  # null = ninguno
signal picked_up(item: Item)
signal pickup_failed(reason: String)

const PICKUP_RANGE := 50.0
const FONT_SIZE := 14
const PADDING := Vector2(6.0, 3.0)
const MAX_LABEL_SHIFTS := 30

var player: Player
var inventory: Inventory
## {item: Item, rect: Rect2, text: String}
var drops: Array[Dictionary] = []

var _pending: Dictionary = {}
var _hovered := -1


func _ready() -> void:
	z_index = 2  # etiquetas por encima de enemigos y jugador


func drop_item(item: Item, pos: Vector2) -> void:
	var font := ThemeDB.fallback_font
	var text := item.display_name()
	var label_size := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE) + PADDING * 2.0
	var rect := Rect2(pos - label_size / 2.0, label_size)
	# Evita que las etiquetas se tapen entre sí, apilándolas hacia abajo.
	var shifts := 0
	while shifts < MAX_LABEL_SHIFTS and _overlaps(rect):
		rect.position.y += label_size.y + 2.0
		shifts += 1
	drops.append({"item": item, "rect": rect, "text": text})
	queue_redraw()


func clear_all() -> void:
	drops.clear()
	_pending = {}
	_set_hovered(-1)
	queue_redraw()


func _draw() -> void:
	var font := ThemeDB.fallback_font
	var ascent := font.get_ascent(FONT_SIZE)
	for i in drops.size():
		var d := drops[i]
		var item: Item = d["item"]
		var rect: Rect2 = d["rect"]
		var color := Rarity.item_color(item.rarity)
		draw_rect(rect, Color(0.18, 0.16, 0.22, 0.95) if i == _hovered else Color(0, 0, 0, 0.8))
		if item.rarity >= Rarity.Item.UNIQUE or i == _hovered:
			draw_rect(rect, color, false, 1.5)
		draw_string(font, rect.position + Vector2(PADDING.x, PADDING.y + ascent), d["text"],
			HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE, color)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		_set_hovered(_index_at(get_global_mouse_position()))
		return
	var mb := event as InputEventMouseButton
	if mb and mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT:
		var i := _index_at(get_global_mouse_position())
		if i != -1:
			_pending = drops[i]
			player.move_to(_pending["rect"].get_center())
			get_viewport().set_input_as_handled()


func _physics_process(_delta: float) -> void:
	if _pending.is_empty() or player == null:
		return
	if not drops.has(_pending):
		_pending = {}
		return
	var center: Vector2 = _pending["rect"].get_center()
	if player.global_position.distance_to(center) <= PICKUP_RANGE:
		var item: Item = _pending["item"]
		if inventory.add_item(item):
			drops.erase(_pending)
			picked_up.emit(item)
			_set_hovered(-1)
			queue_redraw()
		else:
			pickup_failed.emit("Inventario lleno. Como tu backlog.")
		player.stop_auto_move()
		_pending = {}
	elif not player.has_auto_target():
		_pending = {}  # el jugador cambió de idea


func _index_at(world_pos: Vector2) -> int:
	# De atrás hacia delante: la última etiqueta dibujada está encima.
	for i in range(drops.size() - 1, -1, -1):
		if drops[i]["rect"].has_point(world_pos):
			return i
	return -1


func _overlaps(rect: Rect2) -> bool:
	for d in drops:
		if d["rect"].intersects(rect):
			return true
	return false


func _set_hovered(i: int) -> void:
	if i == _hovered:
		return
	_hovered = i
	hovered_item_changed.emit(drops[i]["item"] if i != -1 else null)
	queue_redraw()
