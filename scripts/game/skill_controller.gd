class_name SkillController
extends Node2D
## Lanza las habilidades de la barra (placas base instaladas) y dibuja sus
## efectos: proyectiles, explosiones, ondas y teletransporte.
## Las cifras salen de SkillCalc; aquí solo se aplican.

signal skill_used(hotbar_index: int)
signal not_enough_mana

const ACTIONS := [&"skill_1", &"skill_2", &"skill_3", &"skill_4", &"skill_5", &"skill_6"]
const KEY_LABELS := ["Der.", "Esp.", "Q", "E", "R", "F"]
const REPEAT_DELAY := 0.15
## El personaje solo se detiene un instante al lanzar (fracción del tiempo de
## uso, con tope), para no quedarse vendido entre enemigos.
const MOVE_LOCK_FRACTION := 0.25
const MAX_MOVE_LOCK := 0.15
const PROJECTILE_RADIUS := 8.0
const DAMAGE_COLORS := {
	"physical": Color("e8d9b0"),
	"fire": Color("e0652f"),
	"cold": Color("7fb8e0"),
	"lightning": Color("e8d070"),
	"chaos": Color("b04ad9"),
	"none": Color("5cb85c"),
}

var player: Player
var enemies: EnemyManager
var character: CharacterData
var cooldowns: Array[float] = []

var _profiles: Array = []         # perfil de SkillCalc por ranura ({} si vacía)
var _projectiles: Array[Dictionary] = []
var _effects: Array[Dictionary] = []      # visuales: anillos y destellos
var _pending: Array[Dictionary] = []      # explosiones retardadas y repeticiones
var _mana_warning_cooldown := 0.0
## Tiempo hasta poder lanzar otra habilidad (el ritmo de ataque/lanzamiento).
var _busy := 0.0


func setup(p_player: Player, p_enemies: EnemyManager, p_character: CharacterData) -> void:
	player = p_player
	enemies = p_enemies
	character = p_character
	cooldowns.resize(ACTIONS.size())
	cooldowns.fill(0.0)
	character.stats_changed.connect(refresh_profiles)
	character.inventory.changed.connect(refresh_profiles)
	refresh_profiles()


func refresh_profiles() -> void:
	_profiles.clear()
	for i in ACTIONS.size():
		_profiles.append(character.skill_profile(i))


func profile(index: int) -> Dictionary:
	return _profiles[index] if index < _profiles.size() else {}


## 0..1 del enfriamiento restante (para el HUD).
func cooldown_fraction(index: int) -> float:
	var p := profile(index)
	var total: float = p.get("cooldown", 0.0)
	return clampf(cooldowns[index] / total, 0.0, 1.0) if total > 0.0 else 0.0


func _physics_process(delta: float) -> void:
	for i in cooldowns.size():
		cooldowns[i] = maxf(0.0, cooldowns[i] - delta)
	_mana_warning_cooldown = maxf(0.0, _mana_warning_cooldown - delta)
	_busy = maxf(0.0, _busy - delta)
	if player.is_alive() and _busy <= 0.0:
		for i in ACTIONS.size():
			if Input.is_action_pressed(ACTIONS[i]) and try_use(i):
				break
	_update_pending(delta)
	_update_projectiles(delta)
	_update_effects(delta)
	queue_redraw()


func try_use(index: int) -> bool:
	var p := profile(index)
	if p.is_empty() or cooldowns[index] > 0.0:
		return false
	if player.mana < p["mana_cost"]:
		if _mana_warning_cooldown <= 0.0:
			_mana_warning_cooldown = 1.5
			not_enough_mana.emit()
		return false
	player.mana -= p["mana_cost"]
	cooldowns[index] = p["cooldown"]
	_busy = p["use_time"]
	player.action_lock = minf(MAX_MOVE_LOCK, p["use_time"] * MOVE_LOCK_FRACTION)
	var target := get_global_mouse_position()
	player.face(target - player.global_position)
	_execute(p, target)
	for r in int(p["repeats"]):
		_pending.append({"type": "repeat", "time": REPEAT_DELAY * (r + 1), "profile": p, "target": target})
	skill_used.emit(index)
	return true


func _execute(p: Dictionary, target: Vector2) -> void:
	var origin := player.global_position
	var color: Color = DAMAGE_COLORS.get(p["damage_type"], Color.WHITE)
	match p["kind"]:
		"melee_area", "nova":
			_damage_area(origin, p["radius"], p)
			_effects.append({"type": "ring", "pos": origin, "radius": p["radius"], "time": 0.0, "duration": 0.25, "color": color})
		"projectile":
			var dir := (target - origin).normalized()
			if dir == Vector2.ZERO:
				dir = Vector2.RIGHT
			var count: int = maxi(1, p["projectiles"])
			var spread := deg_to_rad(p["spread_degrees"])
			for k in count:
				var angle := 0.0 if count == 1 else lerpf(-spread / 2.0, spread / 2.0, float(k) / (count - 1))
				_projectiles.append({
					"pos": origin, "vel": dir.rotated(angle) * float(p["projectile_speed"]),
					"distance_left": float(p["range"]), "pierce_left": int(p["pierce"]),
					"hit_ids": {}, "profile": p, "color": color,
				})
		"ground_aoe":
			var offset := (target - origin).limit_length(p["range"])
			_pending.append({"type": "blast", "time": p["delay"], "pos": origin + offset, "profile": p, "color": color})
			_effects.append({"type": "marker", "pos": origin + offset, "radius": p["radius"], "time": 0.0, "duration": p["delay"], "color": color})
		"blink":
			var offset := (target - origin).limit_length(p["range"])
			_effects.append({"type": "ring", "pos": origin, "radius": 30.0, "time": 0.0, "duration": 0.3, "color": color})
			player.global_position = origin + offset
			player.stop_auto_move()
			_effects.append({"type": "ring", "pos": player.global_position, "radius": 40.0, "time": 0.0, "duration": 0.3, "color": color})


func _damage_area(center: Vector2, radius: float, p: Dictionary) -> void:
	enemies.hit_in_radius(center, radius, p["min_damage"], p["max_damage"], p["crit_chance"], p["crit_multiplier"])
	_leech(p)


func _leech(p: Dictionary) -> void:
	if p["life_leech"] > 0.0 and enemies.last_damage_dealt > 0.0:
		player.heal(enemies.last_damage_dealt * p["life_leech"] / 100.0)


func _update_pending(delta: float) -> void:
	var still: Array[Dictionary] = []
	for e in _pending:
		e["time"] -= delta
		if e["time"] > 0.0:
			still.append(e)
			continue
		var p: Dictionary = e["profile"]
		if e["type"] == "blast":
			_damage_area(e["pos"], p["radius"], p)
			_effects.append({"type": "burst", "pos": e["pos"], "radius": p["radius"], "time": 0.0, "duration": 0.3, "color": e["color"]})
		elif player.is_alive():
			_execute(p, e["target"])
	_pending = still


func _update_projectiles(delta: float) -> void:
	var still: Array[Dictionary] = []
	for pr in _projectiles:
		var step: Vector2 = pr["vel"] * delta
		pr["pos"] += step
		pr["distance_left"] -= step.length()
		var p: Dictionary = pr["profile"]
		var hit := enemies.hit_one(pr["pos"], PROJECTILE_RADIUS, pr["hit_ids"], p["min_damage"], p["max_damage"], p["crit_chance"], p["crit_multiplier"])
		if hit != -1:
			_leech(p)
			pr["hit_ids"][hit] = true
			pr["pierce_left"] -= 1
			_effects.append({"type": "burst", "pos": pr["pos"], "radius": 14.0, "time": 0.0, "duration": 0.15, "color": pr["color"]})
		if pr["distance_left"] > 0.0 and pr["pierce_left"] >= 0:
			still.append(pr)
	_projectiles = still


func _update_effects(delta: float) -> void:
	var still: Array[Dictionary] = []
	for e in _effects:
		e["time"] += delta
		if e["time"] < e["duration"]:
			still.append(e)
	_effects = still


func _draw() -> void:
	for e in _effects:
		var t: float = e["time"] / e["duration"]
		var c: Color = e["color"]
		match e["type"]:
			"ring":
				var r: float = e["radius"] * (0.6 + 0.4 * t)
				draw_circle(e["pos"], r, Color(c, 0.15 * (1.0 - t)))
				draw_arc(e["pos"], r, 0.0, TAU, 48, Color(c, 0.8 * (1.0 - t)), 3.0, true)
			"burst":
				draw_circle(e["pos"], e["radius"] * (0.5 + 0.5 * t), Color(c, 0.45 * (1.0 - t)))
			"marker":
				draw_arc(e["pos"], e["radius"], 0.0, TAU, 48, Color(c, 0.35 + 0.4 * t), 2.0, true)
				draw_circle(e["pos"], e["radius"] * t, Color(c, 0.12))
	for pr in _projectiles:
		var dir: Vector2 = pr["vel"].normalized()
		draw_line(pr["pos"] - dir * 18.0, pr["pos"], Color(pr["color"], 0.5), 4.0, true)
		draw_circle(pr["pos"], 5.0, pr["color"])
