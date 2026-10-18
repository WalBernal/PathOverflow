class_name PassiveTreeView
extends Control
## Dibuja el árbol pasivo entero en UN solo _draw(), en lugar de un Control por
## nodo. Con descarte por viewport y una rejilla espacial para el hover escala
## sin problema a miles de nodos. Solo se redibuja cuando algo cambia.
##
## Controles: click izq. asigna (camino incluido), click der. quita,
## arrastrar mueve la vista, rueda hace zoom.

signal node_hovered(node_id: int)  # -1 = ninguno
signal node_clicked(node_id: int, button: MouseButton)

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
	_hovered_id = -1
	_refresh_preview()
	queue_redraw()


func center_on(tree_pos: Vector2) -> void:
	var view_size := size if size != Vector2.ZERO else get_viewport_rect().size
	offset = view_size / 2.0 - tree_pos * zoom
	queue_redraw()


static func node_radius(n: PassiveNode) -> float:
	match n.kind:
		PassiveNode.Kind.CLASS_START:
			return 30.0
		PassiveNode.Kind.KEYSTONE:
			return 26.0
		PassiveNode.Kind.NOTABLE:
			return 18.0
	return 10.0


static func border_color(n: PassiveNode) -> Color:
	match n.kind:
		PassiveNode.Kind.CLASS_START:
			return Color("e0e0e0")
		PassiveNode.Kind.KEYSTONE:
			return Color("b04ad9")
		PassiveNode.Kind.NOTABLE:
			return Color("d9a441")
	return Color("8a8293")


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), COLOR_BG)
	if allocation == null:
		return
	var tree := allocation.tree
	var visible_rect := Rect2(_to_tree(Vector2.ZERO), size / zoom).grow(40.0)
	var too_expensive := _preview.size() > available_points
	draw_set_transform(offset, 0.0, Vector2(zoom, zoom))

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
		elif not _preview.is_empty() and (a_on or _preview.has(a.id)) and (b_on or _preview.has(b.id)):
			color = COLOR_PREVIEW_BAD if too_expensive else COLOR_PREVIEW
			width = 5.0
		draw_line(a.position, b.position, color, width, true)

	var font := get_theme_default_font()
	for id in tree.nodes:
		var n: PassiveNode = tree.nodes[id]
		if not visible_rect.has_point(n.position):
			continue
		var r := node_radius(n)
		var on := allocation.is_allocated(n.id)
		var fill := COLOR_NODE
		if on:
			fill = COLOR_ALLOCATED
		elif _preview.has(n.id):
			fill = COLOR_PREVIEW_BAD if too_expensive else COLOR_PREVIEW
		var border := border_color(n)
		if not on and allocation.can_allocate(n.id):
			border = border.lightened(0.4)
		draw_circle(n.position, r, fill)
		draw_arc(n.position, r, 0.0, TAU, 32, border, 2.0 if n.kind == PassiveNode.Kind.MINOR else 3.5, true)
		if n.id == _hovered_id:
			draw_arc(n.position, r + 6.0, 0.0, TAU, 32, Color.WHITE, 2.0, true)
		if n.kind == PassiveNode.Kind.CLASS_START:
			var label_pos := n.position + Vector2(-150.0, r + 34.0)
			draw_string_outline(font, label_pos, n.title, HORIZONTAL_ALIGNMENT_CENTER, 300.0, 26, 8, COLOR_BG)
			draw_string(font, label_pos, n.title, HORIZONTAL_ALIGNMENT_CENTER, 300.0, 26, COLOR_TEXT)

	draw_set_transform(Vector2.ZERO)


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
			if mb.pressed:
				_pressed = true
				_drag_distance = 0.0
			else:
				if _pressed and _drag_distance < DRAG_THRESHOLD and _hovered_id != -1:
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


func _to_tree(screen_pos: Vector2) -> Vector2:
	return (screen_pos - offset) / zoom


func _zoom_at(screen_pos: Vector2, factor: float) -> void:
	var anchor := _to_tree(screen_pos)
	zoom = clampf(zoom * factor, MIN_ZOOM, MAX_ZOOM)
	offset = screen_pos - anchor * zoom
	queue_redraw()


func _update_hover(screen_pos: Vector2) -> void:
	var p := _to_tree(screen_pos)
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
	if _hovered_id != -1 and allocation:
		for pid in allocation.find_path(_hovered_id):
			_preview[pid] = true


func _on_allocation_changed() -> void:
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
