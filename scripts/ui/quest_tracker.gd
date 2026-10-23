class_name QuestTracker
extends PanelContainer
## Registro de misiones bajo el minimapa: la principal arriba (dorada) y las
## secundarias debajo, cada una con su paso actual y el progreso. Click en la
## cabecera (o L) para plegarlo. Al cambiar un paso, la misión parpadea.

const WIDTH := 250.0

var quests: QuestLog
var collapsed := false:
	set(value):
		collapsed = value
		_refresh()

const ICON_CELL := 32.0

var _header: Button
var _body: RichTextLabel
var _flash := {}   # id -> segundos de resaltado restantes
## Objetos que piden los pasos de "recoger" activos: [{id, done}], dibujados
## con QuestItemArt bajo el texto (los ya recogidos, tenues y con una marca).
var _items: Array[Dictionary] = []
var _icons: Control


func _ready() -> void:
	theme = UiStyle.make_theme()
	mouse_filter = Control.MOUSE_FILTER_PASS
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.05, 0.04, 0.07, 0.72)
	style.border_color = Color(0.54, 0.43, 0.23, 0.6)
	style.set_border_width_all(1)
	style.set_corner_radius_all(4)
	style.set_content_margin_all(8)
	add_theme_stylebox_override("panel", style)
	custom_minimum_size.x = WIDTH
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 4)
	add_child(box)
	_header = Button.new()
	_header.flat = true
	_header.alignment = HORIZONTAL_ALIGNMENT_LEFT
	_header.focus_mode = Control.FOCUS_NONE
	_header.add_theme_font_size_override("font_size", 14)
	_header.add_theme_color_override("font_color", UiStyle.ACCENT)
	_header.tooltip_text = "Misiones (L para plegar)"
	_header.pressed.connect(func() -> void: collapsed = not collapsed)
	box.add_child(_header)
	_body = RichTextLabel.new()
	_body.bbcode_enabled = true
	_body.fit_content = true
	_body.scroll_active = false
	_body.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_body.custom_minimum_size.x = WIDTH - 16.0
	_body.add_theme_font_size_override("normal_font_size", 13)
	_body.add_theme_font_size_override("bold_font_size", 14)
	box.add_child(_body)
	_icons = Control.new()
	_icons.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_icons.draw.connect(_draw_icons)
	box.add_child(_icons)


func setup(p_quests: QuestLog) -> void:
	quests = p_quests
	for sig in [quests.quest_started, quests.quest_progressed, quests.quest_completed]:
		sig.connect(func(id: String) -> void:
			_flash[id] = 2.0
			_refresh())
	_refresh()


func _process(delta: float) -> void:
	if _flash.is_empty():
		return
	for id in _flash.keys():
		_flash[id] -= delta
		if _flash[id] <= 0.0:
			_flash.erase(id)
	_refresh()


func _refresh() -> void:
	if quests == null or _body == null:
		return
	var ids := quests.active_ids()
	_header.text = ("▸ Misiones (%d)" if collapsed else "▾ Misiones (%d)") % ids.size()
	_body.visible = not collapsed
	_items.clear()
	for id in ids:
		var step := quests.current_step(id)
		if step.get("type", "") != "collect":
			continue
		var wanted: Array = step.get("items", [step["item"]] if step.has("item") else [])
		for item_id in wanted:
			_items.append({"id": String(item_id), "done": quests.character.flags.has("item_" + String(item_id))})
	_icons.visible = not collapsed and not _items.is_empty()
	_icons.custom_minimum_size = Vector2(WIDTH - 16.0, ICON_CELL + 4.0)
	_icons.queue_redraw()
	if collapsed:
		reset_size()
		return
	var lines := PackedStringArray()
	var side_title := false
	for id in ids:
		var def: Dictionary = quests.defs[id]
		var main: bool = def.get("main", false)
		if not main and not side_title:
			side_title = true
			lines.append("[color=#8a8293]Secundarias[/color]")
		var blink: bool = _flash.has(id) and fmod(_flash[id], 0.5) < 0.25
		var name_color := "#ffd84a" if blink else ("#d9a441" if main else "#e8d9b0")
		var prefix := "★ " if main else "• "
		lines.append("[b][color=%s]%s%s[/color][/b]" % [name_color, prefix, def.get("name", id)])
		var step := quests.step_text(id)
		var ready: bool = quests.current_step(id).get("type", "") == "turn_in"
		lines.append("   [color=%s]%s[/color]" % ["#6fd36b" if ready else "#b8ab90", step])
	if ids.is_empty():
		lines.append("[color=#8a8293]Sin misiones activas. Disfruta del silencio.[/color]")
	_body.text = "\n".join(lines)
	reset_size()


func _draw_icons() -> void:
	for k in _items.size():
		var c := Vector2(ICON_CELL * 0.5 + k * (ICON_CELL + 4.0), ICON_CELL * 0.5 + 2.0)
		var done: bool = _items[k]["done"]
		_icons.draw_rect(Rect2(c - Vector2(ICON_CELL, ICON_CELL) * 0.5, Vector2(ICON_CELL, ICON_CELL)),
			Color(0.3, 0.8, 0.4, 0.15) if done else Color(1, 1, 1, 0.05))
		_icons.draw_set_transform(c, 0.0, Vector2(0.6, 0.6))
		QuestItemArt.draw(_icons, Vector2.ZERO, QuestItemArt.kind_for({"id": _items[k]["id"]}))
		_icons.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		if done:
			_icons.draw_rect(Rect2(c - Vector2(ICON_CELL, ICON_CELL) * 0.5, Vector2(ICON_CELL, ICON_CELL)), Color(0, 0, 0, 0.45))
			_icons.draw_polyline(PackedVector2Array([c + Vector2(-6, 0), c + Vector2(-2, 5), c + Vector2(7, -6)]), Color("6fd36b"), 3.0, true)
