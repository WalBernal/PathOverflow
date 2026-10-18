class_name EnemyManager
extends Node2D
## Simula y dibuja a TODOS los enemigos desde un solo nodo: datos en arrays
## empaquetados (estilo orientado a datos) y un MultiMesh que los pinta en una
## sola llamada. Un nodo con física por enemigo no escala igual en GDScript
## cuando hay cientos en pantalla, que es lo normal en un ARPG tipo PoE.
##
## Si el benchmark se queda corto, este es el archivo a portar a C# o a
## GDExtension (C++): la interfaz pública no tendría que cambiar.

signal enemy_killed(rarity: Rarity.Enemy, experience: int, position: Vector2)

const BASE_LIFE := 40.0
const BASE_DAMAGE := 7.0
const BASE_EXPERIENCE := 6.0
const ATTACK_INTERVAL := 1.2
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
const ELITE_SUFFIXES := ["no controlado", "del viernes", "huérfano", "zombi", "bloqueante", "de las 3 AM", "en producción"]
const UNIQUE_NAMES := [
	"El Arquitecto del Monolito",
	"El Backlog Infinito",
	"El Product Owner Sin Rostro",
	"La Reunión Que Pudo Ser Un Email",
]

var player: Player
## Nivel de zona: escala vida, daño y experiencia.
var area_level := 1

var positions := PackedVector2Array()
var lives := PackedFloat32Array()
var max_lives := PackedFloat32Array()
var damages := PackedFloat32Array()
var speeds := PackedFloat32Array()
var radii := PackedFloat32Array()
var cooldowns := PackedFloat32Array()
var rarities := PackedInt32Array()
var names := PackedStringArray()

## Coste del último tick de simulación (IA + separación), en milisegundos.
## Presupuesto orientativo: < 4 ms para dejar sitio al resto del juego.
var last_simulation_ms := 0.0

var _multimesh: MultiMesh
var _grid: Dictionary = {}  # Vector2i -> Array de índices


func _ready() -> void:
	_multimesh = MultiMesh.new()
	_multimesh.transform_format = MultiMesh.TRANSFORM_2D
	_multimesh.use_colors = true
	var quad := QuadMesh.new()
	quad.size = Vector2.ONE
	_multimesh.mesh = quad
	var mm_instance := MultiMeshInstance2D.new()
	mm_instance.multimesh = _multimesh
	mm_instance.texture = _make_circle_texture()
	mm_instance.show_behind_parent = true  # barras de vida y nombres encima
	add_child(mm_instance)


func count() -> int:
	return positions.size()


func spawn(pos: Vector2, rarity: Rarity.Enemy) -> void:
	var info: Dictionary = Rarity.ENEMY_INFO[rarity]
	var level_mult := 1.0 + 0.15 * (area_level - 1)
	var life: float = BASE_LIFE * info.life_mult * level_mult
	positions.append(pos)
	lives.append(life)
	max_lives.append(life)
	damages.append(BASE_DAMAGE * info.damage_mult * level_mult)
	speeds.append(SPEED_BY_RARITY[rarity] * randf_range(0.9, 1.1))
	radii.append(RADIUS_BY_RARITY[rarity])
	cooldowns.append(randf() * ATTACK_INTERVAL)
	rarities.append(rarity)
	names.append(_random_name(rarity))


func clear_all() -> void:
	_resize_all(0)


## Golpea a todos los enemigos dentro del radio. Devuelve cuántos golpeó.
func hit_in_radius(center: Vector2, radius: float, min_damage: float, max_damage: float,
		crit_chance: float, crit_multiplier: float) -> int:
	var hits := 0
	# Hacia atrás: _kill() mueve el último al hueco, que ya está procesado.
	for i in range(positions.size() - 1, -1, -1):
		if positions[i].distance_to(center) > radius + radii[i]:
			continue
		hits += 1
		var damage := randf_range(min_damage, max_damage)
		if randf() * 100.0 < crit_chance:
			damage *= crit_multiplier / 100.0
		lives[i] -= damage
		if lives[i] <= 0.0:
			_kill(i)
	return hits


func _physics_process(delta: float) -> void:
	var n := positions.size()
	if n == 0 or player == null:
		last_simulation_ms = 0.0
		return
	var started := Time.get_ticks_usec()
	_rebuild_grid()
	var player_pos := player.global_position
	var player_alive := player.is_alive()
	for i in n:
		var pos := positions[i]
		var r := radii[i]
		var to_player := player_pos - pos
		var dist := to_player.length()
		var reach := r + Player.RADIUS + 2.0
		var move := Vector2.ZERO
		if player_alive and dist > reach:
			move = to_player / dist * speeds[i]

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
		positions[i] = pos + move * delta + push * 0.5

		cooldowns[i] -= delta
		if player_alive and dist <= reach + 6.0 and cooldowns[i] <= 0.0:
			cooldowns[i] = ATTACK_INTERVAL
			player.take_damage(damages[i])
	last_simulation_ms = (Time.get_ticks_usec() - started) / 1000.0


func _process(_delta: float) -> void:
	var n := positions.size()
	if n > _multimesh.instance_count:
		_multimesh.instance_count = maxi(n, _multimesh.instance_count * 2)
	_multimesh.visible_instance_count = n
	for i in n:
		var d := radii[i] * 2.0
		_multimesh.set_instance_transform_2d(i, Transform2D(0.0, Vector2(d, d), 0.0, positions[i]))
		_multimesh.set_instance_color(i, Rarity.enemy_color(rarities[i]))
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
		var top := positions[i] + Vector2(-w / 2.0, -r - 10.0)
		draw_rect(Rect2(top, Vector2(w, 4.0)), Color(0, 0, 0, 0.7))
		draw_rect(Rect2(top, Vector2(w * lives[i] / max_lives[i], 4.0)), Color("c83232"))
		if rarity >= Rarity.Enemy.ELITE:
			draw_string(font, top + Vector2(-80.0, -6.0), names[i], HORIZONTAL_ALIGNMENT_CENTER,
				w + 160.0, 14, Rarity.enemy_color(rarity))


func _kill(i: int) -> void:
	var rarity := rarities[i]
	var info: Dictionary = Rarity.ENEMY_INFO[rarity]
	var xp := int(BASE_EXPERIENCE * info.xp_mult * (1.0 + 0.15 * (area_level - 1)))
	var pos := positions[i]
	_remove(i)
	enemy_killed.emit(rarity, xp, pos)


## Borrado O(1): el último enemigo ocupa el hueco.
func _remove(i: int) -> void:
	var last := positions.size() - 1
	if i != last:
		positions[i] = positions[last]
		lives[i] = lives[last]
		max_lives[i] = max_lives[last]
		damages[i] = damages[last]
		speeds[i] = speeds[last]
		radii[i] = radii[last]
		cooldowns[i] = cooldowns[last]
		rarities[i] = rarities[last]
		names[i] = names[last]
	_resize_all(last)


func _resize_all(n: int) -> void:
	positions.resize(n)
	lives.resize(n)
	max_lives.resize(n)
	damages.resize(n)
	speeds.resize(n)
	radii.resize(n)
	cooldowns.resize(n)
	rarities.resize(n)
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


## Círculo blanco con borde oscuro; el color por instancia lo tiñe según rareza.
static func _make_circle_texture() -> Texture2D:
	var gradient := Gradient.new()
	gradient.offsets = PackedFloat32Array([0.0, 0.72, 0.8, 0.95, 1.0])
	gradient.colors = PackedColorArray([
		Color(0.95, 0.95, 0.95), Color(0.8, 0.8, 0.8), Color(0.15, 0.12, 0.15),
		Color(0.15, 0.12, 0.15), Color(0, 0, 0, 0)])
	var tex := GradientTexture2D.new()
	tex.gradient = gradient
	tex.fill = GradientTexture2D.FILL_RADIAL
	tex.fill_from = Vector2(0.5, 0.5)
	tex.fill_to = Vector2(1.0, 0.5)
	tex.width = 64
	tex.height = 64
	return tex
