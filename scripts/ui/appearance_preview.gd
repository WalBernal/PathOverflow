class_name AppearancePreview
extends Control
## Muestra la figura de un personaje a cualquier tamaño (creador, lista de personajes).

var appearance: Dictionary = CharacterAppearance.default():
	set(value):
		appearance = value
		queue_redraw()
var facing := Vector2.DOWN:
	set(value):
		facing = value
		queue_redraw()
## Si está activo, la figura respira (sube y baja) y se dibuja un pedestal brillante.
var animated := false:
	set(value):
		animated = value
		set_process(value)
var glow_color := Color("d9a441")

var _time := 0.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_process(animated)


func _process(delta: float) -> void:
	_time += delta
	queue_redraw()


func _draw() -> void:
	# La figura mide ~46 unidades (con cresta); se escala para llenar el control.
	var scale := minf(size.x / 30.0, size.y / 50.0)
	var feet := Vector2(size.x / 2.0, size.y - 4.0 * scale)
	if animated:
		_draw_pedestal(feet, scale)
		feet.y -= (0.5 + 0.5 * sin(_time * 2.2)) * scale * 0.8
	CharacterAppearance.draw(self, feet, scale, appearance, facing)


func _draw_pedestal(feet: Vector2, scale: float) -> void:
	var pulse := 0.5 + 0.5 * sin(_time * 1.6)
	for k in 5:
		var r := scale * (9.0 + k * 2.2)
		draw_set_transform(feet, 0.0, Vector2(1.0, 0.32))
		draw_circle(Vector2.ZERO, r, Color(glow_color, (0.10 + 0.06 * pulse) * (1.0 - k / 5.0)))
	draw_set_transform(feet, 0.0, Vector2(1.0, 0.32))
	draw_arc(Vector2.ZERO, scale * 11.0, 0.0, TAU, 48, Color(glow_color, 0.45 + 0.3 * pulse), 2.0, true)
	draw_set_transform(Vector2.ZERO)
	# Bits subiendo desde el pedestal.
	var font := get_theme_default_font()
	for k in 6:
		var phase := fmod(_time * 0.4 + k / 6.0, 1.0)
		var x := feet.x + sin(k * 2.3) * scale * 9.0
		var y := feet.y - phase * scale * 40.0
		draw_string(font, Vector2(x, y), "1" if k % 2 == 0 else "0", HORIZONTAL_ALIGNMENT_CENTER, -1, 14,
			Color(glow_color, 0.5 * (1.0 - phase)))
