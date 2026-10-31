class_name Player
extends CharacterBody2D
## Personaje controlado por el jugador. Todas sus cifras salen del StatBlock de
## CharacterData, así que el árbol pasivo, el equipo y las ascendencias afectan
## al juego. Las habilidades las lanza SkillController; las pociones, este nodo.
##
## Movimiento: flechas o mantener click izquierdo (estilo PoE).

signal died
## Golpe recibido que no se esquivó ni bloqueó (nova de hielo de ascendencia).
signal hit_taken
signal flask_used(index: int)
## Poción que cura a las invocaciones (fracción de su vida máxima); la atiende SkillController.
signal heal_minions_requested(fraction: float)
signal dodged

const RADIUS := 14.0
## Tamaño del dibujo del personaje (0.9 antes; +18 % para que no quede más pequeño que las cajas).
const PLAYER_SPRITE_SCALE := PlayerSheet.WORLD_SCALE
## Píxeles que avanza el personaje en cada paso (medio ciclo de la animación).
const STRIDE := 30.0
const BASE_MOVE_SPEED := 260.0
const ES_RECHARGE_DELAY := 2.0
const ES_RECHARGE_PERCENT := 20.0
const MAX_EVADE_CHANCE := 0.75
const MAX_BLOCK_CHANCE := 75.0
## Condiciones (como en PoE): vida baja = 50 % o menos; muerte reciente = 4 s.
const LOW_LIFE_FRACTION := 0.5
const RECENT_KILL_TIME := 4.0
## Teclas del cinturón de pociones (Inventory.FLASK_SLOTS).
const FLASK_ACTIONS := [&"flask_1", &"flask_2", &"flask_3", &"flask_4", &"flask_5"]
## Esquiva ("git stash", Espacio o RT): un salto corto con invulnerabilidad breve.
## Tiene cargas (2 + Stat.DODGE_CHARGES) que se recargan solas una a una.
const DODGE_DISTANCE := 175.0
const DODGE_TIME := 0.18
const DODGE_IFRAMES := 0.3
const DODGE_CHARGES := 2
const DODGE_RECHARGE := 1.6

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

## Cargas de esquiva (fraccionarias: la parte decimal es la que se está recargando).
var dodge_charges := float(DODGE_CHARGES)
var _dodge_time := 0.0
var _dodge_dir := Vector2.RIGHT
var _iframes := 0.0
## Siluetas que deja la esquiva: {pos, t}.
var _ghosts: Array[Dictionary] = []
var _stash_label := 0.0

var _move_held := false
var _since_kill := 99.0
var _since_damage := 99.0
var _hurt_time := 0.0
var _facing := Vector2.RIGHT
var _walk_phase := -1.0
## Pisadas del cosmético de pasos (Achievements): {pos (global), t}.
var _step_marks: Array[Dictionary] = []
const STEP_MARK_TIME := 0.8
## Recuperaciones activas de pociones: {resource, per_second, remaining}.
var _recoveries: Array[Dictionary] = []
## Destino de un movimiento automático (por ejemplo, ir a recoger un objeto).
var _auto_target := Vector2.ZERO
var _has_auto_target := false
## Animación por estados (T72): la acción en curso ("attack", "shoot" o "cast"), cuánto
## lleva y cuánto dura; el brillo de las manos; si canaliza (lo renueva SkillController),
## el retroceso al recibir un golpe y el tiempo desde que murió.
const FLINCH_TIME := 0.25
const DEATH_FALL_TIME := 0.5
## Por encima de esta fracción de la velocidad base, corre en vez de caminar.
const RUN_SPEED_FACTOR := 1.15
var _action := ""
var _action_time := 0.0
var _action_length := 0.0
var _glow := Color.WHITE
var _channel_time := 0.0
var _flinch := 0.0
var _death_time := 0.0
var _anim_time := 0.0


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
	dodge_charges = float(max_dodge_charges())
	life = max_life()
	mana = max_mana()
	energy_shield = max_energy_shield()
	_recoveries.clear()
	deferred_damage = 0.0
	for f in character.inventory.flasks:
		if f:
			(f as Flask).refill()


func heal(amount: float) -> void:
	if is_alive():
		life = minf(max_life(), life + amount)


func facing_direction() -> Vector2:
	return _facing


# --- Esquiva ---

## Multiplicador del radio de recogida de tokens (Stat.TOKEN_PICKUP_RADIUS, con tope).
func token_radius_mult() -> float:
	return 1.0 + clampf(_stat(Stat.TOKEN_PICKUP_RADIUS), 0.0, LootManager.TOKEN_RADIUS_CAP) / 100.0


func max_dodge_charges() -> int:
	return DODGE_CHARGES + maxi(0, int(_stat(Stat.DODGE_CHARGES)))


## Segundos que tarda en volver una carga de esquiva (Stat.DODGE_RECOVERY la acorta).
func dodge_recharge_time() -> float:
	return DODGE_RECHARGE / (1.0 + maxf(0.0, _stat(Stat.DODGE_RECOVERY)) / 100.0)


## ¿Está en los fotogramas invulnerables de la esquiva?
func is_dodging() -> bool:
	return _iframes > 0.0


## Esquiva hacia donde se mueve (o hacia el ratón / el stick si está quieto).
## Cancela el bloqueo de lanzar una habilidad. Devuelve false si no hay carga.
func dodge() -> bool:
	if not is_alive() or controls_locked or is_frozen() or _dodge_time > 0.0 or dodge_charges < 1.0:
		return false
	var dir := Input.get_vector(&"move_left", &"move_right", &"move_up", &"move_down")
	if dir == Vector2.ZERO:
		dir = Touch.stick
	if dir == Vector2.ZERO:
		dir = (Gamepad.aim_point(global_position, _facing) if Gamepad.active else Touch.pointer(self)) - global_position
	if dir == Vector2.ZERO:
		dir = _facing
	dodge_charges -= 1.0
	_dodge_dir = dir.normalized()
	_facing = _dodge_dir
	_dodge_time = DODGE_TIME
	_iframes = DODGE_IFRAMES
	_stash_label = 0.6
	action_lock = 0.0
	_has_auto_target = false
	Sfx.play("blink", -8.0, 1.35)
	dodged.emit()
	return true


## Devuelve cargas de esquiva (poción "Stash de emergencia"); `extra` puede pasar del máximo un rato.
func refill_dodge(extra := 0) -> void:
	dodge_charges = maxf(dodge_charges, float(max_dodge_charges() + extra))


## Aplica un estado al jugador (shock, chill, freeze). Devuelve true si entró.
func apply_status(id: String, duration: float) -> bool:
	if not is_alive() or invulnerable or is_dodging() or not STATUS_RES.has(id):
		return false
	if id == "freeze" and (_freeze_grace > 0.0 or statuses.has("freeze")):
		return false
	var res := minf(Stat.RESISTANCE_CAP, _stat(STATUS_RES[id]))
	var t := duration * (1.0 - res / 100.0) * (1.0 - minf(80.0, _stat(Stat.STATUS_RESIST)) / 100.0)
	if t < 0.15:
		return false
	if not statuses.has(id):
		_status_since[id] = Time.get_ticks_msec() / 1000.0   # para que la escarcha crezca (T99)
	statuses[id] = maxf(float(statuses.get(id, 0.0)), t)
	return true


## Personaje por capas (T102b): el sprite y, debajo, las pisadas y el aura de los logros.
var _sprite: PlayerSprite
var _under: Node2D
var _sprite_look := {}


## Tamaño del mundo (T156): el zoom de la cámara según la opción y la vista.
func apply_world_zoom() -> void:
	var cam := get_node_or_null("Camera2D") as Camera2D
	if cam and is_inside_tree():
		cam.zoom = Vector2.ONE * GraphicsQuality.world_zoom(get_viewport_rect().size)
		Accessibility.world_zoom = cam.zoom.x   # los textos del mundo lo compensan (T158)


## Crea el sprite por capas la primera vez (si las hojas están horneadas).
func _ensure_sprite() -> void:
	if _sprite != null or character == null or not is_inside_tree() or not PlayerSprite.available():
		return
	_under = Node2D.new()
	_under.show_behind_parent = true
	_under.draw.connect(_draw_under)
	add_child(_under)
	_sprite = PlayerSprite.new()
	_sprite.show_behind_parent = true
	_sprite.sprite_scale = PLAYER_SPRITE_SCALE / PlayerSheet.BAKE_SCALE
	add_child(_sprite)


const PLAYER_RING_RADIUS := 15.0
const PLAYER_RING_FLAT := 0.4


## Anillo de la clase, pisadas y aura de los logros (debajo del personaje).
func _draw_under() -> void:
	var ci: CanvasItem = _under if _under != null else self
	var tt := Time.get_ticks_msec() / 1000.0
	# Anillo suave del color de la clase bajo los pies (T157): dónde estás, de un vistazo.
	if _sprite != null and is_alive():
		ci.draw_set_transform(_sprite.position, 0.0, Vector2(1.0, PLAYER_RING_FLAT))
		ci.draw_arc(Vector2.ZERO, PLAYER_RING_RADIUS * PLAYER_SPRITE_SCALE, 0.0, TAU, 40,
			Color(Color(character.class_def.get("color", "d9a441")), 0.5), 2.5, true)
		ci.draw_set_transform(Vector2.ZERO)
	for m in _step_marks:
		Achievements.draw_step(ci, to_local(m["pos"]), character, float(m["t"]) / STEP_MARK_TIME)
	Achievements.draw_aura(ci, Vector2(0.0, RADIUS * 0.6), character, tt)


func _update_sprite(feet: Vector2, tint: Color) -> void:
	if _sprite_look != character.appearance:
		_sprite_look = character.appearance.duplicate()
		# Con el equipo de oficio de su clase (T161).
		_sprite.appearance = CharacterAppearance.with_gear(character.appearance, String(character.class_def.get("id", "")))
	_sprite.position = feet
	var pose := anim_pose()
	_sprite.set_pose(_facing, pose, _walk_phase if is_alive() else -1.0)
	_sprite.tint = Color(tint, 0.6) if tint.a > 0.0 else Color(0, 0, 0, 0)
	_under.queue_redraw()
	# El brillo de las manos al lanzar o canalizar (las hojas no lo traen).
	var state: String = pose["state"]
	if pose.has("glow") and state in ["cast", "channel"]:
		var g: Color = pose["glow"]
		var side := -1.0 if _facing.x < -0.3 else 1.0
		var hand := feet + Vector2(side * 13.0, -26.0) * PLAYER_SPRITE_SCALE
		var pulse := 0.75 + 0.25 * sin(float(pose["time"]) * 9.0) if state == "channel" else minf(1.0, float(pose["t"]) * 2.5)
		draw_circle(hand, 4.5 * PLAYER_SPRITE_SCALE * pulse, Color(g, 0.35))
		draw_circle(hand, 2.4 * PLAYER_SPRITE_SCALE * pulse, Color(g.lightened(0.4), 0.8))


## Cuándo empezó cada estado activo (segundos del reloj), para animar su entrada.
var _status_since: Dictionary = {}


func is_frozen() -> bool:
	return statuses.has("freeze")


## Intensidad de la sacudida de cámara elegida en Pausa (0 = nada, 0.5 = suave, 1 = normal).
static var shake_scale := clampf(float(GameSettings.get_value("interface", "camera_shake", 1.0)), 0.0, 1.0)
## Movimiento con el clic izquierdo (Pausa → Combate): "hold" mantener para
## seguir al cursor (como siempre) · "toggle" un clic empieza a seguirlo y otro
## para (sin mantener el botón) · "click" además camina hasta donde hiciste clic.
const MOUSE_MOVE_MODES := ["hold", "toggle", "click"]
static var mouse_move := String(GameSettings.get_value("combat", "mouse_move", "hold"))
## Siguiendo al cursor sin mantener el botón (modo "toggle").
var _move_toggled := false


## Qué hace un clic izquierdo según el modo: {held, toggled, go_to} (go_to = ir al punto).
static func mouse_press(mode: String, pressed: bool, held: bool, toggled: bool) -> Dictionary:
	match mode:
		"toggle":
			return {"held": false, "toggled": not toggled if pressed else toggled, "go_to": false}
		"click":   # al soltar (mantener sigue al cursor mientras tanto)
			return {"held": pressed, "toggled": false, "go_to": not pressed and held}
	return {"held": pressed, "toggled": false, "go_to": false}


static func set_shake_scale(value: float) -> void:
	shake_scale = clampf(value, 0.0, 1.0)
	GameSettings.set_value("interface", "camera_shake", shake_scale)


## Sacude la cámara un instante (cambios de fase de los jefes, explosiones grandes,
## golpes fuertes). Graduada: cada causa pide su fuerza y la opción la escala.
func camera_shake(amount: float, seconds: float) -> void:
	amount *= shake_scale
	if amount <= 0.0:
		return
	_shake_amount = maxf(_shake_amount, amount)
	_shake_time = maxf(_shake_time, seconds)


func face(direction: Vector2) -> void:
	if direction != Vector2.ZERO:
		_facing = direction.normalized()


## Empieza la animación de una habilidad: `kind` es "attack", "shoot" o "cast".
func play_action(kind: String, length: float, glow := Color.WHITE) -> void:
	_action = kind
	_action_time = 0.0
	_action_length = maxf(0.15, length)
	_glow = glow


## Sigue canalizando este cuadro (manos delante, brillando).
func keep_channeling(glow := Color.WHITE) -> void:
	_channel_time = 0.15
	_glow = glow


## Animación de una habilidad por sus etiquetas: cuerpo a cuerpo, ataque a distancia o hechizo.
static func action_for(p: Dictionary) -> String:
	var tags: Array = p.get("tags", [])
	if "attack" in tags:
		return "attack" if "melee" in tags else "shoot"
	return "cast"


## Estado de la animación ahora (ver CharacterAppearance.draw).
func anim_state() -> String:
	if not is_alive():
		return "dead"
	if is_dodging():
		return "dodge"
	if _channel_time > 0.0:
		return "channel"
	if _action != "" and _action_time < _action_length:
		return _action
	if _flinch > 0.0:
		return "hurt"
	if _walk_phase >= 0.0:
		return "run" if get_real_velocity().length() > BASE_MOVE_SPEED * RUN_SPEED_FACTOR else "walk"
	return "idle"


## La pose para dibujar: estado, avance (0..1), tiempo, arma equipada y brillo.
func anim_pose() -> Dictionary:
	var state := anim_state()
	var t := 0.0
	match state:
		"dead":
			t = _death_time / DEATH_FALL_TIME
		"dodge":
			t = 1.0 - _dodge_time / DODGE_TIME
		"hurt":
			t = 1.0 - _flinch / FLINCH_TIME
		"attack", "shoot", "cast":
			t = _action_time / _action_length
	var weapon := CharacterAppearance.weapon_kind(character.inventory.equipped("weapon")) if character else ""
	return {"state": state, "t": clampf(t, 0.0, 1.0), "time": _anim_time, "weapon": weapon, "glow": _glow}


func _tick_anim(delta: float) -> void:
	_anim_time += delta
	_action_time += delta
	_channel_time = maxf(0.0, _channel_time - delta)
	_flinch = maxf(0.0, _flinch - delta)
	_death_time = 0.0 if is_alive() else _death_time + delta


func _on_stats_changed() -> void:
	life = minf(life, max_life())
	mana = minf(mana, max_mana())
	energy_shield = minf(energy_shield, max_energy_shield())


## Camina hasta `target` mientras el jugador no dé otra orden de movimiento.
func move_to(target: Vector2) -> void:
	_auto_target = target
	_has_auto_target = true


## ¿Lo está moviendo el jugador ahora (teclado, stick o ratón)? El auto-ataque espera.
func manual_moving() -> bool:
	return _move_held or _move_toggled or _has_auto_target or Input.get_vector(&"move_left", &"move_right", &"move_up", &"move_down") != Vector2.ZERO


func stop_auto_move() -> void:
	_has_auto_target = false
	_move_toggled = false


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
	# Pociones con efecto propio (además de sus mods).
	if f.def.get("cleanse", false):
		statuses.clear()
		dots.clear()
		_freeze_grace = FREEZE_GRACE
	if f.def.has("dodge_refill"):
		refill_dodge(int(f.def["dodge_refill"]))
	if f.def.has("heal_minions"):
		heal_minions_requested.emit(float(f.def["heal_minions"]))
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
	restore_mana(_stat(Stat.MANA_ON_KILL))


## Stat con las condiciones activas aplicadas (vida baja, etc.).
func _stat(stat: StringName) -> float:
	return character.stats.get_value(stat, character.condition_tags())


func _update_conditions(delta: float) -> void:
	_since_kill += delta
	character.set_condition(Stat.COND_LOW_LIFE, is_alive() and life <= max_life() * LOW_LIFE_FRACTION)
	character.set_condition(Stat.COND_FULL_LIFE, life >= max_life() - 0.5)
	character.set_condition(Stat.COND_RECENT_KILL, _since_kill <= RECENT_KILL_TIME)
	character.set_condition(Stat.COND_HIGH_MANA, max_mana() > 0.0 and mana >= max_mana() * 0.9)
	# Quieto: sin moverse (más de 2 px) durante STILL_TIME.
	if global_position.distance_to(_still_pos) > 2.0:
		_still_pos = global_position
		_still_time = 0.0
	else:
		_still_time += delta
	character.set_condition(Stat.COND_STILL, _still_time >= STILL_TIME)


const STILL_TIME := 1.0
var _still_pos := Vector2.INF
var _still_time := 0.0


# --- Bucle ---

func _unhandled_input(event: InputEvent) -> void:
	if controls_locked:
		return
	var mb := event as InputEventMouseButton
	if mb and mb.button_index == MOUSE_BUTTON_LEFT:
		var s := mouse_press(mouse_move, mb.pressed, _move_held, _move_toggled)
		_move_held = s["held"]
		_move_toggled = s["toggled"]
		if s["go_to"]:
			move_to(Touch.pointer(self))
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
	_iframes = maxf(0.0, _iframes - delta)
	safe_mode_window = maxf(0.0, safe_mode_window - delta)
	safe_mode_cooldown = maxf(0.0, safe_mode_cooldown - delta)
	# Por sondeo (no por evento): el gatillo del mando manda muchos eventos al apretarlo.
	if InputMap.has_action(&"dodge") and Input.is_action_just_pressed(&"dodge") and not Gamepad.menu_cursor and not UiStyle.typing():
		dodge()
	if dodge_charges < max_dodge_charges():
		dodge_charges = minf(float(max_dodge_charges()), dodge_charges + delta / dodge_recharge_time())
	if _dodge_time > 0.0:
		# Esquivando: en línea recta, rápido, sin control (choca con las paredes).
		_dodge_time -= delta
		velocity = _dodge_dir * DODGE_DISTANCE / DODGE_TIME
		move_and_slide()
		_ghosts.append({"pos": global_position, "t": 0.25})
		_walk_phase = -1.0
		return

	var dir := Input.get_vector(&"move_left", &"move_right", &"move_up", &"move_down") if not Gamepad.menu_cursor and not UiStyle.typing() else Vector2.ZERO
	if dir == Vector2.ZERO:
		dir = Touch.stick   # el joystick táctil (T107), como el stick del mando
	if _move_held and not Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		_move_held = false  # se soltó el botón mientras otra cosa tenía el foco
	if dir != Vector2.ZERO:
		_move_toggled = false   # el teclado o el stick mandan
	if dir != Vector2.ZERO or _move_held or _move_toggled:
		_has_auto_target = false  # una orden manual cancela el movimiento automático
	if dir == Vector2.ZERO and (_move_held or _move_toggled):
		var to_mouse := Touch.pointer(self) - global_position
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
		var before := maxf(_walk_phase, 0.0)
		_walk_phase = fmod(before + moved * delta / STRIDE * PI, TAU)
		if int(before / PI) != int(_walk_phase / PI):
			SoundMap.play_step()   # cada pisada, según el suelo (T77)
			if character and Achievements.equipped(character, "steps") != "":
				_step_marks.append({"pos": global_position + Vector2(randf_range(-5.0, 5.0), RADIUS * 0.6), "t": STEP_MARK_TIME})   # una pisada
	else:
		_walk_phase = -1.0
	for m in _step_marks:
		m["t"] = float(m["t"]) - delta
	_step_marks = _step_marks.filter(func(m: Dictionary) -> bool: return float(m["t"]) > 0.0)


func _process(delta: float) -> void:
	_ensure_sprite()
	_hurt_time = maxf(0.0, _hurt_time - delta)
	_tick_anim(delta)
	_stash_label = maxf(0.0, _stash_label - delta)
	for g in _ghosts:
		g["t"] -= delta
	_ghosts.assign(_ghosts.filter(func(g: Dictionary) -> bool: return g["t"] > 0.0))
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
	var life_gain := 0.0 if _stat(Stat.NO_LIFE_REGEN) > 0.0 else _stat(Stat.LIFE_REGEN)
	var duck := _stat(Stat.RUBBER_DUCK)
	if duck > 0.0 and character.conditions.has(Stat.COND_ALLIES):
		life_gain += max_life() * duck / 100.0   # Pato de Goma: explicárselo a alguien cura
	var mana_gain := mana_regen_per_second()
	if deferred_damage > 0.0 and is_alive():
		# Consistencia Eventual: el daño aplazado se cobra poco a poco.
		var due := KeystoneRules.deferred_drain(deferred_damage, delta)
		deferred_damage -= due
		life -= due
		if life <= 0.0 and not _safe_mode_saves():
			life = 0.0
			deferred_damage = 0.0
			_recoveries.clear()
			died.emit()
			return
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
	_since_hit += delta
	var es_regen := _stat(Stat.ENERGY_SHIELD_REGEN)
	if es_regen > 0.0:
		energy_shield = minf(max_energy_shield(), energy_shield + es_regen * delta)
	if _since_damage >= ES_RECHARGE_DELAY:
		energy_shield = minf(max_energy_shield(),
			energy_shield + max_energy_shield() * ES_RECHARGE_PERCENT / 100.0 * delta)


## Daño degenerativo: no se esquiva, no se bloquea y la armadura no lo reduce,
## pero sí la resistencia de su tipo. La misma clave renueva (no acumula).
func apply_dot(key: String, dps: float, duration: float, kind := "chaos") -> void:
	if not is_alive() or invulnerable or is_dodging() or dps <= 0.0:
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
	life -= _mana_takes(amount - absorbed)
	if life <= 0.0 and not _safe_mode_saves():
		life = 0.0
		dots.clear()
		_recoveries.clear()
		died.emit()


func take_damage(amount: float) -> void:
	if not is_alive() or invulnerable or is_dodging():
		return
	var evasion := _stat(Stat.EVASION)
	if randf() < minf(MAX_EVADE_CHANCE, evasion / (evasion + 600.0)):
		return
	if randf() * 100.0 < minf(MAX_BLOCK_CHANCE, _stat(Stat.BLOCK_CHANCE)):
		return
	if _stat(Stat.RATE_LIMIT) > 0.0 and KeystoneRules.rate_limited(_since_hit):
		return   # Rate Limiting: un golpe por ventana
	_since_hit = 0.0
	if statuses.has("shock"):
		amount *= 1.0 + SHOCK_TAKEN
	# Fórmula de armadura de PoE: protege mucho contra golpes pequeños, poco contra grandes.
	var armour := _stat(Stat.ARMOUR)
	amount *= 1.0 - minf(0.9, armour / (armour + 5.0 * amount))
	_since_damage = 0.0
	_hurt_time = 0.12
	_flinch = FLINCH_TIME
	if amount > max_life() * 0.08:
		camera_shake(clampf(amount / max_life() * 30.0, 2.0, 9.0), 0.18)   # cuanto más duele, más tiembla
		Haptics.pulse("hit")
	Sfx.play("player_hurt", -4.0)
	hit_taken.emit()
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
	life -= _mana_takes(amount - absorbed)
	if life <= 0.0 and not _safe_mode_saves():
		life = 0.0
		_recoveries.clear()
		deferred_damage = 0.0
		died.emit()


## Maná antes que vida: descuenta del maná su parte del daño y devuelve lo que va a la vida.
## Con Consistencia Eventual, la mitad de lo que va a la vida se aplaza (deferred_damage).
func _mana_takes(amount: float) -> float:
	var split := ManaMath.split_damage(amount, mana, _stat(Stat.DAMAGE_TAKEN_FROM_MANA))
	mana -= split.x
	if _stat(Stat.EVENTUAL_CONSISTENCY) > 0.0:
		var later := KeystoneRules.defer_split(split.y)
		deferred_damage += later.y
		return later.x
	return split.y


## Regeneración de maná por segundo (base con sus aumentos + plana). Con Recolector
## de Basura el maná solo vuelve al matar (y con pociones).
func mana_regen_per_second() -> float:
	return ManaMath.regen_per_second(unreserved_mana_max(),
		character.stats.total_multiplier(Stat.MANA_REGEN, character.condition_tags()),
		_stat(Stat.MANA_REGEN_FLAT), _stat(Stat.GARBAGE_COLLECTOR) > 0.0)


## Daño aplazado por Consistencia Eventual que aún falta por cobrar.
var deferred_damage := 0.0
## Segundos desde el último golpe que llegó a dañar (Rate Limiting).
var _since_hit := 10.0


## Recupera maná (al golpear, al matar...), sin pasar del máximo.
func restore_mana(amount: float) -> void:
	if amount > 0.0 and is_alive():
		mana = minf(max_mana(), mana + amount)


# --- Modo Seguro (nodo clave Stat.SAFE_MODE) ---
const SAFE_MODE_WINDOW := 2.0
const SAFE_MODE_COOLDOWN := 30.0
## Segundos que quedan de "no puedes bajar de 1 de vida" y hasta que vuelva a estar listo.
var safe_mode_window := 0.0
var safe_mode_cooldown := 0.0


## Un golpe (o degenerativo) mortal: con Modo Seguro listo (o ya activo) te quedas a 1 de vida.
func _safe_mode_saves() -> bool:
	if _stat(Stat.SAFE_MODE) <= 0.0:
		return false
	if safe_mode_window <= 0.0:
		if safe_mode_cooldown > 0.0:
			return false
		safe_mode_window = SAFE_MODE_WINDOW
		safe_mode_cooldown = SAFE_MODE_COOLDOWN
		Sfx.play("barrier", -2.0)
		camera_shake(4.0, 0.3)
	life = 1.0
	return true


func _draw() -> void:
	# Figura provisional con la apariencia elegida en el creador, hasta tener sprites.
	# Esquiva: siluetas translúcidas por donde pasó y el "git stash" encima.
	for g in _ghosts:
		var gp: Vector2 = to_local(g["pos"])
		var ga: float = g["t"] / 0.25 * 0.4
		draw_rect(Rect2(gp + Vector2(-8.0, -30.0), Vector2(16.0, 30.0)), Color(0.55, 0.85, 1.0, ga))
		draw_circle(gp + Vector2(0.0, -38.0), 8.0, Color(0.55, 0.85, 1.0, ga))
	if _stash_label > 0.0:
		var font := ThemeDB.fallback_font
		var fy := -64.0 - (0.6 - _stash_label) * 30.0
		draw_string_outline(font, Vector2(-60.0, fy), "git stash", HORIZONTAL_ALIGNMENT_CENTER, 120.0, Accessibility.world_size(14), 4, Color(0, 0, 0, _stash_label / 0.6))
		draw_string(font, Vector2(-60.0, fy), "git stash", HORIZONTAL_ALIGNMENT_CENTER, 120.0, Accessibility.world_size(14), Color(0.6, 0.9, 1.0, _stash_label / 0.6))
	var tint := Color(0, 0, 0, 0)
	if not is_alive():
		tint = Color("444444")
	elif _hurt_time > 0.0:
		tint = Color.RED
	var tt := Time.get_ticks_msec() / 1000.0
	var feet := Vector2(0.0, RADIUS * 0.6)
	if _sprite != null:
		# T102b: el personaje con las hojas por capas (PlayerSprite), detrás de lo que
		# se dibuja aquí encima (sombrero, estados); pisadas y aura, en _under.
		_update_sprite(feet, tint)
	else:
		# Cosméticos de los logros: pisadas y aura debajo, sombrero encima.
		_draw_under()
		CharacterAppearance.draw(self, feet, PLAYER_SPRITE_SCALE, character.appearance, _facing, tint,
			_walk_phase if is_alive() else -1.0, anim_pose())
	if Achievements.equipped(character, "hat") != "" and not (anim_state() in ["dead", "dodge"]):   # tumbado o rodando, el sombrero no seguiría la cabeza
		var hs := float(character.appearance.get("height", 1.0))
		Achievements.draw_hat(self, feet + Vector2(0, -31.0 * hs) * PLAYER_SPRITE_SCALE, 7.0 * PLAYER_SPRITE_SCALE, character)
	if statuses.has("freeze") or statuses.has("chill"):
		var frozen := statuses.has("freeze")
		# Escarcha sobre el cuerpo (crece al helarse, T99), cristales en los pies y copos que caen.
		var grow := 1.0 if frozen else FxArt.frost_growth(tt - float(_status_since.get("chill", tt)))
		var cover := PackedVector2Array()
		for q in 18:
			var a := TAU * q / 18.0
			cover.append(Vector2(cos(a) * 20.0 * grow, sin(a) * 30.0 * grow + (-22.0) + (1.0 - grow) * 18.0) * (1.0 + 0.07 * sin(a * 5.0)))
		draw_colored_polygon(cover, Color(0.72, 0.92, 1.0, 0.42 if frozen else 0.18))
		for q in (7 if frozen else 4):
			var bx := (float(q) / (7 if frozen else 4) - 0.5) * 40.0
			var h := (14.0 + 12.0 * fposmod(sin(q * 12.9898) * 43758.5, 1.0)) * (1.4 if frozen else 0.7)
			draw_colored_polygon(PackedVector2Array([Vector2(bx - 3, 14), Vector2(bx, 14 - h), Vector2(bx + 3, 14)]),
				Color(0.82, 0.96, 1.0, 0.85 if frozen else 0.55))
		if frozen:
			draw_polyline(cover + PackedVector2Array([cover[0]]), Color(0.88, 0.98, 1.0, 0.9), 2.0, true)
		else:
			draw_set_transform(Vector2(0, 8), 0.0, Vector2(1.0, 0.45))
			draw_arc(Vector2.ZERO, 20.0, 0.0, TAU, 20, Color(0.55, 0.8, 1.0, 0.8), 2.5, true)
			draw_set_transform(Vector2.ZERO)
		for q in 4:
			var ph := fposmod(tt * 0.8 + q * 0.25, 1.0)
			draw_circle(Vector2((q - 1.5) * 12.0 + sin(tt * 2.0 + q) * 3.0, -56.0 + ph * 60.0), 1.8, Color(0.9, 0.98, 1.0, 0.9 * (1.0 - ph * 0.6)))
	if statuses.has("shock"):
		# Arcos persistentes, resplandor y chispas que saltan.
		var c0 := Vector2(0, -20)
		draw_circle(c0, 28.0, Color(1.0, 0.95, 0.4, 0.10 + 0.06 * sin(tt * 18.0)))
		for q in 3:
			var st := floorf(tt * 10.0 + q * 3.0)
			var a := fposmod(st * 2.399 + q * 2.1, TAU)
			var from := c0 + Vector2.from_angle(a) * 10.0
			var to := c0 + Vector2.from_angle(a + 0.9 + fposmod(st * 1.7, 1.2)) * 30.0
			var mid := from.lerp(to, 0.5) + (to - from).orthogonal().normalized() * (fposmod(st * 3.1, 1.0) - 0.5) * 22.0
			draw_polyline(PackedVector2Array([from, mid, to]), Color(1.0, 0.95, 0.5, 0.9), 2.0, true)
			draw_circle(to, 2.0, Color(1.0, 1.0, 0.8, 0.9))
		for q in 5:
			var ph := fposmod(tt * 2.3 + q * 0.2, 1.0)
			var dir := Vector2.from_angle(q * 1.7 + floorf(tt * 2.3 + q * 0.2) * 0.9)
			draw_circle(c0 + dir * (22.0 + ph * 22.0), 1.8 * (1.0 - ph), Color(1.0, 0.95, 0.4, 1.0 - ph))
	# Daño degenerativo (T99): llamas si quema, gotas si sangra, burbujas del color de su tipo si no.
	var kinds := {}
	for d in dots.values():
		kinds[String(d["kind"])] = true
	for kind in kinds:
		match kind:
			"fire":
				FxArt.flames(self, Vector2(0, -6), 26.0, tt, 0.1)
			"physical":
				FxArt.drops(self, Vector2(0, -34), 22.0, tt, 0.3)
			_:
				FxArt.bubbles(self, Vector2(0, -44), 22.0, tt, 0.6, DOT_COLORS.get(kind, Color("6fd36b")))
