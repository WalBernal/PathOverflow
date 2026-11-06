class_name SkillController
extends Node2D
## Lanza las habilidades de la barra (placas base instaladas) y dibuja sus
## efectos: proyectiles, explosiones, ondas, teletransporte, embestidas, conos,
## rayos, bumeranes, giros, trampas y cadenas.
## Las cifras salen de SkillCalc; aquí solo se aplican.

signal skill_used(hotbar_index: int)
signal not_enough_mana
## La habilidad cuesta vida y no te sobra.
signal not_enough_life
## No queda maná sin reservar para otra invocación persistente.
signal reservation_full(skill_name: String)
## Se intentó lanzar a mano una habilidad con RAM de activación (se lanza sola).
signal trigger_only(skill_name: String)
## Una RAM de activación lanzó la habilidad de esa ranura.
signal skill_triggered(hotbar_index: int)
## Una invocación persistente ha caído.
signal unit_lost(skill_name: String)

const ACTIONS := [&"skill_1", &"skill_2", &"skill_3", &"skill_4", &"skill_5", &"skill_6"]
const KEY_LABELS := ["Q", "W", "E", "R", "T", "Y"]
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
## Punto libre más cercano (sin paredes ni obstáculos) para los teletransportes; lo pone World.
var spot_fixer: Callable
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
	# Contenedor Docker: no caduca (reserva maná); uno por habilidad, relanzarla lo mueve.
	"container": {"range": 300.0, "armed": 0.5, "life": 1.0e9, "trigger": 650.0, "max": 1},
}
## Dispositivos que disparan solos (los demás se activan al pisarlos).
const TURRET_DEVICES := ["totem", "container"]
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
	player.dodged.connect(on_player_dodged)
	player.heal_minions_requested.connect(heal_units)
	enemies.crit_dealt.connect(on_crit)
	var saved_auras: Array = character.flags.get("active_auras", []).duplicate()
	refresh_profiles()
	_restore_auras(saved_auras)


## Vuelve a encender las auras que estaban activas al guardar (o al cambiar de
## zona), sin sonido ni destello; las que ya no están en la barra se ignoran.
func _restore_auras(ids: Array) -> void:
	for p in _profiles:
		if not p.is_empty() and p["kind"] == "aura" and String(p["id"]) in ids:
			var a := {"skill_id": p["id"], "profile": p, "color": DAMAGE_COLORS.get(p["damage_type"], Color.WHITE), "sig": str(p["aura_mods"]), "anchor": Vector2.INF}
			_aura_fx_state(a, 1.0)   # ya encendida: sin la animación de activarse
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
	_refresh_containers()
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
	# Terrenos que ralentizan (aceite, superconductor).
	for t in _terrains:
		var slow: float = TERRAIN_SLOW.get(t["terrain"], 0.0)
		if slow > 0.0:
			fields.append({"pos": t["pos"], "radius": t["radius"], "slow": slow, "damage_taken": 0.0})
	enemies.aura_fields = fields


func _update_reservation() -> void:
	var total := 0.0
	for u in _units:
		total += float(u["profile"]["reserve"]) / 100.0
	for a in _auras:
		total += float(a["profile"]["reserve"]) / 100.0
	for d in _devices:
		if d["kind"] == "container":
			total += float(d["profile"]["reserve"]) / 100.0
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
	# Lo que sigue al jugador mientras dura su buff (T195) se muda con él.
	_effects.assign(_effects.filter(func(e: Dictionary) -> bool: return e.get("live", false)))
	_pending.clear()
	_traps.clear()
	_devices.clear()
	_update_reservation()   # los contenedores se quedan en la zona anterior
	_channel = {}
	_fire_walls.clear()
	_clouds.clear()
	_terrains.clear()
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
	_sync_golem_buffs()


## Bonos de los golems vivos (unit.owner_buff) como efectos "golem:<habilidad>"
## en el personaje; se quitan al caer el último de esa habilidad. Solo se tocan si
## cambian (recalcular las stats rehace los perfiles).
var _golem_sigs := {}


func _sync_golem_buffs() -> void:
	var want := {}
	for u in _units:
		var ob: Array = u["profile"].get("owner_buff", [])
		if not ob.is_empty():
			want[String(u["skill_id"])] = ob
	for e in character.timed_effects.duplicate():
		var eid := String(e["id"])
		if eid.begins_with("golem:") and not want.has(eid.trim_prefix("golem:")):
			character.remove_timed_effect(eid)
			_golem_sigs.erase(eid.trim_prefix("golem:"))
	for sid in want:
		var sig := str(want[sid])
		if _golem_sigs.get(sid, "") == sig:
			continue
		_golem_sigs[sid] = sig
		var mods: Array[Modifier] = []
		for md in want[sid]:
			mods.append(Modifier.from_dict(md, "golem:" + sid))
		character.set_timed_effect("golem:" + sid, mods)


## Bono que da ahora mismo el golem de esa habilidad (para tooltips): [Modifier].
func golem_buff_lines(skill_id: String) -> PackedStringArray:
	var out := PackedStringArray()
	for e in character.timed_effects:
		if e["id"] == "golem:" + skill_id:
			for m in e["mods"]:
				out.append((m as Modifier).describe())
	return out


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
			# Su anillo se desdibuja en sentido contrario donde estaba (T195).
			var center := aura_center(_auras[k])
			_effects.append(SkillFx.move_fx("aura_off", center, center, Vector2.RIGHT,
				float(_auras[k]["profile"].get("aura_radius", 0.0)), SkillFx.aura_tint(String(p["id"]), color)))
			character.remove_timed_effect("aura:" + String(p["id"]))
			_auras.remove_at(k)
			_remember_auras()
			Sfx.play("aura_off", -6.0)
			refresh_profiles()
			return
	var a := {"skill_id": p["id"], "profile": p, "color": color, "sig": str(p["aura_mods"]), "anchor": player.global_position}
	_aura_fx_state(a, 0.0)
	_auras.append(a)
	_remember_auras()
	SoundMap.play_cast(p)   # aura_on + su capa de firma: la única vez que suena al encenderla (T192)
	_apply_aura_effect(a)   # recalcula las stats y, con ello, los perfiles y la reserva
	_update_reservation()


# --- Firmas de buffs, gritos, barrera y auras (T195) ---

## Lo que el dibujo de un aura necesita guardar: cuánto lleva encendida (`on_t`) y, en
## las hostiles, qué enemigos tiene dentro (hasta SkillFx.AURA_MARKS, por índice y por
## id) y desde cuándo (`entered`, id → on_t al entrar); se mira cada 0,25 s, no por fotograma.
func _aura_fx_state(a: Dictionary, on_t: float) -> void:
	a["on_t"] = on_t
	a["scan"] = 0.0
	a["inside"] = PackedInt32Array()
	a["inside_ids"] = PackedInt32Array()
	a["entered"] = {}


func _update_aura_fx(delta: float) -> void:
	for a in _auras:
		if not a.has("on_t"):
			_aura_fx_state(a, 1.0)
		a["on_t"] = float(a["on_t"]) + delta
		if a["profile"].get("aura_enemy", {}).is_empty():
			continue
		a["scan"] = float(a["scan"]) - delta
		if a["scan"] > 0.0:
			continue
		a["scan"] = 0.25
		var idx := PackedInt32Array()
		var ids := PackedInt32Array()
		var seen := {}
		if not fx_light():   # con muchos enemigos en pantalla, sin marcas
			var old: Dictionary = a["entered"]
			var center := aura_center(a)
			var r := float(a["profile"]["aura_radius"])
			for i in enemies.positions.size():
				if enemies.positions[i].distance_to(center) <= r:
					var eid := enemies.ids[i]
					seen[eid] = old.get(eid, a["on_t"])
					if idx.size() < SkillFx.AURA_MARKS:
						idx.append(i)
						ids.append(eid)
		a["inside"] = idx
		a["inside_ids"] = ids
		a["entered"] = seen


## Efecto de lanzamiento de un buff, grito o barrera con firma. Los que siguen al jugador
## mientras dura el buff ("live") los mueve _update_live; relanzarlo quita el anterior.
func _buff_fx(p: Dictionary, origin: Vector2, device := false) -> void:
	var id := String(p["id"])
	var live := SkillFx.is_live(id) and not device
	var cast := float(SkillFx.BUFF_FX.get(id, 0.4))
	if live:
		_effects.assign(_effects.filter(func(e: Dictionary) -> bool: return not (e["type"] == "firma" and e["firma"] == id)))
	var extra := {"cast": cast, "live": live, "end": -1.0}
	if live:
		extra["duration"] = maxf(cast, float(p.get("duration", cast))) + SkillFx.BUFF_FADE
	var marks := PackedVector2Array()
	match id:
		"rollback_grito":
			if float(p.get("heal_allies", 0.0)) > 0.0:
				for u in _units:
					if marks.size() < SkillFx.MAX_MARKS:
						marks.append(u["pos"])
		"hiperthreading":
			extra["lag"] = origin
			extra["back"] = Vector2(-4, 0)
		"daily_standup":
			var steps := PackedVector2Array()
			steps.resize(SkillFx.DAILY_STEPS)
			var times := PackedFloat32Array()
			times.resize(SkillFx.DAILY_STEPS)
			times.fill(-9.0)
			extra.merge({"steps": steps, "step_times": times, "step_n": 0, "step_t": 0.0, "last_step": origin})
	_move_fx(p, origin, origin, Vector2.RIGHT, DAMAGE_COLORS["none"], marks, extra)


func _has_buff(effect_id: String) -> bool:
	for te in character.timed_effects:
		if te["id"] == effect_id:
			return true
	return false


## Lo que sigue al jugador mientras dura el buff: su posición, el doble de Hiperthreading
## que va con retraso y las huellas de Daily. Se apaga al acabarse el buff o la barrera.
func _update_live(e: Dictionary, delta: float) -> void:
	var pos := player.global_position
	if pos.distance_to(e["pos"]) > 300.0:
		# Un salto (cambio de zona o teletransporte largo): el doble no cruza el mapa
		# y las huellas no se quedan pintadas donde ya no está el jugador.
		if e.has("lag"):
			e["lag"] = pos
		if e.has("step_times"):
			var times: PackedFloat32Array = e["step_times"]
			times.fill(-9.0)
			e["step_times"] = times
			e["last_step"] = pos
	e["pos"] = pos
	if float(e["end"]) >= 0.0:
		return
	var id := String(e["firma"])
	var over: bool = not player.is_alive() or float(e["time"]) >= float(e["duration"]) - SkillFx.BUFF_FADE
	if float(e["time"]) > 0.1:
		over = over or (player.barrier <= 0.0 if id == "firewall_personal" else not _has_buff("skill:" + id))
	if over:
		e["end"] = e["time"]
		e["duration"] = float(e["time"]) + (0.3 if id == "firewall_personal" else SkillFx.BUFF_FADE)
		return
	match id:
		"hiperthreading":
			# El segundo hilo: va 0,05 s por detrás y un poco detrás según hacia dónde se mueve.
			e["lag"] = (e["lag"] as Vector2).lerp(pos, clampf(delta / 0.05, 0.0, 1.0))
			if player.velocity.length() > 1.0:
				e["back"] = -player.velocity.normalized() * 4.0
		"daily_standup":
			e["step_t"] = float(e["step_t"]) + delta
			if e["step_t"] >= 0.1:
				e["step_t"] = 0.0
				if pos.distance_to(e["last_step"]) > 2.0:
					var n := int(e["step_n"])
					var slot := n % SkillFx.DAILY_STEPS
					var steps: PackedVector2Array = e["steps"]
					var times: PackedFloat32Array = e["step_times"]
					steps[slot] = pos + Vector2(3.0 if n % 2 == 0 else -3.0, 2.0)
					times[slot] = e["time"]
					e["steps"] = steps
					e["step_times"] = times
					e["step_n"] = n + 1
					e["last_step"] = pos


## Al recibir un golpe: el hexágono de Modo Seguro destella y, si la barrera de Firewall lo
## absorbe, el ladrillo del lado del golpe suelta «DENY» (como mucho uno cada 0,25 s).
func _buff_fx_hit() -> void:
	for e in _effects:
		if e["type"] != "firma" or not e.get("live", false) or float(e["end"]) >= 0.0:
			continue
		match String(e["firma"]):
			"modo_seguro":
				e["hit"] = e["time"]
			"firewall_personal":
				if player.barrier > 0.0 and float(e["time"]) - float(e.get("hit", -9.0)) > 0.25:
					e["hit"] = e["time"]
					var i := enemies.nearest_index(player.global_position, 240.0)
					var d := (enemies.positions[i] - player.global_position).normalized() if i != -1 else Vector2.RIGHT
					e["hit_dir"] = d if d != Vector2.ZERO else Vector2.RIGHT


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


# --- Habilidades propias de clase (Stat.FIRE_WALL, SPRINT_DEMO, ...) ---

## Cada una: cada cuánto se usa, a qué distancia tiene que haber un enemigo, su
## tipo de daño y su daño base (por_nivel × nivel + plano), que luego multiplica
## el daño del personaje de ese tipo (signature_damage).
const SIGNATURES := {
	Stat.FIRE_WALL: {"interval": 7.0, "range": 320.0, "type": "fire", "per_level": 1.6, "flat": 6.0, "color": Color("ff7a3a")},
	Stat.SPRINT_DEMO: {"interval": 10.0, "range": 400.0, "type": "physical", "per_level": 6.0, "flat": 20.0, "color": Color("e8d9b0")},
	Stat.PROFILED_SHOT: {"interval": 5.0, "range": 650.0, "type": "physical", "per_level": 5.0, "flat": 18.0, "color": Color("c8f0a0")},
	Stat.BOTNET: {"interval": 4.0, "range": 350.0, "type": "chaos", "per_level": 2.6, "flat": 9.0, "color": Color("b04ad9")},
	Stat.BLUE_SCREEN: {"interval": 9.0, "range": 170.0, "type": "cold", "per_level": 4.5, "flat": 14.0, "color": Color("4a8ae8")},
	Stat.PAGER_STRIKE: {"interval": 3.0, "range": 450.0, "type": "lightning", "per_level": 3.5, "flat": 12.0, "color": Color("e8d070")},
	Stat.BLUE_GREEN: {"interval": 7.0, "range": 200.0, "type": "fire", "per_level": 3.5, "flat": 12.0, "color": Color("ff9a3a")},
}
const FIRE_WALL_LENGTH := 240.0
const FIRE_WALL_TICK := 0.5
const SPRINT_TIME := 3.0
const SIG_NOVA_RADIUS := 140.0
var _sig_timers := {}
## Muros de fuego en pie: {a, b, life, next, dmg}.
var _fire_walls: Array[Dictionary] = []
## Golpes retrasados (fin del sprint, segunda nova): {time, kind, dmg}.
var _sig_pending: Array[Dictionary] = []


## Daño de una habilidad propia: escala con el nivel y con el daño del personaje de su tipo.
func signature_damage(stat: StringName) -> float:
	var s: Dictionary = SIGNATURES[stat]
	var base := float(s["per_level"]) * character.level + float(s["flat"])
	return base * character.stats.total_multiplier(Stat.DAMAGE_STAT_BY_TYPE[s["type"]])


func _update_signatures(delta: float) -> void:
	_update_fire_walls(delta)
	_update_sig_pending(delta)
	if not player.is_alive():
		return
	for stat: StringName in SIGNATURES:
		if character.stats.get_value(stat) <= 0.0:
			continue
		var s: Dictionary = SIGNATURES[stat]
		var t := float(_sig_timers.get(stat, 0.0)) - delta
		if t <= 0.0 and enemies.nearest_index(player.global_position, s["range"]) != -1:
			t = s["interval"]
			_fire_signature(stat)
		_sig_timers[stat] = maxf(0.0, t)


func _fire_signature(stat: StringName) -> void:
	var s: Dictionary = SIGNATURES[stat]
	var dmg := signature_damage(stat)
	var pos := player.global_position
	var c: Color = s["color"]
	enemies.hit_ailments = {}
	match stat:
		Stat.FIRE_WALL:
			# Perpendicular a la línea hacia el enemigo más cercano, a medio camino.
			var i := enemies.nearest_index(pos, s["range"])
			var to := enemies.positions[i] - pos
			var mid := pos + to * 0.5
			var side := to.orthogonal().normalized() * FIRE_WALL_LENGTH * 0.5
			_fire_walls.append({"a": mid - side, "b": mid + side, "life": 3.0, "next": 0.0, "dmg": dmg})
			Sfx.play("fire", -8.0)
		Stat.SPRINT_DEMO:
			character.add_timed_effect("asc:sprint", [Modifier.new(Stat.MOVEMENT_SPEED, Modifier.Type.INCREASED, 30.0, [], "asc:sprint"),
				Modifier.new(Stat.ATTACK_SPEED, Modifier.Type.INCREASED, 30.0, [], "asc:sprint")] as Array[Modifier], SPRINT_TIME)
			_sig_pending.append({"time": SPRINT_TIME, "kind": "demo", "dmg": dmg})
			_effects.append({"type": "ring", "pos": pos, "radius": 40.0, "time": 0.0, "duration": 0.4, "color": c})
			Sfx.play("buff", -8.0)
		Stat.PROFILED_SHOT:
			var far := -1
			var far_d := 0.0
			for k in enemies.positions.size():
				var d := enemies.positions[k].distance_to(pos)
				if d <= s["range"] and d > far_d:
					far_d = d
					far = k
			var end := pos + (enemies.positions[far] - pos).normalized() * float(s["range"])
			enemies.hit_in_segment(pos, end, 14.0, dmg * 0.9, dmg * 1.1, 30.0, 175.0)
			_effects.append({"type": "beam", "pos": pos, "dir": (end - pos).normalized(), "radius": 8.0, "length": s["range"], "time": 0.0, "duration": 0.3, "color": c})
			Sfx.play("projectile", -6.0)
		Stat.BOTNET:
			var hit := {}
			var from := pos
			for k in 5:
				var i := enemies.nearest_index(from, s["range"] if k == 0 else 220.0, hit)
				if i == -1:
					break
				var to: Vector2 = enemies.positions[i]
				hit[enemies.ids[i]] = true
				_effects.append({"type": "zap", "pos": from, "end": to, "time": 0.0, "duration": 0.25, "color": c})
				enemies.hit_index(i, dmg * 0.9, dmg * 1.1, 5.0, 150.0)
				from = to
			Sfx.play("chaos", -8.0)
		Stat.BLUE_SCREEN:
			enemies.stun_in_radius(pos, s["range"], 1.0)
			enemies.hit_in_radius(pos, s["range"], dmg * 0.9, dmg * 1.1, 5.0, 150.0)
			_effects.append({"type": "lock", "pos": pos, "radius": s["range"], "time": 0.0, "duration": 0.8, "color": c})
			Sfx.play("cold", -6.0)
		Stat.PAGER_STRIKE:
			var near: Array[int] = []
			for k in enemies.positions.size():
				if enemies.positions[k].distance_to(pos) <= s["range"]:
					near.append(k)
			var at: Vector2 = enemies.positions[near.pick_random()]
			enemies.hit_in_radius(at, 60.0, dmg * 0.9, dmg * 1.1, 5.0, 150.0)
			_effects.append({"type": "zap", "pos": at + Vector2(randf_range(-30, 30), -260), "end": at, "time": 0.0, "duration": 0.3, "color": c})
			_effects.append({"type": "ring", "pos": at, "radius": 60.0, "time": 0.0, "duration": 0.3, "color": c})
			Sfx.play("arc", -8.0)
		Stat.BLUE_GREEN:
			enemies.hit_in_radius(pos, SIG_NOVA_RADIUS, dmg * 0.9, dmg * 1.1, 5.0, 150.0)
			_effects.append({"type": "ring", "pos": pos, "radius": SIG_NOVA_RADIUS, "time": 0.0, "duration": 0.35, "color": Color("4a9ae0")})
			var cold_dmg := dmg / character.stats.total_multiplier(Stat.FIRE_DAMAGE) * character.stats.total_multiplier(Stat.COLD_DAMAGE)
			_sig_pending.append({"time": 0.45, "kind": "green", "dmg": cold_dmg})
			Sfx.play("fire", -8.0)


func _update_fire_walls(delta: float) -> void:
	var still: Array[Dictionary] = []
	for w in _fire_walls:
		w["life"] -= delta
		w["next"] -= delta
		if w["next"] <= 0.0:
			w["next"] = FIRE_WALL_TICK
			enemies.hit_ailments = {}
			enemies.hit_in_segment(w["a"], w["b"], 18.0, w["dmg"] * 0.9, w["dmg"] * 1.1, 5.0, 150.0)
		if w["life"] > 0.0:
			still.append(w)
	_fire_walls = still


func _update_sig_pending(delta: float) -> void:
	var still: Array[Dictionary] = []
	for e in _sig_pending:
		e["time"] -= delta
		if e["time"] > 0.0:
			still.append(e)
			continue
		if not player.is_alive():
			continue
		var pos := player.global_position
		enemies.hit_ailments = {}
		enemies.hit_in_radius(pos, SIG_NOVA_RADIUS, e["dmg"] * 0.9, e["dmg"] * 1.1, 5.0, 150.0)
		var c := Color("e8d9b0") if e["kind"] == "demo" else Color("6fd36b")
		_effects.append({"type": "burst", "pos": pos, "radius": SIG_NOVA_RADIUS, "time": 0.0, "duration": 0.35, "color": c})
		_effects.append({"type": "ring", "pos": pos, "radius": SIG_NOVA_RADIUS, "time": 0.0, "duration": 0.4, "color": c})
	_sig_pending = still


func _draw_fire_walls() -> void:
	var t := Time.get_ticks_msec() / 1000.0
	for w in _fire_walls:
		var a: Vector2 = w["a"]
		var b: Vector2 = w["b"]
		var fade := clampf(float(w["life"]) / 0.5, 0.0, 1.0)
		draw_line(a, b, Color(1.0, 0.35, 0.1, 0.35 * fade), 30.0, true)
		for k in 9:
			var p := a.lerp(b, k / 8.0)
			var h := 18.0 + 8.0 * sin(t * 9.0 + k * 1.7)
			draw_colored_polygon(PackedVector2Array([p + Vector2(-8, 0), p + Vector2(0, -h), p + Vector2(8, 0)]), Color(1.0, 0.55 + 0.3 * sin(t * 7.0 + k), 0.15, 0.8 * fade))


## Probabilidad de ganar una carga: la base del tipo más la de los stats.
func _roll_charge(t: String) -> void:
	if randf() * 100.0 < Charges.BASE_CHANCE[t] + character.stats.get_value(Charges.chance_stat(t)):
		if character.gain_charge(t):
			_effects.append({"type": "ring", "pos": player.global_position, "radius": 34.0, "time": 0.0, "duration": 0.3, "color": Charges.color(t)})


var _crit_charge_cd := 0.0


func on_crit() -> void:
	if _crit_charge_cd <= 0.0:
		_crit_charge_cd = 0.25   # un área con 20 críticos no da 20 tiradas
		_roll_charge("overclock")
	if not _triggering:   # los críticos de una habilidad activada no activan nada (sin bucles)
		queue_trigger("on_crit")


# --- RAM de activación (profile.trigger: on_hit, on_crit) ---
# Los eventos se apuntan y se resuelven en el siguiente fotograma: lanzar una
# habilidad en mitad de un golpe tocaría las listas de enemigos mientras se recorren.

var _trigger_cd: Array[float] = []
var _pending_triggers: Array[String] = []
var _triggering := false


func queue_trigger(event: String) -> void:
	if not _pending_triggers.has(event):
		_pending_triggers.append(event)


func _update_triggers(delta: float) -> void:
	if _trigger_cd.size() != ACTIONS.size():
		_trigger_cd.resize(ACTIONS.size())
	for i in _trigger_cd.size():
		_trigger_cd[i] = maxf(0.0, _trigger_cd[i] - delta)
	# Cron Job: cada trigger_cooldown segundos, si hay un enemigo a tiro.
	if player.is_alive() and enemies.nearest_index(player.global_position, TRIGGER_RANGE) != -1:
		for i in ACTIONS.size():
			var tp := profile(i)
			if not tp.is_empty() and String(tp.get("trigger", "")) == "timer" and _trigger_cd[i] <= 0.0:
				fire_triggered(i, tp)
	if _pending_triggers.is_empty():
		return
	var events := _pending_triggers.duplicate()
	_pending_triggers.clear()
	if not player.is_alive():
		return
	for event in events:
		for i in ACTIONS.size():
			var p := profile(i)
			if p.is_empty() or String(p.get("trigger", "")) != event or _trigger_cd[i] > 0.0:
				continue
			fire_triggered(i, p)


## Lanza la habilidad de la ranura `i` por su RAM de activación: paga su maná (y su
## vida, si la cuesta), hacia el enemigo más cercano o hacia donde mira el personaje.
func fire_triggered(i: int, p: Dictionary) -> bool:
	var life_cost := float(p.get("life_cost", 0.0))
	if player.mana < float(p["mana_cost"]) or (life_cost > 0.0 and player.life <= life_cost + 1.0):
		return false
	player.mana -= float(p["mana_cost"])
	player.life -= life_cost
	_trigger_cd[i] = float(p["trigger_cooldown"])
	var near := enemies.nearest_index(player.global_position, TRIGGER_RANGE)
	var target: Vector2 = enemies.positions[near] if near != -1 else player.global_position + player.facing_direction() * 200.0
	var pending_before := _pending.size()
	var shots_before := _projectiles.size()
	_triggering = true
	if String(p["deploy"]) != "":
		_deploy(p, target)
	else:
		_execute(p, target)
	_triggering = false
	# Lo que golpea más tarde (explosiones retardadas, proyectiles) también va marcado.
	for k in range(pending_before, _pending.size()):
		_pending[k]["triggered"] = true
	for k in range(shots_before, _projectiles.size()):
		_projectiles[k]["triggered"] = true
	_effects.append({"type": "ring", "pos": player.global_position, "radius": 28.0, "time": 0.0, "duration": 0.25, "color": TRIGGER_COLOR})
	skill_triggered.emit(i)
	return true


const TRIGGER_RANGE := 600.0
const TRIGGER_COLOR := Color("ffd84a")


## Gasto de cargas (RAM "spend_<tipo>"): devuelve una copia del perfil con el
## bono de las cargas gastadas (más daño, crítico seguro) y cura con las de Buffer.
func _spend_charges(p: Dictionary) -> Dictionary:
	var spend: Dictionary = p.get("spend_charges", {})
	if spend.is_empty():
		return p
	var q := p.duplicate()
	var mult := 1.0
	var mana_per_charge := character.stats.get_value(Stat.CHARGE_SPEND_MANA)
	var spent := []   # los tipos que se gastaron, para la firma de Core Dump (T194)
	q["spent"] = spent
	for t in spend:
		var n := character.spend_charges(t)
		if n <= 0:
			continue
		spent.append(String(t))
		if mana_per_charge > 0.0:
			player.mana = minf(player.max_mana(), player.mana + player.unreserved_mana_max() * mana_per_charge / 100.0 * n)
		match t:
			"buffer":
				player.heal(player.max_life() * 0.06 * n)
				mult *= 1.0 + 0.10 * n
			"multihilo":
				mult *= 1.0 + 0.15 * n
			"overclock":
				if float(q["crit_chance"]) > 0.0:   # Memoria sin ECC: nunca hace críticos
					q["crit_chance"] = 100.0
				q["crit_multiplier"] = float(q["crit_multiplier"]) + 20.0 * n
		# Con firma (Core Dump, T194) las cargas gastadas son sus anillos: el destello queda oculto.
		_effects.append({"type": "burst", "pos": player.global_position, "radius": 40.0 + 12.0 * n, "time": 0.0, "duration": 0.35, "color": Charges.color(t),
			"hidden": String(p["id"]) == "core_dump"})
	q["min_damage"] = float(q["min_damage"]) * mult
	q["max_damage"] = float(q["max_damage"]) * mult
	return q


## Luces de las explosiones y destellos recientes (para WorldPost): {pos, radius, color, power}.
func light_effects() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for e in _effects:
		if e.get("type", "") == "burst" and float(e["radius"]) >= 30.0:
			out.append({"pos": e["pos"], "radius": float(e["radius"]) * 2.2, "color": e["color"],
				"power": 1.0 - float(e["time"]) / maxf(0.01, float(e["duration"]))})
	return out


## Explosiones y novas recién salidas que aún no tienen su ráfaga de partículas
## (BigFx, T98): las «burst» grandes. El diccionario es el del efecto (BigFx lo marca).
func burst_effects() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for e in _effects:
		if e.get("type", "") == "burst" and float(e["radius"]) >= 40.0 and not e.get("big_fx", false):
			out.append(e)
	return out


## Cuánto más abajo cae la sombra de un proyectil (como si volara a esa altura).
const PROJECTILE_SHADOW_DROP := 16.0


## Luz propia de los aliados (WorldPost): cada aura alrededor de su centro y las
## invocaciones persistentes, los esbirros y los drones, cada uno de su color.
## {pos, radius, color, power}.
func light_allies() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	var t := Time.get_ticks_msec() / 1000.0
	for a in _auras:
		var c := SkillFx.aura_tint(String(a["skill_id"]), Accessibility.aura_color(String(a["profile"].get("damage_type", "")), a["color"]))
		out.append({"pos": aura_center(a), "radius": maxf(140.0, float(a["profile"].get("aura_radius", 0.0)) * 0.6), "color": c, "power": 0.35 + 0.05 * sin(t * 2.0)})
	for u in _units:
		out.append({"pos": u["pos"], "radius": 70.0 + float(u["radius"]) * 2.0, "color": u["color"], "power": 0.5})
	for m in _minions:
		out.append({"pos": m["pos"], "radius": 60.0, "color": m["color"], "power": 0.4})
	for d in _drones:
		out.append({"pos": _drone_pos(d), "radius": 60.0, "color": d["color"], "power": 0.45})
	return out


## Proyectiles que alumbran (fuego, rayo, frío y caos): {pos, color}.
func light_projectiles() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for pr in _projectiles:
		var dt := String(pr["profile"].get("damage_type", ""))
		if WorldPost.PROJECTILE_LIGHT.has(dt):
			out.append({"pos": pr["pos"], "color": WorldPost.PROJECTILE_LIGHT[dt]})
	return out


## Cura a las invocaciones persistentes y a las torretas una fracción de su vida
## máxima (poción "Termo de café para el equipo").
const SHOUT_COLOR := Color("e08a50")


## Grito (potenciador con etiqueta warcry): sus mods ya llegan a las invocaciones
## por las stats (daño y vida de esbirros, velocidad de autómatas); aquí se ve la
## onda, destella cada aliado y, si la habilidad cura (heal_allies), los cura.
func _shout(p: Dictionary, origin: Vector2, device := false) -> void:
	# Con firma (T195) cada grito tiene su onda, su texto y lo que lleva cada invocación.
	var firma := SkillFx.has_fx(String(p["id"]))
	if firma:
		_buff_fx(p, origin, device)
	else:
		_effects.append({"type": "ring", "pos": origin, "radius": 170.0, "time": 0.0, "duration": 0.5, "color": SHOUT_COLOR})
		_effects.append({"type": "ring", "pos": origin, "radius": 90.0, "time": 0.0, "duration": 0.35, "color": SHOUT_COLOR})
		for group in [_units, _minions, _devices]:
			for a in group:
				if a.has("pos"):
					_effects.append({"type": "ring", "pos": a["pos"], "radius": 24.0, "time": 0.0, "duration": 0.45, "color": SHOUT_COLOR})
	if float(p.get("heal_allies", 0.0)) > 0.0:
		heal_units(float(p["heal_allies"]), not firma)


## `rings`: el anillo verde de cada curado (sin él con ¡Rollback!, que suelta sus «+»).
func heal_units(fraction: float, rings := true) -> void:
	for u in _units:
		u["life"] = minf(u["max_life"], u["life"] + u["max_life"] * fraction)
		if rings:
			_effects.append({"type": "ring", "pos": u["pos"], "radius": 30.0, "time": 0.0, "duration": 0.4, "color": Color("6fd36b")})
	for d in _devices:
		var hp: Dictionary = d.get("ally", {})
		if not hp.is_empty():
			hp["life"] = minf(float(hp["max_life"]), float(hp["life"]) + float(hp["max_life"]) * fraction)
	if not _units.is_empty():
		Sfx.play("heal", -8.0)


## Lo llama World al morir un enemigo.
func on_enemy_killed(pos: Vector2) -> void:
	_roll_charge("multihilo")
	if not _triggering:   # lo que mata una habilidad activada no activa nada (sin bucles)
		queue_trigger("on_kill")
	var gc := character.stats.get_value(Stat.GARBAGE_COLLECTOR)
	if gc > 0.0 and player.is_alive():
		# Recolector de Basura: el maná vuelve al matar (no se regenera solo).
		player.mana = minf(player.max_mana(), player.mana + player.unreserved_mana_max() * gc / 100.0)
	var chance := character.stats.get_value(Stat.KILL_EXPLOSION)
	if chance > 0.0 and randf() * 100.0 < chance and _pending_explosions.size() < 8:
		_pending_explosions.append(pos)


## Lo llama el jugador al recibir un golpe (Player.hit_taken).
func on_player_hit() -> void:
	_roll_charge("buffer")
	queue_trigger("on_hit")
	_buff_fx_hit()
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


## "git stash pop": explosiones que dejan las esquivas, {pos, time} (estallan al llegar a 0).
const STASH_POP_DELAY := 0.45
const STASH_POP_RADIUS := 100.0
var _stash_pops: Array[Dictionary] = []


## Qué dispara una RAM de activación, en texto ("" si la habilidad no tiene ninguna).
static func trigger_text(p: Dictionary) -> String:
	var cd := float(p.get("trigger_cooldown", 0.0))
	match String(p.get("trigger", "")):
		"on_hit": return "al recibir un golpe (cada %.1f s como mucho)" % cd
		"on_crit": return "con los críticos de tus otras habilidades (cada %.1f s como mucho)" % cd
		"timer": return "cada %.1f s si hay un enemigo cerca" % cd
		"on_dodge": return "al esquivar (cada %.1f s como mucho)" % cd
		"on_kill": return "al matar con otra habilidad (cada %.1f s como mucho)" % cd
	return ""


## Lo llama el jugador al esquivar (Player.dodged), aún en el punto de partida:
## cargas de Multihilos seguras (Stat.DODGE_MULTIHILO) y la explosión que se
## queda atrás (Stat.DODGE_BLAST).
func on_player_dodged() -> void:
	queue_trigger("on_dodge")
	for k in int(character.stats.get_value(Stat.DODGE_MULTIHILO)):
		if character.gain_charge("multihilo"):
			_effects.append({"type": "ring", "pos": player.global_position, "radius": 34.0, "time": 0.0, "duration": 0.3, "color": Charges.color("multihilo")})
	if character.stats.get_value(Stat.DODGE_BLAST) > 0.0:
		_stash_pops.append({"pos": player.global_position, "time": STASH_POP_DELAY})
		_effects.append({"type": "marker", "pos": player.global_position, "radius": STASH_POP_RADIUS, "time": 0.0, "duration": STASH_POP_DELAY, "color": Color("ff9a3a")})


func _update_stash_pops(delta: float) -> void:
	if _stash_pops.is_empty():
		return
	var still: Array[Dictionary] = []
	for s in _stash_pops:
		s["time"] -= delta
		if s["time"] > 0.0:
			still.append(s)
			continue
		var dmg := player.max_life() * character.stats.get_value(Stat.DODGE_BLAST) / 100.0
		enemies.hit_ailments = {}
		enemies.hit_in_radius(s["pos"], STASH_POP_RADIUS, dmg * 0.9, dmg * 1.1, 5.0, 150.0)
		Sfx.play("mine", -6.0, randf_range(0.95, 1.05))
		_effects.append({"type": "burst", "pos": s["pos"], "radius": STASH_POP_RADIUS, "time": 0.0, "duration": 0.35, "color": Color("ff9a3a")})
		_effects.append({"type": "ring", "pos": s["pos"], "radius": STASH_POP_RADIUS, "time": 0.0, "duration": 0.4, "color": Color("ffd060")})
	_stash_pops = still


func _update_ascendancy_procs(delta: float) -> void:
	_nova_cooldown = maxf(0.0, _nova_cooldown - delta)
	_crit_charge_cd = maxf(0.0, _crit_charge_cd - delta)
	_update_stash_pops(delta)
	_update_signatures(delta)
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
	enemies.cold_cache = character.stats.get_value(Stat.COLD_CACHE) > 0.0
	_mana_warning_cooldown = maxf(0.0, _mana_warning_cooldown - delta)
	_busy = maxf(0.0, _busy - delta)
	# En escenas (enemigos congelados, jugador bloqueado) nada ataca: ni aliados,
	# ni torretas, ni proyectiles en vuelo. Solo se apagan los efectos visuales.
	if enemies.frozen or player.controls_locked:
		_channel = {}
		_update_effects(delta)
		queue_redraw()
		return
	if not _channel.is_empty():
		_update_channel(delta, Input.is_action_pressed(ACTIONS[int(_channel["index"])]), _aim_target())
	if player.is_alive() and _busy <= 0.0 and not player.controls_locked and not player.is_frozen() and not Gamepad.menu_cursor and not UiStyle.typing():
		var used := false
		for i in ACTIONS.size():
			if i == 0 and Gamepad.skill_1_blocked():
				continue   # A se usó para recoger o hablar (mando)
			if Input.is_action_pressed(ACTIONS[i]) and try_use(i):
				used = true
				break
		if not used and ((auto_attack and not player.manual_moving()) or touch_auto_on()):
			_try_auto_attack()
	_update_aura_fields()
	character.set_condition(Stat.COND_ALLIES, _units.size() + _minions.size() + _drones.size() >= 3)
	_update_triggers(delta)
	_update_pending(delta)
	_update_projectiles(delta)
	_update_spin(delta)
	_update_traps(delta)
	_update_devices(delta)
	_update_minions(delta)
	_update_units(delta)
	_sync_golem_buffs()
	_update_rains(delta)
	_update_clouds(delta)
	_update_terrains(delta)
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
	# Se conservan el tipo de daño (resistencias) y el bono contra enemigos con estados.
	var out := ctx.duplicate()
	out["chances"] = scaled
	enemies.hit_ailments = out


func try_use(index: int) -> bool:
	var p := profile(index)
	if p.is_empty() or cooldowns[index] > 0.0:
		return false
	if String(p.get("trigger", "")) != "":
		if _mana_warning_cooldown <= 0.0:
			_mana_warning_cooldown = 1.5
			trigger_only.emit(String(p["name"]))
		return false   # RAM de activación: se lanza sola
	if p["kind"] in CHANNEL_KINDS:
		# Canalizada: empieza aquí y cobra su maná por segundo mientras se mantenga.
		if player.mana < float(p["mana_cost"]) * 0.25:
			if _mana_warning_cooldown <= 0.0:
				_mana_warning_cooldown = 1.5
				not_enough_mana.emit()
			return false
		_start_channel(index, p, _aim_target())
		SoundMap.play_cast(p)
		skill_used.emit(index)
		return true
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
	if p["deploy"] == "container" and not _has_container(p["id"]) and player.mana_reserved + float(p["reserve"]) / 100.0 > 0.95 + 0.0001:
		if _mana_warning_cooldown <= 0.0:
			_mana_warning_cooldown = 1.5
			reservation_full.emit(String(p["name"]))
		return false
	if p["kind"] == "unit" and not _can_summon(p):
		if _mana_warning_cooldown <= 0.0:
			_mana_warning_cooldown = 1.5
			reservation_full.emit(String(p["name"]))
		return false
	# Costo en vida (RAM de alimentación por vida): nunca te mata, pero no alcanza si no te sobra.
	var life_cost := float(p.get("life_cost", 0.0))
	if life_cost > 0.0 and player.life <= life_cost + 1.0:
		if _mana_warning_cooldown <= 0.0:
			_mana_warning_cooldown = 1.5
			not_enough_life.emit()
		return false
	player.mana -= p["mana_cost"]
	if life_cost > 0.0:
		player.life -= life_cost
	p = _spend_charges(p)
	cooldowns[index] = p["cooldown"]
	_busy = p["use_time"]
	player.action_lock = minf(MAX_MOVE_LOCK, p["use_time"] * MOVE_LOCK_FRACTION)
	var target := _aim_target()
	player.face(target - player.global_position)
	player.play_action(Player.action_for(p), float(p["use_time"]), Player.DOT_COLORS.get(String(p["damage_type"]), Color("c8d8ff")))
	if not (p["kind"] in SkillCalc.AUTOMATON_KINDS or p["kind"] == "aura"):
		_cast_fx(p, target)
	if p["kind"] != "aura":   # el aura suena al encenderse o apagarse (_toggle_aura), no dos veces
		SoundMap.play_cast(p)   # su tipo + su capa de firma, con su tono (T77)
	if p["deploy"] != "":
		_deploy(p, target)
		skill_used.emit(index)
		return true
	# Los ataques golpean en el cuadro de impacto de la animación, no al pulsar (T72b).
	var impact := impact_delay(p, CharacterAppearance.weapon_kind(player.character.inventory.equipped("weapon")) if player.character else "")
	if impact > 0.0:
		_pending.append({"type": "impact", "time": impact, "profile": p, "target": target})
	else:
		_execute(p, target)
	if p["kind"] in SkillCalc.AUTOMATON_KINDS or p["kind"] == "aura":
		skill_used.emit(index)
		return true   # en invocaciones la repetición ya va en su ritmo de ataque
	for r in int(p["repeats"]):
		_pending.append({"type": "repeat", "time": impact + REPEAT_DELAY * (r + 1), "profile": p, "target": target})
	skill_used.emit(index)
	return true


## Tope del retraso hasta el golpe: con ataques muy lentos, que no parezca que no responde.
const IMPACT_MAX := 0.3


## Segundos desde que se pulsa hasta que el ataque golpea (el cuadro de impacto de la
## animación del jugador); 0 = sale al instante (hechizos, movimiento, invocaciones,
## trampas y RAM de activación).
static func impact_delay(p: Dictionary, weapon: String) -> float:
	var tags: Array = p.get("tags", [])
	if not ("attack" in tags) or "movement" in tags or "minion" in tags or "automaton" in tags \
			or String(p.get("deploy", "")) != "" or String(p.get("trigger", "")) != "":
		return 0.0
	return minf(IMPACT_MAX, float(p.get("use_time", 0.0)) * CharacterAppearance.impact_fraction(Player.action_for(p), weapon))


## Auto-ataque (Pausa → Combate): sin pulsar nada ni moverte, la habilidad 1 sale
## sola contra el enemigo más cercano a AUTO_ATTACK_RANGE.
const AUTO_ATTACK_RANGE := 320.0
static var auto_attack := bool(GameSettings.get_value("combat", "auto_attack", false))
## Mientras se lanza el auto-ataque, se apunta aquí (no al ratón).
var _auto_aim := Vector2.INF


## Habilidades que el auto-ataque puede lanzar: las de golpe directo (no auras,
## invocaciones, canalizadas, contenedores ni las de activación).
static func auto_attack_ok(p: Dictionary) -> bool:
	if p.is_empty() or String(p.get("trigger", "")) != "" or String(p.get("deploy", "")) == "container":
		return false
	return not (String(p.get("kind", "")) in ["aura", "unit"] or String(p.get("kind", "")) in CHANNEL_KINDS)


## Modo automático del celular (T151, el interruptor «AUTO» junto al botón grande): la
## habilidad 1 sale sola contra lo que hay cerca también mientras te mueves con el
## joystick; el resto, a mano. En pausa mientras haya una ventana encima.
static var touch_auto := false


static func touch_auto_on() -> bool:
	return touch_auto and Touch.shown() and not Touch.ui_busy


func _try_auto_attack() -> void:
	if not auto_attack_ok(profile(0)):
		return
	var i := enemies.nearest_index(player.global_position, AUTO_ATTACK_RANGE)
	if touch_auto_on():   # al objetivo de la mira (pegajoso o fijado, T150) si está a tiro
		var t := Touch.pick_target(enemies.ids, enemies.positions, player.global_position, Touch.stick)
		if t != -1 and enemies.positions[t].distance_to(player.global_position) <= AUTO_ATTACK_RANGE:
			i = t
	if i == -1:
		return
	_auto_aim = enemies.positions[i]
	try_use(0)
	_auto_aim = Vector2.INF


## Dónde se lanza la habilidad: el ratón; con mando, el stick derecho o, si está
## suelto, el enemigo más cercano (o hacia donde mira el personaje).
func _aim_target() -> Vector2:
	if _auto_aim != Vector2.INF:
		return _auto_aim
	if Touch.active and Touch.aim_dir != Vector2.ZERO:
		return Touch.manual_target(player.global_position, Touch.aim_dir)   # arrastrando desde el botón
	if Touch.active:
		# Con el pulgar: al de antes si sigue a tiro (T150), si no al del joystick o al más
		# cercano (lo marca TouchControls).
		var t := Touch.pick_target(enemies.ids, enemies.positions, player.global_position, Touch.stick)
		return enemies.positions[t] if t != -1 else player.global_position + player.facing_direction().normalized() * Gamepad.AIM_DISTANCE
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


## Los contenedores siguen a su placa, como las invocaciones: se van si deja de
## ser contenedor (o sale de la barra) y toman sus cifras nuevas si cambian.
func _refresh_containers() -> void:
	if not _devices.any(func(d: Dictionary) -> bool: return d["kind"] == "container"):
		return
	var by_id := {}
	for p in _profiles:
		if not p.is_empty() and p["deploy"] == "container":
			by_id[p["id"]] = p
	var keep: Array[Dictionary] = []
	for d in _devices:
		if d["kind"] == "container":
			var p: Dictionary = by_id.get(d["profile"]["id"], {})
			if p.is_empty():
				continue
			var inner := p.duplicate()
			inner["deploy"] = ""
			d["profile"] = inner
			d["interval"] = _device_interval(p)
		keep.append(d)
	_devices = keep
	_update_reservation()


func _has_container(skill_id: String) -> bool:
	return _devices.any(func(d: Dictionary) -> bool: return d["kind"] == "container" and d["profile"]["id"] == skill_id)


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
	var device_names := {"trap": "Trampas", "mine": "Minas", "totem": "Torreta", "container": "Contenedor"}
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
	# Firma propia de cuerpo a cuerpo y movimiento (T193) o de hechizo (T194): en vez del
	# anillo, la estela, el cono, el salto, el rayo, el marcador o el zigzag genéricos de su kind.
	var firma := SkillFx.has_fx(String(p["id"]))
	match p["kind"]:
		"leap_slam":
			# Salto: se mueve con colisión (no atraviesa paredes) y golpea al caer.
			var land := origin + (target - origin).limit_length(p["range"])
			if not device:
				player.move_and_collide(land - origin)
				player.stop_auto_move()
				land = player.global_position
			if firma:
				_move_fx(p, origin, land, dir, color)
				if not device and not Accessibility.reduce_motion:
					player.camera_shake(3.0, 0.15)
			else:
				_effects.append({"type": "leap", "pos": origin, "end": land, "time": 0.0, "duration": 0.3, "color": color})
			if p["stun"] > 0.0:
				enemies.stun_in_radius(land, p["radius"], p["stun"])
			_damage_area(land, p["radius"], p)
			if not firma:
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
				if not firma:
					_effects.append({"type": "lock", "pos": origin, "radius": p["radius"], "time": 0.0, "duration": 0.6, "color": color})
			if firma:
				_move_fx(p, origin, origin, dir, color, _marks_in_radius(origin, p["radius"]), _nova_extra(p))
			_damage_area(origin, p["radius"], p)
			if not firma:
				_effects.append({"type": "ring", "pos": origin, "radius": p["radius"], "time": 0.0, "duration": 0.25, "color": color})
		"dash":
			# Embestida: se mueve con colisión (no atraviesa paredes) y golpea lo que hay en la línea.
			var offset := (target - origin).limit_length(p["range"])
			var end := origin + offset
			if not device:
				player.move_and_collide(offset)
				player.stop_auto_move()
				end = player.global_position
			if firma:
				_move_fx(p, origin, end, dir, color, _marks_in_segment(origin, end, p["width"] * 0.5))
			enemies.hit_in_segment(origin, end, p["width"] * 0.5, p["min_damage"], p["max_damage"], p["crit_chance"], p["crit_multiplier"])
			_leech(p)
			if not firma:
				_effects.append({"type": "trail", "pos": origin, "end": end, "radius": p["width"], "time": 0.0, "duration": 0.3, "color": color})
		"cone":
			var half := deg_to_rad(p["angle"]) / 2.0
			if firma:
				var ctx: Dictionary = p.get("ailment_ctx", {})
				_move_fx(p, origin, origin, dir, color, _marks_in_cone(origin, dir, p["radius"], half),
					{"half": half, "bleed": float(ctx.get("chances", {}).get(Ailments.BLEED, 0.0)) / 100.0})
			enemies.hit_in_cone(origin, dir, p["radius"], half, p["min_damage"], p["max_damage"], p["crit_chance"], p["crit_multiplier"])
			_leech(p)
			if not firma:
				_effects.append({"type": "cone", "pos": origin, "dir": dir, "radius": p["radius"], "half": half, "time": 0.0, "duration": 0.35, "color": color})
		"beam":
			_pending.append({"type": "beam", "time": p["delay"], "pos": origin, "dir": dir, "profile": p, "color": color, "firma": firma})
			if firma:
				_move_fx(p, origin, origin + dir * float(p["range"]), dir, color, PackedVector2Array(),
					{"radius": float(p["width"]), "length": float(p["range"]), "duration": float(p["delay"])})
			else:
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
			if firma:
				_buff_fx(p, origin, device)
			else:
				_effects.append({"type": "ring", "pos": origin, "radius": 60.0, "time": 0.0, "duration": 0.5, "color": Color("cfe8ff")})
		"buff":
			if not device:
				var mods: Array[Modifier] = []
				for md in p["buff_mods"]:
					mods.append(Modifier.from_dict(md, "skill:" + String(p["id"])))
				character.add_timed_effect("skill:" + String(p["id"]), mods, p["duration"])
			if p["tags"].has(&"warcry"):
				_shout(p, origin, device)
			elif firma:
				_buff_fx(p, origin, device)
			else:
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
			# Con su firma (T194), la gota que cae y un charco de celdas de memoria que crece.
			_clouds.append({"pos": origin + offset, "life": p["duration"], "next": 0.0, "profile": p, "color": color, "seed": randi(),
				"leak": firma, "mb": PackedVector2Array(), "mb_age": 0.5})
			if firma:
				_move_fx(p, origin, origin + offset, dir, color)
		"trap":
			var offset := (target - origin).limit_length(p["range"])
			_traps.append({"pos": origin + offset, "armed_in": 0.5, "life": p["duration"], "profile": p, "color": color})
			while _traps.size() > maxi(1, p["max_active"]) + int(p.get("extra_devices", 0)):
				_traps.pop_front()
		"chain":
			_chain(p, origin, target, color)
		"projectile":
			if firma:
				_move_fx(p, origin, origin, dir, color)
			_fire_volley(p, origin, dir, color)
		"ground_aoe":
			var offset := (target - origin).limit_length(p["range"])
			_pending.append({"type": "blast", "time": p["delay"], "pos": origin + offset, "profile": p, "color": color, "firma": firma})
			if firma:
				_move_fx(p, origin + offset, origin + offset, dir, color, PackedVector2Array(),
					{"delay": float(p["delay"]), "duration": float(p["delay"]) + 0.5})
			else:
				_effects.append({"type": "marker", "pos": origin + offset, "radius": p["radius"], "time": 0.0, "duration": p["delay"], "color": color})
		"blink":
			if device:
				return
			var offset := (target - origin).limit_length(p["range"])
			if not firma:
				_effects.append({"type": "ring", "pos": origin, "radius": 30.0, "time": 0.0, "duration": 0.3, "color": color})
			player.global_position = _landing(origin + offset)
			player.stop_auto_move()
			if firma:
				_move_fx(p, origin, player.global_position, dir, color)
			else:
				_effects.append({"type": "ring", "pos": player.global_position, "radius": 40.0, "time": 0.0, "duration": 0.3, "color": color})
		"terrain":
			# Terreno: aceite, estática o refrigerante en el suelo (ver _update_terrains).
			var offset := (target - origin).limit_length(p["range"])
			_terrains.append({"pos": origin + offset, "radius": float(p["radius"]), "terrain": String(p["def"].get("terrain", "oil")),
				"life": float(p["duration"]), "next": 0.0, "profile": p, "color": color, "seed": randi()})
			while _terrains.size() > MAX_TERRAINS:
				_terrains.pop_front()
			_effects.append({"type": "ring", "pos": origin + offset, "radius": p["radius"], "time": 0.0, "duration": 0.3, "color": color})
		"ssh":
			# Túnel SSH: teletransporte corto con una descarga al salir y otra al llegar.
			if device:
				return
			var dest := _landing(origin + (target - origin).limit_length(p["range"]))
			_ssh_burst(origin, p, color, not firma)
			player.global_position = dest
			player.stop_auto_move()
			_ssh_burst(dest, p, color, not firma)
			if firma:
				_move_fx(p, origin, dest, dir, color)
			else:
				_effects.append({"type": "zap", "pos": origin, "end": dest, "time": 0.0, "duration": 0.25, "color": color})
		"charge":
			# Force Push: carga hasta el primer enemigo en el cono hacia el cursor, lo
			# arrolla con los de alrededor, los empuja lejos y los aturde un momento.
			if device:
				return
			var hit_at := origin + dir * float(p["range"])
			var first := _first_enemy_in_cone(origin, dir, float(p["range"]), deg_to_rad(float(p["angle"])) / 2.0)
			if first != -1:
				var to := enemies.positions[first] - origin
				hit_at = origin + to - to.normalized() * minf(to.length(), enemies.radii[first] + 18.0)
			player.move_and_collide(hit_at - origin)
			player.stop_auto_move()
			var end := player.global_position
			if firma:
				_move_fx(p, origin, end, dir, color, _marks_in_radius(end, p["radius"] + 20.0) if first != -1 else PackedVector2Array(),
					{"hit": first != -1})
			else:
				_effects.append({"type": "trail", "pos": origin, "end": end, "radius": 40.0, "time": 0.0, "duration": 0.3, "color": color})
			if first != -1:
				_damage_area(end, p["radius"], p)
				enemies.push_in_radius(end, p["radius"] + 20.0, float(p["def"].get("push", 2.0)))
				if p["stun"] > 0.0:
					enemies.stun_in_radius(end, p["radius"], p["stun"])
				if not firma:
					_effects.append({"type": "quake", "pos": end, "radius": p["radius"], "time": 0.0, "duration": 0.35, "color": color})
		"backflip":
			# Git Revert: salto hacia atrás (lejos del cursor) que deja una zona helada.
			if device:
				return
			# Con su firma (T193), la zona es un diff con el fantasma de donde estabas.
			_clouds.append({"pos": origin, "life": p["duration"], "next": 0.0, "profile": p, "color": color, "seed": randi(),
				"revert": firma, "err": Accessibility.aura_color("fire", Color("d9534f"))})
			player.move_and_collide(-dir * float(p["range"]))
			player.stop_auto_move()
			if firma:
				_move_fx(p, origin, player.global_position, dir, color)
			else:
				_effects.append({"type": "leap", "pos": origin, "end": player.global_position, "time": 0.0, "duration": 0.25, "color": color})


## Dónde cae un teletransporte: el punto libre más cercano (sin paredes ni obstáculos).
func _landing(pos: Vector2) -> Vector2:
	return spot_fixer.call(pos) if spot_fixer.is_valid() else pos


func _ssh_burst(pos: Vector2, p: Dictionary, color: Color, ring := true) -> void:
	_damage_area(pos, p["radius"], p)
	if ring:
		_effects.append({"type": "ring", "pos": pos, "radius": p["radius"], "time": 0.0, "duration": 0.3, "color": color})


## Firma de cuerpo a cuerpo o movimiento (T193, SkillFx.move_fx). El color del daño, el
## verde y el rojo pasan por el modo daltónico como las auras.
func _move_fx(p: Dictionary, from: Vector2, to: Vector2, dir: Vector2, color: Color, marks := PackedVector2Array(), extra := {}) -> void:
	var dtype := String(p.get("damage_type", "physical"))
	var e := SkillFx.move_fx(String(p["id"]), from, to, dir, float(p.get("radius", 0.0)), Accessibility.aura_color(dtype, color), marks, extra)
	e["ok"] = Accessibility.aura_color("none", e["ok"])
	e["err"] = Accessibility.aura_color("fire", e["err"])
	_effects.append(e)


## Lo propio de cada nova con firma (T194): cuánto dura el aturdimiento de Deadlock y los
## anillos de Core Dump (uno del color de cada tipo de carga gastado; crítico con Overclock).
func _nova_extra(p: Dictionary) -> Dictionary:
	match String(p["id"]):
		"deadlock":
			var stun := float(p["stun"])
			return {"stun": stun, "duration": maxf(0.65, stun + 0.15)}
		"core_dump":
			var spent: Array = p.get("spent", [])
			var rings := []
			for t in spent:
				rings.append(Charges.color(t))
			# Con Memoria sin ECC el Overclock no da críticos: sin destello.
			return {"rings": rings, "crit": spent.has("overclock") and float(p["crit_chance"]) >= 100.0}
	return {}


## Dónde están (hasta SkillFx.MAX_MARKS) los enemigos que va a golpear una firma, para
## sus marcas; se mira antes del golpe, así cuentan también los que mueren. Con muchos
## enemigos en pantalla (versión ligera) no hay marcas y no se busca nada.
func _marks_in_radius(center: Vector2, radius: float) -> PackedVector2Array:
	var out := PackedVector2Array()
	if fx_light():
		return out
	for i in enemies.positions.size():
		if enemies.positions[i].distance_to(center) <= radius + enemies.radii[i]:
			out.append(enemies.positions[i])
			if out.size() >= SkillFx.MAX_MARKS:
				break
	return out


func _marks_in_cone(origin: Vector2, dir: Vector2, radius: float, half: float) -> PackedVector2Array:
	var out := PackedVector2Array()
	if fx_light():
		return out
	for i in enemies.positions.size():
		var to := enemies.positions[i] - origin
		if to.length() <= radius + enemies.radii[i] and (to.length() < enemies.radii[i] or absf(dir.angle_to(to)) <= half):
			out.append(enemies.positions[i])
			if out.size() >= SkillFx.MAX_MARKS:
				break
	return out


func _marks_in_segment(a: Vector2, b: Vector2, half_width: float) -> PackedVector2Array:
	var out := PackedVector2Array()
	if fx_light():
		return out
	for i in enemies.positions.size():
		if Geometry2D.get_closest_point_to_segment(enemies.positions[i], a, b).distance_to(enemies.positions[i]) <= half_width + enemies.radii[i]:
			out.append(enemies.positions[i])
			if out.size() >= SkillFx.MAX_MARKS:
				break
	return out


## Primer enemigo (el más cercano) dentro de un cono de semiángulo `half` hacia `dir`; -1 si no hay.
func _first_enemy_in_cone(origin: Vector2, dir: Vector2, reach: float, half: float) -> int:
	var best := -1
	var best_d := reach
	for i in enemies.positions.size():
		var to := enemies.positions[i] - origin
		var d := to.length()
		if d < best_d and d > 0.0 and absf(dir.angle_to(to)) <= half:
			best = i
			best_d = d
	return best


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
			# Código Espagueti: rebotes al azar tras golpear (sin gastar perforación).
			"ricochets_left": int(character.stats.get_value(Stat.SPAGHETTI_CODE)) if character else 0,
			"fx": SkillFx.signature(p), "trail_t": 0.0, "phase": randf() * 10.0,
		}
		pr.merge(extra, true)
		_projectiles.append(pr)


## Cadena: el enemigo más cercano al cursor (a tiro) y luego salta al más cercano no golpeado.
func _chain(p: Dictionary, origin: Vector2, target: Vector2, color: Color) -> void:
	# Con su firma (T194), un solo efecto con todos los saltos en vez de un zigzag por salto.
	var firma := SkillFx.has_fx(String(p["id"]))
	var hops := PackedVector2Array([origin])
	var first := enemies.nearest_index(target, 160.0)
	if first == -1 or enemies.positions[first].distance_to(origin) > p["range"]:
		first = enemies.nearest_index(origin, p["range"])
	if first == -1:
		var miss := origin + (target - origin).limit_length(p["range"])
		if firma:
			hops.append(miss)
			_move_fx(p, origin, miss, (miss - origin).normalized(), color, PackedVector2Array(), {"hops": hops, "miss": true})
		else:
			_effects.append({"type": "zap", "pos": origin, "end": miss, "time": 0.0, "duration": 0.2, "color": color})
		return
	var hit := {}
	var from := origin
	var i := first
	for k in int(p["chains"]) + 1:
		var at := enemies.positions[i]
		if firma:
			hops.append(at)
		else:
			_effects.append({"type": "zap", "pos": from, "end": at, "time": -0.06 * k, "duration": 0.3, "color": color})
		var scale := pow(float(p["chain_damage"]), k)
		hit[enemies.hit_index(i, p["min_damage"] * scale, p["max_damage"] * scale, p["crit_chance"], p["crit_multiplier"])] = true
		_leech(p)
		from = at
		i = enemies.nearest_index(at, p["chain_range"], hit)
		if i == -1:
			break
	if firma:
		_move_fx(p, origin, hops[hops.size() - 1], (hops[1] - origin).normalized(), color, PackedVector2Array(),
			{"hops": hops, "duration": 0.06 * (hops.size() - 2) + 0.52})


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


# --- Hechizos canalizados (mantener pulsado) ---

const CHANNEL_KINDS := ["channel_beam", "channel_storm"]
## Segundos de canalización hasta que la tormenta llega a su tamaño y daño máximos.
const CHANNEL_RAMP := 3.0
## Velocidad (px/s) a la que la tormenta sigue al cursor.
const STORM_FOLLOW := 170.0
## Canalización en curso: {index, profile, time, next_tick, aim, center, color}; vacío si no hay.
var _channel: Dictionary = {}


func is_channeling() -> bool:
	return not _channel.is_empty()


func _start_channel(index: int, p: Dictionary, target: Vector2) -> void:
	var origin := player.global_position
	_channel = {"index": index, "profile": p, "time": 0.0, "next_tick": 0.0, "aim": target,
		"center": origin + (target - origin).limit_length(p["range"]),
		"color": DAMAGE_COLORS.get(p["damage_type"], Color.WHITE)}


## De 0 a 1 en CHANNEL_RAMP segundos: la tormenta pasa de ×0,5 a ×1,5 de radio y de ×1 a ×2 de daño.
static func channel_ramp(time: float) -> float:
	return clampf(time / CHANNEL_RAMP, 0.0, 1.0)


## Un golpe por cada uso de la habilidad: su daño por segundo es el de lanzarla a ese ritmo.
static func channel_tick(p: Dictionary) -> float:
	return maxf(0.1, float(p["use_time"]))


static func storm_radius(p: Dictionary, time: float) -> float:
	return float(p["radius"]) * (0.5 + channel_ramp(time))


## Mientras se mantenga la tecla (o el botón del mando) y quede maná: cobra su
## costo por segundo, no deja moverse ni lanzar otra cosa y golpea en cada tick.
func _update_channel(delta: float, held: bool, target: Vector2) -> void:
	if _channel.is_empty():
		return
	var p: Dictionary = _channel["profile"]
	var cost := float(p["mana_cost"]) * delta
	var life_cost := float(p.get("life_cost", 0.0)) * delta
	if not held or not player.is_alive() or player.is_frozen() or player.controls_locked or player.mana < cost \
			or (life_cost > 0.0 and player.life <= life_cost + 1.0):
		_channel = {}
		return
	player.mana -= cost
	player.life -= life_cost
	_channel["time"] += delta
	_channel["aim"] = target
	_busy = maxf(_busy, 0.05)
	player.action_lock = maxf(player.action_lock, 0.05)
	var origin := player.global_position
	player.face(target - origin)
	player.keep_channeling(Player.DOT_COLORS.get(String(p["damage_type"]), Color("c8d8ff")))
	if p["kind"] == "channel_storm":
		var want := origin + (target - origin).limit_length(p["range"])
		_channel["center"] = (_channel["center"] as Vector2).move_toward(want, STORM_FOLLOW * delta)
	_channel["next_tick"] -= delta
	if _channel["next_tick"] > 0.0:
		return
	_channel["next_tick"] = channel_tick(p)
	_ctx(p)
	if p["kind"] == "channel_beam":
		var end := origin + (target - origin).normalized() * float(p["range"])
		enemies.hit_in_segment(origin, end, p["width"] * 0.5, p["min_damage"], p["max_damage"], p["crit_chance"], p["crit_multiplier"])
	else:
		var mult := 1.0 + channel_ramp(_channel["time"])
		enemies.hit_in_radius(_channel["center"], storm_radius(p, _channel["time"]), p["min_damage"] * mult, p["max_damage"] * mult,
			p["crit_chance"], p["crit_multiplier"])
	_leech(p)


func _draw_channel() -> void:
	if _channel.is_empty():
		return
	var p: Dictionary = _channel["profile"]
	var c: Color = _channel["color"]
	var t := Time.get_ticks_msec() / 1000.0
	var origin := player.global_position
	if p["kind"] == "channel_beam":
		# Rayo continuo: halo que vibra, núcleo y un hilo blanco.
		var end := origin + ((_channel["aim"] as Vector2) - origin).normalized() * float(p["range"])
		var w := float(p["width"])
		draw_line(origin, end, Color(c, 0.22), w * (1.0 + 0.15 * sin(t * 22.0)), true)
		draw_line(origin, end, Color(c, 0.8), w * 0.4, true)
		draw_line(origin, end, Color(1, 1, 1, 0.9), maxf(2.0, w * 0.12), true)
		draw_circle(origin, w * 0.35, Color(c, 0.6))
	else:
		# Tormenta: crece y se oscurece mientras se canaliza, con remolinos dentro.
		var center: Vector2 = _channel["center"]
		var ramp := channel_ramp(_channel["time"])
		var r := storm_radius(p, _channel["time"])
		draw_circle(center, r, Color(c, 0.10 + 0.12 * ramp))
		draw_arc(center, r, 0.0, TAU, 48, Color(c, 0.6 + 0.3 * ramp), 2.0 + 2.0 * ramp, true)
		for k in 5:
			var a := t * (2.5 + k * 0.4) + TAU * k / 5.0
			draw_arc(center, r * (0.25 + 0.15 * k), a, a + 1.3, 10, Color(c.lightened(0.3), 0.55), 2.0, true)
		draw_line(origin + Vector2(0, -30), center, Color(c, 0.25), 2.0, true)


# --- Trampas, minas y torretas (RAM de despliegue) ---

## Cada cuánto dispara una torreta o un contenedor.
func _device_interval(p: Dictionary) -> float:
	return maxf(0.35, float(p["use_time"]) * 1.25) / maxf(0.1, float(p["automaton_speed"]))


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
		"interval": _device_interval(p),
		"color": DAMAGE_COLORS.get(p["damage_type"], Color.WHITE)}
	if kind in TURRET_DEVICES:
		# Las torretas tienen vida propia: los cazadores de invocaciones van a por ellas.
		var hp := player.max_life() * TOTEM_LIFE_FRACTION
		device["ally"] = {"pos": dpos, "life": hp, "max_life": hp, "radius": 14.0, "device": true, "hurt": 0.0}
	_devices.append(device)
	# Límite por tipo (los contenedores, por habilidad): se retira el más antiguo.
	var same: Array = _devices.filter(func(d: Dictionary) -> bool: return d["kind"] == kind and (kind != "container" or d["profile"]["id"] == p["id"]))
	if same.size() > int(rules["max"]) + (0 if kind == "container" else int(p.get("extra_devices", 0))):
		_devices.erase(same[0])
	if kind == "container":
		_update_reservation()


func _update_devices(delta: float) -> void:
	_chain_frame += 1   # también vale para _update_traps, que corre en el mismo fotograma
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
		if d.has("chain_in"):
			# Detonación en cadena: la hizo saltar una vecina (su cuenta atrás empieza
			# al fotograma siguiente, aunque la marcaran en este mismo recorrido).
			if int(d.get("chain_frame", -1)) == _chain_frame:
				still.append(d)
				continue
			d["chain_in"] -= delta
			if d["chain_in"] > 0.0:
				still.append(d)
				continue
			var near := enemies.nearest_index(d["pos"], CHAIN_SEEK)
			_execute(d["profile"], enemies.positions[near] if near != -1 else d["pos"] + Vector2.RIGHT * 10.0, d["pos"])
			_effects.append({"type": "burst", "pos": d["pos"], "radius": 30.0, "time": 0.0, "duration": 0.3, "color": CHAIN_COLOR})
			_chain_from(d["pos"])
			continue
		if d["armed_in"] > 0.0:
			still.append(d)
			continue
		var i := enemies.nearest_index(d["pos"], rules["trigger"])
		if d["kind"] in TURRET_DEVICES:
			d["next_use"] -= delta
			if i != -1 and d["next_use"] <= 0.0:
				d["next_use"] = d["interval"]
				_execute(d["profile"], enemies.positions[i], d["pos"])
			still.append(d)
		elif i != -1:
			# Trampa o mina: se activa contra el enemigo que la pisa y desaparece
			# (y hace saltar a las vecinas).
			_execute(d["profile"], enemies.positions[i], d["pos"])
			_effects.append({"type": "burst", "pos": d["pos"], "radius": 26.0, "time": 0.0, "duration": 0.25, "color": d["color"]})
			_chain_from(d["pos"])
		else:
			still.append(d)
	var containers_lost := _devices.any(func(d: Dictionary) -> bool: return d["kind"] == "container" and not still.has(d))
	_devices = still
	if containers_lost:
		_update_reservation()   # un contenedor destruido libera su maná
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


## Habilidades propias de la invocación (unit.ability o unit.abilities): cada una
## con su enfriamiento (u["ab_cds"]).
func _unit_ability(u: Dictionary, p: Dictionary, delta: float) -> void:
	var list: Array = p.get("unit_abilities", [])
	if list.is_empty():
		return
	if not u.has("ab_cds") or (u["ab_cds"] as Array).size() != list.size():
		u["ab_cds"] = []
		for k in list.size():
			u["ab_cds"].append(u["ab_cd"] if k == 0 else float(list[k].get("cooldown", p["unit_interval"])) * (0.5 + 0.3 * k))
	for k in list.size():
		u["ab_cd"] = u["ab_cds"][k]
		_one_unit_ability(u, p, list[k], delta)
		u["ab_cds"][k] = u["ab_cd"]


## Una habilidad de invocación: cura, barrera, salto, veneno, terremoto o láser.
func _one_unit_ability(u: Dictionary, p: Dictionary, ab: Dictionary, delta: float) -> void:
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
			u["ab_cd"] = float(ab["cooldown"]) / speed if ab.has("cooldown") else float(p["unit_interval"])
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
		"quake":
			# Terremoto: golpe enorme alrededor que aturde (si hay enemigos cerca).
			var quake_radius := float(ab.get("radius", 150.0)) * float(p.get("area_scale", 1.0))
			if enemies.nearest_index(pos, quake_radius) == -1:
				u["ab_cd"] = 0.5
				return
			u["ab_cd"] = float(ab.get("cooldown", 6.0)) / speed
			_ctx(p)
			var qm := float(ab.get("damage_mult", 2.0)) * float(p.get("ability_power", 1.0))
			enemies.stun_in_radius(pos, quake_radius, float(ab.get("stun", 1.0)))
			enemies.hit_in_radius(pos, quake_radius, p["min_damage"] * qm, p["max_damage"] * qm, p["crit_chance"], p["crit_multiplier"])
			Sfx.play("mine", -6.0, 0.7)
			player.camera_shake(4.0, 0.25)
			_effects.append({"type": "quake", "pos": pos, "radius": quake_radius, "time": 0.0, "duration": 0.55, "color": u["color"]})
		"tangle":
			# Enredo (Golem UTP): lanza cables a los de alrededor, los atrae hacia él y los aturde.
			var tangle_radius := float(ab.get("radius", 170.0)) * float(p.get("area_scale", 1.0))
			if enemies.nearest_index(pos, tangle_radius) == -1:
				u["ab_cd"] = 0.5
				return
			u["ab_cd"] = float(ab.get("cooldown", 7.0)) / speed
			var pull := float(ab.get("pull", 0.6))
			for i in enemies.positions.size():
				var to_e: Vector2 = enemies.positions[i] - pos
				if to_e.length() <= tangle_radius + enemies.radii[i] and enemies.speeds[i] > 0.0:
					_effects.append({"type": "cable", "pos": pos, "end": enemies.positions[i], "time": 0.0, "duration": 0.35, "color": u["color"]})
					var dest: Vector2 = pos + to_e * (1.0 - pull)
					enemies.positions[i] = enemies.walk_clamp.call(dest, enemies.radii[i]) if enemies.walk_clamp.is_valid() else dest
			_ctx(p)
			var tm := float(ab.get("damage_mult", 1.2)) * float(p.get("ability_power", 1.0))
			enemies.stun_in_radius(pos, tangle_radius * (1.0 - pull * 0.5), float(ab.get("stun", 0.9)))
			enemies.hit_in_radius(pos, tangle_radius * (1.0 - pull * 0.5), p["min_damage"] * tm, p["max_damage"] * tm, p["crit_chance"], p["crit_multiplier"])
			Sfx.play("swing", -6.0, 0.6)
		"corrode":
			# Corrupción (Golem de Kernel): daño de caos continuo a todo lo que esté cerca.
			u["ab_cd"] = float(ab.get("cooldown", 1.0))
			var corrode_radius := float(ab.get("radius", 150.0)) * float(p.get("area_scale", 1.0)) * sqrt(float(p.get("ability_power", 1.0)))
			var avg := (float(p["min_damage"]) + float(p["max_damage"])) * 0.5
			var hit := enemies.dot_in_radius(pos, corrode_radius, avg * float(ab.get("dps_mult", 0.45)) * float(p.get("ability_power", 1.0)), 1.6)
			u["corrode_radius"] = corrode_radius
			if hit > 0:
				_effects.append({"type": "ring", "pos": pos, "radius": corrode_radius, "time": 0.0, "duration": 0.5, "color": Color(u["color"], 0.6)})
		"beam":
			# Láser: una línea hasta el enemigo más lejano a su alcance; daña a todos en ella.
			var reach := float(p["unit"].get("range", 520.0))
			var far := -1
			var far_d := 0.0
			for i in enemies.positions.size():
				var d: float = enemies.positions[i].distance_to(pos)
				if d <= reach and d > far_d:
					far_d = d
					far = i
			if far == -1:
				u["ab_cd"] = 0.5
				return
			u["ab_cd"] = float(ab.get("cooldown", 4.0)) / speed
			var from := pos + Vector2(0, -float(p["unit"].get("beam_height", 74.0)))
			var to: Vector2 = from + (enemies.positions[far] - from).normalized() * reach
			_ctx(p)
			var bm := float(ab.get("damage_mult", 1.6)) * float(p.get("ability_power", 1.0))
			enemies.hit_in_segment(from, to, float(ab.get("width", 22.0)) * 0.5, p["min_damage"] * bm, p["max_damage"] * bm, p["crit_chance"], p["crit_multiplier"])
			Sfx.play("arc", -8.0, 0.8)
			_effects.append({"type": "beam", "pos": from, "dir": (to - from).normalized(), "radius": float(ab.get("width", 22.0)), "length": reach,
				"time": 0.0, "duration": 0.3, "color": Color("ff4a3a")})


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
		if c.get("leak", false):
			# Burbujas «MB» sobre quien pisa la Fuga de Memoria, una tanda cada 0,5 s (T194).
			c["mb_age"] = float(c["mb_age"]) + delta
			if c["mb_age"] >= 0.5:
				c["mb_age"] = 0.0
				c["mb"] = _marks_in_radius(c["pos"], p["radius"])
		if c["life"] > 0.0:
			still.append(c)
	_clouds = still

# --- Terrenos y combos ---
# oil: ralentiza; arde (explosión + suelo en llamas) si dentro hay un enemigo
#   quemándose, lo cruza un proyectil de fuego o cae una explosión de fuego.
# static: daño de rayo por segundo; frost: daño de frío y hiela.
# static + frost encimados = superconductor: el doble de rayo, hiela y puede congelar.
# fire: el aceite ardiendo (quema). base_damage de la habilidad es por segundo.

const MAX_TERRAINS := 6
const TERRAIN_SLOW := {"oil": 0.35, "superconductor": 0.2}
const TERRAIN_COLORS := {"oil": Color("3a2f24"), "static": Color("fff07a"), "frost": Color("9fd8ff"),
	"fire": Color("ff7a2a"), "superconductor": Color("8ae8ff")}
## Explosión del aceite: segundos de daño de su habilidad, y radio respecto al charco.
const OIL_BLAST_SECONDS := 3.0
const OIL_BLAST_SCALE := 1.25
const OIL_FIRE_TIME := 3.0
var _terrains: Array[Dictionary] = []


func _update_terrains(delta: float) -> void:
	if _terrains.is_empty():
		return
	_fuse_superconductors()
	var still: Array[Dictionary] = []
	for t in _terrains:
		t["life"] -= delta
		t["next"] -= delta
		if t["terrain"] == "oil":
			if _oil_should_ignite(t):
				_ignite(t)
		elif t["next"] <= 0.0:
			var p: Dictionary = t["profile"]
			var k: float = maxf(0.05, float(p["tick"]))
			t["next"] = k
			var mult := 1.0
			var ctx: Dictionary = p.get("ailment_ctx", {}).duplicate()
			match t["terrain"]:
				"fire":
					ctx = {"type": "fire", "chances": {Ailments.BURN: 50.0}, "effect": ctx.get("effect", 1.0), "duration": ctx.get("duration", 1.0)}
				"superconductor":
					mult = 2.0
					ctx["type"] = "lightning"
					ctx["chances"] = {Ailments.SHOCK: 50.0, Ailments.CHILL: 100.0, Ailments.FREEZE: 20.0}
			enemies.hit_ailments = ctx
			enemies.hit_in_radius(t["pos"], t["radius"], p["min_damage"] * k * mult, p["max_damage"] * k * mult, 0.0, 100.0)
			_leech(p)
		if t["life"] > 0.0:
			still.append(t)
	_terrains = still


## ¿Arde este charco de aceite? Enemigo quemándose dentro, proyectil de fuego
## encima o un terreno en llamas tocándolo.
func _oil_should_ignite(t: Dictionary) -> bool:
	for i in enemies.positions.size():
		if enemies.burn_time[i] > 0.0 and enemies.positions[i].distance_to(t["pos"]) <= t["radius"] + enemies.radii[i]:
			return true
	for pr in _projectiles:
		if String(pr["profile"].get("damage_type", "")) == "fire" and (pr["pos"] as Vector2).distance_to(t["pos"]) <= t["radius"]:
			return true
	for o in _terrains:
		if o["terrain"] == "fire" and (o["pos"] as Vector2).distance_to(t["pos"]) <= o["radius"] + t["radius"]:
			return true
	return false


## Explosión de fuego en un punto: prende los charcos de aceite que toque.
func _ignite_oil_near(pos: Vector2, radius: float) -> void:
	for t in _terrains:
		if t["terrain"] == "oil" and (t["pos"] as Vector2).distance_to(pos) <= t["radius"] + radius:
			_ignite(t)


## Combo aceite + fuego: explosión que quema a todos y el charco queda ardiendo.
func _ignite(t: Dictionary) -> void:
	if t["terrain"] != "oil":
		return
	var p: Dictionary = t["profile"]
	var ctx: Dictionary = p.get("ailment_ctx", {})
	enemies.hit_ailments = {"type": "fire", "chances": {Ailments.BURN: 100.0}, "effect": ctx.get("effect", 1.0), "duration": ctx.get("duration", 1.0)}
	var r: float = t["radius"] * OIL_BLAST_SCALE
	enemies.hit_in_radius(t["pos"], r, p["min_damage"] * OIL_BLAST_SECONDS, p["max_damage"] * OIL_BLAST_SECONDS, p["crit_chance"], p["crit_multiplier"])
	_leech(p)
	t["terrain"] = "fire"
	t["life"] = OIL_FIRE_TIME
	t["next"] = 0.3
	Sfx.play("mine", -4.0, 0.8)
	_effects.append({"type": "burst", "pos": t["pos"], "radius": r, "time": 0.0, "duration": 0.4, "color": TERRAIN_COLORS["fire"]})
	_effects.append({"type": "ring", "pos": t["pos"], "radius": r, "time": 0.0, "duration": 0.45, "color": Color("ffd060")})


## Combo estática + refrigerante: si se enciman, se funden en un campo superconductor.
func _fuse_superconductors() -> void:
	for a in _terrains:
		if a["terrain"] != "static" or a["life"] <= 0.0:
			continue
		for b in _terrains:
			if b["terrain"] != "frost" or b["life"] <= 0.0:
				continue
			var pa: Vector2 = a["pos"]
			var pb: Vector2 = b["pos"]
			if pa.distance_to(pb) > (a["radius"] + b["radius"]) * 0.6:
				continue
			a["pos"] = pa.lerp(pb, 0.5)
			a["radius"] = maxf(a["radius"], b["radius"]) * 1.1
			a["terrain"] = "superconductor"
			a["life"] = maxf(a["life"], b["life"])
			b["life"] = 0.0
			Sfx.play("arc", -4.0)
			_effects.append({"type": "ring", "pos": a["pos"], "radius": a["radius"], "time": 0.0, "duration": 0.5, "color": TERRAIN_COLORS["superconductor"]})
			break


## Detonación en cadena: al estallar una trampa, mina o bomba en `pos`, las
## armadas a menos de CHAIN_RADIUS estallan CHAIN_DELAY s después (y así sigue).
const CHAIN_RADIUS := 170.0
const CHAIN_DELAY := 0.12
const CHAIN_SEEK := 260.0
const CHAIN_COLOR := Color("ffb040")
## Contador de actualizaciones: una cuenta atrás no avanza en el mismo fotograma en que se marcó.
var _chain_frame := 0


func _chain_from(pos: Vector2) -> void:
	for d in _devices:
		if not (d["kind"] in TURRET_DEVICES) and not d.has("chain_in") and d["armed_in"] <= 0.0 and (d["pos"] as Vector2).distance_to(pos) <= CHAIN_RADIUS:
			d["chain_in"] = CHAIN_DELAY
			d["chain_frame"] = _chain_frame
			_effects.append({"type": "zap", "pos": pos, "end": d["pos"], "time": 0.0, "duration": 0.2, "color": CHAIN_COLOR})
	for trap in _traps:
		if not trap.has("chain_in") and trap["armed_in"] <= 0.0 and (trap["pos"] as Vector2).distance_to(pos) <= CHAIN_RADIUS:
			trap["chain_in"] = CHAIN_DELAY
			trap["chain_frame"] = _chain_frame
			_effects.append({"type": "zap", "pos": pos, "end": trap["pos"], "time": 0.0, "duration": 0.2, "color": CHAIN_COLOR})


func _update_traps(delta: float) -> void:
	var still: Array[Dictionary] = []
	for trap in _traps:
		trap["armed_in"] -= delta
		trap["life"] -= delta
		var p: Dictionary = trap["profile"]
		var chained := false
		if trap.has("chain_in"):
			if int(trap.get("chain_frame", -1)) != _chain_frame:
				trap["chain_in"] -= delta
				chained = trap["chain_in"] <= 0.0
		if chained or (trap["armed_in"] <= 0.0 and not trap.has("chain_in") and enemies.nearest_index(trap["pos"], p["trigger_radius"]) != -1):
			_ctx(p)
			_damage_area(trap["pos"], p["radius"], p)
			_effects.append({"type": "burst", "pos": trap["pos"], "radius": p["radius"], "time": 0.0, "duration": 0.35, "color": CHAIN_COLOR if chained else trap["color"]})
			trap["armed_in"] = 99.0   # ya estalló: que la cadena no la vuelva a contar
			_chain_from(trap["pos"])
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
	if player != null and enemies.last_damage_dealt > 0.0:
		player.restore_mana(character.stats.get_value(Stat.MANA_ON_HIT))


func _update_pending(delta: float) -> void:
	var still: Array[Dictionary] = []
	for e in _pending:
		e["time"] -= delta
		if e["time"] > 0.0:
			still.append(e)
			continue
		var p: Dictionary = e["profile"]
		_ctx(p)
		_triggering = bool(e.get("triggered", false))
		if e["type"] == "blast":
			var radius: float = e.get("radius", p["radius"])
			_damage_area(e["pos"], radius, p)
			if p["damage_type"] == "fire":
				_ignite_oil_near(e["pos"], radius)
			# Con firma (Fork Bomb, T194) la explosión la dibuja ella; el «burst» queda oculto
			# para la luz y las partículas.
			_effects.append({"type": "burst", "pos": e["pos"], "radius": radius, "time": 0.0, "duration": 0.3, "color": e["color"],
				"hidden": e.get("firma", false)})
		elif e["type"] == "beam":
			var end: Vector2 = e["pos"] + e["dir"] * p["range"]
			var marks := _marks_in_segment(e["pos"], end, p["width"] * 0.5) if e.get("firma", false) else PackedVector2Array()
			enemies.hit_in_segment(e["pos"], end, p["width"] * 0.5, p["min_damage"], p["max_damage"], p["crit_chance"], p["crit_multiplier"])
			_leech(p)
			if e.get("firma", false):
				_move_fx(p, e["pos"], end, e["dir"], e["color"], marks, {"firma": "rayo_produccion_fire", "radius": float(p["width"])})
			else:
				_effects.append({"type": "beam", "pos": e["pos"], "dir": e["dir"], "radius": p["width"], "length": p["range"],
					"time": 0.0, "duration": 0.35, "color": e["color"]})
		elif player.is_alive():
			_execute(p, e["target"])
	_pending = still
	_triggering = false


func _update_projectiles(delta: float) -> void:
	var still: Array[Dictionary] = []
	var light := fx_light()
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
		if pr.has("fx") and enemies.impact and not light:
			# Estela de su firma (T74): una partícula cada TRAIL_EVERY segundos.
			pr["trail_t"] = float(pr["trail_t"]) + delta
			if pr["trail_t"] >= SkillFx.TRAIL_EVERY:
				pr["trail_t"] = 0.0
				enemies.impact.trail(pr["pos"], pr["fx"]["trail"], pr["color"], (pr["vel"] as Vector2).normalized())
		var hit := -1
		_ctx(p)
		_triggering = bool(pr.get("triggered", false))
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
			elif int(pr.get("ricochets_left", 0)) > 0 and not pr.get("boomerang", false):
				# Código Espagueti: sale disparado en una dirección cualquiera.
				pr["ricochets_left"] -= 1
				pr["vel"] = (pr["vel"] as Vector2).rotated(randf_range(PI * 0.35, PI * 1.65))
				pr["distance_left"] = maxf(pr["distance_left"], 260.0)
			else:
				pr["pierce_left"] -= 1
			_effects.append({"type": "burst", "pos": pr["pos"], "radius": 14.0, "time": 0.0, "duration": 0.15, "color": pr["color"]})
			if pr.has("fx") and enemies.impact and not light:
				enemies.impact.skill_impact(pr["pos"], pr["fx"]["impact"], pr["color"], (pr["vel"] as Vector2).normalized())
			Sfx.play(SoundMap.impact(String(p.get("damage_type", "physical"))), -12.0, randf_range(0.9, 1.1))   # T77
		var keep: bool = pr.get("boomerang", false) or (pr["distance_left"] > 0.0 and pr["pierce_left"] >= 0)
		if hit != -1 and pr.has("fx") and pr["fx"].has("hit_fx") and not light:
			# Golpe con firma (Ping Letal, T194): su tiempo de respuesta y, si ya no sigue, el eco.
			_move_fx(p, pr["pos"], pr["pos"], (pr["vel"] as Vector2).normalized(), pr["color"], PackedVector2Array(),
				{"firma": pr["fx"]["hit_fx"], "ms": randi_range(1, 99), "echo": not keep})
		if keep:
			still.append(pr)
	_projectiles = still
	_triggering = false


## Versión ligera de los efectos (T74): con muchos enemigos en pantalla, sin estelas
## ni estallidos de firma y con proyectiles simples (el mismo umbral que EnemyManager).
func fx_light() -> bool:
	return enemies != null and enemies.last_drawn_count > EnemyManager.FX_DETAIL_LIMIT


## Destello al lanzar desde la mano del jugador, con la firma de la habilidad.
func _cast_fx(p: Dictionary, target: Vector2) -> void:
	if enemies == null or enemies.impact == null or fx_light() or String(p.get("damage_type", "none")) == "none":
		return
	var dir := (target - player.global_position).normalized() if target != player.global_position else Vector2.RIGHT
	var color: Color = Player.DOT_COLORS.get(String(p["damage_type"]), Color("e8e0d0"))
	enemies.impact.cast(player.global_position + dir * 16.0 + Vector2(0, -24.0), SkillFx.signature(p)["cast"], color, dir)
	if _has_buff("skill:hiperthreading"):
		# Hiperthreading (T195): el segundo hilo suelta su propio destello, un poco detrás.
		enemies.impact.cast(player.global_position + dir * 10.0 + dir.orthogonal() * 8.0 + Vector2(0, -24.0), SkillFx.signature(p)["cast"], color, dir)


func _update_effects(delta: float) -> void:
	_update_aura_fx(delta)
	var still: Array[Dictionary] = []
	for e in _effects:
		e["time"] += delta
		if e.get("live", false) and player != null:
			_update_live(e, delta)
		if e["time"] < e["duration"]:
			still.append(e)
	_effects = still


func _draw() -> void:
	for trap in _traps:
		var armed: bool = trap["armed_in"] <= 0.0
		var blink := armed and (fmod(Time.get_ticks_msec() / 1000.0, 1.0) < 0.5 or not Accessibility.can_blink())
		draw_circle(trap["pos"], 9.0, Color("2a2a30"))
		draw_circle(trap["pos"], 3.0, trap["color"] if blink else Color(trap["color"], 0.3))
		draw_arc(trap["pos"], trap["profile"]["trigger_radius"], 0.0, TAU, 24, Color(trap["color"], 0.18), 1.0, true)
	_draw_auras()
	_draw_terrains()
	_draw_fire_walls()
	_draw_clouds()
	_draw_devices()
	_draw_channel()
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
	var fx_lite := fx_light()
	var fx_font := ThemeDB.fallback_font
	for e in _effects:
		if e["time"] < 0.0:
			continue
		var t: float = e["time"] / e["duration"]
		var c: Color = e["color"]
		match e["type"]:
			"firma":
				SkillFx.draw_move_fx(self, e, fx_font, fx_lite, Accessibility.reduce_flashes)
				if e.get("live", false) and not fx_lite:
					_draw_buff_allies(e)
			"leap":
				# Arco del salto: una sombra que recorre el camino y una estela.
				var a: Vector2 = e["pos"]
				var b: Vector2 = e["end"]
				var pts := PackedVector2Array()
				for k in 9:
					var s := k / 8.0
					pts.append(a.lerp(b, s) + Vector2(0, -sin(s * PI) * 60.0))
				draw_polyline(pts, Color(c, 0.6 * (1.0 - t)), 4.0 * (1.0 - t) + 1.0, true)
			"cable":
				# Enredo: un cable UTP ondulado que sale del golem hasta el enemigo y se recoge.
				var a2: Vector2 = e["pos"] + Vector2(0, -20)
				var b2: Vector2 = (e["end"] as Vector2).lerp(a2, t * 0.6)
				var side := (b2 - a2).orthogonal().normalized()
				var cable := PackedVector2Array()
				for k in 11:
					var s := k / 10.0
					cable.append(a2.lerp(b2, s) + side * sin(s * TAU * 1.5 + t * 8.0) * 6.0 * (1.0 - s))
				draw_polyline(cable, Color(c, 0.9 * (1.0 - t)), 3.0, true)
				draw_rect(Rect2(b2 - Vector2(3, 3), Vector2(6, 6)), Color(0.9, 0.9, 0.9, 1.0 - t))   # el RJ45
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
				if not e.get("hidden", false):
					draw_circle(e["pos"], e["radius"] * (0.5 + 0.5 * t), Color(c, 0.45 * (1.0 - t)))
			"marker":
				draw_arc(e["pos"], e["radius"], 0.0, TAU, 48, Color(c, 0.35 + 0.4 * t), 2.0, true)
				draw_circle(e["pos"], e["radius"] * t, Color(c, 0.12))
	var light := fx_lite
	var fx_time := Time.get_ticks_msec() / 1000.0
	# Sombra de cada proyectil en el suelo (vuelan): primero todas, debajo.
	for pr in _projectiles:
		draw_set_transform(pr["pos"] + Vector2(0, PROJECTILE_SHADOW_DROP), 0.0, Vector2(1.0, 0.45))
		draw_circle(Vector2.ZERO, 6.0, Color(0, 0, 0, 0.22))
	draw_set_transform(Vector2.ZERO)
	for pr in _projectiles:
		if pr.get("boomerang", false):
			# Arma girando: dos aspas.
			var a: float = pr["spin"]
			for k in 2:
				var d := Vector2.from_angle(a + PI * k)
				draw_line(pr["pos"] - d * 12.0, pr["pos"] + d * 12.0, pr["color"], 4.0, true)
			continue
		var dir: Vector2 = pr["vel"].normalized()
		# Cada habilidad con su forma (SkillFx): paquete, esquirla, rayo, bola de fuego, gota…
		var shape: String = pr["fx"]["projectile"] if pr.has("fx") else ("glitch" if pr.get("dot", false) else "orb")
		SkillFx.draw_projectile(self, pr["pos"], dir, pr["color"], shape, fx_time + float(pr.get("phase", 0.0)), light, Accessibility.reduce_flashes)


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
			"container":
				# Contenedor: una caja azul con el logo de la ballena y su carga apilada.
				draw_arc(p, 30.0, 0.0, TAU, 32, Color(c, 0.35), 1.5, true)
				draw_rect(Rect2(p + Vector2(-16, -22), Vector2(32, 24)), Color("1d63a8"))
				draw_rect(Rect2(p + Vector2(-16, -22), Vector2(32, 24)), Color("8ac4f0"), false, 2.0)
				for k in 3:
					draw_line(p + Vector2(-10 + k * 10, -20), p + Vector2(-10 + k * 10, 0), Color("174f86"), 2.0)
				for k in 3:
					var on := fmod(t * 2.0 + k * 0.4, 1.2) < 0.6
					draw_rect(Rect2(p + Vector2(-9 + k * 6, -32), Vector2(5, 5)), c if on else Color("8ac4f0"))
				draw_circle(p + Vector2(0, -10), 3.0, Color.WHITE)
		if String(d["kind"]) in TURRET_DEVICES:
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


## Color de un aura: el suyo (T195) o, si no tiene estilo, rojo las hostiles y el de su tipo las demás.
func _aura_tint(a: Dictionary) -> Color:
	var hostile: bool = not a["profile"].get("aura_enemy", {}).is_empty()
	var fallback: Color = Color("e06c6c") if hostile else Accessibility.aura_color(String(a["profile"].get("damage_type", "")), a["color"])
	return SkillFx.aura_tint(String(a["skill_id"]), fallback)


## Cada aura con su anillo y su motivo en el borde (T195: engranajes, placas, llaves,
## banderas, trazos que giran hacia atrás o dientes con mira), unos aros de su color a
## los pies del jugador (uno por aura) y lo que se ve en los aliados o enemigos de dentro.
func _draw_auras() -> void:
	if _auras.is_empty() or not player.is_alive():
		return
	var tt := Time.get_ticks_msec() / 1000.0
	var light := fx_light()
	var dim := Accessibility.reduce_flashes
	var font := ThemeDB.fallback_font
	for a in _auras:
		var ar := float(a["profile"].get("aura_radius", 0.0))
		if ar <= 0.0:
			continue
		var id := String(a["skill_id"])
		var hostile: bool = not a["profile"].get("aura_enemy", {}).is_empty()
		var rc := _aura_tint(a)
		var ac := aura_center(a)
		if bool(a["profile"].get("aura_anchor", false)):
			# Torre de Señal: una antena en el centro del aura anclada.
			draw_line(ac, ac + Vector2(0, -34), Color("8a8a96"), 3.0)
			draw_circle(ac + Vector2(0, -36), 4.0 + sin(Time.get_ticks_msec() / 200.0), rc)
		var on_t := float(a.get("on_t", 1.0))
		SkillFx.draw_aura(self, id, ac, ar, rc, on_t, tt, hostile)
		if hostile:
			var idx: PackedInt32Array = a.get("inside", PackedInt32Array())
			var ids: PackedInt32Array = a.get("inside_ids", PackedInt32Array())
			var entered: Dictionary = a.get("entered", {})
			var aimed := int(on_t / 0.5) % maxi(1, idx.size())
			for j in idx.size():
				var i := idx[j]
				if i >= enemies.positions.size() or enemies.ids[i] != ids[j]:
					continue   # murió o se movió de sitio en las listas desde la última mirada
				var h := maxf(30.0, enemies.radii[i] * 2.4 + 12.0)
				SkillFx.draw_aura_enemy(self, id, enemies.positions[i], h, on_t - float(entered.get(ids[j], -9.0)), tt, rc, j == aimed, font, light)
		else:
			var k := 0
			for u in _units:
				if u["behavior"] == "orbit" or (u["pos"] as Vector2).distance_to(ac) > ar:
					continue
				SkillFx.draw_aura_ally(self, id, u["pos"], float(u["radius"]), k, tt, rc, dim)
				k += 1
			if id == "aura_mantenimiento" and player.global_position.distance_to(ac) <= ar:
				SkillFx.draw_aura_ally(self, id, player.global_position, 12.0, k, tt, rc, dim)
	var n := 0
	for a in _auras:
		var c := _aura_tint(a)
		var radius := 54.0 + n * 9.0
		draw_set_transform(player.global_position + Vector2(0, 14), 0.0, Vector2(1.0, 0.5))
		for q in 4:
			var a0 := tt * (0.9 + n * 0.3) + TAU * q / 4.0
			draw_arc(Vector2.ZERO, radius, a0, a0 + 0.9, 10, Color(c, 0.55), 2.0, true)
		draw_set_transform(Vector2.ZERO)
		n += 1


## Lo que lleva cada invocación mientras dura un grito con firma (T195).
func _draw_buff_allies(e: Dictionary) -> void:
	var id := String(e["firma"])
	if id != "esta_en_produccion" and id != "daily_standup":
		return
	var k := 0
	for u in _units:
		if u["behavior"] != "orbit" and k < SkillFx.MAX_MARKS:
			SkillFx.draw_buff_ally(self, e, u["pos"], float(u["radius"]), k, Accessibility.reduce_flashes)
			k += 1
	for m in _minions:
		if k < SkillFx.MAX_MARKS:
			SkillFx.draw_buff_ally(self, e, m["pos"], 10.0, k, Accessibility.reduce_flashes)
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
			if u.has("corrode_radius"):
				# Golem de Kernel: el campo de corrupción, siempre visible y latiendo.
				var cr: float = u["corrode_radius"]
				draw_circle(p, cr, Color(c, 0.05 + 0.03 * sin(ph * 0.8)))
				draw_arc(p, cr, ph * 0.2, ph * 0.2 + TAU * 0.85, 40, Color(c, 0.35), 1.5, true)


## Terrenos en el suelo, cada uno con su color y su textura (aceite con brillo,
## estática con chispas, escarcha con cristales, fuego con lenguas, superconductor
## con arcos). En modo daltónico, además, un patrón propio por tipo: rayas
## horizontales (aceite), zigzag (estática), cruces (escarcha), diagonales (fuego)
## y puntos (superconductor).
func _draw_terrains() -> void:
	var t := Time.get_ticks_msec() / 1000.0
	for tr in _terrains:
		var p: Vector2 = tr["pos"]
		var r: float = tr["radius"]
		var kind: String = tr["terrain"]
		var col: Color = TERRAIN_COLORS[kind]
		var fade := clampf(float(tr["life"]) / 0.5, 0.0, 1.0)
		var sd := int(tr["seed"]) % 97
		draw_set_transform(p, 0.0, Vector2(1.0, 0.65))
		match kind:
			"oil":
				draw_circle(Vector2.ZERO, r, Color(0.08, 0.06, 0.05, 0.72 * fade))
				draw_circle(Vector2.ZERO, r * 0.82, Color(col, 0.85 * fade))
				for k in 3:   # reflejos irisados
					var a := TAU * k / 3.0 + sd + t * 0.2
					draw_arc(Vector2.from_angle(a) * r * 0.35, r * 0.25, a, a + 1.6, 10, Color(0.6, 0.45 + 0.15 * k, 0.9, 0.35 * fade), 2.0, true)
			"fire":
				draw_circle(Vector2.ZERO, r, Color(col, 0.28 * fade))
				draw_circle(Vector2.ZERO, r * 0.6, Color(1.0, 0.85, 0.3, 0.22 * fade))
			"static":
				draw_circle(Vector2.ZERO, r, Color(col, 0.12 * fade))
				draw_arc(Vector2.ZERO, r, 0.0, TAU, 32, Color(col, 0.55 * fade), 2.0, true)
			"frost":
				draw_circle(Vector2.ZERO, r, Color(col, 0.25 * fade))
				draw_arc(Vector2.ZERO, r, 0.0, TAU, 32, Color(0.9, 0.97, 1.0, 0.6 * fade), 2.0, true)
			"superconductor":
				draw_circle(Vector2.ZERO, r, Color(col, 0.22 * fade))
				draw_arc(Vector2.ZERO, r, 0.0, TAU, 32, Color(0.75, 0.6, 1.0, 0.8 * fade), 3.0, true)
		if Ailments.colorblind:
			_draw_terrain_pattern(kind, r, Color(1, 1, 1, 0.45 * fade))
		draw_set_transform(Vector2.ZERO)
		# Detalle animado (sin aplastar).
		match kind:
			"fire":
				for k in 6:
					var ph := fmod(t * 1.6 + k / 6.0 + sd * 0.1, 1.0)
					var q := p + Vector2.from_angle(TAU * k / 6.0 + sd) * r * 0.5 * Vector2(1.0, 0.65) + Vector2(0, -ph * 22.0)
					draw_circle(q, (1.0 - ph) * 6.0, Color(1.0, 0.5 + 0.4 * ph, 0.1, 0.8 * (1.0 - ph) * fade))
			"static", "superconductor":
				for k in 3:
					var seed_t := floorf(t * 9.0 + k * 3.0 + sd)
					var a := fposmod(seed_t * 2.399 + k * 2.1, TAU)
					var from := p + Vector2.from_angle(a) * r * 0.2 * Vector2(1.0, 0.65)
					var to := p + Vector2.from_angle(a + 0.8) * r * 0.85 * Vector2(1.0, 0.65)
					var mid := from.lerp(to, 0.5) + (to - from).orthogonal().normalized() * (fposmod(seed_t * 3.1, 1.0) - 0.5) * 18.0
					draw_polyline(PackedVector2Array([from, mid, to]), Color(col, 0.85 * fade), 1.6, true)
			"frost":
				for k in 6:
					var q := p + Vector2.from_angle(TAU * k / 6.0 + sd) * r * 0.6 * Vector2(1.0, 0.65)
					draw_colored_polygon(PackedVector2Array([q + Vector2(-3, 0), q + Vector2(0, -12), q + Vector2(3, 0)]), Color(0.85, 0.96, 1.0, 0.75 * fade))


## Patrón de modo daltónico de cada terreno (en las coordenadas ya aplastadas del charco).
func _draw_terrain_pattern(kind: String, r: float, c: Color) -> void:
	var step := 16.0
	var y := -r + step * 0.5
	while y < r:
		var half := sqrt(maxf(0.0, r * r - y * y)) * 0.85
		match kind:
			"oil":
				draw_line(Vector2(-half, y), Vector2(half, y), c, 2.0)
			"static":
				var pts := PackedVector2Array()
				var x := -half
				var up := true
				while x <= half:
					pts.append(Vector2(x, y + (-4.0 if up else 4.0)))
					up = not up
					x += 8.0
				if pts.size() >= 2:
					draw_polyline(pts, c, 1.5)
			"frost":
				var x := -half + 8.0
				while x < half:
					draw_line(Vector2(x - 4, y), Vector2(x + 4, y), c, 1.5)
					draw_line(Vector2(x, y - 4), Vector2(x, y + 4), c, 1.5)
					x += step
			"fire":
				var x := -half
				while x < half:
					draw_line(Vector2(x, y + 5), Vector2(x + 8, y - 5), c, 1.5)
					x += 12.0
			"superconductor":
				var x := -half + 6.0
				while x < half:
					draw_circle(Vector2(x, y), 2.0, c)
					x += 12.0
		y += step


func _draw_clouds() -> void:
	var t := Time.get_ticks_msec() / 1000.0
	for c in _clouds:
		var p: Vector2 = c["pos"]
		var r: float = c["profile"]["radius"]
		var fade := clampf(c["life"] / 0.4, 0.0, 1.0)
		var col: Color = c["color"]
		if c.get("revert", false):
			SkillFx.draw_revert_zone(self, p, r, col, c["err"], int(c["seed"]), float(c["life"]), fade, fx_light(), Accessibility.reduce_flashes)
			continue
		if c.get("leak", false):
			# Fuga de Memoria (T194): con más de tres charcos a la vez, la rejilla se simplifica.
			var total: float = c["profile"]["duration"]
			SkillFx.draw_leak_zone(self, p, r, Accessibility.aura_color("chaos", col), int(c["seed"]), total - float(c["life"]), total, fade,
				c["mb"], float(c["mb_age"]), ThemeDB.fallback_font, fx_light() or _clouds.size() > 3)
			continue
		draw_set_transform(p, 0.0, Vector2(1.0, 0.7))
		draw_circle(Vector2.ZERO, r, Color(col, 0.18 * fade))
		draw_circle(Vector2.ZERO, r * 0.7, Color(col, 0.18 * fade))
		draw_set_transform(Vector2.ZERO)
		for k in 6:
			var phase := fmod(t * 0.8 + k / 6.0 + (int(c["seed"]) % 7) * 0.1, 1.0)
			var q := p + Vector2.from_angle(k * 1.7 + int(c["seed"])) * r * 0.55 + Vector2(0, -phase * 14.0)
			draw_circle(q, 3.0 + 2.0 * (1.0 - phase), Color(col.lightened(0.3), 0.6 * (1.0 - phase) * fade))
