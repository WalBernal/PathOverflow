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

var _rng := RandomNumberGenerator.new()


## Zonas guiadas que no se generan (el tutorial enseña cosas en sitios concretos).
const FIXED := ["tutorial"]


## ¿Se genera esta zona? Los campamentos, las arenas de jefe y las zonas guiadas se quedan como están.
static func applies_to(def: Dictionary) -> bool:
	return not bool(def.get("safe", false)) and not def.has("boss") and not def.has("incident") and not FIXED.has(String(def.get("id", "")))


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
	var base := Vector2(float(def["size"][0]), float(def["size"][1]))
	var size := Vector2(base.x * _rng.randf_range(1.0 - SIZE_JITTER, 1.0 + SIZE_JITTER), base.y * _rng.randf_range(1.0 - SIZE_JITTER, 1.0 + SIZE_JITTER))
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
	_connect_keys()
	_keep_reachable()


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
		for attempt in 12:   # lejos de las otras salidas del mismo lado
			c = _cell_on_side(side, clampf(along + _rng.randf_range(-0.25, 0.25), 0.1, 0.9))
			if exit_cells.all(func(o: Vector2i) -> bool: return Vector2(o - c).length() >= 10.0):
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
		if not is_floor(c) and attempt < 50:
			continue
		var p := center_of(c)
		var d := INF
		for k in keys:
			d = minf(d, p.distance_to(k))
		if d > best_d:
			best_d = d
			best = p
	return best


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
func _connect_keys() -> void:
	var pts: Array[Vector2i] = []
	for p in key_points():
		pts.append(cell_of(p))
	for pair in _mst(pts):
		_carve(pts[pair[0]], pts[pair[1]], CORRIDOR_CELLS)
	for p in pts:   # un claro alrededor de cada punto clave
		_blob(p, 1.6, 1)


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
