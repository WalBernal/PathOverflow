class_name Builds
## Construcciones guardadas: el árbol pasivo (nodos y maestrías) y qué habilidad
## va en cada ranura de la barra. Se guardan con el personaje (flags["builds"]) y
## al cargarlas se reasignan los puntos gratis (en el árbol se puede devolver
## cualquier nodo sin coste) y se colocan en la barra las placas que tengas, de la
## barra o de la bolsa.

const FLAG := "builds"
const MAX_BUILDS := 8


static func list(c: CharacterData) -> Array:
	var raw = c.flags.get(FLAG, [])
	return raw if raw is Array else []


## Lo que hay ahora: {name, passives, masteries, hotbar: [id de habilidad o ""]}.
static func capture(c: CharacterData, build_name: String) -> Dictionary:
	var ids: Array = []
	for id in c.passives.get_allocated_ids():
		if id != c.passives.start_node_id:
			ids.append(id)
	ids.sort()
	var hotbar: Array = []
	for b in c.inventory.boards:
		hotbar.append(String((b as Motherboard).skill_def["id"]) if b else "")
	return {"name": build_name, "passives": ids, "masteries": c.passives.mastery_choices_dict(), "hotbar": hotbar}


## Guarda (o sustituye, si ya hay una con ese nombre) la construcción actual.
## Devuelve "" o el motivo por el que no se pudo.
static func save(c: CharacterData, build_name: String) -> String:
	build_name = build_name.strip_edges()
	if build_name == "":
		return "Ponle un nombre a la construcción."
	var builds := list(c).filter(func(b: Dictionary) -> bool: return b["name"] != build_name)
	if builds.size() >= MAX_BUILDS:
		return "Ya tienes %d construcciones guardadas: borra alguna." % MAX_BUILDS
	builds.append(capture(c, build_name))
	c.flags[FLAG] = builds
	return ""


static func delete(c: CharacterData, build_name: String) -> void:
	c.flags[FLAG] = list(c).filter(func(b: Dictionary) -> bool: return b["name"] != build_name)


## Carga una construcción. Devuelve {error, missing_skills, dropped_nodes}: con
## error no se cambia nada (faltan puntos, bolsa llena...).
static func apply(c: CharacterData, build: Dictionary) -> Dictionary:
	var result := {"error": "", "missing_skills": [], "dropped_nodes": 0}
	var ids: Array = build.get("passives", [])
	if ids.size() > c.passive_points_total():
		result["error"] = "Esa construcción usa %d puntos y tienes %d." % [ids.size(), c.passive_points_total()]
		return result
	# Barra: para cada ranura, la placa de esa habilidad de más nivel que quede libre.
	var inv := c.inventory
	var hotbar: Array = build.get("hotbar", [])
	var chosen: Array = []          # placa elegida por ranura (o null = se queda la que haya)
	var taken := {}                 # placas ya elegidas
	for i in Inventory.HOTBAR_SIZE:
		var want: String = hotbar[i] if i < hotbar.size() else ""
		var best: Motherboard = null
		if want != "":
			for b in inv.boards + inv.bag:
				if b is Motherboard and not taken.has(b) and String(b.skill_def["id"]) == want and (best == null or b.level > best.level):
					best = b
			if best == null:
				result["missing_skills"].append(want)
		if best:
			taken[best] = true
		chosen.append(best)
	# Las ranuras sin placa elegida conservan la suya si nadie se la ha llevado.
	for i in Inventory.HOTBAR_SIZE:
		var current: Motherboard = inv.boards[i]
		if chosen[i] == null and current and not taken.has(current):
			chosen[i] = current
			taken[current] = true
	var leftover: Array = inv.boards.filter(func(b) -> bool: return b != null and not taken.has(b))
	var free := inv.bag.count(null) + inv.bag.filter(func(b) -> bool: return b != null and taken.has(b)).size()
	if leftover.size() > free:
		result["error"] = "No caben en la bolsa las placas que salen de la barra."
		return result
	for k in inv.bag.size():
		if inv.bag[k] != null and taken.has(inv.bag[k]):
			inv.bag[k] = null
	for b in leftover:
		inv.bag[inv.bag.find(null)] = b
	for i in Inventory.HOTBAR_SIZE:
		inv.boards[i] = chosen[i]
	var masteries = build.get("masteries", {})
	c.passives.load_mastery_choices(masteries if masteries is Dictionary else {})
	result["dropped_nodes"] = c.passives.load_ids(ids)
	inv.changed.emit()
	c.recalculate()
	return result


## Filas para comparar dos placas: [{label, a, b, better}] con better = 0 (la A),
## 1 (la B) o -1 (empate o no comparable). Los textos ya vienen formateados.
static func compare_boards(a: Dictionary, b: Dictionary) -> Array:
	var rows: Array = []
	var add := func(label: String, va: float, vb: float, fmt: String, higher_better := true) -> void:
		if va == 0.0 and vb == 0.0:
			return
		var better := -1
		if not is_equal_approx(va, vb):
			better = 0 if (va > vb) == higher_better else 1
		rows.append({"label": label, "a": fmt % va, "b": fmt % vb, "better": better})
	add.call("DPS aproximado", a["dps"], b["dps"], "%.0f")
	add.call("Daño por golpe", (a["min_damage"] + a["max_damage"]) / 2.0, (b["min_damage"] + b["max_damage"]) / 2.0, "%.0f")
	add.call("Usos por segundo", a["uses_per_second"], b["uses_per_second"], "%.2f")
	add.call("Crítico (%)", a["crit_chance"], b["crit_chance"], "%.1f")
	add.call("Coste de maná", a["mana_cost"], b["mana_cost"], "%.0f", false)
	add.call("Reserva de maná (%)", a["reserve"], b["reserve"], "%.0f", false)
	add.call("Área (radio)", a["radius"], b["radius"], "%.0f")
	add.call("Proyectiles", float(a["projectiles"]), float(b["projectiles"]), "%.0f")
	add.call("Enfriamiento (s)", a["cooldown"], b["cooldown"], "%.1f", false)
	add.call("Duración (s)", a["duration"], b["duration"], "%.1f")
	return rows
