class_name IconCache
## Iconos del HUD en texturas (T68): SkillIcon, ItemIcons y StatusIcon dibujan con
## decenas de formas, y el HUD se redibuja cada fotograma. Cada icono (por clave)
## se pinta una vez en un SubViewport que se renderiza una sola vez, y luego se
## dibuja su textura. Hasta que está lista (un par de fotogramas) o sin pantalla
## (pruebas), texture() devuelve null y se dibuja con formas como antes.

const SIZE := 96   # cabe a 160 % de interfaz sin verse borroso
const READY_FRAMES := 3

static var _entries := {}   # clave -> {viewport, frame}
static var _host: Node


## Textura del icono `key` (pintado por `painter.call(canvas_item, rect, modulate)` en un
## rectángulo de SIZE de ancho y `aspect` veces eso de alto), o null si aún no hay.
static func texture(key: String, painter: Callable, aspect := 1.0) -> Texture2D:
	var e: Dictionary = _entries.get(key, {})
	if not e.is_empty():
		if not is_instance_valid(e["viewport"]):
			_entries.erase(key)
			return null
		if Engine.get_frames_drawn() - int(e["frame"]) < READY_FRAMES:
			return null
		return (e["viewport"] as SubViewport).get_texture()
	if DisplayServer.get_name() == "headless":
		return null
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null or tree.root == null:
		return null
	if _host == null or not is_instance_valid(_host):
		_host = Node.new()
		_host.name = "IconCache"
		tree.root.add_child.call_deferred(_host)
	var px := Vector2i(SIZE, maxi(8, roundi(SIZE * aspect)))
	var vp := SubViewport.new()
	vp.size = px
	vp.transparent_bg = true
	vp.disable_3d = true
	vp.render_target_update_mode = SubViewport.UPDATE_ONCE
	var canvas := Control.new()
	canvas.size = Vector2(px)
	canvas.draw.connect(func() -> void: painter.call(canvas, Rect2(Vector2.ZERO, Vector2(px)), Color.WHITE))
	vp.add_child(canvas)
	_host.add_child.call_deferred(vp)   # durante un _draw no se toca el árbol
	_entries[key] = {"viewport": vp, "frame": Engine.get_frames_drawn()}
	return null


static func cached_count() -> int:
	return _entries.size()


## Dibuja el icono en `ci`: con su textura si ya está, si no con formas.
static func draw(ci: CanvasItem, rect: Rect2, key: String, painter: Callable, modulate := Color.WHITE) -> void:
	var aspect := snappedf(rect.size.y / maxf(1.0, rect.size.x), 0.05)
	var tex := texture("%s@%.2f" % [key, aspect], painter, aspect)
	if tex:
		ci.draw_texture_rect(tex, rect, false, modulate)
	else:
		painter.call(ci, rect, modulate)
