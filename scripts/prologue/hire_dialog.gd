class_name HireDialog
extends Control
## "Confirmar Contratación de Emergencia": ventana modal gris al estilo
## Windows 98 donde se elige el primer puesto (la clase) en un desplegable.
## El botón [ No ] no quiere que lo pulsen:
##   - al acercarse el ratón, salta (la primera vez 150 px a la derecha; luego a
##     cualquier hueco de la ventana lejos del ratón), y encoge un poco cada vez,
##     pero nunca tanto como para que no se lea el «No»; ya pequeño, lo rodea un
##     recuadro punteado que parpadea para no perderlo de vista;
##   - cuando llega a su tamaño mínimo deja de esquivar;
##   - si se le atina, sale el error 0x80004005 y se convierte en «Pues ya que...»,
##     que acepta igual que [ Sí ].

signal hired(class_id: StringName)

const WIN_SIZE := Vector2(720, 470)
const GRAY := Color("c0c0c0")
const DARK := Color("808080")
const BLUE_A := Color("000080")
const BLUE_B := Color("1084d0")
const NO_JUMP := 150.0
const NO_SIZE := Vector2(96, 30)
const APPROACH := 26.0
## Cuánto encoge en cada esquive y su tamaño mínimo (el «No» se sigue leyendo).
const SHRINK := 0.86
const MIN_SCALE := 0.45
const MIN_NO_SIZE := Vector2(40, 22)
const MIN_FONT := 10

var _window: Control
var _dropdown: OptionButton
var _info: RichTextLabel
var _skills: HBoxContainer
var _yes: Button
var _no: Button
var _focus: Control   # capa encima de todo con el recuadro punteado del «No»
var _error: Label
var _error_box: PanelContainer
var _no_scale := 1.0
var _no_armed := true      # vuelve a esquivar cuando el ratón se aleja
var _no_dead := false
var _dodges := 0
var _font: Font
## Apariencia del jugador: el puesto elegido se ve con su figura y su atuendo (T187).
var appearance: Dictionary = CharacterAppearance.default()
var _figure: AppearancePreview
## Velo de fondo (T187): entra con un fundido en vez de aparecer de golpe.
var _veil := 0.0
const VEIL := 0.35
const NO_SLIDE := 0.12
var _opened := false
var _closing := false
var _no_tween: Tween


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	_font = ThemeDB.fallback_font
	theme = _win98_theme()
	_window = Control.new()
	_window.size = WIN_SIZE
	add_child(_window)
	_window.draw.connect(_draw_window)

	var body := VBoxContainer.new()
	body.position = Vector2(18, 40)
	body.size = WIN_SIZE - Vector2(36, 96)
	body.add_theme_constant_override("separation", 10)
	_window.add_child(body)
	var question := Label.new()
	question.text = PrologueText.text("hire", "question", "¿Deseas incorporarte al equipo de infraestructura para resolver la incidencia y obtener experiencia como:")
	question.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	question.custom_minimum_size.x = WIN_SIZE.x - 120
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 14)
	body.add_child(row)
	var icon := Control.new()
	icon.custom_minimum_size = Vector2(40, 40)
	icon.draw.connect(func() -> void:
		icon.draw_circle(Vector2(20, 20), 17, Color("2060c0"))
		icon.draw_circle(Vector2(20, 20), 17, Color.BLACK, false, 1.0)
		icon.draw_string(_font, Vector2(14, 29), "?", HORIZONTAL_ALIGNMENT_LEFT, -1, 24, Color.WHITE))
	row.add_child(icon)
	row.add_child(question)
	_dropdown = OptionButton.new()
	_dropdown.custom_minimum_size = Vector2(380, 30)
	_dropdown.focus_mode = Control.FOCUS_NONE
	for c in GameData.classes:
		_dropdown.add_item(c["name"])
	_dropdown.item_selected.connect(func(_i: int) -> void: _refresh_info())
	var drop_row := HBoxContainer.new()
	drop_row.add_theme_constant_override("separation", 10)
	body.add_child(drop_row)
	var spacer := Control.new()
	spacer.custom_minimum_size.x = 54
	drop_row.add_child(spacer)
	drop_row.add_child(_dropdown)
	var q := Label.new()
	q.text = "?"
	drop_row.add_child(q)
	var info_panel := PanelContainer.new()
	var sunken := StyleBoxFlat.new()
	sunken.bg_color = Color.WHITE
	sunken.border_color = DARK
	sunken.set_border_width_all(2)
	sunken.set_content_margin_all(8)
	info_panel.add_theme_stylebox_override("panel", sunken)
	info_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_child(info_panel)
	var info_row := HBoxContainer.new()
	info_row.add_theme_constant_override("separation", 8)
	info_panel.add_child(info_row)
	# La figura del puesto (T187): posa con su arma y respira, como en la lista de personajes.
	_figure = AppearancePreview.new()
	_figure.animated = true
	_figure.use_sprites = true
	_figure.custom_minimum_size = Vector2(90, 150)
	_figure.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	info_row.add_child(_figure)
	var info_box := VBoxContainer.new()
	info_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info_row.add_child(info_box)
	_info = RichTextLabel.new()
	_info.bbcode_enabled = true
	_info.fit_content = true
	_info.add_theme_color_override("default_color", Color.BLACK)
	_info.add_theme_font_size_override("normal_font_size", 14)
	info_box.add_child(_info)
	_skills = HBoxContainer.new()
	_skills.add_theme_constant_override("separation", 8)
	info_box.add_child(_skills)

	_yes = Button.new()
	_yes.text = PrologueText.text("hire", "yes", "Sí")
	_yes.size = NO_SIZE
	_yes.position = Vector2(WIN_SIZE.x / 2.0 - 150, WIN_SIZE.y - 48)
	_yes.focus_mode = Control.FOCUS_NONE
	_yes.pressed.connect(_accept)
	_window.add_child(_yes)
	_no = Button.new()
	_no.text = PrologueText.text("hire", "no", "No")
	_no.size = NO_SIZE
	_no.position = Vector2(WIN_SIZE.x / 2.0 + 54, WIN_SIZE.y - 48)
	_no.focus_mode = Control.FOCUS_NONE
	_no.pressed.connect(_on_no_pressed)
	_window.add_child(_no)
	_focus = Control.new()
	_focus.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_focus.size = WIN_SIZE
	_focus.draw.connect(_draw_no_focus)
	_window.add_child(_focus)
	# Globo de error amarillo (tooltip del sistema).
	_error_box = PanelContainer.new()
	var tip := StyleBoxFlat.new()
	tip.bg_color = Color("ffffe1")
	tip.border_color = Color.BLACK
	tip.set_border_width_all(1)
	tip.set_content_margin_all(6)
	_error_box.add_theme_stylebox_override("panel", tip)
	_error_box.visible = false
	_window.add_child(_error_box)
	_error = Label.new()
	_error.add_theme_color_override("font_color", Color.BLACK)
	_error.add_theme_font_size_override("font_size", 13)
	_error.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_error.custom_minimum_size = Vector2(340, 0)
	_error_box.add_child(_error)
	_refresh_info()
	resized.connect(_center)
	_center.call_deferred()


func _center() -> void:
	var area := size if size.x > 0.0 else get_viewport_rect().size
	_window.position = ((area - WIN_SIZE) / 2.0).round()
	if not _opened:   # la primera vez, la ventana entra con un zoom corto (T187)
		_opened = true
		UiMotion.window_in(_window)
		Sfx.play("ui_open", -8.0)
		create_tween().tween_property(self, "_veil", VEIL, 0.25)


## Se cierra con un fundido y se libera sola (T187).
func close() -> void:
	if _closing:
		return
	_closing = true
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	Sfx.play("ui_close", -8.0)
	var tw := create_tween().set_parallel(true)
	tw.tween_property(_window, "modulate:a", 0.0, 0.16)
	tw.tween_property(self, "_veil", 0.0, 0.2)
	if not Accessibility.reduce_motion:
		_window.pivot_offset = WIN_SIZE / 2.0
		tw.tween_property(_window, "scale", Vector2(0.96, 0.96), 0.16)
	tw.chain().tween_callback(queue_free)


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color(0, 0, 0, _veil))


func _draw_window() -> void:
	var r := Rect2(Vector2.ZERO, WIN_SIZE)
	_window.draw_rect(r, GRAY)
	# Biseles clásicos: claro arriba-izquierda, oscuro abajo-derecha.
	_window.draw_line(Vector2(0, 0), Vector2(r.size.x, 0), Color.WHITE, 2.0)
	_window.draw_line(Vector2(0, 0), Vector2(0, r.size.y), Color.WHITE, 2.0)
	_window.draw_line(Vector2(r.size.x - 1, 0), Vector2(r.size.x - 1, r.size.y), Color.BLACK, 2.0)
	_window.draw_line(Vector2(0, r.size.y - 1), Vector2(r.size.x, r.size.y - 1), Color.BLACK, 2.0)
	# Barra de título con degradado azul.
	for k in 40:
		var step := (r.size.x - 8) / 40.0
		_window.draw_rect(Rect2(4 + step * k, 4, step + 1.0, 24), BLUE_A.lerp(BLUE_B, k / 39.0))
	_window.draw_string(_font, Vector2(12, 21), PrologueText.text("hire", "title", "Confirmar Contratación de Emergencia"), HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color.WHITE)
	var x := Rect2(r.size.x - 26, 7, 18, 18)
	_window.draw_rect(x, GRAY)
	_window.draw_rect(x, Color.BLACK, false, 1.0)
	_window.draw_string(_font, x.position + Vector2(5, 14), "x", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color.BLACK)


## Recuadro de foco punteado (como en Windows 98) alrededor del «No» cuando ya
## encogió: parpadea para que no se pierda entre el resto de la ventana.
func _draw_no_focus() -> void:
	if _no_dead or _no_scale >= 0.95 or fmod(Time.get_ticks_msec() / 1000.0, 0.8) >= 0.55:
		return
	var box := Rect2(_no.position, _no.size).grow(4.0)
	var corners := [box.position, Vector2(box.end.x, box.position.y), box.end, Vector2(box.position.x, box.end.y)]
	for k in 4:
		_focus.draw_dashed_line(corners[k], corners[(k + 1) % 4], Color.BLACK, 1.0, 3.0)


func _refresh_info() -> void:
	var c: Dictionary = GameData.classes[_dropdown.selected]
	var attrs: Dictionary = c.get("base_attributes", {})
	var difficulty := clampi(int(c.get("difficulty", 2)), 1, 3)
	_info.text = "[b]%s[/b]   [color=#555555](FUE %d · DES %d · INT %d · dificultad %s)[/color]\n%s\n[color=#333333][i]%s[/i][/color]" % [
		c["name"], int(attrs.get("strength", 0)), int(attrs.get("dexterity", 0)), int(attrs.get("intelligence", 0)),
		"★".repeat(difficulty) + "☆".repeat(3 - difficulty), c.get("description", ""), c.get("playstyle", "")]
	var trait_def: Dictionary = c.get("trait", {})
	if not trait_def.is_empty():
		_info.text += "\n[color=#0a3a7a][b]Rasgo: %s.[/b] %s[/color]" % [trait_def.get("name", ""), trait_def.get("description", "")]
	var class_id := String(c.get("id", ""))
	_figure.appearance = CharacterAppearance.with_gear(CharacterAppearance.sanitize(appearance), class_id)
	_figure.glow_color = Color(c.get("color", "2dd4bf"))
	var look: Array = MainMenu.CLASS_POSES.get(class_id, ["attack", "sword"])
	_figure.action = look[0]
	_figure.weapon = look[1]
	if _opened:
		_figure.flash()
	for child in _skills.get_children():
		child.queue_free()
	for skill_id in c.get("starter_skills", []):
		var def: Dictionary = GameData.items.skills.skills.get(skill_id, {})
		if def.is_empty():
			continue
		var icon := Control.new()
		icon.custom_minimum_size = Vector2(36, 36)
		icon.tooltip_text = "%s: %s" % [def.get("name", ""), def.get("description", "")]
		icon.draw.connect(func() -> void: SkillIcon.draw(icon, Rect2(Vector2.ZERO, icon.size), def))
		_skills.add_child(icon)
		var name := Label.new()
		name.text = def.get("name", "")
		name.add_theme_color_override("font_color", Color.BLACK)
		name.add_theme_font_size_override("font_size", 12)
		name.custom_minimum_size.x = 118   # (con la figura al lado, tres caben en la ventana)
		name.autowrap_mode = TextServer.AUTOWRAP_WORD
		_skills.add_child(name)


func _process(_delta: float) -> void:
	if _veil < VEIL or _closing:
		queue_redraw()   # el velo entrando o saliendo
	if _closing:
		return
	if not _no_dead and _no_scale < 0.95:
		_focus.queue_redraw()   # el recuadro punteado parpadea
	if _no_dead or _no_scale <= MIN_SCALE:
		return   # ya es pequeño: se queda quieto (y se le puede atinar)
	var mouse := _window.get_local_mouse_position()
	var area := Rect2(_no.position, _no.size).grow(APPROACH)
	if area.has_point(mouse):
		if _no_armed:
			_no_armed = false
			_dodge(mouse)
	else:
		_no_armed = true


## Esquiva sin salir de la ventana: el primer salto, 150 px a la derecha; luego,
## a cualquier hueco lejos del ratón. Cada vez encoge un poco.
func _dodge(mouse: Vector2) -> void:
	_dodges += 1
	_no_scale = maxf(MIN_SCALE, _no_scale * SHRINK)
	var tiny := _no_scale <= MIN_SCALE
	# Encoge el botón y su letra (no con `scale`, que deja el texto ilegible).
	var w := (NO_SIZE * _no_scale).max(MIN_NO_SIZE)
	_no.add_theme_font_size_override("font_size", maxi(MIN_FONT, int(round(15.0 * _no_scale))))
	_no.custom_minimum_size = w
	_no.size = w
	var area := Rect2(Vector2(12, 40), WIN_SIZE - Vector2(24, 52) - w)
	var target := Vector2(_no.position.x + NO_JUMP, _no.position.y)
	if _dodges > 1 or not area.has_point(target):
		target = _no.position
		var yes_zone := Rect2(_yes.position, _yes.size).grow(14)
		for k in 30:
			var c := area.position + Vector2(randf() * area.size.x, randf() * area.size.y)
			if c.distance_to(mouse) > 140.0 and not yes_zone.intersects(Rect2(c, w)):
				target = c
				break
	# Se desliza rápido hasta el hueco (T187) en vez de teletransportarse.
	if _no_tween:
		_no_tween.kill()
	_no_tween = _no.create_tween()
	_no_tween.tween_property(_no, "position", target.clamp(area.position, area.end), NO_SLIDE).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_no_tween.parallel().tween_method(func(_v: float) -> void: _focus.queue_redraw(), 0.0, 1.0, NO_SLIDE)
	Sfx.play("blink", -8.0, 1.0 + _dodges * 0.06)
	if tiny:
		_no.tooltip_text = PrologueText.text("hire", "no_sure", "¿Seguro?")
	_focus.queue_redraw()


## Si se le atina: error del sistema y el botón se rinde: «Pues ya que...».
func _on_no_pressed() -> void:
	if _no_dead:
		return
	_no_dead = true
	if _no_tween:
		_no_tween.kill()   # se le atinó a medio deslizarse: se queda donde va a ir
	_error.text = PrologueText.text("hire", "refuse_error", "Error 0x80004005: Acción denegada por el mercado laboral. Requiere 3 años de experiencia previa para rechazar esta oferta.")
	_error_box.visible = true
	_error_box.reset_size()
	_error_box.position = Vector2(WIN_SIZE.x - _error_box.size.x - 16.0, WIN_SIZE.y - 60.0 - _error_box.size.y)
	UiMotion.window_in(_error_box)   # el globo aparece con un pop (T187)
	Sfx.play("player_hurt")
	_no.pressed.disconnect(_on_no_pressed)
	_no.remove_theme_font_size_override("font_size")
	_no.text = PrologueText.text("hire", "no_gives_up", "Pues ya que...")
	_no.tooltip_text = ""
	_no.custom_minimum_size = Vector2.ZERO
	_no.size = Vector2(150, NO_SIZE.y)
	_focus.queue_redraw()
	_no.position = Vector2(WIN_SIZE.x / 2.0 + 30, WIN_SIZE.y - 48)
	_no.pressed.connect(_accept)


func _accept() -> void:
	Sfx.play("buff")
	hired.emit(StringName(GameData.classes[_dropdown.selected]["id"]))

## Tema gris de los 90: botones con bisel y texto negro.
func _win98_theme() -> Theme:
	var t := Theme.new()
	var up := StyleBoxFlat.new()
	up.bg_color = GRAY
	up.border_color = Color.BLACK
	up.border_width_right = 2
	up.border_width_bottom = 2
	up.border_width_left = 1
	up.border_width_top = 1
	up.set_content_margin_all(4)
	var down := up.duplicate() as StyleBoxFlat
	down.bg_color = Color("b0b0b0")
	down.border_width_left = 2
	down.border_width_top = 2
	down.border_width_right = 1
	down.border_width_bottom = 1
	var off := up.duplicate() as StyleBoxFlat
	off.border_color = DARK
	for kind in ["Button", "OptionButton"]:
		t.set_stylebox("normal", kind, up)
		t.set_stylebox("hover", kind, up)
		t.set_stylebox("pressed", kind, down)
		t.set_stylebox("focus", kind, StyleBoxEmpty.new())
		t.set_stylebox("disabled", kind, off)
		t.set_color("font_color", kind, Color.BLACK)
		t.set_color("font_hover_color", kind, Color.BLACK)
		t.set_color("font_pressed_color", kind, Color.BLACK)
		t.set_color("font_disabled_color", kind, DARK)
		t.set_font_size("font_size", kind, 15)
	t.set_color("font_color", "Label", Color.BLACK)
	t.set_font_size("font_size", "Label", 15)
	var menu := StyleBoxFlat.new()
	menu.bg_color = GRAY
	menu.border_color = Color.BLACK
	menu.set_border_width_all(1)
	t.set_stylebox("panel", "PopupMenu", menu)
	var hover := StyleBoxFlat.new()
	hover.bg_color = BLUE_A
	t.set_stylebox("hover", "PopupMenu", hover)
	t.set_color("font_color", "PopupMenu", Color.BLACK)
	t.set_color("font_hover_color", "PopupMenu", Color.WHITE)
	t.set_font_size("font_size", "PopupMenu", 15)
	return t
