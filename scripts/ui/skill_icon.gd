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
		_:
			ci.draw_circle(c, r * 0.5, color)
