class_name DeathDump
## Texto de la pantalla de muerte (T168) como un volcado de error: la excepción, la pila
## de llamadas con una broma al final y qué hacer para reaparecer. BBCode para el
## RichTextLabel de GameUI, con la monoespaciada de UiStyle.

static func text(zone_name: String, level: int, touch: bool) -> String:
	var muted := UiStyle.MUTED_HEX
	var lines := PackedStringArray([
		"[color=#f85149][b]FATAL[/b] ProcesoTerminado: integridad = 0[/color]",
		"[color=#%s]  en Player.take_damage()  (player.gd)[/color]" % muted,
		"[color=#%s]  en Enemy.attack()  (%s)[/color]" % [muted, zone_name if zone_name != "" else "zona desconocida"],
		"[color=#%s]  en tu_decision_de_ir_sin_resistencias()  (???)[/color]" % muted,
		"",
		"[color=#%s]nivel %d · core dumped · las partidas siguen a salvo[/color]" % [muted, level],
	])
	if not touch:
		lines.append("")
		lines.append("[color=#%s]> pulsa R para reaparecer en el campamento_[/color]" % UiStyle.ACCENT_HEX)
	return "\n".join(lines)
