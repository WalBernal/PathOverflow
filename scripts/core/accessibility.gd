class_name Accessibility
## Opciones de accesibilidad (Pausa → Interfaz):
## - Menos destellos: atenúa los fogonazos (golpes a jefes, cambios de fase, luz
##   de impactos), los glitches de las escenas y del prólogo, y apaga los parpadeos.
## - Tamaño del texto del mundo: nombres de enemigos y PNJ, etiquetas del botín y
##   avisos sobre el personaje, aparte del tamaño de la interfaz.
## - Paletas para daltonismo de auras y cargas: van con el «Modo daltónico» de
##   siempre (Ailments.colorblind), que ya cambiaba los estados alterados.

const WORLD_TEXT_SIZES := [0.8, 1.0, 1.25, 1.5]
## Cuánto queda de un destello con «menos destellos».
const REDUCED := 0.3
## Auras por tipo de daño, con la paleta Okabe-Ito (se distinguen con cualquier daltonismo).
const AURA_COLORBLIND := {
	"physical": "f0f0f0", "fire": "d55e00", "cold": "56b4e9", "lightning": "f0e442", "chaos": "cc79a7", "none": "009e73",
}

static var reduce_flashes := bool(GameSettings.get_value("interface", "reduce_flashes", false))
static var world_text := float(GameSettings.get_value("interface", "world_text", 1.0))
## Reducir movimiento (T97): sin rebotes ni saltos en la interfaz ni en los números de daño.
static var reduce_motion := bool(GameSettings.get_value("interface", "reduce_motion", false))


static func set_reduce_motion(on: bool) -> void:
	reduce_motion = on
	GameSettings.set_value("interface", "reduce_motion", on)


static func set_reduce_flashes(on: bool) -> void:
	reduce_flashes = on
	GameSettings.set_value("interface", "reduce_flashes", on)


static func set_world_text(scale: float) -> void:
	world_text = scale
	GameSettings.set_value("interface", "world_text", scale)


## Intensidad de un destello (0-1 o más) con la opción aplicada.
static func flash(value: float) -> float:
	return value * REDUCED if reduce_flashes else value


## false con «menos destellos»: lo que parpadea se queda fijo.
static func can_blink() -> bool:
	return not reduce_flashes


## Zoom de la cámara en partida (T156, lo pone Player.apply_world_zoom).
static var world_zoom := 1.0


## Tamaño de letra del texto del mundo. Con el tamaño del mundo (T158) la letra no
## crece tanto como el dibujo: en pantalla, √zoom (al 130 %, un 14 % más) y no el zoom
## entero, para que nombres, números y etiquetas no se pisen ni tapen la pelea.
static func world_size(base: int) -> int:
	return maxi(6, roundi(base * world_text / sqrt(maxf(world_zoom, 1.0))))


## Tamaño en píxeles de pantalla (del lienzo) de un texto del mundo de tamaño `base`.
static func world_size_on_screen(base: int) -> float:
	return world_size(base) * maxf(world_zoom, 1.0)


static func aura_color(damage_type: String, normal: Color) -> Color:
	if Ailments.colorblind and AURA_COLORBLIND.has(damage_type):
		return Color(AURA_COLORBLIND[damage_type])
	return normal
