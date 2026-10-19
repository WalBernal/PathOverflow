class_name CutscenePlayer
extends Control
## Escenas cortas (data/cutscenes.json): líneas de diálogo con retrato y
## efectos de pantalla (glitch, temblor, fundido a negro y la pantalla de "sin
## conexión" del dinosaurio). Mientras dura, el jugador no se mueve.
## Las líneas avanzan solas: al terminar de escribirse, esperan un tiempo de
## lectura (según su longitud) o, con el narrador activado, a que la voz acabe.
## Click, Espacio o Enter: completar el texto o pasar ya a la siguiente.
## Esc: saltar la escena entera.

signal finished

const BOX_WIDTH := 760.0
const CHARS_PER_SECOND := 55.0
const NARRATED_CPS := 15.0
## Tiempo de lectura tras escribirse la línea: base + por carácter.
const READ_BASE := 1.4
const READ_PER_CHAR := 0.035
const DINO_TIME := 4.5
const STYLE_COLORS := {
	"npc": Color("d9a441"), "boss": Color("e0503a"), "console": Color("3cff6a"),
	"system": Color("8ab0e0"), "phone": Color("6fd36b"),
}

var player: Player
var _steps: Array = []
var _index := -1
var _on_done: Callable
var _wait := 0.0
var _waiting_input := false
var _time := 0.0
var _glitch := 0.0          # intensidad (decae sola)
var _shake := 0.0
var _black := 0.0           # 0..1
var _black_target := 0.0
var _dino := false
var _dino_text := ""

var _box: PanelContainer
var _portrait: AppearancePreview
var _name: Label
var _text: RichTextLabel
var _hint: Label
var _shown := 0.0
var _total := 0
var _blip: AudioStreamPlayer
var _pitch := 1.0
var _rate := 1.0
var _read_left := 0.0       # cuenta atrás para pasar sola a la siguiente
var _read_total := 1.0
var _narrating := false
var _cps := CHARS_PER_SECOND
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	theme = UiStyle.make_theme()
	mouse_filter = Control.MOUSE_FILTER_STOP
	visible = false
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_box = PanelContainer.new()
	_box.add_theme_stylebox_override("panel", UiStyle.panel_style())
	add_child(_box)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 14)
	_box.add_child(row)
	_portrait = AppearancePreview.new()
	_portrait.custom_minimum_size = Vector2(90, 120)
	_portrait.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	row.add_child(_portrait)
	var col := VBoxContainer.new()
	col.custom_minimum_size.x = BOX_WIDTH - 120.0
	row.add_child(col)
	_name = UiStyle.label("", 18, UiStyle.ACCENT)
	col.add_child(_name)
	_text = RichTextLabel.new()
	_text.bbcode_enabled = true
	_text.fit_content = true
	_text.scroll_active = false
	_text.custom_minimum_size = Vector2(BOX_WIDTH - 120.0, 50)
	_text.add_theme_font_size_override("normal_font_size", 16)
	_text.add_theme_font_size_override("mono_font_size", 15)
	col.add_child(_text)
	_hint = UiStyle.label("Avanza sola  ·  Click / Espacio: siguiente  ·  Esc: saltar", 11, UiStyle.MUTED)
	_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	col.add_child(_hint)
	_blip = AudioStreamPlayer.new()
	_blip.stream = RetroSfx.blip()
	_blip.volume_db = -14.0
	add_child(_blip)


func play(data: Dictionary, on_done: Callable) -> void:
	_steps = data.get("steps", [])
	_on_done = on_done
	_index = -1
	_black = 0.0
	_black_target = 0.0
	_glitch = 0.0
	_dino = false
	visible = true
	if player:
		player.controls_locked = true
	_box.visible = false
	_next()


func is_playing() -> bool:
	return visible


func _next() -> void:
	_index += 1
	_waiting_input = false
	_dino = false
	if _index >= _steps.size():
		_finish()
		return
	var step: Dictionary = _steps[_index]
	if step.has("effect"):
		_box.visible = false
		var strength := float(step.get("strength", 1.0))
		match String(step["effect"]):
			"glitch":
				_glitch = maxf(_glitch, strength)
			"shake":
				_shake = maxf(_shake, strength)
			"blackout":
				_black_target = 1.0
			"fade_in":
				_black_target = 0.0
			"dino":
				_dino = true
				_dino_text = step.get("text", "")
				_waiting_input = true
				_read_left = DINO_TIME
				_read_total = DINO_TIME
				return
		_wait = float(step.get("time", 0.5))
		return
	_show_line(step)


func _show_line(step: Dictionary) -> void:
	var style: String = step.get("style", "npc")
	var color: Color = STYLE_COLORS.get(style, UiStyle.ACCENT)
	var npc: Dictionary = Zone.npc_database().get("npcs", {}).get(step.get("speaker", ""), {})
	_name.text = step.get("name", npc.get("name", ""))
	_name.add_theme_color_override("font_color", color)
	_portrait.visible = not npc.is_empty() and style != "console"
	if _portrait.visible:
		_portrait.appearance = CharacterAppearance.sanitize(npc.get("appearance", {}))
	_pitch = float(npc.get("voice", {}).get("pitch", 0.7 if style == "boss" else 1.0))
	_rate = float(npc.get("voice", {}).get("rate", 0.9 if style == "boss" else 1.0))
	var text: String = step.get("text", "")
	if style == "console":
		text = "[code][color=#3cff6a]%s[/color][/code]" % text
	elif style == "boss":
		text = "[color=#f0c0b0]%s[/color]" % text
	elif style == "phone":
		text = "[i]%s[/i]" % text   # se oye entrecortado
	_text.text = text
	_total = _text.get_total_character_count()
	_shown = 0.0
	_text.visible_characters = 0
	_box.visible = true
	_waiting_input = true
	_read_total = READ_BASE + READ_PER_CHAR * _total
	_read_left = _read_total
	_speak(style)


## El narrador lee la línea (las de consola no: se leen solas en pantalla).
func _speak(style: String) -> void:
	_stop_voice()
	_cps = CHARS_PER_SECOND
	if style == "console" or not DialogueBox.narrator_enabled():
		return
	var voices := DisplayServer.tts_get_voices_for_language("es")
	if voices.is_empty():
		return
	DisplayServer.tts_speak(_text.get_parsed_text(), voices[0], 80, clampf(_pitch, 0.0, 2.0), clampf(_rate * 1.1, 0.5, 2.0))
	_narrating = true
	_cps = NARRATED_CPS * _rate


func _stop_voice() -> void:
	if _narrating:
		DisplayServer.tts_stop()
		_narrating = false
	_reposition.call_deferred()


func _reposition() -> void:
	_box.reset_size()
	_box.position = Vector2((size.x - _box.size.x) / 2.0, size.y - _box.size.y - 140.0)


func _finish() -> void:
	_stop_voice()
	visible = false
	_box.visible = false
	if player:
		player.controls_locked = false
		_set_camera_offset(Vector2.ZERO)
	finished.emit()
	if _on_done.is_valid():
		_on_done.call()


func _process(delta: float) -> void:
	if not visible:
		return
	_time += delta
	_glitch = maxf(0.0, _glitch - delta * 0.8)
	_shake = maxf(0.0, _shake - delta * 1.5)
	_black = move_toward(_black, _black_target, delta * 1.6)
	_set_camera_offset(Vector2(_rng.randf_range(-1, 1), _rng.randf_range(-1, 1)) * _shake * 14.0)
	if _box.visible and _shown < _total:
		var before := int(_shown)
		_shown = minf(_total, _shown + _cps * delta)
		_text.visible_characters = int(_shown) if _shown < _total else -1
		if int(_shown) / 3 != before / 3 and DialogueBox.blips_enabled():
			_blip.pitch_scale = _pitch * randf_range(0.92, 1.08)
			_blip.play()
	if not _waiting_input:
		_wait -= delta
		if _wait <= 0.0:
			_next()
	elif _dino or (_box.visible and _shown >= _total):
		# Lectura automática: espera a la voz (si habla) y luego el tiempo de lectura.
		if _narrating and DisplayServer.tts_is_speaking():
			_read_left = maxf(_read_left, 0.6)
		else:
			_narrating = false
			_read_left -= delta
			if _read_left <= 0.0:
				_next()
	queue_redraw()


func _set_camera_offset(o: Vector2) -> void:
	if player and player.has_node("Camera2D"):
		(player.get_node("Camera2D") as Camera2D).offset = o


func _gui_input(event: InputEvent) -> void:
	var mb := event as InputEventMouseButton
	if mb and mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT:
		_advance()
		accept_event()


func _input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed(&"ui_cancel"):
		_index = _steps.size()
		_black_target = 0.0
		_black = 0.0
		_next()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed(&"ui_accept") or (event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_SPACE):
		_advance()
		get_viewport().set_input_as_handled()


func _advance() -> void:
	if not _waiting_input:
		return
	if _box.visible and _shown < _total:
		_shown = _total
		_text.visible_characters = -1
		return
	_stop_voice()
	_next()


# --- Dibujo de efectos ---

func _draw() -> void:
	var view := size
	if _dino:
		_draw_offline_page(view)
	# Barra de lectura automática bajo el cuadro de texto.
	if _box.visible and _shown >= _total and _read_total > 0.0:
		var frac := clampf(1.0 - _read_left / _read_total, 0.0, 1.0)
		var bar := Rect2(_box.position + Vector2(0, _box.size.y + 4), Vector2(_box.size.x, 3))
		draw_rect(bar, Color(0, 0, 0, 0.6))
		draw_rect(Rect2(bar.position, Vector2(bar.size.x * frac, bar.size.y)), Color(UiStyle.ACCENT, 0.8))
	if _glitch > 0.0:
		_draw_glitch(view)
	if _black > 0.0:
		draw_rect(Rect2(Vector2.ZERO, view), Color(0, 0, 0, _black))


## Barras de colores desplazadas, ruido y binario: el sistema rompiéndose.
func _draw_glitch(view: Vector2) -> void:
	var seed_value := int(_time * 24.0)
	_rng.seed = seed_value
	var bars := int(6 + 18 * _glitch)
	for k in bars:
		var y := _rng.randf() * view.y
		var h := _rng.randf_range(2.0, 18.0) * _glitch
		var colors := [Color(1, 0, 0.3), Color(0, 1, 0.8), Color(0.3, 0.4, 1.0), Color(1, 1, 1)]
		draw_rect(Rect2(_rng.randf_range(-80, 80), y, view.x, h), Color(colors[k % 4], 0.12 * _glitch))
	var font := get_theme_default_font()
	for k in int(30 * _glitch):
		draw_string(font, Vector2(_rng.randf() * view.x, _rng.randf() * view.y), "1" if _rng.randf() < 0.5 else "0",
			HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color(0.3, 1.0, 0.5, 0.5 * _glitch))
	_rng.randomize()


## La página de "sin conexión" (en modo oscuro), con el dinosaurio saltando cactus.
func _draw_offline_page(view: Vector2) -> void:
	draw_rect(Rect2(Vector2.ZERO, view), Color("202124"))
	var font := get_theme_default_font()
	var grey := Color("9aa0a6")
	var origin := Vector2(view.x * 0.5 - 300.0, view.y * 0.22)
	# Dinosaurio (pixel art) y su carrera.
	var px := 4.0
	var jump := maxf(0.0, sin(fmod(_time * 2.2, PI))) * 46.0 if fmod(_time, 2.8) < 1.43 else 0.0
	var dino := [
		"          ########",
		"         ## ######",
		"         #########",
		"         #########",
		"         #####    ",
		"         ########",
		"#       #####    ",
		"##    #######    ",
		"###  #########   ",
		"############ #   ",
		" ###########     ",
		"  #########      ",
		"   #######       ",
		"    ### ##       ",
		"    ##   #       ",
		"    #    ##      ",
	]
	var base := origin + Vector2(0, 70 - jump)
	for y in dino.size():
		var row: String = dino[y]
		for x in row.length():
			if row[x] == "#":
				draw_rect(Rect2(base + Vector2(x, y) * px, Vector2(px, px)), grey)
	# Suelo y cactus que se acercan.
	var ground_y := origin.y + 70 + dino.size() * px
	draw_line(Vector2(origin.x - 20, ground_y), Vector2(origin.x + 620, ground_y), grey, 2.0)
	var cactus_x := origin.x + 600.0 - fmod(_time * 260.0, 640.0)
	draw_rect(Rect2(cactus_x, ground_y - 44, 12, 44), grey)
	draw_rect(Rect2(cactus_x - 10, ground_y - 30, 8, 16), grey)
	draw_rect(Rect2(cactus_x + 14, ground_y - 36, 8, 18), grey)
	# Texto de la página.
	var y0 := ground_y + 50.0
	draw_string(font, Vector2(origin.x, y0), "No hay conexión a Internet", HORIZONTAL_ALIGNMENT_LEFT, -1, 28, Color("e8eaed"))
	draw_string(font, Vector2(origin.x, y0 + 40), _dino_text + ". Prueba a:", HORIZONTAL_ALIGNMENT_LEFT, -1, 17, grey)
	var tips := ["Comprobar los cables de red, el módem y el router", "Reiniciar el router de La Red Lince (otra vez)",
		"Llamar al servicio técnico de La Red Lince (tiempo de espera: 3 actos)", "Usar los datos del celular de Rafa"]
	for k in tips.size():
		draw_string(font, Vector2(origin.x + 16, y0 + 72 + k * 26), "•  " + tips[k], HORIZONTAL_ALIGNMENT_LEFT, -1, 16, grey)
	draw_string(font, Vector2(origin.x, y0 + 196), "ERR_LINCE_DISCONNECTED", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color("6a6f75"))
	var blink := "_" if fmod(_time, 1.0) < 0.5 else " "
	draw_string(font, Vector2(origin.x, view.y - 60), "Click para continuar" + blink, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color("6a6f75"))
