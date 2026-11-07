class_name PlayerLines
## Frases de combate con la voz del personaje (T223): grabadas una vez con la voz del
## egresado o la egresada (la «Voz» del creador) y guardadas en audio/voces como
## jugador_<momento>_<n>_<m|f>.ogg. Sustituyen al murmullo sintetizado (Barks) del
## jugador; si falta el audio o los murmullos están apagados, no suenan (y quien llama
## puede usar Barks). Nunca la misma frase dos veces seguidas y con pausas mínimas.

## Momento → frases (el texto solo sirve para generarlas: tools/voces).
const LINES := {
	"level": ["¡Compila!", "¡Nueva versión desplegada!", "Subí de nivel... y sin romper nada."],
	"death": ["Segfault...", "Kernel panic...", "Se cayó producción..."],
	"flask": ["Un refresquito...", "Limpiando la caché.", "Reiniciando el servicio."],
	"low_life": ["Esto huele a rollback...", "¡Necesito un hotfix!", "Integridad crítica..."],
	"no_mana": ["Necesito más RAM.", "Sin memoria...", "Out of memory..."],
}
## Segundos mínimos entre dos frases del mismo momento (los que se repiten mucho).
const MOMENT_GAP := {"flask": 8.0, "no_mana": 10.0, "low_life": 20.0}
## Y entre dos frases cualquiera (subir de nivel y morir no esperan).
const MIN_GAP := 4.0
const ALWAYS := ["level", "death"]

static var _player: AudioStreamPlayer
static var _last_index := {}
static var _last_time := {}
static var _last_any := -999.0


static func id_for(moment: String, index: int, voice: int) -> String:
	return "jugador_%s_%d_%s" % [moment, index, "f" if voice == 1 else "m"]


## ¿Puede sonar ya una frase de `moment` en el instante `now` (s)? Sin efectos.
static func allowed(moment: String, now: float, last_time: Dictionary, last_any: float) -> bool:
	if moment in ALWAYS:
		return true
	if now - last_any < MIN_GAP:
		return false
	return now - float(last_time.get(moment, -999.0)) >= float(MOMENT_GAP.get(moment, 0.0))


## Cuál de las `count` frases toca: al azar, pero nunca la misma que `last`.
static func pick(count: int, last: int, rng: RandomNumberGenerator) -> int:
	if count <= 1:
		return 0
	if last < 0 or last >= count:
		return rng.randi_range(0, count - 1)
	var i := rng.randi_range(0, count - 2)
	return i + 1 if i >= last else i


## Dice una frase de `moment` con la voz `voice`. Devuelve si sonó.
static func play(moment: String, voice: int) -> bool:
	var lines: Array = LINES.get(moment, [])
	var volume := Sfx.sfx_volume() * DialogueBox.voice_volume()
	if lines.is_empty() or not Barks.enabled() or volume <= 0.001:
		return false
	var now := Time.get_ticks_msec() / 1000.0
	if not allowed(moment, now, _last_time, _last_any):
		return true   # calla a propósito: que no suene tampoco el murmullo
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	var i := pick(lines.size(), int(_last_index.get(moment, -1)), rng)
	var id := id_for(moment, i, voice)
	if not VoiceLines.has_line(id):
		return false
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null or tree.root == null:
		return false
	if _player == null or not is_instance_valid(_player):
		_player = AudioStreamPlayer.new()
		_player.process_mode = Node.PROCESS_MODE_ALWAYS
		tree.root.add_child(_player)
	_player.stream = load(VoiceLines.path_for(id))
	_player.volume_db = linear_to_db(volume)
	_player.play()
	_last_index[moment] = i
	_last_time[moment] = now
	_last_any = now
	return true
