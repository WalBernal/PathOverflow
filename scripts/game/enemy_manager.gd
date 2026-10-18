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

signal enemy_killed(rarity: Rarity.Enemy, experience: int, position: Vector2)

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
func spawn(pos: Vector2, rarity: Rarity.Enemy, type_index := -1, custom_name := "", life_mult := 1.0) -> void:
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
	radii.append(RADIUS_BY_RARITY[rarity])
	cooldowns.append(randf() * ATTACK_INTERVAL)
	rarities.append(rarity)
	types.append(type_index)
	facings.append(0.0)
	phases.append(randf() * ATLAS_FRAMES)
	flashes.append(0.0)
	names.append(custom_name if custom_name != "" else _random_name(rarity))


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


func _damage(i: int, min_damage: float, max_damage: float, crit_chance: float, crit_multiplier: float) -> void:
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
	var n := positions.size()
	if n == 0 or player == null:
		last_simulation_ms = 0.0
		return
	var started := Time.get_ticks_usec()
	_rebuild_grid()
	var player_pos := player.global_position
	# En el campamento el jugador es intocable: los enemigos ni le persiguen.
	var hunting := player.is_alive() and not is_in_safe_zone(player_pos)
	for i in n:
		var pos := positions[i]
		var r := radii[i]
		var to_player := player_pos - pos
		var dist := to_player.length()
		var reach := r + Player.RADIUS + 2.0
		var move := Vector2.ZERO
		if hunting and dist > reach and dist < AGGRO_RANGE:
			move = to_player / dist * speeds[i]
			facings[i] = 1.0 if move.x < 0.0 else 0.0

		# Separación entre enemigos (rejilla espacial: solo celdas vecinas).
		var push := Vector2.ZERO
		var cell := _cell_of(pos)
		for dx in range(-1, 2):
			for dy in range(-1, 2):
				var bucket = _grid.get(cell + Vector2i(dx, dy))
				if bucket == null:
					continue
				for j: int in bucket:
					if j == i:
						continue
					var diff := pos - positions[j]
					var min_dist := r + radii[j]
					var d2 := diff.length_squared()
					if d2 < min_dist * min_dist and d2 > 0.0001:
						var d := sqrt(d2)
						push += diff / d * (min_dist - d)
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
		new_pos = new_pos.clamp(bounds.position + Vector2(r, r), bounds.end - Vector2(r, r))
		positions[i] = walk_clamp.call(new_pos, r) if walk_clamp.is_valid() else new_pos

		cooldowns[i] -= delta
		flashes[i] = maxf(0.0, flashes[i] - delta)
		if hunting and dist <= reach + 6.0 and cooldowns[i] <= 0.0:
			cooldowns[i] = ATTACK_INTERVAL
			player.take_damage(damages[i])
	last_simulation_ms = (Time.get_ticks_usec() - started) / 1000.0


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


## Barras de vida (solo heridos o no normales) y nombres de élites y únicos.
func _draw() -> void:
	var font := ThemeDB.fallback_font
	for i in positions.size():
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


func _kill(i: int) -> void:
	var rarity := rarities[i]
	var info: Dictionary = Rarity.ENEMY_INFO[rarity]
	var types_list := enemy_types()
	var type_mult: float = types_list[types[i]].get("xp_mult", 1.0) if types[i] < types_list.size() else 1.0
	var xp := int(BASE_EXPERIENCE * info.xp_mult * type_mult * (1.0 + 0.15 * (area_level - 1)))
	var pos := positions[i]
	_remove(i)
	enemy_killed.emit(rarity, xp, pos)


## Borrado O(1): el último enemigo ocupa el hueco.
func _remove(i: int) -> void:
	var last := positions.size() - 1
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
