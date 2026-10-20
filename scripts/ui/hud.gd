class_name Hud
extends Control
## HUD de combate, al estilo de PoE: orbe de vida (con anillo de escudo de
## energía) y de maná en los extremos, y entre ambos una placa con las pociones,
## la barra de habilidades, la de experiencia y accesos a los menús.
## Todo lo importante tiene un tooltip de ayuda al pasar el ratón.

signal menu_requested(menu: String)  # "inventory", "skills", "passives"

const ORB_RADIUS := 78.0
const SLOT := 60.0
const SLOT_GAP := 8.0
const PLATE_HEIGHT := 92.0
const FLASK_SIZE := Vector2(52, 60)
const LIFE_COLOR := Color("b3262b")
const MANA_COLOR := Color("2a4fb3")
const ES_COLOR := Color("7fb8e0")
const XP_COLOR := Color("d9a441")
const PLATE := Color("16131b")
const TRIM := Color("8a6d3b")
const TEXT_COLOR := Color("e8d9b0")
const MUTED := Color("8a8293")

var player: Player
var enemies: EnemyManager
var character: CharacterData
var skills: SkillController

var _info: Label
var _message: Label
var _message_tween: Tween
var _info_timer := 0.0
var _hotspots := {}            # nombre -> Control (para tooltips de ayuda)
var _menu_buttons: Array[Button] = []
## Destello de cada ranura de la barra al usarla (segundos restantes).
var _slot_flash: Array[float] = [0.0, 0.0, 0.0, 0.0, 0.0, 0.0]
## Marco del objetivo: enemigo bajo el cursor (índice) y cuánto se mantiene tras salir.
var _target_id := -1
var _target_linger := 0.0
const TARGET_SIZE := Vector2(360, 44)


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	theme = UiStyle.make_theme()
	_info = Label.new()
	_info.position = Vector2(12, 10)
	_info.add_theme_color_override("font_color", MUTED)
	_info.add_theme_font_size_override("font_size", 13)
	add_child(_info)

	_message = Label.new()
	_message.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_message.add_theme_color_override("font_color", Color("e06c6c"))
	_message.add_theme_font_size_override("font_size", 18)
	add_child(_message)
	_message.anchor_right = 1.0
	_message.offset_top = 124.0   # debajo del marco del objetivo

	for key in ["life", "mana", "xp", "flask_0", "flask_1", "flask_2", "flask_3", "flask_4", "skill_0", "skill_1", "skill_2", "skill_3", "skill_4", "skill_5"]:
		var spot := Control.new()
		spot.mouse_filter = Control.MOUSE_FILTER_STOP
		add_child(spot)
		_hotspots[key] = spot
	for entry in [["C", "character", "Personaje (C): stats, resistencias y opiniones no solicitadas."],
			["I", "inventory", "Inventario (I): equipo y bolsa."],
			["K", "skills", "Habilidades (K): placas base y módulos RAM."],
			["P", "passives", "Árbol pasivo (P): gasta tus puntos. O no, y quéjate en los foros."]]:
		var b := Button.new()
		b.text = entry[0]
		b.tooltip_text = entry[2]
		b.focus_mode = Control.FOCUS_NONE
		b.custom_minimum_size = Vector2(34, 30)
		b.pressed.connect(func() -> void: menu_requested.emit(entry[1]))
		add_child(b)
		_menu_buttons.append(b)
	_layout()


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED and is_node_ready():
		_layout()


## Mensaje temporal en el centro superior de la pantalla.
func flash(text: String, color := Color("e06c6c")) -> void:
	_message.text = text
	_message.add_theme_color_override("font_color", color)
	_message.modulate.a = 1.0
	if _message_tween:
		_message_tween.kill()
	_message_tween = create_tween()
	_message_tween.tween_interval(2.0)
	_message_tween.tween_property(_message, "modulate:a", 0.0, 0.6)


## ¿Está el ratón sobre la placa o los orbes? (para no tirar objetos ahí)
func is_over_hud(pos: Vector2) -> bool:
	return pos.y >= _plate_rect().position.y - 12.0 or pos.distance_to(_life_center()) <= ORB_RADIUS + 10.0 \
		or pos.distance_to(_mana_center()) <= ORB_RADIUS + 10.0


# --- Geometría ---

func _life_center() -> Vector2:
	return Vector2(ORB_RADIUS + 28.0, size.y - ORB_RADIUS - 18.0)


func _mana_center() -> Vector2:
	return Vector2(size.x - ORB_RADIUS - 28.0, size.y - ORB_RADIUS - 18.0)


func _plate_rect() -> Rect2:
	var left := ORB_RADIUS * 2.0 + 40.0
	return Rect2(left, size.y - PLATE_HEIGHT, size.x - left * 2.0, PLATE_HEIGHT)


func _slot_rect(i: int) -> Rect2:
	var plate := _plate_rect()
	var total := SkillController.ACTIONS.size() * SLOT + (SkillController.ACTIONS.size() - 1) * SLOT_GAP
	var x := plate.get_center().x - total / 2.0 + i * (SLOT + SLOT_GAP)
	return Rect2(x, plate.position.y + 18.0, SLOT, SLOT)


func _flask_rect(i: int) -> Rect2:
	var plate := _plate_rect()
	return Rect2(plate.position.x + 16.0 + i * (FLASK_SIZE.x + 6.0), plate.position.y + 8.0, FLASK_SIZE.x, FLASK_SIZE.y)


func _xp_rect() -> Rect2:
	var plate := _plate_rect()
	return Rect2(plate.position.x, plate.position.y - 9.0, plate.size.x, 7.0)


func _layout() -> void:
	var r := ORB_RADIUS
	_place("life", Rect2(_life_center() - Vector2(r, r), Vector2(r, r) * 2.0))
	_place("mana", Rect2(_mana_center() - Vector2(r, r), Vector2(r, r) * 2.0))
	_place("xp", _xp_rect().grow(3.0))
	for i in Inventory.FLASK_SLOTS:
		_place("flask_%d" % i, _flask_rect(i))
	for i in SkillController.ACTIONS.size():
		_place("skill_%d" % i, _slot_rect(i))
	var plate := _plate_rect()
	for i in _menu_buttons.size():
		_menu_buttons[i].position = Vector2(plate.end.x - _menu_buttons.size() * 40.0 - 12.0 + i * 40.0, plate.position.y + 32.0)
		_menu_buttons[i].size = Vector2(34, 30)


func _place(key: String, rect: Rect2) -> void:
	_hotspots[key].position = rect.position
	_hotspots[key].size = rect.size


# --- Actualización ---

func _process(delta: float) -> void:
	queue_redraw()
	for k in _slot_flash.size():
		_slot_flash[k] = maxf(0.0, _slot_flash[k] - delta)
	_update_target(delta)
	_info_timer -= delta
	if _info_timer > 0.0 or character == null:
		return
	_info_timer = 0.25
	_info.text = "FPS %d  ·  Enemigos %d  ·  Simulación %.2f ms  ·  F1-F4: depuración" % [
		Engine.get_frames_per_second(), enemies.count(), enemies.last_simulation_ms]
	_update_tooltips()


func _update_tooltips() -> void:
	_hotspots["life"].tooltip_text = "Vida: %d / %d\nEscudo de energía: %d / %d\nSi llega a 0, game over. Bueno, reaparecer en el campamento." % [
		player.life, player.max_life(), player.energy_shield, player.max_energy_shield()]
	_hotspots["mana"].tooltip_text = "Maná: %d / %d\nLo gastan las habilidades. Se regenera solo, a diferencia de tu motivación." % [
		player.mana, player.max_mana()]
	if player.mana_reserved > 0.0:
		_hotspots["mana"].tooltip_text += "\nReservado: %d %% (%d) por tus invocaciones persistentes." % [
			roundi(player.mana_reserved * 100.0), player.unreserved_mana_max() * player.mana_reserved]
	var states := _player_states()
	if not states.is_empty():
		var lines := PackedStringArray()
		for s in states:
			lines.append(StatusIcon.tooltip(s["id"], s["time"]))
		_hotspots["life"].tooltip_text += "\n\nEstados:\n" + "\n".join(lines)
	_hotspots["xp"].tooltip_text = "Nivel %d · Experiencia %d / %d\nCada nivel da un punto de pasiva (P)." % [
		character.level, character.experience, character.experience_to_next()]
	for i in Inventory.FLASK_SLOTS:
		var f := player.flask_at(i)
		if f == null:
			_hotspots["flask_%d" % i].tooltip_text = "Ranura de poción vacía (tecla %d).\nArrastra una poción desde el inventario (I)." % (i + 1)
			continue
		_hotspots["flask_%d" % i].tooltip_text = "%s (tecla %d) · %s\n%s\n%s\nCargas: %d / %d. Matar enemigos las recarga." % [
			f.display_name(), i + 1, Flask.KIND_NAMES[f.kind()], f.def.get("description", ""), "\n".join(f.effect_lines()),
			f.charges, f.max_charges()]
	for i in SkillController.ACTIONS.size():
		_hotspots["skill_%d" % i].tooltip_text = _skill_tooltip(i)


func _skill_tooltip(i: int) -> String:
	var key: String = SkillController.KEY_LABELS[i]
	var board: Motherboard = character.inventory.boards[i]
	if board == null:
		return "Ranura vacía (%s).\nInstala una placa base desde el menú de habilidades (K)." % key
	var p := skills.profile(i)
	var text := "%s · nivel %d (%s)\n%s\n" % [p["name"], board.level, key, board.skill_def.get("description", "")]
	if p["max_damage"] > 0.0:
		text += "\nDaño: %d-%d  ·  Crítico: %.1f%%" % [p["min_damage"], p["max_damage"], p["crit_chance"]]
	text += "\nCoste: %d de maná  ·  %.2f usos/s" % [p["mana_cost"], p["uses_per_second"]]
	if p["cooldown"] > 0.0:
		text += "  ·  Enfriamiento: %.1f s" % p["cooldown"]
	if p["kind"] == "unit":
		text += "\nPersistente: hasta %d a la vez  ·  Vida %d  ·  Reserva %d %% de maná cada una" % [
			p["max_units"], p["unit_life"], roundi(p["reserve"])]
	if not p["ailments"].is_empty():
		text += "\nEstados: " + Ailments.describe_chances(p["ailments"])
	if p["automaton_speed"] != 1.0:
		text += "\nVelocidad de autómata: ×%.2f" % p["automaton_speed"]
	text += "\nRAM activa: %d de %d ranuras" % [board.active_supports().size(), board.slots.size()]
	return text


## Llama GameUI al usar una habilidad (destello de la ranura).
func notify_skill_used(index: int) -> void:
	if index >= 0 and index < _slot_flash.size():
		_slot_flash[index] = 0.25


## Estados del jugador a partir de sus daños degenerativos: [{id, time}].
func _player_states() -> Array[Dictionary]:
	var best := {}
	for d in player.dots.values():
		var id: String = Ailments.PLAYER_DOT_STATUS.get(d["kind"], "corrupt")
		best[id] = maxf(float(best.get(id, 0.0)), float(d["time"]))
	var out: Array[Dictionary] = []
	for id in best:
		out.append({"id": id, "time": best[id]})
	return out


## Enemigo bajo el cursor; se mantiene un momento tras apartar el ratón.
func _update_target(delta: float) -> void:
	if enemies == null or player == null:
		return
	var i := enemies.hover_index(player.get_global_mouse_position())
	if i != -1:
		_target_id = enemies.ids[i]
		_target_linger = 1.2
	else:
		_target_linger -= delta
		if _target_linger <= 0.0:
			_target_id = -1


# --- Dibujo ---

func _draw() -> void:
	if player == null:
		return
	var font := get_theme_default_font()
	_draw_plate()

	# Orbes.
	var life_center := _life_center()
	var mana_center := _mana_center()
	_draw_orb(life_center, player.life / player.max_life(), LIFE_COLOR)
	var max_es := player.max_energy_shield()
	if max_es > 0.0 and player.energy_shield > 0.0:
		draw_arc(life_center, ORB_RADIUS + 7.0, -PI / 2.0, -PI / 2.0 + TAU * player.energy_shield / max_es,
			64, ES_COLOR, 5.0, true)
	if player.barrier > 0.0:
		# Barrera: aro blanco-azulado por fuera del orbe de vida.
		var frac := player.barrier / maxf(1.0, player.barrier_max)
		draw_arc(life_center, ORB_RADIUS + 13.0, -PI / 2.0, -PI / 2.0 + TAU * frac, 64, Color("cfe8ff"), 4.0, true)
		draw_string(font, life_center + Vector2(-80.0, -ORB_RADIUS - 20.0), "Barrera %d" % player.barrier, HORIZONTAL_ALIGNMENT_CENTER, 160.0, 12, Color("cfe8ff"))
	_draw_orb(mana_center, player.mana / maxf(1.0, player.unreserved_mana_max()), MANA_COLOR, player.mana_reserved)
	_draw_player_states(life_center, font)
	var life_text := "%d / %d" % [player.life, player.max_life()]
	if max_es > 0.0:
		life_text += "\n+%d ES" % player.energy_shield
	draw_multiline_string(font, life_center + Vector2(-80.0, 4.0), life_text, HORIZONTAL_ALIGNMENT_CENTER, 160.0, 16, -1, TEXT_COLOR)
	draw_string(font, mana_center + Vector2(-80.0, 6.0), "%d / %d" % [player.mana, player.max_mana()],
		HORIZONTAL_ALIGNMENT_CENTER, 160.0, 16, TEXT_COLOR)

	# Experiencia.
	var xp := _xp_rect()
	var progress := float(character.experience) / float(character.experience_to_next())
	draw_rect(xp, Color(0, 0, 0, 0.75))
	draw_rect(Rect2(xp.position, Vector2(xp.size.x * progress, xp.size.y)), XP_COLOR)
	for k in range(1, 10):
		var x := xp.position.x + xp.size.x * k / 10.0
		draw_line(Vector2(x, xp.position.y), Vector2(x, xp.end.y), Color(0, 0, 0, 0.5), 1.0)
	draw_rect(xp, TRIM, false, 1.0)
	var level_text := "Nivel %d" % character.level
	var plate := _plate_rect()
	draw_string(font, Vector2(plate.end.x - _menu_buttons.size() * 40.0 - 12.0, plate.position.y + 24.0), level_text,
		HORIZONTAL_ALIGNMENT_LEFT, -1, 14, TEXT_COLOR)

	# Pociones.
	for i in Inventory.FLASK_SLOTS:
		_draw_flask(i, font)

	# Habilidades.
	for i in SkillController.ACTIONS.size():
		_draw_skill_slot(i, font)

	_draw_status_boxes(font)
	_draw_target_frame(font)


## Estados del jugador (quemado, envenenado...) en fila sobre el orbe de vida.
func _draw_player_states(life_center: Vector2, font: Font) -> void:
	var states := _player_states()
	if states.is_empty():
		return
	var side := 26.0
	var y := life_center.y - ORB_RADIUS - 52.0 - (16.0 if player.barrier > 0.0 else 0.0)
	var x := life_center.x - (states.size() * (side + 4.0) - 4.0) / 2.0
	for s in states:
		var r := Rect2(x, y, side, side)
		StatusIcon.draw(self, r, s["id"])
		draw_string_outline(font, r.position + Vector2(0, side + 11.0), "%.0fs" % ceilf(s["time"]), HORIZONTAL_ALIGNMENT_CENTER, side, 10, 3, Color.BLACK)
		draw_string(font, r.position + Vector2(0, side + 11.0), "%.0fs" % ceilf(s["time"]), HORIZONTAL_ALIGNMENT_CENTER, side, 10, Ailments.color(s["id"]))
		x += side + 4.0


## Marco del objetivo (arriba, centrado): nombre, vida y estados del enemigo
## bajo el cursor, como en PoE.
func _draw_target_frame(font: Font) -> void:
	if _target_id == -1:
		return
	var i := enemies.index_of(_target_id)
	if i == -1:
		_target_id = -1
		return
	var rarity: int = enemies.rarities[i]
	var color := Rarity.enemy_color(rarity)
	var types := EnemyManager.enemy_types()
	var type_name: String = types[enemies.types[i]].get("name", "") if enemies.types[i] < types.size() else ""
	var title: String = enemies.names[i] if enemies.names[i] != "" else type_name
	var states := enemies.ailments_of(i)
	# Estados en filas: cada uno es icono + "Nombre ×n 3s".
	var labels: Array[String] = []
	var rows := 1 if not states.is_empty() else 0
	var row_x := 10.0
	for s in states:
		var label := Ailments.display_name(s["id"])
		if int(s.get("stacks", 0)) > 1:
			label += " ×%d" % s["stacks"]
		label += " %.0fs" % ceilf(s["time"])
		labels.append(label)
		var w := 30.0 + font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, 11).x
		if row_x + w > TARGET_SIZE.x - 10.0 and row_x > 10.0:
			rows += 1
			row_x = 10.0
		row_x += w
	var box := Rect2(Vector2((size.x - TARGET_SIZE.x) / 2.0, 10.0), TARGET_SIZE + Vector2(0, 22.0 * rows + (8.0 if rows > 0 else 0.0)))
	draw_rect(box, Color(PLATE, 0.92))
	draw_rect(box, TRIM if rarity >= Rarity.Enemy.ELITE else TRIM.darkened(0.4), false, 1.5)
	draw_string_outline(font, box.position + Vector2(0, 17), title, HORIZONTAL_ALIGNMENT_CENTER, box.size.x, 15, 4, Color.BLACK)
	draw_string(font, box.position + Vector2(0, 17), title, HORIZONTAL_ALIGNMENT_CENTER, box.size.x, 15,
		color if rarity != Rarity.Enemy.NORMAL else TEXT_COLOR)
	if title != type_name and type_name != "":
		draw_string(font, box.position + Vector2(8, 17), type_name, HORIZONTAL_ALIGNMENT_LEFT, -1, 10, MUTED)
	var bar := Rect2(box.position + Vector2(10, 24), Vector2(box.size.x - 20.0, 12))
	var frac: float = clampf(enemies.lives[i] / enemies.max_lives[i], 0.0, 1.0)
	draw_rect(bar, Color(0, 0, 0, 0.8))
	draw_rect(Rect2(bar.position, Vector2(bar.size.x * frac, bar.size.y)), Color("a02020"))
	draw_rect(Rect2(bar.position, Vector2(bar.size.x * frac, 3.0)), Color(1, 1, 1, 0.18))
	draw_rect(bar, Color(0, 0, 0, 0.9), false, 1.0)
	draw_string_outline(font, bar.position + Vector2(0, 10), "%d %%" % ceili(frac * 100.0), HORIZONTAL_ALIGNMENT_CENTER, bar.size.x, 10, 3, Color.BLACK)
	draw_string(font, bar.position + Vector2(0, 10), "%d %%" % ceili(frac * 100.0), HORIZONTAL_ALIGNMENT_CENTER, bar.size.x, 10, TEXT_COLOR)
	if enemies.immune[i] == 1:
		draw_string(font, bar.position + Vector2(0, 10), "INMUNE", HORIZONTAL_ALIGNMENT_RIGHT, bar.size.x - 4.0, 10, ES_COLOR)
	# Estados con su icono, nombre y tiempo.
	var x := box.position.x + 10.0
	var y := bar.end.y + 6.0
	for k in states.size():
		var w := font.get_string_size(labels[k], HORIZONTAL_ALIGNMENT_LEFT, -1, 11).x
		if x - box.position.x + 30.0 + w > box.size.x - 10.0 and x > box.position.x + 10.0:
			x = box.position.x + 10.0
			y += 22.0
		StatusIcon.draw(self, Rect2(x, y, 16, 16), states[k]["id"])
		draw_string(font, Vector2(x + 20.0, y + 12.0), labels[k], HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Ailments.color(states[k]["id"]))
		x += 30.0 + w


## Recuadros de lo que está activo: esbirros, torretas, trampas, minas, giros y
## efectos de pociones de utilidad, con el tiempo que les queda.
func _draw_status_boxes(font: Font) -> void:
	var entries: Array[Dictionary] = skills.active_summaries() if skills else []
	for effect in character.timed_effects:
		var eid: String = effect["id"]
		if eid.begins_with("skill:"):
			# Potenciadores de habilidades (Modo Seguro, Hiperthreading...).
			var skill: Dictionary = GameData.items.skills.skills.get(eid.trim_prefix("skill:"), {})
			entries.append({"name": skill.get("name", "Efecto"), "skill": skill, "count": 1, "remaining": effect["time_left"],
				"total": effect.get("total", effect["time_left"]), "kind": "buff"})
			continue
		var flask_id: String = eid.trim_prefix("flask:")
		entries.append({"name": GameData.items.flasks.get(flask_id, {}).get("name", flask_id), "flask": flask_id,
			"count": 1, "remaining": effect["time_left"], "total": effect.get("total", effect["time_left"]), "kind": "flask"})
	if player.barrier > 0.0:
		entries.append({"name": "Barrera", "skill": GameData.items.skills.skills.get("firewall_personal", {}), "count": 1,
			"remaining": player.barrier_time, "total": maxf(player.barrier_time, 6.0), "kind": "buff"})
	if entries.is_empty():
		return
	var box := 44.0
	var gap := 30.0
	var first := _slot_rect(0)
	var x := first.position.x
	var y := first.position.y - box - 34.0
	var kind_colors := {"minion": Color("7fd07f"), "totem": Color("d9a441"), "trap": Color("b07a3a"), "mine": Color("a0a040"),
		"spin": Color("b8b8c8"), "flask": Color("6fd36b"), "buff": Color("8ab0e0"), "drones": Color("e8d070"), "unit": Color("9ad0ff")}
	for e in entries:
		var r := Rect2(x, y, box, box)
		var color: Color = kind_colors.get(e["kind"], TRIM)
		var persistent: bool = e.get("persistent", false)
		draw_rect(r.grow(2.0), Color(0, 0, 0, 0.7))
		if e.has("flask"):
			ItemIcons.draw(self, r.grow(-4.0), GameData.items.flasks.get(e["flask"], {}).get("icon", e["flask"]), Color.WHITE, false)
		elif not e["skill"].is_empty():
			SkillIcon.draw(self, r.grow(-3.0), e["skill"])
		var frac: float = clampf(e["remaining"] / maxf(0.1, e["total"]), 0.0, 1.0)
		# Barra: tiempo restante o, en las persistentes, la vida (verde).
		var bar_color := Color("6fd36b").lerp(Color("e06c6c"), 1.0 - frac) if persistent else color
		draw_rect(Rect2(r.position.x, r.end.y + 2.0, r.size.x, 4.0), Color(0, 0, 0, 0.8))
		draw_rect(Rect2(r.position.x, r.end.y + 2.0, r.size.x * frac, 4.0), bar_color)
		var blink := frac < 0.2 and fmod(Time.get_ticks_msec() / 1000.0, 0.5) < 0.25
		draw_rect(r, color if not blink else Color.WHITE, false, 2.0)
		if int(e["count"]) > 1:
			draw_string_outline(font, r.position + Vector2(r.size.x - 18.0, 14.0), "x%d" % e["count"], HORIZONTAL_ALIGNMENT_LEFT, -1, 12, 4, Color.BLACK)
			draw_string(font, r.position + Vector2(r.size.x - 18.0, 14.0), "x%d" % e["count"], HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color.WHITE)
		if persistent:
			# Sin cuenta atrás: no caducan. Símbolo de infinito.
			StatusIcon.draw(self, Rect2(r.position + Vector2(r.size.x / 2.0 - 8.0, r.size.y - 14.0), Vector2(16, 12)), "reserve", true)
		else:
			draw_string_outline(font, r.position + Vector2(0, r.size.y - 4.0), "%ds" % ceili(e["remaining"]), HORIZONTAL_ALIGNMENT_CENTER, r.size.x, 11, 4, Color.BLACK)
			draw_string(font, r.position + Vector2(0, r.size.y - 4.0), "%ds" % ceili(e["remaining"]), HORIZONTAL_ALIGNMENT_CENTER, r.size.x, 11, TEXT_COLOR)
		# Nombre corto (primera palabra) si el completo no cabe sobre la caja.
		var label: String = e["name"]
		if font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, 10).x > r.size.x + gap - 4.0:
			label = label.get_slice(" ", 0)
		draw_string_outline(font, r.position + Vector2(-gap / 2.0, -4.0), label, HORIZONTAL_ALIGNMENT_CENTER, r.size.x + gap, 10, 4, Color.BLACK)
		draw_string(font, r.position + Vector2(-gap / 2.0, -4.0), label, HORIZONTAL_ALIGNMENT_CENTER, r.size.x + gap, 10, color)
		x += box + gap


func _draw_plate() -> void:
	var plate := _plate_rect()
	draw_rect(plate, Color(PLATE, 0.96))
	draw_line(plate.position, Vector2(plate.end.x, plate.position.y), TRIM, 2.0)
	# Remates que unen la placa con los orbes.
	for side in [-1.0, 1.0]:
		var x: float = plate.position.x if side < 0.0 else plate.end.x
		draw_colored_polygon(PackedVector2Array([
			Vector2(x, plate.position.y), Vector2(x + side * 26.0, plate.position.y + 26.0),
			Vector2(x + side * 26.0, size.y), Vector2(x, size.y)]), Color(PLATE, 0.96))


func _draw_flask(i: int, font: Font) -> void:
	var r := _flask_rect(i)
	var f := player.flask_at(i)
	draw_rect(r, Color(0, 0, 0, 0.55))
	if f == null:
		draw_rect(r, TRIM.darkened(0.6), false, 1.0)
		draw_string(font, r.position + Vector2(4.0, r.size.y - 4.0), str(i + 1), HORIZONTAL_ALIGNMENT_LEFT, -1, 13, MUTED)
		return
	var color := f.display_color()
	var fill := f.charges / f.max_charges()
	var usable := player.can_use_flask(i)
	var t := Time.get_ticks_msec() / 1000.0
	if player.is_flask_active(i):
		draw_rect(r, Color(color, 0.25 + 0.1 * sin(t * 8.0)))  # efecto activo
	# El sprite (taza, lata, botella), apagado si no hay cargas suficientes.
	var icon_rect := Rect2(r.position + Vector2(1, 3), Vector2(r.size.x - 10.0, r.size.y - 8.0))
	ItemIcons.draw(self, icon_rect, f.icon(), Color.WHITE if usable else Color(0.45, 0.45, 0.5), false)
	# Barra de cargas a la derecha, con una marca por cada uso.
	var bar := Rect2(r.end.x - 7.0, r.position.y + 4.0, 4.0, r.size.y - 8.0)
	draw_rect(bar, Color(0, 0, 0, 0.8))
	draw_rect(Rect2(bar.position + Vector2(0, bar.size.y * (1.0 - fill)), Vector2(bar.size.x, bar.size.y * fill)), color)
	var uses := int(f.max_charges() / f.cost())
	for k in range(1, uses):
		var y := bar.position.y + bar.size.y * k / uses
		draw_line(Vector2(bar.position.x, y), Vector2(bar.end.x, y), Color(0, 0, 0, 0.9), 1.0)
	# Vapor del café o burbujas de las bebidas cuando está lista.
	if usable:
		var top := icon_rect.position + Vector2(icon_rect.size.x * 0.45, 4.0)
		if f.kind() == "life":
			for k in 2:
				var phase := fmod(t * 0.8 + k * 0.5, 1.0)
				var p0 := top + Vector2(k * 8.0 - 4.0 + sin(t * 3.0 + k) * 2.0, -phase * 10.0)
				draw_line(p0, p0 + Vector2(sin(t * 4.0 + k) * 2.0, -5.0), Color(1, 1, 1, 0.5 * (1.0 - phase)), 1.5, true)
		else:
			for k in 3:
				var phase := fmod(t * 0.7 + k * 0.33, 1.0)
				draw_circle(top + Vector2(k * 5.0 - 5.0, 18.0 - phase * 22.0), 1.5, Color(color.lightened(0.5), 0.6 * (1.0 - phase)))
	draw_rect(r, TRIM if usable else TRIM.darkened(0.5), false, 1.5)
	draw_string(font, r.position + Vector2(3.0, r.size.y - 3.0), str(i + 1), HORIZONTAL_ALIGNMENT_LEFT, -1, 12, TEXT_COLOR)
	draw_string(font, r.position + Vector2(0.0, r.size.y + 12.0), "%d/%d" % [f.charges, f.max_charges()],
		HORIZONTAL_ALIGNMENT_CENTER, r.size.x, 10, MUTED)

func _draw_skill_slot(i: int, font: Font) -> void:
	var r := _slot_rect(i)
	# Marco: hueco hundido con borde dorado (como las ranuras de PoE).
	draw_rect(r.grow(3.0), Color(0, 0, 0, 0.75))
	draw_rect(r.grow(3.0), TRIM.darkened(0.45), false, 1.0)
	draw_rect(r, Color(0, 0, 0, 0.7))
	var board: Motherboard = character.inventory.boards[i]
	var key_color := TEXT_COLOR
	if board:
		var p := skills.profile(i)
		var no_mana: bool = player.mana < p.get("mana_cost", 0.0)
		SkillIcon.draw(self, r.grow(-2.0), board.skill_def, no_mana)
		var cd := skills.cooldown_fraction(i)
		if cd > 0.0:
			_draw_pie(r.get_center(), r.size.x * 0.48, cd, Color(0, 0, 0, 0.62))
			var left: float = skills.cooldowns[i]
			var cd_text := ("%.1f" % left) if left < 3.0 else str(ceili(left))
			draw_string_outline(font, r.position + Vector2(0, r.size.y * 0.5 + 7.0), cd_text, HORIZONTAL_ALIGNMENT_CENTER, r.size.x, 18, 5, Color.BLACK)
			draw_string(font, r.position + Vector2(0, r.size.y * 0.5 + 7.0), cd_text, HORIZONTAL_ALIGNMENT_CENTER, r.size.x, 18, Color.WHITE)
		if not p.is_empty():
			SkillIcon.draw_ailment_pips(self, r, p.get("ailments", {}))
			if p["kind"] == "unit":
				# Invocaciones vivas / máximo, arriba a la izquierda.
				var alive := 0
				for e in skills.active_summaries():
					if e.get("persistent", false) and e["skill"].get("id", "") == p["id"]:
						alive = e["count"]
				var units_text := "%d/%d" % [alive, p["max_units"]]
				draw_string_outline(font, r.position + Vector2(3, 12), units_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 10, 3, Color.BLACK)
				draw_string(font, r.position + Vector2(3, 12), units_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color("9ad0ff"))
		# Coste de maná en una chapita arriba a la derecha.
		var cost_text := "%d" % p.get("mana_cost", 0)
		var cost_w := font.get_string_size(cost_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 10).x + 6.0
		var cost_rect := Rect2(r.end.x - cost_w - 1.0, r.position.y + 1.0, cost_w, 13.0)
		draw_rect(cost_rect, Color(0.04, 0.06, 0.14, 0.85))
		draw_string(font, cost_rect.position + Vector2(0, 10.5), cost_text, HORIZONTAL_ALIGNMENT_CENTER, cost_w, 10,
			Color("e06c6c") if no_mana else Color("8ab8ff"))
		var flash := _slot_flash[i] / 0.25
		draw_rect(r, Motherboard.COLOR.darkened(0.2).lerp(Color("ffe8a0"), flash), false, 1.5 + 1.5 * flash)
		if no_mana:
			key_color = Color("e06c6c")
	else:
		draw_rect(r, Color("3a3442"), false, 1.0)
	# Tecla en una chapita abajo a la izquierda.
	var key: String = SkillController.KEY_LABELS[i]
	var key_w := font.get_string_size(key, HORIZONTAL_ALIGNMENT_LEFT, -1, 11).x + 8.0
	var key_rect := Rect2(r.position.x - 2.0, r.end.y - 12.0, key_w, 14.0)
	draw_rect(key_rect, Color(PLATE, 0.95))
	draw_rect(key_rect, TRIM.darkened(0.2), false, 1.0)
	draw_string(font, key_rect.position + Vector2(0, 11.0), key, HORIZONTAL_ALIGNMENT_CENTER, key_w, 11, key_color)


## Sector circular para el enfriamiento (empieza arriba, sentido horario).
func _draw_pie(center: Vector2, radius: float, fraction: float, color: Color) -> void:
	var points := PackedVector2Array([center])
	var steps := 24
	for k in steps + 1:
		points.append(center + Vector2.from_angle(-PI / 2.0 + TAU * fraction * k / steps) * radius)
	draw_colored_polygon(points, color)


## Orbe estilo PoE: círculo rellenado desde abajo según `fill` (0..1), con marco.
## `reserved`: fracción de arriba que no se puede usar (maná reservado), rayada.
func _draw_orb(center: Vector2, fill: float, color: Color, reserved := 0.0) -> void:
	fill = clampf(fill, 0.0, 1.0)
	draw_circle(center, ORB_RADIUS + 10.0, Color(PLATE, 0.96))
	draw_circle(center, ORB_RADIUS, Color(0.05, 0.04, 0.06, 0.95))
	if fill > 0.01:
		draw_colored_polygon(_orb_segment(center, 0.0, fill), color)
		# Ondas en la superficie del líquido.
		var surface_y := center.y + ORB_RADIUS * (1.0 - 2.0 * fill)
		var half := sqrt(maxf(0.0, ORB_RADIUS * ORB_RADIUS - pow(surface_y - center.y, 2.0)))
		if half > 4.0:
			var wave := PackedVector2Array()
			var t := Time.get_ticks_msec() / 1000.0
			for k in 13:
				var x := center.x - half + 2.0 * half * k / 12.0
				wave.append(Vector2(x, surface_y + sin(t * 3.0 + k * 0.9) * 1.5))
			draw_polyline(wave, color.lightened(0.35), 1.5, true)
		# Brillo.
		draw_circle(center + Vector2(-ORB_RADIUS * 0.35, -ORB_RADIUS * 0.4), ORB_RADIUS * 0.18, Color(1, 1, 1, 0.08))
	if reserved > 0.005:
		draw_colored_polygon(_orb_segment(center, 1.0 - reserved, 1.0), Color(0.12, 0.14, 0.22, 0.92))
		var line_y := center.y + ORB_RADIUS * (1.0 - 2.0 * (1.0 - reserved))
		var lhalf := sqrt(maxf(0.0, ORB_RADIUS * ORB_RADIUS - pow(line_y - center.y, 2.0)))
		draw_line(Vector2(center.x - lhalf, line_y), Vector2(center.x + lhalf, line_y), Color("9ad0ff"), 1.5)
		# Rayado diagonal recortado al círculo.
		var top := center.y - ORB_RADIUS
		for k in range(-12, 13):
			var x0 := center.x + k * 12.0
			var a := Vector2(x0, line_y)
			var b := Vector2(x0 + (line_y - top), top)
			var pts := _clip_to_circle(a, b, center, ORB_RADIUS - 1.0)
			if pts.size() == 2:
				draw_line(pts[0], pts[1], Color(0.6, 0.8, 1.0, 0.12), 2.0)


## Polígono de la franja del orbe entre las alturas `from` y `to` (0 = abajo, 1 = arriba).
func _orb_segment(center: Vector2, from: float, to: float) -> PackedVector2Array:
	var points := PackedVector2Array()
	var steps := 48
	# Arco de la parte de abajo (de la línea de "to" hacia la de "from"), por la derecha y por la izquierda.
	var y_top := center.y + ORB_RADIUS * (1.0 - 2.0 * clampf(to, 0.0, 1.0))
	var y_bottom := center.y + ORB_RADIUS * (1.0 - 2.0 * clampf(from, 0.0, 1.0))
	for side in [1.0, -1.0]:
		for k in steps + 1:
			var s := float(k) / steps
			var y := lerpf(y_top, y_bottom, s) if side > 0.0 else lerpf(y_bottom, y_top, s)
			var p := Vector2(center.x + side * sqrt(maxf(0.0, ORB_RADIUS * ORB_RADIUS - pow(y - center.y, 2.0))), y)
			# Sin vértices repetidos (en los polos del círculo coinciden): la triangulación fallaría.
			if points.is_empty() or points[points.size() - 1].distance_to(p) > 0.05:
				points.append(p)
	if points.size() > 2 and points[0].distance_to(points[points.size() - 1]) <= 0.05:
		points.remove_at(points.size() - 1)
	return points


## Recorta el segmento a-b a un círculo; [] si queda fuera.
func _clip_to_circle(a: Vector2, b: Vector2, center: Vector2, radius: float) -> PackedVector2Array:
	var out := PackedVector2Array()
	var steps := 24
	var inside_prev := false
	for k in steps + 1:
		var p := a.lerp(b, float(k) / steps)
		var inside := p.distance_to(center) <= radius
		if inside and not inside_prev and out.is_empty():
			out.append(p)
		elif not inside and inside_prev and out.size() == 1:
			out.append(a.lerp(b, float(k - 1) / steps))
			break
		inside_prev = inside
	if out.size() == 1:
		out.append(b)
	return out
	draw_arc(center, ORB_RADIUS, 0.0, TAU, 64, TRIM, 3.0, true)
	draw_arc(center, ORB_RADIUS + 10.0, 0.0, TAU, 64, TRIM.darkened(0.4), 2.0, true)
