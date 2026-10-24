class_name SkillIcon
## Iconos provisionales de habilidades dibujados con formas (hasta tener arte).
## La forma y el color salen de skills.json → icon.


static func draw(ci: CanvasItem, rect: Rect2, skill_def: Dictionary, dimmed := false) -> void:
	var icon: Dictionary = skill_def.get("icon", {})
	var color := Color(icon.get("color", "c8c8c8"))
	if dimmed:
		color = color.darkened(0.55)
	var c := rect.get_center()
	var r := minf(rect.size.x, rect.size.y) * 0.34
	_draw_backdrop(ci, rect, color, dimmed)
	match icon.get("shape", ""):
		"medic":
			# Dron con cruz de reparación.
			for k in 4:
				var arm := Vector2.from_angle(PI / 4.0 + PI / 2.0 * k) * r * 0.85
				ci.draw_line(c, c + arm, Color("8a8a96"), 2.0, true)
				ci.draw_circle(c + arm, r * 0.22, Color(0.85, 0.9, 0.85, 0.35))
			ci.draw_circle(c, r * 0.5, Color("e8f0e8"))
			ci.draw_rect(Rect2(c + Vector2(-r * 0.12, -r * 0.34), Vector2(r * 0.24, r * 0.68)), color)
			ci.draw_rect(Rect2(c + Vector2(-r * 0.34, -r * 0.12), Vector2(r * 0.68, r * 0.24)), color)
		"shielddrone":
			ci.draw_arc(c + Vector2(0, -r * 0.05), r * 0.95, PI * 1.05, PI * 1.95, 14, color, 3.0, true)
			ci.draw_arc(c + Vector2(0, -r * 0.05), r * 0.65, PI * 1.1, PI * 1.9, 12, Color(color, 0.6), 2.0, true)
			ci.draw_rect(Rect2(c + Vector2(-r * 0.4, r * 0.1), Vector2(r * 0.8, r * 0.4)), Color("3a3f4a"))
			ci.draw_circle(c + Vector2(0, r * 0.3), r * 0.12, color)
			for s in [-1.0, 1.0]:
				ci.draw_line(c + Vector2(s * r * 0.4, r * 0.2), c + Vector2(s * r * 0.8, r * 0.05), Color("8a8a96"), 2.0)
		"testbot":
			# Muñeco de pruebas con una flecha de salto.
			ci.draw_circle(c + Vector2(0, -r * 0.45), r * 0.32, Color("e8d9b0"))
			ci.draw_rect(Rect2(c + Vector2(-r * 0.3, -r * 0.1), Vector2(r * 0.6, r * 0.7)), color.darkened(0.2))
			ci.draw_line(c + Vector2(-r * 0.2, r * 0.6), c + Vector2(-r * 0.35, r), Color("8a8a96"), 2.5)
			ci.draw_line(c + Vector2(r * 0.2, r * 0.6), c + Vector2(r * 0.35, r), Color("8a8a96"), 2.5)
			ci.draw_arc(c + Vector2(r * 0.3, 0), r * 0.7, PI * 1.2, PI * 1.9, 10, Color(color, 0.8), 2.0, true)
			ci.draw_rect(Rect2(c + Vector2(-r * 0.15, -r * 0.5), Vector2(r * 0.1, r * 0.08)), Color("1a1620"))
			ci.draw_rect(Rect2(c + Vector2(r * 0.05, -r * 0.5), Vector2(r * 0.1, r * 0.08)), Color("1a1620"))
		"wheelbomb":
			ci.draw_circle(c + Vector2(0, -r * 0.05), r * 0.62, Color("2a2a30"))
			ci.draw_circle(c + Vector2(-r * 0.2, -r * 0.25), r * 0.14, Color("5a5a66"))
			ci.draw_line(c + Vector2(r * 0.25, -r * 0.55), c + Vector2(r * 0.6, -r * 0.95), Color("8a6d3b"), 2.0, true)
			ci.draw_circle(c + Vector2(r * 0.65, -r * 1.0), r * 0.16, Color("ffd84a"))
			for s in [-1.0, 1.0]:
				ci.draw_circle(c + Vector2(s * r * 0.4, r * 0.75), r * 0.22, Color("5a5a66"))
				ci.draw_circle(c + Vector2(s * r * 0.4, r * 0.75), r * 0.08, color)
		"agent":
			ci.draw_circle(c, r * 0.65, Color("2a1f3a"))
			ci.draw_arc(c, r * 0.65, 0.0, TAU, 20, color, 2.5, true)
			ci.draw_circle(c + Vector2(-r * 0.22, -r * 0.1), r * 0.12, Color("3cff9a"))
			ci.draw_circle(c + Vector2(r * 0.22, -r * 0.1), r * 0.12, Color("3cff9a"))
			ci.draw_arc(c + Vector2(0, r * 0.15), r * 0.28, 0.2, PI - 0.2, 8, Color("3cff9a"), 2.0, true)
			for k in 3:
				ci.draw_circle(c + Vector2(r * (0.5 + 0.18 * k), -r * (0.75 + 0.1 * k)), r * (0.08 + 0.03 * k), Color(color, 0.8))
		"aura_clock", "aura_shield", "aura_cross", "aura_flag":
			# Aros de aura con un símbolo en el centro.
			ci.draw_arc(c, r * 1.0, 0.0, TAU, 28, Color(color, 0.5), 2.0, true)
			ci.draw_arc(c, r * 0.78, 0.4, TAU - 0.4, 24, Color(color, 0.8), 2.0, true)
			match icon.get("shape", ""):
				"aura_clock":
					ci.draw_line(c, c + Vector2(0, -r * 0.5), color, 2.5, true)
					ci.draw_line(c, c + Vector2(r * 0.35, r * 0.15), color, 2.5, true)
					ci.draw_circle(c, r * 0.1, Color.WHITE)
				"aura_shield":
					ci.draw_colored_polygon(PackedVector2Array([c + Vector2(-r * 0.4, -r * 0.4), c + Vector2(r * 0.4, -r * 0.4), c + Vector2(r * 0.35, r * 0.1), c + Vector2(0, r * 0.55), c + Vector2(-r * 0.35, r * 0.1)]), color)
				"aura_cross":
					ci.draw_rect(Rect2(c + Vector2(-r * 0.12, -r * 0.45), Vector2(r * 0.24, r * 0.9)), color)
					ci.draw_rect(Rect2(c + Vector2(-r * 0.45, -r * 0.12), Vector2(r * 0.9, r * 0.24)), color)
				"aura_flag":
					ci.draw_line(c + Vector2(-r * 0.3, r * 0.55), c + Vector2(-r * 0.3, -r * 0.5), Color("c8c8c8"), 2.0, true)
					ci.draw_colored_polygon(PackedVector2Array([c + Vector2(-r * 0.3, -r * 0.5), c + Vector2(r * 0.5, -r * 0.3), c + Vector2(-r * 0.3, -r * 0.05)]), color)
		"leap":
			# Arco de salto que termina en un impacto.
			ci.draw_arc(c + Vector2(-r * 0.1, r * 0.35), r * 0.85, PI * 1.05, PI * 1.85, 14, Color(color, 0.7), 3.0, true)
			ci.draw_colored_polygon(PackedVector2Array([c + Vector2(r * 0.55, -r * 0.2), c + Vector2(r * 0.95, -r * 0.05), c + Vector2(r * 0.6, r * 0.25)]), color)
			ci.draw_line(c + Vector2(-r, r * 0.85), c + Vector2(r, r * 0.85), color, 3.0, true)
			for k in 3:
				ci.draw_line(c + Vector2(r * (0.15 + 0.3 * k), r * 0.85), c + Vector2(r * (0.05 + 0.35 * k), r * 0.45), color.lightened(0.3), 2.0, true)
		"flurry":
			# Tres tajos paralelos.
			for k in 3:
				var o := Vector2((k - 1) * r * 0.45, (k - 1) * r * 0.15)
				ci.draw_line(c + o + Vector2(-r * 0.6, r * 0.85), c + o + Vector2(r * 0.5, -r * 0.85), Color(color, 0.55 + 0.2 * k), 3.0, true)
			ci.draw_circle(c + Vector2(r * 0.85, -r * 0.7), r * 0.12, Color.WHITE)
		"rain":
			# Proyectiles cayendo sobre una zona.
			ci.draw_set_transform(c + Vector2(0, r * 0.7), 0.0, Vector2(1.0, 0.35))
			ci.draw_arc(Vector2.ZERO, r * 0.95, 0.0, TAU, 20, Color(color, 0.7), 2.0, true)
			ci.draw_set_transform(Vector2.ZERO)
			for k in 4:
				var x := (k - 1.5) * r * 0.5
				var y := -r * 0.9 + (k % 2) * r * 0.35
				ci.draw_line(c + Vector2(x - r * 0.15, y), c + Vector2(x + r * 0.05, y + r * 0.8), Color(color, 0.5), 2.0, true)
				ci.draw_circle(c + Vector2(x + r * 0.05, y + r * 0.8), r * 0.1, color.lightened(0.4))
		"robot":
			ci.draw_rect(Rect2(c + Vector2(-r * 0.6, -r * 0.55), Vector2(r * 1.2, r * 1.0)), Color("6e7480"))
			ci.draw_rect(Rect2(c + Vector2(-r * 0.45, -r * 0.4), Vector2(r * 0.9, r * 0.35)), Color("10161c"))
			ci.draw_rect(Rect2(c + Vector2(-r * 0.35, -r * 0.32), Vector2(r * 0.7, r * 0.18)), color)
			ci.draw_line(c + Vector2(-r * 0.3, r * 0.45), c + Vector2(-r * 0.45, r), Color("4a4f5c"), 3.0, true)
			ci.draw_line(c + Vector2(r * 0.3, r * 0.45), c + Vector2(r * 0.45, r), Color("4a4f5c"), 3.0, true)
			ci.draw_rect(Rect2(c + Vector2(r * 0.6, -r * 0.1), Vector2(r * 0.45, r * 0.2)), Color("3a3f4a"))
			ci.draw_line(c + Vector2(0, -r * 0.55), c + Vector2(0, -r * 0.9), Color("8a8a96"), 2.0)
			ci.draw_circle(c + Vector2(0, -r * 0.95), r * 0.12, color)
		"daemon":
			ci.draw_circle(c + Vector2(0, r * 0.35), r * 0.55, Color("b8322a"))
			ci.draw_circle(c + Vector2(0, -r * 0.3), r * 0.42, Color("c83a30"))
			for s in [-1.0, 1.0]:
				ci.draw_colored_polygon(PackedVector2Array([c + Vector2(s * r * 0.2, -r * 0.62), c + Vector2(s * r * 0.55, -r * 1.05), c + Vector2(s * r * 0.42, -r * 0.48)]), Color("f0e0c0"))
			ci.draw_circle(c + Vector2(-r * 0.15, -r * 0.3), r * 0.08, Color("ffe070"))
			ci.draw_circle(c + Vector2(r * 0.15, -r * 0.3), r * 0.08, Color("ffe070"))
			ci.draw_line(c + Vector2(r * 0.8, r), c + Vector2(r * 0.8, -r * 0.7), Color("c8c8c8"), 2.0, true)
			for k in 3:
				ci.draw_line(c + Vector2(r * (0.62 + 0.18 * k), -r * 0.7), c + Vector2(r * (0.62 + 0.18 * k), -r * 1.0), Color("c8c8c8"), 1.5, true)
		"escort":
			for k in 4:
				var arm := Vector2.from_angle(PI / 4.0 + PI / 2.0 * k) * r * 0.75
				ci.draw_line(c, c + arm, Color("8a8a96"), 2.0, true)
				ci.draw_circle(c + arm, r * 0.28, Color(0.85, 0.85, 0.9, 0.35))
			ci.draw_circle(c, r * 0.35, Color("3a3f4a"))
			ci.draw_circle(c, r * 0.2, color)
			ci.draw_line(c + Vector2(r * 0.2, r * 0.3), c + Vector2(r * 0.6, r * 0.95), Color(color, 0.8), 2.0, true)
		"golem":
			ci.draw_rect(Rect2(c + Vector2(-r * 0.7, -r * 0.2), Vector2(r * 1.4, r * 1.15)), Color("5a5650"))
			ci.draw_rect(Rect2(c + Vector2(-r * 0.5, -r * 0.95), Vector2(r * 1.0, r * 0.7)), Color("b8b8b0"))
			ci.draw_rect(Rect2(c + Vector2(-r * 0.4, -r * 0.85), Vector2(r * 0.8, r * 0.5)), Color("10200f"))
			ci.draw_line(c + Vector2(-r * 0.25, -r * 0.6), c + Vector2(-r * 0.05, -r * 0.55), Color("3cff6a"), 2.0)
			ci.draw_line(c + Vector2(r * 0.25, -r * 0.6), c + Vector2(r * 0.05, -r * 0.55), Color("3cff6a"), 2.0)
			for k in 3:
				ci.draw_circle(c + Vector2(-r * 0.4 + k * r * 0.4, r * 0.4), r * 0.09, color if k != 1 else Color("e06c6c"))
			ci.draw_rect(Rect2(c + Vector2(-r * 1.05, -r * 0.1), Vector2(r * 0.3, r * 0.8)), Color("47443f"))
			ci.draw_rect(Rect2(c + Vector2(r * 0.75, -r * 0.1), Vector2(r * 0.3, r * 0.8)), Color("47443f"))
		"golem_silicio", "golem_overclock", "golem_utp", "golem_gpu", "golem_kernel":
			# Golems: su propio sprite, en pequeño (cada uno con su silueta).
			var gs := rect.size.y / 66.0
			ci.draw_set_transform(c + Vector2(0, rect.size.y * 0.36), 0.0, Vector2(gs, gs))
			UnitArt.draw(ci, String(icon["shape"]), "tank", Vector2.ZERO, 1.2, color)
			ci.draw_set_transform(Vector2.ZERO)
			if dimmed:
				ci.draw_rect(rect, Color(0, 0, 0, 0.45))
		"titan":
			# Mainframe: torre de racks con tres hileras de LED y un ojo central.
			ci.draw_rect(Rect2(c + Vector2(-r * 0.75, -r * 1.0), Vector2(r * 1.5, r * 2.0)), Color("2a3040"))
			ci.draw_rect(Rect2(c + Vector2(-r * 0.75, -r * 1.0), Vector2(r * 1.5, r * 2.0)), color, false, 2.0)
			for row in 3:
				var y := -r * 0.75 + row * r * 0.55
				ci.draw_rect(Rect2(c + Vector2(-r * 0.6, y), Vector2(r * 1.2, r * 0.32)), Color("1a1e28"))
				for k in 4:
					ci.draw_rect(Rect2(c + Vector2(-r * 0.5 + k * r * 0.28, y + r * 0.1), Vector2(r * 0.12, r * 0.12)),
						Color("3cff6a") if (k + row) % 3 != 0 else color)
			ci.draw_circle(c + Vector2(0, r * 0.05), r * 0.18, Color("e06c6c"))
		"watchdog":
			# Perro guardián con un reloj (el temporizador que vigila).
			ci.draw_rect(Rect2(c + Vector2(-r * 0.7, -r * 0.05), Vector2(r * 1.1, r * 0.55)), color.darkened(0.2))
			ci.draw_circle(c + Vector2(r * 0.45, -r * 0.25), r * 0.38, color)
			ci.draw_colored_polygon(PackedVector2Array([c + Vector2(r * 0.25, -r * 0.55), c + Vector2(r * 0.35, -r * 0.95), c + Vector2(r * 0.5, -r * 0.55)]), color.darkened(0.3))
			ci.draw_circle(c + Vector2(r * 0.55, -r * 0.3), r * 0.07, Color("1a1620"))
			for k in 4:
				ci.draw_line(c + Vector2(-r * 0.6 + k * r * 0.3, r * 0.5), c + Vector2(-r * 0.6 + k * r * 0.3, r * 0.85), color.darkened(0.35), 3.0)
			ci.draw_circle(c + Vector2(-r * 0.55, -r * 0.55), r * 0.32, Color("e8d9b0"))
			ci.draw_line(c + Vector2(-r * 0.55, -r * 0.55), c + Vector2(-r * 0.55, -r * 0.78), Color("1a1620"), 2.0)
			ci.draw_line(c + Vector2(-r * 0.55, -r * 0.55), c + Vector2(-r * 0.4, -r * 0.5), Color("1a1620"), 2.0)
		"tracker":
			# Bot rastreador: antena parabólica con ondas.
			ci.draw_rect(Rect2(c + Vector2(-r * 0.45, r * 0.3), Vector2(r * 0.9, r * 0.5)), Color("3a3f4a"))
			ci.draw_line(c + Vector2(0, r * 0.3), c + Vector2(0, -r * 0.1), Color("8a8a96"), 3.0)
			ci.draw_arc(c + Vector2(-r * 0.1, -r * 0.2), r * 0.55, PI * 0.15, PI * 0.95, 12, color, 3.0, true)
			for k in 3:
				ci.draw_arc(c + Vector2(r * 0.15, -r * 0.45), r * (0.3 + 0.25 * k), -PI * 0.45, -PI * 0.05, 8, Color(color, 0.9 - 0.25 * k), 2.0, true)
		"aura_bolt", "aura_target":
			ci.draw_arc(c, r * 1.0, 0.0, TAU, 28, Color(color, 0.5), 2.0, true)
			ci.draw_arc(c, r * 0.78, 0.4, TAU - 0.4, 24, Color(color, 0.8), 2.0, true)
			if icon.get("shape", "") == "aura_bolt":
				ci.draw_colored_polygon(PackedVector2Array([c + Vector2(r * 0.1, -r * 0.55), c + Vector2(-r * 0.3, r * 0.05), c + Vector2(-r * 0.02, r * 0.05),
					c + Vector2(-r * 0.12, r * 0.55), c + Vector2(r * 0.3, -r * 0.08), c + Vector2(r * 0.02, -r * 0.08)]), color)
			else:
				# Diana: los enemigos dentro quedan expuestos.
				ci.draw_arc(c, r * 0.45, 0.0, TAU, 20, color, 2.0, true)
				ci.draw_circle(c, r * 0.12, color)
				for k in 4:
					var d := Vector2.from_angle(PI / 2.0 * k)
					ci.draw_line(c + d * r * 0.25, c + d * r * 0.6, color, 2.0, true)
		"ring":
			ci.draw_arc(c, r, 0.0, TAU, 32, color, r * 0.28, true)
			ci.draw_line(c + Vector2(-r * 0.2, r * 0.2), c + Vector2(r * 0.9, -r * 0.9), color, 3.0, true)
		"fan":
			for k in 3:
				var a := -0.45 + 0.45 * k
				ci.draw_line(c + Vector2(-r, r * 0.6), c + Vector2(-r, r * 0.6) + Vector2.from_angle(-0.6 + a) * r * 2.0, color, 3.0, true)
		"bolt":
			ci.draw_polyline(PackedVector2Array([c + Vector2(r * 0.3, -r), c + Vector2(-r * 0.4, 0.1 * r),
				c + Vector2(r * 0.25, 0.1 * r), c + Vector2(-r * 0.3, r)]), color, 4.0, true)
		"burst":
			for k in 8:
				var dir := Vector2.from_angle(TAU * k / 8.0)
				ci.draw_line(c + dir * r * 0.3, c + dir * r, color, 3.0, true)
			ci.draw_circle(c, r * 0.3, color)
		"nova":
			ci.draw_arc(c, r, 0.0, TAU, 32, color, 2.0, true)
			ci.draw_arc(c, r * 0.6, 0.0, TAU, 32, color, 2.0, true)
			ci.draw_circle(c, r * 0.18, color)
		"arrow":
			ci.draw_line(c + Vector2(-r, r * 0.6), c + Vector2(r * 0.8, -r * 0.6), color, 4.0, true)
			ci.draw_colored_polygon(PackedVector2Array([c + Vector2(r, -r * 0.8), c + Vector2(r * 0.15, -r * 0.65),
				c + Vector2(r * 0.75, -r * 0.05)]), color)
		"dash":
			for k in 3:
				var y := (k - 1) * r * 0.45
				ci.draw_line(c + Vector2(-r, y), c + Vector2(r * 0.2 - k * 0.1 * r, y), Color(color, 0.4 + 0.3 * k), 3.0, true)
			ci.draw_colored_polygon(PackedVector2Array([c + Vector2(r * 0.3, -r * 0.6), c + Vector2(r, 0), c + Vector2(r * 0.3, r * 0.6)]), color)
		"cone":
			var pts := PackedVector2Array([c + Vector2(-r, 0)])
			for k in 7:
				pts.append(c + Vector2(-r, 0) + Vector2.from_angle(lerpf(-0.6, 0.6, k / 6.0)) * r * 2.0)
			ci.draw_colored_polygon(pts, Color(color, 0.7))
			ci.draw_circle(c + Vector2(-r, 0), r * 0.18, color.lightened(0.4))
		"beam":
			ci.draw_line(c + Vector2(-r, r), c + Vector2(r, -r), Color(color, 0.45), r * 0.7, true)
			ci.draw_line(c + Vector2(-r, r), c + Vector2(r, -r), Color.WHITE, r * 0.18, true)
		"boomerang":
			ci.draw_arc(c, r * 0.8, PI * 0.9, PI * 2.1, 16, color, r * 0.35, true)
			ci.draw_arc(c, r * 1.05, -0.5, 0.6, 8, Color(color, 0.5), 2.0, true)
		"spin":
			for k in 3:
				var a := TAU * k / 3.0
				ci.draw_arc(c, r * 0.8, a, a + 1.4, 10, color, 3.0, true)
			ci.draw_circle(c, r * 0.22, color)
		"lock":
			ci.draw_rect(Rect2(c + Vector2(-r * 0.6, -r * 0.1), Vector2(r * 1.2, r * 0.95)), color)
			ci.draw_arc(c + Vector2(0, -r * 0.1), r * 0.42, PI, TAU, 12, color, r * 0.2, true)
			ci.draw_circle(c + Vector2(0, r * 0.35), r * 0.12, Color(0.1, 0.1, 0.15))
		"trap":
			ci.draw_circle(c + Vector2(0, r * 0.2), r * 0.65, color.darkened(0.5))
			ci.draw_circle(c + Vector2(0, r * 0.2), r * 0.25, color)
			ci.draw_line(c + Vector2(r * 0.3, -r * 0.3), c + Vector2(r * 0.8, -r * 0.9), color.lightened(0.3), 2.0, true)
			ci.draw_circle(c + Vector2(r * 0.85, -r * 0.95), r * 0.12, Color("ffd84a"))
		"chain":
			var pts := PackedVector2Array([c + Vector2(-r, r * 0.6), c + Vector2(-r * 0.3, -r * 0.5), c + Vector2(r * 0.2, r * 0.3), c + Vector2(r, -r * 0.7)])
			ci.draw_polyline(pts, color, 3.0, true)
			for q in pts:
				ci.draw_circle(q, r * 0.17, color.lightened(0.3))
		"minion":
			for k in 2:
				var o := c + Vector2((k - 0.5) * r * 0.9, r * 0.1 * k)
				ci.draw_rect(Rect2(o + Vector2(-r * 0.35, -r * 0.7), Vector2(r * 0.7, r * 0.5)), Color("b8b8b0"))
				ci.draw_rect(Rect2(o + Vector2(-r * 0.25, -r * 0.6), Vector2(r * 0.5, r * 0.3)), color.darkened(0.5))
				ci.draw_rect(Rect2(o + Vector2(-r * 0.25, -r * 0.18), Vector2(r * 0.5, r * 0.7)), color.darkened(0.2))
		"puddle":
			ci.draw_set_transform(c + Vector2(0, r * 0.25), 0.0, Vector2(1.0, 0.55))
			ci.draw_circle(Vector2.ZERO, r, Color(color, 0.6))
			ci.draw_circle(Vector2.ZERO, r * 0.6, color)
			ci.draw_set_transform(Vector2.ZERO)
			for k in 3:
				ci.draw_circle(c + Vector2((k - 1) * r * 0.45, -r * 0.2 - k * r * 0.15), r * 0.12, color.lightened(0.4))
		"barrier":
			ci.draw_arc(c, r, PI * 0.9, PI * 2.1, 20, color, r * 0.25, true)
			ci.draw_arc(c, r * 0.6, PI * 0.95, PI * 2.05, 16, Color(color, 0.6), 2.0, true)
			for k in 3:
				ci.draw_rect(Rect2(c + Vector2(-r * 0.6 + k * r * 0.45, r * 0.15), Vector2(r * 0.35, r * 0.25)), color.darkened(0.2))
		"safe_mode":
			ci.draw_colored_polygon(PackedVector2Array([c + Vector2(-r * 0.8, -r * 0.7), c + Vector2(r * 0.8, -r * 0.7), c + Vector2(r * 0.7, r * 0.2), c + Vector2(0, r), c + Vector2(-r * 0.7, r * 0.2)]), color)
			ci.draw_line(c + Vector2(-r * 0.35, 0), c + Vector2(-r * 0.05, r * 0.3), Color("1a1620"), 3.0, true)
			ci.draw_line(c + Vector2(-r * 0.05, r * 0.3), c + Vector2(r * 0.45, -r * 0.3), Color("1a1620"), 3.0, true)
		"threads":
			for k in 2:
				var off := (k - 0.5) * r * 0.6
				var pts := PackedVector2Array()
				for j in 9:
					pts.append(c + Vector2(-r + j * r * 0.25, off + sin(j * 1.2 + k * PI) * r * 0.25))
				ci.draw_polyline(pts, color if k == 0 else color.lightened(0.3), 3.0, true)
		"ransom":
			ci.draw_rect(Rect2(c + Vector2(-r * 0.6, -r * 0.1), Vector2(r * 1.2, r * 0.95)), color)
			ci.draw_arc(c + Vector2(0, -r * 0.1), r * 0.42, PI, TAU, 12, color, r * 0.2, true)
			ci.draw_string(ThemeDB.fallback_font, c + Vector2(-r * 0.5, r * 0.6), "$", HORIZONTAL_ALIGNMENT_CENTER, r, int(r * 0.9), Color("1a1620"))
		"corrupt":
			ci.draw_circle(c, r * 0.6, color)
			for k in 4:
				ci.draw_rect(Rect2(c + Vector2(-r + k * r * 0.3, -r * 0.8 + k * r * 0.4), Vector2(r * 0.7, r * 0.18)), Color(0.3, 1.0, 0.6, 0.8))
		"homing":
			ci.draw_arc(c + Vector2(-r * 0.2, r * 0.2), r * 0.8, PI * 0.6, PI * 1.6, 16, color, 3.0, true)
			ci.draw_colored_polygon(PackedVector2Array([c + Vector2(r * 0.6, -r * 0.8), c + Vector2(r * 0.2, -r * 0.2), c + Vector2(r, -r * 0.3)]), color)
			ci.draw_arc(c + Vector2(r * 0.55, r * 0.5), r * 0.3, 0.0, TAU, 12, Color("e06c6c"), 2.0, true)
		"drones":
			for k in 3:
				var p := c + Vector2.from_angle(-PI / 2.0 + TAU * k / 3.0) * r * 0.6
				ci.draw_rect(Rect2(p - Vector2(r * 0.25, r * 0.1), Vector2(r * 0.5, r * 0.2)), Color("8a8a96"))
				ci.draw_circle(p, r * 0.1, color)
		"turret":
			# Torreta: trípode, cuerpo y cañón con un sensor.
			for s in [-1.0, 0.0, 1.0]:
				ci.draw_line(c + Vector2(0, r * 0.2), c + Vector2(s * r * 0.8, r), Color("8a8a96"), 2.0, true)
			ci.draw_rect(Rect2(c + Vector2(-r * 0.5, -r * 0.4), Vector2(r, r * 0.65)), color)
			ci.draw_rect(Rect2(c + Vector2(r * 0.4, -r * 0.25), Vector2(r * 0.6, r * 0.2)), Color("3a3f4a"))
			ci.draw_circle(c + Vector2(-r * 0.15, -r * 0.1), r * 0.14, Color("7fd0e8"))
			ci.draw_arc(c + Vector2(-r * 0.15, -r * 0.1), r * 0.6, -0.6, 0.6, 8, Color("7fd0e8", 0.5), 1.5, true)
		_:
			ci.draw_circle(c, r * 0.5, color)
	# Brillo diagonal de cristal por encima del glifo.
	ci.draw_colored_polygon(PackedVector2Array([rect.position, rect.position + Vector2(rect.size.x * 0.55, 0),
		rect.position + Vector2(0, rect.size.y * 0.55)]), Color(1, 1, 1, 0.05))


## Fondo del icono: degradado vertical del color de la habilidad a casi negro,
## un halo detrás del glifo y un bisel (luz arriba-izquierda, sombra abajo-derecha).
static func _draw_backdrop(ci: CanvasItem, rect: Rect2, color: Color, dimmed: bool) -> void:
	var top := Color(color.darkened(0.35), 0.55 if not dimmed else 0.3)
	var bottom := Color(0.04, 0.03, 0.06, 0.95)
	ci.draw_polygon(PackedVector2Array([rect.position, Vector2(rect.end.x, rect.position.y), rect.end, Vector2(rect.position.x, rect.end.y)]),
		PackedColorArray([top, top, bottom, bottom]))
	var c := rect.get_center()
	var r := minf(rect.size.x, rect.size.y) * 0.5
	for k in 3:
		ci.draw_circle(c, r * (0.9 - 0.25 * k), Color(color, 0.05 + 0.03 * k))
	ci.draw_line(rect.position, Vector2(rect.end.x, rect.position.y), Color(1, 1, 1, 0.18), 1.0)
	ci.draw_line(rect.position, Vector2(rect.position.x, rect.end.y), Color(1, 1, 1, 0.12), 1.0)
	ci.draw_line(Vector2(rect.position.x, rect.end.y), rect.end, Color(0, 0, 0, 0.6), 1.0)
	ci.draw_line(Vector2(rect.end.x, rect.position.y), rect.end, Color(0, 0, 0, 0.6), 1.0)


## Puntitos de colores con los estados que puede aplicar (esquina inferior derecha).
static func draw_ailment_pips(ci: CanvasItem, rect: Rect2, chances: Dictionary) -> void:
	var k := 0
	for id in Ailments.ALL:
		if not chances.has(id):
			continue
		var p := Vector2(rect.end.x - 5.0 - k * 7.0, rect.end.y - 5.0)
		ci.draw_circle(p, 3.2, Color(0, 0, 0, 0.8))
		ci.draw_circle(p, 2.3, Ailments.color(id))
		k += 1
