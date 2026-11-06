extends SceneTree
## Genera los sonidos del juego (síntesis procedural, sin archivos externos):
##   assets/audio/sfx/<nombre>.wav      efectos cortos (habilidades, golpes, interfaz)
##   assets/audio/ambient/<estilo>.wav  ambientes en bucle, uno por estilo de zona
##
## Uso:  Godot_v4.7.2-stable_win64_console.exe --headless --path . -s res://tools/generate_sfx.gd
##
## Para usar sonidos propios basta con sustituir el .wav con el mismo nombre.
## Los ambientes, después, se pasan a OGG con tools/convert_audio.ps1 (los efectos se quedan en WAV).

const RATE := 22050
const SFX_DIR := "res://assets/audio/sfx/"
const AMB_DIR := "res://assets/audio/ambient/"
## Duración generada de cada ambiente; el bucle final dura AMBIENT_FADE menos
## (24 s), múltiplo de los latidos de 0.5, 0.75 y 1 s para que no se descuadren.
const AMBIENT_SECONDS := 26.0
const AMBIENT_FADE := 2.0
## Ambientes más bajos que el resto (los del prólogo no deben tapar los diálogos).
const AMBIENT_PEAK := {"oficina": 0.28, "pasillo": 0.4, "calle": 0.5}

var rng := RandomNumberGenerator.new()


## Golpes por material, clic de crítico, botín único y muertes con estilo. Con
## `-- golpes` solo se generan estos (no se tocan los demás, por si alguno se ha
## sustituido a mano).
func _hit_sfx() -> Dictionary:
	return {
		"hit_flesh": _hit_flesh, "hit_metal": _hit_metal, "hit_crystal": _hit_crystal, "hit_digital": _hit_digital,
		"crit_click": _crit_click, "unique_drop": _unique_drop, "death_ash": _death_ash, "death_decompile": _death_decompile,
	}


## Ambientes del Acto IV. Con `-- acto4` solo se generan estos (como `-- golpes`).
func _act4_ambients() -> Dictionary:
	return {"setup": _amb_setup, "vga16": _amb_vga16}


## Ambiente posicional (suena cerca de su fuente, AmbientEmitters): zumbido de
## racks, goteo y viento. Con `-- posicional` solo se generan estos.
func _positional_ambients() -> Dictionary:
	return {"emit_rack": _emit_rack, "emit_drip": _emit_drip, "emit_wind": _emit_wind}


## T77: capas de lanzamiento, impactos por tipo, recoger y equipar por material,
## pasos por suelo e interfaz. Con `-- t77` solo se generan estos.
func _t77_sfx() -> Dictionary:
	return {
		"lay_click": _lay_click, "lay_whoosh": _lay_whoosh, "lay_hum": _lay_hum, "lay_chime": _lay_chime, "lay_thump": _lay_thump,
		"imp_fire": _imp_fire, "imp_ice": _imp_ice, "imp_zap": _imp_zap, "imp_splat": _imp_splat, "imp_thud": _imp_thud,
		"pick_metal": _pick_metal, "pick_cloth": _pick_cloth, "pick_glass": _pick_glass, "pick_board": _pick_board,
		"equip_metal": _equip_metal, "equip_cloth": _equip_cloth, "set_drop": _set_drop,
		"step_stone": _step.bind(900.0, 0.03), "step_dirt": _step.bind(420.0, 0.05), "step_metal": _step_metal,
		"ui_open": _ui_open, "ui_close": _ui_close, "ui_hover": _ui_hover, "ui_buy": _ui_buy, "ui_error": _ui_error,
	}


## T78: avisos cortos de música (élite, botín bueno, subida de nivel y jefe). Con
## `-- t78` solo se generan estos.
func _t78_stingers() -> Dictionary:
	return {"sting_elite": _sting_elite, "sting_loot": _sting_loot, "sting_level": _sting_level, "sting_boss": _sting_boss}


func _initialize() -> void:
	if OS.get_cmdline_user_args().has("t196"):
		rng.seed = 196
		var t196 := _t196_sigs()
		for name in t196:
			var s: PackedFloat32Array = t196[name].call()
			_save(SFX_DIR + name + ".wav", s, _layer_peak(s))
		print("Capas de firma de T196 generadas: %d" % t196.size())
		quit()
		return
	if OS.get_cmdline_user_args().has("t192"):
		rng.seed = 192
		_save(SFX_DIR + "thump.wav", _thump())
		print("Sonido de T192 generado: thump")
		quit()
		return
	if OS.get_cmdline_user_args().has("t189"):
		rng.seed = 189
		_save(SFX_DIR + "sting_commit.wav", _sting_commit(), 0.85)
		print("Aviso de T189 generado: sting_commit")
		return
	if OS.get_cmdline_user_args().has("t78"):
		rng.seed = 7878
		var t78 := _t78_stingers()
		for name in t78:
			_save(SFX_DIR + name + ".wav", t78[name].call(), 0.85)
		print("Avisos de T78 generados: %d" % t78.size())
		quit()
		return
	if OS.get_cmdline_user_args().has("t77"):
		rng.seed = 7777
		var t77 := _t77_sfx()
		for name in t77:
			_save(SFX_DIR + name + ".wav", t77[name].call())
		print("Sonidos de T77 generados: %d" % t77.size())
		quit()
		return
	if OS.get_cmdline_user_args().has("posicional"):
		rng.seed = 5555
		var pos := _positional_ambients()
		for name in pos:
			_save(AMB_DIR + name + ".wav", _loopable(pos[name].call()), 0.8)
		print("Ambientes posicionales generados: %d" % pos.size())
		quit()
		return
	if OS.get_cmdline_user_args().has("acto4"):
		rng.seed = 4444
		var act4 := _act4_ambients()
		for name in act4:
			_save(AMB_DIR + name + ".wav", _loopable(act4[name].call()), float(AMBIENT_PEAK.get(name, 0.9)))
		print("Ambientes del Acto IV generados: %d" % act4.size())
		quit()
		return
	if OS.get_cmdline_user_args().has("golpes"):
		rng.seed = 4242
		var only := _hit_sfx()
		for name in only:
			_save(SFX_DIR + name + ".wav", only[name].call())
		print("Sonidos de golpe generados: %d" % only.size())
		quit()
		return
	rng.seed = 1337
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(SFX_DIR))
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(AMB_DIR))
	var sfx := {
		"swing": _swing, "projectile": _projectile, "fire": _fire, "cold": _cold, "lightning": _lightning,
		"chaos": _chaos, "explosion": _explosion, "blink": _blink, "buff": _buff, "barrier": _barrier,
		"summon": _summon, "trap": _trap, "enemy_death": _enemy_death, "player_hurt": _player_hurt,
		"pickup": _pickup, "level_up": _level_up, "flask": _flask, "portal": _portal, "wave": _wave_horn, "coin": _coin,
	}
	# Estados, auras, invocaciones e interacciones (después de los ambientes, para
	# no cambiar la secuencia aleatoria de los que ya existían).
	var late_sfx := {
		"poison": _poison, "bleed": _bleed, "freeze": _freeze, "aura_on": _aura_on, "aura_off": _aura_off,
		"heal": _heal, "mine": _mine, "arc": _arc, "shatter": _shatter,
		# Prólogo: el servidor se traga a todos.
		"scream_m": _scream.bind(150.0, 1.0), "scream_f": _scream.bind(330.0, 1.18), "suction": _suction, "glitch_burst": _glitch_burst,
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
	for name in late_sfx:
		_save(SFX_DIR + name + ".wav", late_sfx[name].call())
	rng.seed = 4242
	var hit_sfx := _hit_sfx()
	for name in hit_sfx:
		_save(SFX_DIR + name + ".wav", hit_sfx[name].call())
		late_sfx[name] = hit_sfx[name]
	rng.seed = 4444
	var act4 := _act4_ambients()
	for name in act4:
		_save(AMB_DIR + name + ".wav", _loopable(act4[name].call()), float(AMBIENT_PEAK.get(name, 0.9)))
		ambients[name] = act4[name]
	rng.seed = 5555
	var positional := _positional_ambients()
	for name in positional:
		_save(AMB_DIR + name + ".wav", _loopable(positional[name].call()), 0.8)
		ambients[name] = positional[name]
	rng.seed = 192
	_save(SFX_DIR + "thump.wav", _thump())
	late_sfx["thump"] = _thump
	rng.seed = 196
	var t196 := _t196_sigs()
	for name in t196:
		var s: PackedFloat32Array = t196[name].call()
		_save(SFX_DIR + name + ".wav", s, _layer_peak(s))
		late_sfx[name] = t196[name]
	print("Sonidos generados: %d efectos y %d ambientes" % [sfx.size() + late_sfx.size(), ambients.size()])
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
	var fade := int(AMBIENT_FADE * RATE)
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


# --- T77: capas, impactos, objetos, pasos e interfaz ---

## Capa digital: ráfaga de clics de paquete (paquetes, rastreadores, bits).
func _lay_click() -> PackedFloat32Array:
	var b := _buf(0.16)
	for i in b.size():
		var t := float(i) / RATE
		var tick := fmod(t, 0.035) < 0.004
		b[i] = (_sq(t * 2400.0) * 0.6 if tick else 0.0) * _env(t, 0.001, 0.08)
	return b


## Capa de aire: barrido de ruido que sube y baja (cuerpo a cuerpo).
func _lay_whoosh() -> PackedFloat32Array:
	var b := _buf(0.22)
	var lp := 0.0
	for i in b.size():
		var t := float(i) / RATE
		lp = _lp(lp, _noise(), 500.0 + 2500.0 * sin(PI * t / 0.22))
		b[i] = lp * sin(PI * t / 0.22)
	return b


## Capa eléctrica: zumbido de red con armónicos (rayo).
func _lay_hum() -> PackedFloat32Array:
	var b := _buf(0.25)
	for i in b.size():
		var t := float(i) / RATE
		b[i] = (_sq(t * 120.0) * 0.4 + sin(TAU * 360.0 * t) * 0.4 + _noise() * 0.2) * _env(t, 0.01, 0.09)
	return b


## Capa brillante: campanita (frío, buffs, auras).
func _lay_chime() -> PackedFloat32Array:
	var b := _buf(0.4)
	for i in b.size():
		var t := float(i) / RATE
		b[i] = (sin(TAU * 1568.0 * t) + 0.5 * sin(TAU * 2349.0 * t) + 0.25 * sin(TAU * 3136.0 * t)) * _env(t, 0.002, 0.12)
	return b


## Capa grave: golpe sordo al suelo (áreas, novas, saltos).
func _lay_thump() -> PackedFloat32Array:
	var b := _buf(0.3)
	var lp := 0.0
	for i in b.size():
		var t := float(i) / RATE
		lp = _lp(lp, _noise(), 300.0)
		b[i] = sin(TAU * (90.0 - 50.0 * t) * t) * _env(t, 0.002, 0.08) + lp * 0.8 * _env(t, 0.001, 0.04)
	return b


## Impacto de fuego: chasquido con chisporroteo.
func _imp_fire() -> PackedFloat32Array:
	var b := _buf(0.3)
	var lp := 0.0
	for i in b.size():
		var t := float(i) / RATE
		lp = _lp(lp, _noise(), 1800.0)
		var crackle := _noise() if rng.randf() < 0.04 else 0.0
		b[i] = lp * _env(t, 0.002, 0.06) + crackle * _env(t, 0.0, 0.15) * 0.6
	return b


## Impacto de hielo: cristalitos que se rompen.
func _imp_ice() -> PackedFloat32Array:
	var b := _buf(0.3)
	for k in 5:
		var start := int(rng.randf_range(0.0, 0.08) * RATE)
		var f := rng.randf_range(2200.0, 4200.0)
		for i in range(start, b.size()):
			var t := float(i - start) / RATE
			b[i] += sin(TAU * f * t) * _env(t, 0.0005, 0.03) * 0.5
	for i in b.size():
		b[i] += _noise() * 0.25 * _env(float(i) / RATE, 0.0005, 0.01)
	return b


## Impacto de rayo: chispazo seco.
func _imp_zap() -> PackedFloat32Array:
	var b := _buf(0.16)
	for i in b.size():
		var t := float(i) / RATE
		b[i] = (_sq(t * rng.randf_range(800.0, 2200.0)) * 0.5 + _noise() * 0.5) * _env(t, 0.0005, 0.035)
	return b


## Impacto de caos: plaf húmedo que baja.
func _imp_splat() -> PackedFloat32Array:
	var b := _buf(0.25)
	var lp := 0.0
	for i in b.size():
		var t := float(i) / RATE
		lp = _lp(lp, _noise(), 900.0 - 2500.0 * t)
		b[i] = lp * _env(t, 0.003, 0.07) + sin(TAU * (260.0 - 500.0 * t) * t) * 0.4 * _env(t, 0.002, 0.05)
	return b


## Impacto físico: golpe seco.
func _imp_thud() -> PackedFloat32Array:
	var b := _buf(0.18)
	var lp := 0.0
	for i in b.size():
		var t := float(i) / RATE
		lp = _lp(lp, _noise(), 1200.0)
		b[i] = lp * _env(t, 0.001, 0.03) + sin(TAU * 160.0 * t) * 0.6 * _env(t, 0.001, 0.04)
	return b


## Recoger metal: tintineo de dos piezas.
func _pick_metal() -> PackedFloat32Array:
	var b := _buf(0.35)
	for i in b.size():
		var t := float(i) / RATE
		var t2 := maxf(0.0, t - 0.06)
		b[i] = (sin(TAU * 1180.0 * t) + 0.4 * sin(TAU * 2950.0 * t)) * _env(t, 0.001, 0.07) \
			+ (sin(TAU * 1420.0 * t2) + 0.4 * sin(TAU * 3310.0 * t2)) * _env(t2, 0.001, 0.08) * (1.0 if t >= 0.06 else 0.0)
	return b


## Recoger tela o cuero: roce suave.
func _pick_cloth() -> PackedFloat32Array:
	var b := _buf(0.22)
	var lp := 0.0
	for i in b.size():
		var t := float(i) / RATE
		lp = _lp(lp, _noise(), 1400.0)
		b[i] = lp * sin(PI * t / 0.22) * (0.6 + 0.4 * sin(TAU * 18.0 * t))
	return b


## Recoger cristal (pociones): «clink» de botella.
func _pick_glass() -> PackedFloat32Array:
	var b := _buf(0.4)
	for i in b.size():
		var t := float(i) / RATE
		b[i] = (sin(TAU * 1975.0 * t) + 0.6 * sin(TAU * 2810.0 * t) + 0.3 * sin(TAU * 4620.0 * t)) * _env(t, 0.0008, 0.09) + _noise() * 0.15 * _env(t, 0.0005, 0.004)
	return b


## Recoger placa o RAM: clic de plástico y un pitido de circuito.
func _pick_board() -> PackedFloat32Array:
	var b := _buf(0.2)
	for i in b.size():
		var t := float(i) / RATE
		var beep := _sq(t * 1760.0) * 0.35 * (1.0 if t > 0.05 and t < 0.12 else 0.0)
		b[i] = _noise() * _env(t, 0.0005, 0.006) + beep
	return b


## Equipar metal: «clanc» de cierre.
func _equip_metal() -> PackedFloat32Array:
	var b := _buf(0.35)
	var lp := 0.0
	for i in b.size():
		var t := float(i) / RATE
		lp = _lp(lp, _noise(), 2500.0)
		b[i] = (sin(TAU * 420.0 * t) + 0.7 * sin(TAU * 1130.0 * t)) * _env(t, 0.001, 0.08) + lp * _env(t, 0.0005, 0.015)
	return b


## Equipar tela: roce más largo, como ponerse una prenda.
func _equip_cloth() -> PackedFloat32Array:
	var b := _buf(0.35)
	var lp := 0.0
	for i in b.size():
		var t := float(i) / RATE
		lp = _lp(lp, _noise(), 900.0 + 900.0 * sin(PI * t / 0.35))
		b[i] = lp * sin(PI * t / 0.35)
	return b


## Caída de una pieza de conjunto: acorde verde, distinto del de los únicos.
func _set_drop() -> PackedFloat32Array:
	return _arpeggio([392.0, 494.0, 587.0, 784.0], 0.07, 0.35, 1)


## Paso: golpecito filtrado (`cut` Hz, más bajo en tierra) con un poco de grava.
func _step(cut: float, decay: float) -> PackedFloat32Array:
	var b := _buf(0.12)
	var lp := 0.0
	for i in b.size():
		var t := float(i) / RATE
		lp = _lp(lp, _noise(), cut)
		b[i] = lp * _env(t, 0.002, decay)
	return b


## Paso en metal: golpecito con un leve tañido.
func _step_metal() -> PackedFloat32Array:
	var b := _step(1500.0, 0.02)
	for i in b.size():
		var t := float(i) / RATE
		b[i] += sin(TAU * 740.0 * t) * 0.3 * _env(t, 0.001, 0.05)
	return b


## Abrir ventana: dos notas que suben y un roce de papel.
func _ui_open() -> PackedFloat32Array:
	return _arpeggio([660.0, 880.0], 0.045, 0.06)


func _ui_close() -> PackedFloat32Array:
	return _arpeggio([880.0, 587.0], 0.045, 0.05)


## Pasar el ratón: tic muy corto.
func _ui_hover() -> PackedFloat32Array:
	var b := _buf(0.03)
	for i in b.size():
		var t := float(i) / RATE
		b[i] = sin(TAU * 2600.0 * t) * _env(t, 0.0005, 0.006)
	return b


## Comprar: caja registradora en miniatura (campana y monedas).
func _ui_buy() -> PackedFloat32Array:
	var b := _arpeggio([1318.0, 1760.0], 0.05, 0.12)
	for i in mini(b.size(), int(0.08 * RATE)):
		b[i] += _noise() * 0.2 * _env(float(i) / RATE, 0.001, 0.02)
	return b


## Error: zumbido grave de dos golpes.
func _ui_error() -> PackedFloat32Array:
	var b := _buf(0.28)
	for i in b.size():
		var t := float(i) / RATE
		var on := 1.0 if fmod(t, 0.14) < 0.1 else 0.0
		b[i] = _sq(t * 150.0) * 0.5 * on * _env(t, 0.002, 0.2)
	return b


# --- T78: avisos de música ---

## Diente de sierra suavizado (metales graves).
func _saw(phase: float) -> float:
	return 2.0 * fmod(phase, 1.0) - 1.0


## Élite: golpe de metales graves en segunda menor y un timbal.
func _sting_elite() -> PackedFloat32Array:
	var b := _buf(1.2)
	var lp := 0.0
	for i in b.size():
		var t := float(i) / RATE
		var brass := (_saw(t * 110.0) + _saw(t * 116.5) + 0.5 * _saw(t * 55.0)) / 2.5
		lp = _lp(lp, brass, 600.0 + 1400.0 * exp(-t / 0.15))
		var timp := sin(TAU * (75.0 - 20.0 * t) * t) * _env(t, 0.002, 0.25)
		b[i] = lp * _env(t, 0.01, 0.4) + timp * 0.8
	return b


## Botín bueno: destello que sube (arpegio mayor con séptima, campanas) y un brillo de ruido.
func _sting_loot() -> PackedFloat32Array:
	var b := _arpeggio([1046.0, 1318.0, 1568.0, 1976.0, 2093.0], 0.055, 0.25)
	for i in mini(b.size(), int(0.5 * RATE)):
		var t := float(i) / RATE
		b[i] += _noise() * 0.08 * sin(PI * t / 0.5)
	return b


## Subida de nivel: fanfarria de cuadrada (do-mi-sol-do) que acaba en acorde.
func _sting_level() -> PackedFloat32Array:
	var b := _arpeggio([523.0, 659.0, 784.0], 0.09, 0.12, 1)
	var start := int(0.27 * RATE)
	var tail := _buf(0.9)
	for i in tail.size():
		var t := float(i) / RATE
		tail[i] = (_sq(t * 523.0) * 0.25 + _sq(t * 659.0) * 0.2 + _sq(t * 784.0) * 0.2 + _sq(t * 1046.0) * 0.25) * _env(t, 0.005, 0.35)
	b.resize(maxi(b.size(), start + tail.size()))
	for i in tail.size():
		b[start + i] += tail[i]
	return b


## Jefe: oleada de ruido que crece, acorde grave menor y dos golpes de timbal.
func _sting_boss() -> PackedFloat32Array:
	var b := _buf(2.2)
	var lp := 0.0
	for i in b.size():
		var t := float(i) / RATE
		var swell := 0.0
		if t < 0.6:
			lp = _lp(lp, _noise(), 200.0 + 2000.0 * t)
			swell = lp * (t / 0.6)
		var h := maxf(0.0, t - 0.6)
		var chord := (_saw(h * 82.4) + _saw(h * 98.0) + _saw(h * 123.5) + _saw(h * 41.2)) / 4.0 * _env(h, 0.01, 0.6) if t >= 0.6 else 0.0
		var hit := 0.0
		for at in [0.6, 1.0]:
			if t >= at:
				var u: float = t - at
				hit += sin(TAU * (65.0 - 15.0 * u) * u) * _env(u, 0.002, 0.3)
		b[i] = swell * 0.7 + chord * 0.8 + hit
	return b


## «EL ÚLTIMO COMMIT» (T189): golpe grave, acorde mayor abierto que se queda sonando
## y se va degradando a 8 bits (cada vez con menos resolución), como el mundo al caer.
func _sting_commit() -> PackedFloat32Array:
	var b := _buf(3.0)
	var lp := 0.0
	for i in b.size():
		var t := float(i) / RATE
		var boom := sin(TAU * (55.0 - 18.0 * t) * t) * _env(t, 0.002, 0.5)
		var chord := (_saw(t * 98.0) + _saw(t * 146.8) + _saw(t * 196.0) + _saw(t * 246.9) * 0.6) / 3.6
		lp = _lp(lp, chord, 500.0 + 2500.0 * exp(-t / 0.4))
		var sustain := lp * _env(t, 0.01, 1.6)
		var steps := lerpf(64.0, 4.0, clampf(t / 2.6, 0.0, 1.0))   # menos niveles: se pixela el sonido
		sustain = roundf(sustain * steps) / steps
		b[i] = boom * 0.9 + sustain * 0.75 + _noise() * 0.12 * _env(t, 0.001, 0.08)
	return b


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


## Golpe de área física (T192: Core Dump y las áreas sin elemento): un bombo grave
## que cae de 85 a 35 Hz, con un crujido de ruido filtrado al principio y un rebote
## sordo 60 ms después. Más corto y seco que la explosión, sin la cola de fuego.
func _thump() -> PackedFloat32Array:
	var b := _buf(0.45)
	var f := 0.0
	var ph := 0.0
	for i in b.size():
		var t := float(i) / RATE
		ph += lerpf(85.0, 35.0, minf(1.0, t / 0.3)) / RATE
		f = _lp(f, _noise(), 700.0 * exp(-t * 8.0) + 120.0)
		var body := sin(TAU * ph) * _env(t, 0.002, 0.12)
		var rebound := sin(TAU * 60.0 * (t - 0.06)) * 0.4 * _env(t - 0.06, 0.003, 0.05) if t > 0.06 else 0.0
		b[i] = body + rebound + f * 1.4 * _env(t, 0.001, 0.05)
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


# --- Estados, auras e invocaciones ---

## Veneno: burbujeo ácido que sisea.
func _poison() -> PackedFloat32Array:
	var b := _buf(0.45)
	var f := 0.0
	for k in 4:
		var start := k * 0.07
		for i in int(0.1 * RATE):
			var t := float(i) / RATE
			var idx := int(start * RATE) + i
			if idx < b.size():
				b[idx] += sin(TAU * lerpf(220.0 + k * 60.0, 520.0 + k * 80.0, t / 0.1) * t) * _env(t, 0.004, 0.03) * 0.5
	for i in b.size():
		var t := float(i) / RATE
		f = _lp(f, _noise(), 4500.0)
		b[i] += f * 0.25 * _env(t, 0.05, 0.15)
	return b


## Sangrado: golpe húmedo y grave con un goteo.
func _bleed() -> PackedFloat32Array:
	var b := _buf(0.4)
	var f := 0.0
	var ph := 0.0
	for i in b.size():
		var t := float(i) / RATE
		f = _lp(f, _noise(), 700.0)
		ph += lerpf(160.0, 70.0, t / 0.4) / RATE
		b[i] = (f * 1.4 + sin(TAU * ph) * 0.6) * _env(t, 0.003, 0.07)
		if t > 0.22:
			b[i] += sin(TAU * lerpf(900.0, 1400.0, (t - 0.22) / 0.06) * (t - 0.22)) * _env(t - 0.22, 0.002, 0.03) * 0.4
	return b


## Congelación: hielo que cruje y se cierra.
func _freeze() -> PackedFloat32Array:
	var b := _buf(0.55)
	for i in b.size():
		var t := float(i) / RATE
		var crack := _noise() * (1.0 if rng.randf() < 0.04 * exp(-t * 4.0) else 0.0)
		b[i] = crack * 0.8 + sin(TAU * 2637.0 * t) * _env(t, 0.01, 0.2) * 0.25 + sin(TAU * 3520.0 * t) * _env(t - 0.1, 0.01, 0.15) * (0.2 if t > 0.1 else 0.0)
	return b


## Aura encendida: acorde que sube y se abre.
func _aura_on() -> PackedFloat32Array:
	var b := _buf(0.7)
	for i in b.size():
		var t := float(i) / RATE
		var sweep := 1.0 + 0.5 * t
		b[i] = (sin(TAU * 330.0 * sweep * t) + sin(TAU * 495.0 * sweep * t) * 0.7 + sin(TAU * 660.0 * sweep * t) * 0.4) * _env(t, 0.08, 0.3)
	return b


## Aura apagada: el mismo acorde, cayendo.
func _aura_off() -> PackedFloat32Array:
	var b := _buf(0.5)
	for i in b.size():
		var t := float(i) / RATE
		var sweep := 1.0 - 0.45 * t
		b[i] = (sin(TAU * 495.0 * sweep * t) + sin(TAU * 330.0 * sweep * t) * 0.7) * _env(t, 0.01, 0.16)
	return b


## Curación del dron: campanitas que suben.
func _heal() -> PackedFloat32Array:
	return _arpeggio([659.25, 830.61, 987.77, 1318.5], 0.06, 0.2)


## Explosión de la Mina Rodante: más grave y con metralla.
func _mine() -> PackedFloat32Array:
	var b := _buf(0.9)
	var f := 0.0
	for i in b.size():
		var t := float(i) / RATE
		f = _lp(f, _noise(), 800.0 * exp(-t * 2.5) + 80.0)
		var shrapnel := _noise() * 0.5 if rng.randf() < 0.02 * exp(-t * 3.0) else 0.0
		b[i] = f * 2.2 * _env(t, 0.002, 0.3) + sin(TAU * lerpf(70.0, 30.0, t / 0.9) * t) * _env(t, 0.002, 0.2) + shrapnel
	return b


## Superconductor (helado + rayo): un arco que salta entre enemigos.
func _arc() -> PackedFloat32Array:
	var b := _buf(0.35)
	var ph := 0.0
	var freq := 900.0
	for i in b.size():
		var t := float(i) / RATE
		if i % 160 == 0:
			freq = rng.randf_range(600.0, 2400.0)
		ph += freq / RATE
		b[i] = (_sq(ph) * 0.4 + sin(TAU * 2093.0 * t) * 0.3) * _env(t, 0.002, 0.1)
	return b


## Rotura: el hielo estalla en pedazos.
func _shatter() -> PackedFloat32Array:
	var b := _buf(0.5)
	var f := 0.0
	for i in b.size():
		var t := float(i) / RATE
		f = _lp(f, _noise(), 7000.0)
		var tinkle := 0.0
		for k in 4:
			var st := 0.03 + k * 0.05
			if t > st:
				tinkle += sin(TAU * (2200.0 + k * 470.0) * (t - st)) * _env(t - st, 0.001, 0.05)
		b[i] = f * _env(t, 0.001, 0.05) + tinkle * 0.3
	return b


# --- Golpes por material y muertes ---

## Carne (bichos, gusanos): golpe sordo y grave.
func _hit_flesh() -> PackedFloat32Array:
	var b := _buf(0.12)
	var f := 0.0
	for i in b.size():
		var t := float(i) / RATE
		f = _lp(f, _noise(), 500.0)
		b[i] = (sin(TAU * lerpf(140.0, 70.0, t / 0.12) * t) * 0.7 + f * 1.6) * _env(t, 0.001, 0.035)
	return b


## Metal (racks, daemons, robots): clang con parciales inarmónicos.
func _hit_metal() -> PackedFloat32Array:
	var b := _buf(0.3)
	for i in b.size():
		var t := float(i) / RATE
		var ring := sin(TAU * 523.0 * t) + 0.6 * sin(TAU * 1371.0 * t) + 0.4 * sin(TAU * 2419.0 * t)
		b[i] = ring * _env(t, 0.001, 0.07) * 0.5 + _noise() * _env(t, 0.0005, 0.008)
	return b


## Cristal (ROM, silicio, hielo): ping agudo y corto.
func _hit_crystal() -> PackedFloat32Array:
	var b := _buf(0.25)
	for i in b.size():
		var t := float(i) / RATE
		b[i] = (sin(TAU * 2637.0 * t) + 0.5 * sin(TAU * 3951.0 * t)) * _env(t, 0.0008, 0.05) + _noise() * 0.3 * _env(t, 0.0005, 0.005)
	return b


## Digital (procesos, fantasmas, glitches): chasquido de bits a 2 bits.
func _hit_digital() -> PackedFloat32Array:
	var b := _buf(0.1)
	var ph := 0.0
	for i in b.size():
		var t := float(i) / RATE
		ph += (1800.0 if int(t * 120.0) % 2 == 0 else 900.0) / RATE
		b[i] = floorf(_sq(ph) * 2.0) / 2.0 * _env(t, 0.001, 0.025)
	return b


## Crítico: el clic de un teclado mecánico (switch azul): chasquido + resorte.
func _crit_click() -> PackedFloat32Array:
	var b := _buf(0.09)
	var f := 0.0
	for i in b.size():
		var t := float(i) / RATE
		f = _lp(f, _noise(), 6000.0)
		var click := f * _env(t, 0.0003, 0.004) * 2.0
		var second := f * _env(maxf(0.0, t - 0.018), 0.0003, 0.004) * 1.4 if t > 0.018 else 0.0
		b[i] = click + second + sin(TAU * 3200.0 * t) * _env(t, 0.0005, 0.01) * 0.3
	return b


## Objeto único en el suelo: fanfarria corta, inconfundible (sube y brilla).
func _unique_drop() -> PackedFloat32Array:
	var notes := [783.99, 1046.5, 1318.5, 1567.98, 2093.0]
	var b := _buf(1.1)
	for i in b.size():
		var t := float(i) / RATE
		var s := 0.0
		for k in notes.size():
			var st := k * 0.07
			if t > st:
				s += (sin(TAU * notes[k] * (t - st)) + 0.3 * _sq(notes[k] * 0.5 * (t - st))) * _env(t - st, 0.004, 0.35)
		s += sin(TAU * 4186.0 * t) * 0.15 * sin(TAU * 7.0 * t) * _env(t, 0.3, 0.4)   # brillo final
		b[i] = s
	return b


## Muerte por fuego: chisporroteo que se apaga en ceniza.
func _death_ash() -> PackedFloat32Array:
	var b := _buf(0.45)
	var f := 0.0
	for i in b.size():
		var t := float(i) / RATE
		f = _lp(f, _noise(), 2500.0)
		var crackle := _noise() if rng.randf() < 0.02 * (1.0 - t / 0.45) else 0.0
		b[i] = f * 0.4 * _env(t, 0.01, 0.15) + crackle
	return b


## Muerte por daño físico o caos: el enemigo se "descompila" en bits que caen.
func _death_decompile() -> PackedFloat32Array:
	var b := _buf(0.35)
	var ph := 0.0
	for i in b.size():
		var t := float(i) / RATE
		var step := floorf(t * 40.0)
		ph += (1600.0 - step * 90.0) / RATE
		b[i] = floorf(_sq(ph) * 1.5) / 1.5 * _env(t, 0.002, 0.12) * (0.6 if int(step) % 2 == 0 else 1.0)
	return b


# --- Prólogo: absorción por el servidor ---

## Grito «¡AAAH!» sintetizado: armónicos de una voz (f0 que sube y cae) pesados
## por los formantes de la vocal A, con vibrato y aliento; al final la voz se
## «digitaliza» (cae de golpe y se entrecorta) porque se la traga el servidor.
## `formant_shift` sube los formantes (voz más aguda).
func _scream(f0: float, formant_shift: float) -> PackedFloat32Array:
	var dur := 1.5
	var b := _buf(dur)
	var formants := [Vector2(800.0, 120.0), Vector2(1200.0, 160.0), Vector2(2500.0, 260.0)]
	var ph := 0.0
	var f := 0.0
	for i in b.size():
		var t := float(i) / RATE
		var contour := 1.0 + 0.35 * sin(PI * minf(1.0, t / 0.9)) - (2.2 * pow((t - 1.0) / 0.5, 2.0) if t > 1.0 else 0.0)
		var pitch := f0 * maxf(0.25, contour) * (1.0 + 0.03 * sin(TAU * 6.0 * t))
		ph += pitch / RATE
		var v := 0.0
		for n in range(1, 18):
			var hz := pitch * n
			var amp := 0.0
			for fm: Vector2 in formants:
				var center := fm.x * formant_shift
				amp += exp(-pow((hz - center) / (fm.y * 2.0), 2.0))
			v += sin(TAU * ph * n) * amp / n * 2.0
		f = _lp(f, _noise(), 3000.0)
		v += f * 0.25   # aliento
		var env := _env(t, 0.04, 2.0) * clampf((dur - t) / 0.15, 0.0, 1.0)
		if t > 1.0 and fmod(t * 40.0, 1.0) < 0.35:
			v = floorf(v * 3.0) / 3.0   # entrecortado digital
		b[i] = v * env
	return b


## Succión del servidor: ruido que sube de agudo, un zumbido grave que acelera.
func _suction() -> PackedFloat32Array:
	var dur := 3.2
	var b := _buf(dur)
	var f := 0.0
	var ph := 0.0
	for i in b.size():
		var t := float(i) / RATE
		var k := t / dur
		f = _lp(f, _noise(), lerpf(150.0, 3800.0, k * k))
		ph += lerpf(40.0, 140.0, k) / RATE
		b[i] = (f * 1.6 + sin(TAU * ph) * 0.5 + sin(TAU * ph * 1.5) * 0.2) * minf(1.0, t / 0.4) * (0.4 + 0.6 * k) * clampf((dur - t) / 0.25, 0.0, 1.0)
	return b


## Ráfaga digital: chasquidos de bits y un barrido cuadrado.
func _glitch_burst() -> PackedFloat32Array:
	var b := _buf(0.5)
	var ph := 0.0
	var hz := 800.0
	for i in b.size():
		var t := float(i) / RATE
		if i % 300 == 0:
			hz = rng.randf_range(200.0, 3000.0)
		ph += hz / RATE
		b[i] = (_sq(ph) * 0.5 + (_noise() if rng.randf() < 0.1 else 0.0)) * _env(t, 0.002, 0.18)
	return b


# --- T196: capa de firma de cada habilidad ---
# Una función _sig_<id> por habilidad, según la columna de sonido de la ficha de
# T191 (docs/habilidades_y_ram.md). SoundMap.SIGNATURES las pone a -6 dB sobre la
# base de su tipo. Se generan todas las funciones que empiezan por _sig_.

## Capas de firma: {"sig_<id>": callable}, sacadas de los métodos _sig_<id>.
func _t196_sigs() -> Dictionary:
	var out := {}
	for m in get_method_list():
		var name := String(m["name"])
		if name.begins_with("_sig_"):
			out[name.substr(1)] = Callable(self, name)
	return out


## Pico al guardar una capa de firma: 0.9, salvo que así su volumen eficaz pase
## de 0.3 (cuadradas llenas, sirenas), para que ninguna tape a la base de su tipo.
func _layer_peak(s: PackedFloat32Array) -> float:
	var peak := 0.001
	var sum := 0.0
	for v in s:
		peak = maxf(peak, absf(v))
		sum += v * v
	var rms := sqrt(sum / maxi(1, s.size())) / peak * 0.9
	return 0.9 * minf(1.0, 0.3 / maxf(rms, 0.001))


## Nota de `dur` s que se desliza de `f0` a `f1` Hz: onda 0 seno, 1 cuadrada, 2 sierra.
func _note(f0: float, f1: float, dur: float, decay: float, wave := 0) -> PackedFloat32Array:
	var b := _buf(dur)
	var ph := 0.0
	for i in b.size():
		var t := float(i) / RATE
		ph += lerpf(f0, f1, t / dur) / RATE
		var v := sin(TAU * ph)
		if wave == 1:
			v = _sq(ph) * 0.5
		elif wave == 2:
			v = _saw(ph) * 0.5
		b[i] = v * _env(t, 0.002, decay) * minf(1.0, (dur - t) / 0.003)
	return b


## Ruido filtrado de `dur` s con el corte de `c0` a `c1` Hz, con el volumen
## compensado (un paso bajo grave casi no se oiría al lado de una nota).
func _hiss(dur: float, c0: float, c1: float, decay: float, attack := 0.001) -> PackedFloat32Array:
	var b := _buf(dur)
	var f := 0.0
	for i in b.size():
		var t := float(i) / RATE
		var cut := lerpf(c0, c1, t / dur)
		var a := clampf(TAU * cut / RATE, 0.001, 1.0)
		f = _lp(f, _noise(), cut)
		b[i] = f * sqrt((2.0 - a) / a) * 0.5 * _env(t, attack, decay) * minf(1.0, (dur - t) / 0.003)
	return b


## Ruido retenido: `hz` valores al azar por segundo (bits, volcados, datos rotos).
func _bits(dur: float, hz: float, decay: float) -> PackedFloat32Array:
	var b := _buf(dur)
	var hold := maxi(1, int(RATE / hz))
	var v := 0.0
	for i in b.size():
		if i % hold == 0:
			v = rng.randf_range(-1.0, 1.0)
		b[i] = v * 0.6 * _env(float(i) / RATE, 0.002, decay)
	return b


## Trémolo: el volumen de `src` sube y baja de `hz0` a `hz1` veces por segundo.
func _trem(src: PackedFloat32Array, hz0: float, hz1: float, depth := 0.8) -> PackedFloat32Array:
	var ph := 0.0
	for i in src.size():
		ph += lerpf(hz0, hz1, float(i) / src.size()) / RATE
		src[i] *= 1.0 - depth * (0.5 + 0.5 * sin(TAU * ph))
	return src


## Paso bajo sobre un sonido ya hecho (cuadradas y sierras apagadas).
func _lowpass(src: PackedFloat32Array, cut: float) -> PackedFloat32Array:
	var f := 0.0
	for i in src.size():
		f = _lp(f, src[i], cut)
		src[i] = f
	return src


## Junta trozos: [[sonido, segundo en que empieza, ganancia (1 si no está)], ...].
func _seq(parts: Array) -> PackedFloat32Array:
	var b := PackedFloat32Array()
	for p in parts:
		var src: PackedFloat32Array = p[0]
		var start := int(float(p[1]) * RATE)
		var gain := float(p[2]) if p.size() > 2 else 1.0
		if b.size() < start + src.size():
			var old := b.size()
			b.resize(start + src.size())
			for i in range(old, b.size()):
				b[i] = 0.0
		for i in src.size():
			b[start + i] += src[i] * gain
	return b


## Clic cuadrado corto de `hz`.
func _blip(hz: float, dur := 0.015) -> PackedFloat32Array:
	return _note(hz, hz, dur, dur * 0.6, 1)


## Clac seco: ruido filtrado a `cut` de pocos milisegundos.
func _clack(cut: float, dur := 0.01) -> PackedFloat32Array:
	return _hiss(dur, cut, cut, dur * 0.4)


# Cuerpo a cuerpo y movimiento

## Refactorizar: aire que barre de 400 a 2400 Hz y la llave que se cierra.
func _sig_barrido() -> PackedFloat32Array:
	return _seq([[_hiss(0.2, 400.0, 2400.0, 0.2, 0.02), 0.0], [_blip(1800.0), 0.2, 0.7]])


## Pipeline: tres pitidos cuadrados que suben (etapas en verde).
func _sig_deploy_continuo() -> PackedFloat32Array:
	return _seq([[_blip(660.0, 0.035), 0.0], [_blip(880.0, 0.035), 0.06], [_blip(1320.0, 0.035), 0.12]])


## Reinicio a patadas: relé, disco que se para y el pitido del POST.
func _sig_reinicio_forzado() -> PackedFloat32Array:
	return _seq([[_clack(4000.0, 0.005), 0.0], [_note(120.0, 40.0, 0.25, 0.12), 0.005], [_blip(1000.0, 0.08), 0.27, 0.6]])


## git push --force: empujón de ruido grave, sierra que baja y un clic seco.
func _sig_force_push() -> PackedFloat32Array:
	return _seq([[_hiss(0.2, 300.0, 300.0, 0.18, 0.005), 0.0], [_note(220.0, 110.0, 0.2, 0.15, 2), 0.0, 0.8], [_clack(5000.0), 0.2, 0.8]])


## Entradas aleatorias: tres golpes de ruido, cada uno con un tono al azar.
func _sig_fuzzing() -> PackedFloat32Array:
	var parts := []
	for k in 3:
		var hz := rng.randf_range(300.0, 2000.0)
		parts.append([_hiss(0.03, 3000.0, 3000.0, 0.02), k * 0.08, 0.7])
		parts.append([_note(hz, hz, 0.03, 0.02, 1), k * 0.08, 0.6])
	return _seq(parts)


## SYN, trino de módem y ACK.
func _sig_teleport_tcp() -> PackedFloat32Array:
	var modem := _buf(0.09)
	var ph := 0.0
	for i in modem.size():
		ph += (1800.0 if int(float(i) / RATE / 0.01) % 2 == 0 else 2400.0) / RATE
		modem[i] = sin(TAU * ph) * sin(PI * float(i) / modem.size())
	return _seq([[_blip(1200.0, 0.03), 0.0], [modem, 0.04, 0.2], [_blip(1600.0, 0.03), 0.15]])


## Túnel cifrado: clic metálico, zumbido de 60 Hz y otro clic.
func _sig_tunel_ssh() -> PackedFloat32Array:
	var hum := _lowpass(_note(60.0, 60.0, 0.15, 1.0, 1), 600.0)
	return _seq([[_clack(3000.0), 0.0], [hum, 0.01, 1.6], [_clack(3000.0), 0.17]])


## Deshacer: el arpegio del buff al revés (sol-mi-do) y una campanita.
func _sig_git_revert() -> PackedFloat32Array:
	return _seq([[_arpeggio([783.99, 659.25, 523.25], 0.065, 0.06), 0.0, 0.6], [_note(1568.0, 1568.0, 0.25, 0.1), 0.2, 0.5]])


# Hechizos y proyectiles

## Ping: seno de 1760 Hz y su eco más bajo.
func _sig_ping_letal() -> PackedFloat32Array:
	var ping := _note(1760.0, 1760.0, 0.3, 0.09)
	return _seq([[ping, 0.0], [ping, 0.12, 0.25]])


## :(){ :|:& };: — clics que se duplican cada cuarto (1, 2, 4 y 8).
func _sig_fork_bomb() -> PackedFloat32Array:
	var parts := []
	for q in 4:
		var n := 1 << q
		for k in n:
			parts.append([_blip(900.0, 0.006), q * 0.12 + k * 0.12 / n, 0.8])
	return _seq(parts)


## Push, push, push... y la pila se desborda hacia abajo.
func _sig_stack_overflow() -> PackedFloat32Array:
	var parts := []
	var notes := [440.0, 523.25, 659.25, 783.99, 990.0]
	for k in notes.size():
		parts.append([_blip(notes[k], 0.025), k * 0.03])
	parts.append([_note(990.0, 160.0, 0.15, 0.12, 1), 0.15])
	return _seq(parts)


## Tabuladores contra espacios: dos sierras que discuten a destiempo.
func _sig_flamewar() -> PackedFloat32Array:
	var a := _trem(_note(300.0, 290.0, 0.25, 0.2, 2), 18.0, 18.0, 0.9)
	var b := _trem(_note(340.0, 355.0, 0.25, 0.2, 2), 18.0, 18.0, 0.9)
	return _lowpass(_seq([[a, 0.0], [b, 0.028]]), 2500.0)


## Carga que sube y la sirena de producción al disparar.
func _sig_rayo_produccion() -> PackedFloat32Array:
	var parts := [[_note(200.0, 1200.0, 0.2, 1.0), 0.0, 0.6]]
	for k in 4:
		parts.append([_blip(800.0 if k % 2 == 0 else 600.0, 0.06), 0.2 + k * 0.06, 0.8])
	return _seq(parts)


## Dos procesos que se esperan: tonos disonantes alternos que se cortan en seco.
func _sig_deadlock() -> PackedFloat32Array:
	var parts := []
	for k in 6:
		var hz := 440.0 if k % 2 == 0 else 466.16
		parts.append([_note(hz, hz, 0.05, 1.0, 1), k * 0.05])
	return _seq(parts)


## Uncaught: las dos notas del error.
func _sig_excepcion_en_cadena() -> PackedFloat32Array:
	return _seq([[_note(880.0, 880.0, 0.06, 0.1, 1), 0.0], [_note(660.0, 660.0, 0.06, 0.1, 1), 0.06]])


## Goteo de memoria sobre un borboteo.
func _sig_fuga_de_memoria() -> PackedFloat32Array:
	var parts := [[_trem(_hiss(0.35, 500.0, 500.0, 0.25, 0.03), 12.0, 7.0, 0.7), 0.0, 0.5]]
	for k in 3:
		parts.append([_note(600.0, 300.0, 0.04, 0.03), k * 0.1])
	return _seq(parts)


## Segmentation fault: ráfaga de bits y el golpe grave del volcado.
func _sig_core_dump() -> PackedFloat32Array:
	return _seq([[_bits(0.2, 2000.0, 0.12), 0.0, 0.8], [_note(60.0, 50.0, 0.05, 0.04), 0.18, 1.2]])


# Buffs, gritos, barrera y auras

## Muro de ladrillos: seis clacs y un chime grave.
func _sig_firewall_personal() -> PackedFloat32Array:
	var parts := []
	for k in 6:
		parts.append([_clack(1500.0, 0.008), k * 0.02, 0.9])
	parts.append([_note(330.0, 330.0, 0.3, 0.12), 0.12, 0.6])
	return _seq(parts)


## Modo seguro: acorde grave y apagado.
func _sig_modo_seguro() -> PackedFloat32Array:
	var chord := _seq([[_note(220.0, 220.0, 0.4, 0.25, 1), 0.0], [_note(261.63, 261.63, 0.4, 0.25, 1), 0.0]])
	return _lowpass(chord, 500.0)


## Dos hilos: el mismo arpegio dos veces, desfasado 20 ms.
func _sig_hiperthreading() -> PackedFloat32Array:
	var arp := _arpeggio([523.25, 659.25, 783.99], 0.05, 0.05)
	return _seq([[arp, 0.0], [arp, 0.02, 0.8]])


## ¡PROD!: sirena de dos tonos, dos ciclos.
func _sig_esta_en_produccion() -> PackedFloat32Array:
	var parts := []
	for k in 4:
		var hz := 960.0 if k % 2 == 0 else 770.0
		parts.append([_note(hz, hz, 0.125, 1.0, 1), k * 0.125])
	return _lowpass(_seq(parts), 3000.0)


## Daily: tic-tac que se acelera y el «ding» del calendario.
func _sig_daily_standup() -> PackedFloat32Array:
	var parts := []
	var at := 0.0
	for k in 4:
		parts.append([_clack(2000.0 if k % 2 == 0 else 1500.0, 0.006), at])
		at += 0.08 - k * 0.015
	var ding := _seq([[_note(1320.0, 1320.0, 0.25, 0.1), 0.0], [_note(2640.0, 2640.0, 0.25, 0.06), 0.0, 0.4]])
	parts.append([ding, at + 0.02, 0.7])
	return _seq(parts)


## Volver atrás: ruido con la envolvente al revés y un arpegio que baja.
func _sig_rollback_grito() -> PackedFloat32Array:
	var rev := _hiss(0.3, 1500.0, 4000.0, 1.0)
	for i in rev.size():
		rev[i] *= float(i) / rev.size()
	# Arpegio de 0,195 s (4 × 0,03 + 3 × 0,025) para no pasar de los 0,5 s de la ficha.
	return _seq([[rev, 0.0], [_arpeggio([1046.5, 783.99, 659.25, 523.25], 0.03, 0.025), 0.3, 0.6]])


## Overclock: ventilador que acelera.
func _sig_aura_overclock() -> PackedFloat32Array:
	return _trem(_hiss(0.35, 800.0, 800.0, 0.3, 0.05), 10.0, 30.0, 0.85)


## N+2: dos clanks de placa.
func _sig_aura_blindaje() -> PackedFloat32Array:
	var clank := _seq([[_hiss(0.1, 2000.0, 2000.0, 0.03), 0.0, 0.6], [_note(420.0, 420.0, 0.1, 0.05), 0.0]])
	return _seq([[clank, 0.0], [clank, 0.12]])


## Mantenimiento: carraca de seis clics y un chime.
func _sig_aura_mantenimiento() -> PackedFloat32Array:
	var parts := []
	for k in 6:
		parts.append([_blip(3000.0, 0.006), k * 0.025, 0.7])
	parts.append([_note(1568.0, 1568.0, 0.3, 0.1), 0.16, 0.5])
	return _seq(parts)


## Mando: fanfarria de dos notas cuadradas.
func _sig_aura_mando() -> PackedFloat32Array:
	return _seq([[_note(783.99, 783.99, 0.1, 0.1, 1), 0.0], [_note(1046.5, 1046.5, 0.22, 0.12, 1), 0.1]])


## 429: tres bips graves y apagados.
func _sig_aura_throttling() -> PackedFloat32Array:
	var bip := _lowpass(_note(220.0, 220.0, 0.06, 0.05, 1), 700.0)
	return _seq([[bip, 0.0], [bip, 0.15], [bip, 0.3]])


## CVE: alerta de dos tonos y el escáner que barre.
func _sig_aura_exposicion() -> PackedFloat32Array:
	return _seq([[_blip(1200.0, 0.04), 0.0], [_blip(900.0, 0.04), 0.04], [_note(900.0, 2400.0, 0.2, 0.15), 0.09, 0.5]])


# Con efecto visual propio

## UDP: cinco clics de paquete, y faltan uno o dos.
func _sig_rafaga_de_paquetes() -> PackedFloat32Array:
	var lost := [rng.randi_range(1, 4)]
	if rng.randf() < 0.5:
		lost.append(rng.randi_range(0, 4))
	var parts := []
	for k in 5:
		if k not in lost:
			parts.append([_blip(1400.0, 0.008), k * 0.02])
	parts.append([_buf(0.1), 0.0])   # dura lo mismo aunque falte el último
	return _seq(parts)


## La tubería: zumbido cuadrado de 120 Hz apagado.
func _sig_pipe_de_datos() -> PackedFloat32Array:
	return _lowpass(_note(120.0, 120.0, 0.3, 0.2, 1), 900.0)


## Papeles que vuelan y el «ding» de un ticket nuevo.
func _sig_tormenta_tickets() -> PackedFloat32Array:
	var parts := []
	for k in 3:
		parts.append([_hiss(0.02, 4000.0, 4000.0, 0.012), k * 0.04 + rng.randf_range(0.0, 0.015), 0.8])
	parts.append([_note(1568.0, 1568.0, 0.25, 0.08), 0.15, 0.6])
	return _seq(parts)


## Ida y vuelta: aire que sube de tono y vuelve a bajar.
func _sig_rollback() -> PackedFloat32Array:
	var b := _buf(0.4)
	var f := 0.0
	for i in b.size():
		var t := float(i) / RATE
		var cut := 500.0 + 2500.0 * sin(PI * t / 0.4)
		f = _lp(f, _noise(), cut)
		b[i] = f * sqrt(RATE / (TAU * cut)) * 0.5 * (0.4 + 0.6 * absf(sin(TAU * t / 0.4)))
	return b


## while (true): cuatro vueltas cortas, un semitono más arriba cada una.
func _sig_bucle_infinito() -> PackedFloat32Array:
	var parts := []
	for k in 4:
		var c := 1200.0 * pow(2.0, k / 12.0)
		parts.append([_hiss(0.08, c, c * 1.6, 0.05, 0.01), k * 0.09])
	return _seq(parts)


## Tic-tac de la bomba al ponerla.
func _sig_bomba_logica() -> PackedFloat32Array:
	return _seq([[_clack(2000.0, 0.008), 0.0], [_clack(1500.0, 0.008), 0.12]])


## Rescate: candado que se cierra y la caja registradora.
func _sig_ransomware() -> PackedFloat32Array:
	return _seq([[_clack(3000.0), 0.0], [_blip(2500.0, 0.01), 0.005, 0.5],
		[_note(1568.0, 1568.0, 0.25, 0.08), 0.1, 0.6], [_note(2093.0, 2093.0, 0.25, 0.08), 0.1, 0.5]])


## Datos rotos: trozos de 15 ms a frecuencias al azar.
func _sig_corrupcion_datos() -> PackedFloat32Array:
	var parts := []
	for k in 10:
		var hz := rng.randf_range(50.0, 4000.0)
		parts.append([_note(hz, hz, 0.015, 1.0, 1), k * 0.015])
	return _seq(parts)


## Tracking: dos pips de radar.
func _sig_paquete_rastreador() -> PackedFloat32Array:
	var pip := _note(2000.0, 2000.0, 0.03, 0.015)
	return _seq([[pip, 0.0], [pip, 0.08]])


## Servo de la torreta y el clic de bloqueo.
func _sig_torreta_ci() -> PackedFloat32Array:
	return _seq([[_lowpass(_note(300.0, 500.0, 0.15, 0.2, 2), 2000.0), 0.0], [_clack(4000.0), 0.16]])


## Glug, glug: dos burbujas graves con vibrato.
func _sig_derrame_aceite() -> PackedFloat32Array:
	var glug := _buf(0.1)
	var ph := 0.0
	for i in glug.size():
		var t := float(i) / RATE
		ph += (180.0 + 60.0 * t / 0.1 + 15.0 * sin(TAU * 30.0 * t)) / RATE
		glug[i] = sin(TAU * ph) * _env(t, 0.005, 0.04)
	return _seq([[glug, 0.0], [glug, 0.15]])


## Estática: crepitar de picos al azar.
func _sig_campo_estatica() -> PackedFloat32Array:
	var parts := [[_hiss(0.3, 6000.0, 6000.0, 0.1), 0.0, 0.15]]
	for k in 14:
		var at := rng.randf_range(0.0, 0.28)
		parts.append([_clack(rng.randf_range(3000.0, 8000.0), 0.004), at, 1.0 - at / 0.3])
	return _seq(parts)


## Refrigerante: chorro y gorgoteo.
func _sig_charco_refrigerante() -> PackedFloat32Array:
	var parts := [[_hiss(0.3, 1200.0, 1200.0, 0.2, 0.02), 0.0, 0.7]]
	for k in 3:
		parts.append([_note(300.0 + k * 80.0, 500.0 + k * 80.0, 0.04, 0.02), 0.12 + k * 0.05, 0.5])
	return _seq(parts)


## Cascada: cinco clics que bajan (un !important tras otro).
func _sig_cascada_css() -> PackedFloat32Array:
	var parts := []
	var notes := [1568.0, 1396.9, 1174.7, 987.77, 783.99]
	for k in notes.size():
		parts.append([_blip(notes[k], 0.02), k * 0.05])
	return _seq(parts)


# Invocaciones

## fork(): dos clics iguales.
func _sig_proceso_hijo() -> PackedFloat32Array:
	return _seq([[_blip(1000.0), 0.0], [_blip(1000.0), 0.04], [_buf(0.1), 0.0]])   # 0,1 s como mínimo, como las demás


## Hélice de los drones.
func _sig_drones_vigilancia() -> PackedFloat32Array:
	return _lowpass(_trem(_note(180.0, 180.0, 0.4, 0.3, 2), 25.0, 25.0, 0.8), 2000.0)


## Servo y el «bip-bup» del centinela.
func _sig_robot_centinela() -> PackedFloat32Array:
	return _seq([[_lowpass(_note(300.0, 450.0, 0.1, 0.2, 2), 2000.0), 0.0],
		[_note(880.0, 880.0, 0.06, 0.08, 1), 0.11], [_note(1320.0, 1320.0, 0.06, 0.08, 1), 0.17]])


## Daemon: batido grave de dos sierras.
func _sig_daemon_segundo_plano() -> PackedFloat32Array:
	return _lowpass(_seq([[_note(110.0, 110.0, 0.3, 0.2, 2), 0.0], [_note(116.0, 116.0, 0.3, 0.2, 2), 0.0]]), 1200.0)


## Rotor del dron y el chasquido de la bengala.
func _sig_dron_escolta() -> PackedFloat32Array:
	var rotor := _lowpass(_trem(_note(150.0, 160.0, 0.25, 0.3, 2), 30.0, 30.0, 0.8), 1800.0)
	return _seq([[rotor, 0.0], [_hiss(0.15, 5000.0, 2000.0, 0.05), 0.2, 0.9]])


## Golem de chatarra: clanks y un ventilador viejo que arranca.
func _sig_golem_hardware() -> PackedFloat32Array:
	var clank := _seq([[_hiss(0.08, 2000.0, 2000.0, 0.03), 0.0, 0.6], [_note(350.0, 350.0, 0.08, 0.04), 0.0]])
	var fan := _trem(_hiss(0.35, 200.0, 1500.0, 1.0, 0.1), 6.0, 25.0, 0.6)
	return _seq([[clank, 0.0], [clank, 0.1, 0.8], [fan, 0.15, 0.6]])


## Mainframe: zumbido de 50 Hz y cinta.
func _sig_mainframe_titan() -> PackedFloat32Array:
	var hum := _lowpass(_note(50.0, 50.0, 0.5, 0.4, 1), 400.0)
	return _seq([[hum, 0.0, 1.5], [_trem(_hiss(0.5, 2500.0, 2500.0, 0.4, 0.05), 8.0, 8.0, 0.9), 0.0, 0.4]])


## Dron médico: chime suave de dos notas que suben.
func _sig_dron_medico() -> PackedFloat32Array:
	return _seq([[_note(1046.5, 1046.5, 0.2, 0.08), 0.0], [_note(1318.5, 1318.5, 0.3, 0.1), 0.08]])


## Cortafuegos portátil: clac de ladrillo y chime.
func _sig_dron_escudo() -> PackedFloat32Array:
	return _seq([[_clack(1500.0, 0.012), 0.0], [_note(659.25, 659.25, 0.3, 0.1), 0.03, 0.6]])


## Tests: el bip de PASS... y el de FAIL.
func _sig_bot_pruebas() -> PackedFloat32Array:
	return _seq([[_note(1320.0, 1320.0, 0.07, 0.06, 1), 0.0], [_note(330.0, 330.0, 0.12, 0.08, 1), 0.1]])


## Mina: tic-tac rápido y chirrido de ruedas.
func _sig_mina_rodante() -> PackedFloat32Array:
	var parts := []
	for k in 6:
		parts.append([_clack(2000.0 if k % 2 == 0 else 1500.0, 0.005), k * 0.04])
	var squeak := _buf(0.15)
	var ph := 0.0
	for i in squeak.size():
		var t := float(i) / RATE
		ph += (2200.0 + 150.0 * sin(TAU * 40.0 * t)) / RATE
		squeak[i] = sin(TAU * ph) * sin(PI * t / 0.15)
	parts.append([squeak, 0.25, 0.4])
	return _seq(parts)


## Agente IA: cuatro notas al azar de una pentatónica (muy seguro) y un glitch.
func _sig_agente_ia() -> PackedFloat32Array:
	var scale := [523.25, 587.33, 659.25, 783.99, 880.0, 1046.5]
	var notes := []
	for k in 4:
		notes.append(scale[rng.randi_range(0, scale.size() - 1)])
	return _seq([[_arpeggio(notes, 0.06, 0.04), 0.0, 0.7], [_bits(0.05, 3000.0, 0.03), 0.26, 0.8]])


## Watchdog: ladrido corto (sierra que cae con la boca de un paso bajo).
func _sig_watchdog() -> PackedFloat32Array:
	var bark := _seq([[_note(400.0, 280.0, 0.14, 0.06, 2), 0.0], [_hiss(0.06, 2500.0, 1200.0, 0.03), 0.0, 0.4]])
	return _lowpass(bark, 1600.0)


## Bot de bugs: zumbido de insecto.
func _sig_bot_rastreador() -> PackedFloat32Array:
	return _lowpass(_trem(_note(220.0, 230.0, 0.2, 0.2, 2), 60.0, 60.0, 0.7), 2500.0)


## Golem de silicio: golpe de cristal y un chime agudo.
func _sig_golem_silicio() -> PackedFloat32Array:
	return _seq([[_hit_crystal(), 0.0], [_note(3136.0, 3136.0, 0.25, 0.08), 0.08, 0.5]])


## Golem de overclock: ventilador que se acelera y chisporroteo.
func _sig_golem_overclock() -> PackedFloat32Array:
	var crackle := _buf(0.35)
	for i in crackle.size():
		crackle[i] = _noise() if rng.randf() < 0.02 else 0.0
	return _seq([[_trem(_hiss(0.35, 600.0, 1200.0, 0.3, 0.05), 8.0, 32.0, 0.85), 0.0], [crackle, 0.0, 0.5]])


## Golem UTP: latigazo y el clic del RJ45.
func _sig_golem_utp() -> PackedFloat32Array:
	return _seq([[_clack(6000.0, 0.003), 0.0], [_note(2000.0, 500.0, 0.06, 0.04, 2), 0.002], [_blip(2500.0, 0.008), 0.12, 0.8]])


## Golem GPU: pitido de bobina muy bajo sobre los ventiladores.
func _sig_golem_gpu() -> PackedFloat32Array:
	return _seq([[_trem(_hiss(0.4, 900.0, 900.0, 0.4, 0.05), 20.0, 20.0, 0.5), 0.0], [_note(8000.0, 8000.0, 0.4, 0.4), 0.0, 0.12]])


## Golem de kernel: zumbido grave de 55 Hz con glitch.
func _sig_golem_kernel() -> PackedFloat32Array:
	var hum := _lowpass(_note(55.0, 55.0, 0.4, 0.3, 2), 500.0)
	return _seq([[hum, 0.0, 1.6], [_bits(0.06, 1500.0, 0.04), 0.1, 0.5], [_bits(0.05, 3500.0, 0.03), 0.25, 0.4]])


# --- Habilidades nuevas (T208): van al final para no cambiar el azar de las de T196 ---

## Ticket Escalado: un sello seco (el juego le sube el tono en cada etapa).
func _sig_ticket_escalado() -> PackedFloat32Array:
	return _seq([[_clack(1200.0, 0.02), 0.0, 1.2], [_note(320.0, 260.0, 0.12, 0.06, 1), 0.01, 0.6]])


## Lazy Loading: clic suave de «placeholder» y dos puntitos de spinner.
func _sig_lazy_loading() -> PackedFloat32Array:
	return _seq([[_blip(900.0, 0.012), 0.0, 0.7], [_blip(1300.0, 0.01), 0.08, 0.5], [_blip(1300.0, 0.01), 0.16, 0.4]])


## Descenso de Gradiente: un rodar grave cuyo tono baja (bajando por la pendiente).
func _sig_descenso_gradiente() -> PackedFloat32Array:
	var roll := _lowpass(_note(220.0, 110.0, 0.35, 0.25, 2), 700.0)
	return _seq([[roll, 0.0, 1.2], [_hiss(0.3, 1500.0, 400.0, 0.2), 0.0, 0.5]])


# --- Ambientes (en bucle) ---

func _amb_base() -> PackedFloat32Array:
	return _buf(AMBIENT_SECONDS)


## Cantidad de sucesos sueltos (gotas, pitidos...) pensada para 6 s, escalada a la
## duración real del ambiente.
func _n(count_per_6s: int) -> int:
	return int(round(count_per_6s * AMBIENT_SECONDS / 6.0))


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
	for k in _n(count):
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
	for k in _n(14):   # burbujas
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
	for k in _n(8):   # ráfagas de glitch
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
	for k in _n(26):   # teclado
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


## Rack de servidores: zumbido eléctrico y ventilador, con algún pitido de disco.
func _emit_rack() -> PackedFloat32Array:
	var b := _amb_base()
	_add_drone(b, 120.0, 0.25, 0.0)
	_add_drone(b, 240.0, 0.08, 0.0)
	_add_wind(b, 0.3, 2200.0, 0.03)
	_add_pings(b, 5, 3000.0, 3400.0, 0.05, 0.03)
	return b


## Goteo de alcantarilla: gotas sueltas con eco sobre un rumor de agua muy bajo.
func _emit_drip() -> PackedFloat32Array:
	var b := _amb_base()
	_add_wind(b, 0.06, 400.0, 0.2)
	_add_pings(b, 16, 1500.0, 2600.0, 0.5, 0.12)
	return b


## Viento de grieta: ráfagas que suben y bajan.
func _emit_wind() -> PackedFloat32Array:
	var b := _amb_base()
	_add_wind(b, 0.9, 650.0, 0.18)
	_add_drone(b, 70.0, 0.04, 0.1)
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
	for k in _n(3):   # crujido de metal
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
	for k in _n(3):   # gaviotas
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
	for k in _n(9):   # el disco duro buscando sectores
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
	for k in _n(4):   # pitidos del POST
		var start := rng.randi_range(0, b.size() - 3000)
		for i in 2600:
			b[start + i] += _sq(i * 1000.0 / RATE) * 0.06 * (1.0 if i < 2200 else 0.0)
	return b


func _amb_rom() -> PackedFloat32Array:
	var b := _amb_base()
	_add_drone(b, 70.0, 0.14, 0.08)
	_add_pings(b, 10, 1800.0, 2900.0, 0.18, 0.22)   # cristales que resuenan
	return b


## Setup de la BIOS: zumbido de la fuente, ventilador y los pitidos del POST (uno largo y dos cortos).
func _amb_setup() -> PackedFloat32Array:
	var b := _amb_base()
	_add_drone(b, 50.0, 0.1, 0.0)
	_add_wind(b, 0.2, 1500.0, 0.04)
	for k in _n(3):
		var start := rng.randi_range(0, b.size() - 30000)
		for beep in [[0, 6000], [9000, 2200], [13000, 2200]]:
			for i in beep[1]:
				b[start + beep[0] + i] += _sq(i * 880.0 / RATE) * 0.05
	return b


## VGA de 16 colores: zumbido del monitor CRT (15,7 kHz, aquí más grave) y chirridos de módem.
func _amb_vga16() -> PackedFloat32Array:
	var b := _amb_base()
	_add_drone(b, 55.0, 0.1, 0.04)
	_add_pings(b, 12, 1200.0, 3200.0, 0.08, 0.05)
	_add_wind(b, 0.08, 2400.0, 0.3)
	return b


func _amb_flash() -> PackedFloat32Array:
	var b := _amb_base()
	_add_drone(b, 40.0, 0.3, 0.06)
	_add_thumps(b, 0.75, 55.0, 0.5)                  # latido de la escritura
	_add_wind(b, 0.15, 1400.0, 0.6)
	return b
