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
var _option_labels := {}      # clave -> Label del valor (complexión, peinado...)
var _swatch_rows := {}        # clave -> Array[Button]
var _name_edit: LineEdit
var _error: Label
var _create_button: Button
var _skip_prologue: CheckBox


func _ready() -> void:
	theme = UiStyle.make_theme()
	_rng.randomize()
	_student_id = "%d%06d" % [Time.get_date_dict_from_system()["year"] % 100, _rng.randi_range(0, 999999)]
	MusicPlayer.play_title()
	for data in CharacterSaves.list_all():
		_existing_names.append(data.get("name", ""))
	_build()
	_refresh_appearance()
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
	queue_redraw()


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


func _draw() -> void:
	UiStyle.draw_background(self, size)
	var font := get_theme_default_font()
	for f in _floaters:
		var color := Color(0.25, 0.95, 0.45, f["alpha"]) if f["binary"] else Color(0.85, 0.8, 0.6, f["alpha"])
		draw_string(font, Vector2(f["x"], f["y"]), f["text"], HORIZONTAL_ALIGNMENT_LEFT, -1, 15, color)


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
	header.add_child(titles)
	titles.add_child(UiStyle.label("Recién egresado", 36, UiStyle.ACCENT))
	titles.add_child(UiStyle.label("$ git init personaje  —  elige cara y un nombre que no dé vergüenza en los logs. El puesto ya te lo darán... más o menos.", 15, UiStyle.MUTED))

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
	_preview.size_flags_vertical = Control.SIZE_EXPAND_FILL
	preview_box.add_child(_preview)
	var rotate_row := HBoxContainer.new()
	rotate_row.alignment = BoxContainer.ALIGNMENT_CENTER
	rotate_row.add_theme_constant_override("separation", 12)
	preview_box.add_child(rotate_row)
	rotate_row.add_child(UiStyle.button("<", _rotate.bind(-1), 48))
	rotate_row.add_child(UiStyle.label("Girar", 14, UiStyle.MUTED))
	rotate_row.add_child(UiStyle.button(">", _rotate.bind(1), 48))

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
		["Experiencia", "0 años [color=#8a8293](requerida: 5)[/color]"],
		["Servicio social", "480 h [color=#e06c6c](falta el sello)[/color]"],
		["Título", "[color=#e06c6c]en trámite[/color]"],
		["Estado", "[color=#d9a441]Desempleado[/color]"],
	]
	var text := ""
	for r in rows:
		text += "[color=#8a8293]%s:[/color]  %s\n" % r
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
	_preview.facing = FACINGS[_facing_index]


func _randomize_appearance() -> void:
	_appearance = CharacterAppearance.random(_rng)
	_refresh_appearance()


func _refresh_appearance() -> void:
	_appearance = CharacterAppearance.sanitize(_appearance)
	_preview.appearance = _appearance.duplicate()
	_face.appearance = _appearance.duplicate()
	_option_labels["body"].text = CharacterAppearance.BODY_NAMES[_appearance["body"]]
	_option_labels["height"].text = CharacterAppearance.HEIGHT_NAMES[CharacterAppearance.height_index(_appearance)]
	_option_labels["hair"].text = CharacterAppearance.HAIR_NAMES[_appearance["hair"]]
	_option_labels["beard"].text = CharacterAppearance.BEARD_NAMES[_appearance["beard"]]
	_option_labels["accessory"].text = CharacterAppearance.ACCESSORY_NAMES[_appearance["accessory"]]
	for key in _swatch_rows:
		for b: Button in _swatch_rows[key]:
			var hex := b.tooltip_text.substr(1)
			var selected: bool = hex == String(_appearance.get(key, ""))
			var style := StyleBoxFlat.new()
			style.bg_color = Color(hex)
			style.border_color = UiStyle.ACCENT if selected else UiStyle.BORDER
			style.set_border_width_all(3 if selected else 1)
			style.set_corner_radius_all(3)
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
	get_tree().change_scene_to_file(GameData.PROLOGUE_SCENE)


func _back() -> void:
	get_tree().change_scene_to_file(GameData.MAIN_MENU_SCENE)
