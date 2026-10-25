class_name TechDebt
## Árbol de deuda técnica (fin de juego): se abre al terminar el Acto IV. Cada nodo
## da un bono fuerte y una penalización que te llevas con él. Tres ramas de cuatro
## nodos que salen de la raíz; cada nodo pide el anterior de su rama.
##
## Puntos: 1 al abrirlo, +1 por nivel del atlas y +1 por cada 5 oleadas de tu
## récord del banco (hasta MAX_WAVE_POINTS). Quitar un nodo es gratis («pagar la
## deuda»), pero solo si nada que tengas depende de él. Se guarda en flags.tech_debt.

const FLAG := "tech_debt"
const UNLOCK_FLAG := "act4_complete"
const MAX_WAVE_POINTS := 5
const WAVES_PER_POINT := 5

## {id, name, branch, requires, bonus: [mods], penalty: [mods]}. requires = "" es la raíz.
const NODES := [
	{"id": "commit_directo", "name": "Commit directo a main", "branch": "", "requires": "",
		"bonus": [{"stat": "damage", "type": "increased", "value": 20}], "penalty": [{"stat": "life", "type": "increased", "value": -5}]},
	# Hotfix: daño a costa de aguante.
	{"id": "hotfix", "name": "Hotfix en producción", "branch": "hotfix", "requires": "commit_directo",
		"bonus": [{"stat": "damage", "type": "increased", "value": 30}], "penalty": [{"stat": "life", "type": "increased", "value": -15}]},
	{"id": "sin_review", "name": "Sin code review", "branch": "hotfix", "requires": "hotfix",
		"bonus": [{"stat": "crit_chance", "type": "increased", "value": 50}], "penalty": [{"stat": "evasion", "type": "increased", "value": -25}, {"stat": "armour", "type": "increased", "value": -25}]},
	{"id": "optimizacion_prematura", "name": "Optimización prematura", "branch": "hotfix", "requires": "sin_review",
		"bonus": [{"stat": "attack_speed", "type": "increased", "value": 15}, {"stat": "cast_speed", "type": "increased", "value": 15}], "penalty": [{"stat": "mana", "type": "increased", "value": -25}]},
	{"id": "reescribir", "name": "Reescribirlo desde cero", "branch": "hotfix", "requires": "optimizacion_prematura",
		"bonus": [{"stat": "damage", "type": "more", "value": 25}], "penalty": [{"stat": "life", "type": "more", "value": -20}]},
	# Legacy: aguante a costa de daño y ritmo.
	{"id": "legacy", "name": "Código legacy que funciona", "branch": "legacy", "requires": "commit_directo",
		"bonus": [{"stat": "life", "type": "increased", "value": 25}], "penalty": [{"stat": "movement_speed", "type": "increased", "value": -8}]},
	{"id": "no_lo_toques", "name": "No lo toques", "branch": "legacy", "requires": "legacy",
		"bonus": [{"stat": "armour", "type": "increased", "value": 50}, {"stat": "evasion", "type": "increased", "value": 50}], "penalty": [{"stat": "attack_speed", "type": "increased", "value": -10}, {"stat": "cast_speed", "type": "increased", "value": -10}]},
	{"id": "try_catch_vacio", "name": "try/catch vacío", "branch": "legacy", "requires": "no_lo_toques",
		"bonus": [{"stat": "energy_shield", "type": "increased", "value": 50}, {"stat": "life_regen", "type": "flat", "value": 20}], "penalty": [{"stat": "crit_chance", "type": "increased", "value": -40}]},
	{"id": "monolito", "name": "El monolito", "branch": "legacy", "requires": "try_catch_vacio",
		"bonus": [{"stat": "fire_res", "type": "flat", "value": 20}, {"stat": "cold_res", "type": "flat", "value": 20}, {"stat": "lightning_res", "type": "flat", "value": 20}, {"stat": "chaos_res", "type": "flat", "value": 20}],
		"penalty": [{"stat": "damage", "type": "more", "value": -15}]},
	# Deadline: velocidad a costa de precisión y defensas.
	{"id": "viernes", "name": "Deploy el viernes", "branch": "deadline", "requires": "commit_directo",
		"bonus": [{"stat": "movement_speed", "type": "increased", "value": 15}], "penalty": [{"stat": "fire_res", "type": "flat", "value": -10}, {"stat": "cold_res", "type": "flat", "value": -10}, {"stat": "lightning_res", "type": "flat", "value": -10}]},
	{"id": "stack_overflow", "name": "Copiado de Stack Overflow", "branch": "deadline", "requires": "viernes",
		"bonus": [{"stat": "area_of_effect", "type": "increased", "value": 30}], "penalty": [{"stat": "accuracy", "type": "increased", "value": -25}]},
	{"id": "parche_sobre_parche", "name": "Parche sobre parche", "branch": "deadline", "requires": "stack_overflow",
		"bonus": [{"stat": "cooldown_recovery", "type": "increased", "value": 25}], "penalty": [{"stat": "skill_duration", "type": "increased", "value": -20}]},
	{"id": "crunch", "name": "Crunch", "branch": "deadline", "requires": "parche_sobre_parche",
		"bonus": [{"stat": "attack_speed", "type": "increased", "value": 20}, {"stat": "cast_speed", "type": "increased", "value": 20}, {"stat": "movement_speed", "type": "increased", "value": 10}],
		"penalty": [{"stat": "life", "type": "increased", "value": -15}, {"stat": "mana_regen", "type": "increased", "value": -30}]},
]
const BRANCHES := {"hotfix": "Hotfix (daño)", "legacy": "Legacy (aguante)", "deadline": "Deadline (velocidad)"}


static func node(id: String) -> Dictionary:
	for n in NODES:
		if n["id"] == id:
			return n
	return {}


static func unlocked(c: CharacterData) -> bool:
	return c.flags.has(UNLOCK_FLAG)


static func allocated(c: CharacterData) -> Array:
	var a = c.flags.get(FLAG, [])
	return a if a is Array else []


static func total_points(c: CharacterData) -> int:
	if not unlocked(c):
		return 0
	var waves := int(c.flags.get("ladder", {}).get("best_wave", 0))
	return 1 + Atlas.tier(c) + mini(MAX_WAVE_POINTS, waves / WAVES_PER_POINT)


static func free_points(c: CharacterData) -> int:
	return total_points(c) - allocated(c).size()


static func can_allocate(c: CharacterData, id: String) -> bool:
	var n := node(id)
	if n.is_empty() or allocated(c).has(id) or free_points(c) <= 0:
		return false
	return n["requires"] == "" or allocated(c).has(n["requires"])


## Se puede quitar si ningún nodo que tengas lo pide.
static func can_refund(c: CharacterData, id: String) -> bool:
	if not allocated(c).has(id):
		return false
	for other in allocated(c):
		if node(other).get("requires", "") == id:
			return false
	return true


static func allocate(c: CharacterData, id: String) -> bool:
	if not can_allocate(c, id):
		return false
	var a := allocated(c).duplicate()
	a.append(id)
	c.flags[FLAG] = a
	c.recalculate()
	return true


static func refund(c: CharacterData, id: String) -> bool:
	if not can_refund(c, id):
		return false
	var a := allocated(c).duplicate()
	a.erase(id)
	c.flags[FLAG] = a
	c.recalculate()
	return true


## Mods de todos los nodos asignados (bonos y penalizaciones). Si los puntos
## bajaran (no debería), solo cuentan los primeros que caben.
static func modifiers(c: CharacterData) -> Array[Modifier]:
	var out: Array[Modifier] = []
	var a := allocated(c)
	for i in mini(a.size(), total_points(c)):
		var n := node(String(a[i]))
		for md in n.get("bonus", []) + n.get("penalty", []):
			out.append(Modifier.from_dict(md, "tech_debt"))
	return out


static func describe(id: String) -> String:
	var n := node(id)
	var lines := PackedStringArray()
	for md in n.get("bonus", []):
		lines.append("Bono: " + Modifier.from_dict(md).describe())
	for md in n.get("penalty", []):
		lines.append("Precio: " + Modifier.from_dict(md).describe())
	return "\n".join(lines)
