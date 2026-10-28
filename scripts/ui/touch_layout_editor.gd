class_name TouchLayoutEditor
extends Control
## Editor de disposición táctil (T137), desde Pausa → Controles: con el juego en
## pausa y el HUD a la vista, arrastrar un botón lo mueve; tocar uno lo elige y
## «Más grande» / «Más chico» le cambian el tamaño. Opacidad de todos los botones,
## «Restaurar» (vuelve a la distribución elegida) y «Listo». Se guarda al momento
## en settings.cfg (Touch.custom).

signal closed

const NAMES := {"skill_0": "Habilidad 1", "skill_1": "Habilidad 2", "skill_2": "Habilidad 3", "skill_3": "Habilidad 4",
	"skill_4": "Habilidad 5", "skill_5": "Habilidad 6", "dodge": "Esquiva", "use": "Usar", "flasks": "Pociones", "menu": "Menús"}
## Lo que se agranda o achica por toque.
const SCALE_STEP := 1.12

var hud: Hud
var _selected := ""
var _drag_from := Vector2.INF
var _opacity_button: Button
var _hint: Label


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	visible = false
	var frame := PanelContainer.new()
	frame.theme = UiStyle.make_theme()
	UiStyle.decorate_window(frame)
	frame.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	frame.grow_horizontal = Control.GROW_DIRECTION_BOTH
	frame.offset_top = 70.0
	add_child(frame)
	var top := VBoxContainer.new()
	top.add_theme_constant_override("separation", 6)
	frame.add_child(top)
	_hint = UiStyle.label("Arrastra un botón para moverlo. Toca uno y usa Más grande / Más chico.", 16, UiStyle.TEXT)
	_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	top.add_child(_hint)
	var bar := HBoxContainer.new()
	bar.add_theme_constant_override("separation", 8)
	bar.alignment = BoxContainer.ALIGNMENT_CENTER
	top.add_child(bar)
	bar.add_child(UiStyle.button("Más grande", func() -> void: _resize(SCALE_STEP), 130))
	bar.add_child(UiStyle.button("Más chico", func() -> void: _resize(1.0 / SCALE_STEP), 130))
	_opacity_button = UiStyle.button("", _cycle_opacity, 170)
	bar.add_child(_opacity_button)
	bar.add_child(UiStyle.button("Restaurar", func() -> void:
		Touch.reset_custom()
		_changed(), 120))
	bar.add_child(UiStyle.button("Listo", close, 100))
	for b in bar.get_children():
		(b as Control).custom_minimum_size.y = 44.0


func open() -> void:
	Touch.load_layout()
	_selected = ""
	visible = true
	_changed()


func close() -> void:
	Touch.save_layout()
	visible = false
	closed.emit()


func _cycle_opacity() -> void:
	var k := Touch.OPACITIES.find(snappedf(Touch.button_opacity, 0.05))
	Touch.button_opacity = Touch.OPACITIES[(k + 1) % Touch.OPACITIES.size()]
	_changed()


func _resize(factor: float) -> void:
	if _selected == "":
		_hint.text = "Primero toca el botón que quieras cambiar."
		return
	Touch.adjust(_selected, Vector2.ZERO, factor)
	_changed()


## Botón del HUD en `p` (coordenadas de este control, las mismas que las del HUD).
func key_at(p: Vector2) -> String:
	var rects := hud.touch_rects()
	for key in rects:
		if (rects[key] as Rect2).grow(6.0).has_point(p):
			return key
	return ""


func _gui_input(event: InputEvent) -> void:
	var mb := event as InputEventMouseButton
	if mb and mb.button_index == MOUSE_BUTTON_LEFT:
		if mb.pressed:
			_selected = key_at(mb.position)
			_drag_from = mb.position if _selected != "" else Vector2.INF
			if _selected != "":
				_hint.text = "%s: arrástralo o cambia su tamaño." % NAMES.get(_selected, _selected)
		else:
			_drag_from = Vector2.INF
			Touch.save_layout()
		queue_redraw()
		accept_event()
		return
	var mm := event as InputEventMouseMotion
	if mm and _drag_from != Vector2.INF and _selected != "":
		var delta := mm.position - _drag_from
		_drag_from = mm.position
		if Touch.left_handed:
			delta.x = -delta.x   # se guarda como si fuera diestro
		Touch.adjust(_selected, delta)
		_changed(false)
		accept_event()


func _changed(save := true) -> void:
	if save:
		Touch.save_layout()
	_opacity_button.text = "Opacidad: %d %%" % roundi(Touch.button_opacity * 100.0)
	if hud:
		hud.refresh_touch_layout()
	queue_redraw()


func _draw() -> void:
	if hud == null:
		return
	var font := get_theme_default_font()
	var rects := hud.touch_rects()
	for key in rects:
		var r: Rect2 = rects[key]
		var on: bool = key == _selected
		draw_rect(r.grow(4.0), Color(UiStyle.ACCENT, 0.9) if on else Color(1, 1, 1, 0.45), false, 3.0 if on else 1.5)
		draw_string_outline(font, r.position + Vector2(0, -6), NAMES.get(key, key), HORIZONTAL_ALIGNMENT_CENTER, r.size.x, 12, 4, Color.BLACK)
		draw_string(font, r.position + Vector2(0, -6), NAMES.get(key, key), HORIZONTAL_ALIGNMENT_CENTER, r.size.x, 12,
			UiStyle.ACCENT if on else UiStyle.TEXT)
