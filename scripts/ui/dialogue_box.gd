class_name DialogueBox
extends PanelContainer
## Caja de diálogo con NPCs: retrato, nombre, texto que se escribe solo y
## opciones. Las opciones pueden depender de banderas del personaje y lanzar
## acciones (dar objetos, misiones, rellenar pociones...), que ejecuta World.
##
## Sonido mientras sale el texto:
## - Narrador: lee el texto con una voz en español del sistema (Windows/macOS/
##   Linux con speech-dispatcher), con el tono y la velocidad de cada NPC. El
##   texto avanza al ritmo de la voz.
## - Si no hay voz (o se desactiva): pitidos retro, uno cada pocas letras, con
##   el tono de cada NPC.

signal action_requested(action: Dictionary)
signal closed(npc_id: String)

const CHARS_PER_SECOND := 70.0
## Ritmo del texto mientras habla el narrador (lo corrigen los avisos de la voz).
const NARRATED_CPS := 15.0
## Distancia al borde inferior de la pantalla (deja ver el HUD).
const BOTTOM_MARGIN := 125.0
const BLIP_EVERY := 2

var character: CharacterData
var npc: Dictionary = {}
var _dialogue: Dictionary = {}
var _portrait: AppearancePreview
var _name: Label
var _text: RichTextLabel
var _options: VBoxContainer
var _blip_player: AudioStreamPlayer
var _shown := 0.0          # letras visibles (con decimales)
var _total := 0
var _cps := CHARS_PER_SECOND
var _pitch := 1.0
var _rate := 1.0
var _utterance := 0
var _narrating := false

static var _utterance_counter := 0


## ¿Hay voz en español para el narrador? (Sin pantalla, como en las pruebas, no.)
static func narrator_available() -> bool:
	if DisplayServer.get_name() == "headless":
		return false
	return not DisplayServer.tts_get_voices_for_language("es").is_empty()


static func narrator_enabled() -> bool:
	return narrator_available() and bool(GameSettings.get_value("dialogue", "narrator", true))


static func blips_enabled() -> bool:
	return bool(GameSettings.get_value("dialogue", "blips", true))


func _ready() -> void:
	add_theme_stylebox_override("panel", UiStyle.panel_style())
	theme = UiStyle.make_theme()
	visible = false
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 16)
	add_child(row)
	_portrait = AppearancePreview.new()
	_portrait.custom_minimum_size = Vector2(110, 150)
	_portrait.size_flags_vertical = Control.SIZE_SHRINK_BEGIN  # que no se estire con el texto
	row.add_child(_portrait)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 8)
	col.custom_minimum_size.x = 620
	row.add_child(col)
	_name = UiStyle.label("", 20, UiStyle.ACCENT)
	col.add_child(_name)
	_text = RichTextLabel.new()
	_text.bbcode_enabled = true
	_text.fit_content = true
	_text.custom_minimum_size = Vector2(620, 60)
	_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_text.add_theme_font_size_override("normal_font_size", 16)
	col.add_child(_text)
	_options = VBoxContainer.new()
	_options.add_theme_constant_override("separation", 4)
	col.add_child(_options)

	_blip_player = AudioStreamPlayer.new()
	_blip_player.stream = RetroSfx.blip()
	_blip_player.volume_db = -12.0
	_blip_player.max_polyphony = 2
	add_child(_blip_player)
	if narrator_available():
		DisplayServer.tts_set_utterance_callback(DisplayServer.TTS_UTTERANCE_BOUNDARY,
			func(pos: int, id: int) -> void: _on_voice_boundary.call_deferred(pos, id))
		DisplayServer.tts_set_utterance_callback(DisplayServer.TTS_UTTERANCE_ENDED,
			func(id: int) -> void: _on_voice_ended.call_deferred(id))


func open(p_npc: Dictionary, dialogue: Dictionary) -> void:
	npc = p_npc
	_dialogue = dialogue
	_portrait.appearance = CharacterAppearance.sanitize(npc.get("appearance", {}))
	_name.text = npc.get("name", "?")
	var voice: Dictionary = npc.get("voice", {})
	# Sin voz definida, un tono estable sacado del id del NPC.
	_pitch = float(voice.get("pitch", 0.8 + float(hash(npc.get("id", "")) % 60) / 100.0))
	_rate = float(voice.get("rate", 1.0))
	visible = true
	_portrait.queue_redraw.call_deferred()  # estaba oculto: forzar el dibujo
	_show_node(dialogue.get("start", ""))


func close() -> void:
	if not visible:
		return
	_stop_voice()
	visible = false
	closed.emit(npc.get("id", ""))
	npc = {}


func is_typing() -> bool:
	return _shown < _total


func _show_node(node_id: String) -> void:
	var nodes: Dictionary = _dialogue.get("nodes", {})
	if node_id == "" or not nodes.has(node_id):
		close()
		return
	var node: Dictionary = nodes[node_id]
	_text.text = node.get("text", "")
	_total = _text.get_total_character_count()
	_shown = 0.0
	_text.visible_characters = 0
	_stop_voice()
	_narrating = narrator_enabled()
	if _narrating:
		_utterance_counter += 1
		_utterance = _utterance_counter
		var voices := DisplayServer.tts_get_voices_for_language("es")
		# Tono de Godot: 0..2 (1 = normal); velocidad: 0.1..10.
		DisplayServer.tts_speak(_text.get_parsed_text(), voices[0], 80, clampf(_pitch, 0.0, 2.0),
			clampf(_rate * 1.1, 0.5, 2.0), _utterance, true)
		_cps = NARRATED_CPS * _rate
	else:
		_cps = CHARS_PER_SECOND

	for c in _options.get_children():
		_options.remove_child(c)
		c.queue_free()
	var n := 0
	for option in node.get("options", []):
		if option.has("requires_flag") and not character.flags.has(option["requires_flag"]):
			continue
		if option.has("hides_if_flag") and character.flags.has(option["hides_if_flag"]):
			continue
		n += 1
		var b := Button.new()
		b.text = "%d. %s" % [n, option["text"]]
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.focus_mode = Control.FOCUS_NONE
		b.pressed.connect(_choose.bind(option))
		_options.add_child(b)
	_reposition.call_deferred()


func _process(delta: float) -> void:
	if not visible or _shown >= _total:
		return
	var before := int(_shown)
	_shown = minf(_total, _shown + _cps * delta)
	_reveal(before)


## Muestra las letras nuevas y, sin narrador, pita cada pocas.
func _reveal(before: int) -> void:
	var now := int(_shown)
	_text.visible_characters = now if now < _total else -1
	if _narrating or not blips_enabled() or now == before:
		return
	var parsed := _text.get_parsed_text()
	for i in range(before, now):
		if i % BLIP_EVERY == 0 and i < parsed.length() and parsed[i] != " ":
			_blip_player.pitch_scale = _pitch * randf_range(0.93, 1.07)
			_blip_player.play()
			break


func _on_voice_boundary(pos: int, id: int) -> void:
	if id != _utterance or not visible:
		return
	# La voz va por delante: el texto la alcanza (mostrando la palabra entera).
	var parsed := _text.get_parsed_text()
	var word_end := pos
	while word_end < parsed.length() and parsed[word_end] != " ":
		word_end += 1
	if word_end > _shown:
		var before := int(_shown)
		_shown = float(word_end)
		_reveal(before)


func _on_voice_ended(id: int) -> void:
	if id == _utterance and visible:
		_finish_text()


func _finish_text() -> void:
	_shown = _total
	_text.visible_characters = -1


func _stop_voice() -> void:
	if _narrating:
		DisplayServer.tts_stop()
		_narrating = false


## Centrada abajo, por encima del HUD (se recalcula porque la altura cambia con el texto).
func _reposition() -> void:
	reset_size()
	var view := get_viewport_rect().size
	position = Vector2((view.x - size.x) / 2.0, view.y - BOTTOM_MARGIN - size.y)


func _choose(option: Dictionary) -> void:
	# Un click mientras se escribe el texto lo completa primero (la voz sigue).
	if is_typing():
		_finish_text()
		return
	if option.has("action"):
		action_requested.emit(option["action"])
	_show_node(option.get("next", ""))
