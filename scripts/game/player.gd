class_name Player
extends CharacterBody2D
## Personaje controlado por el jugador. Todas sus cifras salen del StatBlock de
## CharacterData, así que el árbol pasivo, el equipo y las ascendencias afectan
## al juego. Las habilidades las lanza SkillController; las pociones, este nodo.
##
## Movimiento: WASD o mantener click izquierdo (estilo PoE).

signal died
signal flask_used(index: int)

const RADIUS := 14.0
## Tamaño del dibujo del personaje (0.9 antes; +18 % para que no quede más pequeño que las cajas).
const PLAYER_SPRITE_SCALE := 1.06
## Píxeles que avanza el personaje en cada paso (medio ciclo de la animación).
const STRIDE := 30.0
const BASE_MOVE_SPEED := 260.0
const MANA_REGEN_PERCENT := 1.75
const ES_RECHARGE_DELAY := 2.0
const ES_RECHARGE_PERCENT := 20.0
const MAX_EVADE_CHANCE := 0.75
const MAX_BLOCK_CHANCE := 75.0
## Condiciones (como en PoE): vida baja = 50 % o menos; muerte reciente = 4 s.
const LOW_LIFE_FRACTION := 0.5
const RECENT_KILL_TIME := 4.0
## Teclas del cinturón de pociones (Inventory.FLASK_SLOTS).
const FLASK_ACTIONS := [&"flask_1", &"flask_2", &"flask_3", &"flask_4", &"flask_5"]

var character: CharacterData
var enemies: EnemyManager
var life := 1.0
var mana := 1.0
var energy_shield := 0.0
## Para depurar y para el benchmark.
var invulnerable := false
## Mientras sea > 0, el personaje está lanzando una habilidad y no se mueve.
var action_lock := 0.0
## Durante las escenas: ni se mueve, ni lanza, ni bebe.
var controls_locked := false
## Fracción del maná máximo reservada por invocaciones persistentes (0..0.95).
var mana_reserved := 0.0
## Daños degenerativos activos (charcos, quemaduras): clave -> {dps, time, kind}.
## Cada fuente tiene su clave; la misma fuente no se acumula, se renueva.
var dots: Dictionary = {}
const DOT_COLORS := {"chaos": Color("6fd36b"), "fire": Color("e0652f"), "cold": Color("7fb8e0"), "lightning": Color("e8d070")}
const DOT_RES := {"chaos": &"chaos_res", "fire": &"fire_res", "cold": &"cold_res", "lightning": &"lightning_res"}
## Estados sobre el jugador (los aplican enemigos y afijos): id -> segundos que quedan.
## shock: recibes un 25 % más de daño · chill: te mueves un 30 % más lento · freeze: no puedes actuar.
## Su duración baja con la resistencia al rayo (shock) o al frío (chill y freeze).
var statuses: Dictionary = {}
const STATUS_RES := {"shock": &"lightning_res", "chill": &"cold_res", "freeze": &"cold_res"}
const SHOCK_TAKEN := 0.25
const CHILL_SLOW := 0.30
## Tras descongelarte, unos segundos sin poder volver a congelarte.
const FREEZE_GRACE := 3.0
var _freeze_grace := 0.0
var _shake_time := 0.0
var _shake_amount := 0.0
## Barrera temporal (Firewall Personal): absorbe daño antes que el escudo y la vida.
var barrier := 0.0
var barrier_max := 0.0
var barrier_time := 0.0


func add_barrier(amount: float, seconds: float) -> void:
	barrier = maxf(barrier, amount)
	barrier_max = maxf(barrier, 1.0)
	barrier_time = seconds

var _move_held := false
var _since_kill := 99.0
var _since_damage := 99.0
var _hurt_time := 0.0
var _facing := Vector2.RIGHT
var _walk_phase := -1.0
## Recuperaciones activas de pociones: {resource, per_second, remaining}.
var _recoveries: Array[Dictionary] = []
## Destino de un movimiento automático (por ejemplo, ir a recoger un objeto).
var _auto_target := Vector2.ZERO
var _has_auto_target := false


func setup(p_character: CharacterData, p_enemies: EnemyManager) -> void:
	character = p_character
	enemies = p_enemies
	character.stats_changed.connect(_on_stats_changed)
	refill()


func max_life() -> float:
	return maxf(1.0, character.stats.get_value(Stat.LIFE))


## Maná utilizable: el máximo menos lo que reservan las invocaciones persistentes.
func max_mana() -> float:
	return unreserved_mana_max() * (1.0 - mana_reserved)


## Maná máximo sin contar la reserva (el tamaño del orbe).
func unreserved_mana_max() -> float:
	return maxf(0.0, character.stats.get_value(Stat.MANA))


## Fracción (0..1) del maná máximo reservada (la pone SkillController).
func set_mana_reserved(fraction: float) -> void:
	mana_reserved = clampf(fraction, 0.0, 0.95)
	mana = minf(mana, max_mana())


func max_energy_shield() -> float:
	return maxf(0.0, character.stats.get_value(Stat.ENERGY_SHIELD))


func is_alive() -> bool:
	return life > 0.0


func refill() -> void:
	dots.clear()
	statuses.clear()
	life = max_life()
	mana = max_mana()
	energy_shield = max_energy_shield()
	_recoveries.clear()
	for f in character.inventory.flasks:
		if f:
			(f as Flask).refill()


func heal(amount: float) -> void:
	if is_alive():
		life = minf(max_life(), life + amount)


func facing_direction() -> Vector2:
	return _facing


## Aplica un estado al jugador (shock, chill, freeze). Devuelve true si entró.
func apply_status(id: String, duration: float) -> bool:
	if not is_alive() or invulnerable or not STATUS_RES.has(id):
		return false
	if id == "freeze" and (_freeze_grace > 0.0 or statuses.has("freeze")):
		return false
	var res := minf(Stat.RESISTANCE_CAP, _stat(STATUS_RES[id]))
	var t := duration * (1.0 - res / 100.0)
	if t < 0.15:
		return false
	statuses[id] = maxf(float(statuses.get(id, 0.0)), t)
	return true


func is_frozen() -> bool:
	return statuses.has("freeze")


## Sacude la cámara un instante (cambios de fase de los jefes, explosiones grandes).
func camera_shake(amount: float, seconds: float) -> void:
	_shake_amount = maxf(_shake_amount, amount)
	_shake_time = maxf(_shake_time, seconds)


func face(direction: Vector2) -> void:
	if direction != Vector2.ZERO:
		_facing = direction.normalized()


func _on_stats_changed() -> void:
	life = minf(life, max_life())
	mana = minf(mana, max_mana())
	energy_shield = minf(energy_shield, max_energy_shield())


## Camina hasta `target` mientras el jugador no dé otra orden de movimiento.
func move_to(target: Vector2) -> void:
	_auto_target = target
	_has_auto_target = true


func stop_auto_move() -> void:
	_has_auto_target = false


func has_auto_target() -> bool:
	return _has_auto_target


# --- Pociones ---

func flask_at(index: int) -> Flask:
	return character.inventory.flasks[index] as Flask if index < character.inventory.flasks.size() else null


func can_use_flask(index: int) -> bool:
	var f := flask_at(index)
	return is_alive() and f != null and f.has_charges() and character.level >= f.required_level()


func use_flask(index: int) -> bool:
	if not can_use_flask(index):
		return false
	var f := flask_at(index)
	f.charges -= f.cost()
	match f.kind():
		"life", "mana":
			_recoveries.append({"resource": f.kind(), "per_second": f.recover() / f.duration(), "remaining": f.duration(),
				"flask": f.def["id"]})
		_:
			character.add_timed_effect("flask:" + String(f.def["id"]), f.timed_modifiers(), f.duration())
	Sfx.play("flask")
	flask_used.emit(index)
	return true


## ¿Está haciendo efecto la poción de esa ranura? (para el brillo del HUD)
func is_flask_active(index: int) -> bool:
	var f := flask_at(index)
	if f == null:
		return false
	if f.kind() == "utility":
		return character.has_timed_effect("flask:" + String(f.def["id"]))
	return _recoveries.any(func(r: Dictionary) -> bool: return r.get("flask", "") == f.def["id"])


func is_recovering(resource: String) -> bool:
	return _recoveries.any(func(r: Dictionary) -> bool: return r["resource"] == resource)


func add_flask_charges(enemy_rarity: int) -> void:
	var amount: float = Flask.CHARGES_BY_RARITY.get(enemy_rarity, 1.0)
	for f in character.inventory.flasks:
		if f:
			(f as Flask).add_charges(amount)


## Lo llama World al matar un enemigo (condición «has matado recientemente»).
func notify_kill() -> void:
	_since_kill = 0.0
	var on_kill := _stat(Stat.LIFE_ON_KILL)
	if on_kill > 0.0:
		heal(on_kill)


## Stat con las condiciones activas aplicadas (vida baja, etc.).
func _stat(stat: StringName) -> float:
	return character.stats.get_value(stat, character.condition_tags())


func _update_conditions(delta: float) -> void:
	_since_kill += delta
	character.set_condition(Stat.COND_LOW_LIFE, is_alive() and life <= max_life() * LOW_LIFE_FRACTION)
	character.set_condition(Stat.COND_FULL_LIFE, life >= max_life() - 0.5)
	character.set_condition(Stat.COND_RECENT_KILL, _since_kill <= RECENT_KILL_TIME)


# --- Bucle ---

func _unhandled_input(event: InputEvent) -> void:
	if controls_locked:
		return
	var mb := event as InputEventMouseButton
	if mb and mb.button_index == MOUSE_BUTTON_LEFT:
		_move_held = mb.pressed
	else:
		for i in FLASK_ACTIONS.size():
			if event.is_action_pressed(FLASK_ACTIONS[i]):
				use_flask(i)
				break


func _physics_process(delta: float) -> void:
	if not is_alive():
		velocity = Vector2.ZERO
		return
	_update_conditions(delta)
	_regenerate(delta)
	_tick_dots(delta)
	_freeze_grace = maxf(0.0, _freeze_grace - delta)
	for id in statuses.keys():
		statuses[id] -= delta
		if statuses[id] <= 0.0:
			statuses.erase(id)
			if id == "freeze":
				_freeze_grace = FREEZE_GRACE
	character.tick_timed_effects(delta)
	if barrier_time > 0.0:
		barrier_time -= delta
		if barrier_time <= 0.0:
			barrier = 0.0
	action_lock = maxf(0.0, action_lock - delta)

	var dir := Input.get_vector(&"move_left", &"move_right", &"move_up", &"move_down")
	if _move_held and not Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		_move_held = false  # se soltó el botón mientras otra cosa tenía el foco
	if dir != Vector2.ZERO or _move_held:
		_has_auto_target = false  # una orden manual cancela el movimiento automático
	if dir == Vector2.ZERO and _move_held:
		var to_mouse := get_global_mouse_position() - global_position
		if to_mouse.length() > 8.0:
			dir = to_mouse.normalized()
	elif dir == Vector2.ZERO and _has_auto_target:
		var to_target := _auto_target - global_position
		if to_target.length() > 6.0:
			dir = to_target.normalized()
		else:
			_has_auto_target = false
	if action_lock > 0.0 or controls_locked or is_frozen():
		dir = Vector2.ZERO  # como en PoE: quieto mientras lanza (o en una escena)
	if dir != Vector2.ZERO:
		_facing = dir
	velocity = dir * BASE_MOVE_SPEED * _stat(Stat.MOVEMENT_SPEED) / 100.0 * (1.0 - CHILL_SLOW if statuses.has("chill") else 1.0)
	move_and_slide()
	# Ciclo de paso: avanza con la distancia recorrida de verdad (si choca con
	# algo, deja de "caminar en el sitio").
	var moved := get_real_velocity().length()
	if moved > 10.0:
		_walk_phase = fmod(maxf(_walk_phase, 0.0) + moved * delta / STRIDE * PI, TAU)
	else:
		_walk_phase = -1.0


func _process(delta: float) -> void:
	_hurt_time = maxf(0.0, _hurt_time - delta)
	var cam := get_node_or_null("Camera2D") as Camera2D
	if cam:
		if _shake_time > 0.0:
			_shake_time -= delta
			cam.offset = Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)) * _shake_amount * clampf(_shake_time * 4.0, 0.0, 1.0)
			if _shake_time <= 0.0:
				_shake_amount = 0.0
				cam.offset = Vector2.ZERO
		elif cam.offset != Vector2.ZERO:
			cam.offset = Vector2.ZERO
	queue_redraw()


func _regenerate(delta: float) -> void:
	var life_gain := _stat(Stat.LIFE_REGEN)
	var mana_gain := unreserved_mana_max() * MANA_REGEN_PERCENT / 100.0 * character.stats.total_multiplier(Stat.MANA_REGEN, character.condition_tags())
	for r in _recoveries:
		var dt := minf(delta, r["remaining"])
		if r["resource"] == "life":
			life_gain += r["per_second"] * dt / delta
		else:
			mana_gain += r["per_second"] * dt / delta
		r["remaining"] -= delta
	_recoveries.assign(_recoveries.filter(func(r: Dictionary) -> bool: return r["remaining"] > 0.0))
	life = minf(max_life(), life + life_gain * delta)
	mana = minf(max_mana(), mana + mana_gain * delta)
	_since_damage += delta
	if _since_damage >= ES_RECHARGE_DELAY:
		energy_shield = minf(max_energy_shield(),
			energy_shield + max_energy_shield() * ES_RECHARGE_PERCENT / 100.0 * delta)


## Daño degenerativo: no se esquiva, no se bloquea y la armadura no lo reduce,
## pero sí la resistencia de su tipo. La misma clave renueva (no acumula).
func apply_dot(key: String, dps: float, duration: float, kind := "chaos") -> void:
	if not is_alive() or invulnerable or dps <= 0.0:
		return
	var old: Dictionary = dots.get(key, {})
	dots[key] = {"dps": maxf(dps, float(old.get("dps", 0.0))), "time": maxf(duration, float(old.get("time", 0.0))), "kind": kind}


func _tick_dots(delta: float) -> void:
	if dots.is_empty():
		return
	var total := 0.0
	for key in dots.keys():
		var d: Dictionary = dots[key]
		d["time"] -= delta
		if d["time"] <= 0.0:
			dots.erase(key)
			continue
		var res := minf(Stat.RESISTANCE_CAP, _stat(DOT_RES.get(d["kind"], &"chaos_res")))
		total += float(d["dps"]) * delta * (1.0 - res / 100.0)
	if total <= 0.0 or not is_alive():
		return
	_since_damage = 0.0
	var amount := total
	if barrier > 0.0:
		var blocked := minf(barrier, amount)
		barrier -= blocked
		amount -= blocked
	var absorbed := minf(energy_shield, amount)
	energy_shield -= absorbed
	life -= amount - absorbed
	if life <= 0.0:
		life = 0.0
		dots.clear()
		_recoveries.clear()
		died.emit()


func take_damage(amount: float) -> void:
	if not is_alive() or invulnerable:
		return
	var evasion := _stat(Stat.EVASION)
	if randf() < minf(MAX_EVADE_CHANCE, evasion / (evasion + 600.0)):
		return
	if randf() * 100.0 < minf(MAX_BLOCK_CHANCE, _stat(Stat.BLOCK_CHANCE)):
		return
	if statuses.has("shock"):
		amount *= 1.0 + SHOCK_TAKEN
	# Fórmula de armadura de PoE: protege mucho contra golpes pequeños, poco contra grandes.
	var armour := _stat(Stat.ARMOUR)
	amount *= 1.0 - minf(0.9, armour / (armour + 5.0 * amount))
	_since_damage = 0.0
	_hurt_time = 0.12
	Sfx.play("player_hurt", -4.0)
	var thorns := _stat(Stat.THORNS)
	if thorns > 0.0 and enemies != null:
		# Espinas: el golpe recibido se devuelve a quien esté cerca.
		enemies.hit_in_radius(global_position, 110.0, thorns, thorns * 1.3, 0.0, 100.0)
	if barrier > 0.0:
		var blocked := minf(barrier, amount)
		barrier -= blocked
		amount -= blocked
	var absorbed := minf(energy_shield, amount)
	energy_shield -= absorbed
	life -= amount - absorbed
	if life <= 0.0:
		life = 0.0
		_recoveries.clear()
		died.emit()


func _draw() -> void:
	# Figura provisional con la apariencia elegida en el creador, hasta tener sprites.
	var tint := Color(0, 0, 0, 0)
	if not is_alive():
		tint = Color("444444")
	elif _hurt_time > 0.0:
		tint = Color.RED
	CharacterAppearance.draw(self, Vector2(0.0, RADIUS * 0.6), PLAYER_SPRITE_SCALE, character.appearance, _facing, tint,
		_walk_phase if is_alive() else -1.0)
	if statuses.has("freeze"):
		var ice := PackedVector2Array()
		for q in 6:
			ice.append(Vector2.from_angle(TAU * q / 6.0 + 0.3) * 24.0 + Vector2(0, -14))
		draw_colored_polygon(ice, Color(0.7, 0.9, 1.0, 0.38))
		ice.append(ice[0])
		draw_polyline(ice, Color(0.85, 0.97, 1.0, 0.9), 2.0, true)
	elif statuses.has("chill"):
		draw_set_transform(Vector2(0, 8), 0.0, Vector2(1.0, 0.45))
		draw_arc(Vector2.ZERO, 20.0, 0.0, TAU, 20, Color(0.55, 0.8, 1.0, 0.8), 2.5, true)
		draw_set_transform(Vector2.ZERO)
	if statuses.has("shock") and fmod(Time.get_ticks_msec() / 150.0, 1.0) < 0.5:
		var sa := Time.get_ticks_msec() / 90.0
		var from := Vector2.from_angle(sa) * 20.0 + Vector2(0, -14)
		var to := Vector2.from_angle(sa + 1.2) * 20.0 + Vector2(0, -14)
		draw_polyline(PackedVector2Array([from, from.lerp(to, 0.5) + Vector2(4, -3), to]), Color(1.0, 0.92, 0.45), 2.0, true)
	# Burbujas del daño degenerativo sobre la cabeza (del color de su tipo).
	var k := 0
	for d in dots.values():
		var ph := fmod(Time.get_ticks_msec() / 700.0 + k * 0.33, 1.0)
		var c: Color = DOT_COLORS.get(d["kind"], Color("6fd36b"))
		draw_circle(Vector2(-8.0 + k * 8.0, -52.0 - ph * 14.0), 2.5 + ph * 1.5, Color(c, 0.85 * (1.0 - ph)))
		k += 1
