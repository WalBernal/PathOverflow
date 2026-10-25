class_name Barks
## Voces cortas: murmullos de dos o tres sílabas sin palabras (como en los juegos
## de los 90) para los PNJ al empezar a hablar y para el personaje al subir de
## nivel o al quedarse con poca vida. Se sintetizan al vuelo (pulsos glotales por
## dos formantes de vocal) y se guardan; el tono de cada uno lo pone pitch_scale.
## Se apagan en Pausa → Diálogos (dialogue/barks).

const MIX_RATE := 22050
## Frecuencia base de la voz (Hz) antes del tono de cada personaje.
const BASE_F0 := 150.0
## Formantes (F1, F2) de cada vocal.
const VOWELS := {"a": [800.0, 1200.0], "e": [450.0, 1900.0], "i": [300.0, 2300.0], "o": [500.0, 900.0], "u": [330.0, 800.0], "m": [250.0, 1100.0]}
## Cada tipo: sílabas [vocal, duración (s), tono al empezar, tono al acabar].
const KINDS := {
	"greet": [["e", 0.09, 1.0, 1.1], ["o", 0.16, 1.15, 0.95]],          # «¡eo!»
	"talk": [["a", 0.08, 1.0, 1.0], ["e", 0.07, 1.05, 0.95], ["o", 0.12, 0.95, 0.85]],
	"question": [["e", 0.08, 0.95, 1.0], ["i", 0.16, 1.05, 1.35]],      # sube
	"exclaim": [["a", 0.18, 1.3, 0.9]],                                  # «¡ah!»
	"hmm": [["m", 0.3, 1.0, 0.92]],
	"level": [["e", 0.07, 1.1, 1.2], ["i", 0.1, 1.25, 1.4], ["a", 0.2, 1.45, 1.3]],   # celebración
	"hurt": [["u", 0.22, 1.05, 0.7]],                                    # quejido
}

static var _cache: Dictionary = {}


static func enabled() -> bool:
	return bool(GameSettings.get_value("dialogue", "barks", true))


## Tipo de murmullo para lo que dice un PNJ: pregunta, exclamación o charla; el
## primero de la conversación, un saludo.
static func kind_for(text: String, first: bool) -> String:
	var t := text.strip_edges()
	if first:
		return "greet"
	if t.ends_with("?"):
		return "question"
	if t.ends_with("!"):
		return "exclaim"
	if t.ends_with("...") or t.ends_with("…"):
		return "hmm"
	return "talk"


static func stream(kind: String) -> AudioStreamWAV:
	if not _cache.has(kind):
		_cache[kind] = _synth(KINDS.get(kind, KINDS["talk"]))
	return _cache[kind]


## Suena un murmullo con el tono `pitch` (1 = voz media).
static func play(kind: String, pitch := 1.0, volume_db := -6.0) -> void:
	var volume := Sfx.sfx_volume() * DialogueBox.voice_volume()
	if not enabled() or volume <= 0.001:
		return
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null or tree.root == null:
		return
	var p := AudioStreamPlayer.new()
	p.stream = stream(kind)
	p.pitch_scale = clampf(pitch, 0.5, 2.0) * randf_range(0.97, 1.03)
	p.volume_db = volume_db + linear_to_db(volume)
	p.process_mode = Node.PROCESS_MODE_ALWAYS
	tree.root.add_child(p)
	p.finished.connect(p.queue_free)
	p.play()


static func _synth(syllables: Array) -> AudioStreamWAV:
	var samples := PackedFloat32Array()
	var phase := 0.0
	for syl in syllables:
		var f: Array = VOWELS[syl[0]]
		var n := int(float(syl[1]) * MIX_RATE)
		var y1 := [0.0, 0.0]
		var y2 := [0.0, 0.0]
		for i in n:
			var t := float(i) / n
			var f0 := BASE_F0 * lerpf(float(syl[2]), float(syl[3]), t) * (1.0 + 0.015 * sin(TAU * 6.0 * i / MIX_RATE))   # algo de vibrato
			phase = fmod(phase + f0 / MIX_RATE, 1.0)
			var source := (1.0 - 2.0 * phase) * 0.6 + randf_range(-0.05, 0.05)   # diente de sierra con aire
			var out := 0.0
			for k in 2:   # dos resonadores (formantes)
				var r := 0.97 if k == 0 else 0.95
				var w := TAU * float(f[k]) / MIX_RATE
				var y: float = source * (1.0 - r) + 2.0 * r * cos(w) * y1[k] - r * r * y2[k]
				y2[k] = y1[k]
				y1[k] = y
				out += y * (1.0 if k == 0 else 0.6)
			var env := minf(1.0, t * 12.0) * minf(1.0, (1.0 - t) * 6.0)
			samples.append(out * env)
		for i in int(0.025 * MIX_RATE):   # pausita entre sílabas
			samples.append(0.0)
	var peak := 0.001
	for s in samples:
		peak = maxf(peak, absf(s))
	var data := PackedByteArray()
	data.resize(samples.size() * 2)
	for i in samples.size():
		data.encode_s16(i * 2, int(clampf(samples[i] / peak, -1.0, 1.0) * 22000.0))
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = MIX_RATE
	wav.stereo = false
	wav.data = data
	return wav
