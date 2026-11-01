class_name EventLog
extends VBoxContainer
## Registro de sucesos (T128): un panel lateral plegable con lo que conviene no perderse
## —botín raro y único, waypoints descubiertos, mecánicas completadas, instancias que
## caducan—, lo más nuevo arriba. Se pliega con su cabecera (ratón, toque o el cursor de
## mando); plegado solo dice cuántos sucesos nuevos hay.

const MAX_ENTRIES := 40
const SHOWN := 7
const WIDTH := 300.0

## [{text, color, t}] (t: segundos de partida en que pasó), lo más nuevo al final.
var entries: Array[Dictionary] = []
var collapsed := false
var unseen := 0

var _header: Button
var _list: VBoxContainer
var _time := 0.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	custom_minimum_size.x = WIDTH
	add_theme_constant_override("separation", 2)
	_header = UiStyle.button("", toggle, WIDTH)
	_header.add_theme_font_size_override("font_size", 12)
	_header.alignment = HORIZONTAL_ALIGNMENT_LEFT
	add_child(_header)
	_list = VBoxContainer.new()
	_list.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_list.add_theme_constant_override("separation", 1)
	add_child(_list)
	_refresh()


func _process(delta: float) -> void:
	_time += delta


func add(text: String, color := UiStyle.TEXT) -> void:
	entries.append({"text": text, "color": color, "t": _time})
	while entries.size() > MAX_ENTRIES:
		entries.pop_front()
	if collapsed:
		unseen += 1
	_refresh()


func toggle() -> void:
	collapsed = not collapsed
	if not collapsed:
		unseen = 0
	_refresh()


## Texto de la cabecera: plegado, cuántos sucesos nuevos hay.
func header_text() -> String:
	if collapsed:   # [+] y [–]: la fuente de la interfaz no tiene los triángulos
		return "[+] Registro" + ("  (%d nuevos)" % unseen if unseen > 0 else "")
	return "[–] Registro"


func _refresh() -> void:
	if _header == null:
		return
	_header.text = header_text()
	for c in _list.get_children():
		_list.remove_child(c)
		c.queue_free()
	_list.visible = not collapsed
	if collapsed:
		return
	var from := maxi(0, entries.size() - SHOWN)
	for i in range(entries.size() - 1, from - 1, -1):
		var e: Dictionary = entries[i]
		var l := UiStyle.label(String(e["text"]), 12, e["color"])
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		l.custom_minimum_size.x = WIDTH
		l.add_theme_constant_override("outline_size", 4)
		l.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.85))
		l.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_list.add_child(l)
