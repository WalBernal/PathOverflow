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

const TYPES_PATH := "res://data/enemies.json"
const ATLAS := preload("res://assets/sprites/enemies/enemies.png")
const SPRITE_SHADER := preload("res://assets/shaders/enemy_sprite.gdshader")
const ATLAS_FRAMES := 4
## Tamaño del sprite respecto al diámetro de colisión.
const SPRITE_SCALE := 1.9
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

## Proyectiles enemigos: {pos, vel, damage, radius, life, color}
var projectiles: Array[Dictionary] = []
## Ataques en el suelo con retardo (jefe): {pos, radius, time, delay, damage}
var hazards: Array[Dictionary] = []
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
		special_abilities: Array = []) -> int:
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
	if not special_abilities.is_empty():
		var list: Array = []
		for a in special_abilities:
			list.append({"def": a, "timer": float(a.get("first", a.get("cooldown", 6.0) * 0.5))})
		abilities[ids[ids.size() - 1]] = list
	return ids[ids.size() - 1]


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
		if bool(enemy_types()[i].get("boss_only", false)) == boss:
			options.append(i)
	return options.pick_random() if not options.is_empty() else 0


func clear_all() -> void:
	_resize_all(0)
	projectiles.clear()
	hazards.clear()
	abilities.clear()
	casting.clear()
	_flashes_fx.clear()


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
	var damage := randf_range(min_damage, max_damage)
	if randf() * 100.0 < crit_chance:
		damage *= crit_multiplier / 100.0
	last_damage_dealt += minf(damage, lives[i])
	lives[i] -= damage
	flashes[i] = FLASH_TIME
	if lives[i] <= 0.0:
		_kill(i)


func is_in_safe_zone(pos: Vector2) -> bool:
	return safe_radius > 0.0 and pos.distance_to(safe_center) < safe_radius


func _physics_process(delta: float) -> void:
	if frozen:
		return
	var n := positions.size()
	_update_projectiles(delta)
	_update_hazards(delta)
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
		var atk: Dictionary = all_types[types[i]].get("attack", {}) if types[i] < all_types.size() else {}
		var kind: String = atk.get("kind", "melee")
		var move := Vector2.ZERO
		cooldowns[i] -= delta
		flashes[i] = maxf(0.0, flashes[i] - delta)

		if stuns[i] > 0.0:
			stuns[i] -= delta
		elif dashes[i] > 0.0:
			# Embestida: en línea recta, golpea una vez si toca al jugador.
			dashes[i] -= delta
			move = attack_dirs[i] * float(atk.get("dash_speed", 600.0))
			if dash_hit[i] == 0 and hunting and dist <= reach + float(atk.get("width", 30.0)) * 0.5:
				dash_hit[i] = 1
				player.take_damage(damages[i] * float(atk.get("damage_mult", 1.0)))
		elif windups[i] > 0.0:
			windups[i] -= delta
			if windups[i] <= 0.0 and hunting:
				_resolve_attack(i, atk, player_pos)
				pos = positions[i]   # el teletransporte mueve al enemigo
		elif casting.has(ids[i]):
			var cast: Dictionary = casting[ids[i]]
			cast["time"] -= delta
			if cast["time"] <= 0.0:
				casting.erase(ids[i])
				if hunting:
					_resolve_ability(i, cast["def"], cast["target"])
		elif hunting and dist < AGGRO_RANGE:
			facings[i] = 1.0 if to_player.x < 0.0 else 0.0
			var started_ability := _try_ability(i, delta, dist, player_pos)
			if not started_ability:
				move = _decide(i, atk, kind, to_player, dist, reach)

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
		if kind == "melee" and stuns[i] <= 0.0 and hunting and dist <= reach + 6.0 and cooldowns[i] <= 0.0:
			cooldowns[i] = ATTACK_INTERVAL
			player.take_damage(damages[i])
		i += 1
	last_simulation_ms = (Time.get_ticks_usec() - started) / 1000.0


## Movimiento y, si toca, inicio del ataque telegrafiado según el tipo.
func _decide(i: int, atk: Dictionary, kind: String, to_player: Vector2, dist: float, reach: float) -> Vector2:
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
				projectiles.append({"pos": pos, "vel": aim.rotated(angle) * float(atk.get("projectile_speed", 360.0)),
					"damage": damage, "radius": float(atk.get("projectile_radius", 7.0)), "life": 2.5,
					"color": Color(atk.get("color", "e0c040"))})
		"charge":
			dashes[i] = float(atk.get("dash_time", 0.5))
			dash_hit[i] = 0
		"slam":
			var radius := float(atk.get("radius", 100.0))
			_flashes_fx.append({"type": "circle", "pos": pos, "radius": radius, "time": 0.0, "color": Color(atk.get("color", "c86030"))})
			if pos.distance_to(player_pos) <= radius + Player.RADIUS:
				player.take_damage(damage)
		"cone":
			var radius := float(atk.get("range", 160.0)) + 20.0
			var half := deg_to_rad(float(atk.get("angle", 60.0))) / 2.0
			_flashes_fx.append({"type": "cone", "pos": pos, "dir": dir, "radius": radius, "half": half, "time": 0.0,
				"color": Color(atk.get("color", "e0652f"))})
			var to := player_pos - pos
			if to.length() <= radius + Player.RADIUS and absf(dir.angle_to(to)) <= half + 0.15:
				player.take_damage(damage)


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
		pr["pos"] += pr["vel"] * delta
		pr["life"] -= delta
		var p: Vector2 = pr["pos"]
		var gone: bool = pr["life"] <= 0.0
		if not gone and player and player.is_alive() and p.distance_to(player.global_position) <= pr["radius"] + Player.RADIUS:
			player.take_damage(pr["damage"])
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
	for i in positions.size():
		if stuns[i] > 0.0:
			_draw_stun(positions[i] + Vector2(0, -radii[i] * SPRITE_SCALE * 1.1 - 18.0))
		if immune[i] == 1:
			var pulse := 0.5 + 0.5 * sin(Time.get_ticks_msec() / 120.0)
			draw_arc(positions[i], radii[i] * 1.7, 0.0, TAU, 32, Color(0.6, 0.8, 1.0, 0.4 + 0.4 * pulse), 3.0, true)
		var rarity := rarities[i]
		if rarity == Rarity.Enemy.NORMAL and lives[i] >= max_lives[i]:
			continue
		var r := radii[i]
		var w := maxf(r * 2.0, 30.0)
		var top := positions[i] + Vector2(-w / 2.0, -r * SPRITE_SCALE * 1.1 - 8.0)
		draw_rect(Rect2(top, Vector2(w, 4.0)), Color(0, 0, 0, 0.7))
		draw_rect(Rect2(top, Vector2(w * lives[i] / max_lives[i], 4.0)), Color("c83232"))
		if rarity >= Rarity.Enemy.ELITE:
			draw_string(font, top + Vector2(-80.0, -6.0), names[i], HORIZONTAL_ALIGNMENT_CENTER,
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
		var dir: Vector2 = pr["vel"].normalized()
		draw_line(pr["pos"] - dir * 16.0, pr["pos"], Color(c, 0.45), pr["radius"], true)
		draw_circle(pr["pos"], pr["radius"], c)
		draw_circle(pr["pos"], pr["radius"] * 0.45, Color.WHITE)


static func _cone_points(origin: Vector2, dir: Vector2, radius: float, half: float) -> PackedVector2Array:
	var pts := PackedVector2Array([origin])
	for k in 13:
		pts.append(origin + dir.rotated(lerpf(-half, half, k / 12.0)) * radius)
	return pts


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
