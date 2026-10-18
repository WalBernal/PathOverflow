extends SceneTree
## Compone y guarda assets/audio/title_theme.wav: un tema synthwave oscuro en
## La menor (Am - F - C - G) con bajo, arpegio con eco, pad y batería.
## Música de programador: suena bien, pero si tienes un compositor, sustitúyela.
##
## Uso:  Godot_v4.7.2-stable_win64_console.exe --headless --path . -s res://tools/generate_music.gd

const RATE := 22050
const BPM := 104.0
const BARS := 16
const OUT := "res://assets/audio/title_theme.wav"

const ROOTS := [57, 53, 48, 55]  # La3, Fa3, Do3, Sol3 (MIDI)
const CHORDS := [[0, 3, 7], [0, 4, 7], [0, 4, 7], [0, 4, 7]]

var buf := PackedFloat32Array()
var rng := RandomNumberGenerator.new()


func _initialize() -> void:
	rng.seed = 2024
	var beat := 60.0 / BPM
	buf.resize(int(BARS * 4 * beat * RATE))
	for bar in BARS:
		var ci := (bar / 2) % 4
		var root: int = ROOTS[ci]
		var chord: Array = CHORDS[ci]
		var t0 := bar * 4 * beat
		# Pad: el acorde entero, suave, durante todo el compás.
		for tone in chord:
			_note(t0, 4.0 * beat, root + tone, "pad", 0.045)
		# Bajo: corcheas en la fundamental, con la quinta al final.
		for e in 8:
			var n := root - 12 + (7 if e == 6 else 0)
			_note(t0 + e * beat / 2.0, beat / 2.0 * 0.85, n, "saw", 0.16 if e % 2 == 0 else 0.12)
		# Arpegio (desde el compás 3), con eco.
		if bar >= 2:
			for s in 16:
				var octave := 12 if (s / 3) % 2 == 0 else 24
				var n: int = root + chord[s % 3] + octave
				var t := t0 + s * beat / 4.0
				_note(t, beat / 4.0, n, "square", 0.05)
				_note(t + beat * 0.75, beat / 4.0, n, "square", 0.018)
		# Batería (desde el compás 5).
		if bar >= 4:
			for b in 4:
				var tb := t0 + b * beat
				if b % 2 == 0:
					_kick(tb)
				else:
					_snare(tb)
			for h in 8:
				_hat(t0 + h * beat / 2.0, 0.035 if h % 2 == 0 else 0.02)
		# Remate de la melodía en los últimos compases de cada vuelta.
		if bar % 8 == 7:
			for m in 4:
				_note(t0 + m * beat, beat * 0.9, root + 24 + [7, 5, 3, 0][m], "square", 0.04)

	var peak := 0.0
	for v in buf:
		peak = maxf(peak, absf(v))
	var data := PackedByteArray()
	data.resize(buf.size() * 2)
	for i in buf.size():
		data.encode_s16(i * 2, int(clampf(buf[i] / peak * 0.85, -1.0, 1.0) * 32767.0))
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = RATE
	stream.stereo = false
	stream.data = data
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://assets/audio"))
	stream.save_to_wav(ProjectSettings.globalize_path(OUT))
	print("Escrito %s (%.1f s)" % [OUT, buf.size() / float(RATE)])
	quit()


func _freq(midi: int) -> float:
	return 440.0 * pow(2.0, (midi - 69) / 12.0)


func _note(start: float, duration: float, midi: int, wave: String, gain: float) -> void:
	var f := _freq(midi)
	var i0 := int(start * RATE)
	var n := int(duration * RATE)
	for k in n:
		var i := i0 + k
		if i >= buf.size():
			break
		var t := float(k) / RATE
		var phase := fmod(t * f, 1.0)
		var v := 0.0
		var env := 1.0
		match wave:
			"saw":
				v = 2.0 * phase - 1.0
				env = exp(-t * 6.0) * minf(1.0, t * 400.0)
			"square":
				v = 1.0 if phase < 0.5 else -1.0
				env = exp(-t * 14.0) * minf(1.0, t * 600.0)
			"pad":
				var p2 := fmod(t * f * 1.006, 1.0)
				v = (2.0 * phase - 1.0) * 0.5 + (2.0 * p2 - 1.0) * 0.5
				env = minf(1.0, t / 0.6) * minf(1.0, (duration - t) / 0.4)
		buf[i] += v * env * gain


func _kick(start: float) -> void:
	var i0 := int(start * RATE)
	var phase := 0.0
	for k in int(0.25 * RATE):
		var i := i0 + k
		if i >= buf.size():
			break
		var t := float(k) / RATE
		phase += (45.0 + 90.0 * exp(-t * 30.0)) / RATE
		buf[i] += sin(phase * TAU) * exp(-t * 12.0) * 0.5


func _snare(start: float) -> void:
	var i0 := int(start * RATE)
	for k in int(0.18 * RATE):
		var i := i0 + k
		if i >= buf.size():
			break
		var t := float(k) / RATE
		buf[i] += (rng.randf_range(-1.0, 1.0) * 0.7 + sin(t * 190.0 * TAU) * 0.3) * exp(-t * 22.0) * 0.22


func _hat(start: float, gain: float) -> void:
	var i0 := int(start * RATE)
	var last := 0.0
	for k in int(0.04 * RATE):
		var i := i0 + k
		if i >= buf.size():
			break
		var t := float(k) / RATE
		var noise := rng.randf_range(-1.0, 1.0)
		buf[i] += (noise - last) * exp(-t * 90.0) * gain * 4.0
		last = noise
