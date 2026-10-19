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


## Efecto al lanzar una habilidad, según su tipo y su daño principal.
static func skill_sound(kind: String, damage_type := "") -> String:
	match kind:
		"melee_area", "spin", "dash":
			return "swing"
		"blink":
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
