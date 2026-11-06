class_name Sfx
## Acceso al sonido desde cualquier script: busca el autoload AudioManager y,
## si no está (pruebas sin escena, herramientas), no hace nada.

const SFX_DIR := "res://assets/audio/sfx/"
const AMB_DIR := "res://assets/audio/ambient/"
## Estilos de zona sin ambiente propio → ambiente que usan.
const AMBIENT_ALIASES := {"town": "camp", "camp2": "camp", "socket": "camp", "hub": "camp"}


static func play(sfx_name: String, volume := 0.0, pitch := 1.0) -> void:
	var m := _manager()
	if m:
		m.play_sfx(sfx_name, volume, pitch)


static func ambient(style: String) -> void:
	var m := _manager()
	if m:
		m.play_ambient(style)


static func refresh_settings() -> void:
	var m := _manager()
	if m:
		m.refresh_settings()


static func sfx_enabled() -> bool:
	return bool(GameSettings.get_value("audio", "sfx", true))


static func ambient_enabled() -> bool:
	return bool(GameSettings.get_value("audio", "ambient", true))


## Volumen de los efectos (0..1); 0 si están apagados.
static func sfx_volume() -> float:
	return clampf(float(GameSettings.get_value("audio", "sfx_volume", 1.0)), 0.0, 1.0) if sfx_enabled() else 0.0


## Volumen del ambiente de las zonas (0..1); 0 si está apagado.
static func ambient_volume() -> float:
	return clampf(float(GameSettings.get_value("audio", "ambient_volume", 1.0)), 0.0, 1.0) if ambient_enabled() else 0.0


## Guarda el volumen de un canal ("sfx" o "ambient"); 0 equivale a apagarlo.
static func set_volume(channel: String, value: float) -> void:
	GameSettings.set_value("audio", channel + "_volume", clampf(value, 0.0, 1.0))
	GameSettings.set_value("audio", channel, value > 0.001)
	refresh_settings()


## Frecuencia de la música de zona (tools/generate_zone_music.gd): music_loops.json
## guarda el inicio de cada bucle en muestras a esta frecuencia.
const MUSIC_RATE := 16000
## Frecuencia de los ambientes y del tema del título (generate_sfx.gd, generate_music.gd).
const AMBIENT_RATE := 22050


## Ruta del audio `base` (sin extensión): la música, los ambientes y el tema del
## título van en OGG (tools/convert_audio.ps1); los efectos cortos, en WAV. "" si no hay.
static func audio_path(base: String) -> String:
	for ext in [".ogg", ".wav"]:
		if ResourceLoader.exists(base + ext):
			return base + ext
	return ""


## Carga `base` (OGG o WAV) en bucle desde `begin` muestras a `rate` Hz hasta el final.
static func load_looped(base: String, begin := 0, rate := AMBIENT_RATE) -> AudioStream:
	var path := audio_path(base)
	if path == "":
		return null
	var stream = load(path)
	if stream is AudioStreamOggVorbis:
		(stream as AudioStreamOggVorbis).loop = true
		(stream as AudioStreamOggVorbis).loop_offset = begin / float(rate)
	elif stream is AudioStreamWAV:
		set_loop(stream as AudioStreamWAV, int(round(begin * (stream as AudioStreamWAV).mix_rate / float(rate))))
	return stream


## Muestras de un .wav importado. No vale data.size() / 2: Godot los importa
## comprimidos (QOA) y `data` no es PCM de 16 bits.
static func frame_count(wav: AudioStreamWAV) -> int:
	return int(round(wav.get_length() * wav.mix_rate))


## Pone un .wav en bucle desde `begin` (en muestras) hasta el final.
static func set_loop(wav: AudioStreamWAV, begin := 0) -> void:
	var frames := frame_count(wav)
	wav.loop_mode = AudioStreamWAV.LOOP_FORWARD
	wav.loop_begin = clampi(begin, 0, maxi(0, frames - 1))
	wav.loop_end = frames


## Sonido al lanzar de los tipos que suenan igual sea cual sea su daño (T192):
## cuerpo a cuerpo y saltos, movimientos, buffs, invocaciones, trampas y auras
## (el aura suena una sola vez al encenderla, con aura_on).
const KIND_SOUNDS := {
	"melee_area": "swing", "spin": "swing", "dash": "swing", "charge": "swing", "leap_slam": "swing", "ticket": "swing",
	"blink": "blink", "ssh": "blink", "backflip": "blink",
	"buff": "buff", "barrier": "barrier", "aura": "aura_on", "breakpoint": "barrier",
	"minion": "summon", "drones": "summon", "unit": "summon", "canary": "summon", "charm": "summon",
	"trap": "trap",
}
## Tipos que suenan a su daño (fuego, frío, rayo o caos) → lo que suenan si son
## físicos o sin tipo: los proyectiles, a disparo; las áreas, a golpe (thump); el
## cono físico (Fuzzing), a tajo.
const DAMAGE_KINDS := {
	"projectile": "projectile", "homing": "projectile", "boomerang": "projectile", "dot_projectile": "projectile",
	"rain": "projectile", "chain": "projectile", "beam": "projectile",
	"channel_beam": "projectile", "channel_storm": "projectile", "lazy": "projectile", "gradient": "projectile",
	"ground_aoe": "thump", "nova": "thump", "terrain": "thump", "degen_area": "thump", "curse_area": "thump",
	"cone": "swing",
}
const ELEMENT_SOUNDS := {"fire": "fire", "cold": "cold", "lightning": "lightning", "chaos": "chaos"}
## Lo que suena un tipo que no está en ninguna de las dos tablas.
const DEFAULT_SKILL_SOUND := "projectile"


## ¿Tiene `kind` sonido propio al lanzar (no cae en DEFAULT_SKILL_SOUND)?
static func has_skill_sound(kind: String) -> bool:
	return KIND_SOUNDS.has(kind) or DAMAGE_KINDS.has(kind)


## Efecto al lanzar una habilidad, según su tipo y su daño principal.
static func skill_sound(kind: String, damage_type := "") -> String:
	if KIND_SOUNDS.has(kind):
		return String(KIND_SOUNDS[kind])
	if not DAMAGE_KINDS.has(kind):
		return DEFAULT_SKILL_SOUND
	if damage_type == "fire" and kind in ["ground_aoe", "nova"]:
		return "explosion"
	return String(ELEMENT_SOUNDS.get(damage_type, DAMAGE_KINDS[kind]))


## Archivo de ambiente para un estilo de zona ("" = silencio).
static func ambient_for(style: String) -> String:
	if style == "":
		return ""
	var s: String = AMBIENT_ALIASES.get(style, style)
	return s if audio_path(AMB_DIR + s) != "" else "ruins"


static func _manager() -> Node:
	var tree := Engine.get_main_loop() as SceneTree
	return tree.root.get_node_or_null("AudioManager") if tree else null
