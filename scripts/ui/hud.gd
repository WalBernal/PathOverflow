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
const FLASK_SIZE := Vector2(40, 58)
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
	_message.offset_top = 90.0

	for key in ["life", "mana", "xp", "flask_0", "flask_1", "skill_0", "skill_1", "skill_2", "skill_3", "skill_4", "skill_5"]:
		var spot := Control.new()
		spot.mouse_filter = Control.MOUSE_FILTER_STOP
		add_child(spot)
		_hotspots[key] = spot
	for entry in [["I", "inventory", "Inventario (I): equipo y bolsa."],
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
	return Rect2(plate.position.x + 20.0 + i * (FLASK_SIZE.x + 10.0), plate.position.y + 10.0, FLASK_SIZE.x, FLASK_SIZE.y)


func _xp_rect() -> Rect2:
	var plate := _plate_rect()
	return Rect2(plate.position.x, plate.position.y - 9.0, plate.size.x, 7.0)


func _layout() -> void:
	var r := ORB_RADIUS
	_place("life", Rect2(_life_center() - Vector2(r, r), Vector2(r, r) * 2.0))
	_place("mana", Rect2(_mana_center() - Vector2(r, r), Vector2(r, r) * 2.0))
	_place("xp", _xp_rect().grow(3.0))
	for i in 2:
		_place("flask_%d" % i, _flask_rect(i))
	for i in SkillController.ACTIONS.size():
		_place("skill_%d" % i, _slot_rect(i))
	var plate := _plate_rect()
	for i in _menu_buttons.size():
		_menu_buttons[i].position = Vector2(plate.end.x - 3 * 40.0 - 12.0 + i * 40.0, plate.position.y + 32.0)
		_menu_buttons[i].size = Vector2(34, 30)


func _place(key: String, rect: Rect2) -> void:
	_hotspots[key].position = rect.position
	_hotspots[key].size = rect.size


# --- Actualización ---

func _process(delta: float) -> void:
	queue_redraw()
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
	_hotspots["xp"].tooltip_text = "Nivel %d · Experiencia %d / %d\nCada nivel da un punto de pasiva (P)." % [
		character.level, character.experience, character.experience_to_next()]
	for i in 2:
		var f: Dictionary = Player.FLASKS[i]
		_hotspots["flask_%d" % i].tooltip_text = "%s (tecla %d)\n%s\nCargas: %d / %d (cada uso gasta %d; matar enemigos las recarga)." % [
			f["name"], i + 1, f["description"], player.flask_charges[i], f["max_charges"], f["cost"]]
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
	text += "\nRAM activa: %d de %d ranuras" % [board.active_supports().size(), board.slots.size()]
	return text


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
	_draw_orb(mana_center, player.mana / maxf(1.0, player.max_mana()), MANA_COLOR)
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
	draw_string(font, Vector2(plate.end.x - 3 * 40.0 - 12.0, plate.position.y + 24.0), level_text,
		HORIZONTAL_ALIGNMENT_LEFT, -1, 14, TEXT_COLOR)

	# Pociones.
	for i in 2:
		_draw_flask(i, font)

	# Habilidades.
	for i in SkillController.ACTIONS.size():
		_draw_skill_slot(i, font)


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
	var f: Dictionary = Player.FLASKS[i]
	var fill: float = player.flask_charges[i] / f["max_charges"]
	var usable := player.can_use_flask(i)
	# Cuello y cuerpo de la botella.
	var neck := Rect2(r.position + Vector2(r.size.x * 0.3, 0.0), Vector2(r.size.x * 0.4, 10.0))
	var body := Rect2(r.position + Vector2(0.0, 10.0), r.size - Vector2(0.0, 10.0))
	draw_rect(body, Color(0, 0, 0, 0.6))
	var liquid := Rect2(body.position + Vector2(0.0, body.size.y * (1.0 - fill)), Vector2(body.size.x, body.size.y * fill))
	draw_rect(liquid, f["color"] if usable else Color(f["color"]).darkened(0.5))
	draw_rect(body, TRIM, false, 1.5)
	draw_rect(neck, TRIM, false, 1.5)
	draw_string(font, r.position + Vector2(3.0, r.size.y - 4.0), str(i + 1), HORIZONTAL_ALIGNMENT_LEFT, -1, 13, TEXT_COLOR)
	draw_string(font, r.position + Vector2(0.0, r.size.y + 13.0), "x%d" % floori(player.flask_charges[i] / f["cost"]),
		HORIZONTAL_ALIGNMENT_CENTER, r.size.x, 11, MUTED)


func _draw_skill_slot(i: int, font: Font) -> void:
	var r := _slot_rect(i)
	draw_rect(r, Color(0, 0, 0, 0.7))
	var board: Motherboard = character.inventory.boards[i]
	if board:
		var p := skills.profile(i)
		var no_mana: bool = player.mana < p.get("mana_cost", 0.0)
		SkillIcon.draw(self, r.grow(-4.0), board.skill_def, no_mana)
		var cd := skills.cooldown_fraction(i)
		if cd > 0.0:
			_draw_pie(r.get_center(), r.size.x * 0.48, cd, Color(0, 0, 0, 0.6))
		draw_string(font, r.position + Vector2(0.0, 13.0), "%d" % p.get("mana_cost", 0), HORIZONTAL_ALIGNMENT_RIGHT, r.size.x - 4.0, 11,
			Color("e06c6c") if no_mana else Color("7fa8e0"))
		draw_rect(r, Motherboard.COLOR.darkened(0.2), false, 1.5)
	else:
		draw_rect(r, Color("3a3442"), false, 1.0)
	draw_string(font, r.position + Vector2(4.0, r.size.y - 5.0), SkillController.KEY_LABELS[i],
		HORIZONTAL_ALIGNMENT_LEFT, -1, 12, TEXT_COLOR)


## Sector circular para el enfriamiento (empieza arriba, sentido horario).
func _draw_pie(center: Vector2, radius: float, fraction: float, color: Color) -> void:
	var points := PackedVector2Array([center])
	var steps := 24
	for k in steps + 1:
		points.append(center + Vector2.from_angle(-PI / 2.0 + TAU * fraction * k / steps) * radius)
	draw_colored_polygon(points, color)


## Orbe estilo PoE: círculo rellenado desde abajo según `fill` (0..1), con marco.
func _draw_orb(center: Vector2, fill: float, color: Color) -> void:
	fill = clampf(fill, 0.0, 1.0)
	draw_circle(center, ORB_RADIUS + 10.0, Color(PLATE, 0.96))
	draw_circle(center, ORB_RADIUS, Color(0.05, 0.04, 0.06, 0.95))
	if fill > 0.01:
		# Arco desde la línea de llenado, pasando por abajo (sin(t) > 0 es "abajo").
		var start := asin(clampf(1.0 - 2.0 * fill, -1.0, 1.0))
		var points := PackedVector2Array()
		var steps := 48
		for k in steps + 1:
			var t := lerpf(start, PI - start, float(k) / steps)
			points.append(center + Vector2(cos(t), sin(t)) * ORB_RADIUS)
		draw_colored_polygon(points, color)
		# Brillo.
		draw_circle(center + Vector2(-ORB_RADIUS * 0.35, -ORB_RADIUS * 0.4), ORB_RADIUS * 0.18, Color(1, 1, 1, 0.08))
	draw_arc(center, ORB_RADIUS, 0.0, TAU, 64, TRIM, 3.0, true)
	draw_arc(center, ORB_RADIUS + 10.0, 0.0, TAU, 64, TRIM.darkened(0.4), 2.0, true)
