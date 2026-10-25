class_name Companions
## Acompañantes: un NPC del hub del Acto IV que decide venir contigo (acción de
## diálogo "companion"). Te sigue por las zonas de combate (en el hub se queda en
## su sitio) y te da un bono pequeño mientras te acompaña. Uno a la vez.
## flags["companion"] = id del NPC; flags["companion_<id>"] para las opciones de diálogo.

const FLAG := "companion"
const DEFS := {
	"mario_bios": {"name": "Mario", "text": "Mario corre detrás de ti para acabar antes las horas: +8 % de velocidad de movimiento.",
		"mods": [{"stat": "movement_speed", "type": "increased", "value": 8}]},
	"paez_bios": {"name": "M. Páez", "text": "M. Páez te calcula los ángulos: +15 % de probabilidad de crítico.",
		"mods": [{"stat": "crit_chance", "type": "increased", "value": 15}]},
	"eugenio_bios": {"name": "Eugenio", "text": "Eugenio te comparte su café (6/10): +6 de regeneración de vida.",
		"mods": [{"stat": "life_regen", "type": "flat", "value": 6}]},
}


static func current(c: CharacterData) -> String:
	return String(c.flags.get(FLAG, "")) if c else ""


## Cambia de acompañante ("" = ninguno) y aplica su bono.
static func choose(c: CharacterData, id: String) -> void:
	for other in DEFS:
		c.flags.erase("companion_" + other)
	if DEFS.has(id):
		c.flags[FLAG] = id
		c.flags["companion_" + id] = true
	else:
		c.flags.erase(FLAG)
	apply(c)


## Pone (o quita) el bono del acompañante como efecto sin caducidad.
static func apply(c: CharacterData) -> void:
	for other in DEFS:
		if other != current(c):
			c.remove_timed_effect("companion:" + other)
	var id := current(c)
	if DEFS.has(id):
		var mods: Array[Modifier] = []
		for md in DEFS[id]["mods"]:
			mods.append(Modifier.from_dict(md, "companion:" + id))
		c.set_timed_effect("companion:" + id, mods)
