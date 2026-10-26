class_name StatExplain
## De dónde sale cada número de la hoja de personaje (T81): el desglose por origen
## de un stat, para los tooltips, y el DPS de cada habilidad de la barra.


## Una línea por habilidad de la barra con su tecla y su DPS (las de apoyo, sin DPS, con lo que hacen).
static func hotbar_dps_lines(sc: SkillController) -> Array[String]:
	var out: Array[String] = []
	if sc == null:
		return out
	for i in SkillController.ACTIONS.size():
		var p := sc.profile(i)
		if p.is_empty():
			continue
		var key := Controls.key_label(SkillController.ACTIONS[i])
		var dps := float(p.get("dps", 0.0))
		out.append("  [%s] %s:  %s" % [key, p["name"], ("%.1f DPS" % dps) if dps > 0.0 else "apoyo (sin daño directo)"])
	return out


## Tooltip de dónde sale un número (T81): base, cada origen (clase, árbol, objetos,
## auras, cargas…) con su plano, su aumento y su multiplicador, y el total.
static func explain(stats: StatBlock, stat: StringName, title: String, total_text := "", tags: Array = []) -> String:
	var lines := PackedStringArray()
	var b := stats.get_breakdown(stat, tags)
	lines.append("%s: %s" % [title, total_text if total_text != "" else Modifier._fmt(stats.get_value(stat, tags))])
	if float(b["base"]) != 0.0:
		lines.append("  Base (clase y nivel): %s" % Modifier._fmt(b["base"]))
	for r in stats.source_breakdown(stat, tags):
		var parts := PackedStringArray()
		if float(r["flat"]) != 0.0:
			parts.append("%+d" % roundi(r["flat"]) if absf(r["flat"]) >= 1.0 else "%+.1f" % r["flat"])
		if float(r["increased"]) != 0.0:
			parts.append("%+d %%" % roundi(r["increased"]))
		if not is_equal_approx(float(r["more"]), 1.0):
			parts.append("×%.2f" % r["more"])
		if not parts.is_empty():
			lines.append("  %s: %s" % [r["group"], "  ".join(parts)])
	if lines.size() == 1:
		lines.append("  (nada lo modifica todavía)")
	elif float(b["increased"]) != 0.0 or not is_equal_approx(float(b["more"]), 1.0):
		lines.append("  = (base + planos) × %+d %% aumentado × %.2f más" % [roundi(b["increased"]), b["more"]])
	return "\n".join(lines)
