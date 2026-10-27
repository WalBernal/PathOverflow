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
## Enemigos: gris (normales), azul claro (mágicos), amarillo (raros) y naranja (únicos).
const ENEMY_COLORS := {
	Rarity.Enemy.NORMAL: Color("a8a8b0"),
	Rarity.Enemy.SPECIAL: Color("7fd4ff"),
	Rarity.Enemy.ELITE: Color("ffe14a"),
	Rarity.Enemy.UNIQUE: Color("ff8c2a"),
}
const QUEST_COLOR := Color("4fd36b")
const NPC_COLOR := Color("e8c87a")
const OUTLINE := Color(0.03, 0.02, 0.05, 0.95)

const FEATURE_COLORS := {
	"lake": Color("1c3a55"), "bog": Color("3a2a4a"), "data_lake": Color("0c3a40"), "hill": Color("2c3a24"),
	"cliff": Color("4a4036"), "chasm": Color("050407"), "void": Color("020306"), "lava": Color("8a1a12"),
}

var player: Player
var enemies: EnemyManager
var loot: LootManager
var zone: Zone
## Para dibujar también las marcas propias del mapa grande.
var world_map: WorldMap


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	custom_minimum_size = Vector2(RADIUS * 2.0, RADIUS * 2.0 + 38.0)
	size = custom_minimum_size


## Se redibuja a 30 Hz: el minimapa no necesita más y con cientos de enemigos se nota.
const REDRAW_INTERVAL := 1.0 / 30.0
var _redraw_left := 0.0


func _process(delta: float) -> void:
	_redraw_left -= delta
	if _redraw_left <= 0.0:
		_redraw_left = REDRAW_INTERVAL
		queue_redraw()


func _to_map(world: Vector2) -> Vector2:
	return Vector2(RADIUS, RADIUS) + (world - player.global_position) * SCALE


func _inside(p: Vector2) -> bool:
	return p.distance_to(Vector2(RADIUS, RADIUS)) <= RADIUS - 3.0


## Tiempo de CPU del último _draw (ms), para la prueba de rendimiento.
var last_draw_ms := 0.0


func _draw() -> void:
	var t0 := Time.get_ticks_usec()
	_draw_map()
	last_draw_ms = (Time.get_ticks_usec() - t0) / 1000.0


## Dónde está la mecánica principal de la zona: su evento mientras no se complete o,
## si es de las que trae la zona (mutex, carrera crítica), sus puntos.
static func mechanic_points(z: Zone) -> Array[Vector2]:
	var out: Array[Vector2] = []
	if z == null or z.mechanic.is_empty() or String(z.mechanic.get("main", "")) == "":
		return out
	if z.events:
		for e in z.events.events:
			if e.get("main", false) and e["state"] != "done":
				out.append(e["pos"])
	if z.mechanic.get("fixed", false):
		var m := String(z.mechanic["main"])
		var d: Dictionary = z.def.get(String(ZoneMechanics.info(m).get("data_key", m)), {})
		if d.has("pos"):
			out.append(Zone._v(d["pos"]))
		for p in d.get("positions", []):
			out.append(Zone._v(p))
	return out


func _draw_map() -> void:
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
	if not zone.ground_rects.is_empty():
		# Zona generada (T115): sus rectángulos de suelo, solo los que caen en el círculo.
		var view := Rect2(Vector2.ZERO, Vector2(RADIUS, RADIUS) * 2.0)
		for r in zone.ground_rects:
			var a := _to_map(r.position)
			var b := _to_map(r.end)
			var mr := Rect2(a.min(b), (b - a).abs())
			if not mr.intersects(view):
				continue
			var quad := PackedVector2Array([mr.position, Vector2(mr.end.x, mr.position.y), mr.end, Vector2(mr.position.x, mr.end.y)])
			var corners_in := true
			for q in quad:
				corners_in = corners_in and q.distance_to(center) <= RADIUS
			if corners_in:
				draw_rect(mr, Color("2a2530"))   # entero dentro del círculo: sin recortar
				continue
			for poly in Geometry2D.intersect_polygons(quad, circle):
				# El recorte con el borde puede dejar astillas sin área: no se pueden triangular.
				if poly.size() >= 3 and not Geometry2D.triangulate_polygon(poly).is_empty():
					draw_colored_polygon(poly, Color("2a2530"))
	else:
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
	# La mecánica principal de la zona (T120): rombo dorado donde está, hasta completarla.
	for p in mechanic_points(zone):
		var mp := _to_map(p)
		if _inside(mp):
			var r := 5.0
			draw_colored_polygon(PackedVector2Array([mp + Vector2(0, -r), mp + Vector2(r, 0), mp + Vector2(0, r), mp + Vector2(-r, 0)]), Color("ffd24a"))
			draw_polyline(PackedVector2Array([mp + Vector2(0, -r), mp + Vector2(r, 0), mp + Vector2(0, r), mp + Vector2(-r, 0), mp + Vector2(0, -r)]), Color("4a3a10"), 1.0)
	if world_map:
		for m in world_map.marks():
			var mp := _to_map(Vector2(m[0], m[1]))
			if _inside(mp):
				draw_line(mp, mp + Vector2(0, -9), WorldMap.MARK_COLOR, 1.5)
				draw_colored_polygon(PackedVector2Array([mp + Vector2(0, -9), mp + Vector2(6, -7), mp + Vector2(0, -5)]), WorldMap.MARK_COLOR)
	var time := Time.get_ticks_msec() / 1000.0

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
	# NPCs: una silueta (cabeza y hombros); con «!» si ofrecen misión y «?» si
	# tienen una lista para entregar, como sobre su cabeza en el mundo.
	for npc in zone.npcs:
		var p := _to_map(zone.npc_position(npc))
		if not _inside(p):
			continue
		var mark := ""
		if zone.quests and zone.quests.npc_has_turn_in(npc["id"]):
			mark = "?"
		elif zone.quests and zone.quests.npc_offers_quest(npc["id"]):
			mark = "!"
		_draw_npc_icon(p, mark)

	# Botín: solo lo que merece la pena mirar.
	for d in loot.drops:
		var item: Item = d["item"]
		if item.is_equipment() and item.rarity < Rarity.Item.RARE:
			continue
		var p := _to_map(d["rect"].get_center())
		if _inside(p):
			draw_rect(Rect2(p - Vector2(2, 2), Vector2(4, 4)), item.display_color())

	# Enemigos: puntos con borde oscuro, más grandes cuanto más raros.
	var boss := enemies.boss_info()
	var boss_index := enemies.index_of(boss["id"]) if not boss.is_empty() else -1
	for i in enemies.count():
		if i == boss_index:
			continue
		var p := _to_map(enemies.positions[i])
		if not _inside(p):
			continue
		# Cuadritos (mucho más baratos que círculos cuando hay cientos).
		var rarity := enemies.rarities[i]
		var r := 1.5 + rarity * 0.7
		draw_rect(Rect2(p - Vector2(r + 1.0, r + 1.0), Vector2(r + 1.0, r + 1.0) * 2.0), OUTLINE)
		draw_rect(Rect2(p - Vector2(r, r), Vector2(r, r) * 2.0), ENEMY_COLORS[rarity])

	# Aliados (invocaciones persistentes): puntos azules.
	for a in enemies.allies:
		var ap := _to_map(a["pos"])
		if _inside(ap):
			draw_circle(ap, 3.0, Color("9ad0ff"))
			draw_arc(ap, 4.5, 0.0, TAU, 12, Color("1a2a40"), 1.0, true)
	# Objetos de misión: insignia verde con «!» (encima de enemigos y aliados).
	for q in zone.quest_items:
		if not zone.quest_item_visible(q):
			continue
		var p := _to_map(q["pos"])
		if _inside(p):
			_draw_quest_icon(p, time)
		else:
			_edge_arrow(center, p, QUEST_COLOR)
	# Jefe: su propio sprite en una insignia, con ondas rojas que se expanden.
	# Si queda fuera del mapa, la insignia (más pequeña) se pega al borde.
	if not boss.is_empty():
		var bp := _to_map(boss["pos"])
		if _inside(bp):
			_draw_boss_icon(bp, boss["sprite"], time, 1.0)
		else:
			var dir := (bp - center).normalized()
			var edge := center + dir * (RADIUS - 13.0)
			_draw_boss_icon(edge, boss["sprite"], time, 0.75)
			var tip := center + dir * (RADIUS + 2.0)
			draw_colored_polygon(PackedVector2Array([tip, tip - dir * 6.0 + dir.orthogonal() * 4.0, tip - dir * 6.0 - dir.orthogonal() * 4.0]), Color(1.0, 0.3, 0.2))

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


func _draw_quest_icon(p: Vector2, time: float) -> void:
	var pulse := 0.5 + 0.5 * sin(time * 4.0)
	draw_circle(p, 9.0 + pulse * 2.0, Color(QUEST_COLOR, 0.18 + 0.12 * pulse))
	draw_circle(p, 7.5, OUTLINE)
	draw_circle(p, 6.3, QUEST_COLOR)
	# El «!»: palo y punto.
	draw_rect(Rect2(p + Vector2(-1.2, -4.2), Vector2(2.4, 5.0)), OUTLINE)
	draw_circle(p + Vector2(0, 3.0), 1.3, OUTLINE)


func _draw_npc_icon(p: Vector2, mark: String) -> void:
	var col := NPC_COLOR
	draw_circle(p + Vector2(0, -2.5), 3.4, OUTLINE)
	draw_colored_polygon(PackedVector2Array([p + Vector2(-5.2, 5.0), p + Vector2(-3.6, 0.2), p + Vector2(3.6, 0.2), p + Vector2(5.2, 5.0)]), OUTLINE)
	draw_colored_polygon(PackedVector2Array([p + Vector2(-4.0, 4.0), p + Vector2(-2.8, 1.2), p + Vector2(2.8, 1.2), p + Vector2(4.0, 4.0)]), col)
	draw_circle(p + Vector2(0, -2.5), 2.4, col)
	if mark != "":
		var font := get_theme_default_font()
		var mc := Color("ffd84a") if mark == "!" else QUEST_COLOR
		draw_string_outline(font, p + Vector2(-6, -6), mark, HORIZONTAL_ALIGNMENT_CENTER, 12, 12, 4, OUTLINE)
		draw_string(font, p + Vector2(-6, -6), mark, HORIZONTAL_ALIGNMENT_CENTER, 12, 12, mc)


## Insignia del jefe: el primer fotograma de su sprite dentro de un círculo
## oscuro con borde rojo, y dos ondas que salen hacia fuera y se apagan.
func _draw_boss_icon(p: Vector2, region: Rect2, time: float, scale_factor: float) -> void:
	var r := 11.0 * scale_factor
	for k in 2:
		var t := fmod(time * 0.9 + k * 0.5, 1.0)
		draw_arc(p, r + 2.0 + t * 12.0 * scale_factor, 0.0, TAU, 24, Color(1.0, 0.3, 0.2, 0.8 * (1.0 - t)), 2.0, true)
	draw_circle(p, r + 1.5, OUTLINE)
	draw_circle(p, r, Color("2a0e10"))
	var side := r * 1.9
	draw_texture_rect_region(EnemyManager.ATLAS, Rect2(p - Vector2(side, side) / 2.0, Vector2(side, side)), region)
	var beat := 0.5 + 0.5 * sin(time * 6.0)
	draw_arc(p, r, 0.0, TAU, 24, Color(1.0, 0.25 + 0.3 * beat, 0.2), 2.0, true)


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
