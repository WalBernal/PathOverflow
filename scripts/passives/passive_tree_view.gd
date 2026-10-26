class_name PassiveTreeView
extends Control
## Dibuja el árbol pasivo entero en UN solo _draw(), en lugar de un Control por
## nodo. Con descarte por viewport y una rejilla espacial para el hover escala
## sin problema a miles de nodos. Solo se redibuja cuando algo cambia.
##
## Controles: click izq. asigna (camino incluido), click der. quita,
## arrastrar mueve la vista, rueda hace zoom.
##
## Cada cluster se pinta con el color de su temática; las pasivas menores toman
## ese color al asignarse, y notables y piedras angulares muestran su icono.

signal node_hovered(node_id: int)  # -1 = ninguno
signal node_clicked(node_id: int, button: MouseButton)
## Click en el medallón de la ascendencia (junto al inicio de la clase).
signal ascendancy_clicked

const GRID_CELL := 128.0
const MIN_ZOOM := 0.15
const MAX_ZOOM := 2.5
const DRAG_THRESHOLD := 5.0

const COLOR_BG := Color("0d0b10")
const COLOR_EDGE := Color("3a3442")
const COLOR_ALLOCATED := Color("e8b64c")
const COLOR_PREVIEW := Color("6fb36b")
const COLOR_PREVIEW_BAD := Color("b35050")
const COLOR_NODE := Color("1e1b24")
const COLOR_TEXT := Color("e8d9b0")

var allocation: PassiveAllocation
## Plan (T83): nodos marcados sin gastar (anillo cian) y, en modo plan, de dónde
## sale el camino previsto (lo asignado + lo planeado).
var planned: Dictionary = {}
var path_source: PassiveAllocation
const COLOR_PLANNED := Color("4fd0e0")
const COLOR_CONSTELLATION := Color("c9a7f0")
## Arte (T85): fondo de cada región con el color de su clase (id del nodo de inicio
## -> Color, lo pone la pantalla), línea que se ilumina al asignar y destello al
## completar un grupo.
var region_colors: Dictionary = {}
const REGION_RADIUS := 760.0
## Por debajo de este zoom, el árbol se dibuja simplificado (T89b).
const LOD_FAR_ZOOM := 0.5
## Desde este zoom, el modo simplificado conserva los iconos de notables y piedras angulares.
const LOD_ICON_ZOOM := 0.3
const GLOW_TIME := 0.9
const CLUSTER_FLASH_TIME := 1.3
var _prev_alloc: Dictionary = {}
var _edge_glow: Dictionary = {}       # Vector2i -> segundo en que se iluminó
var _cluster_flashes: Array[Dictionary] = []   # {pos, t0, color}
## Puntos disponibles: si el camino previsto cuesta más, se pinta en rojo.
var available_points := 0
var zoom := 0.55
## Posición en pantalla del origen (0, 0) del árbol.
var offset := Vector2.ZERO

var _hovered_id := -1
var _preview: Dictionary = {}  # ids del camino previsto -> true
var _grid: Dictionary = {}     # Vector2i -> Array de ids
var _grid_tree: PassiveTree
var _pressed := false
var _drag_distance := 0.0
var _search: Dictionary = {}   # ids que coinciden con la búsqueda -> true
## Estado del medallón de ascendencia: {unlocked, pending, name}.
var ascendancy_info: Dictionary = {}
## Chips engastados (id de nodo -> ExpansionChip), los pone la pantalla del árbol.
var chips: Dictionary = {}
var _medallion_hover := false
const MEDALLION_RADIUS := 30.0
## Rectángulo de todo el árbol (minimapa, T94).
var _bounds := Rect2()


func _ready() -> void:
	clip_contents = true
	mouse_filter = Control.MOUSE_FILTER_STOP


func setup(p_allocation: PassiveAllocation) -> void:
	if allocation and allocation.changed.is_connected(_on_allocation_changed):
		allocation.changed.disconnect(_on_allocation_changed)
	allocation = p_allocation
	allocation.changed.connect(_on_allocation_changed)
	if _grid_tree != allocation.tree:
		_build_grid(allocation.tree)
		_bounds = Rect2()
	_hovered_id = -1
	_prev_alloc = _alloc_set()   # al abrir no se ilumina nada
	_edge_glow.clear()
	_cluster_flashes.clear()
	_refresh_preview()
	queue_redraw()


func _alloc_set() -> Dictionary:
	var s := {}
	for id in allocation.get_allocated_ids():
		s[id] = true
	return s


## Grupos (clusters) que quedan completos con `after` y no lo estaban con `before`.
static func completed_clusters(tree: PassiveTree, before: Dictionary, after: Dictionary) -> Array[String]:
	var touched := {}
	for id in after:
		if not before.has(id):
			var c: String = tree.get_node_data(int(id)).cluster
			if c != "":
				touched[c] = true
	var out: Array[String] = []
	for c in touched:
		var full := true
		for n: PassiveNode in tree.nodes.values():
			if n.cluster == c and not after.has(n.id):
				full = false
				break
		if full:
			out.append(c)
	return out


static func _now() -> float:
	return Time.get_ticks_msec() / 1000.0


func center_on(tree_pos: Vector2) -> void:
	var view_size := size if size != Vector2.ZERO else get_viewport_rect().size
	offset = view_size / 2.0 - tree_pos * zoom
	queue_redraw()


static func node_radius(n: PassiveNode) -> float:
	match n.kind:
		PassiveNode.Kind.CLASS_START:
			return 30.0
		PassiveNode.Kind.KEYSTONE:
			return 30.0
		PassiveNode.Kind.NOTABLE:
			return 22.0
	return 10.0


## Resalta (con un anillo que late) los nodos que coinciden con una búsqueda.
func set_search(ids: Array) -> void:
	_search.clear()
	for id in ids:
		_search[id] = true
	queue_redraw()


func _process(_delta: float) -> void:
	var now := _now()
	for k in _edge_glow.keys():
		if now - float(_edge_glow[k]) > GLOW_TIME:
			_edge_glow.erase(k)
	_cluster_flashes = _cluster_flashes.filter(func(f: Dictionary) -> bool: return now - float(f["t0"]) <= CLUSTER_FLASH_TIME)
	if is_visible_in_tree() and allocation != null:
		queue_redraw()  # el flujo de luz de las líneas asignadas (T94), la búsqueda y los destellos están animados


## Detrás del inicio de la clase (hacia el centro, donde no hay pasivas); para
## la clase central, debajo de su inicio.
func medallion_position() -> Vector2:
	var start := allocation.tree.get_node_data(allocation.start_node_id).position
	var dir := -start.normalized() if start.length() > 1.0 else Vector2(0, 1)
	return start + dir * 95.0


static func border_color(n: PassiveNode) -> Color:
	match n.kind:
		PassiveNode.Kind.CLASS_START:
			return Color("e0e0e0")
		PassiveNode.Kind.KEYSTONE:
			return Color("b04ad9")
		PassiveNode.Kind.NOTABLE:
			return Color("d9a441")
	return Color("8a8293")


## Lo que tardó el último dibujo (ms), para medir el árbol 2.0 (T89b).
var last_draw_ms := 0.0


func _draw() -> void:
	var t0 := Time.get_ticks_usec()
	_draw_tree()
	last_draw_ms = (Time.get_ticks_usec() - t0) / 1000.0


func _draw_tree() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), COLOR_BG)
	if allocation == null:
		return
	var tree := allocation.tree
	var visible_rect := Rect2(_to_tree(Vector2.ZERO), size / zoom).grow(40.0)
	var too_expensive := _preview.size() > available_points
	# Nivel de detalle (T89b): de lejos, nodos como cuadros y círculos lisos, sin iconos,
	# aros ni adornos; con ~1400 nodos en pantalla, el dibujo completo se hace pesado.
	var far := zoom < LOD_FAR_ZOOM
	_draw_regions(tree)   # fondo con parallax (T94), en coordenadas de pantalla
	draw_set_transform(offset, 0.0, Vector2(zoom, zoom))
	_draw_clusters(tree, visible_rect)
	var now := _now()

	for e in tree.edges:
		var a := tree.get_node_data(e.x)
		var b := tree.get_node_data(e.y)
		if not Rect2(a.position, Vector2.ZERO).expand(b.position).grow(1.0).intersects(visible_rect):
			continue
		var a_on := allocation.is_allocated(a.id)
		var b_on := allocation.is_allocated(b.id)
		var color := COLOR_EDGE
		var width := 3.0
		if a_on and b_on:
			color = COLOR_ALLOCATED
			width = 6.0
		elif not _preview.is_empty() and (a_on or planned.has(a.id) or _preview.has(a.id)) and (b_on or planned.has(b.id) or _preview.has(b.id)) \
				and (_preview.has(a.id) or _preview.has(b.id)):
			color = COLOR_PREVIEW_BAD if too_expensive else COLOR_PREVIEW
			width = 5.0
		elif not planned.is_empty() and (a_on or planned.has(a.id)) and (b_on or planned.has(b.id)):
			color = Color(COLOR_PLANNED, 0.8)   # el camino del plan
			width = 4.0
		draw_line(a.position, b.position, color, width, not far)   # de lejos, sin suavizado (T89b)
		if a_on and b_on and not far:
			# Flujo de luz por las líneas asignadas (T94): un destello que las recorre.
			var phase := fmod(now * 0.55 + float((e.x * 7 + e.y * 13) % 17) / 17.0, 1.0)
			draw_circle(a.position.lerp(b.position, phase), 3.2, Color(1.0, 0.93, 0.7, 0.75 * sin(phase * PI)))
		if not _edge_glow.is_empty() and _edge_glow.has(e) and now >= float(_edge_glow[e]):
			# Recién asignada (T85): un brillo que se apaga y una chispa que la recorre;
			# con T94 cada tramo empieza un poco después que el anterior (pulso por el camino).
			var gt := clampf((now - float(_edge_glow[e])) / GLOW_TIME, 0.0, 1.0)
			draw_line(a.position, b.position, Color(1.0, 0.95, 0.7, 0.7 * (1.0 - gt)), 6.0 + 10.0 * (1.0 - gt), true)
			draw_circle(a.position.lerp(b.position, minf(1.0, gt * 2.0)), 7.0 * (1.0 - gt) + 2.0, Color(1, 1, 0.85, 1.0 - gt))

	var font := get_theme_default_font()
	var pulse := 0.5 + 0.5 * sin(Time.get_ticks_msec() / 150.0)
	for id in tree.nodes:
		var n: PassiveNode = tree.nodes[id]
		if not visible_rect.has_point(n.position):
			continue
		var r := node_radius(n)
		var on := allocation.is_allocated(n.id)
		var in_preview := _preview.has(n.id)
		var available := not on and allocation.can_allocate(n.id)
		var theme_color := tree.theme_color(n.theme)
		if far:
			var col := COLOR_ALLOCATED if on else (COLOR_PLANNED if planned.has(n.id) else (COLOR_PREVIEW if in_preview else theme_color.darkened(0.25 if available else 0.55)))
			if n.kind == PassiveNode.Kind.MINOR:
				draw_rect(Rect2(n.position - Vector2(r, r), Vector2(r, r) * 2.0), col)
			elif zoom >= LOD_ICON_ZOOM and (n.kind == PassiveNode.Kind.NOTABLE or n.kind == PassiveNode.Kind.KEYSTONE):
				# A media distancia, los notables conservan su icono y un aro simple.
				draw_circle(n.position, r, Color("120f16"))
				PassiveIcons.draw(self, n.position, r * 1.45, n.icon, Color.WHITE if on else Color(0.5, 0.5, 0.55))
				draw_arc(n.position, r, 0.0, TAU, 16, col if not on else COLOR_ALLOCATED, 4.0, false)
			else:
				draw_circle(n.position, r, col if n.kind != PassiveNode.Kind.CLASS_START else Color("e0e0e0"))
			continue
		match n.kind:
			PassiveNode.Kind.MINOR:
				var fill := theme_color.darkened(0.15) if on else COLOR_NODE
				if in_preview:
					fill = COLOR_PREVIEW_BAD if too_expensive else COLOR_PREVIEW
				draw_circle(n.position, r, fill)
				var ring := COLOR_ALLOCATED if on else theme_color.darkened(0.55 if not available else 0.1)
				draw_polyline(TreeArt.frame(TreeArt.frame_kind(n), n.position, r), ring, 2.5)   # marco de píxel (T94)
				# Icono en pixel art de su temática (T85), solo si se ve lo bastante grande.
				if r * zoom >= 7.0 and n.theme != "" and PassiveIcons.has_icon(n.theme):
					PassiveIcons.draw(self, n.position, r * 1.25, n.theme, Color(1, 1, 1, 0.95) if on else Color(1, 1, 1, 0.3))
			PassiveNode.Kind.NOTABLE, PassiveNode.Kind.KEYSTONE:
				var keystone := n.kind == PassiveNode.Kind.KEYSTONE
				draw_circle(n.position, r, Color("120f16"))
				# Icono: apagado hasta que se asigna (como en PoE).
				var tint := Color.WHITE if on else Color(0.5, 0.5, 0.55)
				if in_preview:
					tint = Color(0.75, 1.0, 0.75) if not too_expensive else Color(1.0, 0.6, 0.6)
				PassiveIcons.draw(self, n.position, r * 1.45, n.icon, tint)
				var frame := COLOR_ALLOCATED if on else (theme_color if not keystone else Color("b04ad9"))
				if not on and not available:
					frame = frame.darkened(0.45)
				# Marco de pixel art según el tipo (T94): octógono con remaches, hexágono doble
				# para las piedras angulares, rombo para las maestrías, estrella en constelaciones.
				var fk := TreeArt.frame_kind(n)
				var outline := TreeArt.frame(fk, n.position, r)
				draw_polyline(outline, Color("0a080c"), 7.0)
				draw_polyline(outline, frame, 4.0)
				if fk == "notable":
					for k in 4:
						var stud := n.position + Vector2.from_angle(PI / 4.0 + TAU * k / 4.0) * (r + 1.0)
						draw_rect(Rect2(stud - Vector2(3, 3), Vector2(6, 6)), frame.lightened(0.25))
				if keystone:
					draw_polyline(TreeArt.frame("keystone", n.position, r + 7.0), frame.darkened(0.2), 2.0)
				if n.is_mastery():
					# Maestría: un rombo por opción encima del nodo; el elegido, encendido.
					var chosen := allocation.mastery_choice(n.id)
					for k in n.choices.size():
						var pp := n.position + Vector2.from_angle(-PI / 2.0 + (k - (n.choices.size() - 1) / 2.0) * 0.45) * (r + 10.0)
						var lit := on and k == chosen
						draw_colored_polygon(PackedVector2Array([pp + Vector2(0, -5), pp + Vector2(4, 0), pp + Vector2(0, 5), pp + Vector2(-4, 0)]),
							Color("8ae0c0") if lit else Color(0.35, 0.45, 0.42))
				if in_preview:
					draw_arc(n.position, r + 3.0, 0.0, TAU, 40, COLOR_PREVIEW_BAD if too_expensive else COLOR_PREVIEW, 2.5, true)
			PassiveNode.Kind.CLASS_START:
				draw_circle(n.position, r, COLOR_ALLOCATED if on else COLOR_NODE)
				draw_arc(n.position, r, 0.0, TAU, 40, Color("e0e0e0"), 3.5, true)
				var label_pos := n.position + Vector2(-150.0, r + 34.0)
				draw_string_outline(font, label_pos, n.title, HORIZONTAL_ALIGNMENT_CENTER, 300.0, 26, 8, COLOR_BG)
				draw_string(font, label_pos, n.title, HORIZONTAL_ALIGNMENT_CENTER, 300.0, 26, COLOR_TEXT)
		if tree.is_socket(n.id):
			# Ranura de chip: hexágono dorado alrededor y, si tiene chip, el chip encima.
			var hexa := PackedVector2Array()
			for k in 7:
				hexa.append(n.position + Vector2.from_angle(PI / 6.0 + TAU * k / 6.0) * (r + 11.0))
			draw_polyline(hexa, Color("c8a050") if on else Color("6a5a3a"), 3.0, true)
			var chip: Item = chips.get(n.id, null)
			if chip:
				ItemIcons.draw_item(self, Rect2(n.position + Vector2(r * 0.4, -r * 1.3), Vector2(r, r)), chip, Color.WHITE if on else Color(1, 1, 1, 0.4))
				if chip is ExpansionChip and not (chip as ExpansionChip).transform_map().is_empty():
					# Radio en el que transforma los nodos.
					draw_arc(n.position, ExpansionChip.TRANSFORM_RADIUS, 0.0, TAU, 96, Color(Rarity.item_color(chip.rarity), 0.55 if on else 0.2), 2.0, true)
		if not n.requires.is_empty():
			# Constelación (T84): cuatro puntas de estrella alrededor; apagadas si no llegan los atributos.
			var lit := on or allocation.meets_requirements(n.id)
			for k in 4:
				var d := Vector2.from_angle(PI / 4.0 + TAU * k / 4.0)
				draw_line(n.position + d * (r + 2.0), n.position + d * (r + 9.0), COLOR_CONSTELLATION if lit else COLOR_CONSTELLATION.darkened(0.6), 2.0, true)
		if n.style:
			draw_arc(n.position, r + 8.0, 0.0, TAU, 40, Color(COLOR_ALLOCATED, 0.7), 2.0, true)   # notable de estilo (T84)
		if n.capstone:
			draw_arc(n.position, r + 6.0, 0.0, TAU, 40, Color("b04ad9") if not on else COLOR_ALLOCATED.darkened(0.2), 2.0, true)   # como una piedra angular
		if planned.has(n.id):
			draw_arc(n.position, r + 4.0, 0.0, TAU, 32, COLOR_PLANNED, 3.0, true)   # planeado (T83)
		if _search.has(n.id):
			draw_arc(n.position, r + 8.0 + pulse * 4.0, 0.0, TAU, 32, Color(1.0, 0.85, 0.2, 0.5 + 0.5 * pulse), 3.0, true)
		if n.id == _hovered_id:
			draw_arc(n.position, r + 5.0, 0.0, TAU, 32, Color.WHITE, 2.0, true)

	if zoom < LOD_ICON_ZOOM:
		_draw_plaques(tree, visible_rect)
	if not ascendancy_info.is_empty():
		_draw_medallion(font, pulse)
	_draw_cluster_flashes()
	draw_set_transform(Vector2.ZERO)
	_draw_labels(tree, visible_rect, font)
	_draw_minimap(tree)


## De lejos (T94): un medallón en el centro de cada cluster con el icono de su familia.
func _draw_plaques(tree: PassiveTree, visible_rect: Rect2) -> void:
	for c in tree.clusters.values():
		var center := Vector2(c["x"], c["y"])
		if c["theme"] == "" or not visible_rect.has_point(center):
			continue
		var color := tree.theme_color(c["theme"])
		var pr := clampf(11.0 / zoom, 46.0, 90.0)   # unos 11 px en pantalla como mínimo
		draw_circle(center, pr, Color("120f16"))
		draw_polyline(TreeArt.frame("notable", center, pr), color.lightened(0.15), 6.0)
		if PassiveIcons.has_icon(c["theme"]):
			PassiveIcons.draw(self, center, pr * 1.4, c["theme"], Color(1, 1, 1, 0.9))


## Minimapa (T94): el árbol entero en una esquina, con lo asignado y el encuadre actual.
func _draw_minimap(tree: PassiveTree) -> void:
	if _bounds.size == Vector2.ZERO:
		_bounds = TreeArt.bounds(tree)
	var map := TreeArt.minimap_rect(size)
	draw_rect(map.grow(3.0), Color(0, 0, 0, 0.75))
	draw_rect(map, Color("15111a"))
	for start_id in region_colors:
		var s := tree.get_node_data(int(start_id))
		if s != null:
			draw_circle(TreeArt.to_minimap(s.position, _bounds, map), 16.0, Color(region_colors[start_id], 0.18))
	for c in tree.clusters.values():
		draw_rect(Rect2(TreeArt.to_minimap(Vector2(c["x"], c["y"]), _bounds, map) - Vector2(1.5, 1.5), Vector2(3, 3)), Color(tree.theme_color(c["theme"]), 0.7))
	for id in allocation.get_allocated_ids():
		draw_rect(Rect2(TreeArt.to_minimap(tree.get_node_data(id).position, _bounds, map) - Vector2(1, 1), Vector2(2, 2)), COLOR_ALLOCATED)
	var view_a := TreeArt.to_minimap(_to_tree(Vector2.ZERO), _bounds, map)
	var view_b := TreeArt.to_minimap(_to_tree(size), _bounds, map)
	var frame_rect := Rect2(view_a, view_b - view_a).intersection(map)
	draw_rect(frame_rect, Color(1, 1, 1, 0.85), false, 1.5)
	draw_rect(map.grow(3.0), Color("5a4a3a"), false, 2.0)


func _draw_medallion(font: Font, pulse: float) -> void:
	var p := medallion_position()
	var start := allocation.tree.get_node_data(allocation.start_node_id).position
	var unlocked: bool = ascendancy_info.get("unlocked", false)
	var pending: bool = ascendancy_info.get("pending", false)
	draw_line(start, p, Color(COLOR_ALLOCATED, 0.5) if unlocked else COLOR_EDGE, 3.0, true)
	if pending:
		draw_circle(p, MEDALLION_RADIUS + 10.0 + pulse * 6.0, Color(1.0, 0.85, 0.3, 0.12 + 0.12 * pulse))
	draw_circle(p, MEDALLION_RADIUS, Color("1a1410") if unlocked else COLOR_NODE)
	var gold := Color("d9a441") if unlocked else Color("5a5363")
	draw_arc(p, MEDALLION_RADIUS, 0.0, TAU, 40, gold if not _medallion_hover else Color.WHITE, 4.0, true)
	draw_arc(p, MEDALLION_RADIUS - 7.0, 0.0, TAU, 40, Color(gold, 0.5), 1.5, true)
	# Estrella de la ascendencia.
	var pts := PackedVector2Array()
	for k in 10:
		pts.append(p + Vector2.from_angle(-PI / 2.0 + TAU * k / 10.0) * (16.0 if k % 2 == 0 else 7.0))
	draw_colored_polygon(pts, gold)
	var label: String = ascendancy_info.get("name", "Ascendencia")
	if not unlocked:
		label = "Ascendencia · nv. %d" % CharacterData.ASCENDANCY_LEVEL
	draw_string_outline(font, p + Vector2(-160, MEDALLION_RADIUS + 26), label, HORIZONTAL_ALIGNMENT_CENTER, 320, 18, 6, COLOR_BG)
	draw_string(font, p + Vector2(-160, MEDALLION_RADIUS + 26), label, HORIZONTAL_ALIGNMENT_CENTER, 320, 18, gold.lightened(0.2))


## Fondo (T94): dos capas de estrellas y una nebulosa por región con el color de su
## clase, cada capa con su parallax (se mueven menos que el árbol al arrastrar).
func _draw_regions(tree: PassiveTree) -> void:
	var view := size
	var screen := Rect2(Vector2.ZERO, view)
	for start_id in region_colors:
		var n := tree.get_node_data(int(start_id))
		if n == null:
			continue
		var c: Color = region_colors[start_id]
		for blob in TreeArt.nebula_blobs(n.position, int(start_id) * 31 + 7):
			var p := TreeArt.parallax(Vector2(blob.x, blob.y), zoom, offset, view, TreeArt.NEBULA_DEPTH)
			var rr: float = blob.z * zoom * TreeArt.NEBULA_DEPTH
			if not screen.grow(rr).has_point(p):
				continue
			for k in 4:
				draw_circle(p, rr * (1.0 - k * 0.22), Color(c, 0.02 + 0.006 * k))
	for layer in TreeArt.STAR_DEPTHS.size():
		var depth: float = TreeArt.STAR_DEPTHS[layer]
		for s: Vector3 in TreeArt.stars(layer):
			var p := TreeArt.parallax(Vector2(s.x, s.y), zoom, offset, view, depth)
			if screen.has_point(p):
				var px := 1.0 + layer
				draw_rect(Rect2(p, Vector2(px, px)), Color(0.85, 0.85, 1.0, s.z * (0.35 + 0.25 * layer)))


## Fondos de los clusters: la silueta de su símbolo (corazón, llama, rayo...)
## brillando con el color de su temática; los que no tienen forma, un halo.


## Destello al completar un grupo (T85): un anillo que se abre y chispas de píxel.
func _draw_cluster_flashes() -> void:
	var now := _now()
	for f in _cluster_flashes:
		if now < float(f["t0"]):
			continue   # espera a que llegue el pulso
		var t := clampf((now - float(f["t0"])) / CLUSTER_FLASH_TIME, 0.0, 1.0)
		var c: Color = f["color"]
		var pos: Vector2 = f["pos"]
		if f.get("big", false):
			# Constelación: una estrella de ocho puntas que se abre.
			draw_polyline(TreeArt.frame("constellation", pos, 60.0 + 260.0 * t), Color(c.lightened(0.3), 0.9 * (1.0 - t)), 6.0 * (1.0 - t) + 1.5)
		draw_arc(pos, 40.0 + 160.0 * t, 0.0, TAU, 48, Color(c.lightened(0.4), 0.9 * (1.0 - t)), 5.0 * (1.0 - t) + 1.0, true)
		draw_circle(pos, 70.0 * (1.0 - t), Color(c, 0.25 * (1.0 - t)))
		for k in 10:
			var d := Vector2.from_angle(TAU * k / 10.0 + t)
			var s := 6.0 * (1.0 - t) + 2.0
			draw_rect(Rect2(pos + d * (30.0 + 190.0 * t) - Vector2(s, s) * 0.5, Vector2(s, s)), Color(1.0, 0.95, 0.75, 1.0 - t))


func _draw_clusters(tree: PassiveTree, visible_rect: Rect2) -> void:
	for c in tree.clusters.values():
		var center := Vector2(c["x"], c["y"])
		var radius: float = c["radius"] + 34.0
		if not visible_rect.grow(radius).has_point(center):
			continue
		var color := tree.theme_color(c["theme"])
		if c.has("segments"):
			if c.has("fill"):
				var poly := PackedVector2Array()
				for p in c["fill"]:
					poly.append(Vector2(p[0], p[1]))
				draw_colored_polygon(poly, Color(color, 0.08))
				poly.append(poly[0])
				draw_polyline(poly, Color(color, 0.30), 3.0, true)
			for s in c["segments"]:
				var a := Vector2(s[0], s[1])
				var b := Vector2(s[2], s[3])
				draw_line(a, b, Color(color, 0.07), 38.0, true)   # resplandor ancho
				draw_line(a, b, Color(color, 0.10), 20.0, true)
			continue
		draw_circle(center, radius, Color(color, 0.07))
		draw_arc(center, radius, 0.0, TAU, 48, Color(color, 0.22), 2.0, true)


## Textos en coordenadas de pantalla (tamaño legible con cualquier zoom):
## nombres de clusters de lejos, nombres de notables de cerca.
func _draw_labels(tree: PassiveTree, visible_rect: Rect2, font: Font) -> void:
	var used: Array[Rect2] = []  # para no pintar etiquetas encima de otras
	if zoom < 0.35:
		# De lejos (T94): el nombre de cada región, del color de su clase.
		for start_id in region_colors:
			var s := tree.get_node_data(int(start_id))
			if s != null and visible_rect.has_point(s.position):
				_label(font, s.position * zoom + offset + Vector2(0, -30), s.title, 22, (region_colors[start_id] as Color).lightened(0.35), used)
	if zoom >= 0.25 and zoom < 0.8:
		for c in tree.clusters.values():
			var center := Vector2(c["x"], c["y"])
			if visible_rect.has_point(center):
				var top := (center - Vector2(0, c["radius"] + 44.0)) * zoom + offset
				_label(font, top, c["name"], 13, tree.theme_color(c["theme"]).lightened(0.25), used)
	if zoom >= 0.8:
		for id in tree.nodes:
			var n: PassiveNode = tree.nodes[id]
			if (n.kind == PassiveNode.Kind.NOTABLE or n.kind == PassiveNode.Kind.KEYSTONE) and visible_rect.has_point(n.position):
				var p := (n.position + Vector2(0, node_radius(n) + 10.0)) * zoom + offset + Vector2(0, 10)
				_label(font, p, n.title, 12, COLOR_TEXT, used)


## Etiqueta centrada en `pos` (pantalla); se omite si chocaría con otra ya dibujada.
func _label(font: Font, pos: Vector2, text: String, font_size: int, color: Color, used: Array[Rect2]) -> void:
	var w := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	var rect := Rect2(pos - Vector2(w / 2.0, font_size), Vector2(w, font_size + 4.0))
	for r in used:
		if r.intersects(rect):
			return
	used.append(rect)
	draw_string_outline(font, rect.position + Vector2(0, font_size), text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, 4, COLOR_BG)
	draw_string(font, rect.position + Vector2(0, font_size), text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, color)


func _gui_input(event: InputEvent) -> void:
	if allocation == null:
		return
	var mb := event as InputEventMouseButton
	if mb:
		if mb.button_index == MOUSE_BUTTON_WHEEL_UP and mb.pressed:
			_zoom_at(mb.position, 1.15)
		elif mb.button_index == MOUSE_BUTTON_WHEEL_DOWN and mb.pressed:
			_zoom_at(mb.position, 1.0 / 1.15)
		elif mb.button_index == MOUSE_BUTTON_LEFT:
			if mb.pressed and TreeArt.minimap_rect(size).has_point(mb.position) and _bounds.size != Vector2.ZERO:
				center_on(TreeArt.from_minimap(mb.position, _bounds, TreeArt.minimap_rect(size)))   # click en el minimapa: saltar ahí
				_pressed = false
			elif mb.pressed:
				_pressed = true
				_drag_distance = 0.0
			else:
				if _pressed and _drag_distance < DRAG_THRESHOLD and _medallion_hover:
					ascendancy_clicked.emit()
				elif _pressed and _drag_distance < DRAG_THRESHOLD and _hovered_id != -1:
					node_clicked.emit(_hovered_id, MOUSE_BUTTON_LEFT)
				_pressed = false
		elif mb.button_index == MOUSE_BUTTON_RIGHT and mb.pressed and _hovered_id != -1:
			node_clicked.emit(_hovered_id, MOUSE_BUTTON_RIGHT)
		accept_event()
		return
	var mm := event as InputEventMouseMotion
	if mm:
		if _pressed:
			_drag_distance += mm.relative.length()
			offset += mm.relative
			queue_redraw()
		_update_hover(mm.position)


func _notification(what: int) -> void:
	if what == NOTIFICATION_MOUSE_EXIT:
		_pressed = false
		_set_hovered(-1)


## Sitios a los que salta la cruceta del cursor de mando (GamepadCursor): los
## nodos que se ven, en coordenadas globales.
func cursor_targets() -> Array[Rect2]:
	var out: Array[Rect2] = []
	if allocation == null:
		return out
	var visible_rect := Rect2(_to_tree(Vector2.ZERO), size / zoom)
	var xf := get_global_transform()
	for id in allocation.tree.nodes:
		var n: PassiveNode = allocation.tree.nodes[id]
		if visible_rect.has_point(n.position):
			var r := node_radius(n) * zoom
			out.append(Rect2(xf * (offset + n.position * zoom) - Vector2(r, r), Vector2(r, r) * 2.0))
	return out


func _to_tree(screen_pos: Vector2) -> Vector2:
	return (screen_pos - offset) / zoom


func _zoom_at(screen_pos: Vector2, factor: float) -> void:
	var anchor := _to_tree(screen_pos)
	zoom = clampf(zoom * factor, MIN_ZOOM, MAX_ZOOM)
	offset = screen_pos - anchor * zoom
	queue_redraw()


func _update_hover(screen_pos: Vector2) -> void:
	var p := _to_tree(screen_pos)
	var on_medallion := not ascendancy_info.is_empty() and p.distance_to(medallion_position()) <= MEDALLION_RADIUS + 4.0
	if on_medallion != _medallion_hover:
		_medallion_hover = on_medallion
		mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND if on_medallion else Control.CURSOR_ARROW
		queue_redraw()
	var cell := _cell_of(p)
	var best := -1
	var best_dist := INF
	for dx in range(-1, 2):
		for dy in range(-1, 2):
			for id in _grid.get(cell + Vector2i(dx, dy), []):
				var n := allocation.tree.get_node_data(id)
				var dist := n.position.distance_to(p)
				if dist <= node_radius(n) + 6.0 and dist < best_dist:
					best = id
					best_dist = dist
	_set_hovered(best)


func _set_hovered(id: int) -> void:
	if id == _hovered_id:
		return
	_hovered_id = id
	_refresh_preview()
	node_hovered.emit(id)
	queue_redraw()


func _refresh_preview() -> void:
	_preview.clear()
	var source := path_source if path_source else allocation
	if _hovered_id != -1 and source:
		for pid in source.find_path(_hovered_id):
			_preview[pid] = true


func _on_allocation_changed() -> void:
	# Lo recién asignado: sus líneas se iluminan y, si completa un grupo, destello.
	var now_set := _alloc_set()
	var tree := allocation.tree
	var t := _now()
	# Pulso (T94): cada tramo se ilumina un poco después que el anterior, desde lo que ya
	# estaba asignado hasta el nodo pulsado.
	var depths := TreeArt.path_depths(tree, _prev_alloc, now_set)
	for id in now_set:
		if _prev_alloc.has(id):
			continue
		var t_id := t + (int(depths.get(id, 1)) - 1) * TreeArt.PULSE_STEP
		for nb in tree.neighbors(int(id)):
			if now_set.has(nb):
				var t_edge := maxf(t_id, float(_edge_glow.get(Vector2i(id, nb), 0.0)))
				_edge_glow[Vector2i(id, nb)] = t_edge   # en tree.edges puede ir en cualquier orden
				_edge_glow[Vector2i(nb, id)] = t_edge
	var done := completed_clusters(tree, _prev_alloc, now_set)
	if done.size() > 3:
		done = done.slice(0, 3)   # al cargar una build entera, sin fuegos artificiales por todo el árbol
	for c in done:
		var pos := Vector2.ZERO
		var count := 0
		var theme := ""
		var constellation := false
		for n: PassiveNode in tree.nodes.values():
			if n.cluster == c:
				pos += n.position
				count += 1
				theme = n.theme
				constellation = constellation or n.constellation != ""
		# Constelación completa (T94): destello violeta y más grande.
		_cluster_flashes.append({"pos": pos / maxf(1.0, count), "t0": t + float(depths.size()) * TreeArt.PULSE_STEP * 0.5,
			"color": COLOR_CONSTELLATION if constellation else tree.theme_color(theme), "big": constellation})
		Sfx.play("level_up", -12.0 if not constellation else -6.0, 1.5 if not constellation else 1.1)
	_prev_alloc = now_set
	_refresh_preview()
	queue_redraw()


func _cell_of(p: Vector2) -> Vector2i:
	return Vector2i(floori(p.x / GRID_CELL), floori(p.y / GRID_CELL))


func _build_grid(tree: PassiveTree) -> void:
	_grid.clear()
	_grid_tree = tree
	for id in tree.nodes:
		var c := _cell_of(tree.get_node_data(id).position)
		if not _grid.has(c):
			_grid[c] = []
		_grid[c].append(id)
