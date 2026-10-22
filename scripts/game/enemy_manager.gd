class_name EnemyManager
extends Node2D
## Simula y dibuja a TODOS los enemigos desde un solo nodo: datos en arrays
## empaquetados (estilo orientado a datos) y un MultiMesh que los pinta en una
## sola llamada. Un nodo con física por enemigo no escala igual en GDScript
## cuando hay cientos en pantalla, que es lo normal en un ARPG tipo PoE.
##
## Los sprites salen de un atlas animado por un shader (enemy_sprite.gdshader):
## fotograma, volteo, contorno de rareza y destello de daño van por instancia.
##
## Si el benchmark se queda corto, este es el archivo a portar a C# o a
## GDExtension (C++): la interfaz pública no tendría que cambiar.

signal enemy_killed(rarity: Rarity.Enemy, experience: int, position: Vector2, type_id: String)
## Un golpe a un enemigo inmune (para el aviso "INMUNE").
signal immune_hit(position: Vector2)
## Un jefe cruza el umbral de una fase: (id, nombre de la fase, texto, color).
signal phase_started(id: int, phase_name: String, text: String, color: Color)

const TYPES_PATH := "res://data/enemies.json"
const ATLAS := preload("res://assets/sprites/enemies/enemies.png")
const SPRITE_SHADER := preload("res://assets/shaders/enemy_sprite.gdshader")
const ATLAS_FRAMES := 4
## Tamaño del sprite respecto al diámetro de colisión.
const SPRITE_SCALE := 2.24
const BASE_LIFE := 40.0
const BASE_DAMAGE := 7.0
const BASE_EXPERIENCE := 6.0
const ATTACK_INTERVAL := 1.2
## Más lejos que esto del jugador, los enemigos se quedan quietos.
const AGGRO_RANGE := 850.0
const FLASH_TIME := 0.12
const GRID_CELL := 48.0
const RADIUS_BY_RARITY := {
	Rarity.Enemy.NORMAL: 11.0,
	Rarity.Enemy.SPECIAL: 14.0,
	Rarity.Enemy.ELITE: 18.0,
	Rarity.Enemy.UNIQUE: 30.0,
}
const SPEED_BY_RARITY := {
	Rarity.Enemy.NORMAL: 135.0,
	Rarity.Enemy.SPECIAL: 145.0,
	Rarity.Enemy.ELITE: 125.0,
	Rarity.Enemy.UNIQUE: 105.0,
}
const ELITE_PREFIXES := ["Excepción", "Segfault", "Proceso", "Demonio", "Hilo", "Cron"]
const ELITE_SUFFIXES := ["sin control", "del viernes", "huérfano", "zombi", "bloqueante", "de las 3 AM", "en producción"]
const UNIQUE_NAMES := [
	"El Arquitecto del Monolito",
	"El Backlog Infinito",
	"El Product Owner Sin Rostro",
	"La Reunión Que Pudo Ser Un Email",
]

static var _types: Array = []
static var _affixes: Dictionary = {}
## Tipos de daño con resistencia, y el tipo de daño de cada estado (para su daño por segundo).
const RESIST_TYPES := ["physical", "fire", "cold", "lightning", "chaos"]
const AILMENT_ELEMENT := {"burn": "fire", "poison": "chaos", "bleed": "physical"}
const RESIST_CAP := 90.0

var player: Player
## Nivel de zona: escala vida, daño y experiencia.
var area_level := 1
## Zona segura (campamento): los enemigos no entran ni persiguen dentro.
var safe_center := Vector2.ZERO
var safe_radius := 0.0
## Daño total del último golpe (para el robo de vida).
var last_damage_dealt := 0.0
## Obstáculos de la zona (x, y, radio) y límites del mapa: los enemigos no los atraviesan.
var obstacles: Array[Vector3] = []
var bounds := Rect2(-1e6, -1e6, 2e6, 2e6)
## Opcional: (pos, radio) -> pos dentro de los bordes irregulares de la zona.
var walk_clamp: Callable
## Durante las escenas todo se congela (ni se mueven, ni atacan, ni disparan).
var frozen := false
## Distancia a la que despiertan (cada zona puede cambiarla: el tutorial la acorta).
var aggro_range := AGGRO_RANGE

var ids := PackedInt32Array()
var positions := PackedVector2Array()
var lives := PackedFloat32Array()
var max_lives := PackedFloat32Array()
var damages := PackedFloat32Array()
var speeds := PackedFloat32Array()
var radii := PackedFloat32Array()
var cooldowns := PackedFloat32Array()
var rarities := PackedInt32Array()
var types := PackedInt32Array()
var facings := PackedFloat32Array()   # 1 = mira a la izquierda
var phases := PackedFloat32Array()    # desfase de animación
var flashes := PackedFloat32Array()   # tiempo restante de destello
var names := PackedStringArray()
var stuns := PackedFloat32Array()     # aturdimiento restante
var windups := PackedFloat32Array()   # > 0: preparando su ataque (telegrafiado)
var attack_dirs := PackedVector2Array()
var dashes := PackedFloat32Array()    # > 0: embistiendo
var dash_hit := PackedByteArray()     # 1 si la embestida ya golpeó al jugador
var immune := PackedByteArray()       # 1 = no recibe daño (gemelos de la Carrera Crítica)
var dot_dps := PackedFloat32Array()   # daño degenerativo por segundo
var dot_time := PackedFloat32Array()  # segundos que le quedan
# Estados alterados (ver Ailments).
var burn_dps := PackedFloat32Array()
var burn_time := PackedFloat32Array()
var shock_time := PackedFloat32Array()
var shock_amp := PackedFloat32Array()   # daño extra recibido mientras dure (0.25 = +25 %)
var chill_time := PackedFloat32Array()
var freeze_time := PackedFloat32Array()
var poison_dps := PackedFloat32Array()
var poison_time := PackedFloat32Array()
var poison_stacks := PackedInt32Array()
var bleed_dps := PackedFloat32Array()
var bleed_time := PackedFloat32Array()

## Estados que puede aplicar el golpe en curso (lo prepara SkillController antes
## de llamar a hit_*): {chances: {burn: %, ...}, effect: mult. de daño, duration: mult.}.
var hit_ailments: Dictionary = {}
## Rasgos de cada enemigo: {res: {tipo: %}, immune: {estado: true}, affixes: [ids]} (o {} si no tiene).
var traits: Array = []
## Jefes con fases: id -> {list: [...], next: índice de la próxima fase}.
var boss_phases := {}
## Segundos de invulnerabilidad restantes tras cambiar de fase: id -> tiempo.
var phase_shield := {}
## ¿Tiran afijos los élite y especiales nuevos? (las pruebas lo apagan para ser deterministas)
var roll_affixes := true
var _affix_timers := {}
## Explosiones diferidas (Sobrecarga: electrocutado + daño de fuego) y último sonido de cada estado.
var _booms: Array[Dictionary] = []
var _sfx_last := {}
## Aliados que los enemigos pueden atacar (invocaciones persistentes):
## [{pos, life, max_life, radius, taunt}]. Los mantiene SkillController.
var allies: Array = []

## Proyectiles enemigos: {pos, vel, damage, radius, life, color}
var projectiles: Array[Dictionary] = []
## Ataques en el suelo con retardo (jefe): {pos, radius, time, delay, damage}
var hazards: Array[Dictionary] = []
## Charcos que hacen daño degenerativo mientras se pisan: {pos, radius, life, dps, color, kind}.
var pools: Array[Dictionary] = []
## Habilidades especiales por id de enemigo: [{def, timer}] y lanzamiento en curso.
var abilities := {}
var casting := {}                     # id -> {def, time, target, total}
var _flashes_fx: Array[Dictionary] = []  # destellos de impactos enemigos (solo visual)

## Coste del último tick de simulación (IA + separación), en milisegundos.
## Presupuesto orientativo: < 4 ms para dejar sitio al resto del juego.
var last_simulation_ms := 0.0

var _next_id := 1
var _multimesh: MultiMesh
var _grid: Dictionary = {}  # Vector2i -> Array de índices


static func affix_defs() -> Dictionary:
	if _affixes.is_empty():
		var data = DataLoader.load_json("res://data/enemy_affixes.json")
		for a in (data.get("affixes", []) if data is Dictionary else []):
			_affixes[a["id"]] = a
	return _affixes


static func enemy_types() -> Array:
	if _types.is_empty():
		var data = DataLoader.load_json(TYPES_PATH)
		_types = data.get("types", []) if data is Dictionary else []
	return _types


func _ready() -> void:
	_multimesh = MultiMesh.new()
	_multimesh.transform_format = MultiMesh.TRANSFORM_2D
	_multimesh.use_colors = true
	_multimesh.use_custom_data = true
	var quad := QuadMesh.new()
	quad.size = Vector2.ONE
	_multimesh.mesh = quad
	var mm_instance := MultiMeshInstance2D.new()
	mm_instance.multimesh = _multimesh
	mm_instance.texture = ATLAS
	mm_instance.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	var sprite_material := ShaderMaterial.new()
	sprite_material.shader = SPRITE_SHADER
	sprite_material.set_shader_parameter("grid", Vector2(ATLAS_FRAMES, enemy_types().size()))
	mm_instance.material = sprite_material
	mm_instance.show_behind_parent = true  # barras de vida y nombres encima
	add_child(mm_instance)


func count() -> int:
	return positions.size()


## type_index -1: un tipo aleatorio (los únicos usan los tipos de jefe).
## custom_name y life_mult: para jefes con nombre propio.
## abilities: habilidades especiales (jefes), ver act1.json → boss.abilities.
func spawn(pos: Vector2, rarity: Rarity.Enemy, type_index := -1, custom_name := "", life_mult := 1.0,
		special_abilities: Array = [], affix_ids: Array = []) -> int:
	if type_index < 0:
		type_index = random_type(rarity == Rarity.Enemy.UNIQUE)
	var t: Dictionary = enemy_types()[type_index] if not enemy_types().is_empty() else {}
	var info: Dictionary = Rarity.ENEMY_INFO[rarity]
	var level_mult := 1.0 + 0.15 * (area_level - 1)
	var life: float = BASE_LIFE * info.life_mult * level_mult * t.get("life_mult", 1.0) * life_mult
	ids.append(_next_id)
	_next_id += 1
	positions.append(pos)
	lives.append(life)
	max_lives.append(life)
	damages.append(BASE_DAMAGE * info.damage_mult * level_mult * t.get("damage_mult", 1.0))
	speeds.append(SPEED_BY_RARITY[rarity] * t.get("speed_mult", 1.0) * randf_range(0.9, 1.1))
	radii.append(RADIUS_BY_RARITY[rarity] * float(t.get("radius_mult", 1.0)))
	cooldowns.append(randf() * ATTACK_INTERVAL)
	rarities.append(rarity)
	types.append(type_index)
	facings.append(0.0)
	phases.append(randf() * ATLAS_FRAMES)
	flashes.append(0.0)
	names.append(custom_name if custom_name != "" else _random_name(rarity))
	stuns.append(0.0)
	windups.append(0.0)
	attack_dirs.append(Vector2.RIGHT)
	dashes.append(0.0)
	dash_hit.append(0)
	immune.append(0)
	dot_dps.append(0.0)
	dot_time.append(0.0)
	burn_dps.append(0.0)
	burn_time.append(0.0)
	shock_time.append(0.0)
	shock_amp.append(0.0)
	chill_time.append(0.0)
	freeze_time.append(0.0)
	poison_dps.append(0.0)
	poison_time.append(0.0)
	poison_stacks.append(0)
	bleed_dps.append(0.0)
	bleed_time.append(0.0)
	traits.append(_make_traits(t, rarity, affix_ids if not affix_ids.is_empty() or not roll_affixes else _roll_affixes(rarity), special_abilities.is_empty()))
	var tr: Dictionary = traits[traits.size() - 1]
	if tr.has("affixes"):
		var i_new := traits.size() - 1
		for aid in tr["affixes"]:
			var shield_frac := float(affix_defs().get(aid, {}).get("shield", 0.0))
			if shield_frac > 0.0:
				tr["shield"] = lives[i_new] * shield_frac
		var affix_speed := 1.0
		var prefix := ""
		for aid in tr["affixes"]:
			var def: Dictionary = affix_defs().get(aid, {})
			affix_speed *= float(def.get("speed_mult", 1.0))
			if prefix == "":
				prefix = String(def.get("name", ""))
		speeds[i_new] *= affix_speed
		if rarity >= Rarity.Enemy.ELITE and prefix != "":
			names[i_new] = "%s %s" % [prefix, names[i_new]]
	if not special_abilities.is_empty():
		var list: Array = []
		for a in special_abilities:
			list.append({"def": a, "timer": float(a.get("first", a.get("cooldown", 6.0) * 0.5))})
		abilities[ids[ids.size() - 1]] = list
	return ids[ids.size() - 1]


## Afijos al azar según la rareza y el nivel de la zona: élite 1 (2 desde el nivel 8),
## especiales 1 de cada 4 desde el nivel 3. Los únicos no tiran (los jefes tienen fases).
func _roll_affixes(rarity: int) -> Array:
	var count := 0
	if rarity == Rarity.Enemy.ELITE:
		count = 2 if area_level >= 8 else 1
	elif rarity == Rarity.Enemy.SPECIAL and area_level >= 3 and randf() < 0.25:
		count = 1
	if count == 0:
		return []
	var pool: Array = []
	for aid in affix_defs():
		if int(affix_defs()[aid].get("min_level", 1)) <= area_level:
			pool.append(aid)
	pool.shuffle()
	return pool.slice(0, mini(count, pool.size()))


## Resistencias, inmunidades y afijos de un enemigo (tipo + afijos).
func _make_traits(t: Dictionary, _rarity: int, affix_ids: Array, _normal_spawn: bool) -> Dictionary:
	var res: Dictionary = {}
	var immune_set: Dictionary = {}
	for k in t.get("resist", {}):
		res[k] = float(t["resist"][k])
	for k in t.get("immune", []):
		immune_set[k] = true
	var applied: Array = []
	for aid in affix_ids:
		var def: Dictionary = affix_defs().get(aid, {})
		if def.is_empty():
			continue
		applied.append(aid)
		for k in def.get("resist", {}):
			res[k] = maxf(float(res.get(k, 0.0)), float(def["resist"][k]))
		for k in def.get("immune", []):
			immune_set[k] = true
	if res.is_empty() and immune_set.is_empty() and applied.is_empty():
		return {}
	var out := {}
	if not res.is_empty():
		out["res"] = res
	if not immune_set.is_empty():
		out["immune"] = immune_set
	if not applied.is_empty():
		out["affixes"] = applied
	return out


## Resistencia (%) del enemigo i a un tipo de daño.
func resist_of(i: int, damage_type: String) -> float:
	return minf(RESIST_CAP, float(traits[i].get("res", {}).get(damage_type, 0.0)))


func is_immune_to(i: int, ailment: String) -> bool:
	return traits[i].get("immune", {}).has(ailment)


func affixes_of(i: int) -> Array:
	return traits[i].get("affixes", [])


## Fases de un jefe (act*.json → boss.phases). Al cruzar cada umbral de vida:
## aviso, más velocidad y daño, un instante de invulnerabilidad y una onda.
func set_phases(id: int, list: Array) -> void:
	if not list.is_empty():
		boss_phases[id] = {"list": list, "next": 0}


## Info para la barra de jefe: {id, index (fase actual 0..n), thresholds, frac, shield}.
func boss_info() -> Dictionary:
	for id in boss_phases:
		var i := index_of(id)
		if i == -1:
			continue
		var bp: Dictionary = boss_phases[id]
		var thresholds: Array = []
		var names_list: Array = []
		for ph in bp["list"]:
			thresholds.append(float(ph["at"]))
			names_list.append(String(ph.get("name", "")))
		return {"id": id, "index": int(bp["next"]), "thresholds": thresholds, "phase_names": names_list,
			"frac": lives[i] / max_lives[i], "shield": float(phase_shield.get(id, 0.0)), "name": names[i], "pos": positions[i], "rarity": rarities[i]}
	return {}


func _update_phases(delta: float) -> void:
	for id in phase_shield.keys():
		phase_shield[id] -= delta
		if phase_shield[id] <= 0.0:
			phase_shield.erase(id)
	for id in boss_phases.keys():
		var i := index_of(id)
		if i == -1:
			boss_phases.erase(id)
			continue
		var bp: Dictionary = boss_phases[id]
		var list: Array = bp["list"]
		var frac := lives[i] / max_lives[i]
		while bp["next"] < list.size() and frac <= float(list[bp["next"]]["at"]):
			_start_phase(i, list[bp["next"]])
			bp["next"] += 1


func _start_phase(i: int, ph: Dictionary) -> void:
	var color := Color(ph.get("nova", {}).get("color", "ff8c2a"))
	speeds[i] *= float(ph.get("speed_mult", 1.0))
	damages[i] *= float(ph.get("damage_mult", 1.0))
	phase_shield[ids[i]] = float(ph.get("invulnerable", 1.0))
	stuns[i] = 0.0
	windups[i] = 0.0
	dashes[i] = 0.0
	casting.erase(ids[i])
	flashes[i] = FLASH_TIME * 4.0
	# Las habilidades de la fase nueva llegan pronto.
	var list: Array = abilities.get(ids[i], [])
	for k in list.size():
		list[k]["timer"] = minf(float(list[k]["timer"]), 2.5 + 1.0 * k)
	if ph.has("resist") or ph.has("immune"):
		# La fase cambia lo que resiste y a qué estados es inmune.
		var tr: Dictionary = traits[i]
		tr["res"] = ph.get("resist", tr.get("res", {})).duplicate()
		var imm := {}
		for k in ph.get("immune", []):
			imm[k] = true
		tr["immune"] = imm
		traits[i] = tr
		for k in Ailments.ALL:
			if imm.has(k):
				match k:
					"burn": burn_time[i] = 0.0
					"shock": shock_time[i] = 0.0
					"chill": chill_time[i] = 0.0
					"freeze": freeze_time[i] = 0.0
					"poison": poison_time[i] = 0.0
					"bleed": bleed_time[i] = 0.0
	if player:
		player.camera_shake(9.0, 0.7)
	var nova: Dictionary = ph.get("nova", {})
	if not nova.is_empty():
		var radius := float(nova.get("radius", 220.0))
		_flashes_fx.append({"type": "circle", "pos": positions[i], "radius": radius, "time": 0.0, "color": color})
		if player and player.is_alive() and positions[i].distance_to(player.global_position) <= radius + Player.RADIUS:
			player.take_damage(damages[i] * 0.6)
		_damage_allies_near(positions[i], radius, damages[i] * 0.6)
	projectiles.clear()
	phase_started.emit(ids[i], String(ph.get("name", "")), String(ph.get("text", "")), color)


func _update_booms() -> void:
	if _booms.is_empty():
		return
	var list := _booms
	_booms = []
	var saved := hit_ailments
	hit_ailments = {}   # no encadena más interacciones
	for b in list:
		_flashes_fx.append({"type": "circle", "pos": b["pos"], "radius": b["radius"], "time": 0.0, "color": Color("ffd84a")})
		hit_in_radius(b["pos"], b["radius"], b["damage"], b["damage"], 0.0, 100.0)
	hit_ailments = saved
	Sfx.play("explosion", -12.0, 1.4)


## Afijos con efecto por tick: regeneración, curación a otros, teletransporte e invocación.
func _update_affixes(delta: float) -> void:
	for i in range(positions.size() - 1, -1, -1):
		var aff: Array = traits[i].get("affixes", [])
		if aff.is_empty():
			continue
		for aid in aff:
			var def: Dictionary = affix_defs().get(aid, {})
			if def.has("healer"):
				var heal_def: Dictionary = def["healer"]
				for j in positions.size():
					if j != i and lives[j] < max_lives[j] and positions[j].distance_to(positions[i]) <= float(heal_def.get("radius", 220.0)):
						lives[j] = minf(max_lives[j], lives[j] + max_lives[j] * float(heal_def.get("pct", 3.0)) / 100.0 * delta)
			if def.has("teleporter") and stuns[i] <= 0.0 and player != null and player.is_alive() and positions[i].distance_to(player.global_position) < aggro_range:
				var tp: Dictionary = def["teleporter"]
				var tkey := "%d:%s" % [ids[i], aid]
				_affix_timers[tkey] = float(_affix_timers.get(tkey, float(tp.get("cooldown", 6.0)))) - delta
				if _affix_timers[tkey] <= 0.0 and positions[i].distance_to(player.global_position) > 170.0:
					_affix_timers[tkey] = float(tp.get("cooldown", 6.0))
					var dest := player.global_position + Vector2.from_angle(randf() * TAU) * float(tp.get("range", 230.0))
					if walk_clamp.is_valid():
						dest = walk_clamp.call(dest, radii[i])
					_flashes_fx.append({"type": "circle", "pos": positions[i], "radius": radii[i] + 12.0, "time": 0.0, "color": Color(def.get("color", "c08aff"))})
					positions[i] = dest
					_flashes_fx.append({"type": "circle", "pos": dest, "radius": radii[i] + 16.0, "time": 0.0, "color": Color(def.get("color", "c08aff"))})
			if def.has("regen") and lives[i] < max_lives[i]:
				lives[i] = minf(max_lives[i], lives[i] + max_lives[i] * float(def["regen"]) / 100.0 * delta)
			if def.has("summoner") and stuns[i] <= 0.0 and player != null and positions[i].distance_to(player.global_position) < aggro_range:
				var sm: Dictionary = def["summoner"]
				var key := "%d:%s" % [ids[i], aid]
				_affix_timers[key] = float(_affix_timers.get(key, float(sm.get("cooldown", 9.0)) * 0.5)) - delta
				if _affix_timers[key] <= 0.0:
					_affix_timers[key] = float(sm.get("cooldown", 9.0))
					if count_type(String(sm.get("type", "bug"))) < int(sm.get("max_alive", 6)):
						var type_i := type_index_of(String(sm.get("type", "bug")))
						for k in int(sm.get("count", 2)):
							var sp := positions[i] + Vector2.from_angle(TAU * k / maxf(1.0, float(sm.get("count", 2))) + randf()) * (radii[i] + 30.0)
							if walk_clamp.is_valid():
								sp = walk_clamp.call(sp, 12.0)
							var saved := roll_affixes
							roll_affixes = false
							spawn(sp, Rarity.Enemy.NORMAL, type_i)
							roll_affixes = saved
						_flashes_fx.append({"type": "circle", "pos": positions[i], "radius": radii[i] + 28.0, "time": 0.0, "color": Color(def.get("color", "c08aff"))})


## Golpe al jugador con los efectos de los afijos (veneno, quemadura).
func _hit_player(i: int, amount: float) -> void:
	player.take_damage(amount)
	for aid in traits[i].get("affixes", []):
		var dot: Dictionary = affix_defs().get(aid, {}).get("on_hit", {}).get("dot", {})
		if not dot.is_empty():
			player.apply_dot("afijo_" + String(aid), damages[i] * float(dot.get("dps_mult", 0.3)), float(dot.get("duration", 3.0)), String(dot.get("kind", "chaos")))
	apply_status_to_player(_status_of(i))


## Sonido corto de un estado (con pausa para que muchos golpes no lo saturen).
func _state_sfx(id: String, on_player := false) -> void:
	var now := Time.get_ticks_msec()
	if now - int(_sfx_last.get(id, -1000)) < 220:
		return
	_sfx_last[id] = now
	var table := {"burn": ["fire", -15.0, 1.5], "shock": ["lightning", -15.0, 1.4], "chill": ["cold", -14.0, 1.3],
		"freeze": ["cold", -10.0, 0.85], "poison": ["flask", -14.0, 0.7], "bleed": ["swing", -16.0, 0.6]}
	if table.has(id):
		var t: Array = table[id]
		Sfx.play(t[0], float(t[1]) + (6.0 if on_player else 0.0), float(t[2]))


## Estado (shock, chill, freeze) que aplican los golpes del enemigo i: el del tipo
## (enemies.json → on_hit_status) o el de un afijo. {} si ninguno.
func _status_of(i: int) -> Dictionary:
	var all_types := enemy_types()
	var st: Dictionary = all_types[types[i]].get("on_hit_status", {}) if types[i] < all_types.size() else {}
	if not st.is_empty():
		return st
	for aid in traits[i].get("affixes", []):
		st = affix_defs().get(aid, {}).get("on_hit", {}).get("status", {})
		if not st.is_empty():
			return st
	return {}


func apply_status_to_player(st: Dictionary) -> void:
	if st.is_empty() or player == null:
		return
	if randf() * 100.0 < float(st.get("chance", 30.0)):
		if player.apply_status(String(st["id"]), float(st.get("duration", 2.0))):
			_state_sfx(String(st["id"]), true)


func set_immune(id: int, value: bool) -> void:
	var i := index_of(id)
	if i != -1:
		immune[i] = 1 if value else 0


## ¿Sigue vivo el enemigo con ese id?
func is_alive_id(id: int) -> bool:
	return index_of(id) != -1


func count_type(type_id: String) -> int:
	var t := type_index_of(type_id)
	var n := 0
	for k in types:
		if k == t:
			n += 1
	return n


func type_index_of(type_id: String) -> int:
	for i in enemy_types().size():
		if enemy_types()[i]["id"] == type_id:
			return i
	return -1


func count_rarity(rarity: int) -> int:
	var n := 0
	for r in rarities:
		if r == rarity:
			n += 1
	return n


func random_type(boss := false) -> int:
	var options: Array = []
	for i in enemy_types().size():
		if bool(enemy_types()[i].get("summon_only", false)):
			continue   # solo aparecen invocados
		if bool(enemy_types()[i].get("boss_only", false)) == boss:
			options.append(i)
	return options.pick_random() if not options.is_empty() else 0


func clear_all() -> void:
	_resize_all(0)
	projectiles.clear()
	hazards.clear()
	pools.clear()
	abilities.clear()
	casting.clear()
	_flashes_fx.clear()
	boss_phases.clear()
	phase_shield.clear()
	_affix_timers.clear()
	_booms.clear()


## Ataque del tipo (enemies.json → attack); {} = cuerpo a cuerpo por contacto.
func attack_of(i: int) -> Dictionary:
	var all_types := enemy_types()
	return all_types[types[i]].get("attack", {}) if types[i] < all_types.size() else {}


## Quita (sin contar como muertos) los enemigos más lejos que `distance`.
func despawn_beyond(center: Vector2, distance: float) -> void:
	for i in range(positions.size() - 1, -1, -1):
		if positions[i].distance_to(center) > distance:
			_remove(i)


## Golpea a todos los enemigos dentro del radio. Devuelve cuántos golpeó y deja
## el daño total en last_damage_dealt.
func hit_in_radius(center: Vector2, radius: float, min_damage: float, max_damage: float,
		crit_chance: float, crit_multiplier: float) -> int:
	var hits := 0
	last_damage_dealt = 0.0
	# Hacia atrás: _kill() mueve el último al hueco, que ya está procesado.
	for i in range(positions.size() - 1, -1, -1):
		if positions[i].distance_to(center) > radius + radii[i]:
			continue
		hits += 1
		_damage(i, min_damage, max_damage, crit_chance, crit_multiplier)
	return hits


## Golpea al primer enemigo dentro del radio que no esté en `ignore_ids`
## (para proyectiles que atraviesan). Devuelve su id, o -1 si no hay nadie.
func hit_one(center: Vector2, radius: float, ignore_ids: Dictionary, min_damage: float, max_damage: float,
		crit_chance: float, crit_multiplier: float) -> int:
	last_damage_dealt = 0.0
	for i in positions.size():
		if ignore_ids.has(ids[i]) or positions[i].distance_to(center) > radius + radii[i]:
			continue
		var id := ids[i]
		_damage(i, min_damage, max_damage, crit_chance, crit_multiplier)
		return id
	return -1


## Golpea a los enemigos que cumplan `test(i)` (forma del golpe) y no estén en
## `ignore_ids`. Devuelve los ids golpeados; el daño total queda en last_damage_dealt.
func hit_where(test: Callable, min_damage: float, max_damage: float, crit_chance: float, crit_multiplier: float,
		ignore_ids: Dictionary = {}, stun := 0.0) -> Array[int]:
	last_damage_dealt = 0.0
	var targets: Array[int] = []
	for i in positions.size():
		if not ignore_ids.has(ids[i]) and test.call(i):
			targets.append(ids[i])
	var dealt := 0.0
	for id in targets:
		var i := index_of(id)
		if i == -1:
			continue
		if stun > 0.0:
			stun_index(i, stun)
		_damage(i, min_damage, max_damage, crit_chance, crit_multiplier)
		dealt += last_damage_dealt
		last_damage_dealt = 0.0
	last_damage_dealt = dealt
	return targets


func hit_in_cone(origin: Vector2, dir: Vector2, radius: float, half_angle: float, min_damage: float, max_damage: float,
		crit_chance: float, crit_multiplier: float) -> int:
	return hit_where(func(i: int) -> bool:
		var to := positions[i] - origin
		var d := to.length()
		return d <= radius + radii[i] and (d < radii[i] or absf(dir.angle_to(to)) <= half_angle + asin(minf(1.0, radii[i] / maxf(d, 1.0)))),
		min_damage, max_damage, crit_chance, crit_multiplier).size()


## Segmento de `a` a `b` con medio ancho `half_width` (embestidas, rayos, bumeranes).
func hit_in_segment(a: Vector2, b: Vector2, half_width: float, min_damage: float, max_damage: float,
		crit_chance: float, crit_multiplier: float, ignore_ids: Dictionary = {}) -> Array[int]:
	return hit_where(func(i: int) -> bool:
		return Geometry2D.get_closest_point_to_segment(positions[i], a, b).distance_to(positions[i]) <= half_width + radii[i],
		min_damage, max_damage, crit_chance, crit_multiplier, ignore_ids)


## Daño degenerativo: el más fuerte manda y renueva la duración (no se apilan).
func apply_dot(i: int, dps: float, duration: float) -> void:
	if immune[i] == 1:
		immune_hit.emit(positions[i])
		return
	if dps >= dot_dps[i] or dot_time[i] <= 0.0:
		dot_dps[i] = dps
	dot_time[i] = maxf(dot_time[i], duration)


func dot_in_radius(center: Vector2, radius: float, dps: float, duration: float) -> int:
	var n := 0
	for i in positions.size():
		if positions[i].distance_to(center) <= radius + radii[i]:
			apply_dot(i, dps, duration)
			n += 1
	return n


## Aplica el degenerativo al primer enemigo tocado (proyectiles). Devuelve su id o -1.
func dot_one(center: Vector2, radius: float, ignore_ids: Dictionary, dps: float, duration: float) -> int:
	for i in positions.size():
		if not ignore_ids.has(ids[i]) and positions[i].distance_to(center) <= radius + radii[i]:
			apply_dot(i, dps, duration)
			return ids[i]
	return -1


## Daños degenerativos (corrupción, quemadura, veneno, sangrado) y duración de
## los demás estados. Electrocutado también amplifica estos daños.
func _update_dots(delta: float) -> void:
	for i in range(positions.size() - 1, -1, -1):
		var dps := 0.0
		if dot_time[i] > 0.0:
			dot_time[i] -= delta
			dps += dot_dps[i]
		if burn_time[i] > 0.0:
			burn_time[i] -= delta
			dps += burn_dps[i]
		if poison_time[i] > 0.0:
			poison_time[i] -= delta
			dps += poison_dps[i]
			if bleed_time[i] > 0.0:
				dps += poison_dps[i] * 0.5   # Infección: envenenado y sangrando a la vez
		if bleed_time[i] > 0.0:
			bleed_time[i] -= delta
			dps += bleed_dps[i] * (Ailments.BLEED_MOVING_MULT if _is_moving(i) else 1.0)
		if shock_time[i] > 0.0:
			shock_time[i] -= delta
			dps *= 1.0 + shock_amp[i]
		chill_time[i] = maxf(0.0, chill_time[i] - delta)
		freeze_time[i] = maxf(0.0, freeze_time[i] - delta)
		if dps <= 0.0:
			continue
		var dmg := dps * delta
		last_damage_dealt += minf(dmg, lives[i])
		lives[i] -= dmg
		if lives[i] <= 0.0:
			_kill(i)


## Aproximado: no está bloqueado, puede moverse y aún no ha llegado al jugador.
func _is_moving(i: int) -> bool:
	return speeds[i] > 0.0 and stuns[i] <= 0.0 and windups[i] <= 0.0 and player != null \
		and positions[i].distance_to(player.global_position) > radii[i] + Player.RADIUS + 8.0


func stun_in_radius(center: Vector2, radius: float, time: float) -> void:
	for i in positions.size():
		if positions[i].distance_to(center) <= radius + radii[i]:
			stun_index(i, time)


## Los únicos se aturden la mitad (los jefes no se quedan bloqueados medio combate).
func stun_index(i: int, time: float) -> void:
	var t := time * (0.5 if rarities[i] == Rarity.Enemy.UNIQUE else 1.0)
	stuns[i] = maxf(stuns[i], t)
	windups[i] = 0.0
	dashes[i] = 0.0
	casting.erase(ids[i])


## Índice del enemigo más cercano a `pos` (dentro de max_dist), ignorando ids; -1 si no hay.
func nearest_index(pos: Vector2, max_dist: float, ignore_ids: Dictionary = {}) -> int:
	var best := -1
	var best_d := max_dist
	for i in positions.size():
		if ignore_ids.has(ids[i]):
			continue
		var d := positions[i].distance_to(pos) - radii[i]
		if d <= best_d:
			best_d = d
			best = i
	return best


func index_of(id: int) -> int:
	for i in ids.size():
		if ids[i] == id:
			return i
	return -1


## Golpea a un enemigo concreto (cadenas). Devuelve su id.
func hit_index(i: int, min_damage: float, max_damage: float, crit_chance: float, crit_multiplier: float) -> int:
	last_damage_dealt = 0.0
	var id := ids[i]
	_damage(i, min_damage, max_damage, crit_chance, crit_multiplier)
	return id


func _damage(i: int, min_damage: float, max_damage: float, crit_chance: float, crit_multiplier: float) -> void:
	if immune[i] == 1:
		flashes[i] = FLASH_TIME * 0.5
		immune_hit.emit(positions[i])
		return
	if not phase_shield.is_empty() and phase_shield.has(ids[i]):
		flashes[i] = FLASH_TIME * 0.5   # entre fases, el jefe es invulnerable
		return
	var damage := randf_range(min_damage, max_damage)
	if randf() * 100.0 < crit_chance:
		damage *= crit_multiplier / 100.0
	if not hit_ailments.is_empty():
		var dtype := String(hit_ailments.get("type", ""))
		if dtype != "" and dtype != "none":
			damage *= 1.0 - resist_of(i, dtype) / 100.0
		var ailing := float(hit_ailments.get("ailing", 1.0))
		if ailing != 1.0 and not ailments_of(i).is_empty():
			damage *= ailing
	if shock_time[i] > 0.0:
		damage *= 1.0 + shock_amp[i]
	var dmg_type := String(hit_ailments.get("type", ""))
	if freeze_time[i] > 0.0 and dmg_type == "physical":
		# Rotura: un golpe físico a un enemigo congelado lo hace pedazos (+50 % y se acaba el hielo).
		damage *= 1.5
		freeze_time[i] = 0.0
		_flashes_fx.append({"type": "circle", "pos": positions[i], "radius": radii[i] * 2.0, "time": 0.0, "color": Color("bfe8ff")})
		_state_sfx("freeze")
	elif burn_time[i] > 0.0 and dmg_type == "cold":
		# Choque térmico: el frío sobre un enemigo en llamas hace un 40 % más y apaga la quemadura.
		damage *= 1.4
		burn_time[i] = 0.0
		_flashes_fx.append({"type": "circle", "pos": positions[i], "radius": radii[i] * 1.8, "time": 0.0, "color": Color("c8e8ff")})
		_state_sfx("chill")
	elif shock_time[i] > 0.0 and dmg_type == "fire":
		# Sobrecarga: el fuego sobre un enemigo electrocutado hace saltar una explosión y gasta la descarga.
		_booms.append({"pos": positions[i], "damage": damage * 0.5, "radius": 85.0})
		shock_time[i] = 0.0
	var traits_i: Dictionary = traits[i]
	if traits_i.has("shield") and float(traits_i["shield"]) > 0.0:
		var absorbed := minf(float(traits_i["shield"]), damage)
		traits_i["shield"] = float(traits_i["shield"]) - absorbed
		damage -= absorbed
		flashes[i] = FLASH_TIME
		if damage <= 0.0:
			return
	if traits_i.has("affixes") and player != null and not hit_ailments.is_empty():
		for aid in traits_i["affixes"]:
			var reflect := float(affix_defs().get(aid, {}).get("reflect", 0.0))
			if reflect > 0.0 and player.is_alive():
				player.take_damage(minf(damage * reflect, player.max_life() * 0.1))
	last_damage_dealt += minf(damage, lives[i])
	lives[i] -= damage
	flashes[i] = FLASH_TIME
	if lives[i] <= 0.0:
		_kill(i)
	elif not hit_ailments.is_empty() and damage > 0.0:
		_roll_ailments(i, damage)


## Tira los dados de cada estado alterado del golpe en curso (hit_ailments).
func _roll_ailments(i: int, damage: float) -> void:
	var chances: Dictionary = hit_ailments.get("chances", {})
	var effect := float(hit_ailments.get("effect", 1.0))
	var dur := float(hit_ailments.get("duration", 1.0))
	for id in chances:
		if randf() * 100.0 >= float(chances[id]):
			continue
		apply_ailment(i, id, damage, effect, dur)


## Aplica un estado a un enemigo. `damage`: golpe que lo causa (base de los
## degenerativos). Los únicos lo sufren la mitad de tiempo.
func apply_ailment(i: int, id: String, damage: float, effect := 1.0, duration_mult := 1.0) -> void:
	if immune[i] == 1 or is_immune_to(i, id):
		return
	_state_sfx(id)
	var t: float = Ailments.DURATION.get(id, 2.0) * duration_mult * (0.5 if rarities[i] == Rarity.Enemy.UNIQUE else 1.0)
	var dps: float = damage * float(Ailments.DOT_FRACTION.get(id, 0.0)) * effect
	if AILMENT_ELEMENT.has(id):
		dps *= 1.0 - resist_of(i, AILMENT_ELEMENT[id]) / 100.0
	match id:
		Ailments.BURN:
			# La quemadura más fuerte manda; renueva la duración.
			burn_dps[i] = maxf(burn_dps[i] if burn_time[i] > 0.0 else 0.0, dps)
			burn_time[i] = maxf(burn_time[i], t)
		Ailments.SHOCK:
			shock_amp[i] = maxf(shock_amp[i] if shock_time[i] > 0.0 else 0.0, Ailments.SHOCK_AMP * effect)
			shock_time[i] = maxf(shock_time[i], t)
		Ailments.CHILL:
			chill_time[i] = maxf(chill_time[i], t)
		Ailments.FREEZE:
			freeze_time[i] = maxf(freeze_time[i], t)
			stun_index(i, t * (2.0 if rarities[i] == Rarity.Enemy.UNIQUE else 1.0))   # stun_index ya lo reduce a la mitad
		Ailments.POISON:
			# El veneno se acumula: cada aplicación suma (hasta POISON_MAX_STACKS).
			if poison_time[i] <= 0.0:
				poison_dps[i] = 0.0
				poison_stacks[i] = 0
			if poison_stacks[i] < Ailments.POISON_MAX_STACKS:
				poison_stacks[i] += 1
				poison_dps[i] += dps
			else:
				poison_dps[i] = maxf(poison_dps[i], dps * Ailments.POISON_MAX_STACKS)
			poison_time[i] = maxf(poison_time[i], t)
		Ailments.BLEED:
			bleed_dps[i] = maxf(bleed_dps[i] if bleed_time[i] > 0.0 else 0.0, dps)
			bleed_time[i] = maxf(bleed_time[i], t)


## Estados activos del enemigo i: [{id, time, stacks}] (para el HUD y su dibujo).
func ailments_of(i: int) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	if freeze_time[i] > 0.0:
		out.append({"id": Ailments.FREEZE, "time": freeze_time[i]})
	elif stuns[i] > 0.0:
		out.append({"id": "stun", "time": stuns[i]})
	if burn_time[i] > 0.0:
		out.append({"id": Ailments.BURN, "time": burn_time[i]})
	if shock_time[i] > 0.0:
		out.append({"id": Ailments.SHOCK, "time": shock_time[i]})
	if chill_time[i] > 0.0:
		out.append({"id": Ailments.CHILL, "time": chill_time[i]})
	if poison_time[i] > 0.0:
		out.append({"id": Ailments.POISON, "time": poison_time[i], "stacks": poison_stacks[i]})
	if bleed_time[i] > 0.0:
		out.append({"id": Ailments.BLEED, "time": bleed_time[i]})
	if dot_time[i] > 0.0:
		out.append({"id": "corrupt", "time": dot_time[i]})
	return out


## Enemigo bajo el cursor (o el más cercano a `pos` a menos de `slack` de su borde); -1 si no hay.
func hover_index(pos: Vector2, slack := 14.0) -> int:
	var best := -1
	var best_d := INF
	for i in positions.size():
		var d := positions[i].distance_to(pos) - radii[i] * SPRITE_SCALE
		if d <= slack and d < best_d:
			best_d = d
			best = i
	return best


func is_in_safe_zone(pos: Vector2) -> bool:
	return safe_radius > 0.0 and pos.distance_to(safe_center) < safe_radius


func _physics_process(delta: float) -> void:
	if frozen:
		return
	var n := positions.size()
	_update_projectiles(delta)
	_update_hazards(delta)
	_update_pools(delta)
	_update_dots(delta)
	_update_phases(delta)
	_update_affixes(delta)
	_update_booms()
	n = positions.size()
	if n == 0 or player == null:
		last_simulation_ms = 0.0
		return
	var started := Time.get_ticks_usec()
	_rebuild_grid()
	var player_pos := player.global_position
	# En el campamento el jugador es intocable: los enemigos ni le persiguen.
	var hunting := player.is_alive() and not is_in_safe_zone(player_pos)
	var all_types := enemy_types()
	var i := 0
	while i < positions.size():
		var pos := positions[i]
		var r := radii[i]
		var to_player := player_pos - pos
		var dist := to_player.length()
		var reach := r + Player.RADIUS + 2.0
		# Objetivo: el jugador, salvo que un aliado (invocación) esté más a mano o provoque.
		var ally := _pick_ally(pos, dist) if hunting and not allies.is_empty() else -1
		var target_pos := player_pos if ally == -1 else (allies[ally]["pos"] as Vector2)
		var to_target := target_pos - pos
		var tdist := to_target.length()
		var treach := reach if ally == -1 else r + float(allies[ally].get("radius", 12.0)) + 2.0
		var atk: Dictionary = all_types[types[i]].get("attack", {}) if types[i] < all_types.size() else {}
		var kind: String = atk.get("kind", "melee")
		var move := Vector2.ZERO
		# Helado: todo va más lento (movimiento, recarga y preparación de ataques).
		var tempo := (1.0 - Ailments.CHILL_SLOW) if chill_time[i] > 0.0 else 1.0
		cooldowns[i] -= delta * tempo
		flashes[i] = maxf(0.0, flashes[i] - delta)

		if stuns[i] > 0.0:
			stuns[i] -= delta
		elif dashes[i] > 0.0:
			# Embestida: en línea recta, golpea una vez a lo que toque.
			dashes[i] -= delta
			move = attack_dirs[i] * float(atk.get("dash_speed", 600.0)) * tempo
			var half_w := float(atk.get("width", 30.0)) * 0.5
			if dash_hit[i] == 0 and hunting and dist <= reach + half_w:
				dash_hit[i] = 1
				_hit_player(i, damages[i] * float(atk.get("damage_mult", 1.0)))
			elif dash_hit[i] == 0 and _damage_allies_near(pos, r + half_w, damages[i] * float(atk.get("damage_mult", 1.0)), true):
				dash_hit[i] = 1
		elif windups[i] > 0.0:
			windups[i] -= delta * tempo
			if windups[i] <= 0.0 and hunting:
				_resolve_attack(i, atk, target_pos)
				pos = positions[i]   # el teletransporte mueve al enemigo
		elif casting.has(ids[i]):
			var cast: Dictionary = casting[ids[i]]
			cast["time"] -= delta * tempo
			if cast["time"] <= 0.0:
				casting.erase(ids[i])
				if hunting:
					_resolve_ability(i, cast["def"], cast["target"])
		elif hunting and tdist < aggro_range:
			facings[i] = 1.0 if to_target.x < 0.0 else 0.0
			var started_ability := _try_ability(i, delta, dist, player_pos)
			if not started_ability:
				move = _decide(i, atk, kind, to_target, tdist, treach, target_pos) * tempo

		# Separación entre enemigos (rejilla espacial: solo celdas vecinas).
		var push := Vector2.ZERO
		var cell := _cell_of(pos)
		for dx in range(-1, 2):
			for dy in range(-1, 2):
				var bucket = _grid.get(cell + Vector2i(dx, dy))
				if bucket == null:
					continue
				for j: int in bucket:
					if j == i or j >= positions.size():
						continue
					var diff := pos - positions[j]
					var min_dist := r + radii[j]
					var d2 := diff.length_squared()
					if d2 < min_dist * min_dist and d2 > 0.0001:
						var d := sqrt(d2)
						push += diff / d * (min_dist - d)
		# Estáticos (candados...): no se mueven ni se dejan empujar; es el jugador quien choca con ellos.
		if speeds[i] <= 0.0:
			if dist < reach and dist > 0.001:
				player.global_position = pos + to_player / dist * reach
			i += 1
			continue
		# No se meten dentro del jugador.
		if dist < reach and dist > 0.001:
			push -= to_player / dist * (reach - dist)
		var new_pos := pos + move * delta + push * 0.5
		# Ni dentro del campamento.
		if safe_radius > 0.0:
			var from_safe := new_pos - safe_center
			if from_safe.length() < safe_radius + r:
				new_pos = safe_center + from_safe.normalized() * (safe_radius + r)
		for o in obstacles:
			var away := new_pos - Vector2(o.x, o.y)
			var min_d := o.z + r
			if away.length_squared() < min_d * min_d:
				new_pos = Vector2(o.x, o.y) + away.normalized() * min_d
				dashes[i] = 0.0  # una embestida se para al chocar
		new_pos = new_pos.clamp(bounds.position + Vector2(r, r), bounds.end - Vector2(r, r))
		positions[i] = walk_clamp.call(new_pos, r) if walk_clamp.is_valid() else new_pos

		# Cuerpo a cuerpo por contacto (los que no tienen ataque especial).
		if kind == "melee" and stuns[i] <= 0.0 and hunting and cooldowns[i] <= 0.0:
			if ally != -1 and tdist <= treach + 6.0:
				cooldowns[i] = ATTACK_INTERVAL
				_damage_ally(ally, damages[i])
			elif dist <= reach + 6.0:
				cooldowns[i] = ATTACK_INTERVAL
				_hit_player(i, damages[i])
		i += 1
	last_simulation_ms = (Time.get_ticks_usec() - started) / 1000.0


## Aliado al que irá el enemigo en `pos` (o -1 = el jugador): el que provoca
## (golem) dentro de su radio, o uno claramente más cerca que el jugador.
func _pick_ally(pos: Vector2, player_dist: float) -> int:
	var best := -1
	var best_d := INF
	for k in allies.size():
		var a: Dictionary = allies[k]
		if float(a.get("life", 0.0)) <= 0.0:
			continue
		var d := pos.distance_to(a["pos"])
		var taunting := d <= float(a.get("taunt", 0.0))
		if (taunting or d < player_dist * 0.7) and d < best_d:
			best_d = d
			best = k
			if taunting:
				best_d = -1.0   # la provocación gana a cualquier otro
	return best


func _damage_ally(k: int, amount: float) -> void:
	var a: Dictionary = allies[k]
	a["life"] = float(a["life"]) - amount * (1.0 - float(a.get("reduction", 0.0)))
	a["hurt"] = 0.15


## Daña a los aliados a menos de `radius` de `center`. `only_one`: al primero.
func _damage_allies_near(center: Vector2, radius: float, amount: float, only_one := false) -> bool:
	var any := false
	for k in allies.size():
		var a: Dictionary = allies[k]
		if float(a.get("life", 0.0)) > 0.0 and center.distance_to(a["pos"]) <= radius + float(a.get("radius", 12.0)):
			_damage_ally(k, amount)
			any = true
			if only_one:
				return true
	return any


## Movimiento y, si toca, inicio del ataque telegrafiado según el tipo.
## `to_player`/`dist`/`reach`: respecto al objetivo actual (jugador o aliado en `target_pos`).
func _decide(i: int, atk: Dictionary, kind: String, to_player: Vector2, dist: float, reach: float, target_pos: Vector2) -> Vector2:
	var dir := to_player / maxf(dist, 0.001)
	var speed := speeds[i]
	match kind:
		"ranged":
			var keep := float(atk.get("keep_distance", 280.0))
			if dist <= float(atk.get("range", 420.0)) and cooldowns[i] <= 0.0:
				_start_windup(i, atk, dir)
				return Vector2.ZERO
			if dist > keep + 40.0:
				return dir * speed
			if dist < keep - 70.0:
				return -dir * speed * 0.8   # se aleja (kiting)
			return dir.orthogonal() * speed * 0.4 * (1.0 if ids[i] % 2 == 0 else -1.0)  # se mueve de lado
		"summon", "seeker", "lob_pool":
			# A distancia, como los de "ranged"; el invocador no supera su tope de esbirros.
			var keep_d := float(atk.get("keep_distance", 300.0))
			var ready := cooldowns[i] <= 0.0 and dist <= float(atk.get("range", 450.0))
			if ready and kind == "summon" and count_type(String(atk.get("type", "proceso_fantasma"))) >= int(atk.get("max_alive", 8)):
				ready = false
			if ready:
				_start_windup(i, atk, dir)
				if kind == "lob_pool":
					attack_dirs[i] = target_pos   # el charco cae donde estabas
				return Vector2.ZERO
			if dist > keep_d + 40.0:
				return dir * speed
			if dist < keep_d - 70.0:
				return -dir * speed * 0.8
			return dir.orthogonal() * speed * 0.4 * (1.0 if ids[i] % 2 == 0 else -1.0)
		"none":
			return Vector2.ZERO   # candados, torres... no se mueven ni atacan
		"blink":
			# Se teletransporta cerca del jugador cada poco (telegrafiado en el destino).
			if cooldowns[i] <= 0.0 and dist < float(atk.get("range", 600.0)):
				var dest := positions[i] + Vector2.from_angle(randf() * TAU) * randf_range(150.0, float(atk.get("jump", 380.0)))
				if walk_clamp.is_valid():
					dest = walk_clamp.call(dest, radii[i])
				attack_dirs[i] = dest
				windups[i] = float(atk.get("windup", 0.5))
				cooldowns[i] = float(atk.get("cooldown", 2.5)) + windups[i]
				return Vector2.ZERO
			return dir * speed if dist > reach else Vector2.ZERO
		"charge", "slam", "cone":
			var trigger := float(atk.get("range", 120.0))
			if dist <= trigger and cooldowns[i] <= 0.0:
				_start_windup(i, atk, dir)
				return Vector2.ZERO
			if dist > reach:
				return dir * speed
			return Vector2.ZERO
	# Cuerpo a cuerpo normal: persigue hasta tocar.
	return dir * speed if dist > reach else Vector2.ZERO


func _start_windup(i: int, atk: Dictionary, dir: Vector2) -> void:
	windups[i] = float(atk.get("windup", 0.5))
	attack_dirs[i] = dir
	cooldowns[i] = float(atk.get("cooldown", 2.5)) + windups[i]


## Fin del telegrafiado: se comprueba la forma del golpe contra el jugador.
func _resolve_attack(i: int, atk: Dictionary, player_pos: Vector2) -> void:
	var pos := positions[i]
	var damage := damages[i] * float(atk.get("damage_mult", 1.0))
	var dir := attack_dirs[i]
	match String(atk.get("kind", "melee")):
		"blink":
			_flashes_fx.append({"type": "circle", "pos": pos, "radius": radii[i] + 10.0, "time": 0.0, "color": Color(atk.get("color", "c08aff"))})
			positions[i] = attack_dirs[i]
			_flashes_fx.append({"type": "circle", "pos": positions[i], "radius": radii[i] + 14.0, "time": 0.0, "color": Color(atk.get("color", "c08aff"))})
		"ranged":
			var count := int(atk.get("projectiles", 1))
			var spread := deg_to_rad(float(atk.get("spread", 0.0)))
			# Apunta a donde está ahora el jugador (el telegrafiado avisa, no persigue).
			var aim := (player_pos - pos).normalized()
			for k in count:
				var angle := 0.0 if count == 1 else lerpf(-spread / 2.0, spread / 2.0, float(k) / (count - 1))
				var shot := {"pos": pos, "vel": aim.rotated(angle) * float(atk.get("projectile_speed", 360.0)),
					"damage": damage, "radius": float(atk.get("projectile_radius", 7.0)), "life": 2.5,
					"color": Color(atk.get("color", "e0c040"))}
				for aid in traits[i].get("affixes", []):
					var adot: Dictionary = affix_defs().get(aid, {}).get("on_hit", {}).get("dot", {})
					if not adot.is_empty() and not atk.has("dot"):
						shot["dot_dps"] = damages[i] * float(adot.get("dps_mult", 0.3))
						shot["dot_time"] = float(adot.get("duration", 3.0))
						shot["dot_kind"] = String(adot.get("kind", "chaos"))
				var shot_status := _status_of(i)
				if not shot_status.is_empty():
					shot["status"] = shot_status
				if atk.has("dot"):   # proyectil que quema/corrompe: sigue haciendo daño después
					var dot: Dictionary = atk["dot"]
					shot["dot_dps"] = damages[i] * float(dot.get("dps_mult", 0.4))
					shot["dot_time"] = float(dot.get("duration", 4.0))
					shot["dot_kind"] = String(dot.get("kind", "fire"))
				projectiles.append(shot)
		"summon":
			var t_index := type_index_of(String(atk.get("type", "proceso_fantasma")))
			for k in int(atk.get("count", 2)):
				var sp := pos + Vector2.from_angle(TAU * k / maxf(1.0, float(atk.get("count", 2))) + randf()) * (radii[i] + 40.0)
				if walk_clamp.is_valid():
					sp = walk_clamp.call(sp, 12.0)
				spawn(sp, Rarity.Enemy.NORMAL, t_index)
			_flashes_fx.append({"type": "circle", "pos": pos, "radius": radii[i] + 34.0, "time": 0.0, "color": Color(atk.get("color", "7a4ad9"))})
		"seeker":
			var aim_s := (player_pos - pos).normalized()
			var n := int(atk.get("projectiles", 1))
			for k in n:
				var a := 0.0 if n == 1 else lerpf(-0.6, 0.6, float(k) / (n - 1))
				projectiles.append(_seeker_orb(pos, aim_s.rotated(a), damage, atk))
				var orb_status := _status_of(i)
				if not orb_status.is_empty():
					projectiles[projectiles.size() - 1]["status"] = orb_status
		"lob_pool":
			pools.append({"pos": attack_dirs[i], "radius": float(atk.get("radius", 70.0)), "life": float(atk.get("pool_time", 5.0)),
				"total": float(atk.get("pool_time", 5.0)), "dps": damages[i] * float(atk.get("dps_mult", 0.6)),
				"kind": String(atk.get("dot_kind", "chaos")), "color": Color(atk.get("color", "6fd36b"))})
			_flashes_fx.append({"type": "circle", "pos": attack_dirs[i], "radius": float(atk.get("radius", 70.0)), "time": 0.0, "color": Color(atk.get("color", "6fd36b"))})
		"charge":
			dashes[i] = float(atk.get("dash_time", 0.5))
			dash_hit[i] = 0
		"slam":
			var radius := float(atk.get("radius", 100.0))
			_flashes_fx.append({"type": "circle", "pos": pos, "radius": radius, "time": 0.0, "color": Color(atk.get("color", "c86030"))})
			if pos.distance_to(player.global_position) <= radius + Player.RADIUS:
				_hit_player(i, damage)
			_damage_allies_near(pos, radius, damage)
			if atk.has("pool"):   # el golpe deja un charco (condensador que revienta)
				var pd: Dictionary = atk["pool"]
				pools.append({"pos": pos, "radius": radius * 0.8, "life": float(pd.get("time", 4.0)), "total": float(pd.get("time", 4.0)),
					"dps": damages[i] * float(pd.get("dps_mult", 0.4)), "kind": String(pd.get("kind", "chaos")), "color": Color(atk.get("color", "d0b040"))})
		"cone":
			var radius := float(atk.get("range", 160.0)) + 20.0
			var half := deg_to_rad(float(atk.get("angle", 60.0))) / 2.0
			_flashes_fx.append({"type": "cone", "pos": pos, "dir": dir, "radius": radius, "half": half, "time": 0.0,
				"color": Color(atk.get("color", "e0652f"))})
			var to := player.global_position - pos
			if to.length() <= radius + Player.RADIUS and absf(dir.angle_to(to)) <= half + 0.15:
				_hit_player(i, damage)
			for k in allies.size():
				var to_ally: Vector2 = allies[k]["pos"] - pos
				if to_ally.length() <= radius + 12.0 and absf(dir.angle_to(to_ally)) <= half + 0.15:
					_damage_ally(k, damage)


# --- Habilidades especiales (jefes) ---

func _try_ability(i: int, delta: float, dist: float, player_pos: Vector2) -> bool:
	var list: Array = abilities.get(ids[i], [])
	if list.is_empty():
		return false
	# Furia: por debajo de la mitad de vida, todo se recarga más rápido.
	var rate := 1.4 if lives[i] < max_lives[i] * 0.5 else 1.0
	for a in list:
		a["timer"] -= delta * rate
	var life_fraction := lives[i] / max_lives[i]
	for a in list:
		var d: Dictionary = a["def"]
		if life_fraction > float(d.get("max_life", 1.01)) or life_fraction <= float(d.get("min_life", -1.0)):
			continue   # habilidad de otra fase
		if a["timer"] <= 0.0 and dist < float(d.get("range", 700.0)):
			a["timer"] = float(a["def"].get("cooldown", 6.0))
			var windup := float(a["def"].get("windup", 0.8))
			casting[ids[i]] = {"def": a["def"], "time": windup, "total": windup, "target": player_pos}
			return true
	return false


func _resolve_ability(i: int, def: Dictionary, target: Vector2) -> void:
	var pos := positions[i]
	var damage := damages[i] * float(def.get("damage_mult", 1.0))
	match String(def.get("kind", "")):
		"projectile_nova":
			var count := int(def.get("count", 12))
			var offset := randf() * TAU
			for k in count:
				var dir := Vector2.from_angle(offset + TAU * k / count)
				projectiles.append({"pos": pos + dir * radii[i], "vel": dir * float(def.get("speed", 300.0)),
					"damage": damage, "radius": float(def.get("projectile_radius", 9.0)), "life": 3.5,
					"color": Color(def.get("color", "ff5050"))})
		"ground_marks":
			var count := int(def.get("count", 4))
			var spread := float(def.get("spread", 150.0))
			for k in count:
				var p := target if k == 0 else target + Vector2.from_angle(randf() * TAU) * randf_range(spread * 0.4, spread)
				hazards.append({"pos": p, "radius": float(def.get("radius", 90.0)), "time": 0.0,
					"delay": float(def.get("delay", 1.0)) + k * 0.12, "damage": damage, "color": Color(def.get("color", "ff8c2a"))})
		"summon":
			var type_index := type_index_of(def.get("type", "bug"))
			var count := int(def.get("count", 3))
			for k in count:
				var p := pos + Vector2.from_angle(TAU * k / maxf(1.0, count) + randf()) * (radii[i] + 60.0)
				if walk_clamp.is_valid():
					p = walk_clamp.call(p, 12.0)
				spawn(p, Rarity.Enemy.NORMAL, type_index, def.get("summon_name", ""), float(def.get("summon_life", 1.0)))
		"seeker_nova":
			# Orbes lentos en todas direcciones que luego persiguen al jugador.
			var n := int(def.get("count", 6))
			var off := randf() * TAU
			for k in n:
				projectiles.append(_seeker_orb(pos, Vector2.from_angle(off + TAU * k / n), damage, def))
		"pool_marks":
			# Marcas en el suelo que, al caer, dejan charcos de daño degenerativo.
			var n := int(def.get("count", 4))
			var spread := float(def.get("spread", 180.0))
			for k in n:
				var mp := target if k == 0 else target + Vector2.from_angle(randf() * TAU) * randf_range(spread * 0.3, spread)
				hazards.append({"pos": mp, "radius": float(def.get("radius", 80.0)), "time": 0.0,
					"delay": float(def.get("delay", 0.9)) + k * 0.15, "damage": damage, "color": Color(def.get("color", "6fd36b")),
					"pool": {"dps": damages[i] * float(def.get("dps_mult", 0.5)), "time": float(def.get("pool_time", 5.0)),
						"kind": String(def.get("dot_kind", "chaos"))}})
		"oom_beam":
			# OOM Killer: un rayo desde un núcleo de la CPU a través del jugador.
			# Si al disparar atraviesa al propio jefe, se lo come él.
			var cores: Array = def.get("cores", [])
			for k in int(def.get("count", 1)):
				var core: Vector2 = Vector2(cores[k % cores.size()][0], cores[k % cores.size()][1]) if not cores.is_empty() else pos
				var dir := (target - core).normalized()
				if dir == Vector2.ZERO:
					dir = Vector2.RIGHT
				hazards.append({"kind": "beam", "pos": core, "dir": dir, "length": float(def.get("length", 2600.0)),
					"radius": float(def.get("width", 60.0)) * 0.5, "time": 0.0, "delay": float(def.get("delay", 1.4)) + k * 0.35,
					"damage": damage, "color": Color(def.get("color", "e0e040")), "boss_id": ids[i],
					"self_damage": float(def.get("self_damage", 0.08))})


func _update_projectiles(delta: float) -> void:
	if projectiles.is_empty():
		return
	var still: Array[Dictionary] = []
	for pr in projectiles:
		if pr.has("homing") and player:
			# Orbe perseguidor: gira poco a poco hacia el jugador (se le puede esquivar tras una cobertura).
			var want: Vector2 = (player.global_position - pr["pos"]).normalized()
			var vel: Vector2 = pr["vel"]
			var turn := clampf(vel.angle_to(want), -float(pr["homing"]) * delta, float(pr["homing"]) * delta)
			pr["vel"] = vel.rotated(turn)
		pr["pos"] += pr["vel"] * delta
		pr["life"] -= delta
		var p: Vector2 = pr["pos"]
		var gone: bool = pr["life"] <= 0.0
		if not gone and player and player.is_alive() and p.distance_to(player.global_position) <= pr["radius"] + Player.RADIUS:
			player.take_damage(pr["damage"])
			if pr.has("status"):
				apply_status_to_player(pr["status"])
			if pr.has("dot_dps"):
				player.apply_dot("golpe_%d" % (randi() % 3), pr["dot_dps"], pr["dot_time"], pr.get("dot_kind", "fire"))
			_flashes_fx.append({"type": "circle", "pos": p, "radius": 16.0, "time": 0.0, "color": pr["color"]})
			gone = true
		if not gone and not allies.is_empty() and _damage_allies_near(p, pr["radius"], pr["damage"], true):
			_flashes_fx.append({"type": "circle", "pos": p, "radius": 16.0, "time": 0.0, "color": pr["color"]})
			gone = true
		if not gone:
			for o in obstacles:
				if p.distance_squared_to(Vector2(o.x, o.y)) < o.z * o.z:
					gone = true
					break
		if not gone and walk_clamp.is_valid() and walk_clamp.call(p, 0.0) != p:
			gone = true
		if not gone:
			still.append(pr)
	projectiles = still


## Charcos: mientras el jugador esté dentro, se renueva un daño degenerativo corto.
func _update_pools(delta: float) -> void:
	if pools.is_empty():
		return
	var still: Array[Dictionary] = []
	for pool in pools:
		pool["life"] -= delta
		if pool["life"] <= 0.0:
			continue
		if player and player.is_alive() and (pool["pos"] as Vector2).distance_to(player.global_position) <= pool["radius"] + Player.RADIUS * 0.5:
			player.apply_dot("charco", pool["dps"], 0.6, pool["kind"])
		still.append(pool)
	pools = still


## Orbe lento y persistente que persigue al jugador (centinelas y jefe del acto III).
func _seeker_orb(pos: Vector2, dir: Vector2, damage: float, def: Dictionary) -> Dictionary:
	return {"pos": pos + dir * 20.0, "vel": dir * float(def.get("projectile_speed", def.get("speed", 130.0))),
		"damage": damage, "radius": float(def.get("projectile_radius", 11.0)), "life": float(def.get("projectile_life", 7.0)),
		"color": Color(def.get("color", "5cd0ff")), "homing": float(def.get("turn_rate", 2.0)), "orb": true}


func _update_hazards(delta: float) -> void:
	for fx in _flashes_fx:
		fx["time"] += delta
	_flashes_fx.assign(_flashes_fx.filter(func(fx: Dictionary) -> bool: return fx["time"] < 0.25))
	if hazards.is_empty():
		return
	var still: Array[Dictionary] = []
	for h in hazards:
		h["time"] += delta
		if h["time"] < h["delay"]:
			still.append(h)
			continue
		if h.get("kind", "") == "beam":
			_resolve_beam(h)
			continue
		_flashes_fx.append({"type": "circle", "pos": h["pos"], "radius": h["radius"], "time": 0.0, "color": h["color"]})
		if player and player.is_alive() and h["pos"].distance_to(player.global_position) <= h["radius"] + Player.RADIUS:
			player.take_damage(h["damage"])
		_damage_allies_near(h["pos"], h["radius"], h["damage"])
		if h.has("pool"):
			var pool: Dictionary = h["pool"]
			pools.append({"pos": h["pos"], "radius": h["radius"], "life": pool["time"], "total": pool["time"], "dps": pool["dps"],
				"kind": pool["kind"], "color": h["color"]})
	hazards = still


func _resolve_beam(h: Dictionary) -> void:
	var a: Vector2 = h["pos"]
	var b: Vector2 = a + h["dir"] * h["length"]
	_flashes_fx.append({"type": "beam", "pos": a, "end": b, "radius": h["radius"], "time": 0.0, "color": h["color"]})
	if player and player.is_alive():
		var p := Geometry2D.get_closest_point_to_segment(player.global_position, a, b)
		if p.distance_to(player.global_position) <= h["radius"] + Player.RADIUS:
			player.take_damage(h["damage"])
	var bi := index_of(h["boss_id"])
	if bi != -1:
		var q := Geometry2D.get_closest_point_to_segment(positions[bi], a, b)
		if q.distance_to(positions[bi]) <= h["radius"] + radii[bi]:
			# El OOM Killer elige al proceso que más pesa... el propio jefe.
			lives[bi] -= max_lives[bi] * float(h["self_damage"])
			flashes[bi] = FLASH_TIME * 3.0
			if lives[bi] <= 0.0:
				_kill(bi)

func _process(_delta: float) -> void:
	var n := positions.size()
	if n > _multimesh.instance_count:
		_multimesh.instance_count = maxi(n, _multimesh.instance_count * 2)
	_multimesh.visible_instance_count = n
	var all_types := enemy_types()
	for i in n:
		var t: Dictionary = all_types[types[i]] if types[i] < all_types.size() else {}
		var size := radii[i] * 2.0 * SPRITE_SCALE * float(t.get("scale", 1.0))
		_multimesh.set_instance_transform_2d(i,
			Transform2D(0.0, Vector2(size, size), 0.0, positions[i] - Vector2(0.0, size * 0.22)))
		var outline := Rarity.enemy_color(rarities[i])
		outline.a = 0.0 if rarities[i] == Rarity.Enemy.NORMAL else 1.0
		_multimesh.set_instance_color(i, outline)
		_multimesh.set_instance_custom_data(i, Color(t.get("sprite_row", 0), phases[i], facings[i], flashes[i] / FLASH_TIME))
	queue_redraw()


## Telegrafiados, proyectiles enemigos, barras de vida (solo heridos o no
## normales), nombres de élites y únicos, aturdimientos y lanzamientos.
func _draw() -> void:
	var font := ThemeDB.fallback_font
	_draw_attacks(font)
	var tt := Time.get_ticks_msec() / 1000.0
	for i in positions.size():
		if stuns[i] > 0.0 and freeze_time[i] <= 0.0:
			_draw_stun(positions[i] + Vector2(0, -radii[i] * SPRITE_SCALE * 1.1 - 18.0))
		_draw_ailment_fx(i, tt)
		_draw_affix_fx(i, tt)
		if phase_shield.has(ids[i]):
			var shield_pulse := 0.5 + 0.5 * sin(tt * 14.0)
			draw_arc(positions[i], radii[i] * 2.0, 0.0, TAU, 32, Color(0.6, 0.85, 1.0, 0.5 + 0.4 * shield_pulse), 4.0, true)
		if immune[i] == 1:
			var pulse := 0.5 + 0.5 * sin(Time.get_ticks_msec() / 120.0)
			draw_arc(positions[i], radii[i] * 1.7, 0.0, TAU, 32, Color(0.6, 0.8, 1.0, 0.4 + 0.4 * pulse), 3.0, true)
		var rarity := rarities[i]
		var r := radii[i]
		var w := maxf(r * 2.0, 30.0)
		var top := positions[i] + Vector2(-w / 2.0, -r * SPRITE_SCALE * 1.1 - 8.0)
		var has_bar := not (rarity == Rarity.Enemy.NORMAL and lives[i] >= max_lives[i])
		# Iconos de estados encima de la barra (o donde iría).
		var states := ailments_of(i)
		if not states.is_empty():
			var side := 11.0
			var x0 := positions[i].x - (states.size() * (side + 2.0) - 2.0) / 2.0
			for k in states.size():
				StatusIcon.draw(self, Rect2(x0 + k * (side + 2.0), top.y - side - 3.0, side, side), states[k]["id"], true)
		if not has_bar:
			continue
		draw_rect(Rect2(top - Vector2(1, 1), Vector2(w + 2.0, 6.0)), Color(0, 0, 0, 0.75))
		var frac := lives[i] / max_lives[i]
		var bar_color := Color("c83232")
		if poison_time[i] > 0.0:
			bar_color = Color("4fa04a")
		elif freeze_time[i] > 0.0 or chill_time[i] > 0.0:
			bar_color = Color("5a9ad0")
		draw_rect(Rect2(top, Vector2(w * frac, 4.0)), bar_color)
		draw_rect(Rect2(top, Vector2(w * frac, 1.0)), Color(1, 1, 1, 0.25))
		if rarity >= Rarity.Enemy.ELITE:
			var name_y := -6.0 - (14.0 if not states.is_empty() else 0.0)
			draw_string_outline(font, top + Vector2(-80.0, name_y), names[i], HORIZONTAL_ALIGNMENT_CENTER, w + 160.0, 14, 4, Color(0, 0, 0, 0.8))
			draw_string(font, top + Vector2(-80.0, name_y), names[i], HORIZONTAL_ALIGNMENT_CENTER,
				w + 160.0, 14, Rarity.enemy_color(rarity))


const TELEGRAPH := Color(1.0, 0.25, 0.2)


func _draw_attacks(font: Font) -> void:
	var all_types := enemy_types()
	for i in positions.size():
		var atk: Dictionary = all_types[types[i]].get("attack", {}) if types[i] < all_types.size() else {}
		var pos := positions[i]
		var dir := attack_dirs[i]
		if windups[i] > 0.0:
			var total := maxf(0.05, float(atk.get("windup", 0.5)))
			var t := clampf(1.0 - windups[i] / total, 0.0, 1.0)
			match String(atk.get("kind", "")):
				"slam":
					var radius := float(atk.get("radius", 100.0))
					draw_circle(pos, radius, Color(TELEGRAPH, 0.10))
					draw_circle(pos, radius * t, Color(TELEGRAPH, 0.22))
					draw_arc(pos, radius, 0.0, TAU, 40, Color(TELEGRAPH, 0.7), 2.0, true)
				"cone":
					var radius := float(atk.get("range", 160.0)) + 20.0
					var half := deg_to_rad(float(atk.get("angle", 60.0))) / 2.0
					draw_colored_polygon(_cone_points(pos, dir, radius, half), Color(TELEGRAPH, 0.10))
					if t > 0.03:
						draw_colored_polygon(_cone_points(pos, dir, radius * t, half), Color(TELEGRAPH, 0.22))
					var outline := _cone_points(pos, dir, radius, half)
					outline.append(outline[0])
					draw_polyline(outline, Color(TELEGRAPH, 0.7), 2.0, true)
				"charge":
					var length := float(atk.get("dash_speed", 600.0)) * float(atk.get("dash_time", 0.5))
					var w := float(atk.get("width", 30.0)) + radii[i]
					var side := dir.orthogonal() * w * 0.5
					draw_colored_polygon(PackedVector2Array([pos + side, pos + side + dir * length, pos - side + dir * length, pos - side]), Color(TELEGRAPH, 0.10))
					draw_colored_polygon(PackedVector2Array([pos + side, pos + side + dir * length * t, pos - side + dir * length * t, pos - side]), Color(TELEGRAPH, 0.22))
				"blink":
					var dest := attack_dirs[i]
					draw_arc(dest, radii[i] + 6.0, 0.0, TAU, 24, Color(Color(atk.get("color", "c08aff")), 0.4 + 0.5 * t), 2.0, true)
					draw_circle(dest, (radii[i] + 6.0) * t, Color(Color(atk.get("color", "c08aff")), 0.2))
				"summon":
					# Círculo de invocación con runas de código girando.
					var sc := Color(atk.get("color", "7a4ad9"))
					draw_arc(pos, radii[i] + 30.0, 0.0, TAU, 32, Color(sc, 0.3 + 0.5 * t), 2.0, true)
					for k in 6:
						var ra := TAU * k / 6.0 + t * 3.0
						draw_string(font, pos + Vector2.from_angle(ra) * (radii[i] + 30.0) + Vector2(-4, 4), "#$%&{}"[k], HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(sc, 0.4 + 0.6 * t))
				"seeker":
					var oc := Color(atk.get("color", "5cd0ff"))
					draw_circle(pos + dir * (radii[i] + 8.0), 4.0 + 8.0 * t, Color(oc, 0.35))
					draw_circle(pos + dir * (radii[i] + 8.0), 2.0 + 4.0 * t, oc)
				"lob_pool":
					var target: Vector2 = attack_dirs[i]
					var pr_radius := float(atk.get("radius", 70.0))
					var lc := Color(atk.get("color", "6fd36b"))
					draw_circle(target, pr_radius, Color(lc, 0.08))
					draw_circle(target, pr_radius * t, Color(lc, 0.2))
					draw_arc(target, pr_radius, 0.0, TAU, 32, Color(lc, 0.7), 2.0, true)
					var arc_top := pos.lerp(target, t) + Vector2(0, -sin(t * PI) * 90.0)
					draw_circle(arc_top, 6.0, lc)
				"ranged":
					draw_line(pos, pos + dir * 60.0, Color(Color(atk.get("color", "e0c040")), 0.6 * t), 2.0, true)
					draw_circle(pos + dir * (radii[i] + 4.0), 3.0 + 4.0 * t, Color(atk.get("color", "e0c040")))
		if casting.has(ids[i]):
			var cast: Dictionary = casting[ids[i]]
			var def: Dictionary = cast["def"]
			var t: float = 1.0 - cast["time"] / maxf(0.05, cast["total"])
			var label: String = "¡%s!" % def.get("name", "")
			var top := pos + Vector2(-150.0, -radii[i] * SPRITE_SCALE * 1.1 - 40.0)
			draw_string_outline(font, top, label, HORIZONTAL_ALIGNMENT_CENTER, 300.0, 18, 5, Color.BLACK)
			draw_string(font, top, label, HORIZONTAL_ALIGNMENT_CENTER, 300.0, 18, Color(def.get("color", "ff8c2a")))
			draw_arc(pos, radii[i] + 10.0, -PI / 2.0, -PI / 2.0 + TAU * t, 40, Color(def.get("color", "ff8c2a")), 3.0, true)
	# Charcos de daño degenerativo: burbujean y se desvanecen al final.
	var now := Time.get_ticks_msec() / 1000.0
	for pool in pools:
		var fade: float = clampf(pool["life"] / 0.8, 0.0, 1.0)
		var pc: Color = pool["color"]
		var pp: Vector2 = pool["pos"]
		draw_set_transform(pp, 0.0, Vector2(1.0, 0.6))
		draw_circle(Vector2.ZERO, pool["radius"], Color(pc, 0.22 * fade))
		draw_circle(Vector2.ZERO, pool["radius"] * 0.7, Color(pc, 0.18 * fade))
		draw_arc(Vector2.ZERO, pool["radius"], 0.0, TAU, 32, Color(pc, 0.55 * fade), 2.0, true)
		draw_set_transform(Vector2.ZERO)
		for k in 4:
			var ph := fmod(now * 0.9 + k * 0.25 + pp.x * 0.01, 1.0)
			var bp := pp + Vector2(cos(k * 1.9) * pool["radius"] * 0.5, sin(k * 2.7) * pool["radius"] * 0.25)
			draw_circle(bp + Vector2(0, -ph * 10.0), 2.0 + ph * 3.0, Color(pc.lightened(0.3), 0.6 * (1.0 - ph) * fade))
	for h in hazards:
		var t: float = clampf(h["time"] / h["delay"], 0.0, 1.0)
		var c: Color = h["color"]
		if h.get("kind", "") == "beam":
			var b: Vector2 = h["pos"] + h["dir"] * h["length"]
			draw_line(h["pos"], b, Color(c, 0.10), h["radius"] * 2.0)
			draw_line(h["pos"], b, Color(c, 0.25 + 0.5 * t), 2.0 + 4.0 * t, true)
			continue
		draw_circle(h["pos"], h["radius"], Color(c, 0.10))
		draw_circle(h["pos"], h["radius"] * t, Color(c, 0.25))
		draw_arc(h["pos"], h["radius"], 0.0, TAU, 40, Color(c, 0.8), 2.0, true)
	for fx in _flashes_fx:
		var a: float = 1.0 - fx["time"] / 0.25
		var c: Color = fx["color"]
		if fx["type"] == "beam":
			draw_line(fx["pos"], fx["end"], Color(c, 0.7 * a), fx["radius"] * 2.0)
			draw_line(fx["pos"], fx["end"], Color(1, 1, 1, 0.8 * a), fx["radius"] * 0.5)
			continue
		if fx["type"] == "cone":
			draw_colored_polygon(_cone_points(fx["pos"], fx["dir"], fx["radius"], fx["half"]), Color(c, 0.45 * a))
		else:
			draw_circle(fx["pos"], fx["radius"], Color(c, 0.45 * a))
	for pr in projectiles:
		var c: Color = pr["color"]
		if pr.has("orb"):
			# Orbe perseguidor: halo que pulsa y se apaga al final de su vida.
			var life_fade: float = clampf(pr["life"] / 1.0, 0.25, 1.0)
			var pulse := 0.5 + 0.5 * sin(now * 8.0 + pr["pos"].x * 0.05)
			draw_circle(pr["pos"], pr["radius"] * (1.6 + 0.3 * pulse), Color(c, 0.18 * life_fade))
			draw_circle(pr["pos"], pr["radius"], Color(c, 0.85 * life_fade))
			draw_circle(pr["pos"], pr["radius"] * 0.4, Color(1, 1, 1, 0.9 * life_fade))
			continue
		var dir: Vector2 = pr["vel"].normalized()
		draw_line(pr["pos"] - dir * 16.0, pr["pos"], Color(c, 0.45), pr["radius"], true)
		draw_circle(pr["pos"], pr["radius"], c)
		draw_circle(pr["pos"], pr["radius"] * 0.45, Color.WHITE)


static func _cone_points(origin: Vector2, dir: Vector2, radius: float, half: float) -> PackedVector2Array:
	var pts := PackedVector2Array([origin])
	for k in 13:
		pts.append(origin + dir.rotated(lerpf(-half, half, k / 12.0)) * radius)
	return pts


## Efectos visuales baratos de cada estado sobre el enemigo.
func _draw_ailment_fx(i: int, tt: float) -> void:
	var p := positions[i]
	var r := radii[i]
	var jitter := ids[i] * 0.37
	if dot_time[i] > 0.0:
		# Burbujas de corrupción.
		for k in 3:
			var ph := fmod(tt * 1.2 + k / 3.0 + jitter, 1.0)
			draw_circle(p + Vector2((k - 1) * r * 0.5, -r - ph * 16.0), 2.5, Color(0.7, 0.3, 0.9, 0.8 * (1.0 - ph)))
	if poison_time[i] > 0.0:
		for k in 3:
			var ph := fmod(tt * 1.0 + k / 3.0 + jitter + 0.5, 1.0)
			draw_circle(p + Vector2((k - 1) * r * 0.6 + sin(tt * 3.0 + k) * 2.0, -r * 0.4 - ph * 18.0), 2.0 + ph * 1.5, Color(0.45, 0.9, 0.4, 0.75 * (1.0 - ph)))
	if burn_time[i] > 0.0:
		# Lenguas de fuego que suben.
		for k in 4:
			var ph := fmod(tt * 1.8 + k / 4.0 + jitter, 1.0)
			var q := p + Vector2((k - 1.5) * r * 0.45, -r * 0.2 - ph * r * 1.6)
			draw_circle(q, (1.0 - ph) * 4.5, Color(1.0, 0.45 + 0.4 * ph, 0.1, 0.8 * (1.0 - ph)))
	if bleed_time[i] > 0.0:
		for k in 2:
			var ph := fmod(tt * 1.4 + k * 0.5 + jitter, 1.0)
			var q := p + Vector2((k - 0.5) * r * 0.8, -r * 0.3 + ph * r * 1.1)
			draw_circle(q, 2.2 * (1.0 - ph * 0.5), Color(0.8, 0.08, 0.1, 0.9 * (1.0 - ph)))
	if shock_time[i] > 0.0:
		_draw_shock_fx(p, r, tt, jitter)
	if freeze_time[i] > 0.0 or chill_time[i] > 0.0:
		_draw_frost_fx(p, r, tt, jitter, freeze_time[i] > 0.0)


## Electrocutado: arcos que no paran, un resplandor amarillo y chispas que saltan.
func _draw_shock_fx(p: Vector2, r: float, tt: float, jitter: float) -> void:
	var c := p + Vector2(0, -r * 0.4)
	draw_circle(c, r * 1.25, Color(1.0, 0.95, 0.4, 0.10 + 0.06 * sin(tt * 18.0 + jitter)))
	for k in 3:  # tres arcos persistentes, cada uno cambia de forma ~10 veces por segundo
		var seed_t := floorf(tt * 10.0 + k * 3.0 + jitter)
		var a := fposmod(seed_t * 2.399 + k * 2.1, TAU)
		var from := c + Vector2.from_angle(a) * r * 0.5
		var to := c + Vector2.from_angle(a + 0.9 + fposmod(seed_t * 1.7, 1.2)) * r * 1.3
		var pts := PackedVector2Array([from])
		for s in 1:
			var mid := from.lerp(to, 0.5) + (to - from).orthogonal().normalized() * (fposmod(seed_t * 3.1, 1.0) - 0.5) * r
			pts.append(mid)
		pts.append(to)
		draw_polyline(pts, Color(1.0, 0.95, 0.5, 0.9), 1.8, true)
		draw_circle(to, 1.8, Color(1.0, 1.0, 0.8, 0.9))
	for k in 4:  # chispas sueltas que se apagan
		var ph := fposmod(tt * 2.3 + k * 0.25 + jitter, 1.0)
		var dir := Vector2.from_angle(k * 1.7 + floorf(tt * 2.3 + k * 0.25 + jitter) * 0.9)
		draw_circle(c + dir * r * (0.8 + ph * 0.9), 1.5 * (1.0 - ph), Color(1.0, 0.95, 0.4, 1.0 - ph))


## Helado/congelado: escarcha que cubre el sprite, copos que caen y cristales en la base.
func _draw_frost_fx(p: Vector2, r: float, tt: float, jitter: float, frozen: bool) -> void:
	var c := p + Vector2(0, -r * 0.45)
	var cover := PackedVector2Array()
	for k in 18:  # silueta irregular de escarcha sobre el cuerpo
		var a := TAU * k / 18.0
		var wob := 1.0 + 0.08 * sin(a * 5.0 + jitter)
		cover.append(c + Vector2(cos(a) * r * 1.05 * wob, sin(a) * r * 1.5 * wob))
	draw_colored_polygon(cover, Color(0.72, 0.92, 1.0, 0.42 if frozen else 0.2))
	# Cristales de la base (más altos y claros si está congelado).
	var n := 7 if frozen else 4
	for k in n:
		var bx := (float(k) / (n - 1) - 0.5) * r * 2.2
		var h := r * (0.5 + 0.5 * fposmod(sin(k * 12.9898 + jitter) * 43758.5, 1.0)) * (1.5 if frozen else 0.8)
		var base := p + Vector2(bx, r * 0.5)
		draw_colored_polygon(PackedVector2Array([base + Vector2(-3, 0), base + Vector2(0, -h), base + Vector2(3, 0)]),
			Color(0.82, 0.96, 1.0, 0.85 if frozen else 0.6))
	if frozen:
		draw_polyline(cover + PackedVector2Array([cover[0]]), Color(0.88, 0.98, 1.0, 0.9), 1.5, true)
	else:
		draw_set_transform(p + Vector2(0, r * 0.5), 0.0, Vector2(1.0, 0.45))
		draw_arc(Vector2.ZERO, r * 1.3, 0.0, TAU, 20, Color(0.55, 0.8, 1.0, 0.7), 2.0, true)
		draw_set_transform(Vector2.ZERO)
	for k in 3:  # copos que caen
		var ph := fposmod(tt * 0.8 + k / 3.0 + jitter, 1.0)
		var q := c + Vector2((k - 1) * r * 0.7 + sin(tt * 2.0 + k) * 3.0, -r * 1.5 + ph * r * 2.4)
		draw_circle(q, 1.6, Color(0.9, 0.98, 1.0, 0.9 * (1.0 - ph * 0.6)))


## Aro de color por afijo, girando alrededor del enemigo.
func _draw_affix_fx(i: int, tt: float) -> void:
	var aff: Array = traits[i].get("affixes", [])
	if aff.is_empty():
		return
	var k := 0
	if float(traits[i].get("shield", 0.0)) > 0.0:
		draw_arc(positions[i] + Vector2(0, -radii[i] * 0.4), radii[i] * 1.5, 0.0, TAU, 28, Color(0.55, 0.8, 1.0, 0.6), 3.0, true)
	for aid in aff:
		var c := Color(affix_defs().get(aid, {}).get("color", "ffffff"))
		var radius := radii[i] * 1.55 + k * 4.0
		var a0 := tt * (1.6 + k * 0.5) + ids[i]
		draw_set_transform(positions[i] + Vector2(0, radii[i] * 0.5), 0.0, Vector2(1.0, 0.5))
		for q in 3:
			draw_arc(Vector2.ZERO, radius, a0 + TAU * q / 3.0, a0 + TAU * q / 3.0 + 1.3, 10, Color(c, 0.85), 2.5, true)
		draw_set_transform(Vector2.ZERO)
		k += 1


func _draw_stun(p: Vector2) -> void:
	# Candado girando: proceso bloqueado.
	var a := Time.get_ticks_msec() / 300.0
	for k in 3:
		var q := p + Vector2.from_angle(a + TAU * k / 3.0) * Vector2(12, 5)
		draw_circle(q, 2.5, Color("7fb8e0"))
	draw_rect(Rect2(p + Vector2(-5, -3), Vector2(10, 8)), Color("c8c8d0"))
	draw_arc(p + Vector2(0, -3), 4.0, PI, TAU, 8, Color("c8c8d0"), 2.0)


func _kill(i: int) -> void:
	var rarity := rarities[i]
	var info: Dictionary = Rarity.ENEMY_INFO[rarity]
	var types_list := enemy_types()
	var type_mult: float = types_list[types[i]].get("xp_mult", 1.0) if types[i] < types_list.size() else 1.0
	var xp := int(BASE_EXPERIENCE * info.xp_mult * type_mult * (1.0 + 0.15 * (area_level - 1)))
	var pos := positions[i]
	var type_id: String = types_list[types[i]]["id"] if types[i] < types_list.size() else ""
	for aid in traits[i].get("affixes", []):
		var boom: Dictionary = affix_defs().get(aid, {}).get("death_explosion", {})
		if not boom.is_empty():
			hazards.append({"pos": pos, "radius": float(boom.get("radius", 100.0)), "time": 0.0, "delay": float(boom.get("delay", 0.9)),
				"damage": damages[i] * float(boom.get("damage_mult", 2.0)), "color": Color(affix_defs()[aid].get("color", "ffb030"))})
	boss_phases.erase(ids[i])
	phase_shield.erase(ids[i])
	_remove(i)
	enemy_killed.emit(rarity, xp, pos, type_id)


## Borrado O(1): el último enemigo ocupa el hueco.
func _remove(i: int) -> void:
	var last := positions.size() - 1
	abilities.erase(ids[i])
	casting.erase(ids[i])
	if i != last:
		ids[i] = ids[last]
		positions[i] = positions[last]
		lives[i] = lives[last]
		max_lives[i] = max_lives[last]
		damages[i] = damages[last]
		speeds[i] = speeds[last]
		radii[i] = radii[last]
		cooldowns[i] = cooldowns[last]
		rarities[i] = rarities[last]
		types[i] = types[last]
		facings[i] = facings[last]
		phases[i] = phases[last]
		flashes[i] = flashes[last]
		names[i] = names[last]
		stuns[i] = stuns[last]
		windups[i] = windups[last]
		attack_dirs[i] = attack_dirs[last]
		dashes[i] = dashes[last]
		dash_hit[i] = dash_hit[last]
		immune[i] = immune[last]
		dot_dps[i] = dot_dps[last]
		dot_time[i] = dot_time[last]
		burn_dps[i] = burn_dps[last]
		burn_time[i] = burn_time[last]
		shock_time[i] = shock_time[last]
		shock_amp[i] = shock_amp[last]
		chill_time[i] = chill_time[last]
		freeze_time[i] = freeze_time[last]
		poison_dps[i] = poison_dps[last]
		poison_time[i] = poison_time[last]
		poison_stacks[i] = poison_stacks[last]
		bleed_dps[i] = bleed_dps[last]
		bleed_time[i] = bleed_time[last]
		traits[i] = traits[last]
	_resize_all(last)


func _resize_all(n: int) -> void:
	ids.resize(n)
	positions.resize(n)
	lives.resize(n)
	max_lives.resize(n)
	damages.resize(n)
	speeds.resize(n)
	radii.resize(n)
	cooldowns.resize(n)
	rarities.resize(n)
	types.resize(n)
	facings.resize(n)
	phases.resize(n)
	flashes.resize(n)
	names.resize(n)
	stuns.resize(n)
	windups.resize(n)
	attack_dirs.resize(n)
	dashes.resize(n)
	dash_hit.resize(n)
	immune.resize(n)
	dot_dps.resize(n)
	dot_time.resize(n)
	burn_dps.resize(n)
	burn_time.resize(n)
	shock_time.resize(n)
	shock_amp.resize(n)
	chill_time.resize(n)
	freeze_time.resize(n)
	poison_dps.resize(n)
	poison_time.resize(n)
	poison_stacks.resize(n)
	bleed_dps.resize(n)
	bleed_time.resize(n)
	traits.resize(n)


func _rebuild_grid() -> void:
	_grid.clear()
	for i in positions.size():
		var c := _cell_of(positions[i])
		var bucket = _grid.get(c)
		if bucket == null:
			_grid[c] = [i]
		else:
			bucket.append(i)


func _cell_of(p: Vector2) -> Vector2i:
	return Vector2i(floori(p.x / GRID_CELL), floori(p.y / GRID_CELL))


func _random_name(rarity: Rarity.Enemy) -> String:
	match rarity:
		Rarity.Enemy.ELITE:
			return "%s %s" % [ELITE_PREFIXES.pick_random(), ELITE_SUFFIXES.pick_random()]
		Rarity.Enemy.UNIQUE:
			return UNIQUE_NAMES.pick_random()
	return ""
