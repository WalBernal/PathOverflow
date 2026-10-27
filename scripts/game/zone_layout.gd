class_name ZoneLayout
extends RefCounted
## Prototipo del generador de zonas de la versión 3.0 (T114, diseño en docs/zonas_3.md).
## A partir de la definición de una zona (act*.json, ya escalada) y una semilla de
## instancia, reparte una rejilla de celdas transitables según una plantilla de forma
## del estilo (salas y pasillos, cueva, plaza con islas, pasillos de racks), recoloca
## salidas, entradas, waypoint y puntos especiales (NPC, objetos de misión, pruebas)
## y abre pasillos entre ellos para que todo quede conectado. Todavía no lo usa Zone:
## se ve con `capture_screens -- semillas`; T115 lo conecta al juego.

const CELL := 80.0
## Celdas de muro que rodean siempre la zona.
const MARGIN := 2
## Ancho (en celdas) de los pasillos que se abren entre puntos clave.
const CORRIDOR_CELLS := 3
## Variación del tamaño de la zona en cada eje (±).
const SIZE_JITTER := 0.15
## Plantillas que puede usar cada estilo (la primera es la más frecuente).
const STYLE_TEMPLATES := {
	"forest": ["cueva", "plaza"], "swamp": ["cueva", "plaza"], "fosa": ["cueva"], "grieta": ["cueva", "salas"],
	"rom": ["cueva", "salas"], "frio": ["plaza", "cueva"], "alcantarillas": ["salas", "cueva"],
	"ruins": ["salas", "plaza"], "catacombs": ["salas"], "fabrica": ["salas", "racks"], "anillo": ["plaza"],
	"servers": ["racks", "salas"], "terminal": ["racks"], "bios": ["racks", "salas"], "setup": ["racks", "plaza"],
	"bus": ["racks", "plaza"], "kernel": ["plaza", "salas"], "silicio": ["plaza", "racks"], "vga16": ["salas", "racks"],
	"sandbox": ["plaza"], "flash": ["plaza"],
}
## Probabilidad de cada variante de forma alargada (larga o ancha) y del rodeo.
const SHAPE_CHANCE := 0.2
const DETOUR_CHANCE := 0.3
## Coste de cavar al unir puntos clave: el pasillo va por el suelo que ya hay y
## solo cava si no queda otra (la cresta del rodeo cuesta mucho más).
const DIG_COST := 8.0
const HARD_COST := 80.0
const TEMPLATE_NAMES := {"salas": "salas y pasillos", "cueva": "cueva orgánica", "plaza": "plaza con islas", "racks": "pasillos de racks"}

var width := 0           # en celdas
var height := 0
var template := ""
var cells := PackedByteArray()   # 1 = transitable
## Puntos en píxeles del mundo (centro de su celda).
var exits: Array[Dictionary] = []      # {target, pos, side}
var entries: Dictionary = {}           # nombre -> Vector2
var waypoint := Vector2.INF
var specials: Array[Dictionary] = []   # {kind, id, pos}: NPC, objeto de misión, prueba, objeto clave

## Variante de forma (T116): "normal" (±15 %), "larga" (+20-30 % de largo) o "ancha".
var shape := "normal"
## Rodeo (T116): una cresta de muro de lado a lado con un solo paso en un extremo, que
## obliga a dar la vuelta. Celdas de la cresta (no se cavan si hay otro camino).
var detour: Array[Vector2i] = []

## Contenido de la instancia (T117), también de la semilla:
## - `type_weights`: peso de cada tipo de `enemies.types` al formar manadas (uno
##   abunda ×3, otro escasea ×0,35, el resto ×1); vacío = todos igual.
## - `elite_mult`: la probabilidad de élite de la zona multiplicada (0,7-1,3; media 1).
## - `ambience`: {weather (si existe la clave, sustituye al del estilo: "", "fog" o
##   "data_rain"), dust (polvo de más), dark (oscuridad de más: apagón parcial)}.
## - `treasure`: rincón apartado con una caja de botín rica (INF = no hay).
var type_weights: Array[float] = []
var elite_mult := 1.0
var ambience: Dictionary = {}
var treasure := Vector2.INF
## Salas temáticas (T123): [{kind, pos, radius, seed, box, lore}] en claros amplios,
## lejos de los puntos clave. Las dibuja Zone; `box`: con caja; `lore`: atrae una nota.
var set_pieces: Array[Dictionary] = []

var _rng := RandomNumberGenerator.new()
var _seed := 0
var _hard := {}   # celdas de muro que los pasillos evitan (la cresta del rodeo)


## Zonas guiadas que no se generan (el tutorial enseña cosas en sitios concretos).
const FIXED := ["tutorial"]


## ¿Se genera esta zona? Los campamentos, las arenas de jefe, los incidentes, el banco
## de oleadas y las zonas guiadas se quedan como están.
static func applies_to(def: Dictionary) -> bool:
	return not bool(def.get("safe", false)) and not def.has("boss") and not def.has("incident") and not def.has("waves_mode") \
		and not FIXED.has(String(def.get("id", "")))


static func generate(def: Dictionary, p_seed: int) -> ZoneLayout:
	var l := ZoneLayout.new()
	l._build(def, p_seed)
	return l


func size_px() -> Vector2:
	return Vector2(width, height) * CELL


func is_floor(c: Vector2i) -> bool:
	return c.x >= 0 and c.y >= 0 and c.x < width and c.y < height and cells[c.y * width + c.x] == 1


func cell_of(p: Vector2) -> Vector2i:
	return Vector2i(clampi(int(p.x / CELL), 0, width - 1), clampi(int(p.y / CELL), 0, height - 1))


func center_of(c: Vector2i) -> Vector2:
	return (Vector2(c) + Vector2(0.5, 0.5)) * CELL


func floor_fraction() -> float:
	var n := 0
	for v in cells:
		n += v
	return float(n) / maxf(1.0, float(cells.size()))


## ¿Hay suelo en `p` y a `margin` píxeles en las cuatro direcciones? (Lo que usa
## Zone.is_walkable en las zonas generadas.)
func point_ok(p: Vector2, margin := 0.0) -> bool:
	if not is_floor(Vector2i(floori(p.x / CELL), floori(p.y / CELL))):
		return false
	if margin <= 0.0:
		return true
	for d in [Vector2(margin, 0), Vector2(-margin, 0), Vector2(0, margin), Vector2(0, -margin)]:
		var q: Vector2 = p + d
		if not is_floor(Vector2i(floori(q.x / CELL), floori(q.y / CELL))):
			return false
	return true


## El punto más cercano a `p` que cumple point_ok con `margin`, buscando en las
## celdas vecinas (barato: lo usan los enemigos en cada tick). Si no hay, `p`.
func clamp_point(p: Vector2, margin := 0.0) -> Vector2:
	if point_ok(p, margin):
		return p
	var c := Vector2i(floori(p.x / CELL), floori(p.y / CELL))
	var m := minf(margin, CELL * 0.45)
	var best := p
	var best_d := INF
	for ring in range(1, 3):
		for dy in range(-ring, ring + 1):
			for dx in range(-ring, ring + 1):
				var n := c + Vector2i(dx, dy)
				if not is_floor(n):
					continue
				var r := Rect2(Vector2(n) * CELL, Vector2(CELL, CELL))
				# Hacia los lados donde la vecina también es suelo no hace falta margen.
				var lo := r.position + Vector2(0.0 if is_floor(n + Vector2i(-1, 0)) else m, 0.0 if is_floor(n + Vector2i(0, -1)) else m)
				var hi := r.end - Vector2(0.0 if is_floor(n + Vector2i(1, 0)) else m, 0.0 if is_floor(n + Vector2i(0, 1)) else m)
				var q := p.clamp(lo, hi)
				var d := q.distance_squared_to(p)
				if d < best_d:
					best_d = d
					best = q
		if best_d < INF:
			return best
	return p


## Centro de la celda de suelo más cercana a `p` (para puntos que venían del diseño).
func nearest_floor(p: Vector2) -> Vector2:
	var c := cell_of(p)
	if is_floor(c):
		return center_of(c)
	for ring in range(1, maxi(width, height)):
		var best := Vector2i(-1, -1)
		for dy in range(-ring, ring + 1):
			for dx in range(-ring, ring + 1):
				if maxi(absi(dx), absi(dy)) != ring:
					continue
				var n := c + Vector2i(dx, dy)
				if is_floor(n) and (best.x < 0 or Vector2(n - c).length() < Vector2(best - c).length()):
					best = n
		if best.x >= 0:
			return center_of(best)
	return p


## Rectángulos (en píxeles) que cubren las celdas con valor `v` (1 suelo, 0 muro):
## tramos por fila unidos con los de la fila siguiente si tienen el mismo ancho.
func rects_of(v: int) -> Array[Rect2]:
	var open := {}   # Vector2i(x0, x1) -> Rect2i en celdas
	var out: Array[Rect2] = []
	for y in height:
		var runs := {}
		var x := 0
		while x < width:
			if cells[y * width + x] != v:
				x += 1
				continue
			var x0 := x
			while x < width and cells[y * width + x] == v:
				x += 1
			runs[Vector2i(x0, x)] = true
		for key in open.keys():
			if not runs.has(key):
				var r: Rect2i = open[key]
				out.append(Rect2(Vector2(r.position) * CELL, Vector2(r.size) * CELL))
				open.erase(key)
		for key in runs:
			if open.has(key):
				var r: Rect2i = open[key]
				r.size.y += 1
				open[key] = r
			else:
				open[key] = Rect2i(key.x, y, key.y - key.x, 1)
	for key in open:
		var r: Rect2i = open[key]
		out.append(Rect2(Vector2(r.position) * CELL, Vector2(r.size) * CELL))
	return out


## Frontera entre suelo y muro en tramos rectos: {a, b, n} con `n` hacia el suelo.
func boundary_segments() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	# Bordes horizontales: entre la fila y y la y-1.
	for y in range(0, height + 1):
		for n in [Vector2(0, 1), Vector2(0, -1)]:   # suelo abajo (borde superior de la celda) o arriba
			var run_start := -1
			for x in range(0, width + 1):
				var below := is_floor(Vector2i(x, y)) if x < width else false
				var above := is_floor(Vector2i(x, y - 1)) if x < width else false
				var edge: bool = (below and not above) if n.y > 0 else (above and not below)
				if edge and run_start < 0:
					run_start = x
				elif not edge and run_start >= 0:
					out.append({"a": Vector2(run_start, y) * CELL, "b": Vector2(x, y) * CELL, "n": n})
					run_start = -1
	for x in range(0, width + 1):
		for n in [Vector2(1, 0), Vector2(-1, 0)]:
			var run_start := -1
			for y in range(0, height + 1):
				var right := is_floor(Vector2i(x, y)) if y < height else false
				var left := is_floor(Vector2i(x - 1, y)) if y < height else false
				var edge: bool = (right and not left) if n.x > 0 else (left and not right)
				if edge and run_start < 0:
					run_start = y
				elif not edge and run_start >= 0:
					out.append({"a": Vector2(x, run_start) * CELL, "b": Vector2(x, y) * CELL, "n": n})
					run_start = -1
	return out


## Copia de la definición de la zona con las posiciones de esta disposición: tamaño,
## salidas, entradas, waypoint, NPC, objetos de misión, pruebas y objetos clave; lo
## demás que tenga posición (decorado, puntos extra, mutex, race condition) se lleva
## en proporción al tamaño nuevo y al suelo más cercano. No toca el original.
func remap_def(def: Dictionary) -> Dictionary:
	var out: Dictionary = def.duplicate(true)
	var old := Vector2(float(def["size"][0]), float(def["size"][1]))
	var size := size_px()
	var arr := func(p: Vector2) -> Array: return [p.x, p.y]
	var moved := func(a: Array) -> Array:
		var p := Vector2(float(a[0]), float(a[1])) / old * size
		var q := nearest_floor(p)
		return [q.x, q.y]
	out["size"] = arr.call(size)
	for i in mini(exits.size(), out.get("exits", []).size()):
		out["exits"][i]["pos"] = arr.call(exits[i]["pos"])
	for k in entries:
		out["entries"][k] = arr.call(entries[k])
	if waypoint != Vector2.INF:
		out["waypoint"] = arr.call(waypoint)
	var by_kind := {}
	for s in specials:
		if not by_kind.has(s["kind"]):
			by_kind[s["kind"]] = []
		by_kind[s["kind"]].append(s["pos"])
	for list in [["npcs", "npc"], ["quest_items", "quest"], ["challenges", "challenge"], ["key_items", "key"]]:
		var spots: Array = by_kind.get(list[1], [])
		for i in mini(spots.size(), out.get(list[0], []).size()):
			out[list[0]][i]["pos"] = arr.call(spots[i])
	for p in out.get("props", []):
		if p is Dictionary and p.has("pos"):
			p["pos"] = moved.call(p["pos"])
	if out.has("extra_points"):
		out["extra_points"] = out["extra_points"].map(moved)
	if out.get("mutex") is Dictionary and out["mutex"].has("positions"):
		out["mutex"]["positions"] = out["mutex"]["positions"].map(moved)
	if out.get("race_condition") is Dictionary and out["race_condition"].has("pos"):
		out["race_condition"]["pos"] = moved.call(out["race_condition"]["pos"])
	for r in out.get("rare_spawns", []):   # los raros, cada instancia en otro sitio apartado (T117)
		if r is Dictionary and r.has("pos"):
			r["pos"] = arr.call(_far_spot())
	out["_layout_seed"] = _seed
	return out


## Todos los puntos clave (entradas, salidas, waypoint y especiales).
func key_points() -> Array[Vector2]:
	var out: Array[Vector2] = []
	for e in exits:
		out.append(e["pos"])
	for k in entries:
		out.append(entries[k])
	if waypoint != Vector2.INF:
		out.append(waypoint)
	for s in specials:
		out.append(s["pos"])
	return out


## Garantías del diseño: todo punto clave sobre suelo y alcanzable desde la primera
## entrada, y cada salida lejos de la entrada principal. "" si se cumplen.
func check() -> String:
	if entries.is_empty() or exits.is_empty():
		return "sin entradas o salidas"
	var start := cell_of(entries.values()[0])
	var reach := _flood(start)
	for p in key_points():
		var c := cell_of(p)
		if not is_floor(c):
			return "punto clave sobre muro en %s" % p
		if not reach.has(c):
			return "punto clave inalcanzable en %s" % p
	var main: Vector2 = entries.values()[0]
	for e in exits:
		if (e["pos"] as Vector2).distance_to(main) < CELL * 4.0 and exits.size() > 1 and e != _exit_nearest(main):
			return "salida %s pegada a la entrada" % e["target"]
	return ""


func _build(def: Dictionary, p_seed: int) -> void:
	_rng.seed = p_seed
	_seed = p_seed
	var base := Vector2(float(def["size"][0]), float(def["size"][1]))
	var mul := Vector2(_rng.randf_range(1.0 - SIZE_JITTER, 1.0 + SIZE_JITTER), _rng.randf_range(1.0 - SIZE_JITTER, 1.0 + SIZE_JITTER))
	var roll := _rng.randf()
	if roll < SHAPE_CHANCE:   # más larga en el sentido de la marcha
		shape = "larga"
		mul = Vector2(_rng.randf_range(1.2, 1.3), _rng.randf_range(0.85, 0.95))
	elif roll < SHAPE_CHANCE * 2.0:
		shape = "ancha"
		mul = Vector2(_rng.randf_range(0.85, 0.95), _rng.randf_range(1.2, 1.3))
	else:
		shape = "normal"
	var size := base * mul
	width = maxi(16, int(size.x / CELL))
	height = maxi(12, int(size.y / CELL))
	cells.resize(width * height)
	var options: Array = STYLE_TEMPLATES.get(String(def.get("style", "")), ["plaza"])
	template = options[0] if options.size() == 1 or _rng.randf() < 0.65 else options[_rng.randi_range(1, options.size() - 1)]
	match template:
		"salas": _fill_rooms()
		"cueva": _fill_cave()
		"racks": _fill_racks()
		_: _fill_plaza()
	if template != "salas":
		_erode_border()
	_place_keys(def, base)
	if _rng.randf() < DETOUR_CHANCE:
		_add_detour()
	_connect_keys()
	_keep_reachable()
	_make_content(def)


# --- Contenido de la instancia (T117) ---

## Estilos donde puede haber niebla o lluvia de datos de más (además de la suya).
const FOG_STYLES := ["forest", "swamp", "fosa", "frio", "grieta", "alcantarillas", "ruins", "catacombs", "rom", "anillo"]
const RAIN_STYLES := ["servers", "terminal", "kernel", "bus", "bios", "setup", "silicio", "vga16", "flash", "fabrica"]
const TREASURE_CHANCE := 0.5
const BLACKOUT_CHANCE := 0.2
const BLACKOUT_DARK := 0.18


func _make_content(def: Dictionary) -> void:
	var types: Array = def.get("enemies", {}).get("types", []) if def.get("enemies") is Dictionary else []
	if types.size() >= 2:
		for t in types:
			type_weights.append(1.0)
		var rich := _rng.randi_range(0, types.size() - 1)
		var poor := (rich + _rng.randi_range(1, types.size() - 1)) % types.size()
		type_weights[rich] = 3.0
		type_weights[poor] = 0.35
	elite_mult = _rng.randf_range(0.7, 1.3)
	var style := String(def.get("style", ""))
	if _rng.randf() < 0.5:   # la mitad de las veces, otro tiempo dentro de lo que pega con el estilo
		if FOG_STYLES.has(style):
			ambience["weather"] = ["", "fog"][_rng.randi_range(0, 1)]
		elif RAIN_STYLES.has(style):
			ambience["weather"] = ["", "data_rain"][_rng.randi_range(0, 1)]
	ambience["dust"] = _rng.randf() < 0.3
	ambience["dark"] = BLACKOUT_DARK if _rng.randf() < BLACKOUT_CHANCE else 0.0
	if _rng.randf() < TREASURE_CHANCE:
		treasure = _nook()
	_place_set_pieces(style)


## Salas temáticas (T123): qué estilos las pueden tener (vacío = todos).
const SET_PIECES := {
	"rack_caido": ["servers", "terminal", "bios", "setup", "bus", "fabrica", "kernel"],
	"cementerio_commits": ["ruins", "catacombs", "rom", "grieta", "fosa", "forest"],
	"backups_inundada": ["swamp", "alcantarillas", "frio", "kernel", "fosa"],
	"altar_becario": [],
	"servidor_legacy": ["silicio", "vga16", "flash", "anillo", "bios", "rom", "setup"],
}
const SET_PIECE_RADIUS := 3.2   # en celdas: el claro que necesita
const SET_PIECE_BOX := 0.4
const SET_PIECE_LORE := 0.5


func _place_set_pieces(style: String) -> void:
	var kinds: Array = []
	for k in SET_PIECES:
		if (SET_PIECES[k] as Array).is_empty() or (SET_PIECES[k] as Array).has(style):
			kinds.append(k)
	var count := _rng.randi_range(1, 2)
	var keys := key_points()
	if treasure != Vector2.INF:
		keys.append(treasure)
	var r_px := SET_PIECE_RADIUS * CELL
	for attempt in 400:
		if set_pieces.size() >= count or kinds.is_empty():
			break
		var c := Vector2i(_rng.randi_range(MARGIN + 4, width - MARGIN - 5), _rng.randi_range(MARGIN + 4, height - MARGIN - 5))
		var p := center_of(c)
		if not _clearing(p, r_px):
			continue
		if keys.any(func(k: Vector2) -> bool: return k.distance_to(p) < CELL * 6.0) \
				or set_pieces.any(func(s: Dictionary) -> bool: return Vector2(s["pos"]).distance_to(p) < CELL * 10.0):
			continue
		var kind: String = kinds[_rng.randi_range(0, kinds.size() - 1)]
		if set_pieces.size() > 0 and set_pieces[0]["kind"] == kind and kinds.size() > 1:
			continue   # dos distintas, si se puede
		set_pieces.append({"kind": kind, "pos": p, "radius": r_px, "seed": _rng.randi(),
			"box": _rng.randf() < SET_PIECE_BOX, "lore": _rng.randf() < SET_PIECE_LORE})
	if set_pieces.is_empty() and not kinds.is_empty():
		# Sin claro libre (racks densos, salas estrechas): se abre uno alrededor de una celda de
		# suelo lejos de todo. Sigue conectado: el claro nace de suelo ya alcanzable.
		var best := Vector2.INF
		var best_d := -1.0
		for attempt in 200:
			var c := Vector2i(_rng.randi_range(MARGIN + 5, width - MARGIN - 6), _rng.randi_range(MARGIN + 5, height - MARGIN - 6))
			if not is_floor(c):
				continue
			var d := INF
			for k in keys:
				d = minf(d, center_of(c).distance_to(k))
			if d > best_d:
				best_d = d
				best = center_of(c)
		if best != Vector2.INF and best_d >= CELL * 6.0:
			var bc := cell_of(best)   # un disco redondo (no _blob: ondula hasta un 30 % hacia dentro)
			var rr := ceili(SET_PIECE_RADIUS + 1.0)
			for dy in range(-rr, rr + 1):
				for dx in range(-rr, rr + 1):
					if Vector2(dx, dy).length() <= SET_PIECE_RADIUS + 1.0:
						_put(bc + Vector2i(dx, dy), 1)
			set_pieces.append({"kind": kinds[_rng.randi_range(0, kinds.size() - 1)], "pos": best, "radius": r_px, "seed": _rng.randi(),
				"box": _rng.randf() < SET_PIECE_BOX, "lore": _rng.randf() < SET_PIECE_LORE})


## ¿Hay suelo en un círculo de radio `r` alrededor de `p`? (muestras en dos anillos)
func _clearing(p: Vector2, r: float) -> bool:
	if not point_ok(p):
		return false
	for ring in [0.5, 1.0]:
		for k in 12:
			if not point_ok(p + Vector2.from_angle(TAU * k / 12.0) * r * ring):
				return false
	return true


## Índice al azar entre `count` opciones según `weights` (vacío o de otro tamaño = todas igual).
static func pick_weighted(weights: Array[float], count: int, rng: RandomNumberGenerator) -> int:
	if weights.size() != count:
		return rng.randi_range(0, count - 1)
	var total := 0.0
	for w in weights:
		total += w
	var r := rng.randf() * total
	for i in count:
		r -= weights[i]
		if r <= 0.0:
			return i
	return count - 1


## Rincón apartado: suelo lejos de todos los puntos clave y rodeado de muro (callejón).
func _nook() -> Vector2:
	var keys := key_points()
	var best := Vector2.INF
	var best_score := -1.0
	for attempt in 300:
		var c := Vector2i(_rng.randi_range(MARGIN + 1, width - MARGIN - 2), _rng.randi_range(MARGIN + 1, height - MARGIN - 2))
		if not is_floor(c):
			continue
		var walls := 0
		for dy in range(-1, 2):
			for dx in range(-1, 2):
				if not is_floor(c + Vector2i(dx, dy)):
					walls += 1
		var p := center_of(c)
		var d := INF
		for k in keys:
			d = minf(d, p.distance_to(k))
		if d < CELL * 8.0:
			continue
		var score := d / CELL + walls * 6.0
		if score > best_score:
			best_score = score
			best = p
	return best


# --- Plantillas de forma ---

func _put(c: Vector2i, v: int) -> void:
	if c.x >= MARGIN and c.y >= MARGIN and c.x < width - MARGIN and c.y < height - MARGIN:
		cells[c.y * width + c.x] = v


func _fill_all(v: int) -> void:
	for y in height:
		for x in width:
			cells[y * width + x] = 0
			_put(Vector2i(x, y), v)


func _blob(center: Vector2i, r: float, v: int) -> void:
	var ri := int(ceil(r))
	for dy in range(-ri, ri + 1):
		for dx in range(-ri, ri + 1):
			var wobble := r * (0.85 + 0.15 * sin(atan2(dy, dx) * 3.0 + center.x))
			if Vector2(dx, dy).length() <= wobble:
				_put(center + Vector2i(dx, dy), v)


## Contorno irregular: mordiscos de muro a lo largo de los cuatro lados (que la zona
## no sea un rectángulo). Los pasillos de los puntos clave se abren después.
func _erode_border() -> void:
	var biggest := clampf(mini(width, height) * 0.12, 2.5, 5.5)   # las zonas pequeñas, mordiscos pequeños
	for side in ["left", "right", "top", "bottom"]:
		var t := 0.0
		while t < 1.0:
			var c := _cell_on_side(side, t) - _inward(side) * MARGIN
			_blob(c, _rng.randf_range(2.0, biggest), 0)
			t += _rng.randf_range(0.06, 0.14)


## Plaza abierta con islas (lagos, colinas, montones de chatarra).
func _fill_plaza() -> void:
	_fill_all(1)
	var n := int(width * height / 160.0)
	for k in _rng.randi_range(n, n * 2):
		_blob(Vector2i(_rng.randi_range(MARGIN + 4, width - MARGIN - 5), _rng.randi_range(MARGIN + 3, height - MARGIN - 4)), _rng.randf_range(1.5, 4.5), 0)


## Cueva orgánica: relleno al azar suavizado con un autómata celular, sin las columnas
## sueltas de pocas celdas (se rellenan de suelo).
func _fill_cave() -> void:
	_fill_all(0)
	for y in range(MARGIN, height - MARGIN):
		for x in range(MARGIN, width - MARGIN):
			cells[y * width + x] = 1 if _rng.randf() < 0.53 else 0
	for it in 6:
		var next := cells.duplicate()
		for y in range(MARGIN, height - MARGIN):
			for x in range(MARGIN, width - MARGIN):
				var walls := 0
				for dy in range(-1, 2):
					for dx in range(-1, 2):
						if not is_floor(Vector2i(x + dx, y + dy)):
							walls += 1
				next[y * width + x] = 0 if walls >= 5 else 1
		cells = next
	_fill_small_walls(10)


## Rellena de suelo los grupos de muro de menos de `min_cells` que no tocan el borde.
func _fill_small_walls(min_cells: int) -> void:
	var seen := {}
	for y in range(MARGIN, height - MARGIN):
		for x in range(MARGIN, width - MARGIN):
			var start := Vector2i(x, y)
			if is_floor(start) or seen.has(start):
				continue
			var group: Array[Vector2i] = [start]
			var touches := false
			seen[start] = true
			var i := 0
			while i < group.size():
				var c := group[i]
				i += 1
				for d in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
					var nb: Vector2i = c + d
					if nb.x < MARGIN or nb.y < MARGIN or nb.x >= width - MARGIN or nb.y >= height - MARGIN:
						touches = true
						continue
					if not is_floor(nb) and not seen.has(nb):
						seen[nb] = true
						group.append(nb)
			if not touches and group.size() < min_cells:
				for c in group:
					_put(c, 1)


## Salas unidas por pasillos (árbol de expansión mínima y algún atajo que cierra un bucle).
func _fill_rooms() -> void:
	_fill_all(0)
	var rooms: Array[Rect2i] = []
	for attempt in 80:
		if rooms.size() >= 9:
			break
		var w := _rng.randi_range(6, 13)
		var h := _rng.randi_range(5, 9)
		var r := Rect2i(_rng.randi_range(MARGIN + 1, width - MARGIN - w - 1), _rng.randi_range(MARGIN + 1, height - MARGIN - h - 1), w, h)
		if r.position.x < MARGIN or r.position.y < MARGIN:
			continue
		if rooms.any(func(o: Rect2i) -> bool: return o.grow(2).intersects(r)):
			continue
		rooms.append(r)
	for r in rooms:
		for y in range(r.position.y, r.end.y):
			for x in range(r.position.x, r.end.x):
				_put(Vector2i(x, y), 1)
	var centers: Array[Vector2i] = []
	for r in rooms:
		centers.append(r.get_center())
	for pair in _mst(centers):
		_carve(centers[pair[0]], centers[pair[1]], 2, true)
	for k in mini(2, int(centers.size() / 3.0)):   # atajos: la zona no es un árbol puro
		_carve(centers[_rng.randi_range(0, centers.size() - 1)], centers[_rng.randi_range(0, centers.size() - 1)], 2, true)


## Pasillos de racks: filas de muro con huecos desplazados (laberinto suave).
func _fill_racks() -> void:
	_fill_all(1)
	var vertical := _rng.randf() < 0.5
	var span := height if vertical else width
	var across := width if vertical else height
	var a := MARGIN + 4
	while a < across - MARGIN - 4:
		var b := MARGIN + 1
		while b < span - MARGIN - 1:
			var run := _rng.randi_range(4, 9)
			for k in run:
				var c := Vector2i(a, b + k) if vertical else Vector2i(b + k, a)
				_put(c, 0)
			b += run + _rng.randi_range(3, 5)
		a += _rng.randi_range(5, 7)
	for k in _rng.randi_range(1, 3):   # claros entre los racks, para pelear
		_blob(Vector2i(_rng.randi_range(MARGIN + 6, width - MARGIN - 7), _rng.randi_range(MARGIN + 5, height - MARGIN - 6)), _rng.randf_range(3.5, 5.5), 1)


# --- Puntos clave ---

## Lado de la zona más cercano a un punto (para conservar de qué lado sale cada salida).
static func side_of(p: Vector2, size: Vector2) -> String:
	var d := {"left": p.x, "right": size.x - p.x, "top": p.y, "bottom": size.y - p.y}
	var best := "left"
	for s in d:
		if float(d[s]) < float(d[best]):
			best = s
	return best


## Celda pegada a `side`, a la fracción `t` (0..1) a lo largo de ese lado.
func _cell_on_side(side: String, t: float) -> Vector2i:
	var inset := MARGIN + 1
	match side:
		"left": return Vector2i(inset, int(lerpf(MARGIN + 2, height - MARGIN - 3, t)))
		"right": return Vector2i(width - inset - 1, int(lerpf(MARGIN + 2, height - MARGIN - 3, t)))
		"top": return Vector2i(int(lerpf(MARGIN + 2, width - MARGIN - 3, t)), inset)
		_: return Vector2i(int(lerpf(MARGIN + 2, width - MARGIN - 3, t)), height - inset - 1)


func _place_keys(def: Dictionary, base: Vector2) -> void:
	var exit_cells: Array[Vector2i] = []
	for e in def.get("exits", []):
		var p := Vector2(float(e["pos"][0]), float(e["pos"][1]))
		var side := side_of(p, base)
		var along := (p.y / base.y) if side == "left" or side == "right" else (p.x / base.x)
		var c := Vector2i.ZERO
		var best_gap := -1.0
		for attempt in 24:   # lejos de las otras salidas del mismo lado (si no se puede, la más lejana)
			var t := clampf(along + _rng.randf_range(-0.25, 0.25), 0.1, 0.9) if attempt < 12 else attempt / 24.0 * 0.8 + 0.1
			var cand := _cell_on_side(side, t)
			var gap := INF
			for o in exit_cells:
				gap = minf(gap, Vector2(o - cand).length())
			if gap > best_gap:
				best_gap = gap
				c = cand
			if gap >= 10.0:
				break
		exit_cells.append(c)
		exits.append({"target": e["target"], "side": side, "pos": center_of(c), "def_pos": p})
	# Cada entrada, junto a la salida que tenía más cerca en el diseño (por ahí se llega).
	for k in def.get("entries", {}):
		var p := Vector2(float(def["entries"][k][0]), float(def["entries"][k][1]))
		var best := -1
		for i in exits.size():
			if best == -1 or (exits[i]["def_pos"] as Vector2).distance_to(p) < (exits[best]["def_pos"] as Vector2).distance_to(p):
				best = i
		if best != -1 and (exits[best]["def_pos"] as Vector2).distance_to(p) < 400.0:
			entries[k] = center_of(exit_cells[best] + _inward(exits[best]["side"]) * 2)
		else:
			entries[k] = Vector2.INF   # la del waypoint: se pone con él
	if def.has("waypoint") and exits.size() >= 1:
		var a: Vector2 = exits[0]["pos"]
		var b: Vector2 = exits[exits.size() - 1]["pos"]
		var mid := a.lerp(b, _rng.randf_range(0.35, 0.65)) + (b - a).orthogonal().normalized() * _rng.randf_range(-0.2, 0.2) * minf(width, height) * CELL
		waypoint = center_of(cell_of(mid))
	for k in entries:
		if entries[k] == Vector2.INF:
			entries[k] = waypoint + Vector2(0, CELL) if waypoint != Vector2.INF else center_of(Vector2i(int(width * 0.5), int(height * 0.5)))
	# NPC, objetos de misión, pruebas y objetos clave: cada uno en su rincón, lejos del resto.
	for list in [["npcs", "npc"], ["quest_items", "quest"], ["challenges", "challenge"], ["key_items", "key"]]:
		for s in def.get(list[0], []):
			specials.append({"kind": list[1], "id": String(s.get("id", "")), "pos": _far_spot()})


func _inward(side: String) -> Vector2i:
	return {"left": Vector2i(1, 0), "right": Vector2i(-1, 0), "top": Vector2i(0, 1), "bottom": Vector2i(0, -1)}[side]


func _exit_nearest(p: Vector2) -> Dictionary:
	var best: Dictionary = exits[0]
	for e in exits:
		if (e["pos"] as Vector2).distance_to(p) < (best["pos"] as Vector2).distance_to(p):
			best = e
	return best


## Una celda de suelo lejos de los puntos clave que ya hay (la mejor de varias al azar).
func _far_spot() -> Vector2:
	var keys := key_points()
	var best := Vector2(width, height) * CELL * 0.5
	var best_d := -1.0
	for attempt in 60:
		var c := Vector2i(_rng.randi_range(MARGIN + 2, width - MARGIN - 3), _rng.randi_range(MARGIN + 2, height - MARGIN - 3))
		if not is_floor(c):
			continue
		var p := center_of(c)
		var d := INF
		for k in keys:
			d = minf(d, p.distance_to(k))
		if d > best_d:
			best_d = d
			best = p
	return best if best_d >= 0.0 else nearest_floor(best)


# --- Conexión y garantías ---

## Pasillo de `a` a `b`, de `w` celdas de ancho: serpenteante o, con `l_shape`, en
## forma de L (primero un eje y luego el otro, como entre salas).
func _carve(a: Vector2i, b: Vector2i, w: int, l_shape := false) -> void:
	var lo := -int(w * 0.5)
	var hi := w + lo
	var x_first := _rng.randf() < 0.5
	var c := a
	var guard := 0
	while guard < 4000:
		guard += 1
		for dy in range(lo, hi):
			for dx in range(lo, hi):
				_put(c + Vector2i(dx, dy), 1)
		if c == b:
			break
		var d := b - c
		var along_x := (d.x != 0 and (x_first or d.y == 0)) if l_shape else ((absi(d.x) > absi(d.y)) == (_rng.randf() < 0.8))
		var step := Vector2i(signi(d.x), 0) if along_x else Vector2i(0, signi(d.y))
		if step == Vector2i.ZERO:
			step = Vector2i(signi(d.x), signi(d.y))
		c += step


## Pares (i, j) del árbol de expansión mínima de `pts` (Prim).
func _mst(pts: Array[Vector2i]) -> Array:
	var out := []
	if pts.size() < 2:
		return out
	var inside := {0: true}
	while inside.size() < pts.size():
		var best := [-1, -1]
		var best_d := INF
		for i in inside:
			for j in pts.size():
				if inside.has(j):
					continue
				var d := Vector2(pts[i] - pts[j]).length()
				if d < best_d:
					best_d = d
					best = [i, j]
		inside[best[1]] = true
		out.append(best)
	return out


## Abre pasillos entre todos los puntos clave (árbol mínimo), así nunca quedan aislados.
## (T116) por el camino más barato: el suelo de la plantilla cuesta 1 y cavar muro
## DIG_COST, así se respeta la forma (la cueva sigue siendo cueva) y el rodeo.
func _connect_keys() -> void:
	var pts: Array[Vector2i] = []
	for p in key_points():
		pts.append(cell_of(p))
	for p in pts:   # un claro alrededor de cada punto clave
		_blob(p, 1.6, 1)
	var astar := AStarGrid2D.new()
	astar.region = Rect2i(0, 0, width, height)
	astar.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_NEVER
	astar.default_compute_heuristic = AStarGrid2D.HEURISTIC_MANHATTAN
	astar.update()
	for y in height:
		for x in width:
			var c := Vector2i(x, y)
			if x < MARGIN or y < MARGIN or x >= width - MARGIN or y >= height - MARGIN:
				astar.set_point_solid(c, true)
			elif not is_floor(c):
				astar.set_point_weight_scale(c, HARD_COST if _hard.has(c) else DIG_COST)
	for pair in _mst(pts):
		var path := astar.get_id_path(pts[pair[0]], pts[pair[1]])
		var lo := -int(CORRIDOR_CELLS * 0.5)
		for c in path:
			if is_floor(c):
				continue   # ya se puede pasar: no hace falta ensanchar el suelo de la plantilla
			for dy in range(lo, CORRIDOR_CELLS + lo):
				for dx in range(lo, CORRIDOR_CELLS + lo):
					_put(c + Vector2i(dx, dy), 1)
			astar.set_point_weight_scale(c, 1.0)   # los siguientes pasillos ya lo aprovechan


## Rodeo: cresta de 2 celdas de grosor que cruza la zona de lado a lado
## (perpendicular a la marcha, lejos de los puntos clave) con un paso de 5 celdas en
## uno de sus extremos.
func _add_detour() -> void:
	var horizontal_trip := exits.all(func(e: Dictionary) -> bool: return e["side"] == "left" or e["side"] == "right")
	var across := width if horizontal_trip else height
	var span := height if horizontal_trip else width
	var keys := key_points()
	var at := -1
	for attempt in 12:
		var cand := int(across * _rng.randf_range(0.35, 0.65))
		var clear := true
		for k in keys:
			var kc := cell_of(k)
			if absi((kc.x if horizontal_trip else kc.y) - cand) < 4:
				clear = false
		if clear:
			at = cand
			break
	if at < 0:
		return
	var gap_at_start := _rng.randf() < 0.5
	for b in range(MARGIN, span - MARGIN):
		var in_gap := (b < MARGIN + 5) if gap_at_start else (b >= span - MARGIN - 5)
		for t in 2:
			var c := Vector2i(at + t, b) if horizontal_trip else Vector2i(b, at + t)
			if in_gap:
				_put(c, 1)
			else:
				_put(c, 0)
				_hard[c] = true
				detour.append(c)


func _flood(start: Vector2i) -> Dictionary:
	var seen := {}
	if not is_floor(start):
		return seen
	var stack: Array[Vector2i] = [start]
	seen[start] = true
	while not stack.is_empty():
		var c: Vector2i = stack.pop_back()
		for d in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
			var n: Vector2i = c + d
			if is_floor(n) and not seen.has(n):
				seen[n] = true
				stack.append(n)
	return seen


## Lo que no se alcanza desde la primera entrada pasa a muro (sin bolsas cerradas).
func _keep_reachable() -> void:
	if entries.is_empty():
		return
	var reach := _flood(cell_of(entries.values()[0]))
	for y in height:
		for x in width:
			if cells[y * width + x] == 1 and not reach.has(Vector2i(x, y)):
				cells[y * width + x] = 0


# --- Dibujo para revisar (capture_screens -- semillas) ---

## Imagen de la disposición: `px` píxeles por celda, con los colores del estilo y los
## puntos clave (verde entradas, amarillo salidas, azul waypoint, magenta especiales).
func draw_image(px: int, ground: Color, outside: Color) -> Image:
	var img := Image.create(width * px, height * px, false, Image.FORMAT_RGBA8)
	img.fill(outside)
	var g := ground.lightened(0.25)
	for y in height:
		for x in width:
			if cells[y * width + x] == 1:
				img.fill_rect(Rect2i(x * px, y * px, px, px), g)
	var dot := func(p: Vector2, color: Color) -> void:
		var c := cell_of(p)
		img.fill_rect(Rect2i(c.x * px - px, c.y * px - px, px * 3, px * 3), color)
	for e in exits:
		dot.call(e["pos"], Color("ffd24a"))
	for k in entries:
		dot.call(entries[k], Color("5cff7a"))
	if waypoint != Vector2.INF:
		dot.call(waypoint, Color("5cd0ff"))
	for s in specials:
		dot.call(s["pos"], Color("ff5cf0"))
	return img
