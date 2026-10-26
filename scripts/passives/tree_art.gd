class_name TreeArt
## Arte del árbol 2.0 (T94), sin nodos: fondo de estrellas y nebulosas con parallax,
## marcos de pixel art por tipo de nodo, minimapa y el orden del pulso al asignar.
## PassiveTreeView lo dibuja; las cuentas se prueban en los tests.

## Profundidad de cada capa del fondo (1 = se mueve con el árbol, 0 = quieta).
const STAR_DEPTHS := [0.18, 0.35]
const NEBULA_DEPTH := 0.7
const STAR_COUNT := 260
const STAR_FIELD := 9000.0
## Minimapa: lado en píxeles y margen con la esquina.
const MINIMAP_SIZE := 170.0
const MINIMAP_MARGIN := 12.0
## Retraso del pulso por cada paso del camino recién asignado (s).
const PULSE_STEP := 0.07

static var _stars: Array = []   # una lista por capa: [Vector3(x, y, brillo)]


## Estrellas fijas (siempre las mismas) de cada capa.
static func stars(layer: int) -> Array:
	if _stars.is_empty():
		var rng := RandomNumberGenerator.new()
		rng.seed = 2049
		for l in STAR_DEPTHS.size():
			var layer_stars := []
			for k in STAR_COUNT:
				layer_stars.append(Vector3(rng.randf_range(-STAR_FIELD, STAR_FIELD), rng.randf_range(-STAR_FIELD, STAR_FIELD), rng.randf_range(0.25, 1.0)))
			_stars.append(layer_stars)
	return _stars[layer]


## Posición en pantalla de un punto del árbol en una capa de profundidad `depth`:
## con depth 1 coincide con el árbol; con menos, se desplaza menos al mover la vista.
static func parallax(p: Vector2, zoom: float, offset: Vector2, view: Vector2, depth: float) -> Vector2:
	return (p * zoom + offset - view / 2.0) * depth + view / 2.0


## Nebulosa de una región: manchas alrededor de su inicio, siempre las mismas.
## [Vector3(x, y, radio)] en coordenadas del árbol.
static func nebula_blobs(start: Vector2, seed_value: int) -> Array:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var out := []
	var outward := start.normalized() if start.length() > 1.0 else Vector2.RIGHT
	for k in 6:
		var along := rng.randf_range(0.0, 1500.0)
		var side := rng.randf_range(-700.0, 700.0)
		var p := start + outward * along + outward.orthogonal() * side
		out.append(Vector3(p.x, p.y, rng.randf_range(420.0, 900.0)))
	return out


## Marco de pixel art de un nodo: polígono cerrado (último punto = primero).
## Menor y notable: octógono; piedra angular: hexágono; maestría: rombo;
## constelación: estrella de cuatro puntas.
static func frame(kind: String, center: Vector2, r: float) -> PackedVector2Array:
	var pts := PackedVector2Array()
	match kind:
		"keystone":
			for k in 7:
				pts.append(center + Vector2.from_angle(-PI / 2.0 + TAU * k / 6.0) * r)
		"mastery":
			for k in 5:
				pts.append(center + Vector2.from_angle(-PI / 2.0 + TAU * k / 4.0) * r * 1.15)
		"constellation":
			for k in 9:
				pts.append(center + Vector2.from_angle(-PI / 2.0 + TAU * k / 8.0) * (r * 1.2 if k % 2 == 0 else r * 0.85))
		_:
			for k in 9:
				pts.append(center + Vector2.from_angle(PI / 8.0 + TAU * k / 8.0) * r)
	return pts


static func frame_kind(n: PassiveNode) -> String:
	if not n.requires.is_empty():
		return "constellation"
	if n.is_mastery():
		return "mastery"
	if n.kind == PassiveNode.Kind.KEYSTONE or n.capstone:
		return "keystone"
	return "notable" if n.kind == PassiveNode.Kind.NOTABLE else "minor"


## Rectángulo que ocupan todos los nodos del árbol (para el minimapa).
static func bounds(tree: PassiveTree) -> Rect2:
	var rect := Rect2()
	var first := true
	for n: PassiveNode in tree.nodes.values():
		if first:
			rect = Rect2(n.position, Vector2.ZERO)
			first = false
		else:
			rect = rect.expand(n.position)
	return rect.grow(200.0)


## Rectángulo del minimapa en la vista (esquina inferior derecha).
static func minimap_rect(view: Vector2) -> Rect2:
	return Rect2(view - Vector2(MINIMAP_SIZE, MINIMAP_SIZE) - Vector2(MINIMAP_MARGIN, MINIMAP_MARGIN), Vector2(MINIMAP_SIZE, MINIMAP_SIZE))


## Punto del árbol -> punto del minimapa (y al revés), conservando la proporción.
static func to_minimap(p: Vector2, tree_bounds: Rect2, map: Rect2) -> Vector2:
	var s := minf(map.size.x / tree_bounds.size.x, map.size.y / tree_bounds.size.y)
	return map.get_center() + (p - tree_bounds.get_center()) * s


static func from_minimap(p: Vector2, tree_bounds: Rect2, map: Rect2) -> Vector2:
	var s := minf(map.size.x / tree_bounds.size.x, map.size.y / tree_bounds.size.y)
	return tree_bounds.get_center() + (p - map.get_center()) / s


## Pulso por el camino: para cada nodo recién asignado, cuántos pasos lo separan de
## lo que ya estaba asignado (el pulso sale de ahí y avanza nodo a nodo).
static func path_depths(tree: PassiveTree, before: Dictionary, after: Dictionary) -> Dictionary:
	var depth := {}
	var frontier: Array = []
	for id in after:
		if before.has(id):
			continue
		for nb in tree.neighbors(int(id)):
			if before.has(nb):
				depth[id] = 1
				frontier.append(id)
				break
	if frontier.is_empty():
		for id in after:
			if not before.has(id):
				depth[id] = 1
				frontier.append(id)
				break
	while not frontier.is_empty():
		var next: Array = []
		for id in frontier:
			for nb in tree.neighbors(int(id)):
				if after.has(nb) and not before.has(nb) and not depth.has(nb):
					depth[nb] = int(depth[id]) + 1
					next.append(nb)
		frontier = next
	for id in after:
		if not before.has(id) and not depth.has(id):
			depth[id] = 1   # sueltos (al cargar una build): sin retraso
	return depth
