class_name Player
extends CharacterBody2D
## Personaje controlado por el jugador. Todas sus cifras salen del StatBlock de
## CharacterData, así que el árbol pasivo y las ascendencias afectan al juego.
##
## Movimiento: WASD o mantener click izquierdo (estilo PoE).
## Ataque: Espacio o click derecho → "Barrido", golpe en área alrededor.

signal died

const RADIUS := 14.0
const BASE_MOVE_SPEED := 260.0
const MANA_REGEN_PERCENT := 1.75
const ES_RECHARGE_DELAY := 2.0
const ES_RECHARGE_PERCENT := 20.0
const MAX_EVADE_CHANCE := 0.75
const MAX_BLOCK_CHANCE := 75.0

var character: CharacterData
var enemies: EnemyManager
var life := 1.0
var mana := 1.0
var energy_shield := 0.0
## Para depurar y para el benchmark.
var invulnerable := false

var _move_held := false
var _attack_cooldown := 0.0
var _since_damage := 99.0
var _swing_time := 0.0
var _swing_radius := 0.0
var _hurt_time := 0.0
var _facing := Vector2.RIGHT
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


func _unhandled_input(event: InputEvent) -> void:
	var mb := event as InputEventMouseButton
	if mb and mb.button_index == MOUSE_BUTTON_LEFT:
		_move_held = mb.pressed


func _physics_process(delta: float) -> void:
	if not is_alive():
		velocity = Vector2.ZERO
		return
	_regenerate(delta)

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
	if dir != Vector2.ZERO:
		_facing = dir
	velocity = dir * BASE_MOVE_SPEED * character.stats.get_value(Stat.MOVEMENT_SPEED) / 100.0
	move_and_slide()

	_attack_cooldown -= delta
	if Input.is_action_pressed(&"attack") and _attack_cooldown <= 0.0:
		_attack()


func _process(delta: float) -> void:
	_swing_time = maxf(0.0, _swing_time - delta)
	_hurt_time = maxf(0.0, _hurt_time - delta)
	queue_redraw()


func _regenerate(delta: float) -> void:
	life = minf(max_life(), life + character.stats.get_value(Stat.LIFE_REGEN) * delta)
	mana = minf(max_mana(), mana + max_mana() * MANA_REGEN_PERCENT / 100.0 * delta)
	_since_damage += delta
	if _since_damage >= ES_RECHARGE_DELAY:
		energy_shield = minf(max_energy_shield(),
			energy_shield + max_energy_shield() * ES_RECHARGE_PERCENT / 100.0 * delta)


## El daño sale del arma equipada + stats (ver CharacterData.attack_profile).
func _attack() -> void:
	var p := character.attack_profile()
	_attack_cooldown = 1.0 / maxf(0.1, p.attacks_per_second)
	enemies.hit_in_radius(global_position, p.radius, p.min_damage, p.max_damage, p.crit_chance, p.crit_multiplier)
	_swing_time = 0.15
	_swing_radius = p.radius


func take_damage(amount: float) -> void:
	if not is_alive() or invulnerable:
		return
	var s := character.stats
	var evasion := s.get_value(Stat.EVASION)
	if randf() < minf(MAX_EVADE_CHANCE, evasion / (evasion + 600.0)):
		return
	if randf() * 100.0 < minf(MAX_BLOCK_CHANCE, s.get_value(Stat.BLOCK_CHANCE)):
		return
	# Fórmula de armadura de PoE: protege mucho contra golpes pequeños, poco contra grandes.
	var armour := s.get_value(Stat.ARMOUR)
	amount *= 1.0 - minf(0.9, armour / (armour + 5.0 * amount))
	_since_damage = 0.0
	_hurt_time = 0.12
	var absorbed := minf(energy_shield, amount)
	energy_shield -= absorbed
	life -= amount - absorbed
	if life <= 0.0:
		life = 0.0
		died.emit()


func _draw() -> void:
	if _swing_time > 0.0:
		var alpha := _swing_time / 0.15
		draw_circle(Vector2.ZERO, _swing_radius, Color(1.0, 0.85, 0.5, 0.12 * alpha))
		draw_arc(Vector2.ZERO, _swing_radius, 0.0, TAU, 48, Color(1.0, 0.85, 0.5, 0.6 * alpha), 3.0, true)
	# Figura provisional con la apariencia elegida en el creador, hasta tener sprites.
	var tint := Color(0, 0, 0, 0)
	if not is_alive():
		tint = Color("444444")
	elif _hurt_time > 0.0:
		tint = Color.RED
	CharacterAppearance.draw(self, Vector2(0.0, RADIUS * 0.6), 0.9, character.appearance, _facing, tint)
