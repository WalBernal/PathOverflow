class_name SkillController
extends Node2D
## Lanza las habilidades de la barra (placas base instaladas) y dibuja sus
## efectos: proyectiles, explosiones, ondas, teletransporte, embestidas, conos,
## rayos, bumeranes, giros, trampas y cadenas.
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
var _pending: Array[Dictionary] = []      # explosiones retardadas, rayos y repeticiones
var _spin: Dictionary = {}                # giro activo (Bucle Infinito)
var _traps: Array[Dictionary] = []        # trampas en el suelo (Bomba Lógica)
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
	character.conditions_changed.connect(refresh_profiles)
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
	_update_spin(delta)
	_update_traps(delta)
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
	var dir := (target - origin).normalized()
	if dir == Vector2.ZERO:
		dir = Vector2.RIGHT
	match p["kind"]:
		"melee_area", "nova":
			if p["stun"] > 0.0:
				enemies.stun_in_radius(origin, p["radius"], p["stun"])
				_effects.append({"type": "lock", "pos": origin, "radius": p["radius"], "time": 0.0, "duration": 0.6, "color": color})
			_damage_area(origin, p["radius"], p)
			_effects.append({"type": "ring", "pos": origin, "radius": p["radius"], "time": 0.0, "duration": 0.25, "color": color})
		"dash":
			# Embestida: se mueve con colisión (no atraviesa paredes) y golpea lo que hay en la línea.
			var offset := (target - origin).limit_length(p["range"])
			player.move_and_collide(offset)
			player.stop_auto_move()
			var end := player.global_position
			enemies.hit_in_segment(origin, end, p["width"] * 0.5, p["min_damage"], p["max_damage"], p["crit_chance"], p["crit_multiplier"])
			_leech(p)
			_effects.append({"type": "trail", "pos": origin, "end": end, "radius": p["width"], "time": 0.0, "duration": 0.3, "color": color})
		"cone":
			var half := deg_to_rad(p["angle"]) / 2.0
			enemies.hit_in_cone(origin, dir, p["radius"], half, p["min_damage"], p["max_damage"], p["crit_chance"], p["crit_multiplier"])
			_leech(p)
			_effects.append({"type": "cone", "pos": origin, "dir": dir, "radius": p["radius"], "half": half, "time": 0.0, "duration": 0.35, "color": color})
		"beam":
			_pending.append({"type": "beam", "time": p["delay"], "pos": origin, "dir": dir, "profile": p, "color": color})
			_effects.append({"type": "beam_marker", "pos": origin, "dir": dir, "radius": p["width"], "length": p["range"],
				"time": 0.0, "duration": p["delay"], "color": color})
		"boomerang":
			var count: int = maxi(1, p["projectiles"])
			var spread := deg_to_rad(p["spread_degrees"])
			for k in count:
				var angle := 0.0 if count == 1 else lerpf(-spread / 2.0, spread / 2.0, float(k) / (count - 1))
				_projectiles.append({
					"pos": origin, "vel": dir.rotated(angle) * float(p["projectile_speed"]),
					"distance_left": float(p["range"]), "pierce_left": 999, "hit_ids": {}, "profile": p,
					"color": color, "boomerang": true, "returning": false, "spin": 0.0,
				})
		"spin":
			_spin = {"time_left": p["duration"], "next_tick": 0.0, "profile": p, "color": color, "angle": 0.0}
		"trap":
			var offset := (target - origin).limit_length(p["range"])
			_traps.append({"pos": origin + offset, "armed_in": 0.5, "life": p["duration"], "profile": p, "color": color})
			while _traps.size() > maxi(1, p["max_active"]):
				_traps.pop_front()
		"chain":
			_chain(p, origin, target, color)
		"projectile":
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


## Cadena: el enemigo más cercano al cursor (a tiro) y luego salta al más cercano no golpeado.
func _chain(p: Dictionary, origin: Vector2, target: Vector2, color: Color) -> void:
	var first := enemies.nearest_index(target, 160.0)
	if first == -1 or enemies.positions[first].distance_to(origin) > p["range"]:
		first = enemies.nearest_index(origin, p["range"])
	if first == -1:
		_effects.append({"type": "zap", "pos": origin, "end": origin + (target - origin).limit_length(p["range"]), "time": 0.0, "duration": 0.2, "color": color})
		return
	var hit := {}
	var from := origin
	var i := first
	for k in int(p["chains"]) + 1:
		var at := enemies.positions[i]
		_effects.append({"type": "zap", "pos": from, "end": at, "time": -0.06 * k, "duration": 0.3, "color": color})
		hit[enemies.hit_index(i, p["min_damage"], p["max_damage"], p["crit_chance"], p["crit_multiplier"])] = true
		_leech(p)
		from = at
		i = enemies.nearest_index(at, p["chain_range"], hit)
		if i == -1:
			break


func _update_spin(delta: float) -> void:
	if _spin.is_empty():
		return
	_spin["time_left"] -= delta
	_spin["next_tick"] -= delta
	_spin["angle"] += delta * 14.0
	var p: Dictionary = _spin["profile"]
	if not player.is_alive() or _spin["time_left"] <= 0.0:
		_spin = {}
		return
	if _spin["next_tick"] <= 0.0:
		_spin["next_tick"] = p["tick"]
		_damage_area(player.global_position, p["radius"], p)


func _update_traps(delta: float) -> void:
	var still: Array[Dictionary] = []
	for trap in _traps:
		trap["armed_in"] -= delta
		trap["life"] -= delta
		var p: Dictionary = trap["profile"]
		if trap["armed_in"] <= 0.0 and enemies.nearest_index(trap["pos"], p["trigger_radius"]) != -1:
			_damage_area(trap["pos"], p["radius"], p)
			_effects.append({"type": "burst", "pos": trap["pos"], "radius": p["radius"], "time": 0.0, "duration": 0.35, "color": trap["color"]})
			continue
		if trap["life"] > 0.0:
			still.append(trap)
	_traps = still


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
		elif e["type"] == "beam":
			var end: Vector2 = e["pos"] + e["dir"] * p["range"]
			enemies.hit_in_segment(e["pos"], end, p["width"] * 0.5, p["min_damage"], p["max_damage"], p["crit_chance"], p["crit_multiplier"])
			_leech(p)
			_effects.append({"type": "beam", "pos": e["pos"], "dir": e["dir"], "radius": p["width"], "length": p["range"],
				"time": 0.0, "duration": 0.35, "color": e["color"]})
		elif player.is_alive():
			_execute(p, e["target"])
	_pending = still


func _update_projectiles(delta: float) -> void:
	var still: Array[Dictionary] = []
	for pr in _projectiles:
		var p: Dictionary = pr["profile"]
		if pr.get("boomerang", false):
			pr["spin"] += delta * 18.0
			if not pr["returning"] and pr["distance_left"] <= 0.0:
				pr["returning"] = true
				pr["hit_ids"] = {}   # a la vuelta puede volver a golpear a los mismos
			if pr["returning"]:
				var back: Vector2 = player.global_position - pr["pos"]
				if back.length() < 24.0:
					continue   # de vuelta en la mano
				pr["vel"] = back.normalized() * float(p["projectile_speed"]) * 1.15
				pr["distance_left"] = 1.0
		var step: Vector2 = pr["vel"] * delta
		pr["pos"] += step
		if not pr.get("returning", false):
			pr["distance_left"] -= step.length()
		var hit := enemies.hit_one(pr["pos"], PROJECTILE_RADIUS, pr["hit_ids"], p["min_damage"], p["max_damage"], p["crit_chance"], p["crit_multiplier"])
		if hit != -1:
			_leech(p)
			pr["hit_ids"][hit] = true
			pr["pierce_left"] -= 1
			_effects.append({"type": "burst", "pos": pr["pos"], "radius": 14.0, "time": 0.0, "duration": 0.15, "color": pr["color"]})
		if pr.get("boomerang", false) or (pr["distance_left"] > 0.0 and pr["pierce_left"] >= 0):
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
	for trap in _traps:
		var armed: bool = trap["armed_in"] <= 0.0
		var blink := armed and fmod(Time.get_ticks_msec() / 1000.0, 1.0) < 0.5
		draw_circle(trap["pos"], 9.0, Color("2a2a30"))
		draw_circle(trap["pos"], 3.0, trap["color"] if blink else Color(trap["color"], 0.3))
		draw_arc(trap["pos"], trap["profile"]["trigger_radius"], 0.0, TAU, 24, Color(trap["color"], 0.18), 1.0, true)
	if not _spin.is_empty():
		var p: Dictionary = _spin["profile"]
		var c: Color = _spin["color"]
		var center := player.global_position
		draw_circle(center, p["radius"], Color(c, 0.06))
		for k in 3:
			var a: float = _spin["angle"] + TAU * k / 3.0
			draw_arc(center, p["radius"] * 0.8, a, a + 1.1, 12, Color(c, 0.85), 5.0, true)
			draw_line(center + Vector2.from_angle(a + 1.1) * p["radius"] * 0.5, center + Vector2.from_angle(a + 1.1) * p["radius"], Color(c, 0.7), 3.0, true)
	for e in _effects:
		if e["time"] < 0.0:
			continue
		var t: float = e["time"] / e["duration"]
		var c: Color = e["color"]
		match e["type"]:
			"trail":
				var a: Vector2 = e["pos"]
				var b: Vector2 = e["end"]
				draw_line(a, b, Color(c, 0.5 * (1.0 - t)), e["radius"] * (1.0 - t * 0.5), true)
				for k in 3:
					draw_circle(a.lerp(b, (k + 1) / 4.0), 10.0, Color(c, 0.3 * (1.0 - t)))
			"cone":
				var pts := PackedVector2Array([e["pos"]])
				for k in 13:
					pts.append(e["pos"] + e["dir"].rotated(lerpf(-e["half"], e["half"], k / 12.0)) * e["radius"] * (0.5 + 0.5 * t))
				draw_colored_polygon(pts, Color(c, 0.4 * (1.0 - t)))
			"beam_marker":
				var end: Vector2 = e["pos"] + e["dir"] * e["length"]
				draw_line(e["pos"], end, Color(c, 0.25), e["radius"], true)
				draw_line(e["pos"], end, Color(c, 0.8), 2.0 + 4.0 * t, true)
			"beam":
				var end: Vector2 = e["pos"] + e["dir"] * e["length"]
				draw_line(e["pos"], end, Color(c, 0.6 * (1.0 - t)), e["radius"] * (1.0 + t * 0.3), true)
				draw_line(e["pos"], end, Color(1, 1, 1, 0.9 * (1.0 - t)), e["radius"] * 0.3, true)
			"zap":
				var a: Vector2 = e["pos"]
				var b: Vector2 = e["end"]
				var pts := PackedVector2Array([a])
				var side := (b - a).orthogonal().normalized()
				for k in range(1, 6):
					pts.append(a.lerp(b, k / 6.0) + side * randf_range(-10.0, 10.0))
				pts.append(b)
				draw_polyline(pts, Color(c, 1.0 - t), 3.0, true)
				draw_circle(b, 8.0 * (1.0 - t), Color(c, 0.6 * (1.0 - t)))
			"lock":
				var r: float = e["radius"]
				for k in 6:
					var q: Vector2 = e["pos"] + Vector2.from_angle(TAU * k / 6.0 + t) * r * 0.7
					draw_rect(Rect2(q - Vector2(5, 3), Vector2(10, 8)), Color(c, 0.8 * (1.0 - t)))
					draw_arc(q - Vector2(0, 3), 4.0, PI, TAU, 8, Color(c, 0.8 * (1.0 - t)), 2.0)
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
		if pr.get("boomerang", false):
			# Arma girando: dos aspas.
			var a: float = pr["spin"]
			for k in 2:
				var d := Vector2.from_angle(a + PI * k)
				draw_line(pr["pos"] - d * 12.0, pr["pos"] + d * 12.0, pr["color"], 4.0, true)
			continue
		var dir: Vector2 = pr["vel"].normalized()
		draw_line(pr["pos"] - dir * 18.0, pr["pos"], Color(pr["color"], 0.5), 4.0, true)
		draw_circle(pr["pos"], 5.0, pr["color"])
