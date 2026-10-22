class_name Minimap
extends Control
## Minimapa circular centrado en el jugador: suelo y obstáculos de la zona,
## salidas, waypoint, NPCs, enemigos (por rareza) y botín valioso. Las salidas
## y el waypoint fuera de vista se señalan con una flecha en el borde.
## Se dibuja entero en _draw(); con unos cientos de puntos sobra.

const RADIUS := 100.0
## Píxeles del minimapa por píxel del mundo.
const SCALE := 0.065
const BG := Color("0d0b10e6")
const RING := Color("8a6d3b")
const ENEMY_COLORS := {
	Rarity.Enemy.NORMAL: Color("c84b4b"),
	Rarity.Enemy.SPECIAL: Color("8888ff"),
	Rarity.Enemy.ELITE: Color("ffff77"),
	Rarity.Enemy.UNIQUE: Color("ff8c2a"),
}

const FEATURE_COLORS := {
	"lake": Color("1c3a55"), "bog": Color("3a2a4a"), "data_lake": Color("0c3a40"), "hill": Color("2c3a24"),
	"cliff": Color("4a4036"), "chasm": Color("050407"), "void": Color("020306"), "lava": Color("8a1a12"),
}

var player: Player
var enemies: EnemyManager
var loot: LootManager
var zone: Zone


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	custom_minimum_size = Vector2(RADIUS * 2.0, RADIUS * 2.0 + 38.0)
	size = custom_minimum_size


func _process(_delta: float) -> void:
	queue_redraw()


func _to_map(world: Vector2) -> Vector2:
	return Vector2(RADIUS, RADIUS) + (world - player.global_position) * SCALE


func _inside(p: Vector2) -> bool:
	return p.distance_to(Vector2(RADIUS, RADIUS)) <= RADIUS - 3.0


func _draw() -> void:
	if player == null:
		return
	var center := Vector2(RADIUS, RADIUS)
	draw_circle(center, RADIUS, BG)

	if zone == null:
		return
	# Suelo de la zona, recortado al círculo.
	var circle := PackedVector2Array()
	for k in 48:
		circle.append(center + Vector2.from_angle(TAU * k / 48.0) * RADIUS)
	var ground := PackedVector2Array()
	if zone.walk_polygon.size() >= 3:
		for q in zone.walk_polygon:
			ground.append(_to_map(q))
	else:
		var r := zone.rect
		ground = PackedVector2Array([_to_map(r.position), _to_map(Vector2(r.end.x, r.position.y)), _to_map(r.end), _to_map(Vector2(r.position.x, r.end.y))])
	for poly in Geometry2D.intersect_polygons(ground, circle):
		draw_colored_polygon(poly, Color("2a2530"))

	for o in zone.obstacles:
		var p := _to_map(o["pos"])
		if o.get("feature", false):
			if p.distance_to(center) > RADIUS + o["visual"] * SCALE:
				continue
			var blob := PackedVector2Array()
			for q in Zone._blob_points(o, 1.0, Vector2.ZERO):
				blob.append(_to_map(q))
			for poly in Geometry2D.intersect_polygons(blob, circle):
				# El recorte con el borde puede dejar astillas sin área: no se pueden triangular.
				if poly.size() >= 3 and not Geometry2D.triangulate_polygon(poly).is_empty():
					draw_colored_polygon(poly, FEATURE_COLORS.get(o["kind"], Color("4a4352")))
		elif _inside(p):
			draw_circle(p, maxf(1.5, o["radius"] * SCALE), Color("4a4352"))
	for q in zone.quest_items:
		var p := _to_map(q["pos"])
		if zone.quest_item_visible(q):
			if _inside(p):
				draw_circle(p, 3.5, Color("ffd84a"))
			else:
				_edge_arrow(center, p, Color("ffd84a"))

	# Salidas: dentro, un rombo; fuera, una flecha en el borde hacia ellas.
	for e in zone.exits:
		if not zone.exit_visible(e):
			continue
		var p := _to_map(e["pos"])
		if _inside(p):
			draw_colored_polygon(PackedVector2Array([p + Vector2(0, -5), p + Vector2(5, 0), p + Vector2(0, 5), p + Vector2(-5, 0)]), Color("7fc8ff"))
		else:
			_edge_arrow(center, p, Color("7fc8ff"))
	if zone.has_waypoint:
		var p := _to_map(zone.waypoint)
		if _inside(p):
			draw_circle(p, 4.0, Color("5cd0ff"))
			draw_arc(p, 6.0, 0.0, TAU, 16, Color("5cd0ff"), 1.0)
		else:
			_edge_arrow(center, p, Color("5cd0ff"))
	for npc in zone.npcs:
		var p := _to_map(zone.npc_position(npc))
		if _inside(p):
			draw_circle(p, 2.5, UiStyle.ACCENT)

	# Botín: solo lo que merece la pena mirar.
	for d in loot.drops:
		var item: Item = d["item"]
		if item.is_equipment() and item.rarity < Rarity.Item.RARE:
			continue
		var p := _to_map(d["rect"].get_center())
		if _inside(p):
			draw_rect(Rect2(p - Vector2(2, 2), Vector2(4, 4)), item.display_color())

	# Enemigos.
	for i in enemies.count():
		var p := _to_map(enemies.positions[i])
		if not _inside(p):
			continue
		var rarity := enemies.rarities[i]
		draw_circle(p, 1.6 + rarity * 0.7, ENEMY_COLORS[rarity])

	# Aliados (invocaciones persistentes): puntos azules.
	for a in enemies.allies:
		var ap := _to_map(a["pos"])
		if _inside(ap):
			draw_circle(ap, 3.0, Color("9ad0ff"))
			draw_arc(ap, 4.5, 0.0, TAU, 12, Color("1a2a40"), 1.0, true)
	# Jefe con fases: marca roja que pulsa; si queda fuera del mapa, una flecha en el borde.
	var boss := enemies.boss_info()
	if not boss.is_empty():
		var bp := _to_map(boss["pos"])
		var pulse := 0.5 + 0.5 * sin(Time.get_ticks_msec() / 250.0)
		if _inside(bp):
			draw_circle(bp, 5.0 + pulse * 2.0, Color(1.0, 0.25, 0.2, 0.9))
			draw_arc(bp, 8.0 + pulse * 3.0, 0.0, TAU, 16, Color(1.0, 0.8, 0.3, 0.8), 1.5, true)
		else:
			var dir := (bp - center).normalized()
			var edge := center + dir * (RADIUS - 8.0)
			draw_colored_polygon(PackedVector2Array([edge + dir * 6.0, edge - dir * 4.0 + dir.orthogonal() * 5.0, edge - dir * 4.0 - dir.orthogonal() * 5.0]), Color(1.0, 0.3, 0.2))

	# Jugador: flecha hacia donde mira.
	var f := player.facing_direction()
	draw_colored_polygon(PackedVector2Array([center + f * 7.0, center - f * 4.0 + f.orthogonal() * 4.5,
		center - f * 2.0, center - f * 4.0 - f.orthogonal() * 4.5]), Color.WHITE)

	draw_arc(center, RADIUS, 0.0, TAU, 64, RING, 2.5, true)
	draw_arc(center, RADIUS + 3.0, 0.0, TAU, 64, RING.darkened(0.5), 1.5, true)
	var label := zone.zone_name
	var sublabel := "Zona segura" if zone.safe else "Nivel de zona %d" % zone.level
	var font := get_theme_default_font()
	draw_string_outline(font, Vector2(0, RADIUS * 2.0 + 16.0), label, HORIZONTAL_ALIGNMENT_CENTER, RADIUS * 2.0, 12, 4, Color.BLACK)
	draw_string(font, Vector2(0, RADIUS * 2.0 + 16.0), label, HORIZONTAL_ALIGNMENT_CENTER, RADIUS * 2.0, 12, UiStyle.TEXT)
	draw_string_outline(font, Vector2(0, RADIUS * 2.0 + 32.0), sublabel, HORIZONTAL_ALIGNMENT_CENTER, RADIUS * 2.0, 11, 4, Color.BLACK)
	draw_string(font, Vector2(0, RADIUS * 2.0 + 32.0), sublabel, HORIZONTAL_ALIGNMENT_CENTER, RADIUS * 2.0, 11, UiStyle.MUTED)


func _edge_arrow(center: Vector2, target: Vector2, color: Color) -> void:
	var dir := (target - center).normalized()
	var tip := center + dir * (RADIUS - 6.0)
	draw_colored_polygon(PackedVector2Array([tip, tip - dir * 10.0 + dir.orthogonal() * 5.0,
		tip - dir * 10.0 - dir.orthogonal() * 5.0]), color)


## Disco recortado al círculo del minimapa (aproximado con puntos del borde).
func _draw_clipped_disc(c: Vector2, r: float, color: Color) -> void:
	var points := PackedVector2Array()
	var center := Vector2(RADIUS, RADIUS)
	for k in 48:
		var p := c + Vector2.from_angle(TAU * k / 48.0) * r
		if p.distance_to(center) > RADIUS:
			p = center + (p - center).normalized() * RADIUS
		points.append(p)
	draw_colored_polygon(points, color)
	draw_polyline(points + PackedVector2Array([points[0]]), Color("8a6d3b"), 1.0, true)
