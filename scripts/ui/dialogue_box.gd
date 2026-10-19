class_name DialogueBox
extends PanelContainer
## Caja de diálogo con NPCs: retrato animado en medallón, nombre, texto que se
## escribe solo y opciones. Las opciones pueden depender de banderas del
## personaje y lanzar acciones (dar objetos, misiones, rellenar pociones...),
## que ejecuta World.
##
## La conversación fluye sin repetirse:
## - Volver al nodo inicial en la misma charla muestra una frase corta del NPC
##   ("menu" del diálogo) en vez del saludo entero.
## - Un nodo ya leído en otra visita muestra su texto "again" (si lo tiene).
## - Las opciones que llevan a temas ya leídos salen marcadas (✓) y al final;
##   las de misiones (★), primero.
## - Un nodo con "next" y sin opciones encadena con un botón "Continuar".
## - Las opciones aparecen cuando termina el texto. Teclas 1-9: elegir;
##   Espacio / Intro: completar el texto o seguir si solo hay una opción.
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
## Ritmo del texto mientras habla el narrador.
const NARRATED_CPS := 15.0
## Distancia al borde inferior de la pantalla (deja ver el HUD).
const BOTTOM_MARGIN := 125.0
const BLIP_EVERY := 2
const DEFAULT_MENU := ["¿Algo más?", "¿Qué más quieres saber?", "Te escucho."]
const READ_COLOR := Color("7a7284")
const QUEST_COLOR := Color("ffd84a")

var character: CharacterData
var npc: Dictionary = {}
var _dialogue: Dictionary = {}
var _dialogue_id := ""
var _node_id := ""
var _visited_now := {}
var _portrait: CharacterPortrait
var _name: Label
var _text: RichTextLabel
var _options: VBoxContainer
var _blip_player: AudioStreamPlayer
var _shown := 0.0          # letras visibles (con decimales)
var _total := 0
var _cps := CHARS_PER_SECOND
var _pitch := 1.0
var _rate := 1.0
var _narrating := false
var _choices: Array[Dictionary] = []
var _rng := RandomNumberGenerator.new()

static var _voice_cache: Variant = null
## Cuánto tarda la voz en empezar (antes de eso tts_is_speaking puede dar false).
const VOICE_GRACE := 0.6
var _voice_age := 0.0


## ¿Hay voz en español para el narrador? (Sin pantalla, como en las pruebas, no.)
static func narrator_available() -> bool:
	return voice_id() != ""


## Voz en español del sistema (se busca una sola vez: enumerarlas es lento).
static func voice_id() -> String:
	if _voice_cache == null:
		_voice_cache = ""
		if DisplayServer.get_name() != "headless":
			var voices := DisplayServer.tts_get_voices_for_language("es")
			if not voices.is_empty():
				_voice_cache = voices[0]
	return _voice_cache


## Habla. En Windows la voz va en un proceso aparte (NarratorVoice): corta la
## frase anterior y se puede callar sin riesgo. En otros sistemas se usa la voz
## de Godot, pero sin cortarla nunca (tts_stop() con SAPI colgaba el juego): si
## sigue hablando, devuelve false y esa línea va sin voz.
static func speak(text: String, pitch: float, rate: float) -> bool:
	if NarratorVoice.supported():
		FreezeWatch.mark("voz: hablar (%d letras)" % text.length())
		return NarratorVoice.speak(text, pitch, rate)
	if voice_id() == "" or DisplayServer.tts_is_speaking():
		return false
	FreezeWatch.mark("voz: hablar (%d letras)" % text.length())
	DisplayServer.tts_speak(text, voice_id(), 80, clampf(pitch, 0.0, 2.0), clampf(rate * 1.1, 0.5, 2.0))
	return true


## Calla la voz (solo con el ayudante; la de Godot termina sola su frase).
static func stop_speaking() -> void:
	if NarratorVoice.supported():
		NarratorVoice.stop()


## ¿Sigue hablando el narrador?
static func voice_busy() -> bool:
	if NarratorVoice.supported():
		return NarratorVoice.is_speaking()
	return voice_id() != "" and DisplayServer.tts_is_speaking()

static func narrator_enabled() -> bool:
	return narrator_available() and bool(GameSettings.get_value("dialogue", "narrator", true))


static func blips_enabled() -> bool:
	return bool(GameSettings.get_value("dialogue", "blips", true))


func _ready() -> void:
	_rng.randomize()
	add_theme_stylebox_override("panel", UiStyle.window_style())
	UiStyle.decorate_window(self)
	theme = UiStyle.make_theme()
	visible = false
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 18)
	add_child(row)
	_portrait = CharacterPortrait.new()
	_portrait.custom_minimum_size = Vector2(136, 136)
	_portrait.size_flags_vertical = Control.SIZE_SHRINK_BEGIN  # que no se estire con el texto
	row.add_child(_portrait)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 8)
	col.custom_minimum_size.x = 640
	row.add_child(col)
	_name = UiStyle.label("", 21, UiStyle.ACCENT)
	_name.add_theme_constant_override("outline_size", 4)
	_name.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.8))
	col.add_child(_name)
	_text = RichTextLabel.new()
	_text.bbcode_enabled = true
	_text.fit_content = true
	_text.custom_minimum_size = Vector2(640, 56)
	_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_text.add_theme_font_size_override("normal_font_size", 17)
	_text.add_theme_constant_override("line_separation", 3)
	_text.mouse_filter = Control.MOUSE_FILTER_PASS
	col.add_child(_text)
	_options = VBoxContainer.new()
	_options.add_theme_constant_override("separation", 4)
	col.add_child(_options)

	_blip_player = AudioStreamPlayer.new()
	_blip_player.stream = RetroSfx.blip()
	_blip_player.volume_db = -12.0
	_blip_player.max_polyphony = 2
	add_child(_blip_player)


func open(p_npc: Dictionary, dialogue: Dictionary) -> void:
	npc = p_npc
	_dialogue = dialogue
	_dialogue_id = String(npc.get("dialogue", npc.get("id", "")))
	_visited_now = {}
	_portrait.appearance = CharacterAppearance.sanitize(npc.get("appearance", {}))
	_portrait.ring_color = Color(npc.get("color", "d9a441"))
	_portrait.glitch = 0.6 if npc.get("terminal", false) else 0.0
	_name.text = npc.get("name", "?")
	var voice: Dictionary = npc.get("voice", {})
	# Sin voz definida, un tono estable sacado del id del NPC.
	_pitch = float(voice.get("pitch", 0.8 + float(hash(npc.get("id", "")) % 60) / 100.0))
	_rate = float(voice.get("rate", 1.0))
	visible = true
	_portrait.queue_redraw.call_deferred()  # estaba oculto: forzar el dibujo
	FreezeWatch.mark("diálogo: abrir " + String(npc.get("id", "")))
	_show_node(dialogue.get("start", ""))


func close() -> void:
	if not visible:
		return
	FreezeWatch.mark("diálogo: cerrar")
	_stop_voice()
	visible = false
	closed.emit(npc.get("id", ""))
	npc = {}


func is_typing() -> bool:
	return _shown < _total


# --- Memoria de lo leído ---

func _seen_nodes() -> Dictionary:
	if character == null:
		return {}
	var all: Dictionary = character.flags.get("dialogue_seen", {})
	if not character.flags.has("dialogue_seen"):
		character.flags["dialogue_seen"] = all
	if not all.has(_dialogue_id):
		all[_dialogue_id] = {}
	return all[_dialogue_id]


func was_seen(node_id: String) -> bool:
	return _seen_nodes().has(node_id)


func _pick(value: Variant) -> String:
	if value is Array and not value.is_empty():
		return String(value[_rng.randi_range(0, value.size() - 1)])
	return String(value)


## Texto del nodo según si ya se leyó (en esta charla o en otra).
func _text_for(node_id: String, node: Dictionary) -> String:
	var start: String = _dialogue.get("start", "")
	if node_id == start and _visited_now.has(start):
		return _pick(_dialogue.get("menu", DEFAULT_MENU))
	if was_seen(node_id):
		if node.has("again"):
			return _pick(node["again"])
		if node_id == start and _dialogue.has("menu"):
			return _pick(_dialogue.get("greeting_again", _dialogue["menu"]))
	return String(node.get("text", ""))


func _show_node(node_id: String) -> void:
	var nodes: Dictionary = _dialogue.get("nodes", {})
	if node_id == "" or not nodes.has(node_id):
		close()
		return
	var node: Dictionary = nodes[node_id]
	_node_id = node_id
	_text.text = _text_for(node_id, node)
	_visited_now[node_id] = true
	_seen_nodes()[node_id] = true
	_total = _text.get_total_character_count()
	_shown = 0.0
	_text.visible_characters = 0
	_stop_voice()
	_narrating = narrator_enabled() and speak(_text.get_parsed_text(), _pitch, _rate)
	if _narrating:
		_voice_age = 0.0
		_cps = NARRATED_CPS * _rate
	else:
		_cps = CHARS_PER_SECOND
	_build_options(node)
	_reposition.call_deferred()


func _build_options(node: Dictionary) -> void:
	for c in _options.get_children():
		_options.remove_child(c)
		c.queue_free()
	_choices.clear()
	var start: String = _dialogue.get("start", "")
	var raw: Array = node.get("options", [])
	if raw.is_empty() and node.has("next"):
		raw = [{"text": node.get("continue", "Continuar"), "next": node["next"]}]
	for option in raw:
		if option.has("requires_flag") and not character.flags.has(option["requires_flag"]):
			continue
		if option.has("hides_if_flag") and character.flags.has(option["hides_if_flag"]):
			continue
		var next: String = option.get("next", "")
		var quest: bool = next.begins_with("mision_") or String(option.get("action", {}).get("type", "")).ends_with("quest")
		var read: bool = next != "" and next != start and was_seen(next) and not quest
		var leaves: bool = next == "" and not option.has("action")
		# Orden: misiones, temas nuevos, temas ya leídos, despedidas.
		var rank := 0 if quest else (3 if leaves else (2 if read else 1))
		_choices.append({"option": option, "read": read, "quest": quest, "rank": rank})
	_choices.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a["rank"] < b["rank"])
	for i in _choices.size():
		var choice: Dictionary = _choices[i]
		var b := Button.new()
		var prefix := "★ " if choice["quest"] else ("✓ " if choice["read"] else "")
		b.text = "%d.  %s%s" % [i + 1, prefix, choice["option"]["text"]]
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.focus_mode = Control.FOCUS_NONE
		if choice["quest"]:
			b.add_theme_color_override("font_color", QUEST_COLOR)
		elif choice["read"]:
			b.add_theme_color_override("font_color", READ_COLOR)
			b.tooltip_text = "Ya lo hablaron."
		b.pressed.connect(_choose.bind(choice["option"]))
		_options.add_child(b)
	_options.modulate.a = 0.0
	_options.visible = false


## Las opciones aparecen (con un fundido escalonado) cuando acaba el texto.
func _show_options() -> void:
	if _options.visible:
		return
	_options.visible = true
	_options.modulate.a = 1.0
	var k := 0
	for b in _options.get_children():
		(b as Control).modulate.a = 0.0
		var tween := create_tween()
		tween.tween_interval(0.05 * k)
		tween.tween_property(b, "modulate:a", 1.0, 0.18)
		k += 1
	_reposition.call_deferred()


func _process(delta: float) -> void:
	if not visible:
		return
	_portrait.talking = is_typing() or (_narrating and voice_busy())
	if _shown >= _total:
		_show_options()
		return
	if _narrating:
		_voice_age += delta
		if _voice_age > VOICE_GRACE and not voice_busy():
			_narrating = false   # la voz terminó: el texto la alcanza de golpe
			_finish_text()
			return
	var before := int(_shown)
	_shown = minf(_total, _shown + _cps * delta)
	_reveal(before)


func _gui_input(event: InputEvent) -> void:
	var mb := event as InputEventMouseButton
	if mb and mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT and is_typing():
		_finish_text()
		accept_event()


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	var key := event as InputEventKey
	if key == null or not key.pressed or key.echo:
		return
	if key.keycode == KEY_SPACE or key.keycode == KEY_ENTER or key.keycode == KEY_KP_ENTER:
		if is_typing():
			_finish_text()
		elif _choices.size() == 1:
			_choose(_choices[0]["option"])
		get_viewport().set_input_as_handled()
		return
	var n := key.keycode - KEY_1
	if n >= 0 and n < 9:
		# Mientras se habla, los números eligen opción (no beben pociones).
		if not is_typing() and n < _choices.size():
			_choose(_choices[n]["option"])
		get_viewport().set_input_as_handled()


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


func _finish_text() -> void:
	_shown = _total
	_text.visible_characters = -1
	_show_options()


func _stop_voice() -> void:
	if _narrating:
		stop_speaking()
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
