class_name WaypointPanel
extends PanelContainer
## Lista de waypoints del acto: los descubiertos permiten viajar; los demás se
## muestran bloqueados (con su nombre oculto, que hay que ganárselo).

signal selected(zone_id: String)

var _list: VBoxContainer


func _ready() -> void:
	theme = UiStyle.make_theme()
	add_theme_stylebox_override("panel", UiStyle.panel_style())
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	add_child(box)
	box.add_child(UiStyle.label("Waypoints", 20, UiStyle.ACCENT))
	box.add_child(UiStyle.label("Teletransporte entre zonas. Sin cola, sin colas de mensajes.", 12, UiStyle.MUTED))
	_list = VBoxContainer.new()
	_list.add_theme_constant_override("separation", 4)
	box.add_child(_list)
	box.add_child(UiStyle.button("Cerrar (Esc)", func() -> void: visible = false, 0))


## Segundos que le quedan a la instancia de cada zona (T119, ZoneInstances.times): la
## zona sigue como la dejaste si viajas antes de que llegue a 0.
var instance_times: Dictionary = {}


func open(discovered: Array, current_zone: String) -> void:
	for c in _list.get_children():
		_list.remove_child(c)
		c.queue_free()
	for a in GameData.acts:
		# Los actos sin ningún waypoint descubierto no se enseñan (sin spoilers).
		var any_known := false
		for z in a.get("zones", []):
			any_known = any_known or discovered.has(z["id"])
		if not any_known:
			continue
		_list.add_child(UiStyle.label(a.get("name", ""), 15, UiStyle.MUTED))
		_add_act_buttons(a, discovered, current_zone)
	visible = true
	reset_size()
	set_anchors_and_offsets_preset.call_deferred(Control.PRESET_CENTER)


func _add_act_buttons(a: Dictionary, discovered: Array, current_zone: String) -> void:
	for z in a.get("zones", []):
		if z.get("waypoint") == null:
			continue
		var known := discovered.has(z["id"])
		var here: bool = z["id"] == current_zone
		var text: String = z["name"] if known else "??? (sin descubrir)"
		if z.get("safe", false) == false and known:
			text += "  ·  nivel %d" % z["level"]
		if here:
			text += "  (aquí)"
		elif known and float(instance_times.get(z["id"], 0.0)) > 0.0:
			text += "  ·  como la dejaste %s" % ZoneInstances.clock(float(instance_times[z["id"]]))
		var b := UiStyle.button(text, func() -> void: selected.emit(z["id"]), 380)
		b.disabled = not known or here
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		_list.add_child(b)
