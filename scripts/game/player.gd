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
const BASE_MOVE_SPEED := 260.0
const MANA_REGEN_PERCENT := 1.75
const ES_RECHARGE_DELAY := 2.0
const ES_RECHARGE_PERCENT := 20.0
const MAX_EVADE_CHANCE := 0.75
const MAX_BLOCK_CHANCE := 75.0
## Condiciones (como en PoE): vida baja = 50 % o menos; muerte reciente = 4 s.
const LOW_LIFE_FRACTION := 0.5
const RECENT_KILL_TIME := 4.0
## Pociones (como los frascos de PoE): se recargan matando enemigos.
## recover: fracción de la vida/maná máximos que devuelven en `duration` segundos.
const FLASKS := [
	{"name": "Café", "icon": "flask_coffee", "resource": "life", "max_charges": 45.0, "cost": 15.0, "recover": 0.45, "duration": 2.5,
		"color": Color("8a5a2b"), "description": "Recupera vida poco a poco. Sin azúcar, como tu vida social."},
	{"name": "Bebida energética", "icon": "flask_energy", "resource": "mana", "max_charges": 45.0, "cost": 15.0, "recover": 0.5, "duration": 2.5,
		"color": Color("3a7bd5"), "description": "Recupera maná poco a poco. Tu cardiólogo no lo aprueba."},
]
## Cargas por enemigo muerto, según su rareza.
const FLASK_CHARGES_BY_RARITY := {
	Rarity.Enemy.NORMAL: 1.0,
	Rarity.Enemy.SPECIAL: 3.0,
	Rarity.Enemy.ELITE: 6.0,
	Rarity.Enemy.UNIQUE: 15.0,
}

var character: CharacterData
var enemies: EnemyManager
var life := 1.0
var mana := 1.0
var energy_shield := 0.0
## Para depurar y para el benchmark.
var invulnerable := false
var flask_charges: Array[float] = []
## Mientras sea > 0, el personaje está lanzando una habilidad y no se mueve.
var action_lock := 0.0

var _move_held := false
var _since_kill := 99.0
var _since_damage := 99.0
var _hurt_time := 0.0
var _facing := Vector2.RIGHT
## Recuperaciones activas de pociones: {resource, per_second, remaining}.
var _recoveries: Array[Dictionary] = []
## Destino de un movimiento automático (por ejemplo, ir a recoger un objeto).
var _auto_target := Vector2.ZERO
var _has_auto_target := false


func setup(p_character: CharacterData, p_enemies: EnemyManager) -> void:
	character = p_character
	enemies = p_enemies
	character.stats_changed.connect(_on_stats_changed)
	for f in FLASKS:
		flask_charges.append(f["max_charges"])
	refill()


func max_life() -> float:
	return maxf(1.0, character.stats.get_value(Stat.LIFE))


func max_mana() -> float:
	return maxf(0.0, character.stats.get_value(Stat.MANA))


func max_energy_shield() -> float:
	return maxf(0.0, character.stats.get_value(Stat.ENERGY_SHIELD))


func is_alive() -> bool:
	return life > 0.0


func refill() -> void:
	life = max_life()
	mana = max_mana()
	energy_shield = max_energy_shield()
	_recoveries.clear()
	for i in flask_charges.size():
		flask_charges[i] = FLASKS[i]["max_charges"]


func heal(amount: float) -> void:
	if is_alive():
		life = minf(max_life(), life + amount)


func facing_direction() -> Vector2:
	return _facing


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

func can_use_flask(index: int) -> bool:
	return is_alive() and flask_charges[index] >= FLASKS[index]["cost"]


func use_flask(index: int) -> bool:
	if not can_use_flask(index):
		return false
	var f: Dictionary = FLASKS[index]
	flask_charges[index] -= f["cost"]
	var total: float = (max_life() if f["resource"] == "life" else max_mana()) * f["recover"]
	_recoveries.append({"resource": f["resource"], "per_second": total / f["duration"], "remaining": f["duration"]})
	flask_used.emit(index)
	return true


func is_recovering(resource: String) -> bool:
	return _recoveries.any(func(r: Dictionary) -> bool: return r["resource"] == resource)


func add_flask_charges(enemy_rarity: int) -> void:
	var amount: float = FLASK_CHARGES_BY_RARITY.get(enemy_rarity, 1.0)
	for i in flask_charges.size():
		flask_charges[i] = minf(FLASKS[i]["max_charges"], flask_charges[i] + amount)


## Lo llama World al matar un enemigo (condición «has matado recientemente»).
func notify_kill() -> void:
	_since_kill = 0.0


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
	var mb := event as InputEventMouseButton
	if mb and mb.button_index == MOUSE_BUTTON_LEFT:
		_move_held = mb.pressed
	elif event.is_action_pressed(&"flask_1"):
		use_flask(0)
	elif event.is_action_pressed(&"flask_2"):
		use_flask(1)


func _physics_process(delta: float) -> void:
	if not is_alive():
		velocity = Vector2.ZERO
		return
	_update_conditions(delta)
	_regenerate(delta)
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
	if action_lock > 0.0:
		dir = Vector2.ZERO  # como en PoE: quieto mientras lanza
	if dir != Vector2.ZERO:
		_facing = dir
	velocity = dir * BASE_MOVE_SPEED * _stat(Stat.MOVEMENT_SPEED) / 100.0
	move_and_slide()


func _process(delta: float) -> void:
	_hurt_time = maxf(0.0, _hurt_time - delta)
	queue_redraw()


func _regenerate(delta: float) -> void:
	var life_gain := _stat(Stat.LIFE_REGEN)
	var mana_gain := max_mana() * MANA_REGEN_PERCENT / 100.0 * character.stats.total_multiplier(Stat.MANA_REGEN, character.condition_tags())
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


func take_damage(amount: float) -> void:
	if not is_alive() or invulnerable:
		return
	var evasion := _stat(Stat.EVASION)
	if randf() < minf(MAX_EVADE_CHANCE, evasion / (evasion + 600.0)):
		return
	if randf() * 100.0 < minf(MAX_BLOCK_CHANCE, _stat(Stat.BLOCK_CHANCE)):
		return
	# Fórmula de armadura de PoE: protege mucho contra golpes pequeños, poco contra grandes.
	var armour := _stat(Stat.ARMOUR)
	amount *= 1.0 - minf(0.9, armour / (armour + 5.0 * amount))
	_since_damage = 0.0
	_hurt_time = 0.12
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
	CharacterAppearance.draw(self, Vector2(0.0, RADIUS * 0.6), 0.9, character.appearance, _facing, tint)
