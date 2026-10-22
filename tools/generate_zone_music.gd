extends SceneTree
## Compone la música de las zonas y los jefes a partir de data/music.json y la
## guarda en assets/audio/music/<id>.wav (mono, bucle sin costuras). Es música de
## programador, con sonido retro: si tienes un compositor, sustituye los .wav.
##
## Uso:  Godot_v4.7.2-stable_win64_console.exe --headless --path . -s res://tools/generate_zone_music.gd [-- id1 id2]

const RATE := 16000
const OUT_DIR := "res://assets/audio/music/"
const SCALES := {
	"major": [0, 2, 4, 5, 7, 9, 11], "minor": [0, 2, 3, 5, 7, 8, 10], "dorian": [0, 2, 3, 5, 7, 9, 10],
	"phrygian": [0, 1, 3, 5, 7, 8, 10], "lydian": [0, 2, 4, 6, 7, 9, 11],
}
const QUALITIES := {
	"M": [0, 4, 7], "m": [0, 3, 7], "M7": [0, 4, 7, 11], "m7": [0, 3, 7, 10], "sus": [0, 5, 7], "dim": [0, 3, 6],
}
## Ritmos de la melodía (duraciones en tiempos; un valor negativo es silencio).
const RHYTHMS := [
	[2.0, 2.0], [1.0, 1.0, 2.0], [1.5, 0.5, 2.0], [1.0, 1.0, 1.0, 1.0], [3.0, 1.0], [0.5, 0.5, 1.0, 2.0],
	[-1.0, 1.0, 2.0], [2.0, 1.0, 1.0], [1.0, 0.5, 0.5, 2.0], [4.0],
]

var buf := PackedFloat32Array()
var rng := RandomNumberGenerator.new()


func _initialize() -> void:
	var f := FileAccess.open("res://data/music.json", FileAccess.READ)
	var data: Dictionary = JSON.parse_string(f.get_as_text())
	var only: PackedStringArray = OS.get_cmdline_user_args()
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT_DIR))
	for id in data["tracks"]:
		if not only.is_empty() and not (id in only):
			continue
		_compose(id, data["tracks"][id])
	quit()


func _compose(id: String, t: Dictionary) -> void:
	rng.seed = int(t.get("seed", 1))
	var bpm := float(t["bpm"])
	var beat := 60.0 / bpm
	var bars := int(t["bars"])
	var chord_bars := int(t.get("chord_bars", 1))
	var root := int(t["root"])
	var scale: Array = SCALES[t.get("scale", "minor")]
	var prog: Array = t["prog"]
	var from: Dictionary = t.get("from", {})
	buf.clear()
	buf.resize(int(bars * 4 * beat * RATE))
	var mel_idx := 7  # grado actual de la melodía (índice sobre la escala extendida)
	for bar in bars:
		var spec: Array = prog[(bar / chord_bars) % prog.size()]
		var croot: int = root + int(spec[0])
		var tones: Array = QUALITIES[spec[1]]
		var t0 := bar * 4 * beat
		var pad_gain := float(t.get("pad", 0.04))
		if pad_gain > 0.0:
			for tone in tones:
				_note(t0, 4.0 * beat, croot + int(tone), "pad", pad_gain * 0.9)
		_bass(t0, beat, croot, String(t.get("bass", "root")))
		if bar >= int(from.get("arp", 0)):
			_arp(t0, beat, croot, tones, String(t.get("arp", "none")), String(t.get("arp_wave", "square")))
		if bar >= int(from.get("drums", 0)):
			_drums(t0, beat, String(t.get("drums", "none")), bar)
		if bar >= int(from.get("lead", 0)) and String(t.get("lead", "none")) != "none":
			mel_idx = _melody(t0, beat, croot, tones, root, scale, mel_idx, String(t["lead"]))
	var peak := 0.0001
	for v in buf:
		peak = maxf(peak, absf(v))
	var bytes := PackedByteArray()
	bytes.resize(buf.size() * 2)
	for i in buf.size():
		bytes.encode_s16(i * 2, int(clampf(buf[i] / peak * 0.8, -1.0, 1.0) * 32767.0))
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = RATE
	stream.stereo = false
	stream.data = bytes
	stream.save_to_wav(ProjectSettings.globalize_path(OUT_DIR + id + ".wav"))
	print("Escrito %s%s.wav (%.1f s)" % [OUT_DIR, id, buf.size() / float(RATE)])


func _bass(t0: float, beat: float, croot: int, kind: String) -> void:
	var low := croot - 12
	match kind:
		"root":
			_note(t0, 2.0 * beat, low, "tri", 0.2)
			_note(t0 + 2.0 * beat, 2.0 * beat * 0.9, low, "tri", 0.16)
		"walk":
			for q in 4:
				_note(t0 + q * beat, beat * 0.9, low + [0, 7, 12, 7][q], "saw", 0.12)
		"eighth":
			for e in 8:
				_note(t0 + e * beat / 2.0, beat / 2.0 * 0.85, low + (7 if e == 6 else 0), "saw", 0.15 if e % 2 == 0 else 0.1)
		"pulse":
			for e in 8:
				var n := low + (12 if e % 4 == 3 else 0)
				_note(t0 + e * beat / 2.0, beat / 2.0 * 0.7, n, "saw", 0.17 if e % 2 == 0 else 0.12)


func _arp(t0: float, beat: float, croot: int, tones: Array, kind: String, wave: String) -> void:
	var n := tones.size()
	match kind:
		"up":
			for s in 16:
				var octave := 12 if (s / 3) % 2 == 0 else 24
				var m: int = croot + int(tones[s % n]) + octave
				var tt := t0 + s * beat / 4.0
				_note(tt, beat / 4.0, m, wave, 0.045)
				_note(tt + beat * 0.75, beat / 4.0, m, wave, 0.016)
		"broken":
			for e in 8:
				var m: int = croot + int(tones[[0, 2, 1, 2][e % 4] % n]) + 12 + (12 if e >= 4 else 0)
				_note(t0 + e * beat / 2.0, beat * 1.2, m, wave, 0.07)
		"ballad":
			var shape := [0, 2, 3, 4, 3, 2, 4, 2]
			var steps := [0, int(tones[1]), int(tones[2]), 12, 12 + int(tones[1])]
			for e in 8:
				var m: int = croot + int(steps[shape[e]])
				_note(t0 + e * beat / 2.0, beat * 1.6, m, wave, 0.075 if e % 2 == 0 else 0.055)


func _drums(t0: float, beat: float, kind: String, bar: int) -> void:
	match kind:
		"soft":
			_kick(t0, 0.3)
			_kick(t0 + 2.0 * beat, 0.22)
			for h in 4:
				_hat(t0 + (h * 2 + 1) * beat / 2.0, 0.018)
		"ballad":
			_kick(t0, 0.32)
			_kick(t0 + 2.5 * beat, 0.2)
			_snare(t0 + 2.0 * beat, 0.45)
			if bar % 2 == 1:
				_snare(t0 + 3.5 * beat, 0.2)
			for h in 8:
				_hat(t0 + h * beat / 2.0, 0.012 if h % 2 == 0 else 0.008)
		"drive":
			for b in 4:
				if b % 2 == 0:
					_kick(t0 + b * beat, 0.5)
				else:
					_snare(t0 + b * beat, 1.0)
			for h in 8:
				_hat(t0 + h * beat / 2.0, 0.035 if h % 2 == 0 else 0.02)
		"boss":
			for b in 4:
				_kick(t0 + b * beat, 0.55)
				if b % 2 == 1:
					_snare(t0 + b * beat, 1.1)
				else:
					_kick(t0 + (b + 0.5) * beat, 0.3)
			for h in 16:
				_hat(t0 + h * beat / 4.0, 0.03 if h % 4 == 0 else 0.016)


## Compone un compás de melodía; devuelve el último grado usado.
func _melody(t0: float, beat: float, croot: int, tones: Array, root: int, scale: Array, idx: int, lead: String) -> int:
	var rhythm: Array = RHYTHMS[rng.randi() % RHYTHMS.size()]
	var pos := 0.0
	var first := true
	for d in rhythm:
		var dur := absf(float(d))
		if d > 0.0:
			if first:
				idx = _nearest_chord_degree(idx, croot, tones, root, scale)
			else:
				var step: int = [-2, -1, -1, 1, 1, 2][rng.randi() % 6]
				idx = clampi(idx + step, 3, 13)
			_note(t0 + pos * beat, dur * beat * 0.95, _degree_midi(idx, root, scale) + 12, lead, 0.075)
			first = false
		pos += dur
	return idx


func _degree_midi(idx: int, root: int, scale: Array) -> int:
	return root + 12 * (idx / scale.size()) + int(scale[idx % scale.size()])


func _nearest_chord_degree(idx: int, croot: int, tones: Array, root: int, scale: Array) -> int:
	var best := idx
	var best_d := 999
	for cand in range(maxi(3, idx - 4), mini(13, idx + 4) + 1):
		var pc := posmod(_degree_midi(cand, root, scale) - croot, 12)
		for tone in tones:
			if pc == int(tone) and absi(cand - idx) < best_d:
				best_d = absi(cand - idx)
				best = cand
	return best


func _freq(midi: float) -> float:
	return 440.0 * pow(2.0, (midi - 69.0) / 12.0)


## Escribe con vuelta al principio, para que el bucle no tenga costura.
func _put(i: int, v: float) -> void:
	buf[i % buf.size()] += v


func _note(start: float, duration: float, midi: int, wave: String, gain: float) -> void:
	var f := _freq(midi)
	var i0 := int(start * RATE)
	var tail := 1.0 if wave in ["bell", "piano", "pluck"] else 0.0
	var n := int((duration + tail) * RATE)
	for k in n:
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
			"pluck":
				v = 1.0 if phase < 0.25 else -1.0
				env = exp(-t * 9.0) * minf(1.0, t * 800.0)
			"tri":
				v = 4.0 * absf(phase - 0.5) - 1.0
				env = exp(-t * 2.2) * minf(1.0, t * 300.0)
			"bell":
				v = sin(t * f * TAU) * 0.7 + sin(t * f * 2.76 * TAU) * 0.2 + sin(t * f * 5.4 * TAU) * 0.1
				env = exp(-t * 3.2) * minf(1.0, t * 800.0)
			"piano":
				v = sin(t * f * TAU) * 0.6 + sin(t * f * 2.0 * TAU) * 0.28 * exp(-t * 3.0) + sin(t * f * 3.0 * TAU) * 0.12 * exp(-t * 5.0)
				env = exp(-t * 2.4) * minf(1.0, t * 900.0)
			"pad":
				var p2 := fmod(t * f * 1.006, 1.0)
				v = (2.0 * phase - 1.0) * 0.5 + (2.0 * p2 - 1.0) * 0.5
				env = minf(1.0, t / 0.6) * minf(1.0, (duration - t) / 0.4)
		if env <= 0.0001 and k > 100:
			break
		_put(i0 + k, v * env * gain)


func _kick(start: float, level: float) -> void:
	var i0 := int(start * RATE)
	var phase := 0.0
	for k in int(0.25 * RATE):
		var t := float(k) / RATE
		phase += (45.0 + 90.0 * exp(-t * 30.0)) / RATE
		_put(i0 + k, sin(phase * TAU) * exp(-t * 12.0) * level)


func _snare(start: float, level: float) -> void:
	var i0 := int(start * RATE)
	for k in int(0.18 * RATE):
		var t := float(k) / RATE
		_put(i0 + k, (rng.randf_range(-1.0, 1.0) * 0.7 + sin(t * 190.0 * TAU) * 0.3) * exp(-t * 22.0) * 0.22 * level)


func _hat(start: float, gain: float) -> void:
	var i0 := int(start * RATE)
	var last := 0.0
	for k in int(0.04 * RATE):
		var t := float(k) / RATE
		var noise := rng.randf_range(-1.0, 1.0)
		_put(i0 + k, (noise - last) * exp(-t * 90.0) * gain * 4.0)
		last = noise
