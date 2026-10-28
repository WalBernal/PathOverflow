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
## Menús con algo nuevo que ver ("skills", "passives"...): su botón lleva un «!»
## dorado que late hasta que se abre (p. ej. al desbloquear una habilidad).
var attention := {}
const MENU_IDS := ["character", "inventory", "skills", "passives", "catalog"]
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
	_message.anchor_top = 1.0   # avisos sobre las cajas de estado, lejos de los marcos de arriba
	_message.anchor_bottom = 1.0
	_message.offset_top = -245.0
	_message.offset_bottom = -215.0

	for key in ["life", "mana", "xp", "states", "target", "flask_0", "flask_1", "flask_2", "flask_3", "flask_4", "skill_0", "skill_1", "skill_2", "skill_3", "skill_4", "skill_5", "dodge"]:
		var spot := Control.new()
		spot.mouse_filter = Control.MOUSE_FILTER_STOP
		add_child(spot)
		_hotspots[key] = spot
	for entry in [["C", "character", "Personaje (C): stats, resistencias y opiniones no solicitadas."],
			["I", "inventory", "Inventario (I): equipo y bolsa."],
			["K", "skills", "Habilidades (K): placas base y módulos RAM."],
			["P", "passives", "Árbol pasivo (P): gasta tus puntos. O no, y quéjate en los foros."],
			["B", "catalog", "Catálogo de hardware (B): todas las placas base y módulos RAM, con lo que ya encontraste."]]:
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
	if color.is_equal_approx(UiStyle.DANGER):
		Sfx.play("ui_error", -10.0)   # los avisos en rojo son errores (T77)
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
	if touch_layout:
		return not touch_button_at(pos).is_empty() or pos.distance_to(_life_center()) <= ORB_RADIUS + 10.0 \
			or pos.distance_to(_mana_center()) <= ORB_RADIUS + 10.0
	return pos.y >= _plate_rect().position.y - 12.0 or pos.distance_to(_life_center()) <= ORB_RADIUS + 10.0 \
		or pos.distance_to(_mana_center()) <= ORB_RADIUS + 10.0


# --- Geometría ---

## Con pantalla táctil (T108) el HUD cambia de forma: sin la placa, las 6 habilidades
## en dos arcos a la izquierda del orbe de maná (para el pulgar derecho: la 1, la
## más cerca y más grande), la esquiva encima del orbe, y pociones y botones de menú
## más grandes a la izquierda, fuera del joystick. Los arcos no suben más allá del
## registro de misiones ni con la interfaz al 140 %.
const TOUCH_SLOT := 66.0
const TOUCH_MAIN_SLOT := 76.0
## [radio, grados] de cada habilidad alrededor del centro del orbe de maná.
const TOUCH_RING := [[150.0, 185.0], [150.0, 212.0], [150.0, 239.0], [232.0, 180.0], [232.0, 198.0], [232.0, 216.0]]
const TOUCH_DODGE := 64.0
const TOUCH_FLASK := Vector2(60, 68)
const TOUCH_MENU := Vector2(48, 42)
## Botón de usar (T134): [radio, grados] desde el orbe de maná, más allá de los arcos.
const TOUCH_USE := 74.0
const TOUCH_USE_AT := [318.0, 194.0]
var touch_layout := false
## Lo que usaría el botón (World.touch_use_target): {kind, pos, text} o vacío.
var use_target: Callable
var use_now: Dictionary = {}


## ¿Qué botón táctil hay en `pos`? {kind: "skill"|"dodge"|"flask", index} o vacío.
func touch_button_at(pos: Vector2) -> Dictionary:
	if not touch_layout:
		return {}
	for i in SkillController.ACTIONS.size():
		var r := _slot_rect(i)
		if pos.distance_to(r.get_center()) <= r.size.x * 0.62:
			return {"kind": "skill", "index": i}
	if pos.distance_to(_dodge_rect().get_center()) <= TOUCH_DODGE * 0.62:
		return {"kind": "dodge", "index": 0}
	if not use_now.is_empty() and pos.distance_to(use_rect().get_center()) <= TOUCH_USE * 0.62:
		return {"kind": "use", "index": 0}
	for i in Inventory.FLASK_SLOTS:
		if _flask_rect(i).grow(4.0).has_point(pos):
			return {"kind": "flask", "index": i}
	return {}


func _life_center() -> Vector2:
	return Vector2(ORB_RADIUS + 28.0, size.y - ORB_RADIUS - 18.0)


func _mana_center() -> Vector2:
	return Vector2(size.x - ORB_RADIUS - 28.0, size.y - ORB_RADIUS - 18.0)


func _plate_rect() -> Rect2:
	var left := ORB_RADIUS * 2.0 + 40.0
	return Rect2(left, size.y - PLATE_HEIGHT, size.x - left * 2.0, PLATE_HEIGHT)


func _slot_rect(i: int) -> Rect2:
	if touch_layout:
		var c := _mana_center() + Vector2.from_angle(deg_to_rad(TOUCH_RING[i][1])) * float(TOUCH_RING[i][0])
		var s := TOUCH_MAIN_SLOT if i == 0 else TOUCH_SLOT
		return Rect2(c - Vector2(s, s) * 0.5, Vector2(s, s))
	var plate := _plate_rect()
	var total := SkillController.ACTIONS.size() * SLOT + (SkillController.ACTIONS.size() - 1) * SLOT_GAP
	# Centrada; si la pantalla es estrecha (o la interfaz grande), justo después de las pociones.
	var left := maxf(plate.get_center().x - total / 2.0, _flask_rect(Inventory.FLASK_SLOTS - 1).end.x + 18.0)
	var x := left + i * (SLOT + SLOT_GAP)
	return Rect2(x, plate.position.y + 18.0, SLOT, SLOT)


func _flask_rect(i: int) -> Rect2:
	if touch_layout:
		var left := _life_center().x + ORB_RADIUS + 24.0
		return Rect2(left + i * (TOUCH_FLASK.x + 6.0), size.y - TOUCH_FLASK.y - 30.0, TOUCH_FLASK.x, TOUCH_FLASK.y)
	var plate := _plate_rect()
	return Rect2(plate.position.x + 16.0 + i * (FLASK_SIZE.x + 6.0), plate.position.y + 8.0, FLASK_SIZE.x, FLASK_SIZE.y)


## Botón táctil de usar (T134): abajo, a la izquierda de los arcos de habilidades.
func use_rect() -> Rect2:
	var c := _mana_center() + Vector2.from_angle(deg_to_rad(TOUCH_USE_AT[1])) * float(TOUCH_USE_AT[0])
	return Rect2(c - Vector2(TOUCH_USE, TOUCH_USE) * 0.5, Vector2(TOUCH_USE, TOUCH_USE))


## Casilla de la esquiva, a la derecha de la barra de habilidades.
func _dodge_rect() -> Rect2:
	if touch_layout:
		var c := _mana_center() + Vector2(0.0, -ORB_RADIUS - TOUCH_DODGE * 0.5 - 14.0)
		return Rect2(c - Vector2(TOUCH_DODGE, TOUCH_DODGE) * 0.5, Vector2(TOUCH_DODGE, TOUCH_DODGE))
	var last := _slot_rect(SkillController.ACTIONS.size() - 1)
	return Rect2(last.end.x + 14.0, last.position.y, 34.0, SLOT)


func _xp_rect() -> Rect2:
	if touch_layout:
		var left := _flask_rect(0).position.x
		return Rect2(left, size.y - 11.0, maxf(200.0, _slot_rect(3).position.x - 20.0 - left), 6.0)
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
	_place("dodge", _dodge_rect())
	var origin := _menu_origin()
	var button := TOUCH_MENU if touch_layout else Vector2(34, 30)
	for i in _menu_buttons.size():
		_menu_buttons[i].custom_minimum_size = button
		_menu_buttons[i].position = origin + Vector2(i * (button.x + 6.0), 8.0)
		_menu_buttons[i].size = button


## Esquina de los botones de menú (C, I, K, P) y del "Nivel N": a la derecha de la
## barra; si no caben junto a las habilidades (interfaz grande), encima de la barra.
func _menu_origin() -> Vector2:
	if touch_layout:   # encima de las pociones (debajo de la zona del joystick)
		return Vector2(_flask_rect(0).position.x, _flask_rect(0).position.y - TOUCH_MENU.y - 22.0)
	var plate := _plate_rect()
	var x := plate.end.x - _menu_buttons.size() * 40.0 - 12.0
	var skills_end := _dodge_rect().end.x + 10.0
	if x < skills_end:
		return Vector2(plate.end.x - _menu_buttons.size() * 40.0 - 12.0, plate.position.y - 58.0)
	return Vector2(x, plate.position.y + 24.0)


func _place(key: String, rect: Rect2) -> void:
	_hotspots[key].position = rect.position
	_hotspots[key].size = rect.size


# --- Actualización ---

func _process(delta: float) -> void:
	queue_redraw()
	if Touch.shown() != touch_layout:
		touch_layout = not touch_layout
		_layout()
	use_now = use_target.call() if touch_layout and use_target.is_valid() else {}
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
	_hotspots["mana"].tooltip_text += "\nRegeneración: %.1f /s" % player.mana_regen_per_second()
	var from_mana := minf(ManaMath.MAX_TAKEN_FROM_MANA, player.character.stats.get_value(Stat.DAMAGE_TAKEN_FROM_MANA))
	if from_mana > 0.0:
		_hotspots["mana"].tooltip_text += "\nEl maná se lleva el %d %% del daño antes que la vida." % roundi(from_mana)
	var states := _player_states()
	var buffs := _player_buffs()
	_place("states", _states_rect)
	if not states.is_empty() or not buffs.is_empty():
		var lines := PackedStringArray()
		for s in states:
			lines.append(StatusIcon.tooltip(s["id"], s["time"]))
		for b in buffs:
			lines.append("%s (%.0f s): %s" % [b["name"], b["time"], b["desc"]])
		_hotspots["states"].tooltip_text = "\n".join(lines)
		_hotspots["life"].tooltip_text += "\n\nEstados:\n" + "\n".join(lines)
	else:
		_hotspots["states"].tooltip_text = ""
		_hotspots["states"].size = Vector2.ZERO
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
	_hotspots["dodge"].tooltip_text = "Esquiva · git stash (Espacio · gatillo derecho)\nUn salto corto en la dirección en que te mueves (o hacia el ratón) con un instante de invulnerabilidad: evita golpes, charcos y estados.\nCargas: %d / %d. Se recarga una cada %.1f s." % [
		floori(player.dodge_charges), player.max_dodge_charges(), player.dodge_recharge_time()]


func _skill_tooltip(i: int) -> String:
	var key: String = Controls.key_label(SkillController.ACTIONS[i])
	var board: Motherboard = character.inventory.boards[i]
	if board == null:
		return "Ranura vacía (%s).\nInstala una placa base desde el menú de habilidades (K)." % key
	var p := skills.profile(i)
	var text := "%s · nivel %d (%s)\n%s\n" % [p["name"], board.level, key, board.skill_def.get("description", "")]
	if SkillController.trigger_text(p) != "":
		text += "\n[AUTO] Se lanza sola %s, hacia el enemigo más cercano. No se lanza con la tecla." % SkillController.trigger_text(p)
	if String(p.get("converted_from", "")) != "":
		text += "\nDaño convertido: %s → %s" % [RamModule.DAMAGE_TYPE_NAMES.get(p["converted_from"], p["converted_from"]),
			RamModule.DAMAGE_TYPE_NAMES.get(p["damage_type"], p["damage_type"])]
	for t in p.get("spend_charges", {}):
		text += "\n%s (tienes %d)" % [Charges.SPEND_TEXT[t], int(character.charges.get(t, 0))]
	if p["max_damage"] > 0.0:
		text += "\nDaño: %d-%d  ·  Crítico: %.1f%%" % [p["min_damage"], p["max_damage"], p["crit_chance"]]
	if p["kind"] in SkillController.CHANNEL_KINDS:
		text += "\nCanalizado: %d de maná por segundo  ·  %.2f golpes/s" % [p["mana_cost"], p["uses_per_second"]]
	else:
		text += "\nCoste: %d de maná  ·  %.2f usos/s" % [p["mana_cost"], p["uses_per_second"]]
	if p["cooldown"] > 0.0:
		text += "  ·  Enfriamiento: %.1f s" % p["cooldown"]
	if p["kind"] == "unit":
		text += "\nPersistente: hasta %d a la vez  ·  Vida %d  ·  Reserva %d %% de maná cada una" % [
			p["max_units"], p["unit_life"], roundi(p["reserve"])]
		if not (p.get("owner_buff", []) as Array).is_empty():
			var buff_lines := PackedStringArray()
			for md in p["owner_buff"]:
				buff_lines.append(Modifier.from_dict(md).describe())
			text += "\nMientras viva, te da: " + " · ".join(buff_lines)
	elif p["kind"] == "aura":
		var lines := PackedStringArray()
		for md in p["aura_mods"]:
			lines.append(Modifier.from_dict(md).describe())
		if p["aura_regen"] > 0.0:
			lines.append("Las invocaciones recuperan un %.1f %% de su vida por segundo" % p["aura_regen"])
		if p["aura_reduction"] > 0.0:
			lines.append("Las invocaciones reciben un %d %% menos de daño" % roundi(p["aura_reduction"] * 100.0))
		text += "\nAura (relánzala para apagarla) · Reserva %d %% del maná\n%s" % [roundi(p["reserve"]), "\n".join(lines)]
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
	for id in player.statuses:
		best[id] = maxf(float(best.get(id, 0.0)), float(player.statuses[id]))
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
	if not touch_layout:
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
	# Cifras de los orbes con la fuente de píxeles (T76), con sombra dura.
	var digits := PixelFont.font()
	var life_text := "%d / %d" % [player.life, player.max_life()]
	_pixel_string(digits, life_center + Vector2(-80.0, 8.0), life_text, TEXT_COLOR)
	if max_es > 0.0:
		_pixel_string(digits, life_center + Vector2(-80.0, 30.0), "+%d ES" % player.energy_shield, ES_COLOR.lightened(0.3))
	# Maná disponible / utilizable. Con invocaciones persistentes, debajo: reservado y total.
	var reserved_amount := player.unreserved_mana_max() * player.mana_reserved
	_pixel_string(digits, mana_center + Vector2(-80.0, 8.0 if reserved_amount <= 0.0 else 0.0), "%d / %d" % [player.mana, player.max_mana()], TEXT_COLOR)
	if reserved_amount > 0.0:
		draw_string(font, mana_center + Vector2(-80.0, 16.0), "reservado %d de %d" % [reserved_amount, player.unreserved_mana_max()],
			HORIZONTAL_ALIGNMENT_CENTER, 160.0, 11, Color("9ad0ff"))

	# Experiencia.
	var xp := _xp_rect()
	var progress := float(character.experience) / float(character.experience_to_next())
	UiAtlas.draw(self, "bar_frame", xp.grow(4.0))   # marco del atlas (T95)
	# Al subir de nivel (T97), la barra brilla un par de segundos.
	if character.level != _seen_level:
		if _seen_level > 0 and character.level > _seen_level:
			_level_glow_at = Time.get_ticks_msec() / 1000.0
		_seen_level = character.level
	var glow := UiMotion.level_glow(Time.get_ticks_msec() / 1000.0 - _level_glow_at)
	if glow > 0.0:
		for k in 4:
			draw_rect(xp.grow(3.0 + k * 3.0), Color(1.0, 0.85, 0.35, Accessibility.flash(glow) * 0.22 * (1.0 - k / 4.0)), false, 3.0)
	draw_rect(xp, Color(0, 0, 0, 0.75))
	draw_rect(Rect2(xp.position, Vector2(xp.size.x * progress, xp.size.y)), XP_COLOR)
	for k in range(1, 10):
		var x := xp.position.x + xp.size.x * k / 10.0
		draw_line(Vector2(x, xp.position.y), Vector2(x, xp.end.y), Color(0, 0, 0, 0.5), 1.0)
	draw_rect(xp, TRIM, false, 1.0)
	var level_text := "Nivel %d" % character.level
	draw_string(font, _menu_origin(), level_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, TEXT_COLOR)
	# «!» sobre los botones de menú con novedades.
	for k in _menu_buttons.size():
		if not attention.get(MENU_IDS[k], false):
			continue
		var br := Rect2(_menu_buttons[k].position, _menu_buttons[k].size)
		var pulse := 0.5 + 0.5 * sin(Time.get_ticks_msec() / 160.0)
		draw_rect(br.grow(2.0 + pulse * 2.0), Color(1.0, 0.85, 0.3, 0.35 + 0.4 * pulse), false, 2.0)
		var c := br.position + Vector2(br.size.x - 2, 2)
		draw_circle(c, 7.0, Color("1a1208"))
		draw_circle(c, 6.0, Color("ffd84a"))
		draw_string(font, c + Vector2(-2, 5), "!", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color("1a1208"))

	# Pociones.
	for i in Inventory.FLASK_SLOTS:
		_draw_flask(i, font)

	# Habilidades.
	for i in SkillController.ACTIONS.size():
		_draw_skill_slot(i, font)
	_draw_dodge(font)
	if touch_layout and not use_now.is_empty():
		_draw_use(font)

	_draw_status_boxes(font)
	var boss_bar := _draw_boss_bar(font)
	_draw_target_frame(font, 78.0 if boss_bar else 0.0)


## Barra de jefe (arriba, centrada) con marco, porcentaje de vida y las fases separadas por marcas.
## Devuelve true si se ha dibujado.
func _draw_boss_bar(font: Font) -> bool:
	var info := enemies.boss_info()
	if info.is_empty() or player == null:
		return false
	var dist: float = (info["pos"] as Vector2).distance_to(player.global_position)
	if dist > 1300.0 and info["frac"] >= 0.999:
		return false   # aún no ha despertado
	var thresholds: Array = info["thresholds"]
	var frac: float = clampf(info["frac"], 0.0, 1.0)
	var width := minf(760.0, size.x - 560.0)
	var box := Rect2(Vector2((size.x - width) / 2.0, 8.0), Vector2(width, 66.0))
	var shield: bool = info["shield"] > 0.0
	draw_rect(box, Color(PLATE, 0.95))
	draw_rect(box, TRIM, false, 2.0)
	draw_rect(box.grow(-3.0), TRIM.darkened(0.5), false, 1.0)
	# Remates en las esquinas.
	for corner in [box.position, Vector2(box.end.x, box.position.y), Vector2(box.position.x, box.end.y), box.end]:
		draw_circle(corner, 4.0, TRIM)
	var boss_color := Rarity.enemy_color(info["rarity"])
	draw_string_outline(font, box.position + Vector2(0, 21), String(info["name"]), HORIZONTAL_ALIGNMENT_CENTER, box.size.x, 17, 5, Color.BLACK)
	draw_string(font, box.position + Vector2(0, 21), String(info["name"]), HORIZONTAL_ALIGNMENT_CENTER, box.size.x, 17, boss_color)
	var bar := Rect2(box.position + Vector2(14, 29), Vector2(box.size.x - 28.0, 16))
	draw_rect(bar, Color(0, 0, 0, 0.85))
	# Cada fase, de un tono (más oscura la que ya pasó): segmentos entre umbrales.
	var edges: Array = [1.0] + thresholds + [0.0]
	var phase_colors := [Color("b02a2a"), Color("c8682a"), Color("c8a82a"), Color("a02ac8")]
	for k in edges.size() - 1:
		var hi: float = edges[k]
		var lo: float = edges[k + 1]
		var seg_frac := clampf((minf(frac, hi) - lo) / maxf(0.001, hi - lo), 0.0, 1.0)
		var seg := Rect2(bar.position.x + bar.size.x * lo, bar.position.y, bar.size.x * (hi - lo), bar.size.y)
		var col: Color = phase_colors[k % phase_colors.size()]
		if shield:
			col = col.lerp(Color("9fd0ff"), 0.5)
		draw_rect(Rect2(seg.position, Vector2(seg.size.x * seg_frac, seg.size.y)), col)
		draw_rect(Rect2(seg.position, Vector2(seg.size.x * seg_frac, 4.0)), Color(1, 1, 1, 0.2))
		if k > 0:
			# Separador de fase (umbral de vida) con un rombo.
			var x := seg.end.x
			draw_line(Vector2(x, bar.position.y - 3.0), Vector2(x, bar.end.y + 3.0), TRIM.lightened(0.2), 2.0)
			draw_colored_polygon(PackedVector2Array([Vector2(x, bar.end.y + 3.0), Vector2(x + 4.0, bar.end.y + 7.0), Vector2(x, bar.end.y + 11.0), Vector2(x - 4.0, bar.end.y + 7.0)]), TRIM.lightened(0.2))
	draw_rect(bar, Color(0, 0, 0, 0.9), false, 1.5)
	var pct := "%d %%" % ceili(frac * 100.0)
	draw_string_outline(font, bar.position + Vector2(0, 13), pct, HORIZONTAL_ALIGNMENT_CENTER, bar.size.x, 13, 4, Color.BLACK)
	draw_string(font, bar.position + Vector2(0, 13), pct, HORIZONTAL_ALIGNMENT_CENTER, bar.size.x, 13, TEXT_COLOR)
	# Nombre de la fase actual y marcas "I II III".
	var phase_names: Array = info["phase_names"]
	var idx: int = clampi(info["index"], 0, phase_names.size())
	var phase_label := "Fase %d" % (idx + 1) if idx == 0 else String(phase_names[idx - 1])
	if shield:
		phase_label += "  ·  ¡invulnerable!"
	draw_string(font, box.position + Vector2(14, 60), phase_label, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, ES_COLOR if shield else MUTED)
	var roman := ["I", "II", "III", "IV"]
	for k in edges.size() - 1:
		var mid: float = (float(edges[k]) + float(edges[k + 1])) / 2.0
		var cx := bar.position.x + bar.size.x * mid
		draw_string(font, Vector2(cx - 12.0, box.end.y - 6.0), roman[k % roman.size()], HORIZONTAL_ALIGNMENT_CENTER, 24.0, 11,
			TEXT_COLOR if k == idx else MUTED.darkened(0.2))
	return true


## Barra de estados del jugador sobre el orbe de vida: debuffs (borde rojo: quemado, helado,
## electrocutado, congelado, envenenado...) y buffs (borde verde: pociones y potenciadores)
## con su tiempo restante. Deja el rectángulo en _states_rect para el tooltip.
var _states_rect := Rect2()


func _player_buffs() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for effect in character.timed_effects:
		var eid: String = effect["id"]
		if eid.begins_with("aura:") or eid.begins_with("golem:"):
			continue   # las auras y los bonos de golem salen en los recuadros de activos
		if eid.begins_with("shrine:"):
			var info: Dictionary = ZoneEvents.SHRINES.get(eid.trim_prefix("shrine:"), {})
			out.append({"name": info.get("name", "Santuario"), "skill": {}, "shrine": info.get("color", "ffffff"), "time": effect["time_left"], "desc": info.get("text", "")})
		elif eid.begins_with("skill:"):
			var skill: Dictionary = GameData.items.skills.skills.get(eid.trim_prefix("skill:"), {})
			out.append({"name": skill.get("name", "Efecto"), "skill": skill, "time": effect["time_left"], "desc": skill.get("description", "")})
		else:
			var flask_id: String = eid.trim_prefix("flask:")
			var fdef: Dictionary = GameData.items.flasks.get(flask_id, {})
			out.append({"name": fdef.get("name", flask_id), "flask": fdef.get("icon", flask_id), "time": effect["time_left"], "desc": fdef.get("description", "")})
	return out


func _draw_player_states(life_center: Vector2, font: Font) -> void:
	var debuffs := _player_states()
	var buffs := _player_buffs()
	_states_rect = Rect2()
	var charge_types: Array = Charges.TYPES.filter(func(t: String) -> bool: return int(character.charges[t]) > 0)
	if debuffs.is_empty() and buffs.is_empty() and charge_types.is_empty():
		return
	var side := 26.0
	var x0 := 24.0
	var y := life_center.y - ORB_RADIUS - 56.0 - (16.0 if player.barrier > 0.0 else 0.0)
	var x := x0
	for s in debuffs:
		var r := Rect2(x, y, side, side)
		_status_icon(r, s["id"])
		draw_rect(r.grow(1.0), Color("e06c6c", 0.9), false, 1.5)
		var label := "%.0fs" % ceilf(s["time"])
		draw_string_outline(font, r.position + Vector2(0, side + 11.0), label, HORIZONTAL_ALIGNMENT_CENTER, side, 10, 3, Color.BLACK)
		draw_string(font, r.position + Vector2(0, side + 11.0), label, HORIZONTAL_ALIGNMENT_CENTER, side, 10, Ailments.color(s["id"]))
		x += side + 4.0
	for b in buffs:
		var r := Rect2(x, y, side, side)
		draw_rect(r, Color(0, 0, 0, 0.7))
		if b.has("shrine"):
			var sc := Color(b["shrine"])
			draw_rect(Rect2(r.get_center() - Vector2(5, 8), Vector2(10, 16)), sc.darkened(0.3))
			draw_rect(Rect2(r.get_center() - Vector2(3, 3), Vector2(6, 6)), sc.lightened(0.3))
		elif b.has("flask"):
			_item_icon(r.grow(-2.0), b["flask"])
		elif not b["skill"].is_empty():
			_skill_icon(r, b["skill"])
		draw_rect(r.grow(1.0), Color("6fd36b", 0.9), false, 1.5)
		var blabel := "%.0fs" % ceilf(b["time"])
		draw_string_outline(font, r.position + Vector2(0, side + 11.0), blabel, HORIZONTAL_ALIGNMENT_CENTER, side, 10, 3, Color.BLACK)
		draw_string(font, r.position + Vector2(0, side + 11.0), blabel, HORIZONTAL_ALIGNMENT_CENTER, side, 10, Color("9ae09a"))
		x += side + 4.0
	# Cargas: rombo de su color con cuántas hay (y el máximo) y el tiempo que les queda.
	for t in charge_types:
		var r := Rect2(x, y, side, side)
		var col: Color = Charges.color(t)
		var c := r.get_center()
		draw_rect(r, Color(0, 0, 0, 0.7))
		draw_colored_polygon(PackedVector2Array([c + Vector2(0, -11), c + Vector2(11, 0), c + Vector2(0, 11), c + Vector2(-11, 0)]), col.darkened(0.2))
		draw_colored_polygon(PackedVector2Array([c + Vector2(0, -7), c + Vector2(7, 0), c + Vector2(0, 7), c + Vector2(-7, 0)]), col.lightened(0.25))
		draw_string_outline(font, r.position + Vector2(0, 18), str(character.charges[t]), HORIZONTAL_ALIGNMENT_CENTER, side, 13, 4, Color.BLACK)
		draw_string(font, r.position + Vector2(0, 18), str(character.charges[t]), HORIZONTAL_ALIGNMENT_CENTER, side, 13, Color.WHITE)
		draw_rect(r.grow(1.0), col, false, 1.5)
		var clabel := "%.0fs" % ceilf(float(character.charge_time[t]))
		draw_string_outline(font, r.position + Vector2(0, side + 11.0), clabel, HORIZONTAL_ALIGNMENT_CENTER, side, 10, 3, Color.BLACK)
		draw_string(font, r.position + Vector2(0, side + 11.0), clabel, HORIZONTAL_ALIGNMENT_CENTER, side, 10, col.lightened(0.3))
		x += side + 4.0
	_states_rect = Rect2(x0, y, x - x0 - 4.0, side + 14.0)


## Marco del objetivo (arriba, centrado): nombre, vida y estados del enemigo
## bajo el cursor, como en PoE.
func _draw_target_frame(font: Font, top_offset := 0.0) -> void:
	_hotspots["target"].size = Vector2.ZERO
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
	var role := enemies.role_of(i)
	if role != "":
		title = "%s · %s" % [EnemyManager.ROLE_NAMES[role], title]
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
	# Afijos, resistencias e inmunidades: una fila más debajo de la vida.
	var tr: Dictionary = enemies.traits[i]
	var resists: Dictionary = tr.get("res", {})
	var immunes: Dictionary = tr.get("immune", {})
	# Las combinaciones van primero y ocultan las chapas de sus componentes
	# (la ayuda los nombra): así caben y se ve el nombre propio.
	var affixes: Array = []
	var hidden := {}
	for aid in tr.get("affixes", []):
		var parts: Array = EnemyManager.affix_defs().get(aid, {}).get("combo", [])
		if not parts.is_empty():
			affixes.push_front(aid)
			for part in parts:
				hidden[part] = true
	for aid in tr.get("affixes", []):
		if not hidden.has(aid) and not affixes.has(aid):
			affixes.append(aid)
	var extra_row := not resists.is_empty() or not immunes.is_empty() or not affixes.is_empty()
	var box := Rect2(Vector2((size.x - TARGET_SIZE.x) / 2.0, 10.0 + top_offset),
		TARGET_SIZE + Vector2(0, 22.0 * rows + (8.0 if rows > 0 else 0.0) + (24.0 if extra_row else 0.0)))
	# Ayuda al pasar el mouse por el marco: qué hace cada estado, afijo, resistencia e inmunidad.
	var tip := PackedStringArray()
	for s in states:
		tip.append(StatusIcon.tooltip(s["id"], s["time"], int(s.get("stacks", 0))))
	for aid in affixes:
		var adef: Dictionary = EnemyManager.affix_defs().get(aid, {})
		if adef.has("combo"):
			var parts := PackedStringArray()
			for part in adef["combo"]:
				parts.append(String(EnemyManager.affix_defs().get(part, {}).get("name", part)))
			tip.append("★ %s (%s): %s" % [adef.get("name", aid), " + ".join(parts), adef.get("description", "")])
			for part in adef["combo"]:
				var pdef: Dictionary = EnemyManager.affix_defs().get(part, {})
				tip.append("   %s: %s" % [pdef.get("name", part), pdef.get("description", "")])
		else:
			tip.append("%s: %s" % [adef.get("name", aid), adef.get("description", "")])
	if not immunes.is_empty():
		var names_list := PackedStringArray()
		for id in Ailments.ALL:
			if immunes.has(id):
				names_list.append(Ailments.display_name(id))
		tip.append("Inmune a: " + ", ".join(names_list))
	if not resists.is_empty():
		tip.append("Resistencias: valores positivos reducen el daño de ese tipo; negativos lo aumentan.")
	_hotspots["target"].position = box.position
	_hotspots["target"].size = box.size
	_hotspots["target"].tooltip_text = "\n".join(tip)
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
	# Afijos (nombre coloreado), resistencias por elemento e inmunidades (icono tachado).
	var y := bar.end.y + 6.0
	if extra_row:
		var fx := box.position.x + 10.0
		for aid in affixes:
			var def: Dictionary = EnemyManager.affix_defs().get(aid, {})
			var combo: bool = def.has("combo")
			var aname := ("★ " if combo else "") + String(def.get("name", aid))
			var aw := font.get_string_size(aname, HORIZONTAL_ALIGNMENT_LEFT, -1, 11).x + 10.0
			draw_rect(Rect2(fx, y, aw, 16), Color(Color(def.get("color", "ffffff")), 0.4 if combo else 0.25))
			draw_rect(Rect2(fx, y, aw, 16), Color(def.get("color", "ffffff")), false, 1.0)
			if combo:   # doble borde dorado: es una combinación con nombre propio
				draw_rect(Rect2(fx - 2.0, y - 2.0, aw + 4.0, 20), UiStyle.ACCENT, false, 1.0)
			draw_string(font, Vector2(fx + 5.0, y + 12.0), aname, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color(def.get("color", "ffffff")).lightened(0.3))
			fx += aw + 6.0
		var res_colors := {"physical": Color("c8b8a0"), "fire": Color("e0652f"), "cold": Color("7fb8e0"), "lightning": Color("e8d070"), "chaos": Color("b04ad9")}
		var res_short := {"physical": "Fís", "fire": "Fue", "cold": "Frío", "lightning": "Rayo", "chaos": "Caos"}
		for t in EnemyManager.RESIST_TYPES:
			if not resists.has(t) or absf(resists[t]) < 1.0:
				continue
			var label := "%s %+d %%" % [res_short[t], roundi(minf(EnemyManager.RESIST_CAP, resists[t]))]
			var lw := font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, 11).x
			draw_string(font, Vector2(fx, y + 12.0), label, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, res_colors[t] if resists[t] > 0.0 else Color("6fd36b"))
			fx += lw + 10.0
		for id in Ailments.ALL:
			if immunes.has(id):
				var ir := Rect2(fx, y, 16, 16)
				StatusIcon.draw(self, ir, id, true, 0.7)
				draw_line(ir.position + Vector2(1, 15), ir.position + Vector2(15, 1), Color("ff4040"), 2.0)
				fx += 20.0
		y += 24.0
	# Estados con su icono, nombre y tiempo.
	var x := box.position.x + 10.0
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
		if eid.begins_with("aura:") or eid.begins_with("golem:"):
			continue   # las auras y los golems salen en active_summaries()
		if eid == "camp:antena":
			entries.append({"name": "Señal fuerte", "skill": GameData.items.skills.skills.get("hiperthreading", {}), "count": 1,
				"remaining": effect["time_left"], "total": effect.get("total", effect["time_left"]), "kind": "buff"})
			continue
		if eid.begins_with("shrine:") or eid.begins_with("companion:") or eid == "incident":
			continue   # santuarios: en la barra de estados; acompañante: lo ves caminar a tu lado
		if eid.begins_with("skill:"):
			# Potenciadores de habilidades (Modo Seguro, Hiperthreading...).
			var skill: Dictionary = GameData.items.skills.skills.get(eid.trim_prefix("skill:"), {})
			entries.append({"name": skill.get("name", "Efecto"), "skill": skill, "count": 1, "remaining": effect["time_left"],
				"total": effect.get("total", effect["time_left"]), "kind": "buff"})
			continue
		if eid == "asc:sprint":
			# Sprint del Scrum Master (habilidad propia de clase).
			entries.append({"name": "Sprint", "skill": GameData.items.skills.skills.get("hiperthreading", {}), "count": 1,
				"remaining": effect["time_left"], "total": effect.get("total", effect["time_left"]), "kind": "buff"})
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
	var kind_colors := {"minion": Color("7fd07f"), "totem": Color("d9a441"), "container": Color("4a9ae0"), "trap": Color("b07a3a"), "mine": Color("a0a040"),
		"spin": Color("b8b8c8"), "flask": Color("6fd36b"), "buff": Color("8ab0e0"), "drones": Color("e8d070"), "unit": Color("9ad0ff"), "aura": Color("d9b0ff")}
	for e in entries:
		var r := Rect2(x, y, box, box)
		var color: Color = kind_colors.get(e["kind"], TRIM)
		var persistent: bool = e.get("persistent", false)
		draw_rect(r.grow(2.0), Color(0, 0, 0, 0.7))
		if e.has("flask"):
			_item_icon(r.grow(-4.0), GameData.items.flasks.get(e["flask"], {}).get("icon", e["flask"]))
		elif not e["skill"].is_empty():
			_skill_icon(r.grow(-3.0), e["skill"])
		var frac: float = clampf(e["remaining"] / maxf(0.1, e["total"]), 0.0, 1.0)
		# Barra: tiempo restante o, en las persistentes, la vida (verde).
		var bar_color := Color("6fd36b").lerp(Color("e06c6c"), 1.0 - frac) if persistent else color
		draw_rect(Rect2(r.position.x, r.end.y + 2.0, r.size.x, 4.0), Color(0, 0, 0, 0.8))
		draw_rect(Rect2(r.position.x, r.end.y + 2.0, r.size.x * frac, 4.0), bar_color)
		var blink := frac < 0.2 and fmod(Time.get_ticks_msec() / 1000.0, 0.5) < 0.25 and Accessibility.can_blink()
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
	# Placa de bronce del atlas de interfaz (T95), si está; si no, el filo dorado de antes.
	if UiAtlas.texture() != null:
		UiAtlas.draw(self, "hotbar_plate", Rect2(plate.position, Vector2(plate.size.x, size.y - plate.position.y + 12.0)))
	else:
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
	UiAtlas.draw(self, "flask_frame", r.grow(3.0))   # marco del atlas (T95)
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
	_item_icon(icon_rect, f.icon(), Color.WHITE if usable else Color(0.45, 0.45, 0.5))
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

## Iconos con la caché de texturas (IconCache): se pintan una vez, no cada fotograma.
func _skill_icon(r: Rect2, def: Dictionary, dimmed := false) -> void:
	IconCache.draw(self, r, "skill:%s:%s:%s:%s" % [def.get("id", ""), def.get("icon", ""), def.get("name", ""), dimmed],
		func(ci: CanvasItem, rr: Rect2, _m: Color) -> void: SkillIcon.draw(ci, rr, def, dimmed))


func _item_icon(r: Rect2, id: String, modulate := Color.WHITE) -> void:
	IconCache.draw(self, r, "item:" + id, func(ci: CanvasItem, rr: Rect2, m: Color) -> void: ItemIcons.draw(ci, rr, id, m, false), modulate)


func _status_icon(r: Rect2, id: String) -> void:
	IconCache.draw(self, r, "status:" + id, func(ci: CanvasItem, rr: Rect2, _m: Color) -> void: StatusIcon.draw(ci, rr, id))


func _draw_skill_slot(i: int, font: Font) -> void:
	var r := _slot_rect(i)
	# Marco: hueco hundido con borde dorado (como las ranuras de PoE); con el atlas, su casilla.
	draw_rect(r.grow(3.0), Color(0, 0, 0, 0.75))
	if UiAtlas.texture() != null:
		UiAtlas.draw(self, "slot_normal", r.grow(5.0))
	else:
		draw_rect(r.grow(3.0), TRIM.darkened(0.45), false, 1.0)
	draw_rect(r, Color(0, 0, 0, 0.7))
	var board: Motherboard = character.inventory.boards[i]
	var key_color := TEXT_COLOR
	if board:
		var p := skills.profile(i)
		var no_mana: bool = player.mana < p.get("mana_cost", 0.0)
		_skill_icon(r.grow(-2.0), board.skill_def, no_mana)
		var cd := skills.cooldown_fraction(i)
		if cd > 0.0:
			_draw_pie(r.get_center(), r.size.x * 0.48, cd, Color(0, 0, 0, 0.62))
			var left: float = skills.cooldowns[i]
			var cd_text := ("%.1f" % left) if left < 3.0 else str(ceili(left))
			draw_string_outline(font, r.position + Vector2(0, r.size.y * 0.5 + 7.0), cd_text, HORIZONTAL_ALIGNMENT_CENTER, r.size.x, 18, 5, Color.BLACK)
			draw_string(font, r.position + Vector2(0, r.size.y * 0.5 + 7.0), cd_text, HORIZONTAL_ALIGNMENT_CENTER, r.size.x, 18, Color.WHITE)
		# Insignias de las RAM instaladas en el borde derecho (como las gemas de soporte).
		var ram_w := RamIcon.draw_board_column(self, r, board, 15.0)
		if not p.is_empty():
			SkillIcon.draw_ailment_pips(self, Rect2(r.position, r.size - Vector2(ram_w, 0.0)), p.get("ailments", {}))
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
		# Habilidades que gastan cargas: cuántas gastaría ahora (chapitas de su color, arriba a la izquierda).
		var spend: Dictionary = p.get("spend_charges", {})
		var cx := r.position.x + 2.0
		for t in spend:
			var n := int(character.charges.get(t, 0))
			var chip := Rect2(cx, r.position.y + 2.0, 16.0, 13.0)
			draw_rect(chip, Color(0, 0, 0, 0.8))
			draw_rect(chip, Charges.color(t) if n > 0 else Color(Charges.color(t), 0.35), false, 1.0)
			draw_string(font, chip.position + Vector2(0, 10.0), str(n), HORIZONTAL_ALIGNMENT_CENTER, chip.size.x, 10,
				Charges.color(t) if n > 0 else MUTED)
			cx += 18.0
		var flash := _slot_flash[i] / 0.25
		draw_rect(r, Motherboard.COLOR.darkened(0.2).lerp(Color("ffe8a0"), flash), false, 1.5 + 1.5 * flash)
		if not p.is_empty() and String(p.get("trigger", "")) != "":
			# RAM de activación: «AUTO» y, mientras dure, su enfriamiento interno en el borde.
			var tcd: float = skills._trigger_cd[i] if i < skills._trigger_cd.size() else 0.0
			var tfrac := clampf(tcd / maxf(0.01, float(p["trigger_cooldown"])), 0.0, 1.0)
			draw_rect(r.grow(1.0), Color(SkillController.TRIGGER_COLOR, 0.35 + 0.5 * (1.0 - tfrac)), false, 2.0)
			# Arriba a la izquierda (a la derecha va el coste de maná).
			draw_string_outline(font, r.position + Vector2(3, 12), "AUTO", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, 3, Color.BLACK)
			draw_string(font, r.position + Vector2(3, 12), "AUTO", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, SkillController.TRIGGER_COLOR)
			if tfrac > 0.0:
				draw_rect(Rect2(r.position.x, r.end.y - 3.0, r.size.x * tfrac, 3.0), SkillController.TRIGGER_COLOR)
		if not p.is_empty() and p["kind"] == "aura" and skills.is_aura_active(p["id"]):
			var glow := 0.5 + 0.5 * sin(Time.get_ticks_msec() / 220.0)
			draw_rect(r.grow(1.0), Color("e0c0ff", 0.55 + 0.45 * glow), false, 2.5)
			draw_string_outline(font, r.position + Vector2(0, 12), "ON", HORIZONTAL_ALIGNMENT_CENTER, r.size.x, 10, 3, Color.BLACK)
			draw_string(font, r.position + Vector2(0, 12), "ON", HORIZONTAL_ALIGNMENT_CENTER, r.size.x, 10, Color("e0c0ff"))
		if no_mana:
			key_color = Color("e06c6c")
	else:
		draw_rect(r, Color("3a3442"), false, 1.0)
	if touch_layout:
		return   # en táctil no hay tecla que enseñar
	# Tecla en una chapita abajo a la izquierda.
	var key: String = Controls.key_label(SkillController.ACTIONS[i])
	var key_w := font.get_string_size(key, HORIZONTAL_ALIGNMENT_LEFT, -1, 11).x + 8.0
	var key_rect := Rect2(r.position.x - 2.0, r.end.y - 12.0, key_w, 14.0)
	draw_rect(key_rect, Color(PLATE, 0.95))
	draw_rect(key_rect, TRIM.darkened(0.2), false, 1.0)
	draw_string(font, key_rect.position + Vector2(0, 11.0), key, HORIZONTAL_ALIGNMENT_CENTER, key_w, 11, key_color)


## Casilla de la esquiva: una pastilla por carga (la que se recarga, a medias) y la tecla.
func _draw_dodge(font: Font) -> void:
	var r := _dodge_rect()
	draw_rect(r.grow(3.0), Color(0, 0, 0, 0.75))
	draw_rect(r.grow(3.0), TRIM.darkened(0.45), false, 1.0)
	draw_rect(r, Color(0, 0, 0, 0.7))
	var total := player.max_dodge_charges()
	var shown := maxi(total, ceili(player.dodge_charges))   # la poción puede dar una de más
	var pip_h := minf(16.0, (r.size.y - 22.0 - (shown - 1) * 3.0) / maxf(1.0, shown))
	var color := Color("8ad8ff")
	for k in shown:
		var pr := Rect2(r.position.x + 6.0, r.position.y + 6.0 + k * (pip_h + 3.0), r.size.x - 12.0, pip_h)
		var fill := clampf(player.dodge_charges - (shown - 1 - k), 0.0, 1.0)   # se llenan de abajo arriba
		draw_rect(pr, Color(0.1, 0.16, 0.22))
		if fill > 0.0:
			draw_rect(Rect2(pr.position + Vector2(0, pr.size.y * (1.0 - fill)), Vector2(pr.size.x, pr.size.y * fill)),
				color if fill >= 1.0 else Color(color, 0.45))
		draw_rect(pr, color.darkened(0.4), false, 1.0)
	if player.is_dodging():
		draw_rect(r.grow(1.0), Color(color, 0.8), false, 2.0)
	if touch_layout:
		return
	var key_rect := Rect2(r.position.x - 2.0, r.end.y - 12.0, r.size.x + 4.0, 14.0)
	draw_rect(key_rect, Color(PLATE, 0.95))
	draw_rect(key_rect, TRIM.darkened(0.2), false, 1.0)
	draw_string(font, key_rect.position + Vector2(0, 11.0), "Esp.", HORIZONTAL_ALIGNMENT_CENTER, key_rect.size.x, 10,
		TEXT_COLOR if player.dodge_charges >= 1.0 else Color("e06c6c"))


## Botón de usar (T134): dorado, con un dibujo de lo que hay cerca (el icono del
## objeto, una burbuja para hablar, un rombo para el waypoint...) y su texto debajo.
func _draw_use(font: Font) -> void:
	var r := use_rect()
	var c := r.get_center()
	var radius := TOUCH_USE * 0.5
	var pulse := 0.5 + 0.5 * sin(Time.get_ticks_msec() / 260.0)
	draw_circle(c, radius + 4.0, Color(0, 0, 0, 0.75))
	draw_circle(c, radius, Color(UiStyle.ACCENT, 0.9))
	draw_arc(c, radius + 2.0 + pulse * 2.0, 0.0, TAU, 40, Color(1.0, 0.92, 0.6, 0.5 + 0.3 * pulse), 2.0, true)
	var ink := Color("1a1208")
	match String(use_now["kind"]):
		"loot":
			var icon := Rect2(c - Vector2(20, 20), Vector2(40, 40))
			draw_rect(icon.grow(3.0), Color(0, 0, 0, 0.55))
			ItemIcons.draw_item(self, icon, use_now["item"], Color.WHITE)
		"npc":
			draw_circle(c + Vector2(0, -3), 16.0, ink)
			draw_colored_polygon(PackedVector2Array([c + Vector2(-6, 10), c + Vector2(4, 10), c + Vector2(-10, 20)]), ink)
			for k in 3:
				draw_circle(c + Vector2(-7 + k * 7, -3), 2.5, UiStyle.ACCENT)
		"waypoint":
			draw_colored_polygon(PackedVector2Array([c + Vector2(0, -18), c + Vector2(14, 0), c + Vector2(0, 18), c + Vector2(-14, 0)]), ink)
			draw_circle(c, 5.0, Color("7fd4ff"))
		"stash":
			draw_rect(Rect2(c - Vector2(16, 10), Vector2(32, 22)), ink)
			draw_rect(Rect2(c - Vector2(16, 14), Vector2(32, 6)), ink.lightened(0.25))
			draw_rect(Rect2(c - Vector2(3, 6), Vector2(6, 6)), UiStyle.ACCENT)
		_:
			draw_circle(c, 13.0, ink)
			draw_circle(c, 6.0, UiStyle.ACCENT)
	var text := String(use_now.get("text", "Usar"))
	var label_pos := Vector2(c.x - 60.0, r.end.y + 16.0)
	draw_string_outline(font, label_pos, text, HORIZONTAL_ALIGNMENT_CENTER, 120.0, 14, 4, Color.BLACK)
	draw_string(font, label_pos, text, HORIZONTAL_ALIGNMENT_CENTER, 120.0, 14, UiStyle.ACCENT.lightened(0.3))


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
		var t := Time.get_ticks_msec() / 1000.0
		# Líquido (T76): más oscuro al fondo y burbujas que suben hasta la superficie.
		draw_colored_polygon(_orb_segment(center, 0.0, fill * 0.35), Color(0, 0, 0, 0.22))
		var surface_y := center.y + ORB_RADIUS * (1.0 - 2.0 * fill)
		var bottom_y := center.y + ORB_RADIUS
		for b in UiStyle.orb_bubbles(t, center.x, bottom_y, surface_y, ORB_RADIUS):
			draw_circle(b[0], b[1], Color(color.lightened(0.5), 0.35))
		# Ondas en la superficie del líquido: la cresta se rellena (chapotea) y una línea clara encima.
		var half := sqrt(maxf(0.0, ORB_RADIUS * ORB_RADIUS - pow(surface_y - center.y, 2.0)))
		if half > 4.0:
			var wave := PackedVector2Array()
			for k in 13:
				var x := center.x - half + 2.0 * half * k / 12.0
				wave.append(Vector2(x, surface_y + sin(t * 3.0 + k * 0.9) * 1.5 + sin(t * 1.3 + k * 0.4) * 1.2))
			var crest := wave.duplicate()
			# Base bien por debajo de las ondas (bajan hasta +2,7): si casi la tocan, no se triangula.
			crest.append(Vector2(center.x + half, surface_y + 6.0))
			crest.append(Vector2(center.x - half, surface_y + 6.0))
			draw_colored_polygon(crest, color)
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
	# Aro dorado del atlas (T95) alrededor del orbe.
	UiAtlas.draw_orb_frame(self, center, ORB_RADIUS)


## Brillo de la barra de experiencia al subir de nivel (T97, UiMotion.level_glow).
var _seen_level := 0
var _level_glow_at := -100.0


## Cifra de los orbes centrada en 160 px: fuente normal con contorno y sombra suave
## (antes, fuente de píxeles; el HUD va hacia un acabado menos pixel art).
func _pixel_string(_font: Font, pos: Vector2, text: String, color: Color) -> void:
	var font := get_theme_default_font()
	var size := 20
	draw_string(font, pos + Vector2(0, 2), text, HORIZONTAL_ALIGNMENT_CENTER, 160.0, size, Color(0, 0, 0, 0.55))
	draw_string_outline(font, pos, text, HORIZONTAL_ALIGNMENT_CENTER, 160.0, size, 5, Color(0, 0, 0, 0.9))
	draw_string(font, pos, text, HORIZONTAL_ALIGNMENT_CENTER, 160.0, size, color)


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
