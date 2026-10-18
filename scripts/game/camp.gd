class_name Camp
extends Node2D
## Campamento seguro en el origen: suelo, empalizada, tiendas, hoguera y NPCs.
## Dentro no entran enemigos (EnemyManager.safe_radius). Todo se dibuja con
## formas mientras no haya arte; los NPCs usan la misma figura que el jugador.
##
## Click en un NPC: el jugador camina hasta él y se abre su diálogo.

signal npc_interacted(npc: Dictionary)
signal npc_hovered(npc: Dictionary)  # {} = ninguno

const DATA_PATH := "res://data/camp.json"
const TALK_RANGE := 70.0
const NPC_CLICK_RADIUS := 26.0
const GROUND := Color("231d17")
const WOOD := Color("5b3f27")

var player: Player
var character: CharacterData
var radius := 380.0
var spawn_point := Vector2(0, 60)
var camp_name := ""
var npcs: Array = []
var dialogues: Dictionary = {}

var _pending: Dictionary = {}
var _hovered := -1
var _time := 0.0


func _ready() -> void:
	var data = DataLoader.load_json(DATA_PATH)
	if data is Dictionary:
		var camp: Dictionary = data.get("camp", {})
		radius = float(camp.get("radius", radius))
		var sp: Array = camp.get("spawn", [0, 60])
		spawn_point = Vector2(sp[0], sp[1])
		camp_name = camp.get("name", "")
		npcs = data.get("npcs", [])
		dialogues = data.get("dialogues", {})


func npc_position(npc: Dictionary) -> Vector2:
	return Vector2(npc["position"][0], npc["position"][1])


func contains(pos: Vector2) -> bool:
	return pos.length() < radius


func _process(delta: float) -> void:
	_time += delta
	queue_redraw()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		var i := _npc_at(get_global_mouse_position())
		if i != _hovered:
			_hovered = i
			npc_hovered.emit(npcs[i] if i != -1 else {})
		return
	var mb := event as InputEventMouseButton
	if mb and mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT:
		var i := _npc_at(get_global_mouse_position())
		if i != -1:
			_pending = npcs[i]
			player.move_to(npc_position(_pending) + Vector2(0, 40))
			get_viewport().set_input_as_handled()


func _physics_process(_delta: float) -> void:
	if _pending.is_empty():
		return
	if player.global_position.distance_to(npc_position(_pending)) <= TALK_RANGE:
		player.stop_auto_move()
		player.face(npc_position(_pending) - player.global_position)
		npc_interacted.emit(_pending)
		_pending = {}
	elif not player.has_auto_target():
		_pending = {}


func _npc_at(pos: Vector2) -> int:
	for i in npcs.size():
		if pos.distance_to(npc_position(npcs[i]) + Vector2(0, -18)) <= NPC_CLICK_RADIUS:
			return i
	return -1


# --- Dibujo ---

func _draw() -> void:
	# Suelo de tierra con borde.
	draw_circle(Vector2.ZERO, radius + 30.0, Color(GROUND, 0.5))
	draw_circle(Vector2.ZERO, radius, GROUND)
	_draw_palisade()
	_draw_tent(Vector2(-250, -120), Color("6b2b2b"))
	_draw_tent(Vector2(250, -150), Color("2b4a6b"))
	_draw_tent(Vector2(-60, 250), Color("3a5a3a"))
	_draw_crates(Vector2(200, 130))
	_draw_crates(Vector2(-230, 120))
	_draw_campfire(Vector2(0, -10))
	_draw_sign(Vector2(0, -radius + 30.0))
	var font := ThemeDB.fallback_font
	for i in npcs.size():
		var npc: Dictionary = npcs[i]
		var pos := npc_position(npc)
		var appearance := CharacterAppearance.sanitize(npc.get("appearance", {}))
		var to_player := player.global_position - pos if player else Vector2.DOWN
		CharacterAppearance.draw(self, pos, 0.95, appearance, Vector2(signf(to_player.x) * 0.5, 1.0))
		var label_color := UiStyle.ACCENT if i == _hovered else UiStyle.TEXT
		var label_pos := pos + Vector2(-100.0, -52.0)
		draw_string_outline(font, label_pos, npc["name"], HORIZONTAL_ALIGNMENT_CENTER, 200.0, 14, 5, Color(0, 0, 0, 0.8))
		draw_string(font, label_pos, npc["name"], HORIZONTAL_ALIGNMENT_CENTER, 200.0, 14, label_color)
		if character and not character.flags.has("talked_" + npc["id"]):
			var bounce := sin(_time * 4.0) * 3.0
			draw_string_outline(font, pos + Vector2(-10.0, -70.0 + bounce), "!", HORIZONTAL_ALIGNMENT_CENTER, 20.0, 22, 5, Color.BLACK)
			draw_string(font, pos + Vector2(-10.0, -70.0 + bounce), "!", HORIZONTAL_ALIGNMENT_CENTER, 20.0, 22, UiStyle.ACCENT)


func _draw_palisade() -> void:
	var posts := 64
	for k in posts:
		var a := TAU * k / posts
		# Cuatro entradas: hacia los puntos cardinales.
		var gap := fmod(a + PI / 4.0, PI / 2.0)
		if absf(gap - PI / 4.0) < 0.12:
			continue
		var p := Vector2.from_angle(a) * radius
		draw_rect(Rect2(p + Vector2(-5, -26), Vector2(10, 26)), WOOD)
		draw_colored_polygon(PackedVector2Array([p + Vector2(-5, -26), p + Vector2(0, -34), p + Vector2(5, -26)]), WOOD.lightened(0.1))
		draw_rect(Rect2(p + Vector2(-5, -26), Vector2(10, 26)), WOOD.darkened(0.4), false, 1.0)


func _draw_tent(pos: Vector2, color: Color) -> void:
	draw_set_transform(pos + Vector2(0, 6), 0.0, Vector2(1.0, 0.35))
	draw_circle(Vector2.ZERO, 62.0, Color(0, 0, 0, 0.35))
	draw_set_transform(Vector2.ZERO)
	draw_colored_polygon(PackedVector2Array([pos + Vector2(-60, 0), pos + Vector2(0, -70), pos + Vector2(60, 0)]), color)
	draw_colored_polygon(PackedVector2Array([pos + Vector2(-14, 0), pos + Vector2(0, -42), pos + Vector2(14, 0)]), Color(0.05, 0.04, 0.05))
	draw_line(pos + Vector2(0, -70), pos + Vector2(0, -80), WOOD, 3.0)
	draw_polyline(PackedVector2Array([pos + Vector2(-60, 0), pos + Vector2(0, -70), pos + Vector2(60, 0)]), color.darkened(0.4), 2.0)


func _draw_crates(pos: Vector2) -> void:
	for offset in [Vector2(0, 0), Vector2(26, 6), Vector2(10, -22)]:
		var r := Rect2(pos + offset, Vector2(24, 22))
		draw_rect(r, WOOD.lightened(0.15))
		draw_rect(r, WOOD.darkened(0.4), false, 2.0)
		draw_line(r.position, r.end, WOOD.darkened(0.3), 1.5)


func _draw_campfire(pos: Vector2) -> void:
	# Luz.
	var flicker := 0.85 + 0.15 * sin(_time * 9.0) * sin(_time * 5.3)
	draw_circle(pos, 160.0 * flicker, Color(1.0, 0.55, 0.2, 0.05))
	draw_circle(pos, 90.0 * flicker, Color(1.0, 0.6, 0.25, 0.06))
	# Piedras y troncos.
	for k in 8:
		draw_circle(pos + Vector2.from_angle(TAU * k / 8.0) * Vector2(26, 12), 5.0, Color("4a4550"))
	draw_line(pos + Vector2(-18, 6), pos + Vector2(18, -4), WOOD, 6.0)
	draw_line(pos + Vector2(-18, -4), pos + Vector2(18, 6), WOOD.darkened(0.2), 6.0)
	# Llamas.
	var layers := [[Color("e0652f"), 16.0, 34.0], [Color("f0a030"), 11.0, 24.0], [Color("ffe070"), 6.0, 14.0]]
	for layer in layers:
		var w: float = layer[1]
		var h: float = layer[2] * (0.85 + 0.2 * sin(_time * 11.0 + w))
		var sway := sin(_time * 6.0 + w) * 3.0
		draw_colored_polygon(PackedVector2Array([pos + Vector2(-w, 0), pos + Vector2(sway, -h), pos + Vector2(w, 0)]), layer[0])


func _draw_sign(pos: Vector2) -> void:
	draw_rect(Rect2(pos + Vector2(-3, -10), Vector2(6, 40)), WOOD)
	var board := Rect2(pos + Vector2(-140, -44), Vector2(280, 34))
	draw_rect(board, WOOD.lightened(0.1))
	draw_rect(board, WOOD.darkened(0.4), false, 2.0)
	draw_string(ThemeDB.fallback_font, board.position + Vector2(0, 23), camp_name, HORIZONTAL_ALIGNMENT_CENTER, board.size.x, 15, Color("f0e0c0"))
