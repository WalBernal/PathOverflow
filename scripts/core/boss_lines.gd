class_name BossLines
## Los jefes hablan durante el combate (T224): una frase al despertar, una al entrar en
## cada fase y una con poca vida, con su voz grabada (audio/voces/jefe_<tipo>_<momento>.ogg)
## y un subtítulo breve bajo su barra. No detienen el juego ni tapan el combate.

## Vida (fracción) por debajo de la cual dice su frase de «poca vida».
const LOW_LIFE := 0.15

## Tipo de enemigo del jefe (act*.json → boss.type) → frases.
const LINES := {
	"daemon": {
		"start": "¿Otro refactor? Llevo veinte años diciendo que esto no se toca.",
		"phases": ["Si tanto quieres refactorizar... ¡empieza por ti!", "Cada parche que puse... ¡te lo cobro ahora, con intereses!"],
		"low": "No... sin mí... el Monolito... se cae...",
	},
	"init": {
		"start": "Proceso huérfano detectado. Procedo a adoptarte... a la fuerza.",
		"phases": ["fork... fork... fork... ¡Hijos míos, despierten!", "Memoria insuficiente. Alguien tiene que morir... y no seré yo."],
		"low": "Soy el PID 1... no pueden... matarme...",
	},
	"fw_update": {
		"start": "Descargando actualización. No apague el equipo. No se mueva. No respire.",
		"phases": ["Borrando sectores. Los suyos incluidos.", "Noventa y nueve por ciento. Noventa y nueve por ciento. Noventa y nueve por ciento."],
		"low": "Error... de escritura... ¿Reintentar... o cancelar...?",
	},
	"admin": {
		"start": "Acceso concedido. Como siempre. A todos. Incluido tú.",
		"phases": ["sudo. sudo. sudo. Nadie me ha dicho que no en veinte años.", "Me quedo. Siempre me quedo. Soy el valor por defecto."],
		"low": "Nadie... me cambió... la contraseña...",
	},
}


static func has_boss(boss_type: String) -> bool:
	return LINES.has(boss_type)


## Momentos: "start", "fase1", "fase2"... y "low".
static func id_for(boss_type: String, moment: String) -> String:
	return "jefe_%s_%s" % [boss_type, moment]


static func text_for(boss_type: String, moment: String) -> String:
	var d: Dictionary = LINES.get(boss_type, {})
	if moment.begins_with("fase"):
		var phases: Array = d.get("phases", [])
		var k := int(moment.substr(4)) - 1
		return String(phases[k]) if k >= 0 and k < phases.size() else ""
	return String(d.get(moment, ""))


## Todos los momentos de un jefe, en orden.
static func moments(boss_type: String) -> Array:
	var out := ["start"]
	for k in (LINES.get(boss_type, {}).get("phases", []) as Array).size():
		out.append("fase%d" % (k + 1))
	out.append("low")
	return out


## Qué momento toca ahora (o "" si ninguno): `said` son los ya dichos de este jefe,
## `phase` la fase en la que acaba de entrar (0 = ninguna nueva), `frac` su vida.
static func due(boss_type: String, said: Dictionary, phase: int, frac: float) -> String:
	if not has_boss(boss_type):
		return ""
	if not said.has("start"):
		return "start"
	if phase > 0 and not said.has("fase%d" % phase) and text_for(boss_type, "fase%d" % phase) != "":
		return "fase%d" % phase
	if frac <= LOW_LIFE and not said.has("low"):
		return "low"
	return ""
