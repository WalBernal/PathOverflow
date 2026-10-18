class_name CharacterPortrait
extends Control
## Retrato animado (de pecho hacia arriba) para la hoja de personaje.
## Respira, parpadea, mira al ratón y cada pocos segundos hace alguna tontería:
## un sorbo de café, pensar (con spinner de carga), bostezar o ponerse gafas de
## sol. Si le queda poca vida, suda. De fondo cae código, porque sí.

signal caption_changed(text: String)

const ACTIONS := ["sip", "think", "yawn", "glasses"]
const CAPTIONS := {
	"idle": ["Esperando input del usuario...", "Funcionando. Más o menos.", "Ocioso, pero con estilo."],
	"sip": ["Recargando cafeína...", "Café nº 7 del día.", "Sin café no hay commits."],
	"think": ["Compilando una idea... 3%", "Buscando en Stack Overflow...", "Pensando. No molestar. (No hay nadie.)"],
	"yawn": ["Daily de 45 minutos...", "Otra reunión que pudo ser un email.", "Bostezo en producción."],
	"glasses": ["Optimizado. Supuestamente.", "Deploy un viernes. Sin miedo.", "Todos los tests en verde. (No hay tests.)"],
	"sweat": ["Esto no estaba en el sprint.", "Vida baja. Pánico alto.", "¿Alguien ha visto el botón de rollback?"],
}
const CODE_LINES := [
	"if (vida <= 0) { reaparecer(); }", "while (true) { farmear(); }", "// TODO: arreglar esto",
	"git push --force", "catch (e) { /* nada */ }", "sudo make me a sandwich", "return 42;",
	"var motivacion = null;", "// funciona, no tocar", "rm -rf /bugs",
]

var appearance: Dictionary = CharacterAppearance.default()
## 0..1 de vida (para sudar cuando es baja).
var life_fraction := 1.0
## Si es true, las gafas de sol tienen más papeletas (DPS alto).
var feeling_powerful := false

var _time := 0.0
var _blink := 0.0
var _next_blink := 2.0
var _action := ""
var _action_time := 0.0
var _next_action := 3.0
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	_rng.randomize()
	clip_contents = true
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _process(delta: float) -> void:
	if not is_visible_in_tree():
		return
	_time += delta
	_next_blink -= delta
	if _next_blink <= 0.0:
		_blink = 0.14
		_next_blink = _rng.randf_range(2.0, 5.0)
	_blink = maxf(0.0, _blink - delta)
	if _action != "":
		_action_time += delta
		if _action_time > 3.0:
			_set_action("")
	else:
		_next_action -= delta
		if _next_action <= 0.0:
			var options: Array = ACTIONS.duplicate()
			if feeling_powerful:
				options.append("glasses")
			_set_action(options[_rng.randi_range(0, options.size() - 1)])
	if life_fraction < 0.35 and _action == "":
		_set_action("sweat")
	queue_redraw()


func _set_action(action: String) -> void:
	_action = action
	_action_time = 0.0
	_next_action = _rng.randf_range(3.0, 6.0)
	var key := action if action != "" else "idle"
	var options: Array = CAPTIONS[key]
	caption_changed.emit(options[_rng.randi_range(0, options.size() - 1)])


func _draw() -> void:
	var w := size.x
	var h := size.y
	draw_rect(Rect2(Vector2.ZERO, size), Color("0b0a0e"))
	_draw_code_rain(w, h)

	var a := appearance
	var skin := Color(a["skin_tone"])
	var hair := Color(a["hair_color"])
	var outfit := Color(a["outfit_color"])
	var body_w: float = CharacterAppearance.BODY_WIDTH[int(a["body"])]
	var breath := sin(_time * 2.0) * 2.0
	var head := Vector2(w / 2.0, h * 0.42 + breath * 0.5)
	var r := w * 0.2

	# Hombros y torso.
	var shoulders_y := h * 0.72 + breath
	draw_colored_polygon(PackedVector2Array([
		Vector2(w / 2.0 - w * 0.42 * body_w, h + 2.0), Vector2(w / 2.0 - w * 0.34 * body_w, shoulders_y),
		Vector2(w / 2.0 + w * 0.34 * body_w, shoulders_y), Vector2(w / 2.0 + w * 0.42 * body_w, h + 2.0)]), outfit)
	draw_rect(Rect2(Vector2(w / 2.0 - r * 0.32, head.y + r * 0.7), Vector2(r * 0.64, shoulders_y - head.y - r * 0.6)), skin.darkened(0.1))
	draw_colored_polygon(PackedVector2Array([Vector2(w / 2.0 - r * 0.5, shoulders_y), Vector2(w / 2.0, shoulders_y + r * 0.45),
		Vector2(w / 2.0 + r * 0.5, shoulders_y)]), skin.darkened(0.1))  # escote

	# Pelo largo por detrás.
	var style := int(a["hair"])
	if style == 2:
		draw_rect(Rect2(head + Vector2(-r * 1.1, -r * 0.4), Vector2(r * 2.2, r * 2.0)), hair)

	# Cabeza.
	draw_circle(head, r, skin)
	_draw_hair(head, r, style, hair)

	# Ojos que siguen al ratón.
	var look := (get_local_mouse_position() - head).limit_length(r * 0.12)
	for side: float in [-1.0, 1.0]:
		var eye := head + Vector2(side * r * 0.38, r * 0.05)
		if _blink > 0.0 or _action == "yawn" and _action_time > 0.6 and _action_time < 2.0:
			draw_line(eye - Vector2(r * 0.12, 0), eye + Vector2(r * 0.12, 0), Color("1a1414"), 2.0)
		else:
			draw_circle(eye, r * 0.13, Color.WHITE)
			draw_circle(eye + look, r * 0.07, Color("1a1414"))
	# Cejas: preocupadas si suda, arqueadas si piensa.
	var brow_tilt := 0.0
	if _action == "sweat":
		brow_tilt = 0.15
	elif _action == "think":
		brow_tilt = -0.12
	for side: float in [-1.0, 1.0]:
		var b := head + Vector2(side * r * 0.38, -r * 0.22)
		draw_line(b + Vector2(-r * 0.16, side * brow_tilt * r), b + Vector2(r * 0.16, -side * brow_tilt * r), hair.darkened(0.2), 2.5)

	# Boca.
	var mouth := head + Vector2(0, r * 0.5)
	match _action:
		"yawn":
			var open := sin(clampf(_action_time / 2.0, 0.0, 1.0) * PI)
			draw_circle(mouth, r * (0.08 + 0.18 * open), Color("3a1a1a"))
		"sweat":
			draw_arc(mouth + Vector2(0, r * 0.1), r * 0.18, PI * 1.15, PI * 1.85, 12, Color("3a1a1a"), 2.0)
		"glasses":
			draw_arc(mouth - Vector2(0, r * 0.08), r * 0.22, PI * 0.15, PI * 0.85, 12, Color("3a1a1a"), 2.0)
		_:
			draw_line(mouth - Vector2(r * 0.15, 0), mouth + Vector2(r * 0.15, 0), Color("3a1a1a"), 2.0)

	match _action:
		"sip":
			_draw_sip(head, r)
		"think":
			_draw_think(head, r)
		"glasses":
			_draw_glasses(head, r)
		"sweat":
			_draw_sweat(head, r)

	draw_rect(Rect2(Vector2.ZERO, size), UiStyle.ACCENT.darkened(0.3), false, 2.0)


func _draw_hair(head: Vector2, r: float, style: int, hair: Color) -> void:
	match style:
		0:
			draw_arc(head, r * 0.97, PI * 1.08, PI * 1.92, 24, hair, r * 0.1, true)
		1, 2, 4:
			var pts := PackedVector2Array()
			for k in 25:
				var t := PI + PI * k / 24.0
				pts.append(head + Vector2(cos(t), sin(t) * 1.05) * (r + 2.0))
			pts.append(head + Vector2(r * 0.7, -r * 0.15))
			pts.append(head + Vector2(-r * 0.7, -r * 0.15))
			draw_colored_polygon(pts, hair)
			if style == 4:
				draw_circle(head + Vector2(0, -r * 1.15), r * 0.38, hair)
		3:
			draw_arc(head, r * 0.97, PI * 1.08, PI * 1.92, 24, hair.darkened(0.3), r * 0.08, true)
			draw_colored_polygon(PackedVector2Array([head + Vector2(-r * 0.22, -r * 0.85),
				head + Vector2(0, -r * 1.9 + sin(_time * 3.0) * 2.0), head + Vector2(r * 0.22, -r * 0.85)]), hair)


func _draw_sip(head: Vector2, r: float) -> void:
	# La taza sube, se queda en la boca y baja.
	var t := _action_time
	var lift := clampf(t / 0.8, 0.0, 1.0) * (1.0 - clampf((t - 2.2) / 0.8, 0.0, 1.0))
	var mug_size := r * 1.1
	var pos := Vector2(head.x + r * 0.15, size.y - (size.y - head.y - r * 0.15) * lift - mug_size * 0.3)
	ItemIcons.draw(self, Rect2(pos - Vector2(mug_size, mug_size) / 2.0, Vector2(mug_size, mug_size)), "flask_coffee", Color.WHITE, false)
	for k in 2:
		var phase := fmod(_time + k * 0.5, 1.0)
		var s := pos + Vector2(k * 8.0 - 6.0, -mug_size * 0.5 - phase * 14.0)
		draw_line(s, s + Vector2(sin(_time * 5.0 + k) * 3.0, -6.0), Color(1, 1, 1, 0.5 * (1.0 - phase)), 2.0, true)


func _draw_think(head: Vector2, r: float) -> void:
	var bubble := head + Vector2(r * 1.25, -r * 1.25)
	draw_circle(head + Vector2(r * 0.85, -r * 0.7), r * 0.08, Color(1, 1, 1, 0.85))
	draw_circle(head + Vector2(r * 1.0, -r * 0.92), r * 0.13, Color(1, 1, 1, 0.85))
	draw_circle(bubble, r * 0.45, Color(1, 1, 1, 0.9))
	# Spinner de carga, el gran clásico.
	for k in 8:
		var ang := TAU * k / 8.0 + floorf(_time * 10.0) * TAU / 8.0
		draw_circle(bubble + Vector2.from_angle(ang) * r * 0.26, r * 0.05, Color(0.1, 0.1, 0.1, 0.15 + 0.85 * k / 7.0))


func _draw_glasses(head: Vector2, r: float) -> void:
	# Bajan desde arriba (estilo "deal with it").
	var drop := clampf(_action_time / 0.9, 0.0, 1.0)
	var y := lerpf(-r * 2.0, head.y + r * 0.02, drop)
	var c := Color("0d0d10")
	var px := maxf(2.0, r * 0.09)
	for side: float in [-1.0, 1.0]:
		var cx := head.x + side * r * 0.38
		draw_rect(Rect2(Vector2(cx - r * 0.25, y - px), Vector2(r * 0.5, px * 2.5)), c)
		draw_rect(Rect2(Vector2(cx - r * 0.18 + side * 0.0, y - px * 0.5), Vector2(px, px)), Color(1, 1, 1, 0.7))
	draw_rect(Rect2(Vector2(head.x - r * 0.15, y - px), Vector2(r * 0.3, px)), c)


func _draw_sweat(head: Vector2, r: float) -> void:
	var phase := fmod(_time * 0.8, 1.0)
	var drop := head + Vector2(r * 0.8, -r * 0.2 + phase * r * 0.9)
	draw_circle(drop, r * 0.09, Color(0.6, 0.85, 1.0, 0.9 * (1.0 - phase * 0.5)))
	draw_colored_polygon(PackedVector2Array([drop + Vector2(-r * 0.08, -r * 0.02), drop + Vector2(0, -r * 0.2),
		drop + Vector2(r * 0.08, -r * 0.02)]), Color(0.6, 0.85, 1.0, 0.9 * (1.0 - phase * 0.5)))


func _draw_code_rain(w: float, h: float) -> void:
	var font := get_theme_default_font()
	var line_h := 14.0
	var offset := fmod(_time * 10.0, line_h)
	var rows := int(h / line_h) + 2
	for row in rows:
		var index := int(floorf(_time * 10.0 / line_h)) - row
		var text: String = CODE_LINES[posmod(index * 7, CODE_LINES.size())]
		var x := float(posmod(index * 37, 60)) - 20.0
		draw_string(font, Vector2(x, row * line_h + offset), text, HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(0.24, 0.8, 0.4, 0.09))
