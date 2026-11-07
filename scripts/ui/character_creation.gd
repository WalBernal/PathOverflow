class_name CharacterCreation
extends Control
## Creador de personaje: apariencia y nombre de un recién egresado. La clase
## (su primer puesto) se elige en el prólogo, en la ventana de "contratación
## de emergencia". Al confirmar se pasa al prólogo (o, si se salta, directo a
## esa ventana).

const RANDOM_NAMES := [
	"Segfault", "NullPointer", "Bobby Tables", "Sudo", "Deadlock", "Hotfix", "Legacy",
	"Pato de Goma", "Chmod 777", "Lorem Ipsum", "Tabulador", "Egresado404", "Commitero",
	"Stack Smasher", "Regexorcista", "Async Await", "Kernel Sanders", "Monolito", "Cron Job",
]
const FACINGS := [Vector2.DOWN, Vector2.LEFT, Vector2.UP, Vector2.RIGHT]
const SNIPPETS := ["git init personaje", "new Egresado()", "chmod +x cv.sh", "// valores por defecto, como tú",
	"npm install experiencia", "assert(contratado)", "SELECT * FROM vacantes WHERE exp = 0; -- 0 rows", "docker build -t egresado ."]

var _appearance := CharacterAppearance.default()
var _facing_index := 0
var _rng := RandomNumberGenerator.new()
var _existing_names: Array = []
var _time := 0.0
var _floaters: Array[Dictionary] = []
var _student_id := ""

var _record: RichTextLabel
var _preview: AppearancePreview
var _face: CharacterPortrait
var _student: StudentPreview
var _option_labels := {}      # clave -> Label del valor (complexión, peinado...)
var _swatch_rows := {}        # clave -> Array[Button]
var _name_edit: LineEdit
var _error: Label
var _create_button: Button
var _skip_prologue: CheckBox
## Arrastre sobre la figura para girarla (T185): píxeles acumulados hacia un lado.
const DRAG_STEP := 48.0
var _drag := 0.0
var _selected_swatches: Array[StyleBoxFlat] = []   # su marco late (T185)
var _built := false
var _floater_layer: Control


func _ready() -> void:
	theme = UiStyle.make_theme()
	UiStyle.apply_ui_scale.call_deferred(self)
	_rng.randomize()
	_student_id = "%d%06d" % [Time.get_date_dict_from_system()["year"] % 100, _rng.randi_range(0, 999999)]
	MusicPlayer.play_title()
	for data in CharacterSaves.list_all():
		_existing_names.append(data.get("name", ""))
	_floater_layer = Control.new()
	_floater_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_floater_layer.draw.connect(_draw_floaters)
	add_child(_floater_layer)
	_floater_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_build()
	_refresh_appearance()
	_built = true
	_refresh_record()
	_name_edit.grab_focus()
	for k in 10:
		_floaters.append(_new_floater(true))


func _process(delta: float) -> void:
	_time += delta
	for i in _floaters.size():
		_floaters[i]["y"] -= _floaters[i]["speed"] * delta
		if _floaters[i]["y"] < -20.0:
			_floaters[i] = _new_floater(false)
	var pulse := 0.5 + 0.5 * sin(_time * 5.0)
	for style in _selected_swatches:
		style.border_color = UiStyle.ACCENT.lerp(Color.WHITE, 0.55 * pulse)
	_floater_layer.queue_redraw()   # el fondo fijo no se redibuja cada fotograma (T186)


## Pasos de giro que da un arrastre acumulado de `drag` píxeles (y lo que sobra).
static func drag_steps(drag: float) -> Array:
	var steps := int(drag / DRAG_STEP)
	return [steps, drag - steps * DRAG_STEP]


func _on_preview_input(event: InputEvent) -> void:
	var dx := 0.0
	if event is InputEventScreenDrag:
		dx = event.relative.x
	elif event is InputEventMouseMotion and event.button_mask & MOUSE_BUTTON_MASK_LEFT:
		dx = event.relative.x
	elif (event is InputEventMouseButton or event is InputEventScreenTouch) and not event.pressed:
		_drag = 0.0
		return
	if dx == 0.0:
		return
	var r := drag_steps(_drag + dx)
	_drag = r[1]
	if r[0] != 0:
		_rotate(-signi(r[0]))   # arrastrar a la derecha gira como el botón «<»


func _new_floater(anywhere: bool) -> Dictionary:
	var binary := _rng.randf() < 0.6
	var text: String
	if binary:
		text = ""
		for k in _rng.randi_range(4, 8):
			text += "1" if _rng.randf() < 0.5 else "0"
	else:
		text = SNIPPETS[_rng.randi_range(0, SNIPPETS.size() - 1)]
	return {"text": text, "x": _rng.randf_range(10.0, maxf(size.x - 260.0, 20.0)),
		"y": _rng.randf_range(0.0, size.y) if anywhere else size.y + 10.0,
		"speed": _rng.randf_range(10.0, 26.0), "alpha": _rng.randf_range(0.05, 0.14), "binary": binary}


## El fondo (rejilla, resplandor y viñeta) solo se pinta al cambiar de tamaño (T186).
func _draw() -> void:
	UiStyle.draw_background(self, size)


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		queue_redraw()


## Los textos que flotan, en su propia capa: lo único que se redibuja cada fotograma.
func _draw_floaters() -> void:
	var font := get_theme_default_font()
	for f in _floaters:
		var color := Color(0.25, 0.95, 0.45, f["alpha"]) if f["binary"] else Color(0.85, 0.8, 0.6, f["alpha"])
		_floater_layer.draw_string(font, Vector2(f["x"], f["y"]), f["text"], HORIZONTAL_ALIGNMENT_LEFT, -1, 15, color)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"ui_cancel"):
		_back()


func _build() -> void:
	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 14)
	add_child(root)
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.offset_left = 28.0
	root.offset_right = -28.0
	root.offset_top = 22.0
	root.offset_bottom = -22.0

	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 18)
	root.add_child(header)
	var logo := GameLogo.new()
	logo.logo_scale = 0.3
	logo.custom_minimum_size = Vector2(300, 84)
	header.add_child(logo)
	var titles := VBoxContainer.new()
	titles.alignment = BoxContainer.ALIGNMENT_CENTER
	titles.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(titles)
	titles.add_child(UiStyle.label("Recién egresado", 36, UiStyle.ACCENT))
	# Con ajuste de línea: de una sola línea, ensanchaba toda la pantalla y la columna de
	# Apariencia (con sus botones «>» y «Comenzar») se salía por la derecha en PC y tableta.
	var subtitle := UiStyle.label("$ git init personaje  —  elige cara y un nombre que no dé vergüenza en los logs. El puesto ya te lo darán... más o menos.", 15, UiStyle.MUTED)
	subtitle.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	subtitle.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	titles.add_child(subtitle)

	var columns := HBoxContainer.new()
	columns.add_theme_constant_override("separation", 16)
	columns.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(columns)

	# --- Expediente del egresado ---
	var record_panel := PanelContainer.new()
	record_panel.custom_minimum_size = Vector2(430, 0)
	columns.add_child(record_panel)
	var record_box := VBoxContainer.new()
	record_box.add_theme_constant_override("separation", 8)
	record_panel.add_child(record_box)
	record_box.add_child(UiStyle.label("Expediente", 22, UiStyle.ACCENT))
	record_box.add_child(UiStyle.label("Universidad Autónoma de Occidente · Unidad Mazatlán", 13, UiStyle.MUTED))
	record_box.add_child(UiStyle.ornament())
	_record = RichTextLabel.new()
	_record.bbcode_enabled = true
	_record.fit_content = true
	_record.size_flags_vertical = Control.SIZE_EXPAND_FILL
	record_box.add_child(_record)
	var note := UiStyle.label("Tu primer puesto (la clase) se decide en el prólogo,\ncuando ya no te quede otra opción.", 13, UiStyle.MUTED)
	record_box.add_child(note)

	# --- Vista previa ---
	var preview_panel := PanelContainer.new()
	preview_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	columns.add_child(preview_panel)
	var preview_box := VBoxContainer.new()
	preview_box.add_theme_constant_override("separation", 8)
	preview_panel.add_child(preview_box)
	var title := UiStyle.label("Así llegas a tu entrevista", 26, UiStyle.ACCENT)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	preview_box.add_child(title)
	_preview = AppearancePreview.new()
	_preview.animated = true
	_preview.use_sprites = true   # el mismo personaje por capas que en el juego (T102b)
	_preview.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_preview.action = "cast"   # posa de vez en cuando (no hay arma: la clase llega en el prólogo)
	preview_box.add_child(_preview)
	# Arrastrar sobre la figura la gira (T185).
	_preview.mouse_filter = Control.MOUSE_FILTER_STOP
	_preview.mouse_default_cursor_shape = Control.CURSOR_DRAG
	_preview.tooltip_text = "Arrastra para girar"
	_preview.gui_input.connect(_on_preview_input)
	var rotate_row := HBoxContainer.new()
	rotate_row.alignment = BoxContainer.ALIGNMENT_CENTER
	rotate_row.add_theme_constant_override("separation", 12)
	preview_box.add_child(rotate_row)
	rotate_row.add_child(UiStyle.button("<", _rotate.bind(-1), 48))
	rotate_row.add_child(UiStyle.label("Girar", 14, UiStyle.MUTED))
	rotate_row.add_child(UiStyle.button(">", _rotate.bind(1), 48))
	# T180: y así se verá dentro del servidor (desde el acto I), en pixel art.
	var server_row := HBoxContainer.new()
	server_row.alignment = BoxContainer.ALIGNMENT_CENTER
	server_row.add_theme_constant_override("separation", 10)
	preview_box.add_child(server_row)
	_student = StudentPreview.new()
	_student.custom_minimum_size = Vector2(110, 150)
	server_row.add_child(_student)
	var server_note := UiStyle.label("Así te verás\ndentro del servidor", 14, UiStyle.MUTED)
	server_note.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	server_row.add_child(server_note)

	# --- Apariencia ---
	var look_panel := PanelContainer.new()
	look_panel.custom_minimum_size = Vector2(430, 0)
	columns.add_child(look_panel)
	var look_box := VBoxContainer.new()
	look_box.add_theme_constant_override("separation", 10)
	look_panel.add_child(look_box)
	# Cabecera con un retrato de cerca (para ver ojos, barba y accesorios).
	var look_top := HBoxContainer.new()
	look_top.add_theme_constant_override("separation", 12)
	look_box.add_child(look_top)
	var look_titles := VBoxContainer.new()
	look_titles.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	look_titles.alignment = BoxContainer.ALIGNMENT_CENTER
	look_top.add_child(look_titles)
	look_titles.add_child(UiStyle.label("Apariencia", 22, UiStyle.ACCENT))
	var hint := UiStyle.label("No da stats. Es puramente cosmética,\ncomo los comentarios del código.", 12, UiStyle.MUTED)
	look_titles.add_child(hint)
	look_titles.add_child(UiStyle.button("Apariencia aleatoria", _randomize_appearance))
	_face = CharacterPortrait.new()
	_face.custom_minimum_size = Vector2(118, 118)
	look_top.add_child(_face)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	look_box.add_child(scroll)
	var options := VBoxContainer.new()
	options.add_theme_constant_override("separation", 6)
	options.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(options)
	options.add_child(_option_row("Complexión", "body", CharacterAppearance.BODY_NAMES))
	options.add_child(_option_row("Estatura", "height", CharacterAppearance.HEIGHT_NAMES))
	options.add_child(_option_row("Peinado", "hair", CharacterAppearance.HAIR_NAMES))
	options.add_child(_option_row("Barba", "beard", CharacterAppearance.BEARD_NAMES))
	options.add_child(_option_row("Accesorio", "accessory", CharacterAppearance.ACCESSORY_NAMES))
	options.add_child(_option_row("Voz", "voice", CharacterAppearance.VOICE_NAMES))
	for entry in [["Tono de piel", "skin_tone", CharacterAppearance.SKIN_TONES],
			["Color de pelo", "hair_color", CharacterAppearance.HAIR_COLORS],
			["Color de ojos", "eye_color", CharacterAppearance.EYE_COLORS],
			["Color del atuendo (en el mundo digital)", "outfit_color", CharacterAppearance.OUTFIT_COLORS],
			["Detalles (cinturón, zapatos, accesorio)", "accent_color", CharacterAppearance.ACCENT_COLORS]]:
		options.add_child(UiStyle.label(entry[0], 13, UiStyle.MUTED))
		options.add_child(_swatch_row(entry[1], entry[2]))

	# --- Nombre y confirmación ---
	var footer := HBoxContainer.new()
	footer.add_theme_constant_override("separation", 12)
	root.add_child(footer)
	footer.add_child(UiStyle.button("Volver", _back, 120))
	footer.add_child(UiStyle.label("Nombre:", 18))
	_name_edit = LineEdit.new()
	_name_edit.placeholder_text = "Cómo te recordarán los logs"
	_name_edit.max_length = CharacterSaves.NAME_MAX
	_name_edit.custom_minimum_size = Vector2(320, 44)
	_name_edit.text_changed.connect(func(_t: String) -> void:
		_validate()
		_refresh_record())
	_name_edit.text_submitted.connect(func(_t: String) -> void: _create())
	footer.add_child(_name_edit)
	footer.add_child(UiStyle.button("Nombre aleatorio", _random_name))
	_error = UiStyle.label("", 15, UiStyle.DANGER)
	_error.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_error.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	footer.add_child(_error)
	_skip_prologue = CheckBox.new()
	_skip_prologue.text = "Saltar prólogo"
	_skip_prologue.tooltip_text = "Directo a la elección de puesto (para quien ya lo vio)."
	_skip_prologue.focus_mode = Control.FOCUS_NONE
	footer.add_child(_skip_prologue)
	_create_button = UiStyle.button("Comenzar", _create, 200)
	_create_button.add_theme_font_size_override("font_size", 20)
	_create_button.custom_minimum_size.y = 48
	footer.add_child(_create_button)
	_validate()


func _option_row(title: String, key: String, names: Array) -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	var label := UiStyle.label(title, 14, UiStyle.MUTED)
	label.custom_minimum_size.x = 110
	row.add_child(label)
	row.add_child(UiStyle.button("<", _cycle.bind(key, names.size(), -1), 40))
	var value := UiStyle.label("", 16)
	value.custom_minimum_size.x = 160
	value.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	row.add_child(value)
	row.add_child(UiStyle.button(">", _cycle.bind(key, names.size(), 1), 40))
	_option_labels[key] = value
	return row


func _swatch_row(key: String, colors: Array) -> Control:
	var row := HFlowContainer.new()
	row.add_theme_constant_override("h_separation", 5)
	row.add_theme_constant_override("v_separation", 5)
	var buttons: Array[Button] = []
	for hex in colors:
		var b := Button.new()
		b.custom_minimum_size = Vector2(30, 26)
		b.focus_mode = Control.FOCUS_NONE
		b.tooltip_text = "#" + hex
		b.pressed.connect(func() -> void:
			_appearance[key] = hex
			_refresh_appearance())
		UiStyle.juicy(b)   # rebote y sonido (T185)
		row.add_child(b)
		buttons.append(b)
	_swatch_rows[key] = buttons
	return row


## El expediente: humor de recién egresado, con el nombre que se va escribiendo.
func _refresh_record() -> void:
	var name := _name_edit.text.strip_edges() if _name_edit and _name_edit.text.strip_edges() != "" else "(sin nombre)"
	var rows := [
		["Nombre", name],
		["Matrícula", _student_id],
		["Carrera", "Ingeniería en Sistemas Computacionales"],
		["Promedio", "9.2"],
		["Vacantes aplicadas", "147"],
		["Entrevistas", "3 (una era una pirámide de ventas)"],
		["Experiencia", "0 años [color=#8b949e](requerida: 5)[/color]"],
		["Servicio social", "480 h [color=#e06c6c](falta el sello)[/color]"],
		["Título", "[color=#e06c6c]en trámite[/color]"],
		["Estado", "[color=#2dd4bf]Desempleado[/color]"],
	]
	var text := ""
	for r in rows:
		text += "[color=#8b949e]%s:[/color]  %s\n" % r
	_record.text = text


func _cycle(key: String, count: int, step: int) -> void:
	if key == "height":
		var i := posmod(CharacterAppearance.height_index(_appearance) + step, count)
		_appearance["height"] = CharacterAppearance.HEIGHT_VALUES[i]
	else:
		_appearance[key] = posmod(int(_appearance.get(key, 0)) + step, count)
	_refresh_appearance()


func _rotate(step: int) -> void:
	_facing_index = posmod(_facing_index + step, FACINGS.size())
	_preview.turn_to(FACINGS[_facing_index])   # con el paso intermedio (T185)
	if _student:   # el alumno gira con él (T181)
		_student.facing = FACINGS[_facing_index]


func _randomize_appearance() -> void:
	_appearance = CharacterAppearance.random(_rng)
	_refresh_appearance()


func _refresh_appearance() -> void:
	_appearance = CharacterAppearance.sanitize(_appearance)
	_preview.appearance = _appearance.duplicate()
	# El pedestal toma el color del atuendo y cada cambio da un «pop» con destello (T185).
	_preview.glow_color = Color(String(_appearance.get("outfit_color", "2dd4bf")))
	if _built:
		_preview.flash()
	_face.appearance = _appearance.duplicate()
	if _student:
		_student.appearance = _appearance.duplicate()
	_option_labels["body"].text = CharacterAppearance.BODY_NAMES[_appearance["body"]]
	_option_labels["height"].text = CharacterAppearance.HEIGHT_NAMES[CharacterAppearance.height_index(_appearance)]
	_option_labels["hair"].text = CharacterAppearance.HAIR_NAMES[_appearance["hair"]]
	_option_labels["beard"].text = CharacterAppearance.BEARD_NAMES[_appearance["beard"]]
	_option_labels["accessory"].text = CharacterAppearance.ACCESSORY_NAMES[_appearance["accessory"]]
	_option_labels["voice"].text = CharacterAppearance.VOICE_NAMES[_appearance["voice"]]
	_selected_swatches.clear()
	for key in _swatch_rows:
		for b: Button in _swatch_rows[key]:
			var hex := b.tooltip_text.substr(1)
			var selected: bool = hex == String(_appearance.get(key, ""))
			var style := StyleBoxFlat.new()
			style.bg_color = Color(hex)
			style.border_color = UiStyle.ACCENT if selected else UiStyle.BORDER
			style.set_border_width_all(3 if selected else 1)
			style.set_corner_radius_all(3)
			if selected:
				_selected_swatches.append(style)
			for state in ["normal", "hover", "pressed", "focus"]:
				b.add_theme_stylebox_override(state, style)


func _random_name() -> void:
	var options: Array = RANDOM_NAMES.filter(func(n: String) -> bool:
		return CharacterSaves.validate_name(n, _existing_names) == "")
	var picked: String = options[_rng.randi_range(0, options.size() - 1)] if not options.is_empty() \
		else "Egresado %d" % _rng.randi_range(100, 999)
	_name_edit.text = picked
	_validate()
	_refresh_record()


func _validate() -> bool:
	var problem := CharacterSaves.validate_name(_name_edit.text, _existing_names)
	# Sin escribir nada todavía, no hace falta regañar.
	_error.text = problem if _name_edit.text != "" else ""
	_create_button.disabled = problem != ""
	return problem == ""


func _create() -> void:
	if not _validate():
		return
	GameData.pending_creation = {"name": _name_edit.text.strip_edges(), "appearance": _appearance.duplicate(),
		"skip_prologue": _skip_prologue.button_pressed}
	ScreenTransition.change_scene(get_tree(), GameData.PROLOGUE_SCENE)   # con el barrido (T183)


func _back() -> void:
	ScreenTransition.change_scene(get_tree(), GameData.MAIN_MENU_SCENE)
