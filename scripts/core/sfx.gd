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


## Efecto al lanzar una habilidad, según su tipo y su daño principal.
static func skill_sound(kind: String, damage_type := "") -> String:
	match kind:
		"melee_area", "spin", "dash", "charge":
			return "swing"
		"blink", "ssh", "backflip":
			return "blink"
		"buff":
			return "buff"
		"barrier":
			return "barrier"
		"minion", "drones":
			return "summon"
		"trap", "mine", "totem":
			return "trap"
		"ground_aoe", "nova":
			if damage_type == "fire":
				return "explosion"
	match damage_type:
		"fire":
			return "fire"
		"cold":
			return "cold"
		"lightning":
			return "lightning"
		"chaos":
			return "chaos"
	return "projectile"


## Archivo de ambiente para un estilo de zona ("" = silencio).
static func ambient_for(style: String) -> String:
	if style == "":
		return ""
	var s: String = AMBIENT_ALIASES.get(style, style)
	return s if ResourceLoader.exists(AMB_DIR + s + ".wav") else "ruins"


static func _manager() -> Node:
	var tree := Engine.get_main_loop() as SceneTree
	return tree.root.get_node_or_null("AudioManager") if tree else null
