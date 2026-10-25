class_name Charges
extends RefCounted
## Cargas temporales (como las de aguante, frenesí y poder de PoE):
## - Buffer (aguante): se gana al recibir un golpe; da armadura y resistencias.
## - Multihilos (frenesí): se gana al matar; da velocidad de ataque, lanzamiento y movimiento.
## - Overclock (poder): se gana al hacer un crítico; da probabilidad de crítico y daño.
## Duran DURATION s (cada carga nueva renueva el tiempo de las de su tipo) y se
## pierden todas juntas. Máximo: 3 + 1 por cada 50 del atributo de su color
## (Fuerza, Destreza, Inteligencia) + "max_<tipo>_charges". Las gastan las RAM
## con "spend_<tipo>" (ver SkillController._spend_charges).

const TYPES := ["buffer", "multihilo", "overclock"]
const NAMES := {"buffer": "Buffer", "multihilo": "Multihilos", "overclock": "Overclock"}
const COLORS := {"buffer": Color("e0a050"), "multihilo": Color("6ad07a"), "overclock": Color("6aa8ff")}
## Con el modo daltónico: bermellón, amarillo y celeste (también distintos en brillo).
const COLORBLIND_COLORS := {"buffer": Color("d55e00"), "multihilo": Color("f0e442"), "overclock": Color("56b4e9")}
const DURATION := 10.0
const BASE_MAX := 3
const ATTR_STEP := 50.0
const ATTRS := {"buffer": &"strength", "multihilo": &"dexterity", "overclock": &"intelligence"}
## Probabilidad base de ganarla (al recibir un golpe / al matar / al hacer crítico).
const BASE_CHANCE := {"buffer": 20.0, "multihilo": 15.0, "overclock": 10.0}
const TRIGGERS := {"buffer": "al recibir un golpe", "multihilo": "al matar", "overclock": "al hacer un crítico"}
## Lo que da cada carga.
const PER_CHARGE := {
	"buffer": [{"stat": "armour", "type": "increased", "value": 12}, {"stat": "fire_res", "type": "flat", "value": 4},
		{"stat": "cold_res", "type": "flat", "value": 4}, {"stat": "lightning_res", "type": "flat", "value": 4}],
	"multihilo": [{"stat": "attack_speed", "type": "increased", "value": 4}, {"stat": "cast_speed", "type": "increased", "value": 4},
		{"stat": "movement_speed", "type": "increased", "value": 3}],
	"overclock": [{"stat": "crit_chance", "type": "increased", "value": 35}, {"stat": "damage", "type": "increased", "value": 5}],
}
## Lo que hace gastarlas (con una RAM "spend_<tipo>"), por carga.
const SPEND_TEXT := {
	"buffer": "Gasta tus cargas de Buffer: 6 % de vida y 10 % más de daño por carga",
	"multihilo": "Gasta tus cargas de Multihilos: 15 % más de daño por carga",
	"overclock": "Gasta tus cargas de Overclock: crítico seguro y +20 % de multiplicador de crítico por carga",
}


static func color(t: String) -> Color:
	return COLORBLIND_COLORS[t] if Ailments.colorblind else COLORS[t]


static func chance_stat(t: String) -> StringName:
	return StringName(t + "_charge_chance")


static func max_stat(t: String) -> StringName:
	return StringName("max_" + t + "_charges")


static func mods_for(t: String, count: int) -> Array[Modifier]:
	var out: Array[Modifier] = []
	for md: Dictionary in PER_CHARGE[t]:
		var scaled := md.duplicate()
		scaled["value"] = float(md["value"]) * count
		out.append(Modifier.from_dict(scaled, "charge:" + t))
	return out
