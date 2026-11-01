class_name QuestTracker
extends PanelContainer
## Registro de misiones bajo el minimapa: la principal arriba (dorada) y las
## secundarias debajo, cada una con su paso actual y el progreso. Click en la
## cabecera (o L) para plegarlo. Al cambiar un paso, la misión parpadea.
## En el celular (T146, `compact`): solo la misión activa y «+N»; tocar la cabecera
## pasa de resumen a todas y a plegado; nunca baja de `max_height` (lo que deja libre
## el HUD táctil: si no cabe, se queda en menos) y se pliega solo en las peleas.

const WIDTH := 250.0
## Alto aproximado de la cabecera y de cada línea (para saber si cabe sin esperar
## a que se maquete).
const HEADER_H := 34.0
const LINE_H := 18.0
## Lo que ocupa de verdad plegado (cabecera y márgenes): con menos sitio, no se ve (T147).
const FOLDED_MIN := 50.0

var quests: QuestLog
var collapsed := false:
	set(value):
		collapsed = value
		_refresh()
## Celular: resumen (1 misión), todas o plegado, lo que eligió el jugador.
enum View { SUMMARY, ALL, FOLDED }
var compact := false:
	set(value):
		if value != compact:
			compact = value
			_refresh()
var chosen_view := View.SUMMARY
## Alto máximo (en el celular, hasta los botones). INF = sin tope.
var max_height := INF:
	set(value):
		if not is_equal_approx(value, max_height):
			max_height = value
			_refresh()
## En una pelea (lo pone World): en el celular, plegado mientras dure.
var in_combat := false:
	set(value):
		if value != in_combat:
			in_combat = value
			_refresh()
## Lo que se ve de verdad (lo elegido, recortado por el alto, la pelea o el escritorio).
var shown_view := View.ALL

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
	_header.pressed.connect(func() -> void:
		if compact:   # resumen → todas → plegado
			chosen_view = (chosen_view + 1) % 3 as View
			_refresh()
		else:
			collapsed = not collapsed)
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
	var all_ids := quests.active_ids()
	shown_view = view_for(chosen_view if compact else (View.FOLDED if collapsed else View.ALL), compact, in_combat,
		all_ids.size(), max_height)
	var folded := shown_view == View.FOLDED
	var ids := all_ids if shown_view == View.ALL else all_ids.slice(0, 1)
	_header.text = ("▸ Misiones (%d)" if folded else "▾ Misiones (%d)") % all_ids.size()
	if shown_view == View.SUMMARY and all_ids.size() > 1:
		_header.text += "  · +%d" % (all_ids.size() - 1)   # (en la cabecera: el resumen, en dos líneas)
	_body.visible = not folded
	_items.clear()
	for id in ids:
		var step := quests.current_step(id)
		if step.get("type", "") != "collect":
			continue
		var wanted: Array = step.get("items", [step["item"]] if step.has("item") else [])
		for item_id in wanted:
			_items.append({"id": String(item_id), "done": quests.character.flags.has("item_" + String(item_id))})
	_icons.visible = not folded and not _items.is_empty()
	_icons.custom_minimum_size = Vector2(WIDTH - 16.0, ICON_CELL + 4.0)
	_icons.queue_redraw()
	if folded:
		reset_size()
		return
	var lines := PackedStringArray()
	var side_title := false
	for id in ids:
		var def: Dictionary = quests.defs[id]
		var main: bool = def.get("main", false)
		if not main and not side_title:
			side_title = true
			lines.append("[color=#8b949e]Secundarias[/color]")
		var blink: bool = _flash.has(id) and fmod(_flash[id], 0.5) < 0.25
		var name_color := "#ffd84a" if blink else ("#2dd4bf" if main else "#e6edf3")
		var prefix := "★ " if main else "• "
		lines.append("[b][color=%s]%s%s[/color][/b]" % [name_color, prefix, def.get("name", id)])
		var step := quests.step_text(id)
		var ready: bool = quests.current_step(id).get("type", "") == "turn_in"
		lines.append("   [color=%s]%s[/color]" % ["#6fd36b" if ready else "#b8ab90", step])
	if ids.is_empty():
		lines.append("[color=#8b949e]Sin misiones activas. Disfruta del silencio.[/color]")
	_body.text = "\n".join(lines)
	reset_size()


## Qué se ve: en el escritorio, lo elegido; en el celular, plegado en las peleas y,
## si lo elegido no cabe en `max_h`, lo siguiente más pequeño (todas → resumen → plegado).
static func view_for(chosen: View, is_compact: bool, combat: bool, count: int, max_h: float) -> View:
	if not is_compact:
		return chosen
	if combat:
		return View.FOLDED
	var v := chosen
	while v != View.FOLDED and height_for(v, count) > max_h:
		v = View.SUMMARY if v == View.ALL else View.FOLDED
	return v


## Alto aproximado con `count` misiones (dos líneas cada una, más la de «Secundarias»;
## el resumen, solo dos).
static func height_for(view: View, count: int) -> float:
	match view:
		View.FOLDED:
			return HEADER_H
		View.SUMMARY:
			return HEADER_H + LINE_H * 2 + 16.0
	return HEADER_H + LINE_H * (count * 2 + (1 if count > 1 else 0)) + 16.0


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


## Alto libre para el registro de misiones (`rect`, ya en su sitio) hasta el primer
## obstáculo de `obstacles` que tenga debajo en su misma columna (T146).
static func room(rect: Rect2, obstacles: Array) -> float:
	var limit := INF
	for o: Rect2 in obstacles:
		if o.position.x < rect.end.x and o.end.x > rect.position.x and o.end.y > rect.position.y:
			limit = minf(limit, o.position.y)
	return maxf(0.0, limit - rect.position.y - 10.0) if limit != INF else INF