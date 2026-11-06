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
## Fase de la zancada (T205): avanza con lo recorrido; -1 = quieto (respira).
var _walk := -1.0
var _time := 0.0
const STRIDE := 14.0   # px por media zancada, como el jugador del prólogo


## Fase de caminar tras recorrer `dist` px (T205): sigue la zancada desde `phase` (o
## empieza si estaba quieto).
static func walk_step(phase: float, dist: float) -> float:
	return fmod(maxf(phase, 0.0) + dist / STRIDE * PI, TAU)


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
	_time += delta
	var target := player.global_position - player.facing_direction() * FOLLOW_DISTANCE + Vector2(0, 10)
	var to := target - global_position
	if to.length() > 900.0:
		global_position = target   # se quedó atrás (portal, salto): aparece a tu lado
		_walk = -1.0
	elif to.length() > 8.0:
		var step := to.limit_length(SPEED * delta * (1.0 + to.length() / 200.0))
		global_position += step
		_facing = to.normalized()   # de espaldas, de perfil o de frente según la marcha (T205)
		_walk = walk_step(_walk, step.length())
	else:
		_walk = -1.0
		_facing = player.facing_direction()   # quieto, mira hacia donde mira el jugador
	queue_redraw()


func _draw() -> void:
	draw_set_transform(Vector2(0, 14), 0.0, Vector2(1.0, 0.35))
	draw_circle(Vector2.ZERO, 12.0, Color(0, 0, 0, 0.35))
	draw_set_transform(Vector2.ZERO)
	# Con su zancada y hacia donde va (T205); antes se deslizaba siempre de frente.
	var pose := {} if _walk >= 0.0 else {"state": "idle", "time": _time}
	CharacterAppearance.draw(self, Vector2(0, 14), 1.0, _appearance, _facing, Color(0, 0, 0, 0), _walk, pose)
	draw_string_outline(ThemeDB.fallback_font, Vector2(-80, -40), _name, HORIZONTAL_ALIGNMENT_CENTER, 160, Accessibility.world_size(12), 4, Color(0, 0, 0, 0.8))
	draw_string(ThemeDB.fallback_font, Vector2(-80, -40), _name, HORIZONTAL_ALIGNMENT_CENTER, 160, Accessibility.world_size(12), Color("8ad8ff"))
