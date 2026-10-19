extends SceneTree
## Genera los sonidos del juego (síntesis procedural, sin archivos externos):
##   assets/audio/sfx/<nombre>.wav      efectos cortos (habilidades, golpes, interfaz)
##   assets/audio/ambient/<estilo>.wav  ambientes en bucle, uno por estilo de zona
##
## Uso:  Godot_v4.7.2-stable_win64_console.exe --headless --path . -s res://tools/generate_sfx.gd
##
## Para usar sonidos propios basta con sustituir el .wav con el mismo nombre.

const RATE := 22050
const SFX_DIR := "res://assets/audio/sfx/"
const AMB_DIR := "res://assets/audio/ambient/"
const AMBIENT_SECONDS := 6.0
## Ambientes más bajos que el resto (los del prólogo no deben tapar los diálogos).
const AMBIENT_PEAK := {"oficina": 0.28, "pasillo": 0.4, "calle": 0.5}

var rng := RandomNumberGenerator.new()


func _initialize() -> void:
	rng.seed = 1337
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(SFX_DIR))
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(AMB_DIR))
	var sfx := {
		"swing": _swing, "projectile": _projectile, "fire": _fire, "cold": _cold, "lightning": _lightning,
		"chaos": _chaos, "explosion": _explosion, "blink": _blink, "buff": _buff, "barrier": _barrier,
		"summon": _summon, "trap": _trap, "enemy_death": _enemy_death, "player_hurt": _player_hurt,
		"pickup": _pickup, "level_up": _level_up, "flask": _flask, "portal": _portal, "wave": _wave_horn, "coin": _coin,
	}
	for name in sfx:
		_save(SFX_DIR + name + ".wav", sfx[name].call())
	var ambients := {
		"camp": _amb_camp, "sandbox": _amb_sandbox, "forest": _amb_forest, "ruins": _amb_wind.bind(0.5, 400.0),
		"swamp": _amb_swamp, "catacombs": _amb_catacombs, "servers": _amb_servers, "boss": _amb_boss,
		"kernel": _amb_kernel, "terminal": _amb_terminal, "fabrica": _amb_factory, "alcantarillas": _amb_sewer,
		"fosa": _amb_pit, "grieta": _amb_rift, "bus": _amb_bus, "anillo": _amb_ring, "frio": _amb_wind.bind(0.7, 1400.0),
		"calle": _amb_street, "pasillo": _amb_hallway, "oficina": _amb_office,
		"silicio": _amb_silicon, "bios": _amb_bios, "rom": _amb_rom, "flash": _amb_flash,
	}
	for name in ambients:
		_save(AMB_DIR + name + ".wav", _loopable(ambients[name].call()), float(AMBIENT_PEAK.get(name, 0.9)))
	print("Sonidos generados: %d efectos y %d ambientes" % [sfx.size(), ambients.size()])
	quit()


# --- Utilidades ---

func _buf(seconds: float) -> PackedFloat32Array:
	var b := PackedFloat32Array()
	b.resize(int(seconds * RATE))
	return b


func _save(path: String, samples: PackedFloat32Array, target_peak := 0.9) -> void:
	var peak := 0.001
	for s in samples:
		peak = maxf(peak, absf(s))
	var gain := target_peak / peak
	var data := PackedByteArray()
	data.resize(samples.size() * 2)
	for i in samples.size():
		data.encode_s16(i * 2, int(clampf(samples[i] * gain, -1.0, 1.0) * 32000.0))
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = RATE
	wav.stereo = false
	wav.data = data
	wav.save_to_wav(ProjectSettings.globalize_path(path))


## Cola mezclada con el principio para que el bucle no se note.
func _loopable(s: PackedFloat32Array) -> PackedFloat32Array:
	var fade := int(0.5 * RATE)
	var out := s.slice(0, s.size() - fade)
	for i in fade:
		var t := float(i) / fade
		out[i] = out[i] * t + s[s.size() - fade + i] * (1.0 - t)
	return out


func _env(t: float, attack: float, decay: float) -> float:
	return minf(1.0, t / maxf(attack, 0.0001)) * exp(-t / maxf(decay, 0.0001))


func _noise() -> float:
	return rng.randf_range(-1.0, 1.0)


## Ruido filtrado (paso bajo de un polo); `cut` en Hz.
func _lp(prev: float, x: float, cut: float) -> float:
	var a := clampf(TAU * cut / RATE, 0.0, 1.0)
	return prev + a * (x - prev)


func _sq(phase: float) -> float:
	return 1.0 if fmod(phase, 1.0) < 0.5 else -1.0


# --- Efectos ---

func _swing() -> PackedFloat32Array:
	var b := _buf(0.25)
	var f := 0.0
	for i in b.size():
		var t := float(i) / RATE
		f = _lp(f, _noise(), 3000.0 - t * 9000.0)
		b[i] = f * sin(PI * t / 0.25)
	return b


func _projectile() -> PackedFloat32Array:
	var b := _buf(0.16)
	var ph := 0.0
	for i in b.size():
		var t := float(i) / RATE
		ph += lerpf(1100.0, 300.0, t / 0.16) / RATE
		b[i] = (fmod(ph, 1.0) * 2.0 - 1.0) * _env(t, 0.004, 0.06)
	return b


func _fire() -> PackedFloat32Array:
	var b := _buf(0.45)
	var f := 0.0
	for i in b.size():
		var t := float(i) / RATE
		f = _lp(f, _noise(), 900.0)
		var crackle := _noise() * 0.6 if rng.randf() < 0.01 else 0.0
		b[i] = (f * 1.5 + crackle) * _env(t, 0.02, 0.18) + sin(TAU * 70.0 * t) * 0.4 * _env(t, 0.01, 0.12)
	return b


func _cold() -> PackedFloat32Array:
	var b := _buf(0.5)
	var f := 0.0
	var tones := [1760.0, 2349.0, 2637.0, 3136.0]
	for i in b.size():
		var t := float(i) / RATE
		f = _lp(f, _noise(), 6000.0)
		var chime := 0.0
		for k in tones.size():
			var start := k * 0.05
			if t > start:
				chime += sin(TAU * tones[k] * (t - start)) * _env(t - start, 0.002, 0.15)
		b[i] = chime * 0.4 + f * 0.25 * _env(t, 0.01, 0.2)
	return b


func _lightning() -> PackedFloat32Array:
	var b := _buf(0.28)
	var ph := 0.0
	var freq := 300.0
	for i in b.size():
		var t := float(i) / RATE
		if i % 220 == 0:
			freq = rng.randf_range(180.0, 900.0)
		ph += freq / RATE
		b[i] = (_sq(ph) * 0.6 + _noise() * 0.5) * _env(t, 0.002, 0.09)
	return b


func _chaos() -> PackedFloat32Array:
	var b := _buf(0.4)
	var p1 := 0.0
	var p2 := 0.0
	for i in b.size():
		var t := float(i) / RATE
		var base := lerpf(260.0, 90.0, t / 0.4)
		p1 += base / RATE
		p2 += base * 1.06 / RATE
		b[i] = ((fmod(p1, 1.0) - 0.5) + (fmod(p2, 1.0) - 0.5)) * _env(t, 0.02, 0.18)
	return b


func _explosion() -> PackedFloat32Array:
	var b := _buf(0.7)
	var f := 0.0
	for i in b.size():
		var t := float(i) / RATE
		f = _lp(f, _noise(), 1200.0 * exp(-t * 3.0) + 100.0)
		b[i] = f * 2.0 * _env(t, 0.003, 0.25) + sin(TAU * lerpf(90.0, 40.0, t / 0.7) * t) * 0.8 * _env(t, 0.002, 0.15)
	return b


func _blink() -> PackedFloat32Array:
	var b := _buf(0.22)
	var ph := 0.0
	for i in b.size():
		var t := float(i) / RATE
		ph += lerpf(300.0, 1600.0, t / 0.22) / RATE
		b[i] = sin(TAU * ph) * sin(PI * t / 0.22)
	return b


func _arpeggio(notes: Array, step: float, decay: float, wave := 0) -> PackedFloat32Array:
	var b := _buf(step * notes.size() + decay * 3.0)
	for k in notes.size():
		var start := int(k * step * RATE)
		var ph := 0.0
		for i in range(start, b.size()):
			var t := float(i - start) / RATE
			ph += notes[k] / RATE
			var v := sin(TAU * ph) if wave == 0 else _sq(ph) * 0.5
			b[i] += v * _env(t, 0.005, decay)
	return b


func _buff() -> PackedFloat32Array:
	return _arpeggio([523.25, 659.25, 783.99], 0.07, 0.15)


func _barrier() -> PackedFloat32Array:
	var b := _buf(0.6)
	for i in b.size():
		var t := float(i) / RATE
		var shimmer := sin(TAU * 880.0 * t) + sin(TAU * 1320.0 * t + sin(TAU * 6.0 * t)) * 0.6 + sin(TAU * 440.0 * t) * 0.5
		b[i] = shimmer * _env(t, 0.05, 0.25)
	return b


func _summon() -> PackedFloat32Array:
	var b := _buf(0.5)
	var ph := 0.0
	for i in b.size():
		var t := float(i) / RATE
		ph += lerpf(110.0, 330.0, t / 0.5) / RATE
		b[i] = (_sq(ph) * 0.4 + sin(TAU * ph * 2.0) * 0.3) * _env(t, 0.05, 0.25)
	return b


func _trap() -> PackedFloat32Array:
	var b := _buf(0.2)
	for i in b.size():
		var t := float(i) / RATE
		var click := _noise() * _env(t, 0.0005, 0.008)
		var beep := sin(TAU * 1200.0 * t) * (_env(t - 0.06, 0.002, 0.04) if t > 0.06 else 0.0)
		b[i] = click + beep * 0.6
	return b


func _enemy_death() -> PackedFloat32Array:
	var b := _buf(0.2)
	var ph := 0.0
	for i in b.size():
		var t := float(i) / RATE
		ph += lerpf(400.0, 60.0, t / 0.2) / RATE
		var crushed := floorf((_sq(ph) * 0.5 + _noise() * 0.5) * 4.0) / 4.0   # 2 bits, sonido "roto"
		b[i] = crushed * _env(t, 0.002, 0.07)
	return b


func _player_hurt() -> PackedFloat32Array:
	var b := _buf(0.16)
	var ph := 0.0
	for i in b.size():
		var t := float(i) / RATE
		ph += lerpf(220.0, 110.0, t / 0.16) / RATE
		b[i] = (_sq(ph) * 0.5 + _noise() * 0.3) * _env(t, 0.002, 0.05)
	return b


func _pickup() -> PackedFloat32Array:
	return _arpeggio([987.77, 1318.5], 0.05, 0.05, 1)


func _coin() -> PackedFloat32Array:
	return _arpeggio([1975.5, 2637.0], 0.045, 0.06)


func _level_up() -> PackedFloat32Array:
	return _arpeggio([523.25, 659.25, 783.99, 1046.5, 1318.5], 0.09, 0.25)


func _flask() -> PackedFloat32Array:
	var b := _buf(0.35)
	for i in b.size():
		var t := float(i) / RATE
		var gulp := 0.0
		for k in 3:
			var start := 0.04 + k * 0.1
			if t > start:
				gulp += sin(TAU * lerpf(200.0, 500.0, (t - start) / 0.08) * (t - start)) * _env(t - start, 0.003, 0.03)
		b[i] = gulp
	return b


func _portal() -> PackedFloat32Array:
	var b := _buf(0.8)
	var f := 0.0
	var ph := 0.0
	for i in b.size():
		var t := float(i) / RATE
		f = _lp(f, _noise(), 300.0 + t * 3000.0)
		ph += lerpf(150.0, 900.0, t / 0.8) / RATE
		b[i] = (f * 1.2 + sin(TAU * ph) * 0.3) * sin(PI * t / 0.8)
	return b


func _wave_horn() -> PackedFloat32Array:
	var b := _buf(0.9)
	var ph := 0.0
	for i in b.size():
		var t := float(i) / RATE
		ph += 110.0 / RATE
		b[i] = ((fmod(ph, 1.0) - 0.5) + (fmod(ph * 1.5, 1.0) - 0.5) * 0.5) * _env(t, 0.08, 0.5)
	return b


# --- Ambientes (en bucle) ---

func _amb_base() -> PackedFloat32Array:
	return _buf(AMBIENT_SECONDS)


func _add_drone(b: PackedFloat32Array, freq: float, amount: float, wobble := 0.3) -> void:
	for i in b.size():
		var t := float(i) / RATE
		b[i] += sin(TAU * freq * t + sin(TAU * wobble * t)) * amount


func _add_wind(b: PackedFloat32Array, amount: float, cut: float, lfo := 0.17) -> void:
	var f := 0.0
	for i in b.size():
		var t := float(i) / RATE
		f = _lp(f, _noise(), cut * (0.6 + 0.4 * sin(TAU * lfo * t)))
		b[i] += f * amount * (0.6 + 0.4 * sin(TAU * lfo * 0.5 * t + 1.0))


func _add_pings(b: PackedFloat32Array, count: int, freq_lo: float, freq_hi: float, amount: float, decay: float) -> void:
	for k in count:
		var start := rng.randi_range(0, b.size() - int(RATE * decay * 4.0) - 1)
		var freq := rng.randf_range(freq_lo, freq_hi)
		for i in int(RATE * decay * 4.0):
			var t := float(i) / RATE
			b[start + i] += sin(TAU * freq * t) * _env(t, 0.002, decay) * amount


func _add_thumps(b: PackedFloat32Array, interval: float, freq: float, amount: float) -> void:
	var n := int(AMBIENT_SECONDS / interval)
	for k in n:
		var start := int(k * interval * RATE)
		for i in int(RATE * 0.3):
			if start + i >= b.size():
				break
			var t := float(i) / RATE
			b[start + i] += sin(TAU * lerpf(freq * 1.6, freq, t / 0.3) * t) * _env(t, 0.003, 0.08) * amount


func _add_crackle(b: PackedFloat32Array, density: float, amount: float) -> void:
	for i in b.size():
		if rng.randf() < density:
			for j in 60:
				if i + j < b.size():
					b[i + j] += _noise() * amount * exp(-j / 12.0)


func _amb_camp() -> PackedFloat32Array:
	var b := _amb_base()
	_add_wind(b, 0.25, 300.0)
	_add_crackle(b, 0.0006, 0.6)
	_add_drone(b, 70.0, 0.08)
	return b


func _amb_sandbox() -> PackedFloat32Array:
	var b := _amb_base()
	_add_drone(b, 220.0, 0.12, 0.1)
	_add_drone(b, 277.18, 0.08, 0.13)
	_add_pings(b, 6, 900.0, 1800.0, 0.15, 0.05)
	return b


func _amb_forest() -> PackedFloat32Array:
	var b := _amb_base()
	_add_wind(b, 0.4, 600.0)
	_add_drone(b, 60.0, 0.05, 0.0)   # zumbido eléctrico de los cables
	_add_pings(b, 10, 2000.0, 3500.0, 0.12, 0.03)   # "pájaros" digitales
	return b


func _amb_wind(amount: float, cut: float) -> PackedFloat32Array:
	var b := _amb_base()
	_add_wind(b, amount, cut, 0.11)
	_add_drone(b, 55.0, 0.05)
	return b


func _amb_swamp() -> PackedFloat32Array:
	var b := _amb_base()
	_add_drone(b, 48.0, 0.15, 0.2)
	_add_wind(b, 0.15, 250.0)
	for k in 14:   # burbujas
		var start := rng.randi_range(0, b.size() - 4000)
		for i in 2500:
			var t := float(i) / RATE
			b[start + i] += sin(TAU * lerpf(180.0, 600.0, t / 0.11) * t) * _env(t, 0.004, 0.03) * 0.3
	return b


func _amb_catacombs() -> PackedFloat32Array:
	var b := _amb_base()
	_add_drone(b, 55.0, 0.2, 0.05)
	_add_pings(b, 8, 1400.0, 2200.0, 0.2, 0.12)   # gotas con eco
	return b


func _amb_servers() -> PackedFloat32Array:
	var b := _amb_base()
	_add_wind(b, 0.35, 1800.0, 0.05)   # ventiladores
	_add_drone(b, 120.0, 0.08, 0.0)
	_add_pings(b, 7, 2400.0, 2600.0, 0.1, 0.02)   # pitidos de estado
	return b


func _amb_boss() -> PackedFloat32Array:
	var b := _amb_base()
	_add_drone(b, 41.0, 0.3, 0.1)
	_add_drone(b, 61.5, 0.15, 0.07)
	_add_thumps(b, 1.0, 50.0, 0.6)    # latido
	return b


func _amb_kernel() -> PackedFloat32Array:
	var b := _amb_base()
	_add_drone(b, 36.0, 0.3, 0.05)
	_add_wind(b, 0.12, 800.0)
	for k in 8:   # ráfagas de glitch
		var start := rng.randi_range(0, b.size() - 3000)
		var ph := 0.0
		for i in 1500:
			ph += rng.randf_range(200.0, 2000.0) / RATE
			b[start + i] += _sq(ph) * 0.12
	return b


func _amb_terminal() -> PackedFloat32Array:
	var b := _amb_base()
	_add_drone(b, 60.0, 0.1, 0.0)
	_add_drone(b, 3150.0, 0.012, 0.0)   # pitido del CRT
	for k in 26:   # teclado
		var start := rng.randi_range(0, b.size() - 600)
		for i in 400:
			b[start + i] += _noise() * exp(-i / 40.0) * 0.35
	return b


func _amb_factory() -> PackedFloat32Array:
	var b := _amb_base()
	_add_thumps(b, 0.5, 70.0, 0.7)    # pistones
	_add_wind(b, 0.25, 2500.0, 2.0)   # vapor
	_add_drone(b, 90.0, 0.08)
	return b


func _amb_sewer() -> PackedFloat32Array:
	var b := _amb_base()
	_add_wind(b, 0.45, 500.0, 0.3)    # agua corriendo
	_add_pings(b, 10, 1600.0, 2400.0, 0.2, 0.06)   # goteo
	return b


func _amb_pit() -> PackedFloat32Array:
	var b := _amb_base()
	_add_wind(b, 0.3, 350.0)
	var ph := 0.0
	for i in b.size():   # lamentos lejanos
		var t := float(i) / RATE
		ph += (140.0 + 20.0 * sin(TAU * 0.3 * t)) / RATE
		b[i] += (fmod(ph, 1.0) - 0.5) * 0.06 * maxf(0.0, sin(TAU * 0.25 * t))
	return b


func _amb_rift() -> PackedFloat32Array:
	var b := _amb_base()
	_add_drone(b, 33.0, 0.3, 0.04)
	for k in 3:   # crujido de metal
		var start := rng.randi_range(0, b.size() - RATE)
		for i in RATE:
			var t := float(i) / RATE
			b[start + i] += sin(TAU * lerpf(300.0, 180.0, t) * t + sin(TAU * 13.0 * t) * 2.0) * sin(PI * t) * 0.08
	return b


func _amb_bus() -> PackedFloat32Array:
	var b := _amb_base()
	_add_drone(b, 110.0, 0.08, 0.0)
	_add_pings(b, 60, 1200.0, 3000.0, 0.08, 0.01)   # flujo de datos
	return b


func _amb_ring() -> PackedFloat32Array:
	var b := _amb_base()
	_add_drone(b, 55.0, 0.25, 0.3)
	_add_drone(b, 110.0, 0.1, 0.25)
	_add_crackle(b, 0.0008, 0.35)   # calor
	return b

# --- Prólogo (mundo real) ---

func _amb_street() -> PackedFloat32Array:
	var b := _amb_base()
	_add_wind(b, 0.3, 700.0, 0.12)        # brisa del malecón
	_add_wind(b, 0.25, 220.0, 0.08)       # olas
	_add_drone(b, 85.0, 0.05, 0.6)        # tráfico lejano
	for k in 3:   # gaviotas
		var start := rng.randi_range(0, b.size() - RATE)
		for i in int(RATE * 0.35):
			var t := float(i) / RATE
			b[start + i] += sin(TAU * lerpf(1700.0, 1100.0, t / 0.35) * t) * sin(PI * t / 0.35) * 0.08
	return b


func _amb_hallway() -> PackedFloat32Array:
	var b := _amb_base()
	_add_wind(b, 0.4, 900.0, 0.4)         # ventiladores industriales al límite
	_add_drone(b, 100.0, 0.1, 0.0)
	_add_drone(b, 50.0, 0.08, 0.0)        # zumbido de las lámparas
	return b


## Oficina: un servidor viejo encerrado en el cuarto. Zumbido grave de la fuente
## (60 Hz y armónicos), ventiladores apagados tras la puerta del rack y algún
## clic de disco duro. Bajo y constante: no debe tapar los diálogos.
func _amb_office() -> PackedFloat32Array:
	var b := _amb_base()
	_add_drone(b, 60.0, 0.22, 0.0)
	_add_drone(b, 120.0, 0.1, 0.0)
	_add_drone(b, 180.0, 0.04, 0.0)
	_add_wind(b, 0.18, 380.0, 0.03)       # ventiladores amortiguados por la carcasa
	for k in 9:   # el disco duro buscando sectores
		var start := rng.randi_range(0, b.size() - 400)
		for i in 300:
			b[start + i] += _noise() * exp(-i / 25.0) * 0.12
	return b

# --- Acto III: el Silicio Profundo ---

func _amb_silicon() -> PackedFloat32Array:
	var b := _amb_base()
	_add_drone(b, 50.0, 0.18, 0.05)           # zumbido del silicio
	_add_drone(b, 1000.0, 0.012, 0.0)          # bobina que silba
	_add_pings(b, 14, 3000.0, 4200.0, 0.05, 0.015)   # electrones saltando
	return b


func _amb_bios() -> PackedFloat32Array:
	var b := _amb_base()
	_add_drone(b, 60.0, 0.12, 0.0)
	_add_wind(b, 0.12, 900.0, 0.05)
	for k in 4:   # pitidos del POST
		var start := rng.randi_range(0, b.size() - 3000)
		for i in 2600:
			b[start + i] += _sq(i * 1000.0 / RATE) * 0.06 * (1.0 if i < 2200 else 0.0)
	return b


func _amb_rom() -> PackedFloat32Array:
	var b := _amb_base()
	_add_drone(b, 70.0, 0.14, 0.08)
	_add_pings(b, 10, 1800.0, 2900.0, 0.18, 0.22)   # cristales que resuenan
	return b


func _amb_flash() -> PackedFloat32Array:
	var b := _amb_base()
	_add_drone(b, 40.0, 0.3, 0.06)
	_add_thumps(b, 0.75, 55.0, 0.5)                  # latido de la escritura
	_add_wind(b, 0.15, 1400.0, 0.6)
	return b
