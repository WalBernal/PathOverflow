extends SceneTree
## Genera docs/habilidades_y_ram.md: todas las placas base (habilidades) y los
## módulos RAM (asistencias), con lo que hace cada uno y sus etiquetas. Las
## invocaciones incluyen su comportamiento y sus habilidades propias; las auras,
## su alcance y sus efectos. Las cifras son las de una placa de nivel 1 para un
## personaje de nivel 1 (crecen con el nivel de la placa).
##
## Uso:  Godot_v4.7.2-stable_win64_console.exe --headless --path . -s res://tools/list_skills.gd

const OUT := "res://docs/habilidades_y_ram.md"
const KIND_NAMES := {
	"melee_area": "golpe en área", "nova": "nova a tu alrededor", "projectile": "proyectiles", "ground_aoe": "explosión en el suelo",
	"blink": "teletransporte", "dash": "embestida", "cone": "cono", "beam": "rayo en línea", "boomerang": "bumerán",
	"spin": "giro continuo", "trap": "trampa", "chain": "cadena", "minion": "esbirros temporales", "degen_area": "charco degenerativo",
	"barrier": "barrera", "buff": "potenciador", "curse_area": "maldición en área", "dot_projectile": "proyectil degenerativo",
	"homing": "proyectiles teledirigidos", "drones": "drones temporales", "leap_slam": "salto y golpe", "rain": "lluvia de impactos",
	"unit": "invocación persistente", "aura": "aura persistente",
	"ssh": "teletransporte con descarga", "charge": "carga con empuje", "backflip": "salto atrás con zona helada",
}
const BEHAVIOR_NAMES := {
	"melee": "cuerpo a cuerpo: persigue al enemigo más cercano",
	"ranged": "a distancia: se queda a tu lado y dispara",
	"orbit": "dron que orbita a tu alrededor (no se le puede dañar)",
	"tank": "tanque: golpea en área y provoca a los enemigos",
}
const ATTR := {"str": "Fuerza (DDR3)", "dex": "Destreza (DDR4)", "int": "Inteligencia (DDR5)"}
const DAMAGE_NAMES := {"physical": "físico", "fire": "fuego", "cold": "frío", "lightning": "rayo", "chaos": "caos", "none": "sin daño"}


func _initialize() -> void:
	var db := ItemDatabase.load_from_dir()
	var tree := PassiveTree.load_from_json("res://data/passive_tree.json")
	var classes: Array = DataLoader.load_json("res://data/classes.json")["classes"]
	var ch := CharacterData.new(classes[0], tree)
	var unlocks := {}   # skill -> ["Guerrero (nv. 5)", ...]
	var starters := {}
	for c in classes:
		for u in c.get("unlocks", []):
			var choice: Array = u.get("choice", [])
			for sid in (choice if not choice.is_empty() else [u["skill"]]):
				unlocks[sid] = unlocks.get(sid, []) + ["%s (nv. %d%s)" % [c["name"], int(u["level"]), ", a elegir" if not choice.is_empty() else ""]]
		for s in c.get("starter_skills", []):
			starters[s] = starters.get(s, []) + [c["name"]]
	var md := PackedStringArray()
	md.append("# Habilidades (placas base) y asistencias (módulos RAM)")
	md.append("")
	md.append("Generado con `tools/list_skills.gd` a partir de `data/skills/`. Cifras de una placa de nivel 1: el daño, el área y la duración crecen con el nivel de la placa, y en los niveles 10, 20 y 30 cada habilidad gana su bonificación de hito.")
	md.append("")
	var groups := [["Ataques y hechizos", func(s: Dictionary) -> bool: return not (s["kind"] in ["unit", "aura", "minion", "drones"])],
		["Invocaciones", func(s: Dictionary) -> bool: return s["kind"] in ["unit", "minion", "drones"]],
		["Auras", func(s: Dictionary) -> bool: return s["kind"] == "aura"]]
	for g in groups:
		md.append("## %s" % g[0])
		md.append("")
		var list: Array = db.skills.skills.values().filter(g[1])
		list.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a["name"] < b["name"])
		for s in list:
			_skill(md, s, SkillCalc.compute(Motherboard.new(s, 1, []), ch), unlocks, starters)
	md.append("## Módulos RAM (asistencias)")
	md.append("")
	md.append("Cada RAM encaja en una ranura de su generación (DDR3 rojo, DDR4 verde, DDR5 azul) y solo funciona con las habilidades que cumplen sus etiquetas. Las de grado *menor* y *mayor* son la misma familia con más o menos efecto. Una RAM que solo mejora el daño no encaja en habilidades sin daño.")
	md.append("")
	var rams: Array = db.skills.rams.values()
	rams.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return "%s|%d" % [RamModule.family_of(a["id"]), int(a.get("tier", 2))] < "%s|%d" % [RamModule.family_of(b["id"]), int(b.get("tier", 2))])
	for r in rams:
		_ram(md, RamModule.new(r), db)
	var f := FileAccess.open(OUT, FileAccess.WRITE)
	f.store_string("\n".join(md) + "\n")
	print("Escrito %s (%d habilidades, %d RAM)" % [OUT, db.skills.skills.size(), rams.size()])
	quit()


func _skill(md: PackedStringArray, s: Dictionary, p: Dictionary, unlocks: Dictionary, starters: Dictionary) -> void:
	md.append("### %s" % s["name"])
	md.append("")
	md.append("*%s* · %s · daño: %s · %s" % [KIND_NAMES.get(s["kind"], s["kind"]), ATTR.get(s.get("attribute", ""), "—"),
		DAMAGE_NAMES.get(s.get("damage_type", "none"), s.get("damage_type", "")), "ataque (usa el arma)" if s.has("attack") else "hechizo"])
	md.append("")
	md.append(String(s.get("description", "")))
	md.append("")
	md.append("- **Etiquetas:** %s" % SkillTags.plain(s.get("tags", [])))
	var facts := PackedStringArray()
	if p["kind"] in ["unit", "aura"]:
		facts.append("reserva %d %% del maná" % roundi(p["reserve"]))
	elif p["mana_cost"] > 0:
		facts.append("maná %d" % int(p["mana_cost"]))
	if p["cooldown"] > 0.0:
		facts.append("enfriamiento %.1f s" % p["cooldown"])
	if p["max_damage"] > 0.0:
		facts.append("daño %.0f-%.0f%s" % [p["min_damage"], p["max_damage"], " por segundo" if s["kind"] in ["degen_area", "curse_area", "dot_projectile", "backflip"] else ""])
	if p["projectiles"] > 0:
		facts.append("%d proyectil%s%s" % [p["projectiles"], "es" if p["projectiles"] > 1 else "", " teledirigidos" if p["homing"] else ""])
	if p["radius"] > 0.0:
		facts.append("radio %.0f" % p["radius"])
	if p["duration"] > 0.0:
		facts.append("dura %.1f s" % p["duration"])
	if p["chains"] > 0:
		facts.append("%d saltos de cadena" % p["chains"])
	if p["stun"] > 0.0:
		facts.append("aturde %.1f s" % p["stun"])
	if not facts.is_empty():
		md.append("- **Cifras:** %s" % ", ".join(facts))
	var ailments: Dictionary = s.get("ailments", {})
	if not ailments.is_empty():
		var parts := PackedStringArray()
		for id in ailments:
			parts.append("%s %d %%" % [Ailments.display_name(id).to_lower(), int(ailments[id])])
		md.append("- **Estados extra:** %s" % ", ".join(parts))
	md.append("- **Hito (niveles 10, 20, 30):** %s" % SkillCalc.milestone_text(s))
	if s["kind"] == "unit":
		var u: Dictionary = s["unit"]
		md.append("- **Comportamiento:** %s; hasta %d a la vez; vida %.0f; ataca cada %.1f s; alcance %d%s" % [
			BEHAVIOR_NAMES.get(u.get("behavior", ""), u.get("behavior", "")), p["max_units"], p["unit_life"],
			p["unit_interval"], int(u.get("range", 0)), "" if p["unit_shoots"] or u.get("behavior", "") != "orbit" else "; no dispara"])
		if float(u.get("reduction", 0.0)) > 0.0:
			md.append("- **Defensa:** recibe un %d %% menos de daño" % roundi(float(u["reduction"]) * 100.0))
		if float(u.get("taunt", 0.0)) > 0.0:
			md.append("- **Provoca** a los enemigos a %d de distancia (te los quita de encima)" % int(u["taunt"]))
		var ab: Dictionary = u.get("ability", {})
		if not ab.is_empty():
			md.append("- **Habilidad propia:** %s" % _ability(ab, p))
	if s["kind"] == "minion":
		md.append("- **Invoca:** %d esbirros que duran %.0f s y golpean cada %.1f s" % [p["count"], p["duration"], p["minion_interval"]])
	if s["kind"] == "drones":
		md.append("- **Invoca:** %d drones que te orbitan %.0f s y disparan cada %.1f s al enemigo más cercano" % [p["drone_count"], p["duration"], p["tick"]])
	if s["kind"] == "aura":
		var effects := PackedStringArray()
		for md_dict in p["aura_mods"]:
			effects.append(Modifier.from_dict(md_dict).describe())
		if p["aura_regen"] > 0.0:
			effects.append("tus invocaciones recuperan un %.1f %% de vida por segundo" % p["aura_regen"])
		if p["aura_reduction"] > 0.0:
			effects.append("tus invocaciones reciben un %d %% menos de daño" % roundi(p["aura_reduction"] * 100.0))
		var en: Dictionary = p["aura_enemy"]
		if float(en.get("slow", 0.0)) > 0.0:
			effects.append("los enemigos dentro se mueven y atacan un %d %% más lento" % roundi(float(en["slow"]) * 100.0))
		if float(en.get("damage_taken", 0.0)) > 0.0:
			effects.append("los enemigos dentro reciben un %d %% más de daño" % roundi(float(en["damage_taken"]) * 100.0))
		md.append("- **Alcance:** %.0f alrededor de ti (las invocaciones fuera no reciben sus bonos)" % p["aura_radius"])
		md.append("- **Efectos:** %s" % "; ".join(effects))
	if starters.has(s["id"]):
		md.append("- **Inicial de:** %s" % ", ".join(starters[s["id"]]))
	if unlocks.has(s["id"]):
		md.append("- **Se desbloquea con:** %s" % ", ".join(unlocks[s["id"]]))
	md.append("")


func _ability(ab: Dictionary, p: Dictionary) -> String:
	match String(ab.get("kind", "")):
		"heal":
			return "repara: cada %.1f s te cura un %d %% de tu vida y a tus invocaciones un %d %% de la suya" % [p["unit_interval"], int(ab.get("player_pct", 5)), int(ab.get("unit_pct", 10))]
		"barrier":
			return "cada %.1f s (si no tienes barrera) te da una barrera de %d + %d %% de tu vida máxima durante 6 s" % [p["unit_interval"], int(ab.get("barrier", 20)), roundi(float(ab.get("barrier_life", 0.1)) * 100.0)]
		"leap":
			return "cada %.0f s salta sobre el enemigo más lejano a su alcance y golpea el suelo (radio %d, ×%.1f de daño)" % [float(ab.get("cooldown", 5.0)), int(ab.get("radius", 75)), float(ab.get("damage_mult", 1.5))]
		"venom":
			return "cada %.0f s escupe un charco venenoso (radio %d, %.0f s) sobre el enemigo más cercano" % [float(ab.get("cooldown", 7.0)), int(ab.get("radius", 95)), float(ab.get("duration", 4.0))]
		"explode":
			return "kamikaze: al tocar a un enemigo (o al caer) explota en un radio de %d" % int(ab.get("radius", 90))
	return str(ab)


func _ram(md: PackedStringArray, ram: RamModule, db: ItemDatabase) -> void:
	var tier_names := {1: "menor", 2: "normal", 3: "mayor"}
	md.append("### %s" % ram.def.get("name", "?"))
	md.append("")
	md.append("*%s* · grado %s · cae desde el nivel %d" % [ram.generation(), tier_names.get(ram.tier(), "normal"), int(ram.def.get("min_level", 1))])
	md.append("")
	md.append(String(ram.def.get("description", "")))
	md.append("")
	md.append("- **Efectos:** %s" % "; ".join(ram.effect_lines()))
	var req: Array = ram.def.get("requires_tags", [])
	var req_all: Array = ram.def.get("requires_all_tags", [])
	var exc: Array = ram.def.get("excludes_tags", [])
	var parts := PackedStringArray()
	if not req.is_empty():
		parts.append("con alguna de: %s" % SkillTags.plain(req))
	if not req_all.is_empty():
		parts.append("que además sea: %s" % SkillTags.plain(req_all))
	if not exc.is_empty():
		parts.append("nunca con: %s" % SkillTags.plain(exc))
	if not ram.def.get("excludes_kinds", []).is_empty():
		parts.append("no en: %s" % ", ".join(ram.def["excludes_kinds"].map(func(k: String) -> String: return KIND_NAMES.get(k, k))))
	md.append("- **Etiquetas:** %s" % ("cualquier habilidad" if parts.is_empty() else "; ".join(parts)))
	var fits := PackedStringArray()
	for sid in db.skills.skills:
		if ram.supports(db.skills.skills[sid]):
			fits.append(db.skills.skills[sid]["name"])
	fits.sort()
	md.append("- **Funciona con (%d):** %s" % [fits.size(), ", ".join(fits)])
	md.append("")
