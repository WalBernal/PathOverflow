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
## Un golpe tuyo (o de tus aliados) fue crítico: cargas de Overclock.
signal crit_dealt
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
## Dibujo: margen fuera de cámara que aún se dibuja, y cuántos enemigos en
## pantalla puede haber antes de pasar a los efectos de estados simplificados.
const CULL_MARGIN := 120.0
## Probabilidad de que una élite con dos afijos salga con una combinación con nombre.
const COMBO_CHANCE := 0.25
## Animación de ataque: duración de la embestida y cuánto avanza (px).
const LUNGE_TIME := 0.16
const LUNGE_DISTANCE := 9.0
## Retroceso máximo (px/s) y lo rápido que se frena (por segundo).
const KNOCK_SPEED := 320.0
const KNOCK_DECAY := 12.0
## Golpe pesado de raros y únicos sin ataque propio: telegrafiado en el suelo.
const HEAVY_WINDUP := 0.8
const HEAVY_COOLDOWN := 5.5
const HEAVY_RADIUS := 105.0
const HEAVY_DAMAGE := 2.4
## Segundos que se ve la frase de un raro al verte.
const QUOTE_TIME := 3.5
## Roles dentro de las manadas (traits["role"]):
##   tank: protege a los de alrededor (reciben ROLE_TANK_REDUCTION menos de daño).
##   healer: se queda atrás y cura a los heridos cercanos cada pocos segundos.
##   sniper: se aleja y dispara un tiro avisado con una línea roja, muy fuerte.
##   swarm: rápidos y frágiles; te rodean por los lados.
const ROLES := ["tank", "healer", "sniper", "swarm"]
const ROLE_NAMES := {"tank": "Guardián", "healer": "Sanador", "sniper": "Francotirador", "swarm": "Enjambre"}
const ROLE_COLORS := {"tank": Color("7fb8e0"), "healer": Color("6fd36b"), "sniper": Color("ff6a50"), "swarm": Color("e8d070")}
const ROLE_TANK_RADIUS := 170.0
const ROLE_TANK_REDUCTION := 0.4
const ROLE_HEAL_RADIUS := 260.0
const ROLE_HEAL_INTERVAL := 3.0
const ROLE_HEAL_FRACTION := 0.12
const ROLE_SNIPE_WINDUP := 1.1
const ROLE_SNIPE_COOLDOWN := 4.0
const ROLE_SNIPE_RANGE := 760.0
const ROLE_SNIPE_DAMAGE := 2.6
const ROLE_KEEP := {"healer": 330.0, "sniper": 470.0}
## Posiciones de los guardianes en este fotograma (para la reducción de daño).
var _tank_spots := PackedVector2Array()
## Ataques a distancia: al soltarlos el enemigo retrocede en vez de embestir.
const RECOIL_ATTACKS := ["ranged", "lob_pool", "seeker", "summon"]
const FX_DETAIL_LIMIT := 60
## Superconductor (helado + rayo): % del golpe de cada arco, cuántos y su alcance.
const SUPERCONDUCTOR_DAMAGE := 0.4
const SUPERCONDUCTOR_TARGETS := 2
const SUPERCONDUCTOR_RANGE := 180.0
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
## Nombres de los raros: un fallo (con su género) y un dueño o un epíteto
## ("Excepción no controlada de Juan", "Null Pointer el Breve").
const RARE_BUGS := [["Excepción no controlada", "f"], ["Null Pointer", "m"], ["Segfault", "m"], ["Fuga de memoria", "f"],
	["Race condition", "f"], ["Deadlock", "m"], ["Off-by-one", "m"], ["Proceso zombi", "m"], ["Hilo bloqueante", "m"],
	["Cron huérfano", "m"], ["Merge conflict", "m"], ["Warning ignorado", "m"], ["Consulta N+1", "f"], ["Variable global", "f"],
	["Excepción silenciada", "f"], ["Timeout", "m"]]
const RARE_OWNERS := ["de Juan", "de Marta", "del becario", "de la última release", "del viernes", "de las 3 AM",
	"de producción", "del código legacy", "del jefe", "de Stack Overflow", "del cliente", "de nadie"]
const RARE_EPITHETS := [["el Breve", "la Breve"], ["el Recursivo", "la Recursiva"], ["el Inmortal", "la Inmortal"],
	["el Indocumentado", "la Indocumentada"], ["el Intermitente", "la Intermitente"], ["el Deprecado", "la Deprecada"],
	["el Sin Tests", "la Sin Tests"], ["el Hardcodeado", "la Hardcodeada"], ["el Irreproducible", "la Irreproducible"],
	["el Heredado", "la Heredada"]]
## Lo que dicen los raros al verte por primera vez.
const RARE_QUOTES := ["¡Funciona en mi máquina!", "No soy un bug, soy una feature.", "¿Has probado a reiniciarme?",
	"Compilé sin warnings. Sin ninguno.", "Nadie lee los logs.", "¡Tus tests no me encontrarán!",
	"Me cerraron como «no se puede reproducir».", "Llevo aquí desde la versión 0.1.", "TODO: borrarte.",
	"git blame dirá que fuiste tú.", "Solo pasa en producción.", "Me arreglaron con un try vacío.",
	"¿Code review? Qué es eso.", "Un hotfix más y me voy. Mentira.", "Tu deploy es mío."]
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
## Retroceso: empuje que reciben al ser golpeados y que se frena solo.
var knocks := PackedVector2Array()
## Partículas de impacto y muertes con estilo (solo visual).
var impact: ImpactFx
## Tipo de daño del golpe (o degenerativo) que está matando al enemigo: decide su muerte.
var _kill_type := ""
## Sonido al golpear según el material del tipo (enemies.json → "material").
const MATERIAL_SFX := {"flesh": "hit_flesh", "metal": "hit_metal", "crystal": "hit_crystal", "digital": "hit_digital"}

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
## Superconductor pendientes: {from, damage} (arcos a enemigos cercanos).
var _arcs: Array[Dictionary] = []
## Potencia de las interacciones entre estados (1 = normal; las ascendencias la
## suben con "efecto de las interacciones"). La fija SkillController.
var interaction_power := 1.0
## Auras del jugador que debilitan: [{pos, radius, slow, damage_taken}] (las pone
## SkillController cada fotograma). No se acumulan entre sí: cuenta la más fuerte.
var aura_fields: Array[Dictionary] = []
## Embestidas de ataque en curso: id -> {t, dir}.
var _lunges := {}


## Efecto ("slow" o "damage_taken") de las auras que alcanzan al enemigo i.
func _aura_effect(i: int, key: String) -> float:
	var best := 0.0
	for f in aura_fields:
		if positions[i].distance_to(f["pos"]) <= float(f["radius"]) + radii[i]:
			best = maxf(best, float(f[key]))
	return best
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
## Enemigos dibujados en el último fotograma (los que se ven en cámara).
var last_drawn_count := 0
## Tiempo de CPU del último _draw (ms), para la prueba de rendimiento.
var last_draw_ms := 0.0

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


func _init() -> void:
	impact = ImpactFx.new()
	add_child(impact)


## Material del enemigo i: "flesh", "metal", "crystal" o "digital" (procesos, hilos, fantasmas).
func material_of(i: int) -> String:
	var all_types := enemy_types()
	if types[i] >= all_types.size():
		return "digital"
	var t: Dictionary = all_types[types[i]]
	var m := String(t.get("material", "digital"))
	return m if MATERIAL_SFX.has(m) else "digital"


## Partículas y sonido de un golpe que no mata (el de muerte lo pone _kill).
func _hit_feedback(i: int, damage: float, crit: bool) -> void:
	var dtype := String(hit_ailments.get("type", "physical"))
	if impact:
		impact.hit(positions[i] - Vector2(0.0, radii[i] * 0.6), dtype, crit, damage / maxf(1.0, max_lives[i]))
	if crit:
		Sfx.play("crit_click", -6.0, randf_range(0.95, 1.1))
	else:
		Sfx.play(MATERIAL_SFX[material_of(i)], -15.0, 1.15 - 0.08 * rarities[i])


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
	knocks.append(Vector2.ZERO)
	traits.append(_make_traits(t, rarity, with_combos(affix_ids) if not affix_ids.is_empty() or not roll_affixes else _roll_affixes(rarity), special_abilities.is_empty()))
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
			if def.has("combo"):
				prefix = String(def.get("name", ""))   # la combinación da su nombre propio
			elif prefix == "":
				prefix = String(def.get("name", ""))
		speeds[i_new] *= affix_speed
		if rarity >= Rarity.Enemy.ELITE and prefix != "":
			names[i_new] = "%s %s" % [prefix, names[i_new]]
	var i_last := traits.size() - 1
	if rarity >= Rarity.Enemy.ELITE and String(t.get("attack", {}).get("kind", "melee")) == "melee" and speeds[i_last] > 0.0:
		tr["heavy"] = HEAVY_COOLDOWN * randf_range(0.3, 0.8)
	if rarity >= Rarity.Enemy.ELITE and custom_name == "":
		tr["quote"] = RARE_QUOTES.pick_random()
		tr["quote_t"] = -1.0   # aún no la ha dicho: al verte por primera vez
	if not special_abilities.is_empty():
		var list: Array = []
		for a in special_abilities:
			list.append({"def": a, "timer": float(a.get("first", a.get("cooldown", 6.0) * 0.5))})
		abilities[ids[ids.size() - 1]] = list
	return ids[ids.size() - 1]


## Da un rol al enemigo `id` y ajusta su vida, velocidad y tamaño (ver ROLES).
func set_role(id: int, role: String) -> void:
	var i := index_of(id)
	if i == -1 or not ROLES.has(role):
		return
	var mult := {"tank": [2.2, 0.8, 1.25], "healer": [1.2, 1.0, 1.0], "sniper": [0.9, 1.05, 1.0], "swarm": [0.45, 1.55, 0.75]}[role] as Array
	lives[i] *= mult[0]
	max_lives[i] *= mult[0]
	speeds[i] *= mult[1]
	radii[i] *= mult[2]
	traits[i]["role"] = role
	traits[i]["role_t"] = randf() * 2.0   # que no actúen todos a la vez
	if rarities[i] >= Rarity.Enemy.ELITE and not names[i].ends_with(")"):
		names[i] = "%s (%s)" % [names[i], ROLE_NAMES[role]]


func role_of(i: int) -> String:
	return String((traits[i] as Dictionary).get("role", ""))


## Afijos al azar según la rareza y el nivel de la zona: élite 1 (2 desde el nivel 8),
## especiales 1 de cada 4 desde el nivel 3. Los únicos no tiran (los jefes tienen fases).
func _roll_affixes(rarity: int) -> Array:
	var count := 0
	if rarity == Rarity.Enemy.ELITE:
		count = (2 if area_level >= 8 else 1) + int(Difficulty.EXTRA_AFFIXES[clampi(difficulty, 0, 2)])
	elif rarity == Rarity.Enemy.SPECIAL and area_level >= 3 and randf() < 0.25 * (1 + difficulty):
		count = 1
	if count == 0:
		return []
	var pool: Array = []
	var combos: Array = []
	for aid in affix_defs():
		var def: Dictionary = affix_defs()[aid]
		if def.get("innate_only", false):
			continue   # rasgo propio de un tipo de enemigo (enemies.json → innate_affixes)
		if def.has("combo"):
			if _combo_available(def):
				combos.append(aid)
		elif int(def.get("min_level", 1)) <= area_level:
			pool.append(aid)
	var picked: Array = []
	# A veces, una élite con dos afijos sale directamente con una combinación.
	if count >= 2 and not combos.is_empty() and randf() < COMBO_CHANCE:
		picked.append_array(affix_defs()[combos[randi() % combos.size()]]["combo"])
	else:
		pool.shuffle()
		for aid in pool:
			if picked.size() >= count:
				break
			if _excluded(aid, picked):
				continue
			picked.append(aid)
	return with_combos(picked)


## Añade a la lista los afijos de combinación cuyos componentes estén todos.
static func with_combos(affix_ids: Array) -> Array:
	var out := affix_ids.duplicate()
	for aid in affix_defs():
		var parts: Array = affix_defs()[aid].get("combo", [])
		if parts.is_empty() or out.has(aid):
			continue
		if parts.all(func(x: String) -> bool: return affix_ids.has(x)):
			out.append(aid)
	return out


func _combo_available(def: Dictionary) -> bool:
	for part in def["combo"]:
		if int(affix_defs().get(part, {}).get("min_level", 99)) > area_level:
			return false
	return true


## ¿Choca `aid` con alguno de los ya elegidos (excludes en cualquiera de los dos)?
static func _excluded(aid: String, picked: Array) -> bool:
	for other in picked:
		if affix_defs().get(aid, {}).get("excludes", []).has(other) or affix_defs().get(other, {}).get("excludes", []).has(aid):
			return true
	return false


## Resistencias, inmunidades y afijos de un enemigo (tipo + afijos).
func _make_traits(t: Dictionary, _rarity: int, affix_ids: Array, _normal_spawn: bool) -> Dictionary:
	var res: Dictionary = {}
	var immune_set: Dictionary = {}
	for k in t.get("resist", {}):
		res[k] = float(t["resist"][k])
	if difficulty > 0:
		for k in ["physical", "fire", "cold", "lightning", "chaos"]:
			res[k] = float(res.get(k, 0.0)) + float(Difficulty.RESIST[difficulty])
	for k in t.get("immune", []):
		immune_set[k] = true
	var applied: Array = []
	# Afijos innatos del tipo (los del Acto IV) y los que impone la zona (incidentes):
	# siempre, sea cual sea su rareza.
	var all_affixes: Array = t.get("innate_affixes", []).duplicate()
	for aid in forced_affixes:
		if not all_affixes.has(aid):
			all_affixes.append(aid)
	for aid in affix_ids:
		if not all_affixes.has(aid):
			all_affixes.append(aid)
	for aid in all_affixes:
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
			"frac": lives[i] / max_lives[i], "shield": float(phase_shield.get(id, 0.0)), "name": names[i], "pos": positions[i], "rarity": rarities[i],
			"sprite": sprite_region(i)}
	return {}


## Primer fotograma del sprite del enemigo `i` dentro de ATLAS (para el minimapa).
func sprite_region(i: int) -> Rect2:
	var all_types := enemy_types()
	var t: Dictionary = all_types[types[i]] if types[i] < all_types.size() else {}
	var frame := ATLAS.get_size() / Vector2(ATLAS_FRAMES, maxi(1, all_types.size()))
	return Rect2(Vector2(0.0, int(t.get("sprite_row", 0)) * frame.y), frame)


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


## Superconductor: cada arco golpea a los SUPERCONDUCTOR_TARGETS enemigos más
## cercanos al helado (sin encadenar más interacciones).
func _update_arcs() -> void:
	if _arcs.is_empty():
		return
	var list := _arcs
	_arcs = []
	var saved := hit_ailments
	hit_ailments = {}
	for a in list:
		var src := index_of(a["id"])
		if src == -1:
			continue
		var from := positions[src]
		var skip := {a["id"]: true}   # por id: un golpe puede matar y mover los índices
		for k in SUPERCONDUCTOR_TARGETS:
			var t := nearest_index(from, SUPERCONDUCTOR_RANGE, skip)
			if t == -1:
				break
			skip[ids[t]] = true
			_flashes_fx.append({"type": "beam", "pos": from, "end": positions[t], "radius": 3.0, "time": 0.0, "color": Color("aee8ff")})
			_damage(t, a["damage"], a["damage"], 0.0, 100.0)
		_state_sfx("arc")
	hit_ailments = saved


func _update_booms() -> void:
	_update_arcs()
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


## Afijo Comandante (enemy_affixes.json → commander {radius, damage, speed}): los
## enemigos cercanos (no él) pegan y se mueven más. [{id, pos, radius, damage, speed}]
var _commanders: Array[Dictionary] = []


func _update_commanders() -> void:
	_commanders.clear()
	_healers.clear()
	for i in positions.size():
		if String(traits[i].get("role", "")) == "healer":
			_healers.append({"id": ids[i], "pos": positions[i]})
		for aid in traits[i].get("affixes", []):
			var cmd: Dictionary = affix_defs().get(aid, {}).get("commander", {})
			if not cmd.is_empty():
				_commanders.append({"id": ids[i], "pos": positions[i], "radius": float(cmd.get("radius", 300.0)),
					"damage": float(cmd.get("damage", 0.2)), "speed": float(cmd.get("speed", 0.1))})


## Reacciones a su estado (traits["react"]: "panic" | "healer" | "rally"), salvo
## jefes y únicos. Devuelve el movimiento o null para seguir con lo normal:
## - quemado: la mitad de las veces entra en pánico y huye un momento;
## - con poca vida: va hacia el sanador más cercano;
## - sin estar peleando: se arrima al aro de un comandante.
const PANIC_CHANCE := 0.5
const PANIC_TIME := 1.6
const SEEK_HEALER_LIFE := 0.35
const SEEK_HEALER_RANGE := 650.0
const RALLY_RANGE := 600.0
const RALLY_ENGAGED := 300.0
var _healers: Array[Dictionary] = []


func _react(i: int, tr_i: Dictionary, delta: float, to_target: Vector2, dist: float) -> Variant:
	tr_i.erase("react")
	if rarities[i] >= Rarity.Enemy.UNIQUE or speeds[i] <= 0.0:
		return null
	var pos := positions[i]
	var dir := to_target / maxf(dist, 0.001)
	if burn_time[i] > 0.0:
		if not tr_i.has("burn_seen"):
			tr_i["burn_seen"] = true
			if randf() < PANIC_CHANCE:
				tr_i["panic"] = PANIC_TIME
	else:
		tr_i.erase("burn_seen")
	if float(tr_i.get("panic", 0.0)) > 0.0:
		tr_i["panic"] = float(tr_i["panic"]) - delta
		tr_i["react"] = "panic"
		return (-dir + dir.orthogonal() * sin(float(tr_i["panic"]) * 9.0) * 0.6).normalized() * speeds[i] * 1.25
	if lives[i] < max_lives[i] * SEEK_HEALER_LIFE and String(tr_i.get("role", "")) != "healer":
		var best := Vector2.INF
		for h in _healers:
			if h["id"] != ids[i] and pos.distance_to(h["pos"]) < SEEK_HEALER_RANGE and pos.distance_to(h["pos"]) < pos.distance_to(best):
				best = h["pos"]
		if best != Vector2.INF and pos.distance_to(best) > 110.0:
			tr_i["react"] = "healer"
			return (best - pos).normalized() * speeds[i]
	if dist > RALLY_ENGAGED:
		for c in _commanders:
			var d := pos.distance_to(c["pos"])
			if c["id"] != ids[i] and d < RALLY_RANGE and d > float(c["radius"]) * 0.6:
				tr_i["react"] = "rally"
				return (Vector2(c["pos"]) - pos).normalized() * speeds[i]
	return null


## Bono de comandante que recibe el enemigo i: {damage, speed} (el mayor, no se suman).
func command_bonus(i: int) -> Dictionary:
	var best := {"damage": 0.0, "speed": 0.0}
	for c in _commanders:
		if c["id"] != ids[i] and positions[i].distance_to(c["pos"]) <= c["radius"]:
			best["damage"] = maxf(best["damage"], c["damage"])
			best["speed"] = maxf(best["speed"], c["speed"])
	return best


## Afijos que llevan todos los enemigos de la zona (incidentes, Incidents).
var forced_affixes: Array = []
## Dificultad (Difficulty): resistencias y afijos extra.
var difficulty := 0


## Último enemigo que golpeó al jugador (para el némesis):
## {id, time (ms), type, rarity, name, affixes, nemesis}.
var last_hitter: Dictionary = {}
signal nemesis_killed(pos: Vector2)


func _note_hitter(i: int) -> void:
	var all_types := enemy_types()
	last_hitter = {"id": ids[i], "time": Time.get_ticks_msec(), "rarity": rarities[i], "name": names[i],
		"type": String(all_types[types[i]].get("id", "")) if types[i] < all_types.size() else "",
		"affixes": (traits[i] as Dictionary).get("affixes", []).duplicate(), "nemesis": (traits[i] as Dictionary).get("nemesis", false)}


## Golpe al jugador con los efectos de los afijos (veneno, quemadura).
func _hit_player(i: int, amount: float) -> void:
	_note_hitter(i)
	if not _commanders.is_empty():
		amount *= 1.0 + float(command_bonus(i)["damage"])
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
		"freeze": ["freeze", -9.0, 1.0], "poison": ["poison", -12.0, 1.0], "bleed": ["bleed", -12.0, 1.0],
		"shatter": ["shatter", -8.0, 1.0], "arc": ["arc", -10.0, 1.0]}
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
	_channels.clear()
	_affix_timers.clear()
	_booms.clear()
	if impact:
		impact.clear()


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
				dps += poison_dps[i] * 0.5 * interaction_power   # Infección: envenenado y sangrando a la vez
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
			# Muere del degenerativo más fuerte: quemado (ceniza), envenenado o corrompido (se disuelve).
			_kill_type = "fire" if burn_dps[i] > 0.0 and burn_time[i] > 0.0 and burn_dps[i] >= poison_dps[i] \
				else ("chaos" if poison_time[i] > 0.0 or dot_time[i] > 0.0 else "physical")
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
	(traits[i] as Dictionary).erase("heavy_on")
	(traits[i] as Dictionary).erase("snipe_on")


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
	var crit := false
	if randf() * 100.0 < crit_chance:
		damage *= crit_multiplier / 100.0
		crit = true
		crit_dealt.emit()
	if not hit_ailments.is_empty():
		var dtype := String(hit_ailments.get("type", ""))
		if dtype != "" and dtype != "none":
			damage *= 1.0 - resist_of(i, dtype) / 100.0
		var ailing := float(hit_ailments.get("ailing", 1.0))
		if ailing != 1.0 and not ailments_of(i).is_empty():
			damage *= ailing
		var stunned := float(hit_ailments.get("stunned", 1.0))   # nodos "contra aturdidos"
		if stunned != 1.0 and (stuns[i] > 0.0 or freeze_time[i] > 0.0):
			damage *= stunned
	if shock_time[i] > 0.0:
		damage *= 1.0 + shock_amp[i]
	if not aura_fields.is_empty():
		damage *= 1.0 + _aura_effect(i, "damage_taken")
	if _tank_protected(i):
		damage *= 1.0 - ROLE_TANK_REDUCTION
	var dmg_type := String(hit_ailments.get("type", ""))
	var power := interaction_power
	if freeze_time[i] > 0.0 and dmg_type == "physical":
		# Rotura: un golpe físico a un enemigo congelado lo hace pedazos (+50 % y se acaba el hielo).
		damage *= 1.0 + 0.5 * power
		freeze_time[i] = 0.0
		_flashes_fx.append({"type": "circle", "pos": positions[i], "radius": radii[i] * 2.0, "time": 0.0, "color": Color("bfe8ff")})
		_state_sfx("shatter")
	elif burn_time[i] > 0.0 and dmg_type == "cold":
		# Choque térmico: el frío sobre un enemigo en llamas hace un 40 % más y apaga la quemadura.
		damage *= 1.0 + 0.4 * power
		burn_time[i] = 0.0
		_flashes_fx.append({"type": "circle", "pos": positions[i], "radius": radii[i] * 1.8, "time": 0.0, "color": Color("c8e8ff")})
		_state_sfx("chill")
	elif shock_time[i] > 0.0 and dmg_type == "fire":
		# Sobrecarga: el fuego sobre un enemigo electrocutado hace saltar una explosión y gasta la descarga.
		_booms.append({"pos": positions[i], "damage": damage * 0.5 * power, "radius": 85.0})
		shock_time[i] = 0.0
	elif chill_time[i] > 0.0 and dmg_type == "lightning":
		# Superconductor: el rayo sobre un enemigo helado salta en arcos a 2 enemigos
		# cercanos (40 % del golpe) y gasta el frío.
		_arcs.append({"from": i, "id": ids[i], "damage": damage * SUPERCONDUCTOR_DAMAGE * power})
		chill_time[i] = 0.0
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
		_kill_type = String(hit_ailments.get("type", "physical"))
		if crit:
			Sfx.play("crit_click", -6.0)
		_kill(i)
		return
	_hit_feedback(i, damage, crit)
	_knock(i, damage)
	if not hit_ailments.is_empty() and damage > 0.0:
		_roll_ailments(i, damage)


## Retroceso: el golpe empuja al enemigo lejos del jugador, más cuanto más vida
## le quita. Las élites lo notan un tercio; los únicos y los estáticos, nada.
func _knock(i: int, damage: float) -> void:
	if speeds[i] <= 0.0 or rarities[i] == Rarity.Enemy.UNIQUE or player == null:
		return
	var away := positions[i] - player.global_position
	if away == Vector2.ZERO:
		return
	var push := clampf(damage / maxf(1.0, max_lives[i]) * 3.0, 0.15, 1.0) * KNOCK_SPEED
	if rarities[i] == Rarity.Enemy.ELITE:
		push *= 0.35
	knocks[i] = (knocks[i] + away.normalized() * push).limit_length(KNOCK_SPEED)


## Empuje en área (Force Push): aleja de `center` a los enemigos del radio con
## `strength` veces el retroceso máximo. Las élites un tercio; los únicos y los estáticos, nada.
func push_in_radius(center: Vector2, radius: float, strength: float) -> void:
	for i in positions.size():
		if speeds[i] <= 0.0 or rarities[i] == Rarity.Enemy.UNIQUE or positions[i].distance_to(center) > radius + radii[i]:
			continue
		var away := positions[i] - center
		if away == Vector2.ZERO:
			away = Vector2.RIGHT
		var push := KNOCK_SPEED * strength * (0.35 if rarities[i] == Rarity.Enemy.ELITE else 1.0)
		knocks[i] = (knocks[i] + away.normalized() * push).limit_length(KNOCK_SPEED * maxf(1.0, strength))


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
	_update_channels(delta)
	_update_affixes(delta)
	_update_commanders()
	_update_booms()
	n = positions.size()
	if n == 0 or player == null:
		last_simulation_ms = 0.0
		return
	var started := Time.get_ticks_usec()
	_rebuild_grid()
	_tank_spots.clear()
	for k in positions.size():
		if (traits[k] as Dictionary).get("role", "") == "tank":
			_tank_spots.append(positions[k])
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
		var ally := _pick_ally(pos, dist, _hunts_allies(i)) if hunting and not allies.is_empty() else -1
		var target_pos := player_pos if ally == -1 else (allies[ally]["pos"] as Vector2)
		var to_target := target_pos - pos
		var tdist := to_target.length()
		var treach := reach if ally == -1 else r + float(allies[ally].get("radius", 12.0)) + 2.0
		var atk: Dictionary = all_types[types[i]].get("attack", {}) if types[i] < all_types.size() else {}
		var kind: String = atk.get("kind", "melee")
		var move := Vector2.ZERO
		# Helado: todo va más lento (movimiento, recarga y preparación de ataques).
		var tempo := (1.0 - Ailments.CHILL_SLOW) if chill_time[i] > 0.0 else 1.0
		if not aura_fields.is_empty():
			tempo *= 1.0 - _aura_effect(i, "slow")
		cooldowns[i] -= delta * tempo
		flashes[i] = maxf(0.0, flashes[i] - delta)
		var tr_i: Dictionary = traits[i]
		if tr_i.has("heavy"):
			tr_i["heavy"] = float(tr_i["heavy"]) - delta * tempo
		if tr_i.has("quote_t") and float(tr_i["quote_t"]) > 0.0:
			tr_i["quote_t"] = float(tr_i["quote_t"]) - delta

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
			if windups[i] <= 0.0 and tr_i.get("heavy_on", false):
				tr_i.erase("heavy_on")
				if hunting:
					_lunge_to(i, target_pos, 1.6)
					_resolve_heavy(i)
			elif windups[i] <= 0.0 and tr_i.get("snipe_on", false):
				tr_i.erase("snipe_on")
				if hunting:
					_lunge_to(i, target_pos, -0.8)
					_resolve_snipe(i)
			elif windups[i] <= 0.0 and hunting:
				# Los que disparan retroceden (culatazo); el resto embiste hacia el objetivo.
				_lunge_to(i, target_pos, -0.6 if String(atk.get("kind", "")) in RECOIL_ATTACKS else 1.0)
				_resolve_attack(i, atk, target_pos)
				pos = positions[i]   # el teletransporte mueve al enemigo
		elif casting.has(ids[i]):
			var cast: Dictionary = casting[ids[i]]
			cast["time"] -= delta * tempo
			if cast["time"] <= 0.0:
				casting.erase(ids[i])
				if hunting:
					_resolve_ability(i, cast["def"], cast["target"], float(cast.get("offset", randf() * TAU)))
		elif hunting and tdist < aggro_range:
			facings[i] = 1.0 if to_target.x < 0.0 else 0.0
			if tr_i.has("quote_t") and float(tr_i["quote_t"]) < 0.0 and dist < aggro_range * 0.7:
				tr_i["quote_t"] = QUOTE_TIME   # te ha visto: suelta su frase
			var react: Variant = _react(i, tr_i, delta, to_target, tdist)
			var started_ability := false
			if react is Vector2:
				move = (react as Vector2) * tempo   # reacciona a su estado: no ataca ni sigue su rol
				started_ability = true
			else:
				started_ability = _try_ability(i, delta, dist, player_pos)
			var role := String(tr_i.get("role", ""))
			if role != "" and not started_ability:
				var role_move: Variant = _role_step(i, tr_i, role, delta, to_target, tdist, treach, ally == -1)
				if role_move is Vector2:
					move = (role_move as Vector2) * tempo
					started_ability = true   # el rol ya decidió el movimiento
			if not started_ability and tr_i.has("heavy") and float(tr_i["heavy"]) <= 0.0 and ally == -1 \
					and dist <= _heavy_radius(i) * 0.75:
				# Golpe pesado: se para, avisa en el suelo y golpea fuerte (esquivable).
				tr_i["heavy"] = HEAVY_COOLDOWN
				tr_i["heavy_on"] = true
				windups[i] = HEAVY_WINDUP
				attack_dirs[i] = to_player / maxf(dist, 0.001)
			elif not started_ability:
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
		if knocks[i] != Vector2.ZERO:
			new_pos += knocks[i] * delta
			knocks[i] *= exp(-KNOCK_DECAY * delta)
			if knocks[i].length_squared() < 4.0:
				knocks[i] = Vector2.ZERO
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
		if kind == "melee" and stuns[i] <= 0.0 and windups[i] <= 0.0 and hunting and cooldowns[i] <= 0.0 \
				and not String(tr_i.get("role", "")) in ["healer", "sniper"]:
			if ally != -1 and tdist <= treach + 6.0:
				cooldowns[i] = ATTACK_INTERVAL
				_lunge_to(i, target_pos)
				_damage_ally(ally, damages[i])
			elif dist <= reach + 6.0:
				cooldowns[i] = ATTACK_INTERVAL
				_lunge_to(i, player_pos)
				_hit_player(i, damages[i])
		i += 1
	last_simulation_ms = (Time.get_ticks_usec() - started) / 1000.0


## Aliado al que irá el enemigo en `pos` (o -1 = el jugador): el que provoca
## (golem) dentro de su radio, o uno claramente más cerca que el jugador. Los
## cazadores (`hunter`) van a por la invocación más cercana aunque estés tú más cerca.
func _pick_ally(pos: Vector2, player_dist: float, hunter := false) -> int:
	var best := -1
	var best_d := INF
	for k in allies.size():
		var a: Dictionary = allies[k]
		if float(a.get("life", 0.0)) <= 0.0:
			continue
		if a.get("device", false) and not hunter:
			continue   # a las torretas solo van los cazadores de invocaciones
		var d := pos.distance_to(a["pos"])
		var taunting := d <= float(a.get("taunt", 0.0))
		if (taunting or d < player_dist * 0.7 or (hunter and d < aggro_range)) and d < best_d:
			best_d = d
			best = k
			if taunting:
				best_d = -1.0   # la provocación gana a cualquier otro
	return best


## Animación de ataque: una embestida corta hacia el objetivo (la dibuja _process).
## `amount`: 1 = embestida hacia el objetivo; negativo = retroceso al disparar.
func _lunge_to(i: int, target: Vector2, amount := 1.0) -> void:
	var dir := (target - positions[i]).normalized()
	_lunges[ids[i]] = {"t": LUNGE_TIME, "dir": (dir if dir != Vector2.ZERO else Vector2.RIGHT) * amount}


## ¿Prioriza a las invocaciones? Tipos con hunts_allies (gusanos, IRQ) y los que
## llevan una carga explosiva (Explosivo, Termonuclear), que buscan torretas y robots.
func _hunts_allies(i: int) -> bool:
	var all_types := enemy_types()
	if types[i] < all_types.size() and bool(all_types[types[i]].get("hunts_allies", false)):
		return true
	for aid in traits[i].get("affixes", []):
		if affix_defs().get(aid, {}).has("death_explosion"):
			return true
	return false


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
	if not _commanders.is_empty():
		speed *= 1.0 + float(command_bonus(i)["speed"])
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


## Comportamiento del rol: devuelve el movimiento (Vector2) o null para el normal
## de su tipo. `vs_player`: su objetivo es el jugador (no una invocación).
func _role_step(i: int, tr_i: Dictionary, role: String, delta: float, to_target: Vector2, dist: float, reach: float, vs_player: bool) -> Variant:
	tr_i["role_t"] = float(tr_i.get("role_t", 0.0)) - delta
	var dir := to_target / maxf(dist, 0.001)
	match role:
		"healer":
			if float(tr_i["role_t"]) <= 0.0:
				tr_i["role_t"] = ROLE_HEAL_INTERVAL
				_heal_around(i)
			return _keep_distance(i, dir, dist, ROLE_KEEP["healer"])
		"sniper":
			if vs_player and cooldowns[i] <= 0.0 and dist <= ROLE_SNIPE_RANGE:
				cooldowns[i] = ROLE_SNIPE_COOLDOWN + ROLE_SNIPE_WINDUP
				windups[i] = ROLE_SNIPE_WINDUP
				attack_dirs[i] = dir
				tr_i["snipe_on"] = true
				return Vector2.ZERO
			return _keep_distance(i, dir, dist, ROLE_KEEP["sniper"])
		"swarm":
			# Rodean: cada uno entra por su lado (según su id) y cierra al final.
			if dist <= reach:
				return Vector2.ZERO
			var side := 1.0 if ids[i] % 2 == 0 else -1.0
			var flank := clampf((dist - reach) / 220.0, 0.0, 1.0) * 0.9
			return (dir + dir.orthogonal() * side * flank).normalized() * speeds[i]
	return null


func _keep_distance(i: int, dir: Vector2, dist: float, keep: float) -> Vector2:
	if dist > keep + 50.0:
		return dir * speeds[i]
	if dist < keep - 60.0:
		return -dir * speeds[i] * 0.85
	return dir.orthogonal() * speeds[i] * 0.35 * (1.0 if ids[i] % 2 == 0 else -1.0)


## Sanador: cura a los heridos de alrededor (y a sí mismo un poco), con un rayo verde.
func _heal_around(i: int) -> void:
	var healed := 0
	for k in positions.size():
		if k == i or lives[k] >= max_lives[k] or positions[k].distance_to(positions[i]) > ROLE_HEAL_RADIUS:
			continue
		lives[k] = minf(max_lives[k], lives[k] + max_lives[k] * ROLE_HEAL_FRACTION)
		_flashes_fx.append({"type": "beam", "pos": positions[i], "end": positions[k], "radius": 3.0, "time": 0.0, "color": ROLE_COLORS["healer"]})
		healed += 1
		if healed >= 5:
			break
	lives[i] = minf(max_lives[i], lives[i] + max_lives[i] * ROLE_HEAL_FRACTION * 0.5)
	if healed > 0:
		_flashes_fx.append({"type": "circle", "pos": positions[i], "radius": ROLE_HEAL_RADIUS * 0.4, "time": 0.0, "color": ROLE_COLORS["healer"]})
		Sfx.play("heal", -14.0, 1.2)


## Tiro del francotirador: un proyectil muy rápido en la dirección avisada.
func _resolve_snipe(i: int) -> void:
	projectiles.append({"pos": positions[i] + attack_dirs[i] * (radii[i] + 6.0), "vel": attack_dirs[i] * 1100.0,
		"damage": damages[i] * ROLE_SNIPE_DAMAGE, "radius": 6.0, "life": ROLE_SNIPE_RANGE / 1100.0 + 0.2,
		"color": ROLE_COLORS["sniper"], "src": ids[i]})
	Sfx.play("projectile", -8.0, 0.7)


## ¿Lo protege un guardián cercano? (los guardianes no se protegen entre sí).
func _tank_protected(i: int) -> bool:
	if _tank_spots.is_empty() or role_of(i) == "tank":
		return false
	for p in _tank_spots:
		if p.distance_to(positions[i]) <= ROLE_TANK_RADIUS:
			return true
	return false


## Radio del golpe pesado (crece con el tamaño del enemigo).
func _heavy_radius(i: int) -> float:
	return HEAVY_RADIUS + radii[i] * 1.5


## Golpe pesado de un raro o único: todo lo que esté en el círculo avisado recibe
## HEAVY_DAMAGE veces su daño (la esquiva lo evita entero).
func _resolve_heavy(i: int) -> void:
	var pos := positions[i]
	var radius := _heavy_radius(i)
	var damage := damages[i] * HEAVY_DAMAGE
	_flashes_fx.append({"type": "circle", "pos": pos, "radius": radius, "time": 0.0, "color": TELEGRAPH})
	if player and pos.distance_to(player.global_position) <= radius + Player.RADIUS:
		_hit_player(i, damage)
	_damage_allies_near(pos, radius, damage)
	if player and pos.distance_to(player.global_position) < 700.0:
		player.camera_shake(5.0, 0.22)
	Sfx.play("explosion", -10.0, 0.7)


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
					"color": Color(atk.get("color", "e0c040")), "src": ids[i]}
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
				projectiles[projectiles.size() - 1]["src"] = ids[i]
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
			casting[ids[i]] = {"def": a["def"], "time": windup, "total": windup, "target": player_pos, "offset": randf() * TAU}
			return true
	return false


## `offset`: ángulo del primer proyectil de la nova (el mismo que se avisó al cargarla).
func _resolve_ability(i: int, def: Dictionary, target: Vector2, offset := 0.0) -> void:
	var pos := positions[i]
	var damage := damages[i] * float(def.get("damage_mult", 1.0))
	match String(def.get("kind", "")):
		"projectile_nova":
			var count := int(def.get("count", 12))
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
		"floor_break":
			# Mecánica de arena: losas que se agrietan (aviso) y se rompen; quien esté
			# encima recibe el golpe y queda un agujero que hace daño al pisarlo.
			var n := int(def.get("count", 5))
			var spread := float(def.get("spread", 260.0))
			for k in n:
				var bp := target if k == 0 else target + Vector2.from_angle(randf() * TAU) * randf_range(spread * 0.35, spread)
				if walk_clamp.is_valid():
					bp = walk_clamp.call(bp, 20.0)
				hazards.append({"kind": "break", "pos": bp, "radius": float(def.get("radius", 85.0)), "time": 0.0,
					"delay": float(def.get("delay", 1.6)) + k * 0.12, "damage": damage, "color": Color(def.get("color", "c8a070")),
					"hole_time": float(def.get("hole_time", 6.0)), "hole_dps": damages[i] * float(def.get("hole_dps_mult", 0.6)), "seed": randi() % 997})
		"safe_zones":
			# Mecánica de arena: toda la arena se marca salvo unos círculos seguros que
			# giran alrededor del centro; al acabar el aviso, daña a quien siga fuera.
			var center := pos
			if def.has("center"):
				center = Vector2(def["center"][0], def["center"][1])
			var safe: Array = []
			var n := int(def.get("safe_count", 2))
			var start := randf() * TAU
			for k in n:
				safe.append({"angle": start + TAU * k / n, "dist": float(def.get("safe_distance", 260.0)), "radius": float(def.get("safe_radius", 110.0))})
			hazards.append({"kind": "safe_zones", "pos": center, "radius": float(def.get("radius", 900.0)), "time": 0.0,
				"delay": float(def.get("delay", 3.2)), "damage": damage, "color": Color(def.get("color", "ff4040")),
				"safe": safe, "spin": float(def.get("spin", 0.6)) * (1.0 if randf() < 0.5 else -1.0)})
		"channel_adds":
			# Mecánica de arena: adds que canalizan hacia el jefe; si no se matan a
			# tiempo, el jefe se cura, gana un escudo o suelta una nova (y vuelven a empezar).
			var type_index := type_index_of(def.get("type", "bug"))
			var n := int(def.get("count", 2))
			var start := randf() * TAU
			for k in n:
				var ap := pos + Vector2.from_angle(start + TAU * k / maxf(1.0, n)) * float(def.get("distance", 320.0))
				if walk_clamp.is_valid():
					ap = walk_clamp.call(ap, 16.0)
				var add_id := spawn(ap, Rarity.Enemy.SPECIAL, type_index, def.get("summon_name", ""), float(def.get("summon_life", 1.5)))
				var total := float(def.get("channel_time", 8.0))
				_channels[add_id] = {"time": total, "total": total, "effect": String(def.get("effect", "heal")), "boss_id": ids[i],
					"amount": float(def.get("amount", 0.08)), "damage": damage, "radius": float(def.get("nova_radius", 520.0)),
					"color": Color(def.get("color", "7a4ad9"))}
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
			var src := index_of(int(pr.get("src", -1)))
			if src != -1:
				_note_hitter(src)
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
		if h.get("kind", "") == "safe_zones":
			for s in h["safe"]:
				s["angle"] += float(h["spin"]) * delta
		if h["time"] < h["delay"]:
			still.append(h)
			continue
		match String(h.get("kind", "")):
			"beam":
				_resolve_beam(h)
				continue
			"safe_zones":
				_resolve_safe_zones(h)
				continue
			"break":
				_flashes_fx.append({"type": "circle", "pos": h["pos"], "radius": h["radius"], "time": 0.0, "color": h["color"]})
				if player and player.is_alive() and h["pos"].distance_to(player.global_position) <= h["radius"] + Player.RADIUS:
					player.take_damage(h["damage"])
				_damage_allies_near(h["pos"], h["radius"], h["damage"])
				pools.append({"pos": h["pos"], "radius": h["radius"], "life": h["hole_time"], "total": h["hole_time"], "dps": h["hole_dps"],
					"kind": "chaos", "color": Color("0a0810"), "pit": true, "seed": h["seed"]})
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


## ¿Está `p` dentro de alguno de los círculos seguros de una mecánica de zonas seguras?
static func in_safe_zone(h: Dictionary, p: Vector2) -> bool:
	for s in h["safe"]:
		var sc: Vector2 = h["pos"] + Vector2.from_angle(s["angle"]) * float(s["dist"])
		if p.distance_to(sc) <= float(s["radius"]):
			return true
	return false


func _resolve_safe_zones(h: Dictionary) -> void:
	_flashes_fx.append({"type": "circle", "pos": h["pos"], "radius": h["radius"], "time": 0.0, "color": h["color"]})
	if player and player.is_alive() and h["pos"].distance_to(player.global_position) <= h["radius"] and not in_safe_zone(h, player.global_position):
		player.take_damage(h["damage"])
		if player:
			player.camera_shake(6.0, 0.4)
	for k in range(allies.size() - 1, -1, -1):
		var ap: Vector2 = allies[k]["pos"]
		if ap.distance_to(h["pos"]) <= h["radius"] and not in_safe_zone(h, ap):
			_damage_ally(k, h["damage"])


## Adds que canalizan (mecánica de arena "channel_adds"): id del add -> {time, total,
## effect (heal | shield | nova), boss_id, amount, damage, radius, color}.
var _channels := {}


func _update_channels(delta: float) -> void:
	if _channels.is_empty():
		return
	for add_id in _channels.keys():
		var ai := index_of(add_id)
		var ch: Dictionary = _channels[add_id]
		var bi := index_of(ch["boss_id"])
		if ai == -1 or bi == -1:
			_channels.erase(add_id)   # muerto (o el jefe ya no está): canalización interrumpida
			continue
		if stuns[ai] > 0.0 or freeze_time[ai] > 0.0:
			continue   # aturdido o congelado: no avanza
		ch["time"] -= delta
		if ch["time"] > 0.0:
			continue
		ch["time"] = ch["total"]
		var c: Color = ch["color"]
		match String(ch["effect"]):
			"heal":
				lives[bi] = minf(max_lives[bi], lives[bi] + max_lives[bi] * float(ch["amount"]))
			"shield":
				phase_shield[ch["boss_id"]] = maxf(float(phase_shield.get(ch["boss_id"], 0.0)), float(ch["amount"]))
			"nova":
				if player and player.is_alive() and positions[bi].distance_to(player.global_position) <= float(ch["radius"]) + Player.RADIUS:
					player.take_damage(ch["damage"])
				_damage_allies_near(positions[bi], float(ch["radius"]), ch["damage"])
		_flashes_fx.append({"type": "circle", "pos": positions[bi], "radius": radii[bi] * 2.5 if ch["effect"] != "nova" else float(ch["radius"]), "time": 0.0, "color": c})
		Sfx.play("wave", -6.0)


## Lo que queda de canalización de un add (0..1, 1 = acaba de empezar); -1 si no canaliza.
func channel_fraction(add_id: int) -> float:
	if not _channels.has(add_id):
		return -1.0
	return float(_channels[add_id]["time"]) / maxf(0.01, float(_channels[add_id]["total"]))


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

func _process(delta: float) -> void:
	var n := positions.size()
	if n > _multimesh.instance_count:
		_multimesh.instance_count = maxi(n, _multimesh.instance_count * 2)
	_multimesh.visible_instance_count = n
	var all_types := enemy_types()
	# Embestidas: van y vuelven (seno) y caducan.
	for id in _lunges.keys():
		_lunges[id]["t"] -= delta
		if _lunges[id]["t"] <= 0.0:
			_lunges.erase(id)
	for i in n:
		var t: Dictionary = all_types[types[i]] if types[i] < all_types.size() else {}
		var size := radii[i] * 2.0 * SPRITE_SCALE * float(t.get("scale", 1.0))
		var sprite_scale := Vector2(size, size)
		var offset := Vector2.ZERO
		if dashes[i] > 0.0:
			# Embistiendo: se estira en la dirección de la carga.
			sprite_scale *= Vector2(1.0 + 0.18 * absf(attack_dirs[i].x), 1.0 - 0.1 * absf(attack_dirs[i].x) + 0.12 * absf(attack_dirs[i].y))
		elif windups[i] > 0.0:
			# Cargando el golpe: se encoge y se ensancha, temblando un poco.
			var squash := 0.08 + 0.03 * sin(Time.get_ticks_msec() / 40.0 + ids[i])
			sprite_scale *= Vector2(1.0 + squash, 1.0 - squash)
		if not _lunges.is_empty() and _lunges.has(ids[i]):
			var l: Dictionary = _lunges[ids[i]]
			offset = l["dir"] * sin(PI * (1.0 - float(l["t"]) / LUNGE_TIME)) * LUNGE_DISTANCE * (size / 40.0)
		_multimesh.set_instance_transform_2d(i,
			Transform2D(0.0, sprite_scale, 0.0, positions[i] + offset - Vector2(0.0, size * 0.22)))
		var outline := Rarity.enemy_color(rarities[i])
		outline.a = 0.0 if rarities[i] == Rarity.Enemy.NORMAL else 1.0
		_multimesh.set_instance_color(i, outline)
		_multimesh.set_instance_custom_data(i, Color(t.get("sprite_row", 0), phases[i], facings[i], Accessibility.flash(flashes[i] / FLASH_TIME)))
	queue_redraw()


## Telegrafiados, proyectiles enemigos, barras de vida (solo heridos o no
## normales), nombres de élites y únicos, aturdimientos y lanzamientos.
func _draw() -> void:
	var t0 := Time.get_ticks_usec()
	_draw_all()
	last_draw_ms = (Time.get_ticks_usec() - t0) / 1000.0


func _draw_all() -> void:
	var font := ThemeDB.fallback_font
	# Solo lo que se ve en cámara (con margen); con muchos enemigos en pantalla, los
	# efectos de estados y afijos pasan a una versión simple (un halo por estado).
	var view := (get_canvas_transform().affine_inverse() * get_viewport_rect()).grow(CULL_MARGIN)
	_draw_attacks(font, view)
	var tt := Time.get_ticks_msec() / 1000.0
	var labels: Array[int] = []   # élites y únicos: nombre (y frase) encima de las barras
	var on_screen: Array[int] = []
	for i in positions.size():
		if view.has_point(positions[i]):
			on_screen.append(i)
	var simple := on_screen.size() > FX_DETAIL_LIMIT
	last_drawn_count = on_screen.size()
	for c in _commanders:   # el radio de sus órdenes, en dorado
		if view.has_point(c["pos"]):
			_batch_ring(c["pos"], c["radius"], 2.0, Color(1.0, 0.82, 0.29, 0.16 + 0.08 * sin(tt * 4.0)), 48)
	for i in on_screen:
		var role := role_of(i)
		if role != "":
			_draw_role(i, role, tt)
		var react := String((traits[i] as Dictionary).get("react", ""))
		if react != "":
			# Lo que le pasa por la cabeza: «!» de pánico, «+» busca sanador, «»» va con el comandante.
			var mark: Array = {"panic": ["!", Color("ff8a3a")], "healer": ["+", Color("6fd36b")], "rally": ["»", Color("ffd24a")]}[react]
			draw_string(font, positions[i] + Vector2(radii[i] * SPRITE_SCALE * 0.6, -radii[i] * SPRITE_SCALE * 1.1), mark[0],
				HORIZONTAL_ALIGNMENT_LEFT, -1, 16, mark[1])
		if stuns[i] > 0.0 and freeze_time[i] <= 0.0:
			_draw_stun(positions[i] + Vector2(0, -radii[i] * SPRITE_SCALE * 1.1 - 18.0))
		if simple:
			_draw_ailment_fx_simple(i)
		else:
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
		var states := _state_ids(i)
		if not states.is_empty():
			var side := 11.0 if not simple else 5.0
			var x0 := positions[i].x - (states.size() * (side + 2.0) - 2.0) / 2.0
			for k in states.size():
				var sr := Rect2(x0 + k * (side + 2.0), top.y - side - 3.0, side, side)
				if simple:
					_batch_rect(sr.grow(1.0), Color(0, 0, 0, 0.8))   # con muchos enemigos: un cuadrito del color del estado
					_batch_rect(sr, Ailments.color(states[k]))
				else:
					StatusIcon.draw(self, sr, states[k], true)
		if not has_bar:
			continue
		_batch_rect(Rect2(top - Vector2(1, 1), Vector2(w + 2.0, 6.0)), Color(0, 0, 0, 0.75))
		var frac := lives[i] / max_lives[i]
		var bar_color := BAR_LIFE
		if poison_time[i] > 0.0:
			bar_color = BAR_POISON
		elif freeze_time[i] > 0.0 or chill_time[i] > 0.0:
			bar_color = BAR_COLD
		_batch_rect(Rect2(top, Vector2(w * frac, 4.0)), bar_color)
		_batch_rect(Rect2(top, Vector2(w * frac, 1.0)), Color(1, 1, 1, 0.25))
		if rarity >= Rarity.Enemy.ELITE:
			labels.append(i)
	# Barras, cuadritos y halos de todos los enemigos: una sola llamada de dibujo.
	_flush_batch()
	_draw_role_marks()
	for i in labels:
		var r := radii[i]
		var w := maxf(r * 2.0, 30.0)
		var top := positions[i] + Vector2(-w / 2.0, -r * SPRITE_SCALE * 1.1 - 8.0)
		var name_y := -6.0 - (14.0 if not _state_ids(i).is_empty() else 0.0)
		var name_size := Accessibility.world_size(14)
		draw_string_outline(font, top + Vector2(-80.0, name_y), names[i], HORIZONTAL_ALIGNMENT_CENTER, w + 160.0, name_size, 4, Color(0, 0, 0, 0.8))
		draw_string(font, top + Vector2(-80.0, name_y), names[i], HORIZONTAL_ALIGNMENT_CENTER,
			w + 160.0, name_size, Rarity.enemy_color(rarities[i]))
		var quote_t := float((traits[i] as Dictionary).get("quote_t", 0.0))
		if quote_t > 0.0:
			_draw_quote(font, positions[i].x, top.y + name_y - 18.0, String(traits[i]["quote"]), clampf(quote_t / 0.4, 0.0, 1.0))


# --- Dibujo por lotes: rectángulos, círculos y aros como triángulos de un solo arreglo ---

const BAR_LIFE := Color("c83232")
const BAR_POISON := Color("4fa04a")
const BAR_COLD := Color("5a9ad0")

var _state_buf := PackedStringArray()


## Ids de los estados del enemigo, en el mismo orden que ailments_of(), sin crear
## diccionarios (para el dibujo de cada fotograma). Se reutiliza el mismo arreglo.
func _state_ids(i: int) -> PackedStringArray:
	_state_buf.clear()
	if freeze_time[i] > 0.0:
		_state_buf.append(Ailments.FREEZE)
	elif stuns[i] > 0.0:
		_state_buf.append("stun")
	if burn_time[i] > 0.0:
		_state_buf.append(Ailments.BURN)
	if shock_time[i] > 0.0:
		_state_buf.append(Ailments.SHOCK)
	if chill_time[i] > 0.0:
		_state_buf.append(Ailments.CHILL)
	if poison_time[i] > 0.0:
		_state_buf.append(Ailments.POISON)
	if bleed_time[i] > 0.0:
		_state_buf.append(Ailments.BLEED)
	if dot_time[i] > 0.0:
		_state_buf.append("corrupt")
	return _state_buf

var _batch_points := PackedVector2Array()
var _batch_colors := PackedColorArray()
var _batch_indices := PackedInt32Array()


func _batch_rect(r: Rect2, c: Color) -> void:
	var b := _batch_points.size()
	_batch_points.append_array([r.position, Vector2(r.end.x, r.position.y), r.end, Vector2(r.position.x, r.end.y)])
	for k in 4:
		_batch_colors.append(c)
	_batch_indices.append_array([b, b + 1, b + 2, b, b + 2, b + 3])


func _batch_circle(p: Vector2, radius: float, c: Color, segments := 12) -> void:
	var b := _batch_points.size()
	_batch_points.append(p)
	_batch_colors.append(c)
	for k in segments:
		_batch_points.append(p + Vector2.from_angle(TAU * k / segments) * radius)
		_batch_colors.append(c)
		_batch_indices.append_array([b, b + 1 + k, b + 1 + (k + 1) % segments])


func _batch_ring(p: Vector2, radius: float, width: float, c: Color, segments := 12) -> void:
	_batch_arc(p, radius, 0.0, TAU, width, c, segments)


## Arco de `from` a `to` (radianes) con grosor `width`.
func _batch_arc(p: Vector2, radius: float, from: float, to: float, width: float, c: Color, segments := 12) -> void:
	var b := _batch_points.size()
	for k in segments + 1:
		var d := Vector2.from_angle(lerpf(from, to, float(k) / segments))
		_batch_points.append_array([p + d * (radius - width * 0.5), p + d * (radius + width * 0.5)])
		_batch_colors.append_array([c, c])
		if k < segments:
			_batch_indices.append_array([b + k * 2, b + k * 2 + 1, b + k * 2 + 3, b + k * 2, b + k * 2 + 3, b + k * 2 + 2])


func _flush_batch() -> void:
	if not _batch_indices.is_empty():
		RenderingServer.canvas_item_add_triangle_array(get_canvas_item(), _batch_indices, _batch_points, _batch_colors)
	_batch_points.clear()
	_batch_colors.clear()
	_batch_indices.clear()


const TELEGRAPH := Color(1.0, 0.25, 0.2)
const STUN_ORBIT := Color("7fb8e0")
const STUN_LOCK := Color("c8c8d0")


## Modo daltónico: rayas diagonales dentro de un círculo de aviso, para que el
## peligro se lea por la forma y no solo por el rojo.
func _hatch_circle(c: Vector2, r: float, color: Color) -> void:
	if not Ailments.colorblind or r < 8.0:
		return
	var step := 14.0
	var k := -r
	while k <= r:
		# Cuerda a 45°: recta x - y = k cortada con el círculo.
		var d := absf(k) / sqrt(2.0)
		if d < r:
			var half := sqrt(r * r - d * d)
			var mid := c + Vector2(k, -k) * 0.5
			var along := Vector2(1, 1).normalized() * half
			draw_line(mid - along, mid + along, Color(color, 0.55), 2.0)
		k += step


## Rol: insignia sobre la cabeza (escudo, cruz, mira, chevrones) y, el guardián,
## el círculo de los que protege.
func _draw_role(i: int, role: String, tt: float) -> void:
	var c: Color = ROLE_COLORS[role]
	var p := positions[i] + Vector2(0, -radii[i] * SPRITE_SCALE * 1.1 - 24.0)
	if role == "tank":
		var pulse := 0.5 + 0.5 * sin(tt * 3.0 + ids[i])
		_batch_ring(positions[i], ROLE_TANK_RADIUS, 2.0, Color(c, 0.18 + 0.12 * pulse), 40)
	# Fondo y aro de la insignia por lotes; el símbolo encima (se dibuja después del lote).
	_batch_circle(p, 7.5, Color(0.04, 0.03, 0.06, 0.9), 12)
	_batch_ring(p, 7.5, 1.5, c, 16)
	_role_marks.append([p, role, c, i, tt])


var _role_marks: Array = []


## Símbolo de cada insignia de rol (escudo, cruz, mira, chevrones), sobre su fondo,
## y el accesorio que distingue a sanadores y francotiradores sobre su sprite.
func _draw_role_marks() -> void:
	for m in _role_marks:
		var p: Vector2 = m[0]
		var c: Color = m[2]
		var i: int = m[3]
		if i < positions.size():
			_draw_role_gear(i, String(m[1]), c, float(m[4]))
		_draw_role_symbol(p, String(m[1]), c)
	_role_marks.clear()


## Sanador: halo verde y brazalete con la cruz. Francotirador: visor rojo y un rifle
## largo que apunta hacia donde mira (con el láser encendido mientras carga el tiro).
func _draw_role_gear(i: int, role: String, c: Color, tt: float) -> void:
	var body := positions[i]
	var r := radii[i] * SPRITE_SCALE
	var head := body + Vector2(0, -r * 0.85)
	match role:
		"healer":
			draw_set_transform(head + Vector2(0, -r * 0.45 + sin(tt * 3.0 + ids[i]) * 1.5), 0.0, Vector2(1.0, 0.35))
			draw_arc(Vector2.ZERO, r * 0.45, 0.0, TAU, 20, Color(c, 0.9), 3.0, true)
			draw_set_transform(Vector2.ZERO)
			var band := body + Vector2(r * 0.5, -r * 0.35)
			draw_rect(Rect2(band - Vector2(5, 4), Vector2(10, 8)), Color("f2f2f0"))
			draw_rect(Rect2(band - Vector2(1, 3), Vector2(2, 6)), c.darkened(0.2))
			draw_rect(Rect2(band - Vector2(3, 1), Vector2(6, 2)), c.darkened(0.2))
		"sniper":
			var dir := attack_dirs[i] if attack_dirs[i] != Vector2.ZERO else Vector2.RIGHT
			var grip := body + Vector2(0, -r * 0.3)
			draw_line(grip, grip + dir * r * 1.6, Color("3a3a42"), 3.0, true)
			draw_rect(Rect2(grip + dir * r * 0.5 - Vector2(3, 5), Vector2(6, 3)), Color("1a1a1e"))   # la mira
			draw_line(head + Vector2(-r * 0.3, 0), head + Vector2(r * 0.3, 0), Color(c, 0.95), 3.0)   # visor
			if windups[i] > 0.0:
				draw_line(grip + dir * r * 1.6, grip + dir * r * 6.0, Color(1.0, 0.2, 0.15, 0.5), 1.0)


func _draw_role_symbol(p: Vector2, role: String, c: Color) -> void:
	match role:
		"tank":
			draw_colored_polygon(PackedVector2Array([p + Vector2(-4, -4), p + Vector2(4, -4), p + Vector2(3.5, 1), p + Vector2(0, 5), p + Vector2(-3.5, 1)]), c)
		"healer":
			draw_rect(Rect2(p + Vector2(-1.5, -4.5), Vector2(3, 9)), c)
			draw_rect(Rect2(p + Vector2(-4.5, -1.5), Vector2(9, 3)), c)
		"sniper":
			draw_arc(p, 3.5, 0.0, TAU, 12, c, 1.5, true)
			for k in 4:
				var d := Vector2.from_angle(PI / 2.0 * k)
				draw_line(p + d * 2.0, p + d * 5.5, c, 1.5)
		"swarm":
			for k in 2:
				draw_polyline(PackedVector2Array([p + Vector2(-4, -1 + k * 4 - 2), p + Vector2(0, -4 + k * 4 - 2), p + Vector2(4, -1 + k * 4 - 2)]), c, 1.5)


## Bocadillo con la frase de un raro, centrado en `x` y con el pico hacia abajo en `bottom`.
func _draw_quote(font: Font, x: float, bottom: float, text: String, alpha: float) -> void:
	var size := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, 13)
	var box := Rect2(x - size.x / 2.0 - 8.0, bottom - size.y - 8.0, size.x + 16.0, size.y + 6.0)
	draw_rect(box, Color(0.95, 0.92, 0.82, 0.92 * alpha))
	draw_rect(box, Color(0.1, 0.08, 0.1, alpha), false, 1.5)
	draw_colored_polygon(PackedVector2Array([Vector2(x - 6.0, box.end.y), Vector2(x + 6.0, box.end.y), Vector2(x, box.end.y + 7.0)]),
		Color(0.95, 0.92, 0.82, 0.92 * alpha))
	draw_string(font, Vector2(box.position.x + 8.0, box.end.y - 6.0), text, HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color(0.12, 0.1, 0.12, alpha))


func _draw_attacks(font: Font, view: Rect2) -> void:
	var all_types := enemy_types()
	var far_view := view.grow(ROLE_SNIPE_RANGE)   # los avisos grandes (cargas, francotiradores) se ven desde lejos
	var marks: Array = []   # "!" de los golpes pesados: encima de los círculos (que van por lotes)
	for i in positions.size():
		if not far_view.has_point(positions[i]) or (windups[i] <= 0.0 and not casting.has(ids[i])):
			continue
		var atk: Dictionary = all_types[types[i]].get("attack", {}) if types[i] < all_types.size() else {}
		var pos := positions[i]
		var dir := attack_dirs[i]
		if windups[i] > 0.0 and (traits[i] as Dictionary).get("heavy_on", false):
			# Golpe pesado: círculo rojo que se llena y un "!" encima.
			var ht := clampf(1.0 - windups[i] / HEAVY_WINDUP, 0.0, 1.0)
			var hr := _heavy_radius(i)
			_batch_circle(pos, hr, Color(TELEGRAPH, 0.12), 32)
			_batch_circle(pos, hr * ht, Color(TELEGRAPH, 0.26), 32)
			_batch_ring(pos, hr, 3.0, Color(TELEGRAPH, 0.6 + 0.4 * ht), 40)
			_hatch_circle(pos, hr, Color.WHITE)
			marks.append([pos + Vector2(-20.0, -radii[i] * SPRITE_SCALE * 1.1 - 30.0), TELEGRAPH.lerp(Color.WHITE, ht * 0.5)])
		elif windups[i] > 0.0 and (traits[i] as Dictionary).get("snipe_on", false):
			# Francotirador: línea roja que se estrecha y brilla justo antes del disparo.
			var st := clampf(1.0 - windups[i] / ROLE_SNIPE_WINDUP, 0.0, 1.0)
			var end := pos + dir * ROLE_SNIPE_RANGE
			draw_line(pos, end, Color(TELEGRAPH, 0.08 + 0.1 * st), 14.0 * (1.0 - st) + 3.0)
			draw_line(pos, end, Color(TELEGRAPH, 0.35 + 0.6 * st), 1.5 + st, true)
			draw_circle(pos + dir * (radii[i] + 6.0), 3.0 + 5.0 * st, Color(1.0, 0.8, 0.6, 0.5 + 0.5 * st))
		elif windups[i] > 0.0:
			var total := maxf(0.05, float(atk.get("windup", 0.5)))
			var t := clampf(1.0 - windups[i] / total, 0.0, 1.0)
			match String(atk.get("kind", "")):
				"slam":
					var radius := float(atk.get("radius", 100.0))
					_batch_circle(pos, radius, Color(TELEGRAPH, 0.10), 32)
					_batch_circle(pos, radius * t, Color(TELEGRAPH, 0.22), 32)
					_batch_ring(pos, radius, 2.0, Color(TELEGRAPH, 0.7), 40)
					_hatch_circle(pos, radius, Color.WHITE)
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
					if t > 0.03:   # con t = 0 el polígono no tiene área y no se puede triangular
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
					_batch_circle(target, pr_radius, Color(lc, 0.08), 28)
					_batch_circle(target, pr_radius * t, Color(lc, 0.2), 28)
					_batch_ring(target, pr_radius, 2.0, Color(lc, 0.7), 32)
					_hatch_circle(target, pr_radius, Color.WHITE)
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
			if String(def.get("kind", "")) == "projectile_nova":
				# Aviso de la nova: las líneas por donde saldrán los proyectiles (los huecos son seguros).
				var count := int(def.get("count", 12))
				var nc := Color(def.get("color", "ff5050"))
				for k in count:
					var ray := Vector2.from_angle(float(cast.get("offset", 0.0)) + TAU * k / count)
					draw_line(pos + ray * (radii[i] + 14.0), pos + ray * (radii[i] + 60.0 + 260.0 * t), Color(nc, 0.15 + 0.35 * t), 3.0, true)
	_flush_batch()   # círculos de aviso de todos los enemigos: una llamada
	for m in marks:
		draw_string_outline(font, m[0], "!", HORIZONTAL_ALIGNMENT_CENTER, 40.0, 26, 6, Color.BLACK)
		draw_string(font, m[0], "!", HORIZONTAL_ALIGNMENT_CENTER, 40.0, 26, m[1])
	# Charcos de daño degenerativo: burbujean y se desvanecen al final.
	var now := Time.get_ticks_msec() / 1000.0
	for pool in pools:
		var fade: float = clampf(pool["life"] / 0.8, 0.0, 1.0)
		var pc: Color = pool["color"]
		var pp: Vector2 = pool["pos"]
		if pool.get("pit", false):
			_draw_pit(pp, pool["radius"], int(pool.get("seed", 0)), fade)
			continue
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
		if h.get("kind", "") == "safe_zones":
			_draw_safe_zones(h, t)
			continue
		if h.get("kind", "") == "break":
			_draw_breaking_floor(h, t)
			continue
		draw_circle(h["pos"], h["radius"], Color(c, 0.10))
		draw_circle(h["pos"], h["radius"] * t, Color(c, 0.25))
		draw_arc(h["pos"], h["radius"], 0.0, TAU, 40, Color(c, 0.8), 2.0, true)
		_hatch_circle(h["pos"], h["radius"], Color.WHITE)
	_draw_channels()
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
	for pr in projectiles:   # sombras en el suelo, debajo de todos los proyectiles
		draw_set_transform(pr["pos"] + Vector2(0, SkillController.PROJECTILE_SHADOW_DROP), 0.0, Vector2(1.0, 0.45))
		draw_circle(Vector2.ZERO, maxf(4.0, float(pr["radius"])), Color(0, 0, 0, 0.22))
	draw_set_transform(Vector2.ZERO)
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


## Losa a punto de romperse: grietas que crecen desde el centro y un relleno rojo
## que se llena como el de los golpes pesados.
func _draw_breaking_floor(h: Dictionary, t: float) -> void:
	var p: Vector2 = h["pos"]
	var r: float = h["radius"]
	var sd: int = h["seed"]
	draw_circle(p, r, Color(TELEGRAPH, 0.10))
	draw_circle(p, r * t, Color(TELEGRAPH, 0.24))
	draw_arc(p, r, 0.0, TAU, 40, Color(TELEGRAPH, 0.55 + 0.45 * t), 3.0, true)
	for k in 6:
		var a := TAU * k / 6.0 + sd
		var mid := p + Vector2.from_angle(a + 0.3) * r * 0.45 * t
		var tip := p + Vector2.from_angle(a - 0.15) * r * 0.95 * t
		draw_polyline(PackedVector2Array([p, mid, tip]), Color(0.1, 0.07, 0.05, 0.85), 2.5)
	_hatch_circle(p, r, Color.WHITE)


## Agujero en el suelo (losa rota): negro con borde irregular de cascotes.
func _draw_pit(p: Vector2, r: float, sd: int, fade: float) -> void:
	var pts := PackedVector2Array()
	for k in 16:
		pts.append(p + Vector2.from_angle(TAU * k / 16.0) * r * (0.85 + 0.15 * sin(k * 2.3 + sd)) * Vector2(1.0, 0.75))
	draw_colored_polygon(pts, Color(0.02, 0.01, 0.03, 0.92 * fade))
	draw_polyline(pts + PackedVector2Array([pts[0]]), Color(0.45, 0.38, 0.3, 0.8 * fade), 3.0)
	_hatch_circle(p, r * 0.8, Color(0.6, 0.2, 0.9))


## Zonas seguras: la arena entera en rojo que se oscurece con el aviso y unos
## círculos verdes (con cruces en modo daltónico) que giran: ahí no te toca.
func _draw_safe_zones(h: Dictionary, t: float) -> void:
	var c: Color = h["color"]
	var center: Vector2 = h["pos"]
	draw_circle(center, h["radius"], Color(c, 0.06 + 0.12 * t))
	draw_arc(center, h["radius"], 0.0, TAU, 64, Color(c, 0.4 + 0.5 * t), 4.0, true)
	for s in h["safe"]:
		var sc: Vector2 = center + Vector2.from_angle(s["angle"]) * float(s["dist"])
		var sr: float = s["radius"]
		draw_circle(sc, sr, Color(0.15, 0.6, 0.3, 0.45))
		draw_arc(sc, sr, 0.0, TAU, 36, Color(0.6, 1.0, 0.7, 0.9), 3.0, true)
		if Ailments.colorblind:
			for k in 4:
				var d := Vector2.from_angle(PI / 4.0 + PI / 2.0 * k) * sr * 0.5
				draw_line(sc - d, sc + d, Color(1, 1, 1, 0.7), 3.0)
	if Ailments.colorblind:
		_hatch_circle(center, h["radius"], Color.WHITE)


## Adds que canalizan: un hilo hacia el jefe que se tensa y un aro con lo que les queda.
func _draw_channels() -> void:
	for add_id in _channels:
		var ai := index_of(add_id)
		var ch: Dictionary = _channels[add_id]
		var bi := index_of(ch["boss_id"])
		if ai == -1 or bi == -1:
			continue
		var frac := 1.0 - float(ch["time"]) / maxf(0.01, float(ch["total"]))
		var c: Color = ch["color"]
		draw_line(positions[ai], positions[bi], Color(c, 0.25 + 0.6 * frac), 2.0 + 4.0 * frac, true)
		draw_arc(positions[ai], radii[ai] + 12.0, -PI / 2.0, -PI / 2.0 + TAU * frac, 32, Color(c.lerp(TELEGRAPH, frac), 0.95), 4.0, true)
		if frac > 0.75:
			draw_arc(positions[ai], radii[ai] + 18.0, 0.0, TAU, 24, Color(TELEGRAPH, 0.4 + 0.5 * sin(Time.get_ticks_msec() / 60.0)), 2.0, true)


static func _cone_points(origin: Vector2, dir: Vector2, radius: float, half: float) -> PackedVector2Array:
	var pts := PackedVector2Array([origin])
	for k in 13:
		pts.append(origin + dir.rotated(lerpf(-half, half, k / 12.0)) * radius)
	return pts


## Efectos visuales baratos de cada estado sobre el enemigo.
## Versión barata de los efectos (muchos enemigos en pantalla): un halo del color
## de cada estado activo y un aro del primer afijo, sin partículas ni suavizado.
func _draw_ailment_fx_simple(i: int) -> void:
	var p := positions[i] + Vector2(0, -radii[i] * 0.4)
	var r := radii[i] * 1.2
	var k := 0
	if burn_time[i] > 0.0:
		_batch_circle(p, r, Color(Ailments.color(Ailments.BURN), 0.22))
		k += 1
	if shock_time[i] > 0.0:
		_batch_circle(p, r + k * 2.0, Color(Ailments.color(Ailments.SHOCK), 0.22))
		k += 1
	if chill_time[i] > 0.0:
		_batch_circle(p, r + k * 2.0, Color(Ailments.color(Ailments.CHILL), 0.22))
		k += 1
	if poison_time[i] > 0.0:
		_batch_circle(p, r + k * 2.0, Color(Ailments.color(Ailments.POISON), 0.22))
		k += 1
	if bleed_time[i] > 0.0:
		_batch_circle(p, r + k * 2.0, Color(Ailments.color(Ailments.BLEED), 0.22))
	if freeze_time[i] > 0.0:
		_batch_circle(p, r, Color(0.8, 0.95, 1.0, 0.45))
	var aff: Array = traits[i].get("affixes", [])
	if not aff.is_empty():
		_batch_ring(positions[i], radii[i] * 1.55, 2.0, Color(affix_defs().get(aff[0], {}).get("color", "ffffff")))


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
		_batch_circle(q, 2.5, STUN_ORBIT, 6)
	_batch_rect(Rect2(p + Vector2(-5, -3), Vector2(10, 8)), STUN_LOCK)
	_batch_arc(p + Vector2(0, -3), 4.0, PI, TAU, 2.0, STUN_LOCK, 6)


func _kill(i: int) -> void:
	var rarity := rarities[i]
	var info: Dictionary = Rarity.ENEMY_INFO[rarity]
	var types_list := enemy_types()
	var type_mult: float = types_list[types[i]].get("xp_mult", 1.0) if types[i] < types_list.size() else 1.0
	var xp := int(BASE_EXPERIENCE * info.xp_mult * type_mult * (1.0 + 0.15 * (area_level - 1)))
	var pos := positions[i]
	var type_id: String = types_list[types[i]]["id"] if types[i] < types_list.size() else ""
	# Explosión al morir: solo la más grande (Termonuclear sustituye a Explosivo).
	var best_boom := {}
	var boom_color := Color("ffb030")
	for aid in traits[i].get("affixes", []):
		var boom: Dictionary = affix_defs().get(aid, {}).get("death_explosion", {})
		if not boom.is_empty() and float(boom.get("radius", 100.0)) > float(best_boom.get("radius", 0.0)):
			best_boom = boom
			boom_color = Color(affix_defs()[aid].get("color", "ffb030"))
	if not best_boom.is_empty():
		hazards.append({"pos": pos, "radius": float(best_boom.get("radius", 100.0)), "time": 0.0, "delay": float(best_boom.get("delay", 0.9)),
			"damage": damages[i] * float(best_boom.get("damage_mult", 2.0)), "color": boom_color})
	boss_phases.erase(ids[i])
	phase_shield.erase(ids[i])
	var was_nemesis: bool = (traits[i] as Dictionary).get("nemesis", false)
	_death_feedback(i)
	_remove(i)
	enemy_killed.emit(rarity, xp, pos, type_id)
	if was_nemesis:
		nemesis_killed.emit(pos)


## Muerte con estilo según lo que lo mató (ver ImpactFx.death) y su sonido.
func _death_feedback(i: int) -> void:
	var kind := _kill_type if _kill_type != "" else "physical"
	_kill_type = ""
	if impact:
		var tint := Rarity.enemy_color(rarities[i]) if rarities[i] != Rarity.Enemy.NORMAL else Color("c8b8a0")
		impact.death(positions[i] - Vector2(0.0, radii[i] * 0.6), kind, radii[i] * SPRITE_SCALE * 0.5, tint)
	match kind:
		"fire":
			Sfx.play("death_ash", -10.0)
		"cold":
			Sfx.play("shatter", -12.0)
		"lightning":
			Sfx.play("arc", -14.0)
		"chaos":
			Sfx.play("poison", -14.0)
		_:
			Sfx.play("death_decompile", -14.0)


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
		knocks[i] = knocks[last]
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
	knocks.resize(n)
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


## Nombre generado de un raro: "<fallo> <dueño>" o "<fallo> <epíteto>" (con su género).
static func rare_name() -> String:
	var bug: Array = RARE_BUGS.pick_random()
	if randf() < 0.5:
		return "%s %s" % [bug[0], RARE_OWNERS.pick_random()]
	return "%s %s" % [bug[0], RARE_EPITHETS.pick_random()[0 if bug[1] == "m" else 1]]


func _random_name(rarity: Rarity.Enemy) -> String:
	match rarity:
		Rarity.Enemy.ELITE:
			return rare_name()
		Rarity.Enemy.UNIQUE:
			return UNIQUE_NAMES.pick_random()
	return ""
