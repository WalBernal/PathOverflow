class_name CutscenePlayer
extends Control
## Escenas cortas (data/cutscenes.json): líneas de diálogo con retrato y
## efectos de pantalla (glitch, temblor, fundido a negro y la pantalla de "sin
## conexión" del dinosaurio). Mientras dura, el jugador no se mueve.
## Las líneas avanzan solas: al terminar de escribirse, esperan un tiempo de
## lectura (según su longitud) o, con el narrador activado, a que la voz acabe.
## Click, toque, Espacio, Enter o A del mando: completar el texto o pasar ya a la
## siguiente. Esc, B del mando o el botón «Saltar escena»: saltar la escena entera.
## Dirección (T129), pasos {effect: ...}:
## - "camera": la cámara va a `to` ("player", "npc:<id>", "boss", "exit:<destino>" o [x, y])
##   con `zoom` (1 = normal) en `time` s; al acabar la escena vuelve sola.
## - "walk": `who` ("npc:<id>" o "player") camina hasta `to` (como en camera, o {"by": [dx, dy]}).
## - "turn": `who` (un NPC) mira a `face` ("left", "right", "player").
## - "bars": bandas de cine (`on`: true/false); salen solas salvo `"bars": false` en la escena.
## Y en las líneas, `expression`: "happy", "angry", "sad", "surprised" o "worried".

signal finished
## Cada paso de efecto (también los que no conoce, para quien escuche: el prólogo).
signal effect(effect_name: String, strength: float)

const BOX_WIDTH := 760.0
const CHARS_PER_SECOND := 55.0
const NARRATED_CPS := 15.0
## Tiempo de lectura tras escribirse la línea: base + por carácter.
const READ_BASE := 1.4
const READ_PER_CHAR := 0.035
const DINO_TIME := 4.5
## Pausa mínima entre dos avances (completar línea / pasar a la siguiente).
const ADVANCE_COOLDOWN := 0.3
const STYLE_COLORS := {
	"npc": UiStyle.ACCENT, "boss": Color("e0503a"), "console": Color("3cff6a"),
	"system": Color("8ab0e0"), "phone": Color("6fd36b"),
}

var player: Player
## Hablantes que no están en npcs.json (p. ej. el jugador en el prólogo):
## id -> {name, appearance, voice, color}.
var speakers: Dictionary = {}
var _steps: Array = []
var _index := -1
var _on_done: Callable
var _wait := 0.0
var _waiting_input := false
var _last_advance := -10.0
var _time := 0.0
var _glitch := 0.0          # intensidad (decae sola)
var _shake := 0.0
var _black := 0.0           # 0..1
var _black_target := 0.0
var _dino := false
var _dino_text := ""

var _box: PanelContainer
var _portrait: CharacterPortrait
var _name: Label
var _text: RichTextLabel
var _hint: Label
var _shown := 0.0
var _total := 0
var _blip: AudioStreamPlayer
var _voice_age := 0.0
var _voice: Dictionary = {}
var _pitch := 1.0
var _rate := 1.0
var _read_left := 0.0       # cuenta atrás para pasar sola a la siguiente
var _read_total := 1.0
var _narrating := false
var _cps := CHARS_PER_SECOND
var _rng := RandomNumberGenerator.new()
## Paso {input: "password", flag, text}: el jugador escribe y se guarda en sus
## banderas (con validación sarcástica). Si salta la escena, queda DEFAULT_PASSWORD.
var _input_edit: LineEdit
var _input_step: Dictionary = {}
const DEFAULT_PASSWORD := "admin2"
const HINT_TEXT := "Avanza sola  ·  Click / Espacio / A: siguiente  ·  Esc / B: saltar"
## Bandas de cine (T129): alto de cada una y lo que tardan en entrar.
const BARS_HEIGHT := 64.0
const BARS_SPEED := 2.5

## La zona donde pasa la escena (GameUI la pone): para buscar NPC, jefe y salidas.
var zone: Zone
var _bars := 0.0
var _bars_target := 0.0
var _cam_from := Vector2.ZERO    # desplazamiento de la cámara respecto al jugador
var _cam_to := Vector2.ZERO
var _cam_zoom_from := 1.0
var _cam_zoom_to := 1.0
var _cam_t := 1.0
var _cam_time := 0.0
var _base_zoom := Vector2.ONE
var _movers: Array[Dictionary] = []   # {who, from, to, t, time}
var _skip_button: Button


func _ready() -> void:
	theme = UiStyle.make_theme()
	mouse_filter = Control.MOUSE_FILTER_STOP
	visible = false
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_box = PanelContainer.new()
	UiStyle.decorate_window(_box)
	add_child(_box)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 14)
	_box.add_child(row)
	_portrait = CharacterPortrait.new()
	_portrait.custom_minimum_size = Vector2(110, 110)
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
	_input_edit = LineEdit.new()
	_input_edit.visible = false
	_input_edit.max_length = 32
	_input_edit.add_theme_font_size_override("font_size", 16)
	_input_edit.text_submitted.connect(_on_input_submitted)
	col.add_child(_input_edit)
	_hint = UiStyle.label(HINT_TEXT, 11, UiStyle.MUTED)
	_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	col.add_child(_hint)
	_blip = AudioStreamPlayer.new()
	_blip.stream = RetroSfx.blip()
	_blip.volume_db = -14.0
	add_child(_blip)
	# Saltar la escena con el ratón o el dedo (T129), arriba a la derecha, sobre la banda.
	_skip_button = UiStyle.button("Saltar escena (Esc)", skip, 0)
	_skip_button.add_theme_font_size_override("font_size", 12)
	_skip_button.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	_skip_button.position = Vector2(-190, 14)
	add_child(_skip_button)


func play(data: Dictionary, on_done: Callable) -> void:
	_steps = data.get("steps", [])
	_on_done = on_done
	_index = -1
	_black = 0.0
	_black_target = 0.0
	_glitch = 0.0
	_dino = false
	_movers.clear()
	_bars = 0.0
	_bars_target = 0.0 if data.get("bars", true) == false else 1.0
	_cam_from = Vector2.ZERO
	_cam_to = Vector2.ZERO
	_cam_t = 1.0
	_cam_zoom_from = 1.0
	_cam_zoom_to = 1.0
	visible = true
	if player:
		player.controls_locked = true
		var cam := _camera()
		if cam:
			_base_zoom = cam.zoom
	_box.visible = false
	_next()


func is_playing() -> bool:
	return visible


func _next() -> void:
	_index += 1
	FreezeWatch.mark("escena: paso %d" % _index)
	_waiting_input = false
	_dino = false
	if _index >= _steps.size():
		_finish()
		return
	var step: Dictionary = _steps[_index]
	if step.has("input"):
		_show_line(step)
		_input_step = step
		_input_edit.text = ""
		_input_edit.visible = true
		_input_edit.grab_focus.call_deferred()
		_hint.text = "Escribe y pulsa Enter"
		return
	if step.has("effect"):
		_box.visible = false
		var strength := float(step.get("strength", 1.0))
		effect.emit(String(step["effect"]), strength)
		match String(step["effect"]):
			"glitch":
				_glitch = maxf(_glitch, strength)
			"shake":
				_shake = maxf(_shake, strength)
			"blackout":
				_black_target = 1.0
			"fade_in":
				_black_target = 0.0
			"camera":
				var target := resolve_point(step.get("to", "player"))
				_cam_from = _current_cam_offset()
				_cam_to = (target - player.global_position) if player and target != Vector2.INF else _cam_from
				_cam_zoom_from = lerpf(_cam_zoom_from, _cam_zoom_to, _ease(_cam_t))
				_cam_zoom_to = float(step.get("zoom", 1.0))
				_cam_time = maxf(0.05, float(step.get("time", 0.8)))
				_cam_t = 0.0
			"walk":
				var from := _position_of(String(step.get("who", "")))
				var to_spec = step.get("to", null)
				var to := from + Zone._v(to_spec["by"]) if to_spec is Dictionary and to_spec.has("by") else resolve_point(to_spec)
				if from != Vector2.INF and to != Vector2.INF:
					_movers.append({"who": String(step.get("who", "")), "from": from, "to": to, "t": 0.0, "time": maxf(0.1, float(step.get("time", 1.0)))})
			"turn":
				var npc := _npc(String(step.get("who", "")).trim_prefix("npc:"))
				if not npc.is_empty():
					var face := String(step.get("face", "player"))
					npc["facing_override"] = {"left": Vector2(-0.5, 1.0), "right": Vector2(0.5, 1.0)}.get(face, null)
					if npc["facing_override"] == null:
						npc.erase("facing_override")
			"bars":
				_bars_target = 1.0 if step.get("on", true) else 0.0
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
	var npc: Dictionary = speakers.get(step.get("speaker", ""), Zone.npc_database().get("npcs", {}).get(step.get("speaker", ""), {}))
	_name.text = step.get("name", npc.get("name", ""))
	_name.add_theme_color_override("font_color", color)
	_portrait.visible = not npc.is_empty() and style != "console"
	if _portrait.visible:
		_portrait.appearance = CharacterAppearance.sanitize(npc.get("appearance", {}))
		_portrait.ring_color = color
		_portrait.glitch = 0.6 if style == "phone" or npc.get("terminal", false) else 0.0
		_portrait.expression = String(step.get("expression", ""))   # la cara de esta línea (T129)
	_voice = npc.get("voice", {})
	_pitch = float(npc.get("voice", {}).get("pitch", 0.7 if style == "boss" else 1.0))
	_rate = float(npc.get("voice", {}).get("rate", 0.9 if style == "boss" else 1.0))
	var text: String = String(step.get("text", "")).replace("{jugador}", String(speakers.get("player", {}).get("name", "tú")))
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
	if not DialogueBox.speak(_text.get_parsed_text(), _pitch, _rate, _voice):
		return   # la voz sigue con la línea anterior: esta va sin voz
	_voice_age = 0.0
	_narrating = true
	_cps = NARRATED_CPS * _rate


func _stop_voice() -> void:
	if _narrating:
		DialogueBox.stop_speaking()
		_narrating = false
	_reposition.call_deferred()


func _reposition() -> void:
	_box.reset_size()
	_box.position = Vector2((size.x - _box.size.x) / 2.0, size.y - _box.size.y - 140.0)


## Por qué no vale una contraseña ("" = vale).
static func password_problem(text: String, player_name := "") -> String:
	var t := text.strip_edges()
	var low := t.to_lower()
	if t == "":
		return "No puede quedar vacía. Así la tenía Berta para el supervisor, y mira."
	if low == "admin":
		return "Esa es la de siempre. Por eso estamos aquí."
	if low.contains("1234") or low.contains("password") or low.contains("contraseña") or low.contains("qwerty"):
		return "No. Simplemente no."
	if player_name != "" and low.contains(player_name.strip_edges().to_lower()):
		return "No uses tu nombre: es lo primero que prueba un Beep Code."
	if t.length() >= 6 and t.is_valid_int() and t.length() <= 8:
		return "¿Es tu fecha de nacimiento? Parece tu fecha de nacimiento. No uses tu fecha de nacimiento."
	if t.length() < 6:
		return "Demasiado corta: admin la adivinaría en un pitido."
	return ""


func _on_input_submitted(text: String) -> void:
	if _input_step.is_empty():
		return
	var problem := password_problem(text, String(speakers.get("player", {}).get("name", "")))
	if problem != "":
		_text.text = "%s\n[color=#e0a060]%s[/color]" % [_input_step.get("text", ""), problem]
		_text.visible_characters = -1
		return
	_save_input(_input_step, text.strip_edges())
	_end_input()
	_next()


func _save_input(step: Dictionary, value: String) -> void:
	if player and player.character:
		player.character.flags[String(step.get("flag", "input"))] = value


func _end_input() -> void:
	_input_step = {}
	if _input_edit:
		_input_edit.visible = false
		_input_edit.release_focus()
		_hint.text = HINT_TEXT


## Al saltar la escena: los pasos de escribir que falten se quedan con su valor por defecto.
func _default_inputs(from: int) -> void:
	for k in range(maxi(from, 0), _steps.size()):
		var s: Dictionary = _steps[k]
		if s.has("input") and player and player.character and not player.character.flags.has(String(s.get("flag", "input"))):
			_save_input(s, DEFAULT_PASSWORD)
			player.character.flags[String(s.get("flag", "input")) + "_saltada"] = true
	_end_input()


func _finish() -> void:
	_default_inputs(_index)
	_stop_voice()
	for m in _movers:   # quien estaba caminando llega a su sitio
		_place(String(m["who"]), m["to"])
	_movers.clear()
	visible = false
	_box.visible = false
	if player:
		player.controls_locked = false
		_set_camera_offset(Vector2.ZERO)
		var cam := _camera()
		if cam:
			cam.zoom = _base_zoom
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
	_bars = move_toward(_bars, _bars_target, delta * BARS_SPEED)
	_cam_t = minf(1.0, _cam_t + delta / maxf(0.05, _cam_time))
	var shake := Vector2(_rng.randf_range(-1, 1), _rng.randf_range(-1, 1)) * _shake * 14.0
	_set_camera_offset(_current_cam_offset() + shake)
	var cam := _camera()
	if cam:
		cam.zoom = _base_zoom * lerpf(_cam_zoom_from, _cam_zoom_to, _ease(_cam_t))
	for m in _movers.duplicate():
		m["t"] = float(m["t"]) + delta
		var k := clampf(float(m["t"]) / float(m["time"]), 0.0, 1.0)
		var from: Vector2 = m["from"]
		var to: Vector2 = m["to"]
		_place(String(m["who"]), from.lerp(to, k), to - from)
		if k >= 1.0:
			_movers.erase(m)
	_portrait.talking = _box.visible and (_shown < _total or (_narrating and DialogueBox.voice_busy()))
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
	elif _input_step.is_empty() and (_dino or (_box.visible and _shown >= _total)):
		# Lectura automática: espera a la voz (si habla) y luego el tiempo de lectura.
		_voice_age += delta
		if _narrating and (_voice_age < DialogueBox.VOICE_GRACE or DialogueBox.voice_busy()):
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


func _camera() -> Camera2D:
	return player.get_node("Camera2D") as Camera2D if player and player.has_node("Camera2D") else null


static func _ease(t: float) -> float:
	return t * t * (3.0 - 2.0 * t)   # suave al salir y al llegar


func _current_cam_offset() -> Vector2:
	return _cam_from.lerp(_cam_to, _ease(_cam_t))


## Un punto de la escena: "player", "npc:<id>", "boss", "exit:<destino>" o [x, y] (INF si no está).
func resolve_point(spec: Variant) -> Vector2:
	if spec is Array and spec.size() >= 2:
		return Vector2(float(spec[0]), float(spec[1]))
	var s := String(spec) if spec != null else "player"
	if s == "player":
		return player.global_position if player else Vector2.INF
	if zone == null:
		return Vector2.INF
	if s.begins_with("npc:"):
		var npc := _npc(s.trim_prefix("npc:"))
		return zone.npc_position(npc) if not npc.is_empty() else Vector2.INF
	if s == "boss":
		var b = zone.def.get("boss")
		return Zone._v(b["pos"]) if b is Dictionary and b.has("pos") else Vector2.INF
	if s.begins_with("exit:"):
		for e in zone.exits:
			if String(e["target"]) == s.trim_prefix("exit:"):
				return e["pos"]
	return Vector2.INF


func _npc(id: String) -> Dictionary:
	if zone:
		for n in zone.npcs:
			if String(n["id"]) == id:
				return n
	return {}


func _position_of(who: String) -> Vector2:
	return resolve_point(who if who != "" else "player")


## Coloca a `who` en `p` (y, si camina, que mire hacia donde va).
func _place(who: String, p: Vector2, dir := Vector2.ZERO) -> void:
	if who == "player" or who == "":
		if player:
			player.global_position = p
		return
	var npc := _npc(who.trim_prefix("npc:"))
	if npc.is_empty():
		return
	npc["position"] = [p.x, p.y]
	if absf(dir.x) > 1.0:
		npc["facing_override"] = Vector2(signf(dir.x) * 0.5, 1.0)


## Saltar la escena entera (Esc, B del mando o el botón).
func skip() -> void:
	if not visible:
		return
	_default_inputs(_index)
	_index = _steps.size()
	_black_target = 0.0
	_black = 0.0
	_next()


func _gui_input(event: InputEvent) -> void:
	var mb := event as InputEventMouseButton
	if mb and mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT:
		_advance()
		accept_event()


func _input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed(&"ui_cancel") or (event is InputEventJoypadButton and event.pressed and event.button_index == JOY_BUTTON_B):
		skip()
		get_viewport().set_input_as_handled()
	elif not _input_step.is_empty():
		return   # escribiendo: Enter y Espacio son del campo de texto
	elif event.is_action_pressed(&"ui_accept") or (event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_SPACE) \
			or (event is InputEventJoypadButton and event.pressed and event.button_index == JOY_BUTTON_A):
		_advance()
		get_viewport().set_input_as_handled()


## Click / Espacio: completa la línea que se escribe o pasa a la siguiente. Con
## una pausa mínima entre las dos cosas, para que un doble click (o machacar el
## botón) no se salte líneas sin leerlas.
func _advance() -> void:
	if not _waiting_input or not _input_step.is_empty() or _time - _last_advance < ADVANCE_COOLDOWN:
		return
	_last_advance = _time
	if _box.visible and _shown < _total:
		_shown = _total
		_text.visible_characters = -1
		return
	_stop_voice()
	_next()


# --- Dibujo de efectos ---

func _draw() -> void:
	var view := size
	if _bars > 0.0:   # bandas de cine (T129), debajo del cuadro de texto
		var h := BARS_HEIGHT * _ease(_bars)
		draw_rect(Rect2(0, 0, view.x, h), Color.BLACK)
		draw_rect(Rect2(0, view.y - h, view.x, h), Color.BLACK)
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
	# El negro no tapa la página del dinosaurio (la escena del túnel pasa de negro a dino y vuelve).
	if _black > 0.0 and not _dino:
		draw_rect(Rect2(Vector2.ZERO, view), Color(0, 0, 0, _black))


## Barras de colores desplazadas, ruido y binario: el sistema rompiéndose.
func _draw_glitch(view: Vector2) -> void:
	var glitch := Accessibility.flash(_glitch)   # con «menos destellos», mucho más suave
	var seed_value := int(_time * 24.0)
	_rng.seed = seed_value
	var bars := int(6 + 18 * glitch)
	for k in bars:
		var y := _rng.randf() * view.y
		var h := _rng.randf_range(2.0, 18.0) * glitch
		var colors := [Color(1, 0, 0.3), Color(0, 1, 0.8), Color(0.3, 0.4, 1.0), Color(1, 1, 1)]
		draw_rect(Rect2(_rng.randf_range(-80, 80), y, view.x, h), Color(colors[k % 4], 0.12 * glitch))
	var font := get_theme_default_font()
	for k in int(30 * glitch):
		draw_string(font, Vector2(_rng.randf() * view.x, _rng.randf() * view.y), "1" if _rng.randf() < 0.5 else "0",
			HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color(0.3, 1.0, 0.5, 0.5 * glitch))
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
