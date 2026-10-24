class_name SkillController
extends Node2D
## Lanza las habilidades de la barra (placas base instaladas) y dibuja sus
## efectos: proyectiles, explosiones, ondas, teletransporte, embestidas, conos,
## rayos, bumeranes, giros, trampas y cadenas.
## Las cifras salen de SkillCalc; aquí solo se aplican.

signal skill_used(hotbar_index: int)
signal not_enough_mana
## No queda maná sin reservar para otra invocación persistente.
signal reservation_full(skill_name: String)
## Una invocación persistente ha caído.
signal unit_lost(skill_name: String)

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
## Invocaciones persistentes (kind "unit"): no caducan, reservan maná y los
## enemigos pueden atacarlas (EnemyManager.allies). Ver _update_units.
var _units: Array[Dictionary] = []
const UNIT_LEASH := 900.0
## Vida de las torretas desplegadas (fracción de la vida máxima del jugador).
const TOTEM_LIFE_FRACTION := 0.4
## Auras activas: [{skill_id, profile, color, sig}]. Reservan maná y dan bonificaciones a los aliados.
var _auras: Array[Dictionary] = []
var _aura_regen := 0.0          # % de vida por segundo que recuperan las invocaciones
var _aura_reduction := 0.0      # daño evitado extra de las invocaciones
var _bare_profiles := {}         # skill_id -> perfil de la invocación sin auras (fuera de su radio)
## Lluvias en curso (Cascada de Estilos): impactos pendientes repartidos en el tiempo.
var _rains: Array[Dictionary] = []
## Robot de compañía (ascendencia Ingeniero en Robótica): {pos, laser, emp, bob}.
var _companion: Dictionary = {}
var _companion_laser: Dictionary = {}
var _companion_emp: Dictionary = {}


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
	player.hit_taken.connect(on_player_hit)
	var saved_auras: Array = character.flags.get("active_auras", []).duplicate()
	refresh_profiles()
	_restore_auras(saved_auras)


## Vuelve a encender las auras que estaban activas al guardar (o al cambiar de
## zona), sin sonido ni destello; las que ya no están en la barra se ignoran.
func _restore_auras(ids: Array) -> void:
	for p in _profiles:
		if not p.is_empty() and p["kind"] == "aura" and String(p["id"]) in ids:
			var a := {"skill_id": p["id"], "profile": p, "color": DAMAGE_COLORS.get(p["damage_type"], Color.WHITE), "sig": str(p["aura_mods"]), "anchor": Vector2.INF}
			_auras.append(a)
			_apply_aura_effect(a)
	_update_reservation()
	_remember_auras()


## Las auras activas se guardan con el personaje (en sus flags).
func _remember_auras() -> void:
	character.flags["active_auras"] = _auras.map(func(a: Dictionary) -> String: return String(a["skill_id"]))


func refresh_profiles() -> void:
	_profiles.clear()
	for i in ACTIONS.size():
		_profiles.append(character.skill_profile(i))
	if enemies:
		enemies.interaction_power = character.stats.total_multiplier(Stat.INTERACTION_EFFECT)
	_companion_laser = {}
	_companion_emp = {}
	if character.stats.get_value(Stat.COMPANION_ROBOT) > 0.0:
		var lvl := clampi(character.level - 2, 1, Motherboard.MAX_LEVEL)
		_companion_laser = SkillCalc.compute(Motherboard.new(CompanionRobot.LASER, lvl, []), character)
		_companion_emp = SkillCalc.compute(Motherboard.new(CompanionRobot.EMP, lvl, []), character)
	_refresh_units()


## Las invocaciones siguen a su placa: si se quita de la barra, desaparecen; si
## cambian sus cifras (nivel, RAM, pasivas), se actualizan conservando su % de vida.
func _refresh_units() -> void:
	var by_id := {}
	var by_aura := {}
	for p in _profiles:
		if not p.is_empty() and p["kind"] == "unit":
			by_id[p["id"]] = p
		elif not p.is_empty() and p["kind"] == "aura":
			by_aura[p["id"]] = p
	# Auras: se van si su placa sale de la barra y se actualizan si cambian sus cifras.
	var keep_auras: Array[Dictionary] = []
	for a in _auras:
		var ap: Dictionary = by_aura.get(a["skill_id"], {})
		if ap.is_empty():
			character.remove_timed_effect("aura:" + String(a["skill_id"]))
			continue
		a["profile"] = ap
		var sig := str(ap["aura_mods"])
		if sig != a["sig"]:
			a["sig"] = sig
			_apply_aura_effect(a)
		keep_auras.append(a)
	var aura_removed := keep_auras.size() != _auras.size()
	_auras = keep_auras
	if aura_removed:
		_remember_auras()
	_aura_regen = 0.0
	_aura_reduction = 0.0
	for a in _auras:
		_aura_regen += float(a["profile"]["aura_regen"])
		_aura_reduction += float(a["profile"]["aura_reduction"])
	_compute_bare_profiles()
	var kept: Array[Dictionary] = []
	var per_skill := {}
	for u in _units:
		var p: Dictionary = by_id.get(u["skill_id"], {})
		if p.is_empty():
			continue
		per_skill[u["skill_id"]] = int(per_skill.get(u["skill_id"], 0)) + 1
		if per_skill[u["skill_id"]] > int(p["max_units"]):
			continue
		var frac: float = clampf(u["life"] / maxf(1.0, u["max_life"]), 0.0, 1.0)
		u["profile"] = p
		u["base_reduction"] = float(p["unit_reduction"])
		u["max_life"] = maxf(1.0, p["unit_life"])
		u["life"] = u["max_life"] * frac
		kept.append(u)
	_units = kept
	_update_reservation()


## Perfiles de las invocaciones sin los bonos de las auras (para cuando se alejan
## del jugador más que el radio del aura). Quita un momento los efectos "aura:*"
## sin avisar a nadie y los vuelve a poner.
func _compute_bare_profiles() -> void:
	_bare_profiles = {}
	if _auras.is_empty():
		return
	var saved: Array = character.timed_effects.duplicate()
	character.timed_effects.assign(saved.filter(func(e: Dictionary) -> bool: return not String(e["id"]).begins_with("aura:")))
	character.recalculate(false)
	for i in ACTIONS.size():
		var p := character.skill_profile(i)
		if not p.is_empty() and p["kind"] == "unit":
			_bare_profiles[p["id"]] = p
	character.timed_effects.assign(saved)
	character.recalculate(false)


## Centro de un aura: el jugador, o el punto donde se activó si está anclada
## (Torre de Señal).
func aura_center(a: Dictionary) -> Vector2:
	if bool(a["profile"].get("aura_on_unit", false)):
		# Enlace de Aura: sobre la invocación más resistente (el tanque primero); con
		# varias auras enlazadas, cada una va a una invocación distinta, en ese orden.
		var hosts := aura_hosts()
		if not hosts.is_empty():
			var k := 0
			for other in _auras:
				if other == a:
					break
				if bool(other["profile"].get("aura_on_unit", false)):
					k += 1
			return hosts[k % hosts.size()]["pos"]
	if bool(a["profile"].get("aura_anchor", false)):
		if a.get("anchor", Vector2.INF) == Vector2.INF:
			a["anchor"] = player.global_position
		return a["anchor"]
	return player.global_position


## Invocaciones que pueden llevar un aura enlazada, de la más resistente a la
## menos (los tanques primero; las que orbitan al jugador no cuentan).
func aura_hosts() -> Array:
	var hosts := _units.filter(func(u: Dictionary) -> bool: return u["behavior"] != "orbit")
	hosts.sort_custom(func(x: Dictionary, y: Dictionary) -> bool:
		var tx: bool = x["behavior"] == "tank"
		var ty: bool = y["behavior"] == "tank"
		if tx != ty:
			return tx
		return float(x["max_life"]) > float(y["max_life"]))
	return hosts


## ¿Está ese punto dentro del alcance de alguna aura activa?
func in_aura_range(pos: Vector2) -> bool:
	if player == null:
		return false
	for a in _auras:
		if pos.distance_to(aura_center(a)) <= float(a["profile"].get("aura_radius", 0.0)):
			return true
	return false


## Auras que debilitan: cada fotograma le dicen al EnemyManager dónde están y qué hacen.
func _update_aura_fields() -> void:
	var fields: Array[Dictionary] = []
	if player and player.is_alive():
		for a in _auras:
			var en: Dictionary = a["profile"].get("aura_enemy", {})
			if not en.is_empty():
				fields.append({"pos": aura_center(a), "radius": float(a["profile"]["aura_radius"]),
					"slow": float(en.get("slow", 0.0)), "damage_taken": float(en.get("damage_taken", 0.0))})
	enemies.aura_fields = fields


func _update_reservation() -> void:
	var total := 0.0
	for u in _units:
		total += float(u["profile"]["reserve"]) / 100.0
	for a in _auras:
		total += float(a["profile"]["reserve"]) / 100.0
	if player:
		player.set_mana_reserved(total)
	if enemies:
		enemies.allies = _units.filter(func(u: Dictionary) -> bool: return u["behavior"] != "orbit")


## Al cambiar de zona: lo que estaba en el suelo desaparece y las invocaciones
## y esbirros llegan con el jugador.
func on_zone_changed() -> void:
	for a in _auras:
		a["anchor"] = Vector2.INF   # las auras ancladas se mudan contigo (se fijan al llegar)
	_projectiles.clear()
	_effects.clear()
	_pending.clear()
	_traps.clear()
	_devices.clear()
	_clouds.clear()
	_rains.clear()
	_spins.assign(_spins.filter(func(s: Dictionary) -> bool: return s["center"] == Vector2.INF))
	var k := 0
	for m in _minions:
		m["pos"] = player.global_position + Vector2.from_angle(TAU * k / maxf(1.0, _minions.size())) * 40.0
		k += 1
	for u in _units:
		u["pos"] = player.global_position + Vector2.from_angle(TAU * k / maxf(1.0, _units.size() + _minions.size())) * 55.0
		k += 1
	_companion = {}


## Quita todas las invocaciones persistentes (al morir).
func clear_units() -> void:
	_units.clear()
	_update_reservation()


## Al morir se apagan también las auras (se vuelven a activar relanzándolas).
func clear_auras() -> void:
	for a in _auras:
		character.remove_timed_effect("aura:" + String(a["skill_id"]))
	_auras.clear()
	_remember_auras()
	_aura_regen = 0.0
	_aura_reduction = 0.0
	_update_reservation()


## Nombres de las auras activas (para la hoja de personaje).
func active_auras() -> PackedStringArray:
	var out := PackedStringArray()
	for a in _auras:
		out.append(String(a["profile"]["name"]).replace("Aura de ", ""))
	return out


func is_aura_active(skill_id: String) -> bool:
	for a in _auras:
		if a["skill_id"] == skill_id:
			return true
	return false


func _apply_aura_effect(a: Dictionary) -> void:
	var mods: Array[Modifier] = []
	for md in a["profile"]["aura_mods"]:
		mods.append(Modifier.from_dict(md, "aura:" + String(a["skill_id"])))
	character.set_timed_effect("aura:" + String(a["skill_id"]), mods)


## Activa la aura (si cabe su reserva) o la apaga.
func _toggle_aura(p: Dictionary, color: Color) -> void:
	for k in _auras.size():
		if _auras[k]["skill_id"] == p["id"]:
			character.remove_timed_effect("aura:" + String(p["id"]))
			_auras.remove_at(k)
			_remember_auras()
			Sfx.play("aura_off", -6.0)
			_effects.append({"type": "ring", "pos": player.global_position, "radius": 70.0, "time": 0.0, "duration": 0.4, "color": Color(color, 0.5)})
			refresh_profiles()
			return
	var a := {"skill_id": p["id"], "profile": p, "color": color, "sig": str(p["aura_mods"]), "anchor": player.global_position}
	_auras.append(a)
	_remember_auras()
	Sfx.play("aura_on", -4.0)
	_effects.append({"type": "ring", "pos": player.global_position, "radius": 90.0, "time": 0.0, "duration": 0.7, "color": color})
	_apply_aura_effect(a)   # recalcula las stats y, con ello, los perfiles y la reserva
	_update_reservation()


func profile(index: int) -> Dictionary:
	return _profiles[index] if index < _profiles.size() else {}


## 0..1 del enfriamiento restante (para el HUD).
func cooldown_fraction(index: int) -> float:
	var p := profile(index)
	var total: float = p.get("cooldown", 0.0)
	return clampf(cooldowns[index] / total, 0.0, 1.0) if total > 0.0 else 0.0


# --- Habilidades únicas de ascendencia (Stat.KILL_EXPLOSION, STATIC_PULSE, RETALIATION_NOVA) ---

const PULSE_INTERVAL := 3.0
const PULSE_RADIUS := 150.0
const EXPLOSION_RADIUS := 95.0
const NOVA_RADIUS := 135.0
const NOVA_COOLDOWN := 1.0
var _pulse_timer := PULSE_INTERVAL
var _nova_cooldown := 0.0
## Explosiones pendientes (se resuelven en el siguiente fotograma: así una muerte
## dentro de un golpe no toca la lista de enemigos mientras se recorre).
var _pending_explosions: Array[Vector2] = []


## Lo llama World al morir un enemigo.
func on_enemy_killed(pos: Vector2) -> void:
	var chance := character.stats.get_value(Stat.KILL_EXPLOSION)
	if chance > 0.0 and randf() * 100.0 < chance and _pending_explosions.size() < 8:
		_pending_explosions.append(pos)


## Lo llama el jugador al recibir un golpe (Player.hit_taken).
func on_player_hit() -> void:
	var chance := character.stats.get_value(Stat.RETALIATION_NOVA)
	if chance <= 0.0 or _nova_cooldown > 0.0 or randf() * 100.0 >= chance:
		return
	_nova_cooldown = NOVA_COOLDOWN
	var dmg := 3.0 * character.level + 10.0
	var pos := player.global_position
	enemies.hit_in_radius(pos, NOVA_RADIUS, dmg * 0.9, dmg * 1.1, 0.0, 150.0)
	enemies.stun_in_radius(pos, NOVA_RADIUS, 0.8)
	Sfx.play("shatter", -6.0)
	_effects.append({"type": "ring", "pos": pos, "radius": NOVA_RADIUS, "time": 0.0, "duration": 0.45, "color": Color("9fe0ff")})
	_effects.append({"type": "burst", "pos": pos, "radius": NOVA_RADIUS * 0.8, "time": 0.0, "duration": 0.35, "color": Color("d8f4ff")})


func _update_ascendancy_procs(delta: float) -> void:
	_nova_cooldown = maxf(0.0, _nova_cooldown - delta)
	var explosions := _pending_explosions.duplicate()
	_pending_explosions.clear()
	for pos in explosions:
		var dmg := 4.0 * character.level + 12.0
		enemies.hit_in_radius(pos, EXPLOSION_RADIUS, dmg * 0.9, dmg * 1.1, 5.0, 150.0)
		Sfx.play("mine", -8.0, randf_range(0.9, 1.1))
		_effects.append({"type": "burst", "pos": pos, "radius": EXPLOSION_RADIUS, "time": 0.0, "duration": 0.35, "color": Color("ff9a3a")})
		_effects.append({"type": "ring", "pos": pos, "radius": EXPLOSION_RADIUS, "time": 0.0, "duration": 0.4, "color": Color("ffd060")})
	var pulse := character.stats.get_value(Stat.STATIC_PULSE)
	if pulse <= 0.0 or not player.is_alive():
		return
	_pulse_timer -= delta
	if _pulse_timer > 0.0:
		return
	_pulse_timer = PULSE_INTERVAL
	var pos := player.global_position
	if enemies.hit_in_radius(pos, PULSE_RADIUS, pulse * character.level * 0.9, pulse * character.level * 1.1, 5.0, 150.0) > 0:
		Sfx.play("arc", -10.0)
	_effects.append({"type": "ring", "pos": pos, "radius": PULSE_RADIUS, "time": 0.0, "duration": 0.5, "color": Color("8ad8ff")})


func _physics_process(delta: float) -> void:
	for i in cooldowns.size():
		cooldowns[i] = maxf(0.0, cooldowns[i] - delta)
	_mana_warning_cooldown = maxf(0.0, _mana_warning_cooldown - delta)
	_busy = maxf(0.0, _busy - delta)
	# En escenas (enemigos congelados, jugador bloqueado) nada ataca: ni aliados,
	# ni torretas, ni proyectiles en vuelo. Solo se apagan los efectos visuales.
	if enemies.frozen or player.controls_locked:
		_update_effects(delta)
		queue_redraw()
		return
	if player.is_alive() and _busy <= 0.0 and not player.controls_locked and not player.is_frozen():
		for i in ACTIONS.size():
			if i == 0 and Gamepad.skill_1_blocked():
				continue   # A se usó para recoger o hablar (mando)
			if Input.is_action_pressed(ACTIONS[i]) and try_use(i):
				break
	_update_aura_fields()
	_update_pending(delta)
	_update_projectiles(delta)
	_update_spin(delta)
	_update_traps(delta)
	_update_devices(delta)
	_update_minions(delta)
	_update_units(delta)
	_update_rains(delta)
	_update_clouds(delta)
	_update_drones(delta)
	_update_companion(delta)
	_update_ascendancy_procs(delta)
	_update_effects(delta)
	enemies.hit_ailments = {}
	queue_redraw()


## Prepara los estados alterados que puede aplicar el próximo golpe de `p`.
## `scale`: para daños por tick (charcos), que tiran los dados muchas veces.
func _ctx(p: Dictionary, scale := 1.0) -> void:
	var ctx: Dictionary = p.get("ailment_ctx", {})
	if scale == 1.0 or ctx.is_empty():
		enemies.hit_ailments = ctx
		return
	var scaled := {}
	for id in ctx["chances"]:
		scaled[id] = float(ctx["chances"][id]) * scale
	enemies.hit_ailments = {"chances": scaled, "effect": ctx["effect"], "duration": ctx["duration"]}


func try_use(index: int) -> bool:
	var p := profile(index)
	if p.is_empty() or cooldowns[index] > 0.0:
		return false
	if player.mana < p["mana_cost"]:
		if _mana_warning_cooldown <= 0.0:
			_mana_warning_cooldown = 1.5
			not_enough_mana.emit()
		return false
	if p["kind"] == "aura" and not is_aura_active(p["id"]) and player.mana_reserved + float(p["reserve"]) / 100.0 > 0.95 + 0.0001:
		if _mana_warning_cooldown <= 0.0:
			_mana_warning_cooldown = 1.5
			reservation_full.emit(String(p["name"]))
		return false
	if p["kind"] == "unit" and not _can_summon(p):
		if _mana_warning_cooldown <= 0.0:
			_mana_warning_cooldown = 1.5
			reservation_full.emit(String(p["name"]))
		return false
	player.mana -= p["mana_cost"]
	cooldowns[index] = p["cooldown"]
	_busy = p["use_time"]
	player.action_lock = minf(MAX_MOVE_LOCK, p["use_time"] * MOVE_LOCK_FRACTION)
	var target := _aim_target()
	player.face(target - player.global_position)
	Sfx.play(Sfx.skill_sound("trap" if p["deploy"] != "" else String(p["kind"]), String(p["damage_type"])))
	if p["deploy"] != "":
		_deploy(p, target)
		skill_used.emit(index)
		return true
	_execute(p, target)
	if p["kind"] in SkillCalc.AUTOMATON_KINDS or p["kind"] == "aura":
		skill_used.emit(index)
		return true   # en invocaciones la repetición ya va en su ritmo de ataque
	for r in int(p["repeats"]):
		_pending.append({"type": "repeat", "time": REPEAT_DELAY * (r + 1), "profile": p, "target": target})
	skill_used.emit(index)
	return true


## Dónde se lanza la habilidad: el ratón; con mando, el stick derecho o, si está
## suelto, el enemigo más cercano (o hacia donde mira el personaje).
func _aim_target() -> Vector2:
	if not Gamepad.active:
		return get_global_mouse_position()
	var stick := Vector2(Input.get_joy_axis(0, JOY_AXIS_RIGHT_X), Input.get_joy_axis(0, JOY_AXIS_RIGHT_Y))
	if stick.length() <= Gamepad.DEADZONE:
		var i := enemies.nearest_index(player.global_position, Gamepad.AIM_DISTANCE * 1.6)
		if i != -1:
			return enemies.positions[i]
	return Gamepad.aim_point(player.global_position, player.facing_direction())


## ¿Cabe otra invocación? Si ya están todas, volver a lanzarla las repara.
func _can_summon(p: Dictionary) -> bool:
	if _units_of(p["id"]).size() >= int(p["max_units"]):
		return true
	return player.mana_reserved + float(p["reserve"]) / 100.0 <= 0.95 + 0.0001


func _units_of(skill_id: String) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for u in _units:
		if u["skill_id"] == skill_id:
			out.append(u)
	return out


## Lo que hay activo ahora mismo (para los recuadros del HUD): esbirros, torretas,
## trampas, minas, giros e invocaciones persistentes, agrupados.
## Cada entrada: {name, skill, count, remaining, total, kind, persistent?}.
func active_summaries() -> Array[Dictionary]:
	var groups := {}
	var add := func(key: String, name: String, skill: Dictionary, remaining: float, total: float, kind: String) -> void:
		if not groups.has(key):
			groups[key] = {"name": name, "skill": skill, "count": 0, "remaining": 0.0, "total": total, "kind": kind}
		var g: Dictionary = groups[key]
		g["count"] += 1
		g["remaining"] = maxf(g["remaining"], remaining)
		g["total"] = maxf(g["total"], total)
	# Definición de cada habilidad (para su icono), sacada de los perfiles.
	var skills_db := {}
	for group in [_units, _minions, _drones, _devices, _traps, _spins]:
		for o in group:
			skills_db[o["profile"]["id"]] = o["profile"].get("def", {})
	for a in _auras:
		var ap: Dictionary = a["profile"]
		skills_db[ap["id"]] = ap.get("def", {})
		groups["aura:" + String(ap["id"])] = {"name": ap["name"], "skill": ap.get("def", {}), "count": 1, "remaining": 1.0, "total": 1.0,
			"kind": "aura", "persistent": true}
	for u in _units:
		var uid: String = u["skill_id"]
		var key := "unit:" + uid
		if not groups.has(key):
			groups[key] = {"name": u["profile"]["name"], "skill": skills_db.get(uid, {}), "count": 0, "remaining": 0.0,
				"total": 0.0, "kind": "unit", "persistent": true}
		var g: Dictionary = groups[key]
		g["count"] += 1
		# Para las persistentes, "remaining/total" es la vida de todas juntas.
		g["remaining"] += maxf(0.0, u["life"])
		g["total"] += u["max_life"]
		g["invulnerable"] = u["behavior"] == "orbit"
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
	_ctx(p)
	match p["kind"]:
		"leap_slam":
			# Salto: se mueve con colisión (no atraviesa paredes) y golpea al caer.
			var land := origin + (target - origin).limit_length(p["range"])
			if not device:
				player.move_and_collide(land - origin)
				player.stop_auto_move()
				land = player.global_position
			_effects.append({"type": "leap", "pos": origin, "end": land, "time": 0.0, "duration": 0.3, "color": color})
			if p["stun"] > 0.0:
				enemies.stun_in_radius(land, p["radius"], p["stun"])
			_damage_area(land, p["radius"], p)
			_effects.append({"type": "quake", "pos": land, "radius": p["radius"], "time": 0.0, "duration": 0.45, "color": color})
		"rain":
			var center := origin + (target - origin).limit_length(p["range"])
			var hits: int = maxi(1, p["rain_hits"])
			_rains.append({"pos": center, "left": hits, "next": 0.0, "interval": p["duration"] / hits, "profile": p, "color": color})
			_effects.append({"type": "marker", "pos": center, "radius": p["radius"], "time": 0.0, "duration": p["duration"] + 0.2, "color": color})
		"unit":
			if not device:
				_summon_unit(p, origin, color)
		"aura":
			if not device:
				_toggle_aura(p, color)
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
			_fire_volley(p, origin, dir, color, {"pierce_left": 999, "boomerang": true, "returning": false, "spin": 0.0, "homing": false})
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
			_fire_volley(p, origin, dir, color, {"dot": p["kind"] == "dot_projectile"})
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
			_fire_volley(p, origin, dir, color)
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


## Dispara los proyectiles de una habilidad en abanico hacia `dir`: uno sale recto
## («|»), dos en «V», tres en «\|/»... Solo persiguen enemigos si la habilidad es
## teledirigida (p["homing"]). `extra` añade o sustituye campos de cada proyectil.
func _fire_volley(p: Dictionary, origin: Vector2, dir: Vector2, color: Color, extra := {}, reach := -1.0) -> void:
	var count: int = maxi(1, int(p.get("projectiles", 1)))
	var spread := deg_to_rad(float(p.get("spread_degrees", 0.0)))
	for k in count:
		var angle := 0.0 if count == 1 else lerpf(-spread / 2.0, spread / 2.0, float(k) / (count - 1))
		var pr := {
			"pos": origin, "vel": dir.rotated(angle) * float(p["projectile_speed"]),
			"distance_left": reach if reach > 0.0 else float(p["range"]), "pierce_left": int(p["pierce"]),
			"hit_ids": {}, "profile": p, "color": color, "chains_left": int(p["projectile_chains"]),
			"homing": bool(p.get("homing", false)),
		}
		pr.merge(extra, true)
		_projectiles.append(pr)


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
		var scale := pow(float(p["chain_damage"]), k)
		hit[enemies.hit_index(i, p["min_damage"] * scale, p["max_damage"] * scale, p["crit_chance"], p["crit_multiplier"])] = true
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
			_ctx(p)
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
	var dpos := origin + (target - origin).limit_length(rules["range"])
	var device := {"kind": kind, "pos": dpos, "armed_in": rules["armed"],
		"life": life, "total": life, "profile": inner, "next_use": 0.0,
		"interval": maxf(0.35, float(p["use_time"]) * 1.25) / maxf(0.1, float(p["automaton_speed"])),
		"color": DAMAGE_COLORS.get(p["damage_type"], Color.WHITE)}
	if kind == "totem":
		# Las torretas tienen vida propia: los cazadores de invocaciones van a por ellas.
		var hp := player.max_life() * TOTEM_LIFE_FRACTION
		device["ally"] = {"pos": dpos, "life": hp, "max_life": hp, "radius": 14.0, "device": true, "hurt": 0.0}
	_devices.append(device)
	# Límite por tipo: se retira el más antiguo.
	var same: Array = _devices.filter(func(d: Dictionary) -> bool: return d["kind"] == kind)
	if same.size() > int(rules["max"]) + int(p.get("extra_devices", 0)):
		_devices.erase(same[0])


func _update_devices(delta: float) -> void:
	var still: Array[Dictionary] = []
	var proxies: Array = []
	for d in _devices:
		d["life"] -= delta
		d["armed_in"] -= delta
		if d["life"] <= 0.0:
			continue
		if d.has("ally"):
			if float(d["ally"]["life"]) <= 0.0:
				_effects.append({"type": "burst", "pos": d["pos"], "radius": 34.0, "time": 0.0, "duration": 0.4, "color": Color("ff7a4a")})
				continue   # la destruyeron
			proxies.append(d["ally"])
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
	# Aliados que ve el EnemyManager: invocaciones persistentes y torretas.
	var allies: Array = _units.filter(func(u: Dictionary) -> bool: return u["behavior"] != "orbit")
	allies.append_array(proxies)
	enemies.allies = allies


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
				m["cd"] = p["minion_interval"]
				_ctx(p)
				enemies.hit_index(i, p["min_damage"], p["max_damage"], p["crit_chance"], p["crit_multiplier"])
				_effects.append({"type": "burst", "pos": pos + to.normalized() * 14.0, "radius": 12.0, "time": 0.0, "duration": 0.15, "color": m["color"]})
		else:
			# Sin enemigos cerca: siguen al jugador.
			var to_player := player.global_position - pos
			if to_player.length() > 80.0:
				m["pos"] = pos + to_player.normalized() * MINION_SPEED * delta
		still.append(m)
	_minions = still


# --- Invocaciones persistentes ---

func _summon_unit(p: Dictionary, origin: Vector2, color: Color) -> void:
	var mine := _units_of(p["id"])
	var unit: Dictionary = p["unit"]
	if mine.size() >= int(p["max_units"]):
		# Ya están todas: se re-monta la más dañada (vida al máximo, junto al jugador).
		var worst: Dictionary = mine[0]
		for u in mine:
			if u["life"] / u["max_life"] < worst["life"] / worst["max_life"]:
				worst = u
		worst["life"] = worst["max_life"]
		if worst["behavior"] != "orbit":
			worst["pos"] = origin + Vector2.from_angle(randf() * TAU) * 40.0
		_effects.append({"type": "ring", "pos": worst["pos"], "radius": 34.0, "time": 0.0, "duration": 0.4, "color": color})
		return
	var life: float = maxf(1.0, p["unit_life"])
	var u := {"skill_id": p["id"], "profile": p, "behavior": String(unit.get("behavior", "melee")),
		"pos": origin + Vector2.from_angle(randf() * TAU) * 45.0, "life": life, "max_life": life,
		"radius": float(unit.get("radius", 12.0)), "taunt": float(unit.get("taunt", 0.0)), "reduction": float(p["unit_reduction"]), "base_reduction": float(p["unit_reduction"]),
		"ab_cd": float(p["unit_ability"].get("cooldown", p["unit_interval"])) * 0.5,
		"cd": 0.5, "phase": randf() * TAU, "hurt": 0.0, "angle": TAU * mine.size() / maxf(1.0, p["max_units"]),
		"slot": mine.size(), "color": color}
	_units.append(u)
	_effects.append({"type": "ring", "pos": u["pos"], "radius": 40.0 + u["radius"], "time": 0.0, "duration": 0.5, "color": color})
	_update_reservation()


func _update_units(delta: float) -> void:
	if _units.is_empty():
		return
	if not player.is_alive():
		clear_units()
		return
	var lost := false
	var still: Array[Dictionary] = []
	for u in _units:
		u["hurt"] = maxf(0.0, float(u.get("hurt", 0.0)) - delta)
		u["phase"] += delta * 6.0
		u["cd"] -= delta
		# Auras con alcance: fuera del radio la invocación pelea con sus cifras sin auras.
		var in_aura := in_aura_range(u["pos"])
		u["in_aura"] = in_aura
		var p: Dictionary = u["profile"] if in_aura else _bare_profiles.get(u["skill_id"], u["profile"])
		u["reduction"] = minf(0.8, float(u["base_reduction"]) + (_aura_reduction if in_aura else 0.0))
		if in_aura and _aura_regen > 0.0 and u["behavior"] != "orbit":
			u["life"] = minf(u["max_life"], u["life"] + u["max_life"] * _aura_regen / 100.0 * delta)
		if u["life"] <= 0.0:
			var death_color := Color("ff7a4a")
			if String(p["unit_ability"].get("kind", "")) == "explode":
				# Mina Rodante: explota al caer.
				var boom_radius: float = float(p["unit_ability"].get("radius", 90.0)) * float(p.get("area_scale", 1.0)) * sqrt(float(p.get("ability_power", 1.0)))
				_ctx(p)
				var boom_p := p.duplicate()
				boom_p["min_damage"] = float(p["min_damage"]) * float(p.get("ability_power", 1.0))
				boom_p["max_damage"] = float(p["max_damage"]) * float(p.get("ability_power", 1.0))
				_damage_area(u["pos"], boom_radius, boom_p)
				Sfx.play("mine", -4.0)
				_effects.append({"type": "quake", "pos": u["pos"], "radius": boom_radius, "time": 0.0, "duration": 0.5, "color": u["color"]})
				death_color = u["color"]
			_effects.append({"type": "burst", "pos": u["pos"], "radius": 36.0 + u["radius"], "time": 0.0, "duration": 0.4, "color": death_color})
			unit_lost.emit(String(p["name"]))
			lost = true
			continue
		_unit_ability(u, p, delta)
		if (u["pos"] as Vector2).distance_to(player.global_position) > UNIT_LEASH:
			u["pos"] = player.global_position + Vector2.from_angle(randf() * TAU) * 60.0   # se ha quedado atrás
		var unit: Dictionary = p["unit"]
		var speed := float(unit.get("speed", 220.0))
		var reach_range := float(unit.get("range", 450.0))
		match String(u["behavior"]):
			"orbit":
				u["angle"] += delta * 1.3
				u["pos"] = player.global_position + Vector2.from_angle(u["angle"]) * Vector2(72, 46) + Vector2(0, -34)
				if p["unit_shoots"]:
					_unit_shoot(u, p, reach_range)
			"ranged":
				# Se queda a un lado del jugador y dispara a distancia.
				var goal := player.global_position + Vector2.from_angle(PI * 0.8 + u["slot"] * 1.1) * Vector2(74, 52)
				_unit_step(u, goal, speed, delta, 10.0)
				_unit_shoot(u, p, reach_range)
			_:
				# Cuerpo a cuerpo (daemon) o tanque (golem): van a por el enemigo más cercano.
				var pos: Vector2 = u["pos"]
				var i := enemies.nearest_index(pos, reach_range)
				if i != -1 and enemies.positions[i].distance_to(player.global_position) < reach_range * 1.8:
					var to := enemies.positions[i] - pos
					var reach: float = enemies.radii[i] + u["radius"] + 4.0
					if to.length() > reach:
						_unit_step(u, enemies.positions[i], speed, delta, reach)
					elif u["cd"] <= 0.0 and String(p["unit_ability"].get("kind", "")) == "explode":
						u["life"] = 0.0   # kamikaze: al tocar, explota
					elif u["cd"] <= 0.0:
						u["cd"] = p["unit_interval"]
						_ctx(p)
						if u["behavior"] == "tank":
							if p["stun"] > 0.0:
								enemies.stun_in_radius(pos, p["radius"], p["stun"])
							_damage_area(pos, p["radius"], p)
							_effects.append({"type": "quake", "pos": pos, "radius": p["radius"], "time": 0.0, "duration": 0.35, "color": u["color"]})
						else:
							enemies.hit_index(i, p["min_damage"], p["max_damage"], p["crit_chance"], p["crit_multiplier"])
							_leech(p)
							_effects.append({"type": "burst", "pos": pos + to.normalized() * u["radius"], "radius": 14.0, "time": 0.0, "duration": 0.15, "color": u["color"]})
				else:
					_unit_step(u, player.global_position + Vector2.from_angle(PI * 0.5 + u["slot"] * 1.4) * 70.0, speed, delta, 12.0)
		still.append(u)
	_units = still
	if lost:
		_update_reservation()


## Habilidad propia de la invocación (unit.ability): cura, barrera, salto o veneno.
func _unit_ability(u: Dictionary, p: Dictionary, delta: float) -> void:
	var ab: Dictionary = p["unit_ability"]
	if ab.is_empty():
		return
	u["ab_cd"] -= delta
	if u["ab_cd"] > 0.0:
		return
	var speed := maxf(0.1, float(p["automaton_speed"]))
	var pos: Vector2 = u["pos"]
	match String(ab.get("kind", "")):
		"heal":
			var hurt := player.life < player.max_life() - 0.5
			for other in _units:
				hurt = hurt or other["life"] < other["max_life"] - 0.5
			if not hurt:
				u["ab_cd"] = 0.4
				return
			u["ab_cd"] = float(p["unit_interval"])
			player.heal(player.max_life() * float(ab.get("player_pct", 5)) / 100.0 * float(p.get("ability_power", 1.0)))
			Sfx.play("heal", -8.0)
			_effects.append({"type": "ring", "pos": player.global_position, "radius": 46.0, "time": 0.0, "duration": 0.5, "color": u["color"]})
			for other in _units:
				other["life"] = minf(other["max_life"], other["life"] + other["max_life"] * float(ab.get("unit_pct", 10)) / 100.0 * float(p.get("ability_power", 1.0)))
				if other["behavior"] != "orbit":
					_effects.append({"type": "ring", "pos": other["pos"], "radius": 26.0, "time": 0.0, "duration": 0.4, "color": u["color"]})
		"barrier":
			if player.barrier > 0.0:
				u["ab_cd"] = 0.5
				return
			u["ab_cd"] = float(p["unit_interval"])
			player.add_barrier((float(ab.get("barrier", 20)) + float(ab.get("barrier_life", 0.1)) * player.max_life()) * float(p.get("ability_power", 1.0)), 6.0)
			Sfx.play("barrier", -8.0, 1.2)
			_effects.append({"type": "ring", "pos": player.global_position, "radius": 60.0, "time": 0.0, "duration": 0.5, "color": Color("cfe8ff")})
		"leap":
			# Salta sobre el enemigo más lejano a su alcance y golpea el suelo al caer.
			var best := -1
			var best_d := 0.0
			for i in enemies.positions.size():
				var d: float = enemies.positions[i].distance_to(pos)
				if d > 170.0 and d <= float(p["unit"].get("range", 500.0)) and enemies.positions[i].distance_to(player.global_position) < 700.0 and d > best_d:
					best_d = d
					best = i
			if best == -1:
				u["ab_cd"] = 0.5
				return
			u["ab_cd"] = float(ab.get("cooldown", 5.0)) / speed
			var land: Vector2 = enemies.positions[best] - (enemies.positions[best] - pos).normalized() * 18.0
			if enemies.walk_clamp.is_valid():
				land = enemies.walk_clamp.call(land, u["radius"])
			_effects.append({"type": "leap", "pos": pos, "end": land, "time": 0.0, "duration": 0.3, "color": u["color"]})
			u["pos"] = land
			_ctx(p)
			var leap_radius := float(ab.get("radius", 75.0)) * float(p.get("area_scale", 1.0))
			var leap_mult := float(ab.get("damage_mult", 1.5)) * float(p.get("ability_power", 1.0))
			enemies.hit_in_radius(land, leap_radius, p["min_damage"] * leap_mult,
				p["max_damage"] * leap_mult, p["crit_chance"], p["crit_multiplier"])
			_effects.append({"type": "quake", "pos": land, "radius": leap_radius, "time": 0.0, "duration": 0.4, "color": u["color"]})
		"venom":
			var t := enemies.nearest_index(pos, float(p["unit"].get("range", 520.0)))
			if t == -1:
				u["ab_cd"] = 0.5
				return
			u["ab_cd"] = float(ab.get("cooldown", 7.0)) / speed
			var cloud := p.duplicate()
			cloud["tick"] = 0.5
			cloud["radius"] = float(ab.get("radius", 95.0)) * float(p.get("area_scale", 1.0))
			cloud["duration"] = float(ab.get("duration", 4.0)) * float(p.get("ability_power", 1.0))
			cloud["min_damage"] = p["min_damage"] * 1.1
			cloud["max_damage"] = p["max_damage"] * 1.1
			cloud["crit_chance"] = 0.0
			_clouds.append({"pos": enemies.positions[t], "life": cloud["duration"], "next": 0.0, "profile": cloud, "color": u["color"], "seed": randi()})


## Avanza hacia `goal` hasta quedarse a `stop` de él, sin salirse del terreno.
func _unit_step(u: Dictionary, goal: Vector2, speed: float, delta: float, stop: float) -> void:
	var to: Vector2 = goal - u["pos"]
	if to.length() <= stop:
		return
	var new_pos: Vector2 = u["pos"] + to.normalized() * minf(speed * delta, to.length() - stop)
	if enemies.walk_clamp.is_valid():
		new_pos = enemies.walk_clamp.call(new_pos, u["radius"])
	u["pos"] = new_pos


func _unit_shoot(u: Dictionary, p: Dictionary, reach_range: float) -> void:
	if u["cd"] > 0.0:
		return
	var pos: Vector2 = u["pos"]
	var t := enemies.nearest_index(pos, reach_range)
	if t == -1:
		u["cd"] = 0.2
		return
	u["cd"] = p["unit_interval"]
	var dir: Vector2 = (enemies.positions[t] - pos).normalized()
	_fire_volley(p, pos, dir, u["color"], {}, reach_range * 1.5)
	_effects.append({"type": "burst", "pos": pos + dir * 10.0, "radius": 8.0, "time": 0.0, "duration": 0.12, "color": u["color"]})


# --- Lluvia de impactos (Cascada de Estilos) ---

func _update_rains(delta: float) -> void:
	var still: Array[Dictionary] = []
	for rain in _rains:
		rain["next"] -= delta
		while rain["next"] <= 0.0 and rain["left"] > 0:
			rain["next"] += rain["interval"]
			rain["left"] -= 1
			var p: Dictionary = rain["profile"]
			var spot: Vector2 = rain["pos"] + Vector2.from_angle(randf() * TAU) * sqrt(randf()) * p["radius"]
			_pending.append({"type": "blast", "time": 0.16, "pos": spot, "profile": p, "color": rain["color"], "radius": p["impact_radius"]})
			_effects.append({"type": "streak", "pos": spot, "radius": p["impact_radius"], "time": 0.0, "duration": 0.16, "color": rain["color"]})
		if rain["left"] > 0:
			still.append(rain)
	_rains = still


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
				_fire_volley(p, pos, dir, d["color"], {}, p["seek_range"] * 1.5)
			else:
				d["next"] = 0.2
		still.append(d)
	_drones = still


func _drone_pos(d: Dictionary) -> Vector2:
	return player.global_position + Vector2.from_angle(d["angle"]) * Vector2(55, 34) + Vector2(0, -28)


# --- Robot de compañía ---

## Sigue al jugador por encima del hombro; dispara su láser al enemigo más
## cercano y, si alguno se acerca demasiado, suelta un pulso EMP que aturde.
func _update_companion(delta: float) -> void:
	if _companion_laser.is_empty() or not player.is_alive():
		_companion = {}
		return
	if _companion.is_empty():
		_companion = {"pos": player.global_position + Vector2(-40, -40), "laser": 0.6, "emp": 3.0, "bob": 0.0}
		_effects.append({"type": "ring", "pos": _companion["pos"], "radius": 30.0, "time": 0.0, "duration": 0.4, "color": Color("7fd0e8")})
	var goal := player.global_position + Vector2(-44, -46)
	_companion["pos"] = (_companion["pos"] as Vector2).lerp(goal, 1.0 - exp(-4.0 * delta))
	_companion["bob"] += delta
	_companion["laser"] -= delta
	_companion["emp"] -= delta
	var pos: Vector2 = _companion["pos"]
	if _companion["laser"] <= 0.0:
		var t := enemies.nearest_index(pos, float(_companion_laser["seek_range"]))
		if t != -1:
			_execute(_companion_laser, enemies.positions[t], pos)
			_companion["laser"] = CompanionRobot.LASER_INTERVAL / maxf(0.1, float(_companion_laser["automaton_speed"]))
		else:
			_companion["laser"] = 0.2
	if _companion["emp"] <= 0.0:
		if enemies.nearest_index(player.global_position, float(_companion_emp["radius"])) != -1:
			_execute(_companion_emp, player.global_position, player.global_position)
			_companion["emp"] = CompanionRobot.EMP_INTERVAL
			Sfx.play("lightning", -6.0, 0.8)
		else:
			_companion["emp"] = 0.4


func _draw_companion() -> void:
	if _companion.is_empty():
		return
	var p: Vector2 = _companion["pos"] + Vector2(0, sin(_companion["bob"] * 3.0) * 3.0)
	draw_circle(p + Vector2(0, 40), 7.0, Color(0, 0, 0, 0.25))
	for s in [-1.0, 1.0]:   # propulsores
		draw_circle(p + Vector2(s * 7, 9), 3.0 + sin(_companion["bob"] * 20.0 + s) * 0.8, Color(0.5, 0.85, 1.0, 0.5))
	draw_rect(Rect2(p - Vector2(11, 8), Vector2(22, 16)), Color("6e7480"))
	draw_rect(Rect2(p - Vector2(11, 8), Vector2(22, 16)), Color("3a3f4a"), false, 1.5)
	draw_rect(Rect2(p - Vector2(8, 5), Vector2(16, 7)), Color("15181e"))
	var eye := 0.6 + 0.4 * sin(_companion["bob"] * 4.0)
	draw_rect(Rect2(p - Vector2(5, 3), Vector2(10, 3)), Color(0.4, 0.95, 1.0, eye))
	draw_line(p + Vector2(0, -8), p + Vector2(0, -14), Color("3a3f4a"), 1.5)
	draw_circle(p + Vector2(0, -15), 2.0, Color("ff5a4a") if _companion["emp"] < 1.0 else Color("e8d070"))
	var font := ThemeDB.fallback_font
	draw_string(font, p + Vector2(-20, 22), "R-2PL", HORIZONTAL_ALIGNMENT_CENTER, 40, 9, Color(0.75, 0.9, 1.0, 0.7))


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
			_ctx(p, k)
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
			_ctx(p)
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
		_ctx(p)
		if e["type"] == "blast":
			var radius: float = e.get("radius", p["radius"])
			_damage_area(e["pos"], radius, p)
			_effects.append({"type": "burst", "pos": e["pos"], "radius": radius, "time": 0.0, "duration": 0.3, "color": e["color"]})
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
		_ctx(p)
		if pr.get("dot", false):
			hit = enemies.dot_one(pr["pos"], PROJECTILE_RADIUS, pr["hit_ids"], (p["min_damage"] + p["max_damage"]) / 2.0, p["duration"])
		else:
			var dm: float = pr.get("dmg_mult", 1.0)
			hit = enemies.hit_one(pr["pos"], PROJECTILE_RADIUS, pr["hit_ids"], p["min_damage"] * dm, p["max_damage"] * dm, p["crit_chance"], p["crit_multiplier"])
		if hit != -1:
			_leech(p)
			pr["hit_ids"][hit] = true
			var next := enemies.nearest_index(pr["pos"], 260.0, pr["hit_ids"]) if pr.get("chains_left", 0) > 0 else -1
			if next != -1:
				# Encadenamiento: rebota hacia otro enemigo en vez de gastar perforación.
				pr["chains_left"] -= 1
				pr["dmg_mult"] = float(pr.get("dmg_mult", 1.0)) * float(p["chain_damage"])
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
	_draw_auras()
	_draw_clouds()
	_draw_devices()
	_draw_minions()
	_draw_units()
	_draw_companion()
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
			"leap":
				# Arco del salto: una sombra que recorre el camino y una estela.
				var a: Vector2 = e["pos"]
				var b: Vector2 = e["end"]
				var pts := PackedVector2Array()
				for k in 9:
					var s := k / 8.0
					pts.append(a.lerp(b, s) + Vector2(0, -sin(s * PI) * 60.0))
				draw_polyline(pts, Color(c, 0.6 * (1.0 - t)), 4.0 * (1.0 - t) + 1.0, true)
			"quake":
				# Golpe al suelo: anillo que se expande y grietas.
				var r: float = e["radius"]
				draw_set_transform(e["pos"], 0.0, Vector2(1.0, 0.6))
				draw_circle(Vector2.ZERO, r * (0.4 + 0.6 * t), Color(c, 0.22 * (1.0 - t)))
				draw_arc(Vector2.ZERO, r * (0.4 + 0.6 * t), 0.0, TAU, 40, Color(c.lightened(0.3), 0.9 * (1.0 - t)), 4.0, true)
				draw_set_transform(Vector2.ZERO)
				for k in 6:
					var ang := TAU * k / 6.0 + 0.4
					var p0: Vector2 = e["pos"] + Vector2.from_angle(ang) * Vector2(1.0, 0.6) * r * 0.25
					var p1: Vector2 = e["pos"] + Vector2.from_angle(ang + 0.15) * Vector2(1.0, 0.6) * r * 0.8
					draw_line(p0, p1, Color(0.1, 0.08, 0.06, 0.8 * (1.0 - t)), 2.0, true)
			"streak":
				# Proyectil que cae del cielo hasta el punto de impacto.
				var top: Vector2 = e["pos"] + Vector2(-60.0, -260.0) * (1.0 - t)
				draw_line(top + Vector2(-12.0, -46.0), top, Color(c, 0.4), 3.0, true)
				draw_circle(top, 5.0, c.lightened(0.4))
				draw_arc(e["pos"], e["radius"] * 0.7, 0.0, TAU, 20, Color(c, 0.5 * t), 1.5, true)
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
				var hp: Dictionary = d.get("ally", {})
				if not hp.is_empty() and float(hp["life"]) < float(hp["max_life"]):
					# Herida por un cazador: barra de vida.
					draw_rect(Rect2(p + Vector2(-14, -52), Vector2(28, 4)), Color(0, 0, 0, 0.75))
					draw_rect(Rect2(p + Vector2(-14, -52), Vector2(28.0 * clampf(hp["life"] / hp["max_life"], 0.0, 1.0), 4)), Color("6fd36b"))


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


## Aros girando alrededor del jugador (uno por aura) y una marca sobre cada aliado beneficiado.
func _draw_auras() -> void:
	if _auras.is_empty() or not player.is_alive():
		return
	var tt := Time.get_ticks_msec() / 1000.0
	# Alcance: un círculo tenue con el radio de cada aura (las que debilitan, en rojo).
	for a in _auras:
		var ar := float(a["profile"].get("aura_radius", 0.0))
		if ar > 0.0:
			var hostile: bool = not a["profile"].get("aura_enemy", {}).is_empty()
			var rc: Color = Color("e06c6c") if hostile else a["color"]
			var ac := aura_center(a)
			if bool(a["profile"].get("aura_anchor", false)):
				# Torre de Señal: una antena en el centro del aura anclada.
				draw_line(ac, ac + Vector2(0, -34), Color("8a8a96"), 3.0)
				draw_circle(ac + Vector2(0, -36), 4.0 + sin(Time.get_ticks_msec() / 200.0), rc)
			draw_set_transform(ac, 0.0, Vector2(1.0, 0.62))
			draw_circle(Vector2.ZERO, ar, Color(rc, 0.035 if hostile else 0.02))
			draw_arc(Vector2.ZERO, ar, 0.0, TAU, 64, Color(rc, 0.28), 1.5, true)
			draw_set_transform(Vector2.ZERO)
	var k := 0
	for a in _auras:
		var c: Color = a["color"]
		var radius := 54.0 + k * 9.0
		draw_set_transform(player.global_position + Vector2(0, 14), 0.0, Vector2(1.0, 0.5))
		for q in 4:
			var a0 := tt * (0.9 + k * 0.3) + TAU * q / 4.0
			draw_arc(Vector2.ZERO, radius, a0, a0 + 0.9, 10, Color(c, 0.55), 2.0, true)
		draw_set_transform(Vector2.ZERO)
		for u in _units:
			if u["behavior"] != "orbit":
				draw_circle((u["pos"] as Vector2) + Vector2(0, u["radius"] * 0.5), 3.0 + sin(tt * 4.0 + k) * 0.6, Color(c, 0.5))
		k += 1


## Invocaciones persistentes: cada comportamiento tiene su figura.
func _draw_units() -> void:
	for u in _units:
		var p: Vector2 = u["pos"]
		var ph: float = u["phase"]
		var c: Color = u["color"]
		var hurt: bool = u.get("hurt", 0.0) > 0.0
		var r: float = u["radius"]
		if u["behavior"] != "orbit":
			draw_set_transform(p + Vector2(0, r * 0.7), 0.0, Vector2(1.0, 0.4))
			draw_circle(Vector2.ZERO, r * 1.1, Color(0, 0, 0, 0.35))
			draw_set_transform(Vector2.ZERO)
		UnitArt.draw(self, String(u["skill_id"]), String(u["behavior"]), p, ph, c)
		if hurt:
			draw_circle(p + Vector2(0, -r), r * 1.1, Color(1, 1, 1, 0.35))
		if u["behavior"] != "orbit":
			# Barra de vida con el símbolo de persistente.
			var w := maxf(24.0, r * 2.2)
			var top := p + Vector2(-w / 2.0, -r * 2.6 - 14.0)
			draw_rect(Rect2(top - Vector2(1, 1), Vector2(w + 2.0, 5.0)), Color(0, 0, 0, 0.75))
			draw_rect(Rect2(top, Vector2(w * clampf(u["life"] / u["max_life"], 0.0, 1.0), 3.0)), Color("6fd36b"))
			if u["taunt"] > 0.0:
				draw_arc(p, u["taunt"], 0.0, TAU, 48, Color(Ailments.color("taunt"), 0.12), 1.5, true)


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
