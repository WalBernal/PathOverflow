class_name TrainingPanel
extends Control
## Panel del muñeco de prácticas (T212): arriba al centro, mientras estás cerca del
## servidor de pruebas del campamento. Como una consola de monitorización: DPS de los
## últimos 10 s, daño por golpe (media, máximo y críticos), lo que hacen los
## degenerativos y una barra por tipo de daño. Solo se lee (no recibe clics): vale
## igual con ratón, mando o dedo, y crece con el tamaño de interfaz como el resto.

const WIDTH := 320.0
const PAD := 10.0
const LINE := 18.0
const BAR_H := 8.0

## El muñeco que se mide (lo pone World al entrar en un campamento; null fuera).
var dummy: TrainingDummy
## Si World quiere que se vea (el jugador está cerca).
var wanted := false
var _stats: Dictionary = {}


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	custom_minimum_size = Vector2(WIDTH, height_for(0))
	size = custom_minimum_size


func _process(_delta: float) -> void:
	if not visible or dummy == null:
		return
	_stats = dummy.stats()
	var h := height_for((_stats["types"] as Array).size())
	if custom_minimum_size.y != h:
		custom_minimum_size.y = h
		size.y = h
	queue_redraw()


## Alto del panel con `types` filas de tipo de daño.
static func height_for(types: int) -> float:
	return PAD * 2.0 + 20.0 + 34.0 + LINE * 2.0 + (6.0 + types * (LINE + 2.0) if types > 0 else LINE)


## Cifra corta: 950, 12.4k, 3.1M.
static func short(v: float) -> String:
	if v >= 1.0e6:
		return "%.1fM" % (v / 1.0e6)
	if v >= 1.0e4:
		return "%.1fk" % (v / 1000.0)
	return str(roundi(v))


## Las líneas de texto del panel (las miran las pruebas).
static func lines(s: Dictionary) -> PackedStringArray:
	var out := PackedStringArray()
	if s.is_empty() or float(s.get("total", 0.0)) <= 0.0:
		out.append("Golpéame: mido los últimos %d s." % int(TrainingDummy.WINDOW))
		return out
	out.append("%s DPS" % short(float(s["dps"])))
	out.append("Golpes %d · media %s · máx %s" % [int(s["hits"]), short(float(s["per_hit"])), short(float(s["max_hit"]))])
	out.append("Críticos %d %% · degenerativos %s/s" % [roundi(float(s["crit_rate"]) * 100.0), short(float(s["dot_dps"]))])
	for row in s["types"]:
		out.append("%s %s (%d %%)" % [TrainingDummy.TYPE_NAMES.get(row[0], row[0]), short(float(row[1])), roundi(float(row[2]) * 100.0)])
	return out


func _draw() -> void:
	var box := UiStyle.inset_style(UiStyle.ACCENT.darkened(0.45))
	box.bg_color = Color(UiStyle.PANEL, 0.97)   # casi opaco: los avisos de abajo no se leen a través
	draw_style_box(box, Rect2(Vector2.ZERO, size))
	var font := UiStyle.mono_font()
	var x := PAD
	var y := PAD + 13.0
	draw_string(font, Vector2(x, y), "$ top --servidor-pruebas", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, UiStyle.MUTED)
	draw_string(font, Vector2(x, y), "últimos %d s" % int(TrainingDummy.WINDOW), HORIZONTAL_ALIGNMENT_RIGHT, WIDTH - PAD * 2.0, 12, UiStyle.MUTED)
	var text := lines(_stats)
	y += 34.0
	if text.size() == 1:
		draw_string(font, Vector2(x, y - 6.0), text[0], HORIZONTAL_ALIGNMENT_LEFT, WIDTH - PAD * 2.0, 14, UiStyle.ACCENT)
		return
	draw_string(font, Vector2(x, y), text[0], HORIZONTAL_ALIGNMENT_LEFT, -1, 28, UiStyle.ACCENT)
	y += LINE + 2.0
	draw_string(font, Vector2(x, y), text[1], HORIZONTAL_ALIGNMENT_LEFT, WIDTH - PAD * 2.0, 12, UiStyle.TEXT)
	y += LINE
	draw_string(font, Vector2(x, y), text[2], HORIZONTAL_ALIGNMENT_LEFT, WIDTH - PAD * 2.0, 12, UiStyle.TEXT)
	y += 6.0
	var types: Array = _stats["types"]
	for k in types.size():
		var row: Array = types[k]
		var color: Color = TrainingDummy.TYPE_COLORS.get(row[0], UiStyle.TEXT)
		y += LINE + 2.0
		draw_string(font, Vector2(x, y), text[3 + k], HORIZONTAL_ALIGNMENT_LEFT, 150.0, 12, color)
		var bar := Rect2(Vector2(x + 154.0, y - BAR_H - 1.0), Vector2(WIDTH - PAD * 2.0 - 154.0, BAR_H))
		draw_rect(bar, Color(color, 0.18))
		draw_rect(Rect2(bar.position, Vector2(bar.size.x * float(row[2]), bar.size.y)), color)
