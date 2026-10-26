class_name CharacterSheet
extends PanelContainer
## Hoja de personaje (tecla C): medallón animado, barra de experiencia y
## tarjetas con barras (atributos, defensa, resistencias y ofensiva), con
## comentarios sarcásticos según cómo vayas.

signal close_requested
signal passives_requested

const WIDTH := 760.0
const MOODS := [
	"Funcional, a duras penas.", "Estable (versión beta).", "Optimista sin motivo aparente.",
	"Cansado, pero desplegado.", "En modo legacy.", "Pendiente de refactorizar.",
]
const QUOTES := [
	"«No es un bug, es una feature.» — Tú, cada día.",
	"«Funciona en mi máquina.» — Tu epitafio.",
	"«Lo arreglo en el siguiente sprint.» — Nunca.",
	"«¿Quién escribió esto?» — Tú, hace dos semanas.",
	"«Es un cambio pequeño.» — Famosas últimas palabras.",
	"«Ya casi está.» — Desde hace tres sprints.",
]
const RESISTANCES := [[Stat.FIRE_RES, "Fuego", "e06c6c"], [Stat.COLD_RES, "Frío", "7fb8e0"],
	[Stat.LIGHTNING_RES, "Rayo", "e8d070"], [Stat.CHAOS_RES, "Caos", "b04ad9"]]

var character: CharacterData
var player: Player
var skills: SkillController

var _portrait: CharacterPortrait
var _caption: Label
var _name: Label
var _class_line: Label
var _asc_line: Label
var _xp: StatBar
var _chips: Label
var _mood: Label
var _bars := {}            # clave -> StatBar
var _skill_icon: Control
var _skill_def: Dictionary = {}
var _skill_name: Label
var _dps: Label
var _offense_rows: Label
var _passive_button: Button
var _quote: Label
var _refresh_timer := 0.0
var _rng := RandomNumberGenerator.new()


func setup(p_character: CharacterData, p_player: Player, p_skills: SkillController) -> void:
	character = p_character
	player = p_player
	skills = p_skills
	_portrait.appearance = character.appearance
	_portrait.ring_color = Color(character.class_def.get("color", "d9a441"))
	visibility_changed.connect(func() -> void:
		if visible:
			_quote.text = QUOTES[_rng.randi_range(0, QUOTES.size() - 1)]
			_refresh())


func _ready() -> void:
	_rng.randomize()
	theme = UiStyle.make_theme()
	UiStyle.decorate_window(self)
	custom_minimum_size.x = WIDTH
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	add_child(box)
	box.add_child(UiStyle.window_header("Personaje", "Tus cifras, sin maquillaje  ·  C para cerrar", func() -> void: close_requested.emit()))
	# El resto se desplaza si no cabe (interfaz grande en pantallas bajas).
	var scroll := FitScroll.new(self)
	box.add_child(scroll)
	box = VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(box)

	# Cabecera: medallón + nombre, clase, ascendencia, experiencia y datos curiosos.
	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", 18)
	box.add_child(top)
	var portrait_box := VBoxContainer.new()
	portrait_box.add_theme_constant_override("separation", 4)
	top.add_child(portrait_box)
	_portrait = CharacterPortrait.new()
	_portrait.idle_actions = true
	_portrait.custom_minimum_size = Vector2(170, 170)
	portrait_box.add_child(_portrait)
	_caption = UiStyle.label("", 12, Color("6fb36b"))
	_caption.custom_minimum_size = Vector2(170, 34)
	_caption.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	portrait_box.add_child(_caption)
	_portrait.caption_changed.connect(func(text: String) -> void: _caption.text = "> " + text)

	var info := VBoxContainer.new()
	info.add_theme_constant_override("separation", 4)
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(info)
	_name = UiStyle.label("", 30, UiStyle.ACCENT.lightened(0.1))
	_name.add_theme_constant_override("outline_size", 5)
	_name.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.8))
	info.add_child(_name)
	_class_line = UiStyle.label("", 17)
	info.add_child(_class_line)
	_asc_line = UiStyle.label("", 14, UiStyle.MUTED)
	info.add_child(_asc_line)
	_xp = StatBar.new()
	_xp.height = 16.0
	info.add_child(_xp)
	_mood = UiStyle.label("", 13, UiStyle.TEXT)
	_mood.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	info.add_child(_mood)
	_chips = UiStyle.label("", 13, UiStyle.MUTED)
	info.add_child(_chips)

	# Tarjetas.
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 12)
	grid.add_theme_constant_override("v_separation", 12)
	box.add_child(grid)
	grid.add_child(_card("Atributos", ["str", "dex", "int"]))
	grid.add_child(_card("Resistencias", ["res0", "res1", "res2", "res3"]))
	grid.add_child(_card("Defensa", ["life", "es", "mana", "armour", "evasion", "block"]))
	grid.add_child(_offense_card())

	var bottom := HBoxContainer.new()
	bottom.add_theme_constant_override("separation", 12)
	box.add_child(bottom)
	_quote = UiStyle.label("", 12, UiStyle.MUTED)
	_quote.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_quote.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	bottom.add_child(_quote)
	_passive_button = UiStyle.button("", func() -> void: passives_requested.emit(), 220)
	bottom.add_child(_passive_button)


func _card(title: String, keys: Array) -> PanelContainer:
	var card := PanelContainer.new()
	card.add_theme_stylebox_override("panel", UiStyle.inset_style())
	card.custom_minimum_size.x = (WIDTH - 52.0) / 2.0
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 5)
	card.add_child(col)
	col.add_child(UiStyle.section_header(title))
	for key in keys:
		var bar := StatBar.new()
		col.add_child(bar)
		_bars[key] = bar
	return card


func _offense_card() -> PanelContainer:
	var card := PanelContainer.new()
	card.add_theme_stylebox_override("panel", UiStyle.inset_style())
	card.custom_minimum_size.x = (WIDTH - 52.0) / 2.0
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 6)
	card.add_child(col)
	col.add_child(UiStyle.section_header("Ofensiva"))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	col.add_child(row)
	_skill_icon = Control.new()
	_skill_icon.custom_minimum_size = Vector2(48, 48)
	_skill_icon.draw.connect(func() -> void:
		if not _skill_def.is_empty():
			SkillIcon.draw(_skill_icon, Rect2(Vector2.ZERO, _skill_icon.size), _skill_def))
	row.add_child(_skill_icon)
	var names := VBoxContainer.new()
	names.add_theme_constant_override("separation", 0)
	row.add_child(names)
	_skill_name = UiStyle.label("", 15)
	names.add_child(_skill_name)
	_dps = UiStyle.label("", 24, Color("ff9a4a"))
	names.add_child(_dps)
	_offense_rows = UiStyle.label("", 13, UiStyle.TEXT)
	col.add_child(_offense_rows)
	return card


func _process(delta: float) -> void:
	if not visible or character == null:
		return
	_portrait.life_fraction = player.life / player.max_life()
	_refresh_timer -= delta
	if _refresh_timer <= 0.0:
		_refresh_timer = 0.5
		_refresh()


func _refresh() -> void:
	if character == null or _bars.is_empty():
		return
	var s := character.stats
	var main := skills.profile(0)
	_portrait.feeling_powerful = main.get("dps", 0.0) > 60.0 * character.level
	_portrait.appearance = character.appearance

	_name.text = character.character_name
	_class_line.text = "%s  ·  Nivel %d" % [character.class_def["name"], character.level]
	_asc_line.text = character.ascendancy_def.get("name", "Sin ascendencia (al nivel 20)")
	var to_next := character.experience_to_next()
	_xp.setup("Experiencia", "%d / %d  (%d%%)" % [character.experience, to_next, int(100.0 * character.experience / maxf(1.0, to_next))],
		float(character.experience) / maxf(1.0, to_next), Color("6fb36b"))
	_mood.text = "Estado de ánimo: " + _mood_text()
	_chips.text = "⏱ %s     ☠ %s     ⚔ %d eliminados     ● %d tokens" % [
		UiStyle.play_time(character.play_time), _deaths_text(), int(character.flags.get("stat_kills", 0)), character.tokens]

	var attrs := [s.get_value(Stat.STRENGTH), s.get_value(Stat.DEXTERITY), s.get_value(Stat.INTELLIGENCE)]
	var top_attr := maxf(100.0, attrs.max())
	_bars["str"].setup("Fuerza", "%d" % attrs[0], attrs[0] / top_attr, Color("e06c6c"))
	_bars["dex"].setup("Destreza", "%d" % attrs[1], attrs[1] / top_attr, Color("6fb36b"))
	_bars["int"].setup("Inteligencia", "%d" % attrs[2], attrs[2] / top_attr, Color("7fb8e0"))
	# Qué da cada atributo (al pasar el mouse) y cuántas cargas permite.
	var bonus := {
		"str": "+5 de vida cada 10 · +1 %% de daño físico cuerpo a cuerpo cada 4\n+1 carga de Buffer máxima cada 50 (tienes %d)",
		"dex": "+2 de precisión por punto · +1 %% de evasión cada 5 · +1 %% de velocidad de ataque cada 10\n+1 %% de daño de proyectiles cada 4 · +1 carga de Multihilos máxima cada 50 (tienes %d)",
		"int": "+5 de maná cada 10 · +1 %% de escudo de energía cada 5 · +1 %% de daño de hechizos cada 4\n+1 carga de Overclock máxima cada 50 (tienes %d)",
	}
	var attr_stats := {"str": [Stat.STRENGTH, "Fuerza"], "dex": [Stat.DEXTERITY, "Destreza"], "int": [Stat.INTELLIGENCE, "Inteligencia"]}
	for k in bonus:
		var t: String = {"str": "buffer", "dex": "multihilo", "int": "overclock"}[k]
		_bars[k].tooltip_text = StatExplain.explain(s, attr_stats[k][0], attr_stats[k][1]) + "\n\n" + (bonus[k] % character.max_charges(t)) + "\nTambién son requisito de armas y armaduras."

	for i in RESISTANCES.size():
		var entry: Array = RESISTANCES[i]
		var value := s.get_value(entry[0])
		var cap := Stat.RESISTANCE_CAP
		var note := ""
		if value < 0.0:
			note = "  te van a freír"
		elif value >= cap:
			note = "  al tope" + (" (+%d)" % (value - cap) if value > cap else "")
		elif value < 30.0:
			note = "  papel de fumar"
		_bars["res%d" % i].setup(entry[1], "%d%%%s" % [minf(value, cap), note], clampf(value, 0.0, cap) / cap,
			Color(entry[2]) if value >= 0.0 else UiStyle.DANGER, value < 0.0)
		_bars["res%d" % i].tooltip_text = StatExplain.explain(s, entry[0], "Resistencia al %s" % String(entry[1]).to_lower(), "%d %%" % value) \
			+ "\n\nTope: %d %%. %s" % [cap, ("Te sobran %d puntos: margen para las penalizaciones." % (value - cap)) if value > cap
				else ("Te faltan %d para el tope." % (cap - value) if value < cap else "Justo al tope.")]

	_bars["life"].setup("Vida", "%d / %d" % [player.life, player.max_life()], player.life / player.max_life(), Color("c23b3b"))
	var es := player.max_energy_shield()
	_bars["es"].setup("Escudo de energía", "%d" % es, (player.energy_shield / es) if es > 0.0 else 0.0, Color("7fd0e8"))
	_bars["mana"].setup("Maná", ("%d / %d" % [player.mana, player.max_mana()]) + ("" if player.mana_reserved <= 0.0 else "  (reservado %d)" % (player.unreserved_mana_max() * player.mana_reserved)), player.mana / maxf(1.0, player.max_mana()), Color("3b6bc2"))
	var armour := s.get_value(Stat.ARMOUR)
	var armour_cut := minf(0.9, armour / (armour + 250.0))
	_bars["armour"].setup("Armadura", "%d  (-%d%% a golpes de 50)" % [armour, roundi(100.0 * armour_cut)], armour_cut / 0.9, Color("b8a07a"))
	var evasion := s.get_value(Stat.EVASION)
	var evade := minf(Player.MAX_EVADE_CHANCE, evasion / (evasion + 600.0))
	_bars["evasion"].setup("Evasión", "%d  (%d%% esquivar)" % [evasion, roundi(100.0 * evade)], evade / Player.MAX_EVADE_CHANCE, Color("8ad08a"))
	var block := minf(Player.MAX_BLOCK_CHANCE, s.get_value(Stat.BLOCK_CHANCE))
	_bars["block"].setup("Bloqueo", "%d%%" % block, block / Player.MAX_BLOCK_CHANCE, Color("c8c8c8"))
	# De dónde sale cada número (T81).
	_bars["life"].tooltip_text = StatExplain.explain(s, Stat.LIFE, "Vida máxima", "%d" % player.max_life())
	_bars["es"].tooltip_text = StatExplain.explain(s, Stat.ENERGY_SHIELD, "Escudo de energía", "%d" % es)
	_bars["mana"].tooltip_text = StatExplain.explain(s, Stat.MANA, "Maná máximo", "%d" % player.max_mana())
	_bars["armour"].tooltip_text = StatExplain.explain(s, Stat.ARMOUR, "Armadura") + "\n\nReduce más los golpes pequeños que los grandes (como en PoE)."
	_bars["evasion"].tooltip_text = StatExplain.explain(s, Stat.EVASION, "Evasión") + "\n\nProbabilidad de esquivar: evasión / (evasión + 600), hasta %d %%." % roundi(Player.MAX_EVADE_CHANCE * 100.0)
	_bars["block"].tooltip_text = StatExplain.explain(s, Stat.BLOCK_CHANCE, "Bloqueo", "%d %%" % block) + "\n\nTope: %d %%." % roundi(Player.MAX_BLOCK_CHANCE)

	if main.is_empty():
		_skill_def = {}
		_skill_name.text = "Sin habilidad principal"
		_dps.text = "Atacas con... ¿opiniones?"
		_offense_rows.text = ""
	else:
		_skill_def = GameData.items.skills.skills.get(main.get("id", ""), {}) if GameData.items else {}
		_skill_name.text = "%s (botón derecho)" % main["name"]
		_dps.text = "%.1f DPS" % main["dps"]
		var lines: Array[String] = []
		if main["max_damage"] > 0.0:
			lines.append("Daño por golpe:  %d – %d" % [main["min_damage"], main["max_damage"]])
		lines.append("Crítico:  %.1f%%  (×%d%%)" % [main["crit_chance"], main["crit_multiplier"]])
		lines.append("Usos por segundo:  %.2f" % main["uses_per_second"])
		lines.append("Velocidad de movimiento:  %d%%" % s.get_value(Stat.MOVEMENT_SPEED))
		lines.append("Regeneración de vida:  %.1f /s     Robo de vida:  %.1f%%" % [s.get_value(Stat.LIFE_REGEN), s.get_value(Stat.LIFE_LEECH)])
		# Estados que aplica la habilidad principal, con potencia y duración.
		if not main["ailments"].is_empty():
			lines.append("Estados:  " + Ailments.describe_chances(main["ailments"]))
			lines.append("Potencia de estados:  ×%.2f     Duración:  ×%.2f" % [main["ailment_effect"], main["ailment_duration"]])
		if main["ailing_bonus"] != 1.0:
			lines.append("Daño contra enemigos con estados:  ×%.2f" % main["ailing_bonus"])
		var aliados := PackedStringArray()
		var speed := s.total_multiplier(Stat.AUTOMATON_SPEED, [&"automaton"])
		if speed != 1.0:
			aliados.append("velocidad ×%.2f" % speed)
		var thorns := s.get_value(Stat.THORNS)
		if thorns > 0.0:
			lines.append("Espinas:  %d de daño al recibir un golpe" % thorns)
		if s.get_value(Stat.LIFE_ON_KILL) > 0.0:
			lines.append("Vida al matar:  %d" % s.get_value(Stat.LIFE_ON_KILL))
		if skills != null and not skills.active_auras().is_empty():
			aliados.append("auras: " + ", ".join(skills.active_auras()))
		if player.mana_reserved > 0.0:
			aliados.append("maná reservado %d %%" % roundi(player.mana_reserved * 100.0))
		if not aliados.is_empty():
			lines.append("Aliados:  " + "  ·  ".join(aliados))
		# DPS de cada habilidad de la barra (T81).
		var bar := StatExplain.hotbar_dps_lines(skills)
		if bar.size() > 1:
			lines.append("")
			lines.append("DPS de la barra:")
			lines.append_array(bar)
		_offense_rows.text = "\n".join(lines)
	_skill_icon.queue_redraw()

	var points := character.passive_points_available()
	_passive_button.visible = points > 0
	_passive_button.text = "%d pasiva%s sin gastar (P)" % [points, "" if points == 1 else "s"]


func _mood_text() -> String:
	var s := character.stats
	if player.life < player.max_life() * 0.3:
		return "En pánico (controlado, dice)."
	if s.get_value(Stat.FIRE_RES) < 0.0 or s.get_value(Stat.COLD_RES) < 0.0 or s.get_value(Stat.LIGHTNING_RES) < 0.0:
		return "Inflamable, congelable y conductor. Polivalente."
	if character.passive_points_available() > 5:
		return "Acumulando puntos de pasiva. Para la jubilación."
	if int(character.flags.get("stat_deaths", 0)) > 10:
		return "Experto en reaparecer."
	return MOODS[(character.level + int(character.flags.get("stat_kills", 0)) / 25) % MOODS.size()]


func _deaths_text() -> String:
	var deaths := int(character.flags.get("stat_deaths", 0))
	if deaths == 0:
		return "0 muertes (de momento)"
	if deaths < 5:
		return "%d muertes (todas evitables)" % deaths
	return "%d muertes (ya es un patrón)" % deaths


## Fila con etiqueta, valor y una barra fina debajo que se llena con suavidad.
class StatBar extends Control:
	var label := ""
	var value_text := ""
	var fraction := 0.0
	var color := UiStyle.ACCENT
	var warning := false
	var height := 6.0
	var _shown := 0.0

	func _ready() -> void:
		custom_minimum_size = Vector2(0, 20.0 + height)
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func setup(p_label: String, p_value: String, p_fraction: float, p_color: Color, p_warning := false) -> void:
		label = p_label
		value_text = p_value
		fraction = clampf(p_fraction, 0.0, 1.0)
		color = p_color
		warning = p_warning
		custom_minimum_size.y = 20.0 + height
		queue_redraw()

	func _process(delta: float) -> void:
		if absf(_shown - fraction) > 0.001:
			_shown = move_toward(_shown, fraction, delta * 2.5)
			queue_redraw()

	func _draw() -> void:
		var font := get_theme_default_font()
		draw_string(font, Vector2(0, 14), label, HORIZONTAL_ALIGNMENT_LEFT, -1, 13, UiStyle.MUTED)
		draw_string(font, Vector2(0, 14), value_text, HORIZONTAL_ALIGNMENT_RIGHT, size.x, 13, UiStyle.DANGER if warning else UiStyle.TEXT)
		var bar := Rect2(0, 18, size.x, height)
		draw_rect(bar, Color(0, 0, 0, 0.45))
		if _shown > 0.0:
			var fill := Rect2(bar.position, Vector2(bar.size.x * _shown, bar.size.y))
			draw_rect(fill, color.darkened(0.25))
			draw_rect(Rect2(fill.position, Vector2(fill.size.x, maxf(1.0, height * 0.4))), color.lightened(0.15))
		draw_rect(bar, Color(1, 1, 1, 0.06), false, 1.0)
