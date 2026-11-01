class_name EventLog
extends VBoxContainer
## Registro de sucesos (T128): un panel lateral plegable con lo que conviene no perderse
## —botín raro y único, waypoints descubiertos, mecánicas completadas, instancias que
## caducan—, lo más nuevo arriba. Se pliega con su cabecera (ratón, toque o el cursor de
## mando); plegado solo dice cuántos sucesos nuevos hay. T167: cada línea como en una
## consola, con la hora de partida y su nivel («12:04 [INFO] ...»).

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
		var l := RichTextLabel.new()
		l.bbcode_enabled = true
		l.fit_content = true
		l.scroll_active = false
		l.custom_minimum_size.x = WIDTH
		l.add_theme_font_size_override("normal_font_size", 12)
		l.add_theme_font_size_override("bold_font_size", 12)
		l.add_theme_constant_override("outline_size", 4)
		l.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.85))
		l.mouse_filter = Control.MOUSE_FILTER_IGNORE
		l.text = console_line(String(e["text"]), e["color"], float(e["t"]))
		_list.add_child(l)


## Nivel de un suceso por su color: rojo → WARN, verde → OK, el resto INFO.
static func level_of(color: Color) -> String:
	if color.r > 0.75 and color.g < 0.55 and color.b < 0.55:
		return "WARN"
	if color.g > 0.7 and color.r < 0.6 and color.b < 0.7:
		return "OK"
	return "INFO"


## Una línea de consola: hora de partida (mm:ss) apagada, el nivel en su color y el texto.
static func console_line(text: String, color: Color, t: float) -> String:
	var lv := level_of(color)
	var lv_color: String = {"WARN": "f59e0b", "OK": "3fb950", "INFO": UiStyle.ACCENT_HEX}[lv]
	var s := int(t)
	text = text.replace("[", "\u0001").replace("]", "[rb]").replace("\u0001", "[lb]")   # corchetes literales
	return "[color=#%s]%02d:%02d[/color] [color=#%s][lb]%s[rb][/color] [color=#%s]%s[/color]" % [
		UiStyle.MUTED_HEX, s / 60, s % 60, lv_color, lv, color.to_html(false), text]
