class_name StatusIcon
## Iconos de estados alterados y efectos (quemado, electrocutado, helado,
## congelado, envenenado, sangrando, aturdido, corrompido...), dibujados con
## formas como SkillIcon. Los nombres y colores salen de Ailments.INFO.
## Se usan sobre los enemigos, en el marco del objetivo y en el HUD del jugador.


## `compact`: para tamaños pequeños (sobre los enemigos): menos detalle.
static func draw(ci: CanvasItem, rect: Rect2, id: String, compact := false, alpha := 1.0) -> void:
	var color := Ailments.color(id)
	color.a = alpha
	var c := rect.get_center()
	var r := minf(rect.size.x, rect.size.y) * 0.5
	# Placa: fondo oscuro, borde del color del estado y un brillo arriba.
	ci.draw_rect(rect, Color(0.05, 0.04, 0.07, 0.85 * alpha))
	ci.draw_rect(Rect2(rect.position, Vector2(rect.size.x, rect.size.y * 0.45)), Color(color, 0.18 * alpha))
	ci.draw_rect(rect, color, false, 1.0 if compact else 1.5)
	var g := r * 0.78   # radio del glifo
	var w := maxf(1.0, r * (0.22 if compact else 0.16))
	match id:
		Ailments.BURN:
			ci.draw_colored_polygon(PackedVector2Array([c + Vector2(0, -g), c + Vector2(g * 0.7, g * 0.1), c + Vector2(g * 0.5, g * 0.8),
				c + Vector2(-g * 0.5, g * 0.8), c + Vector2(-g * 0.7, g * 0.1), c + Vector2(-g * 0.25, -g * 0.35)]), color)
			ci.draw_colored_polygon(PackedVector2Array([c + Vector2(0.05 * g, -g * 0.25), c + Vector2(g * 0.4, g * 0.45), c + Vector2(g * 0.25, g * 0.8),
				c + Vector2(-g * 0.25, g * 0.8), c + Vector2(-g * 0.35, g * 0.4)]), Color(1.0, 0.85, 0.3, alpha))
		Ailments.SHOCK:
			ci.draw_colored_polygon(PackedVector2Array([c + Vector2(g * 0.25, -g), c + Vector2(-g * 0.55, g * 0.15), c + Vector2(-g * 0.05, g * 0.15),
				c + Vector2(-g * 0.3, g), c + Vector2(g * 0.6, -g * 0.2), c + Vector2(g * 0.08, -g * 0.2)]), color)
		Ailments.CHILL:
			for k in 3:
				var d := Vector2.from_angle(PI / 3.0 * k + PI / 2.0) * g
				ci.draw_line(c - d, c + d, color, w, true)
			if not compact:
				for k in 6:
					var tip := c + Vector2.from_angle(PI / 3.0 * k + PI / 2.0) * g * 0.6
					ci.draw_circle(tip, w * 0.8, color.lightened(0.3))
		Ailments.FREEZE:
			var hexagon := PackedVector2Array()
			for k in 6:
				hexagon.append(c + Vector2.from_angle(TAU * k / 6.0 + PI / 6.0) * g)
			ci.draw_colored_polygon(hexagon, Color(color, 0.55 * alpha))
			hexagon.append(hexagon[0])
			ci.draw_polyline(hexagon, Color(1, 1, 1, alpha), w, true)
			ci.draw_line(c + Vector2(-g * 0.4, -g * 0.1), c + Vector2(g * 0.1, -g * 0.55), Color(1, 1, 1, 0.9 * alpha), w, true)
		Ailments.POISON:
			# Gota con una calavera mínima.
			ci.draw_colored_polygon(PackedVector2Array([c + Vector2(0, -g), c + Vector2(g * 0.6, g * 0.05), c + Vector2(-g * 0.6, g * 0.05)]), color)
			ci.draw_circle(c + Vector2(0, g * 0.3), g * 0.62, color)
			if not compact:
				ci.draw_circle(c + Vector2(-g * 0.22, g * 0.25), g * 0.13, Color(0.05, 0.15, 0.05, alpha))
				ci.draw_circle(c + Vector2(g * 0.22, g * 0.25), g * 0.13, Color(0.05, 0.15, 0.05, alpha))
		Ailments.BLEED:
			ci.draw_colored_polygon(PackedVector2Array([c + Vector2(-g * 0.35, -g), c + Vector2(g * 0.15, -g * 0.1), c + Vector2(-g * 0.75, -g * 0.1)]), color)
			ci.draw_circle(c + Vector2(-g * 0.3, g * 0.1), g * 0.46, color)
			ci.draw_colored_polygon(PackedVector2Array([c + Vector2(g * 0.45, -g * 0.35), c + Vector2(g * 0.8, g * 0.3), c + Vector2(g * 0.1, g * 0.3)]), color.darkened(0.15))
			ci.draw_circle(c + Vector2(g * 0.45, g * 0.45), g * 0.36, color.darkened(0.15))
			ci.draw_circle(c + Vector2(-g * 0.45, -g * 0.05), g * 0.12, Color(1, 0.6, 0.6, 0.8 * alpha))
		"stun":
			ci.draw_rect(Rect2(c + Vector2(-g * 0.6, -g * 0.05), Vector2(g * 1.2, g * 0.95)), color)
			ci.draw_arc(c + Vector2(0, -g * 0.05), g * 0.42, PI, TAU, 10, color, w * 1.3, true)
			ci.draw_circle(c + Vector2(0, g * 0.4), g * 0.13, Color(0.1, 0.1, 0.15, alpha))
		"corrupt":
			ci.draw_circle(c, g * 0.55, color)
			for k in 3:
				ci.draw_rect(Rect2(c + Vector2(-g + k * g * 0.35, -g * 0.7 + k * g * 0.5), Vector2(g * 0.9, g * 0.22)), Color(0.3, 1.0, 0.6, 0.85 * alpha))
		"taunt":
			ci.draw_rect(Rect2(c + Vector2(-w, -g * 0.85), Vector2(w * 2.0, g * 1.1)), color)
			ci.draw_circle(c + Vector2(0, g * 0.65), w * 1.2, color)
		"reserve":
			# Infinito: invocación persistente (reserva maná en vez de durar).
			ci.draw_arc(c + Vector2(-g * 0.42, 0), g * 0.42, 0.0, TAU, 16, color, w, true)
			ci.draw_arc(c + Vector2(g * 0.42, 0), g * 0.42, 0.0, TAU, 16, color, w, true)
		_:
			ci.draw_circle(c, g * 0.5, color)


## Texto de ayuda: "Quemado (3 s): Recibe daño de fuego por segundo."
static func tooltip(id: String, time := -1.0, stacks := 0) -> String:
	var text := Ailments.display_name(id)
	if stacks > 1:
		text += " ×%d" % stacks
	if time >= 0.0:
		text += " (%.1f s)" % time
	return "%s: %s" % [text, Ailments.description(id)]
