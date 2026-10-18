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

var player: Player
var enemies: EnemyManager
var loot: LootManager
var zone: Zone


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	custom_minimum_size = Vector2(RADIUS * 2.0, RADIUS * 2.0 + 22.0)
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
	var r := zone.rect
	var ground := PackedVector2Array([_to_map(r.position), _to_map(Vector2(r.end.x, r.position.y)), _to_map(r.end), _to_map(Vector2(r.position.x, r.end.y))])
	for poly in Geometry2D.intersect_polygons(ground, circle):
		draw_colored_polygon(poly, Color("2a2530"))

	for o in zone.obstacles:
		var p := _to_map(o["pos"])
		if _inside(p):
			draw_circle(p, maxf(1.5, o["radius"] * SCALE), Color("4a4352"))

	# Salidas: dentro, un rombo; fuera, una flecha en el borde hacia ellas.
	for e in zone.exits:
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

	# Jugador: flecha hacia donde mira.
	var f := player.facing_direction()
	draw_colored_polygon(PackedVector2Array([center + f * 7.0, center - f * 4.0 + f.orthogonal() * 4.5,
		center - f * 2.0, center - f * 4.0 - f.orthogonal() * 4.5]), Color.WHITE)

	draw_arc(center, RADIUS, 0.0, TAU, 64, RING, 2.5, true)
	draw_arc(center, RADIUS + 3.0, 0.0, TAU, 64, RING.darkened(0.5), 1.5, true)
	var label := zone.zone_name if zone.safe else "%s · nivel %d" % [zone.zone_name, zone.level]
	var font := get_theme_default_font()
	draw_string_outline(font, Vector2(0, RADIUS * 2.0 + 16.0), label, HORIZONTAL_ALIGNMENT_CENTER, RADIUS * 2.0, 12, 4, Color.BLACK)
	draw_string(font, Vector2(0, RADIUS * 2.0 + 16.0), label, HORIZONTAL_ALIGNMENT_CENTER, RADIUS * 2.0, 12, UiStyle.TEXT)


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
