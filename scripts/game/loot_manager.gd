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
const MAX_LABEL_SHIFTS := 12

var player: Player
var inventory: Inventory
## Opcionales (los pone World con la zona actual): ¿se puede llegar a este
## punto? y, si no, el punto transitable más cercano.
var placement_check: Callable
var spot_fixer: Callable
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
	drops.append({"item": item, "rect": find_spot(pos, label_size), "text": text})
	queue_redraw()


## Busca, en espiral alrededor de `pos`, un hueco donde la etiqueta no tape a
## otras y su centro sea alcanzable (dentro de la zona, fuera de obstáculos).
func find_spot(pos: Vector2, label_size: Vector2) -> Rect2:
	var start := pos
	if placement_check.is_valid() and not placement_check.call(start):
		start = spot_fixer.call(start) if spot_fixer.is_valid() else start
	var fallback := Rect2(start - label_size / 2.0, label_size)
	for ring in MAX_LABEL_SHIFTS:
		var count := 1 if ring == 0 else 8 + ring * 2
		for k in count:
			var a := TAU * k / count + ring * 0.7
			var center := start + Vector2(cos(a) * ring * 48.0, sin(a) * ring * (label_size.y + 4.0))
			var rect := Rect2(center - label_size / 2.0, label_size)
			if _overlaps(rect):
				continue
			if placement_check.is_valid() and not placement_check.call(center):
				continue
			return rect
	return fallback


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
		var color := item.display_color()
		draw_rect(rect, Color(0.18, 0.16, 0.22, 0.95) if i == _hovered else Color(0, 0, 0, 0.8))
		if item.rarity >= Rarity.Item.UNIQUE or not item.is_equipment() or i == _hovered:
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
