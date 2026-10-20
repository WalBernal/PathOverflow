class_name Ailments
## Estados alterados (como los de PoE): quemado, electrocutado, helado,
## congelado, envenenado y sangrando. Aquí solo están las reglas y los textos;
## los aplica EnemyManager al golpear (con el contexto que prepara
## SkillController a partir del perfil de SkillCalc) y los dibuja StatusIcon.

const BURN := "burn"
const SHOCK := "shock"
const CHILL := "chill"
const FREEZE := "freeze"
const POISON := "poison"
const BLEED := "bleed"
const ALL := [BURN, SHOCK, CHILL, FREEZE, POISON, BLEED]

const CHANCE_STAT := {
	BURN: Stat.BURN_CHANCE,
	SHOCK: Stat.SHOCK_CHANCE,
	CHILL: Stat.CHILL_CHANCE,
	FREEZE: Stat.FREEZE_CHANCE,
	POISON: Stat.POISON_CHANCE,
	BLEED: Stat.BLEED_CHANCE,
}
## Probabilidad innata según el tipo de daño: cada elemento "tiende" a su estado.
const INNATE := {
	"fire": {BURN: 10.0},
	"cold": {CHILL: 25.0},
	"lightning": {SHOCK: 10.0},
	"chaos": {POISON: 15.0},
	"physical": {BLEED: 5.0},
}
## Duración base (s), antes de "duración de estados alterados".
const DURATION := {BURN: 4.0, SHOCK: 3.0, CHILL: 2.5, FREEZE: 1.0, POISON: 3.0, BLEED: 4.0}
## Daño por segundo como fracción del golpe que lo aplicó.
const DOT_FRACTION := {BURN: 0.5, POISON: 0.25, BLEED: 0.3}
## Electrocutado: el enemigo recibe un 25 % más de daño (escala con el efecto).
const SHOCK_AMP := 0.25
## Helado: un 35 % más lento al moverse y atacar.
const CHILL_SLOW := 0.35
const POISON_MAX_STACKS := 10
## Sangrar mientras se mueve duele el doble.
const BLEED_MOVING_MULT := 2.0

## Textos e iconos (StatusIcon) de los estados, también los que no son
## "ailments" (aturdido, corrompido) y los del jugador.
const INFO := {
	BURN: {"name": "Quemado", "color": "e0652f", "desc": "Recibe daño de fuego por segundo."},
	SHOCK: {"name": "Electrocutado", "color": "e8d070", "desc": "Recibe un 25 % más de daño."},
	CHILL: {"name": "Helado", "color": "7fb8e0", "desc": "Se mueve y ataca un 35 % más lento."},
	FREEZE: {"name": "Congelado", "color": "bfe8ff", "desc": "No puede moverse ni atacar."},
	POISON: {"name": "Envenenado", "color": "6fd36b", "desc": "Daño de caos por segundo. Se acumula (hasta 10)."},
	BLEED: {"name": "Sangrando", "color": "c83232", "desc": "Daño físico por segundo; el doble si se mueve."},
	"stun": {"name": "Aturdido", "color": "c8c8d0", "desc": "Bloqueado: no hace nada."},
	"corrupt": {"name": "Corrompido", "color": "b04ad9", "desc": "Daño de caos por segundo."},
	"taunt": {"name": "Provocado", "color": "d9a441", "desc": "Solo tiene ojos para el golem."},
	"reserve": {"name": "Persistente", "color": "9ad0ff", "desc": "No caduca: reserva maná mientras siga en pie."},
}
## Daño degenerativo del jugador (Player.dots → kind) → estado que se muestra.
const PLAYER_DOT_STATUS := {"fire": BURN, "cold": CHILL, "lightning": SHOCK, "chaos": POISON}


static func display_name(id: String) -> String:
	return INFO.get(id, {}).get("name", id)


static func color(id: String) -> Color:
	return Color(INFO.get(id, {}).get("color", "c8c8c8"))


static func description(id: String) -> String:
	return INFO.get(id, {}).get("desc", "")


## Probabilidades (en %) de cada estado para una habilidad: innata por su tipo
## de daño + la propia de la habilidad (skills.json → ailments) + stats.
## Solo devuelve los que tienen probabilidad > 0.
static func chances(stats: StatBlock, tags: Array, skill: Dictionary) -> Dictionary:
	var result := {}
	if String(skill.get("damage_type", "none")) == "none":
		return result   # potenciadores, barreras y movimiento: no golpean
	var innate: Dictionary = INNATE.get(String(skill.get("damage_type", "none")), {})
	var own: Dictionary = skill.get("ailments", {})
	for id in ALL:
		var chance := float(innate.get(id, 0.0)) + float(own.get(id, 0.0)) + stats.get_value(CHANCE_STAT[id], tags)
		if chance > 0.0:
			result[id] = minf(100.0, chance)
	return result


## "25 % quemar · 10 % electrocutar" para tooltips.
static func describe_chances(chances_by_id: Dictionary) -> String:
	var verbs := {BURN: "quemar", SHOCK: "electrocutar", CHILL: "helar", FREEZE: "congelar", POISON: "envenenar", BLEED: "hacer sangrar"}
	var parts := PackedStringArray()
	for id in ALL:
		if chances_by_id.has(id):
			parts.append("%d %% %s" % [roundi(chances_by_id[id]), verbs[id]])
	return " · ".join(parts)
