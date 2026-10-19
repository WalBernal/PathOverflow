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
	ci.draw_rect(rect, Color(color, 0.12))
	match icon.get("shape", ""):
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
		_:
			ci.draw_circle(c, r * 0.5, color)
