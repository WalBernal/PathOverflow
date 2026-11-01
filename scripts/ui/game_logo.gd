class_name GameLogo
extends Control
## Logo de «Path Overflow»: título con efecto glitch (copias roja y cian que
## tiemblan), una pila que se desborda (stack overflow, claro), llaves de
## código y el subtítulo «{ el último commit }». Se dibuja con formas y texto,
## así que escala a cualquier tamaño (`logo_scale`). T168: con los colores del panel de
## datos (texto claro, acento turquesa); la pila verde y roja, como la del ícono.

@export var logo_scale := 1.0

var _time := 0.0
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_rng.randomize()


func _process(delta: float) -> void:
	_time += delta
	queue_redraw()


func _draw() -> void:
	var s := logo_scale
	var font := get_theme_default_font()
	var center := size / 2.0
	var title_size := int(84 * s)
	var line1 := "PATH"
	var line2 := "OVERFLOW"
	var w1 := font.get_string_size(line1, HORIZONTAL_ALIGNMENT_LEFT, -1, title_size).x
	var w2 := font.get_string_size(line2, HORIZONTAL_ALIGNMENT_LEFT, -1, title_size).x
	var y1 := center.y - 10.0 * s
	var y2 := y1 + title_size * 0.95

	# Glitch: cada pocos segundos, un temblor fuerte.
	var burst := fmod(_time, 3.2) < 0.18
	var jitter := 6.0 * s if burst else 1.5 * s
	var off := Vector2(_rng.randf_range(-jitter, jitter), _rng.randf_range(-jitter * 0.3, jitter * 0.3))

	# Pila desbordada a la izquierda: bloques que se caen por arriba.
	var stack_x := center.x - maxf(w1, w2) / 2.0 - 70.0 * s
	for k in 6:
		var block := Rect2(Vector2(stack_x - 22.0 * s, y2 - 8.0 * s - k * 16.0 * s), Vector2(44.0 * s, 13.0 * s))
		var color := Color("3cff6a") if k < 4 else Color("e06c6c")
		if k >= 4:
			block.position += Vector2((k - 3) * 9.0 * s + sin(_time * 3.0 + k) * 2.0 * s, -(k - 3) * 4.0 * s)
		draw_rect(block, Color(color, 0.85))
		draw_rect(block, color.darkened(0.5), false, 2.0)
	var falling := fmod(_time * 0.6, 1.0)
	draw_rect(Rect2(Vector2(stack_x + 30.0 * s, y2 - 110.0 * s + falling * 90.0 * s), Vector2(30.0 * s, 11.0 * s)), Color(0.9, 0.4, 0.4, 1.0 - falling))

	for layer in [[Color(1.0, 0.15, 0.25, 0.75), -off], [Color(0.1, 0.9, 1.0, 0.75), off], [UiStyle.TEXT, Vector2.ZERO]]:
		var c: Color = layer[0]
		var o: Vector2 = layer[1]
		draw_string(font, Vector2(center.x - w1 / 2.0, y1) + o, line1, HORIZONTAL_ALIGNMENT_LEFT, -1, title_size, c)
		draw_string(font, Vector2(center.x - w2 / 2.0, y2) + o, line2, HORIZONTAL_ALIGNMENT_LEFT, -1, title_size, c)
	# La "O" final se "desborda": unos píxeles caen de ella.
	for k in 4:
		var drip := fmod(_time * 0.8 + k * 0.25, 1.0)
		draw_rect(Rect2(Vector2(center.x + w2 / 2.0 - 30.0 * s + k * 6.0 * s, y2 + drip * 40.0 * s), Vector2(4.0 * s, 4.0 * s)),
			Color(UiStyle.ACCENT, 1.0 - drip))
	# Barras de ruido durante el glitch.
	if burst:
		for k in 3:
			var y := _rng.randf_range(y1 - title_size, y2)
			draw_rect(Rect2(Vector2(center.x - w2 / 2.0, y), Vector2(w2, _rng.randf_range(2.0, 6.0) * s)), Color(1, 1, 1, 0.15))

	# Llaves y subtítulo.
	var sub_size := int(22 * s)
	var subtitle := "{ el último commit }"
	var ws := font.get_string_size(subtitle, HORIZONTAL_ALIGNMENT_LEFT, -1, sub_size).x
	draw_string(font, Vector2(center.x - ws / 2.0, y2 + 36.0 * s), subtitle, HORIZONTAL_ALIGNMENT_LEFT, -1, sub_size, UiStyle.ACCENT)
	var brace_size := int(120 * s)
	var bw := font.get_string_size("<", HORIZONTAL_ALIGNMENT_LEFT, -1, brace_size).x
	var bracket_y := y2 - 4.0 * s
	draw_string(font, Vector2(center.x - maxf(w1, w2) / 2.0 - bw - 120.0 * s, bracket_y), "<", HORIZONTAL_ALIGNMENT_LEFT, -1, brace_size, Color(UiStyle.ACCENT, 0.2))
	draw_string(font, Vector2(center.x + maxf(w1, w2) / 2.0 + 30.0 * s, bracket_y), "/>", HORIZONTAL_ALIGNMENT_LEFT, -1, brace_size, Color(UiStyle.ACCENT, 0.2))
