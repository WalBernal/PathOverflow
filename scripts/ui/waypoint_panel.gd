class_name WaypointPanel
extends PanelContainer
## Ventana de waypoints como mapa del acto (T126): una pestaña por acto (solo los que
## tienen algún waypoint descubierto, sin spoilers) y, en cada una, sus zonas unidas por
## sus salidas, del campamento a la arena del jefe. Cada zona es un botón: las de waypoint
## descubierto llevan a ella (ratón, mando —el cursor salta entre botones— o toque); las
## demás se ven, pero sin nombre hasta haberlas pisado. Si la zona tiene una instancia
## viva, dice cuánto le queda y qué mecánica tiene (T118-T120). Ahora es la única forma
## de volver a un acto anterior (T113).

signal selected(zone_id: String)

const MAP_SIZE := Vector2(1040, 430)
const NODE_SIZE := Vector2(132, 62)
const LINK := Color("5a4a2e")
const LINK_KNOWN := Color("c8a050")

## Segundos que le quedan a la instancia de cada zona (T119, ZoneInstances.times) y su
## mecánica principal (T120), por zona.
var instance_times: Dictionary = {}
var instance_mechanics: Dictionary = {}
## Zonas que el personaje ya pisó (flags["visited"]): su nombre deja de ser «???».
var visited: Array = []

var _tabs: HBoxContainer
var _map: Control
var _acts: Array = []          # los actos que se enseñan (con algún waypoint descubierto)
var _act_index := 0
var _discovered: Array = []
var _current := ""
var _centers := {}             # zona -> centro del botón en el mapa (para las líneas)
var _edges: Array = []


func _ready() -> void:
	theme = UiStyle.make_theme()
	add_theme_stylebox_override("panel", UiStyle.panel_style())
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	add_child(box)
	box.add_child(UiStyle.label("Waypoints", 20, UiStyle.ACCENT))
	box.add_child(UiStyle.label("Teletransporte entre zonas. Sin cola, sin colas de mensajes. La única forma de volver a un acto anterior.", 12, UiStyle.MUTED))
	_tabs = HBoxContainer.new()
	_tabs.add_theme_constant_override("separation", 6)
	box.add_child(_tabs)
	_map = Control.new()
	_map.custom_minimum_size = MAP_SIZE
	_map.draw.connect(_draw_links)
	box.add_child(_map)
	box.add_child(UiStyle.button("Cerrar (Esc)", func() -> void: visible = false, 0))


## `acts`: GameData.acts (se pasa para que la ventana no dependa del autoload).
func open(discovered: Array, current_zone: String, acts: Array) -> void:
	_discovered = discovered
	_current = current_zone
	_acts.clear()
	_act_index = 0
	for a in acts:
		var any_known := false
		for z in a.get("zones", []):
			any_known = any_known or discovered.has(z["id"])
		if not any_known:
			continue
		for z in a.get("zones", []):
			if z["id"] == current_zone:
				_act_index = _acts.size()   # se abre en el acto donde estás
		_acts.append(a)
	for c in _tabs.get_children():
		_tabs.remove_child(c)
		c.queue_free()
	for i in _acts.size():
		var b := UiStyle.button(String(_acts[i].get("name", "Acto %d" % (i + 1))), func() -> void: _show_act(i), 0)
		b.add_theme_color_override("font_disabled_color", UiStyle.ACCENT)   # la pestaña abierta, resaltada
		_tabs.add_child(b)
	_show_act(_act_index)
	visible = true
	reset_size()
	set_anchors_and_offsets_preset.call_deferred(Control.PRESET_CENTER)


## Texto del botón de una zona: nombre (o «???»), nivel, el waypoint y, si hay
## instancia viva, cuánto le queda y su mecánica.
static func node_text(z: Dictionary, known: bool, has_waypoint: bool, waypoint_found: bool, here: bool,
		time_left: float, mechanic: String) -> String:
	var lines: Array[String] = [String(z.get("name", z["id"])) if known else "???"]
	var second := ""
	if not z.get("safe", false) and known:
		second = "nivel %d" % int(z.get("level", 1))
	if has_waypoint:
		second += ("  ·  " if second != "" else "") + ("waypoint" if waypoint_found else "waypoint sin descubrir")
	if here:
		second += "  (aquí)"
	if second != "":
		lines.append(second)
	if time_left > 0.0 and not here:
		lines.append("como la dejaste %s%s" % [ZoneInstances.clock(time_left), ("  ·  " + mechanic) if mechanic != "" else ""])
	return "\n".join(lines)


func _show_act(i: int) -> void:
	_act_index = clampi(i, 0, maxi(0, _acts.size() - 1))
	for k in _tabs.get_child_count():
		(_tabs.get_child(k) as Button).disabled = k == _act_index   # la pestaña abierta
	for c in _map.get_children():
		_map.remove_child(c)
		c.queue_free()
	_centers.clear()
	_edges.clear()
	if _acts.is_empty():
		return
	var act: Dictionary = _acts[_act_index]
	var lay := Zone.act_map_layout(act)
	_edges = lay["edges"]
	var cols := maxi(1, int(lay["cols"]))
	var rows := maxi(1, int(lay["rows"]))
	var cell := Vector2(MAP_SIZE.x / cols, MAP_SIZE.y / rows)
	var node_size := Vector2(minf(NODE_SIZE.x, cell.x - 10.0), NODE_SIZE.y)
	for z in act.get("zones", []):
		var at: Vector2i = lay["cells"][z["id"]]
		var center := Vector2((at.x + 0.5) * cell.x, (at.y + 0.5) * cell.y)
		_centers[z["id"]] = center
		var has_wp: bool = z.get("waypoint") != null
		var found := _discovered.has(z["id"])
		var here: bool = z["id"] == _current
		var known := found or here or visited.has(z["id"])
		var text := node_text(z, known, has_wp, found, here, float(instance_times.get(z["id"], 0.0)), String(instance_mechanics.get(z["id"], "")))
		var zid := String(z["id"])
		var b := UiStyle.button(text, func() -> void: selected.emit(zid), node_size.x)
		b.add_theme_font_size_override("font_size", 11)
		b.clip_text = true   # que no crezca con el texto y pise a la de al lado
		b.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		b.tooltip_text = text   # el texto entero, al pasar el ratón
		b.custom_minimum_size = node_size
		b.size = node_size
		b.position = center - node_size / 2.0
		b.disabled = not (has_wp and found) or here
		if z.get("boss") != null:
			b.add_theme_color_override("font_disabled_color", Color("e07060"))
		_map.add_child(b)
	_map.queue_redraw()


func _draw_links() -> void:
	for pair in _edges:
		if not _centers.has(pair[0]) or not _centers.has(pair[1]):
			continue
		var known: bool = (visited.has(pair[0]) or _discovered.has(pair[0])) and (visited.has(pair[1]) or _discovered.has(pair[1]))
		_map.draw_line(_centers[pair[0]], _centers[pair[1]], LINK_KNOWN if known else LINK, 3.0 if known else 2.0, true)
