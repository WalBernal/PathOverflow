class_name RetroSfx
## Sonidos 8 bits generados en código (sin archivos): el "pitido" de los
## diálogos mientras se escribe el texto. Onda cuadrada con envolvente corta.

const MIX_RATE := 22050

static var _blip: AudioStreamWAV


## Pitido corto (~45 ms). El tono de cada NPC se cambia con pitch_scale al reproducirlo.
static func blip() -> AudioStreamWAV:
	if _blip:
		return _blip
	var samples := int(MIX_RATE * 0.045)
	var data := PackedByteArray()
	data.resize(samples * 2)
	var freq := 660.0
	for i in samples:
		var t := float(i) / MIX_RATE
		var square := 1.0 if fmod(t * freq, 1.0) < 0.5 else -1.0
		# Un poco de la octava de arriba para que suene más a consola.
		square = square * 0.75 + (1.0 if fmod(t * freq * 2.0, 1.0) < 0.5 else -1.0) * 0.25
		var envelope := minf(1.0, i / 60.0) * pow(1.0 - float(i) / samples, 2.0)
		data.encode_s16(i * 2, int(square * envelope * 9000.0))
	_blip = AudioStreamWAV.new()
	_blip.format = AudioStreamWAV.FORMAT_16_BITS
	_blip.mix_rate = MIX_RATE
	_blip.stereo = false
	_blip.data = data
	return _blip
