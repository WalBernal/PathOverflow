class_name LootManager
extends Node2D
## Objetos en el suelo, dibujados como etiquetas de texto al estilo del filtro
## de botín de PoE. Click en una etiqueta: el jugador camina hasta ella y la recoge.
## Los tokens (moneda) se recogen solos al pasar cerca: se acercan al jugador.

signal hovered_item_changed(item: Item)  # null = ninguno
signal picked_up(item: Item)
signal pickup_failed(reason: String)
signal tokens_picked(amount: int)

const PICKUP_RANGE := 50.0
const FONT_SIZE := 14
const PADDING := Vector2(6.0, 3.0)
const MAX_LABEL_SHIFTS := 12
const TOKEN_PICKUP_RANGE := 34.0
const TOKEN_MAGNET_RANGE := 150.0

var player: Player
var inventory: Inventory
## Opcionales (los pone World con la zona actual): ¿se puede llegar a este
## punto? y, si no, el punto transitable más cercano.
var placement_check: Callable
var spot_fixer: Callable
## {item: Item, rect: Rect2, text: String}
var drops: Array[Dictionary] = []
## Montoncitos de tokens: {pos: Vector2, amount: int, age: float}
var coins: Array[Dictionary] = []

var _pending: Dictionary = {}
var _hovered := -1
var _alt_was := false


func _ready() -> void:
	z_index = 2  # etiquetas por encima de enemigos y jugador


## Letra de la rareza para el modo daltónico ("" en el equipo normal y lo que no es equipo).
static func rarity_tag(item: Item) -> String:
	if not item.is_equipment():
		return ""
	return {Rarity.Item.MAGIC: "M", Rarity.Item.RARE: "R", Rarity.Item.ULTRA_RARE: "UR", Rarity.Item.UNIQUE: "Ú", Rarity.Item.SET: "C"}.get(item.rarity, "")


## Filtro de botín (ver LootFilter y su ventana). Con Shift pulsado se ve todo,
## y lo que el filtro oculta aparece atenuado.
static func show_all_held() -> bool:
	return InputMap.has_action(&"show_all_loot") and Input.is_action_pressed(&"show_all_loot")


func _visible(d: Dictionary) -> bool:
	return show_all_held() or LootFilter.passes(d["item"])


func drop_item(item: Item, pos: Vector2) -> void:
	var font := ThemeDB.fallback_font
	var text := item.display_name()
	var label_size := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE) + PADDING * 2.0
	drops.append({"item": item, "rect": find_spot(pos, label_size), "text": text, "age": 0.0})
	# Botín bueno: haz de luz del color de la rareza y su propio sonido.
	if item.is_equipment() and (item.rarity == Rarity.Item.UNIQUE or item.rarity == Rarity.Item.SET):
		Sfx.play("unique_drop", -3.0)
	elif LootFilter.beams(item):
		Sfx.play("coin", -2.0, 0.65)
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


## Deja tokens en el suelo (en un punto alcanzable).
func drop_tokens(amount: int, pos: Vector2) -> void:
	if amount <= 0:
		return
	if placement_check.is_valid() and not placement_check.call(pos) and spot_fixer.is_valid():
		pos = spot_fixer.call(pos)
	coins.append({"pos": pos, "amount": amount, "age": 0.0})
	queue_redraw()


func clear_all() -> void:
	drops.clear()
	coins.clear()
	_pending = {}
	_set_hovered(-1)
	queue_redraw()


func _draw() -> void:
	var font := ThemeDB.fallback_font
	var ascent := font.get_ascent(FONT_SIZE)
	for c in coins:
		_draw_coin(c, font)
	for i in drops.size():
		var d := drops[i]
		if not _visible(d):
			continue
		var item: Item = d["item"]
		var rect: Rect2 = d["rect"]
		var color := item.display_color()
		var filtered := not LootFilter.passes(item)   # solo se ve con Shift: atenuado
		if filtered:
			color = Color(color, 0.55)
		if not filtered and (LootFilter.beams(item) or item.rarity == Rarity.Item.UNIQUE or item.rarity == Rarity.Item.SET):
			# Haz de luz: fuerte los primeros segundos, luego queda tenue (se ve de lejos).
			var strength := 0.35 + 0.4 * clampf(1.0 - float(d.get("age", 0.0)) / 4.0, 0.0, 1.0)
			var bx := rect.get_center().x
			for k in 6:
				var w := 10.0 - k * 1.4
				draw_rect(Rect2(bx - w / 2.0, rect.position.y - 260.0 + k * 40.0, w, 40.0), Color(color, strength * (0.15 + 0.12 * k)))
		draw_rect(rect, Color(0.18, 0.16, 0.22, 0.95) if i == _hovered else Color(0, 0, 0, 0.8))
		if item.rarity >= Rarity.Item.UNIQUE or not item.is_equipment() or i == _hovered:
			draw_rect(rect, color, false, 1.5)
		draw_string(font, rect.position + Vector2(PADDING.x, PADDING.y + ascent), d["text"],
			HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE, color)
		var tag := rarity_tag(item)
		if Ailments.colorblind and tag != "":
			# Modo daltónico: la rareza también en letra, en una chapita a la izquierda.
			var tw := font.get_string_size(tag, HORIZONTAL_ALIGNMENT_LEFT, -1, 11).x + 6.0
			var tr := Rect2(rect.position.x - tw - 2.0, rect.position.y + 2.0, tw, rect.size.y - 4.0)
			draw_rect(tr, Color(0, 0, 0, 0.9))
			draw_rect(tr, color, false, 1.0)
			draw_string(font, tr.position + Vector2(3, tr.size.y - 4.0), tag, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color.WHITE)


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


func _physics_process(delta: float) -> void:
	_update_coins(delta)
	var beams := false
	for d in drops:
		if float(d.get("age", 0.0)) < 4.0:
			d["age"] = float(d.get("age", 0.0)) + delta
			beams = true
	if beams or show_all_held() != _alt_was:
		_alt_was = show_all_held()
		queue_redraw()
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


## Mando: recoge el objeto más cercano a `pos` (a menos de `radius`). true si hay alguno.
func pick_near(pos: Vector2, radius: float) -> bool:
	var best := -1
	var best_d := radius
	for i in drops.size():
		if not _visible(drops[i]):
			continue
		var d: float = (drops[i]["rect"] as Rect2).get_center().distance_to(pos)
		if d < best_d:
			best_d = d
			best = i
	if best == -1:
		return false
	_pending = drops[best]
	player.move_to(_pending["rect"].get_center())
	return true


func _index_at(world_pos: Vector2) -> int:
	# De atrás hacia delante: la última etiqueta dibujada está encima.
	for i in range(drops.size() - 1, -1, -1):
		if drops[i]["rect"].has_point(world_pos) and _visible(drops[i]):
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

func _update_coins(delta: float) -> void:
	if coins.is_empty() or player == null or not player.is_alive():
		return
	var picked := 0
	for i in range(coins.size() - 1, -1, -1):
		var c := coins[i]
		c["age"] += delta
		var to_player := player.global_position - (c["pos"] as Vector2)
		var dist := to_player.length()
		if dist <= TOKEN_PICKUP_RANGE:
			picked += int(c["amount"])
			coins.remove_at(i)
		elif dist <= TOKEN_MAGNET_RANGE and c["age"] > 0.35:
			c["pos"] += to_player / dist * minf(dist, (260.0 + (TOKEN_MAGNET_RANGE - dist) * 4.0) * delta)
	if picked > 0:
		tokens_picked.emit(picked)
	queue_redraw()


func _draw_coin(c: Dictionary, font: Font) -> void:
	var p: Vector2 = c["pos"]
	var bob := sin(c["age"] * 5.0 + p.x) * 1.5
	var n := clampi(int(c["amount"]) / 8 + 1, 1, 4)
	for k in n:
		var q := p + Vector2((k - (n - 1) / 2.0) * 7.0, -bob - k % 2 * 3.0)
		draw_circle(q + Vector2(0, 2), 6.0, Color(0, 0, 0, 0.35))
		draw_circle(q, 6.0, Economy.COLOR.darkened(0.25))
		draw_circle(q, 4.5, Economy.COLOR)
		draw_line(q + Vector2(-1.5, -2.5), q + Vector2(-1.5, 2.5), Economy.COLOR.darkened(0.45), 1.2)
	draw_string(font, p + Vector2(-20, -14 - bob), "+%d" % c["amount"], HORIZONTAL_ALIGNMENT_CENTER, 40, 11, Economy.COLOR)
