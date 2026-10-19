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
var _spins: Array[Dictionary] = []        # giros activos (Bucle Infinito; también de torretas)
var _traps: Array[Dictionary] = []        # trampas en el suelo (Bomba Lógica)
## Trampas, minas y torretas de las RAM de despliegue: ejecutan la habilidad solas.
var _devices: Array[Dictionary] = []
var _minions: Array[Dictionary] = []      # esbirros (Proceso Hijo)
var _clouds: Array[Dictionary] = []       # charcos de daño degenerativo (Fuga de Memoria)
var _drones: Array[Dictionary] = []       # drones que orbitan y disparan (Drones de Vigilancia)

const DEVICE_RULES := {
	"trap": {"range": 450.0, "armed": 0.4, "life": 16.0, "trigger": 50.0, "max": 3},
	"mine": {"range": 350.0, "armed": 1.1, "life": 25.0, "trigger": 75.0, "max": 5},
	"totem": {"range": 300.0, "armed": 0.3, "life": 8.0, "trigger": 650.0, "max": 1},
}
const MINION_SPEED := 240.0
const MINION_SEARCH := 450.0
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
	if player.is_alive() and _busy <= 0.0 and not player.controls_locked:
		for i in ACTIONS.size():
			if Input.is_action_pressed(ACTIONS[i]) and try_use(i):
				break
	_update_pending(delta)
	_update_projectiles(delta)
	_update_spin(delta)
	_update_traps(delta)
	_update_devices(delta)
	_update_minions(delta)
	_update_clouds(delta)
	_update_drones(delta)
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
	Sfx.play(Sfx.skill_sound("trap" if p["deploy"] != "" else String(p["kind"]), String(p["damage_type"])))
	if p["deploy"] != "":
		_deploy(p, target)
		skill_used.emit(index)
		return true
	_execute(p, target)
	for r in int(p["repeats"]):
		_pending.append({"type": "repeat", "time": REPEAT_DELAY * (r + 1), "profile": p, "target": target})
	skill_used.emit(index)
	return true


## Lo que hay activo ahora mismo (para los recuadros del HUD): esbirros, torretas,
## trampas, minas y giros, agrupados. Cada entrada: {name, skill, count, remaining, total, kind}.
func active_summaries() -> Array[Dictionary]:
	var groups := {}
	var add := func(key: String, name: String, skill: Dictionary, remaining: float, total: float, kind: String) -> void:
		if not groups.has(key):
			groups[key] = {"name": name, "skill": skill, "count": 0, "remaining": 0.0, "total": total, "kind": kind}
		var g: Dictionary = groups[key]
		g["count"] += 1
		g["remaining"] = maxf(g["remaining"], remaining)
		g["total"] = maxf(g["total"], total)
	var skills_db: Dictionary = GameData.items.skills.skills if GameData.items else {}
	for m in _minions:
		var id: String = m["profile"]["id"]
		add.call("minion:" + id, "Esbirros", skills_db.get(id, {}), m["life"], m["total"], "minion")
	for d in _drones:
		var id: String = d["profile"]["id"]
		add.call("drones:" + id, "Drones", skills_db.get(id, {}), d["life"], d["total"], "drones")
	var device_names := {"trap": "Trampas", "mine": "Minas", "totem": "Torreta"}
	for d in _devices:
		var id: String = d["profile"]["id"]
		add.call(d["kind"] + ":" + id, device_names[d["kind"]], skills_db.get(id, {}), d["life"], d["total"], d["kind"])
	for trap in _traps:
		var id: String = trap["profile"]["id"]
		add.call("bomb:" + id, "Bombas", skills_db.get(id, {}), trap["life"], trap["profile"]["duration"], "trap")
	for spin in _spins:
		var id: String = spin["profile"]["id"]
		add.call("spin:" + id, "Giro", skills_db.get(id, {}), spin["time_left"], spin["profile"]["duration"], "spin")
	var result: Array[Dictionary] = []
	for g in groups.values():
		result.append(g)
	return result


## `from`: si se indica, la usa un dispositivo (trampa, mina, torreta) desde ahí.
func _execute(p: Dictionary, target: Vector2, from := Vector2.INF) -> void:
	var device := from != Vector2.INF
	var origin := from if device else player.global_position
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
			var end := origin + offset
			if not device:
				player.move_and_collide(offset)
				player.stop_auto_move()
				end = player.global_position
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
			_spins.append({"time_left": p["duration"], "next_tick": 0.0, "profile": p, "color": color, "angle": 0.0,
				"center": origin if device else Vector2.INF})
		"minion":
			for k in maxi(1, p["count"]):
				_minions.append({"pos": origin + Vector2.from_angle(TAU * k / maxf(1.0, p["count"])) * 30.0,
					"life": p["duration"], "total": p["duration"], "cd": 0.3, "profile": p, "color": color, "phase": randf() * TAU})
			while _minions.size() > maxi(1, p["max_active"]) + int(p.get("count", 0)):
				_minions.pop_front()
			_effects.append({"type": "ring", "pos": origin, "radius": 50.0, "time": 0.0, "duration": 0.3, "color": color})
		"barrier":
			if not device:
				player.add_barrier(p["barrier"], p["duration"])
			_effects.append({"type": "ring", "pos": origin, "radius": 60.0, "time": 0.0, "duration": 0.5, "color": Color("cfe8ff")})
		"buff":
			if not device:
				var mods: Array[Modifier] = []
				for md in p["buff_mods"]:
					mods.append(Modifier.from_dict(md, "skill:" + String(p["id"])))
				character.add_timed_effect("skill:" + String(p["id"]), mods, p["duration"])
			_effects.append({"type": "ring", "pos": origin, "radius": 45.0, "time": 0.0, "duration": 0.6, "color": Color("e8d070")})
		"curse_area":
			var offset := (target - origin).limit_length(p["range"])
			var center := origin + offset
			var dps: float = (p["min_damage"] + p["max_damage"]) / 2.0
			enemies.dot_in_radius(center, p["radius"], dps, p["duration"])
			_effects.append({"type": "curse", "pos": center, "radius": p["radius"], "time": 0.0, "duration": 0.8, "color": color})
		"dot_projectile", "homing":
			var count: int = maxi(1, p["projectiles"])
			var spread := deg_to_rad(p["spread_degrees"])
			for k in count:
				var angle := 0.0 if count == 1 else lerpf(-spread / 2.0, spread / 2.0, float(k) / (count - 1))
				_projectiles.append({
					"pos": origin, "vel": dir.rotated(angle) * float(p["projectile_speed"]),
					"distance_left": float(p["range"]), "pierce_left": int(p["pierce"]),
					"hit_ids": {}, "profile": p, "color": color, "chains_left": int(p["projectile_chains"]),
					"dot": p["kind"] == "dot_projectile", "homing": p["kind"] == "homing",
				})
		"drones":
			var n: int = maxi(1, p["drone_count"])
			for k in n:
				_drones.append({"angle": TAU * k / n, "life": p["duration"], "total": p["duration"],
					"next": 0.3 + 0.25 * k, "profile": p, "color": color})
			while _drones.size() > n * 2:
				_drones.pop_front()
		"degen_area":
			var offset := (target - origin).limit_length(p["range"])
			_clouds.append({"pos": origin + offset, "life": p["duration"], "next": 0.0, "profile": p, "color": color, "seed": randi()})
		"trap":
			var offset := (target - origin).limit_length(p["range"])
			_traps.append({"pos": origin + offset, "armed_in": 0.5, "life": p["duration"], "profile": p, "color": color})
			while _traps.size() > maxi(1, p["max_active"]) + int(p.get("extra_devices", 0)):
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
					"hit_ids": {}, "profile": p, "color": color, "chains_left": int(p["projectile_chains"]),
				})
		"ground_aoe":
			var offset := (target - origin).limit_length(p["range"])
			_pending.append({"type": "blast", "time": p["delay"], "pos": origin + offset, "profile": p, "color": color})
			_effects.append({"type": "marker", "pos": origin + offset, "radius": p["radius"], "time": 0.0, "duration": p["delay"], "color": color})
		"blink":
			if device:
				return
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
	var still: Array[Dictionary] = []
	for spin in _spins:
		spin["time_left"] -= delta
		spin["next_tick"] -= delta
		spin["angle"] += delta * 14.0
		var p: Dictionary = spin["profile"]
		var own: bool = spin["center"] == Vector2.INF
		if spin["time_left"] <= 0.0 or (own and not player.is_alive()):
			continue
		if spin["next_tick"] <= 0.0:
			spin["next_tick"] = p["tick"]
			_damage_area(_spin_center(spin), p["radius"], p)
		still.append(spin)
	_spins = still


func _spin_center(spin: Dictionary) -> Vector2:
	return player.global_position if spin["center"] == Vector2.INF else spin["center"]


# --- Trampas, minas y torretas (RAM de despliegue) ---

func _deploy(p: Dictionary, target: Vector2) -> void:
	var kind: String = p["deploy"]
	var rules: Dictionary = DEVICE_RULES[kind]
	var origin := player.global_position
	var inner := p.duplicate()
	inner["deploy"] = ""
	var life: float = p["totem_duration"] if kind == "totem" else rules["life"]
	_devices.append({"kind": kind, "pos": origin + (target - origin).limit_length(rules["range"]), "armed_in": rules["armed"],
		"life": life, "total": life, "profile": inner, "next_use": 0.0,
		"interval": maxf(0.35, float(p["use_time"]) * 1.25), "color": DAMAGE_COLORS.get(p["damage_type"], Color.WHITE)})
	# Límite por tipo: se retira el más antiguo.
	var same: Array = _devices.filter(func(d: Dictionary) -> bool: return d["kind"] == kind)
	if same.size() > int(rules["max"]) + int(p.get("extra_devices", 0)):
		_devices.erase(same[0])


func _update_devices(delta: float) -> void:
	var still: Array[Dictionary] = []
	for d in _devices:
		d["life"] -= delta
		d["armed_in"] -= delta
		if d["life"] <= 0.0:
			continue
		var rules: Dictionary = DEVICE_RULES[d["kind"]]
		if d["armed_in"] > 0.0:
			still.append(d)
			continue
		var i := enemies.nearest_index(d["pos"], rules["trigger"])
		if d["kind"] == "totem":
			d["next_use"] -= delta
			if i != -1 and d["next_use"] <= 0.0:
				d["next_use"] = d["interval"]
				_execute(d["profile"], enemies.positions[i], d["pos"])
			still.append(d)
		elif i != -1:
			# Trampa o mina: se activa contra el enemigo que la pisa y desaparece.
			_execute(d["profile"], enemies.positions[i], d["pos"])
			_effects.append({"type": "burst", "pos": d["pos"], "radius": 26.0, "time": 0.0, "duration": 0.25, "color": d["color"]})
		else:
			still.append(d)
	_devices = still


# --- Esbirros ---

func _update_minions(delta: float) -> void:
	var still: Array[Dictionary] = []
	for m in _minions:
		m["life"] -= delta
		m["cd"] -= delta
		m["phase"] += delta * 8.0
		if m["life"] <= 0.0:
			continue
		var p: Dictionary = m["profile"]
		var pos: Vector2 = m["pos"]
		var i := enemies.nearest_index(pos, MINION_SEARCH)
		if i != -1 and enemies.positions[i].distance_to(player.global_position) < MINION_SEARCH * 1.6:
			var to := enemies.positions[i] - pos
			var reach := enemies.radii[i] + 14.0
			if to.length() > reach:
				m["pos"] = pos + to.normalized() * minf(MINION_SPEED * delta, to.length() - reach)
			elif m["cd"] <= 0.0:
				m["cd"] = SkillCalc.MINION_ATTACK_INTERVAL
				enemies.hit_index(i, p["min_damage"], p["max_damage"], p["crit_chance"], p["crit_multiplier"])
				_effects.append({"type": "burst", "pos": pos + to.normalized() * 14.0, "radius": 12.0, "time": 0.0, "duration": 0.15, "color": m["color"]})
		else:
			# Sin enemigos cerca: siguen al jugador.
			var to_player := player.global_position - pos
			if to_player.length() > 80.0:
				m["pos"] = pos + to_player.normalized() * MINION_SPEED * delta
		still.append(m)
	_minions = still


# --- Drones ---

func _update_drones(delta: float) -> void:
	var still: Array[Dictionary] = []
	for d in _drones:
		d["life"] -= delta
		d["next"] -= delta
		d["angle"] += delta * 1.6
		if d["life"] <= 0.0 or not player.is_alive():
			continue
		var p: Dictionary = d["profile"]
		var pos := _drone_pos(d)
		if d["next"] <= 0.0:
			var t := enemies.nearest_index(pos, p["seek_range"])
			if t != -1:
				d["next"] = p["tick"]
				var dir: Vector2 = (enemies.positions[t] - pos).normalized()
				_projectiles.append({"pos": pos, "vel": dir * float(p["projectile_speed"]), "distance_left": p["seek_range"] * 1.5,
					"pierce_left": 0, "hit_ids": {}, "profile": p, "color": d["color"], "chains_left": 0, "homing": true})
			else:
				d["next"] = 0.2
		still.append(d)
	_drones = still


func _drone_pos(d: Dictionary) -> Vector2:
	return player.global_position + Vector2.from_angle(d["angle"]) * Vector2(55, 34) + Vector2(0, -28)


# --- Charcos degenerativos ---

func _update_clouds(delta: float) -> void:
	var still: Array[Dictionary] = []
	for c in _clouds:
		c["life"] -= delta
		c["next"] -= delta
		var p: Dictionary = c["profile"]
		if c["next"] <= 0.0:
			c["next"] = p["tick"]
			# base_damage es por segundo: cada tick hace la parte proporcional.
			var k: float = p["tick"]
			enemies.hit_in_radius(c["pos"], p["radius"], p["min_damage"] * k, p["max_damage"] * k, 0.0, 100.0)
			_leech(p)
		if c["life"] > 0.0:
			still.append(c)
	_clouds = still

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
		if pr.get("homing", false):
			# Teledirigido: gira hacia el enemigo más cercano que no haya tocado.
			var t := enemies.nearest_index(pr["pos"], p["seek_range"], pr["hit_ids"])
			if t != -1:
				var want: Vector2 = (enemies.positions[t] - pr["pos"]).normalized()
				var cur: Vector2 = pr["vel"].normalized()
				var turned := cur.slerp(want, clampf(p["turn_rate"] * delta, 0.0, 1.0))
				pr["vel"] = turned * pr["vel"].length()
		var step: Vector2 = pr["vel"] * delta
		pr["pos"] += step
		if not pr.get("returning", false):
			pr["distance_left"] -= step.length()
		var hit := -1
		if pr.get("dot", false):
			hit = enemies.dot_one(pr["pos"], PROJECTILE_RADIUS, pr["hit_ids"], (p["min_damage"] + p["max_damage"]) / 2.0, p["duration"])
		else:
			hit = enemies.hit_one(pr["pos"], PROJECTILE_RADIUS, pr["hit_ids"], p["min_damage"], p["max_damage"], p["crit_chance"], p["crit_multiplier"])
		if hit != -1:
			_leech(p)
			pr["hit_ids"][hit] = true
			var next := enemies.nearest_index(pr["pos"], 260.0, pr["hit_ids"]) if pr.get("chains_left", 0) > 0 else -1
			if next != -1:
				# Encadenamiento: rebota hacia otro enemigo en vez de gastar perforación.
				pr["chains_left"] -= 1
				pr["vel"] = (enemies.positions[next] - pr["pos"]).normalized() * pr["vel"].length()
				pr["distance_left"] = maxf(pr["distance_left"], 300.0)
			else:
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
	_draw_clouds()
	_draw_devices()
	_draw_minions()
	for d in _drones:
		var dp := _drone_pos(d)
		draw_circle(dp + Vector2(0, 30), 5.0, Color(0, 0, 0, 0.25))
		draw_rect(Rect2(dp - Vector2(7, 3), Vector2(14, 6)), Color("3a3f4a"))
		for s in [-1.0, 1.0]:
			draw_line(dp + Vector2(s * 7, -1), dp + Vector2(s * 13, -4), Color("8a8a96"), 1.5)
			draw_circle(dp + Vector2(s * 13, -4), 3.5 + sin(Time.get_ticks_msec() / 30.0) * 0.5, Color(0.8, 0.8, 0.9, 0.35))
		draw_circle(dp, 2.0, d["color"])
	for spin in _spins:
		var p: Dictionary = spin["profile"]
		var c: Color = spin["color"]
		var center := _spin_center(spin)
		draw_circle(center, p["radius"], Color(c, 0.06))
		for k in 3:
			var a: float = spin["angle"] + TAU * k / 3.0
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
			"curse":
				# Ransomware: candado violeta que se cierra sobre la zona.
				var r: float = e["radius"]
				draw_circle(e["pos"], r, Color(c, 0.15 * (1.0 - t)))
				draw_arc(e["pos"], r * (1.2 - 0.2 * t), 0.0, TAU, 48, Color(c, 0.8 * (1.0 - t)), 3.0, true)
				draw_rect(Rect2(e["pos"] + Vector2(-14, -6), Vector2(28, 22)), Color(c, 0.8 * (1.0 - t)))
				draw_arc(e["pos"] + Vector2(0, -6), 10.0, PI, TAU, 12, Color(c, 0.8 * (1.0 - t)), 4.0)
				draw_string(ThemeDB.fallback_font, e["pos"] + Vector2(-40, 34), "PAGA 0.5 BTC", HORIZONTAL_ALIGNMENT_CENTER, 80, 11, Color(c.lightened(0.4), 1.0 - t))
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
		if pr.get("dot", false):
			# Paquete corrupto: borroso y con glitch.
			draw_circle(pr["pos"], 7.0, Color(pr["color"], 0.6))
			draw_rect(Rect2(pr["pos"] - Vector2(5, 2) + dir.orthogonal() * randf_range(-3, 3), Vector2(10, 4)), Color(0.3, 1.0, 0.6, 0.7))
			continue
		draw_line(pr["pos"] - dir * (26.0 if pr.get("homing", false) else 18.0), pr["pos"], Color(pr["color"], 0.5), 4.0, true)
		draw_circle(pr["pos"], 5.0, pr["color"])


func _draw_devices() -> void:
	var t := Time.get_ticks_msec() / 1000.0
	for d in _devices:
		var p: Vector2 = d["pos"]
		var c: Color = d["color"]
		var armed: bool = d["armed_in"] <= 0.0
		match String(d["kind"]):
			"trap":
				# Cepo con una placa base encima.
				draw_circle(p, 12.0, Color("3a2a1a"))
				for k in 6:
					var a := TAU * k / 6.0
					draw_line(p + Vector2.from_angle(a) * 8.0, p + Vector2.from_angle(a) * 14.0, Color("8a8a8a"), 2.0)
				draw_rect(Rect2(p - Vector2(5, 4), Vector2(10, 8)), Color("2f6a3a"))
				draw_circle(p, 2.5, c if armed and fmod(t, 0.8) < 0.4 else Color(c, 0.3))
			"mine":
				# Casi invisible: solo un parpadeo cuando está armada.
				var alpha := 0.25 if armed else 0.6
				var hexagon := PackedVector2Array()
				for k in 6:
					hexagon.append(p + Vector2.from_angle(TAU * k / 6.0) * 9.0)
				draw_colored_polygon(hexagon, Color(0.2, 0.2, 0.25, alpha))
				if armed and fmod(t + p.x * 0.01, 1.5) < 0.15:
					draw_circle(p, 3.0, Color(1.0, 0.3, 0.2))
			"totem":
				# Torreta: un mini servidor con antena y un aro de alcance.
				var life: float = d["life"] / maxf(0.1, d["total"])
				draw_arc(p, 30.0, -PI / 2.0, -PI / 2.0 + TAU * life, 32, Color(c, 0.7), 2.0, true)
				draw_rect(Rect2(p + Vector2(-11, -30), Vector2(22, 32)), Color("23262e"))
				draw_rect(Rect2(p + Vector2(-11, -30), Vector2(22, 32)), Color("4a4f5c"), false, 2.0)
				for k in 3:
					var on := fmod(t * 3.0 + k, 2.0) < 1.0
					draw_circle(p + Vector2(6, -22 + k * 8), 2.0, c if on else Color("1a2a1a"))
				draw_line(p + Vector2(0, -30), p + Vector2(0, -42), Color("8a8a8a"), 2.0)
				draw_circle(p + Vector2(0, -43), 3.0, c)


func _draw_minions() -> void:
	for m in _minions:
		var p: Vector2 = m["pos"]
		var bob := sin(m["phase"]) * 1.5
		draw_set_transform(p + Vector2(0, 8), 0.0, Vector2(1.0, 0.4))
		draw_circle(Vector2.ZERO, 9.0, Color(0, 0, 0, 0.35))
		draw_set_transform(Vector2.ZERO)
		draw_rect(Rect2(p + Vector2(-6, -8 + bob), Vector2(12, 14)), Color("2f4a3a"))
		draw_rect(Rect2(p + Vector2(-8, -20 + bob), Vector2(16, 12)), Color("b8b8b0"))
		draw_rect(Rect2(p + Vector2(-6, -18 + bob), Vector2(12, 8)), Color("10200f"))
		draw_string(ThemeDB.fallback_font, p + Vector2(-5, -11 + bob), ">_", HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Color("3cff6a"))
		var life: float = m["life"] / maxf(0.1, m["total"])
		draw_rect(Rect2(p + Vector2(-10, -26), Vector2(20 * life, 2)), Color("7fd07f"))


func _draw_clouds() -> void:
	var t := Time.get_ticks_msec() / 1000.0
	for c in _clouds:
		var p: Vector2 = c["pos"]
		var r: float = c["profile"]["radius"]
		var fade := clampf(c["life"] / 0.4, 0.0, 1.0)
		var col: Color = c["color"]
		draw_set_transform(p, 0.0, Vector2(1.0, 0.7))
		draw_circle(Vector2.ZERO, r, Color(col, 0.18 * fade))
		draw_circle(Vector2.ZERO, r * 0.7, Color(col, 0.18 * fade))
		draw_set_transform(Vector2.ZERO)
		for k in 6:
			var phase := fmod(t * 0.8 + k / 6.0 + (int(c["seed"]) % 7) * 0.1, 1.0)
			var q := p + Vector2.from_angle(k * 1.7 + int(c["seed"])) * r * 0.55 + Vector2(0, -phase * 14.0)
			draw_circle(q, 3.0 + 2.0 * (1.0 - phase), Color(col.lightened(0.3), 0.6 * (1.0 - phase) * fade))
