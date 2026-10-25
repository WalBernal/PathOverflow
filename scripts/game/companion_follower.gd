class_name CompanionFollower
extends Node2D
## El acompañante (Companions) caminando detrás del jugador, con su aspecto de NPC.

const FOLLOW_DISTANCE := 70.0
const SPEED := 260.0

var npc_id := ""
var player: Player
var _appearance: Dictionary = {}
var _name := ""
var _facing := Vector2.DOWN


func setup(p_player: Player, id: String) -> void:
	player = p_player
	npc_id = id
	var npc: Dictionary = Zone.npc_database().get("npcs", {}).get(id, {})
	_appearance = CharacterAppearance.sanitize(npc.get("appearance", {}))
	_name = String(Companions.DEFS.get(id, {}).get("name", npc.get("name", id)))
	global_position = player.global_position + Vector2(-FOLLOW_DISTANCE, 20)


func _process(delta: float) -> void:
	if player == null:
		return
	var target := player.global_position - player.facing_direction() * FOLLOW_DISTANCE + Vector2(0, 10)
	var to := target - global_position
	if to.length() > 900.0:
		global_position = target   # se quedó atrás (portal, salto): aparece a tu lado
	elif to.length() > 8.0:
		global_position += to.limit_length(SPEED * delta * (1.0 + to.length() / 200.0))
		_facing = to.normalized()
	queue_redraw()


func _draw() -> void:
	draw_set_transform(Vector2(0, 14), 0.0, Vector2(1.0, 0.35))
	draw_circle(Vector2.ZERO, 12.0, Color(0, 0, 0, 0.35))
	draw_set_transform(Vector2.ZERO)
	CharacterAppearance.draw(self, Vector2(0, 14), 1.0, _appearance, Vector2(signf(_facing.x) * 0.5, 1.0))
	draw_string_outline(ThemeDB.fallback_font, Vector2(-80, -40), _name, HORIZONTAL_ALIGNMENT_CENTER, 160, 12, 4, Color(0, 0, 0, 0.8))
	draw_string(ThemeDB.fallback_font, Vector2(-80, -40), _name, HORIZONTAL_ALIGNMENT_CENTER, 160, 12, Color("8ad8ff"))
