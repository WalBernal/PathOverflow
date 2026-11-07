class_name VoiceLines
## Diálogos grabados: audio generado una vez en el PC (tools/voces, Qwen3-TTS, ver
## docs/voces.md) y guardado en audio/voces/<id>.ogg. Si una línea tiene su audio,
## suena ese en vez de la voz del sistema; si no, todo sigue como antes (voz de
## Windows/Android o pitidos). En el celular solo es reproducir un .ogg corto.
##
## Ids: en las escenas, "<escena>_<nº de paso con dos cifras>" (prologo_rafa_02); las
## líneas del jugador llevan además "_m" o "_f" según la voz elegida en el creador.

const DIR := "res://audio/voces/"

static var _player: AudioStreamPlayer


## Id de la línea `index` de la escena `scene`. `player_voice`: -1 si no habla el
## jugador; si no, su voz (CharacterAppearance.VOICE_NAMES: 0 masculina, 1 femenina).
static func cutscene_id(scene: String, index: int, player_voice := -1) -> String:
	var id := "%s_%02d" % [scene, index]
	if player_voice >= 0:
		id += "_f" if player_voice == 1 else "_m"
	return id


## Id de una línea de los diálogos de NPC (npcs.json → dialogues): `part` es el id del
## nodo (su texto), "<nodo>_tactil" (su versión para el dedo), "<nodo>_otra" (sus textos
## al releerlo), "_menu" o "_saludo" (las frases del menú y de bienvenida al volver);
## `index`, cuál de la lista. No cambia si se añaden otros NPC o nodos.
static func npc_id(dialogue: String, part: String, index := -1) -> String:
	var id := "npc_%s_%s" % [dialogue, part]
	if index >= 0:
		id += "_%d" % index
	return id


static func path_for(id: String) -> String:
	return DIR + id + ".ogg"


static func has_line(id: String) -> bool:
	return id != "" and ResourceLoader.exists(path_for(id))


## Mismo interruptor que el narrador (Pausa → Diálogos), pero sin depender de que el
## sistema tenga una voz en español: el audio grabado suena en cualquier dispositivo.
static func enabled() -> bool:
	return bool(GameSettings.get_value("dialogue", "narrator", true))


## Hace sonar la línea (cortando la anterior). Devuelve su duración en segundos, o 0.0
## si no tiene audio, las voces están apagadas o no hay dónde sonar.
static func play(id: String) -> float:
	if not enabled() or not has_line(id):
		return 0.0
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null or tree.root == null:
		return 0.0
	var stream := load(path_for(id)) as AudioStream
	if stream == null:
		return 0.0
	if _player == null or not is_instance_valid(_player):
		_player = AudioStreamPlayer.new()
		_player.process_mode = Node.PROCESS_MODE_ALWAYS
		tree.root.add_child(_player)
	_player.stop()
	_player.stream = stream
	var volume := DialogueBox.voice_volume()
	_player.volume_db = linear_to_db(maxf(volume, 0.0001))
	_player.play()
	return stream.get_length()


static func stop() -> void:
	if _player and is_instance_valid(_player):
		_player.stop()


static func is_playing() -> bool:
	return _player != null and is_instance_valid(_player) and _player.playing
