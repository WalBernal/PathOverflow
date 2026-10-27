class_name WorldMap
extends Control
## Mapa grande (Tab): la zona entera superpuesta al juego, como en PoE, con
## niebla de guerra. Lo explorado (celdas de CELL px alrededor del jugador) se
## guarda en el personaje (flags "map_<zona>") y se ve al volver.
## Muestra salidas con su destino, waypoint, NPCs, objetos de misión, el jefe,
## los enemigos cercanos, el botín bueno y al jugador. El juego no se pausa.
## Rueda o +/−: zoom (centrado en el jugador). Clic derecho: pone una marca
## propia (o quita la que haya ahí); se guardan por zona en flags "marks_<zona>".

const CELL := 160.0
const REVEAL_RADIUS := 560.0
const MARGIN := 80.0
const BOTTOM_FREE := 170.0
const FOG := Color(0.02, 0.015, 0.03, 0.92)
const GROUND := Color("2a2530")
const ZOOMS := [1.0, 1.5, 2.0, 3.0, 4.0]
const MAX_MARKS := 12
## Un clic derecho a menos de esto (en el mundo) de una marca la quita.
const MARK_PICK := 120.0
const MARK_COLOR := Color("ff6ad5")

var player: Player
var enemies: EnemyManager
var loot: LootManager
var character: CharacterData
var zone: Zone
## Celdas exploradas de la zona actual (1 byte por celda; 1 = vista).
var explored := PackedByteArray()
var _cols := 0
var _rows := 0
var _reveal_left := 0.0
var zoom_index := 0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	visible = false


## Al entrar en una zona: guarda lo explorado de la anterior y carga lo de esta.
func set_zone(new_zone: Zone) -> void:
	save_explored()
	zone = new_zone
	_cols = maxi(1, ceili(zone.rect.size.x / CELL))
	_rows = maxi(1, ceili(zone.rect.size.y / CELL))
	explored = PackedByteArray()
	explored.resize(_cols * _rows)
	# Las zonas generadas cambian de forma: lo explorado de otra visita no sirve (T118 lo guardará con la instancia).
	var saved := String(character.flags.get("map_" + zone.id, "")) if character and zone.layout == null else ""
	if saved != "":
		var raw := Marshalls.base64_to_raw(saved)
		for k in mini(raw.size() * 8, explored.size()):
			explored[k] = (raw[k / 8] >> (k % 8)) & 1
	reveal()


## Guarda lo explorado en el personaje, en bits y base64 (unos cientos de bytes por zona).
func save_explored() -> void:
	if zone == null or character == null or explored.is_empty() or zone.layout != null:
		return
	var raw := PackedByteArray()
	raw.resize(ceili(explored.size() / 8.0))
	for k in explored.size():
		if explored[k] != 0:
			raw[k / 8] |= 1 << (k % 8)
	character.flags["map_" + zone.id] = Marshalls.raw_to_base64(raw)


## Fracción explorada de la zona (0..1).
func explored_fraction() -> float:
	if explored.is_empty():
		return 0.0
	var n := 0
	for b in explored:
		n += b
	return float(n) / explored.size()


## Descubre las celdas alrededor del jugador.
func reveal() -> void:
	if zone == null or player == null:
		return
	var p := player.global_position - zone.rect.position
	var r := ceili(REVEAL_RADIUS / CELL)
	var cx := floori(p.x / CELL)
	var cy := floori(p.y / CELL)
	for y in range(maxi(0, cy - r), mini(_rows, cy + r + 1)):
		for x in range(maxi(0, cx - r), mini(_cols, cx + r + 1)):
			if Vector2((x + 0.5) * CELL, (y + 0.5) * CELL).distance_to(p) <= REVEAL_RADIUS:
				explored[y * _cols + x] = 1


func is_explored(world: Vector2) -> bool:
	if zone == null:
		return false
	var p := world - zone.rect.position
	var x := floori(p.x / CELL)
	var y := floori(p.y / CELL)
	return x >= 0 and y >= 0 and x < _cols and y < _rows and explored[y * _cols + x] == 1


func toggle() -> void:
	visible = not visible
	queue_redraw()


func _process(delta: float) -> void:
	_reveal_left -= delta
	if _reveal_left <= 0.0:
		_reveal_left = 0.25
		reveal()
	if visible:
		queue_redraw()


## Escala y origen para que la zona quepa en la pantalla; con zoom, centrado en
## el jugador sin dejar ver fuera de la zona.
func _fit() -> Array:
	# Deja libre la franja de abajo (orbes y barra de habilidades).
	var area := size - Vector2(MARGIN * 2.0, MARGIN + BOTTOM_FREE)
	var s := minf(area.x / zone.rect.size.x, area.y / zone.rect.size.y)
	var origin := Vector2((size.x - zone.rect.size.x * s) / 2.0, MARGIN + (area.y - zone.rect.size.y * s) / 2.0)
	var z: float = ZOOMS[zoom_index]
	if z > 1.0:
		s *= z
		var area_pos := Vector2(MARGIN, MARGIN)
		origin = area_pos + area / 2.0 - (player.global_position - zone.rect.position) * s
		var span := zone.rect.size * s
		for k in 2:   # que la zona no se despegue del borde si es más grande que el área
			if span[k] > area[k]:
				origin[k] = clampf(origin[k], area_pos[k] + area[k] - span[k], area_pos[k])
			else:
				origin[k] = area_pos[k] + (area[k] - span[k]) / 2.0
	return [s, origin]


func zoom_by(step: int) -> void:
	zoom_index = clampi(zoom_index + step, 0, ZOOMS.size() - 1)
	queue_redraw()


# --- Marcas propias ---

func marks() -> Array:
	if zone == null or character == null:
		return []
	return character.flags.get("marks_" + zone.id, [])


## Pone o quita (si hay una cerca) una marca en `world`. True si quedó puesta.
func toggle_mark(world: Vector2) -> bool:
	var list := toggle_in(marks(), world, MARK_PICK, MAX_MARKS)
	var placed: bool = list.size() > marks().size()
	character.flags["marks_" + zone.id] = list
	queue_redraw()
	return placed


## La lista de marcas ([x, y]) tras un clic en `p`: quita la más cercana a menos
## de `pick`; si no hay, añade una (si no se pasa de `max_marks`).
static func toggle_in(list: Array, p: Vector2, pick: float, max_marks: int) -> Array:
	var out := list.duplicate()
	var best := -1
	var best_d := pick
	for i in out.size():
		var d := Vector2(out[i][0], out[i][1]).distance_to(p)
		if d <= best_d:
			best = i
			best_d = d
	if best != -1:
		out.remove_at(best)
	elif out.size() < max_marks:
		out.append([roundf(p.x), roundf(p.y)])
	return out


## Del punto del mapa (local) al mundo.
func map_to_world(local: Vector2) -> Vector2:
	var fit := _fit()
	return zone.rect.position + (local - (fit[1] as Vector2)) / float(fit[0])


func _unhandled_input(event: InputEvent) -> void:
	if not visible or zone == null:
		return
	var mb := event as InputEventMouseButton
	if mb and mb.pressed:
		match mb.button_index:
			MOUSE_BUTTON_WHEEL_UP:
				zoom_by(1)
			MOUSE_BUTTON_WHEEL_DOWN:
				zoom_by(-1)
			MOUSE_BUTTON_RIGHT:
				var w := map_to_world((make_input_local(mb) as InputEventMouseButton).position)
				if zone.rect.has_point(w):
					toggle_mark(w)
			_:
				return
		get_viewport().set_input_as_handled()
		return
	var key := event as InputEventKey
	if key and key.pressed and not key.echo:
		if key.keycode in [KEY_EQUAL, KEY_PLUS, KEY_KP_ADD]:
			zoom_by(1)
		elif key.keycode in [KEY_MINUS, KEY_KP_SUBTRACT]:
			zoom_by(-1)
		else:
			return
		get_viewport().set_input_as_handled()


func _draw() -> void:
	if zone == null or player == null:
		return
	var fit := _fit()
	var s: float = fit[0]
	var origin: Vector2 = fit[1]
	var to_map := func(w: Vector2) -> Vector2: return origin + (w - zone.rect.position) * s
	var font := get_theme_default_font()
	var t := Time.get_ticks_msec() / 1000.0
	draw_rect(Rect2(Vector2.ZERO, size), Color(0, 0, 0, 0.35))
	# Suelo y obstáculos.
	var ground := PackedVector2Array()
	for q in zone.walk_polygon:
		ground.append(to_map.call(q))
	if not zone.ground_rects.is_empty():
		for r in zone.ground_rects:   # zona generada (T115)
			draw_rect(Rect2(to_map.call(r.position), r.size * s), Color(GROUND, 0.85))
	elif ground.size() >= 3:
		draw_colored_polygon(ground, Color(GROUND, 0.85))
		draw_polyline(ground + PackedVector2Array([ground[0]]), Color("8a6d3b", 0.7), 1.5)
	else:
		draw_rect(Rect2(origin, zone.rect.size * s), Color(GROUND, 0.85))
	for o in zone.obstacles:
		if o.get("feature", false):
			var blob := PackedVector2Array()
			for q in Zone._blob_points(o, 1.0, Vector2.ZERO):
				blob.append(to_map.call(q))
			if blob.size() >= 3 and not Geometry2D.triangulate_polygon(blob).is_empty():
				draw_colored_polygon(blob, Minimap.FEATURE_COLORS.get(o["kind"], Color("4a4352")))
		else:
			draw_circle(to_map.call(o["pos"]), maxf(1.5, o["radius"] * s), Color("4a4352"))
	# Niebla de guerra sobre lo no explorado.
	var cell := CELL * s
	for y in _rows:
		for x in _cols:
			if explored[y * _cols + x] == 0:
				draw_rect(Rect2(origin + Vector2(x, y) * cell, Vector2(cell, cell) + Vector2.ONE), FOG)
	# Marcas (solo en lo explorado, salvo las salidas y el waypoint ya descubiertos).
	for e in zone.exits:
		if not zone.exit_visible(e) or not is_explored(e["pos"]):
			continue
		var p: Vector2 = to_map.call(e["pos"])
		var col := Color("7fc8ff") if zone.exit_open(e) else Color("8a8293")
		draw_colored_polygon(PackedVector2Array([p + Vector2(0, -7), p + Vector2(7, 0), p + Vector2(0, 7), p + Vector2(-7, 0)]), col)
		var label := String(e.get("label", ""))
		if label == "":
			var gd := get_node_or_null("/root/GameData")
			label = String(gd.get("zones").get(e["target"], {}).get("name", e["target"])) if gd else String(e["target"])
		_text(font, p + Vector2(-90, -12), label, 180.0, 12, col)
	if zone.has_waypoint and is_explored(zone.waypoint):
		var wp: Vector2 = to_map.call(zone.waypoint)
		draw_circle(wp, 6.0, Color("5cd0ff"))
		draw_arc(wp, 9.0, 0.0, TAU, 20, Color("5cd0ff"), 1.5)
		_text(font, wp + Vector2(-60, 22), "Waypoint", 120.0, 11, Color("5cd0ff"))
	for npc in zone.npcs:
		var np := zone.npc_position(npc)
		if not is_explored(np):
			continue
		var p: Vector2 = to_map.call(np)
		draw_circle(p, 4.5, Minimap.NPC_COLOR)
		_text(font, p + Vector2(-60, -8), String(npc.get("name", npc["id"])), 120.0, 11, Minimap.NPC_COLOR)
	for q in zone.quest_items:
		if zone.quest_item_visible(q) and is_explored(q["pos"]):
			var p: Vector2 = to_map.call(q["pos"])
			var pulse := 0.5 + 0.5 * sin(t * 4.0)
			draw_circle(p, 7.0 + 2.0 * pulse, Color(Minimap.QUEST_COLOR, 0.3))
			draw_circle(p, 5.0, Minimap.QUEST_COLOR)
	if loot:
		for d in loot.drops:
			var item: Item = d["item"]
			if item.is_equipment() and item.rarity < Rarity.Item.RARE:
				continue
			var lp: Vector2 = (d["rect"] as Rect2).get_center()
			if is_explored(lp):
				draw_rect(Rect2(to_map.call(lp) - Vector2(2.5, 2.5), Vector2(5, 5)), item.display_color())
	if enemies:
		for i in enemies.count():
			var ep := enemies.positions[i]
			# Solo los que se ven (cerca del jugador) y los raros o mejores ya descubiertos.
			if ep.distance_to(player.global_position) > REVEAL_RADIUS * 1.6 and not (enemies.rarities[i] >= Rarity.Enemy.ELITE and is_explored(ep)):
				continue
			var r := 1.5 + enemies.rarities[i] * 0.8
			var p: Vector2 = to_map.call(ep)
			draw_rect(Rect2(p - Vector2(r, r), Vector2(r, r) * 2.0), Minimap.ENEMY_COLORS[enemies.rarities[i]])
	# Marcas propias: un banderín numerado (se ven aunque haya niebla).
	var list := marks()
	for i in list.size():
		var mp: Vector2 = to_map.call(Vector2(list[i][0], list[i][1]))
		draw_line(mp, mp + Vector2(0, -16), MARK_COLOR, 2.0)
		draw_colored_polygon(PackedVector2Array([mp + Vector2(0, -16), mp + Vector2(11, -12), mp + Vector2(0, -8)]), MARK_COLOR)
		draw_circle(mp, 2.5, MARK_COLOR)
		_text(font, mp + Vector2(-20, -20), str(i + 1), 40.0, 11, MARK_COLOR)
	# Jugador.
	var pp: Vector2 = to_map.call(player.global_position)
	var f := player.facing_direction()
	draw_circle(pp, 11.0 + 3.0 * sin(t * 5.0), Color(1, 1, 1, 0.12))
	draw_colored_polygon(PackedVector2Array([pp + f * 9.0, pp - f * 5.0 + f.orthogonal() * 6.0, pp - f * 2.5, pp - f * 5.0 - f.orthogonal() * 6.0]), Color.WHITE)
	# Título y leyenda.
	_text(font, Vector2(0, 40), zone.zone_name, size.x, 26, UiStyle.ACCENT)
	_text(font, Vector2(0, 62), ("Zona segura" if zone.safe else "Nivel de zona %d" % zone.level) + "  ·  Explorado %d %%" % roundi(explored_fraction() * 100.0)
		+ ("  ·  Zoom ×%s" % str(ZOOMS[zoom_index]) if zoom_index > 0 else ""), size.x, 13, UiStyle.MUTED)
	_text(font, Vector2(0, size.y - BOTTOM_FREE + 22.0), "Tab: cerrar  ·  ◆ salida  ·  ● waypoint  ·  NPC en dorado  ·  misión en verde  ·  enemigos por rareza", size.x, 12, UiStyle.MUTED)
	_text(font, Vector2(0, size.y - BOTTOM_FREE + 40.0), "Rueda o +/−: zoom  ·  clic derecho: poner o quitar una marca (%d/%d)" % [list.size(), MAX_MARKS], size.x, 12, UiStyle.MUTED)


func _text(font: Font, pos: Vector2, text: String, width: float, font_size: int, color: Color) -> void:
	draw_string_outline(font, pos, text, HORIZONTAL_ALIGNMENT_CENTER, width, font_size, 4, Color.BLACK)
	draw_string(font, pos, text, HORIZONTAL_ALIGNMENT_CENTER, width, font_size, color)
