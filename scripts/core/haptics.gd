class_name Haptics
## Vibración del celular (T143): un pulso corto al recibir un golpe fuerte, hacer un
## crítico, subir de nivel, caer un único y pulsar un botón táctil. Solo en el celular
## (en el PC Input.vibrate_handheld no hace nada) y si no se apagó en Pausa → Combate.
## Entre pulsos hay un respiro (GAP) para que una lluvia de críticos no zumbe sin parar;
## los importantes (nivel, único) pasan siempre.

## [milisegundos, intensidad 0-1] de cada causa.
const PULSES := {
	"hit": [45, 0.8],
	"crit": [18, 0.35],
	"level": [120, 1.0],
	"unique": [90, 1.0],
	"button": [10, 0.25],
	"ready": [8, 0.2],   # una habilidad vuelve a estar lista (T148)
}
const IMPORTANT := ["level", "unique"]
const GAP := 0.12

static var _last := -10.0
## Último pulso pedido (para las pruebas): [causa, ms] o [].
static var last_pulse: Array = []


static func enabled() -> bool:
	return bool(GameSettings.get_value("combat", "vibration", true))


static func set_enabled(on: bool) -> void:
	GameSettings.set_value("combat", "vibration", on)


## ¿Vibraría ahora por `kind`? (encendida, en el celular o forzada, y sin pisar el respiro).
static func would_pulse(kind: String, now: float) -> bool:
	if not PULSES.has(kind) or not enabled() or not (GameSettings.is_mobile() or Touch.force):
		return false
	return IMPORTANT.has(kind) or now - _last >= GAP


static func pulse(kind: String) -> void:
	var now := Time.get_ticks_msec() / 1000.0
	if not would_pulse(kind, now):
		return
	_last = now
	var p: Array = PULSES[kind]
	last_pulse = [kind, int(p[0])]
	Input.vibrate_handheld(int(p[0]), float(p[1]))
