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
	box.add_child(UiStyle.label("Waypoints · %s" % GameData.act.get("name", ""), 20, UiStyle.ACCENT))
	box.add_child(UiStyle.label("Teletransporte entre zonas. Sin cola, sin colas de mensajes.", 12, UiStyle.MUTED))
	_list = VBoxContainer.new()
	_list.add_theme_constant_override("separation", 4)
	box.add_child(_list)
	box.add_child(UiStyle.button("Cerrar (Esc)", func() -> void: visible = false, 0))


func open(discovered: Array, current_zone: String) -> void:
	for c in _list.get_children():
		_list.remove_child(c)
		c.queue_free()
	for z in GameData.act.get("zones", []):
		if z.get("waypoint") == null:
			continue
		var known := discovered.has(z["id"])
		var here: bool = z["id"] == current_zone
		var text: String = z["name"] if known else "??? (sin descubrir)"
		if z.get("safe", false) == false and known:
			text += "  ·  nivel %d" % z["level"]
		if here:
			text += "  (aquí)"
		var b := UiStyle.button(text, func() -> void: selected.emit(z["id"]), 380)
		b.disabled = not known or here
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		_list.add_child(b)
	visible = true
	reset_size()
	set_anchors_and_offsets_preset.call_deferred(Control.PRESET_CENTER)
