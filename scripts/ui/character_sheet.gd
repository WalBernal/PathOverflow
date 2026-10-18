class_name CharacterSheet
extends PanelContainer
## Hoja de personaje (tecla C): retrato animado, datos, atributos, defensas,
## resistencias y ofensiva, con comentarios sarcásticos según cómo vayas.

const MOODS := [
	"Funcional, a duras penas.", "Estable (versión beta).", "Optimista sin motivo aparente.",
	"Cansado, pero desplegado.", "En modo legacy.", "Pendiente de refactorizar.",
]
const QUOTES := [
	"«No es un bug, es una feature.» — Tú, cada día.",
	"«Funciona en mi máquina.» — Tu epitafio.",
	"«Lo arreglo en el siguiente sprint.» — Nunca.",
	"«¿Quién ha escrito esto?» — Tú, hace dos semanas.",
	"«Es un cambio pequeño.» — Famosas últimas palabras.",
]

var character: CharacterData
var player: Player
var skills: SkillController

var _portrait: CharacterPortrait
var _caption: Label
var _header: RichTextLabel
var _left: RichTextLabel
var _right: RichTextLabel
var _quote: Label
var _refresh_timer := 0.0
var _rng := RandomNumberGenerator.new()


func setup(p_character: CharacterData, p_player: Player, p_skills: SkillController) -> void:
	character = p_character
	player = p_player
	skills = p_skills
	_portrait.appearance = character.appearance
	visibility_changed.connect(func() -> void:
		if visible:
			_quote.text = QUOTES[_rng.randi_range(0, QUOTES.size() - 1)]
			_refresh())


func _ready() -> void:
	_rng.randomize()
	add_theme_stylebox_override("panel", UiStyle.panel_style())
	theme = UiStyle.make_theme()
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	add_child(box)

	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", 16)
	box.add_child(top)
	var portrait_box := VBoxContainer.new()
	top.add_child(portrait_box)
	_portrait = CharacterPortrait.new()
	_portrait.custom_minimum_size = Vector2(190, 210)
	portrait_box.add_child(_portrait)
	_caption = UiStyle.label("", 12, Color("6fb36b"))
	_caption.custom_minimum_size.x = 190
	_caption.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	portrait_box.add_child(_caption)
	_portrait.caption_changed.connect(func(text: String) -> void: _caption.text = "> " + text)

	_header = _rich(360)
	top.add_child(_header)

	var columns := HBoxContainer.new()
	columns.add_theme_constant_override("separation", 24)
	box.add_child(columns)
	_left = _rich(270)
	columns.add_child(_left)
	_right = _rich(290)
	columns.add_child(_right)

	_quote = UiStyle.label("", 12, UiStyle.MUTED)
	_quote.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(_quote)


func _rich(width: float) -> RichTextLabel:
	var r := RichTextLabel.new()
	r.bbcode_enabled = true
	r.fit_content = true
	r.custom_minimum_size.x = width
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return r


func _process(delta: float) -> void:
	if not visible or character == null:
		return
	_portrait.life_fraction = player.life / player.max_life()
	_refresh_timer -= delta
	if _refresh_timer <= 0.0:
		_refresh_timer = 0.5
		_refresh()


func _refresh() -> void:
	if character == null:
		return
	var s := character.stats
	var main := skills.profile(0)
	_portrait.feeling_powerful = main.get("dps", 0.0) > 60.0 * character.level

	var asc: String = character.ascendancy_def.get("name", "sin ascendencia (aún)")
	_header.text = "[font_size=26][color=#d9a441]%s[/color][/font_size]\n%s · Nivel %d\n[color=#8a8293]%s[/color]\n\n%s%s%s%s%s" % [
		character.character_name, character.class_def["name"], character.level, asc,
		_kv("Experiencia", "%d / %d" % [character.experience, character.experience_to_next()]),
		_kv("Estado de ánimo", _mood()),
		_kv("Tiempo jugado", UiStyle.play_time(character.play_time)),
		_kv("Enemigos eliminados", str(int(character.flags.get("stat_kills", 0)))),
		_kv("Muertes", _deaths_text()),
	]

	var left := _section("Atributos")
	left += _kv("Fuerza", "%d" % s.get_value(Stat.STRENGTH))
	left += _kv("Destreza", "%d" % s.get_value(Stat.DEXTERITY))
	left += _kv("Inteligencia", "%d" % s.get_value(Stat.INTELLIGENCE))
	left += _section("Defensa")
	left += _kv("Vida", "%d / %d" % [player.life, player.max_life()])
	left += _kv("Escudo de energía", "%d" % player.max_energy_shield())
	left += _kv("Maná", "%d / %d" % [player.mana, player.max_mana()])
	left += _kv("Regeneración de vida", "%.1f /s" % s.get_value(Stat.LIFE_REGEN))
	var armour := s.get_value(Stat.ARMOUR)
	left += _kv("Armadura", "%d  [color=#8a8293](-%d%% a golpes de 50)[/color]" % [armour, roundi(100.0 * minf(0.9, armour / (armour + 250.0)))])
	var evasion := s.get_value(Stat.EVASION)
	left += _kv("Evasión", "%d  [color=#8a8293](%d%% esquivar)[/color]" % [evasion, roundi(100.0 * minf(Player.MAX_EVADE_CHANCE, evasion / (evasion + 600.0)))])
	left += _kv("Bloqueo", "%d%%" % minf(Player.MAX_BLOCK_CHANCE, s.get_value(Stat.BLOCK_CHANCE)))
	_left.text = left

	var right := _section("Resistencias")
	for entry in [[Stat.FIRE_RES, "Fuego", "e06c6c"], [Stat.COLD_RES, "Frío", "7fb8e0"],
			[Stat.LIGHTNING_RES, "Rayo", "e8d070"], [Stat.CHAOS_RES, "Caos", "b04ad9"]]:
		right += _resistance_line(s.get_value(entry[0]), entry[1], entry[2])
	right += _section("Ofensiva")
	if main.is_empty():
		right += "[color=#8a8293]Sin habilidad en la primera ranura. Atacas con... ¿opiniones?[/color]\n"
	else:
		right += _kv("Habilidad principal", main["name"])
		right += _kv("DPS estimado", "%.1f" % main["dps"])
		if main["max_damage"] > 0.0:
			right += _kv("Daño", "%d-%d" % [main["min_damage"], main["max_damage"]])
		right += _kv("Crítico", "%.1f%% (×%d%%)" % [main["crit_chance"], main["crit_multiplier"]])
		right += _kv("Usos por segundo", "%.2f" % main["uses_per_second"])
	right += _kv("Velocidad de movimiento", "%d%%" % s.get_value(Stat.MOVEMENT_SPEED))
	right += _kv("Robo de vida", "%.1f%%" % s.get_value(Stat.LIFE_LEECH))
	right += _kv("Pasivas sin gastar", _unspent_text())
	_right.text = right


func _section(title: String) -> String:
	return "\n[color=#d9a441][b]%s[/b][/color]\n" % title


func _kv(label: String, value: String) -> String:
	return "[color=#8a8293]%s:[/color] %s\n" % [label, value]


func _resistance_line(value: float, label: String, color: String) -> String:
	var cap := Stat.RESISTANCE_CAP
	var shown := minf(value, cap)
	var note := ""
	if value < 0.0:
		note = "  [color=#e06c6c]te van a freír[/color]"
	elif value >= cap:
		note = "  [color=#6fb36b]al tope%s[/color]" % (" (+%d%% sobrante)" % (value - cap) if value > cap else "")
	elif value < 30.0:
		note = "  [color=#8a8293]papel de fumar[/color]"
	return "[color=#%s]%s:[/color] %d%%%s\n" % [color, label, shown, note]


func _mood() -> String:
	var s := character.stats
	if player.life < player.max_life() * 0.3:
		return "[color=#e06c6c]En pánico (controlado, dice).[/color]"
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
		return "0 [color=#8a8293](de momento)[/color]"
	if deaths < 5:
		return "%d [color=#8a8293](todas evitables)[/color]" % deaths
	return "%d [color=#8a8293](ya es un patrón)[/color]" % deaths


func _unspent_text() -> String:
	var points := character.passive_points_available()
	if points <= 0:
		return "0"
	return "%d [color=#e06c6c](pulsa P, por favor)[/color]" % points
