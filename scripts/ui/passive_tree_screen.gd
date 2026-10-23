class_name PassiveTreeScreen
extends Control
## Pantalla del árbol pasivo. Dos modos:
## - standalone (escena suelta, F6): elegir clase y nivel para probar builds.
## - en juego (standalone = false): muestra el personaje que se le pasa con
##   show_character(); la clase y el nivel vienen del juego.
## La UI se construye en código mientras es un prototipo; cuando el diseño se
## asiente conviene pasarla a escenas + Theme para editarla visualmente.

signal closed

var standalone := true

var _character: CharacterData
var _standalone_controls: Array[Control] = []
var _close_button: Button
var _view: PassiveTreeView
var _class_option: OptionButton
var _ascendancy_panel: AscendancyPanel
var _level_spin: SpinBox
var _points_label: Label
var _status_label: Label
var _stats_label: RichTextLabel
var _tooltip: PanelContainer
var _tooltip_label: RichTextLabel
var _hovered_id := -1
var _search_edit: LineEdit
var _search_label: Label
var _search_matches: Array = []
var _search_index := -1


func _ready() -> void:
	_build_ui()
	for control in _standalone_controls:
		control.visible = standalone
	_close_button.visible = not standalone
	if standalone:
		for c in GameData.classes:
			_class_option.add_item(c["name"])
		_select_class(0)


func _process(_delta: float) -> void:
	if _tooltip.visible:
		var pos := get_local_mouse_position() + Vector2(20, 20)
		pos.x = minf(pos.x, size.x - _tooltip.size.x - 8.0)
		pos.y = minf(pos.y, size.y - _tooltip.size.y - 8.0)
		_tooltip.position = pos


# --- Construcción de la UI ---

func _build_ui() -> void:
	_view = PassiveTreeView.new()
	add_child(_view)
	_view.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_view.node_hovered.connect(_on_node_hovered)
	_view.node_clicked.connect(_on_node_clicked)
	_view.ascendancy_clicked.connect(func() -> void:
		_ascendancy_panel.allow_change = standalone
		_ascendancy_panel.open(_character))

	var top := PanelContainer.new()
	add_child(top)
	top.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	var bar := HBoxContainer.new()
	bar.add_theme_constant_override("separation", 12)
	top.add_child(bar)

	_close_button = Button.new()
	_close_button.text = "Cerrar (P)"
	_close_button.pressed.connect(func() -> void: closed.emit())
	bar.add_child(_close_button)

	var class_label := _make_label("Clase:")
	bar.add_child(class_label)
	_class_option = OptionButton.new()
	_class_option.item_selected.connect(_select_class)
	bar.add_child(_class_option)


	var level_label := _make_label("Nivel:")
	bar.add_child(level_label)
	_level_spin = SpinBox.new()
	_level_spin.min_value = 1
	_level_spin.max_value = CharacterData.MAX_LEVEL
	_level_spin.value = 40
	_level_spin.value_changed.connect(func(v: float) -> void: _character.set_level(int(v)))
	bar.add_child(_level_spin)
	_standalone_controls.assign([class_label, _class_option, level_label, _level_spin])

	_points_label = _make_label("")
	bar.add_child(_points_label)

	var reset := Button.new()
	reset.text = "Reiniciar árbol"
	reset.pressed.connect(func() -> void: _character.passives.reset())
	bar.add_child(reset)

	_search_edit = LineEdit.new()
	_search_edit.placeholder_text = "Buscar: vida, fuego, crítico..."
	_search_edit.custom_minimum_size.x = 240
	_search_edit.clear_button_enabled = true
	_search_edit.text_changed.connect(_on_search_changed)
	_search_edit.text_submitted.connect(func(_t: String) -> void: _focus_next_match())
	bar.add_child(_search_edit)
	_search_label = _make_label("")
	_search_label.add_theme_color_override("font_color", Color("e8d070"))
	bar.add_child(_search_label)

	_status_label = _make_label("")
	_status_label.add_theme_color_override("font_color", Color("e06c6c"))
	bar.add_child(_status_label)

	var hint := _make_label("Click izq.: asignar  ·  Click der.: quitar  ·  Arrastrar: mover  ·  Rueda: zoom  ·  Enter en la búsqueda: ir al siguiente resultado")
	add_child(hint)
	hint.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
	hint.position += Vector2(12, -12)
	hint.add_theme_color_override("font_color", Color("8a8293"))

	var side := PanelContainer.new()
	add_child(side)
	side.anchor_left = 1.0
	side.anchor_right = 1.0
	side.anchor_bottom = 1.0
	side.offset_left = -380.0
	side.offset_right = -10.0
	side.offset_top = 60.0
	side.offset_bottom = -10.0
	side.add_theme_stylebox_override("panel", _make_panel_style())
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	side.add_child(scroll)
	_stats_label = RichTextLabel.new()
	_stats_label.bbcode_enabled = true
	_stats_label.fit_content = true
	_stats_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(_stats_label)

	_tooltip = PanelContainer.new()
	_tooltip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_tooltip.visible = false
	_tooltip.add_theme_stylebox_override("panel", _make_panel_style())
	add_child(_tooltip)
	_tooltip_label = RichTextLabel.new()
	_tooltip_label.bbcode_enabled = true
	_tooltip_label.fit_content = true
	_tooltip_label.custom_minimum_size = Vector2(340, 0)
	_tooltip_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_tooltip.add_child(_tooltip_label)

	_ascendancy_panel = AscendancyPanel.new()
	_ascendancy_panel.theme = UiStyle.make_theme()
	add_child(_ascendancy_panel)
	_ascendancy_panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_ascendancy_panel.changed.connect(_refresh)

func _make_panel_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color("16131bf2")
	style.border_color = Color("3a3442")
	style.set_border_width_all(1)
	style.set_corner_radius_all(4)
	style.set_content_margin_all(12)
	return style


func _make_label(text: String) -> Label:
	var l := Label.new()
	l.text = text
	return l


# --- Eventos ---

func _select_class(index: int) -> void:
	var character := CharacterData.new(GameData.classes[index], GameData.passive_tree)
	character.set_level(int(_level_spin.value))
	show_character(character)


func show_character(character: CharacterData) -> void:
	if _character:
		_character.stats_changed.disconnect(_refresh)
	_character = character
	_character.stats_changed.connect(_refresh)

	_ascendancy_panel.visible = false
	_view.setup(_character.passives)
	var start := GameData.passive_tree.get_node_data(_character.passives.start_node_id)
	_view.center_on.call_deferred(start.position)
	_refresh()



func _on_node_clicked(id: int, button: MouseButton) -> void:
	var alloc := _character.passives
	if button == MOUSE_BUTTON_LEFT and not alloc.is_allocated(id):
		var cost := alloc.find_path(id).size()
		if cost > 0 and alloc.allocate_path(id, _character.passive_points_available()) == 0:
			_flash("Puntos insuficientes: necesitas %d" % cost)
	elif button == MOUSE_BUTTON_RIGHT and alloc.is_allocated(id):
		if not alloc.refund(id):
			_flash("No se puede quitar: desconectaría otros nodos")
	_on_node_hovered(id)


func _on_node_hovered(id: int) -> void:
	_hovered_id = id
	if id == -1:
		_tooltip.hide()
		return
	_tooltip_label.text = _build_tooltip(GameData.passive_tree.get_node_data(id))
	_tooltip.reset_size()
	_tooltip.show()


func _flash(message: String) -> void:
	_status_label.text = message
	get_tree().create_timer(2.5).timeout.connect(func() -> void:
		if _status_label.text == message:
			_status_label.text = "")


func _refresh() -> void:
	var available := _character.passive_points_available()
	_view.available_points = available
	_view.queue_redraw()
	_points_label.text = "Puntos: %d / %d" % [available, _character.passive_points_total()]
	if _character.ascendancy_points_total() > 0:
		_points_label.text += "   ·   Ascendencia: %d / %d" % [_character.ascendancy_points_available(), _character.ascendancy_points_total()]
	var asc_pending := _character.can_choose_ascendancy() or (not _character.ascendancy_def.is_empty() and _character.ascendancy_points_available() > 0)
	_view.ascendancy_info = {"unlocked": _character.level >= CharacterData.ASCENDANCY_LEVEL, "pending": asc_pending,
		"name": _character.ascendancy_def.get("name", "Elegir ascendencia")}
	_points_label.add_theme_color_override("font_color", Color("e06c6c") if available < 0 else Color("e8d9b0"))
	_stats_label.text = _build_stats_text()
	if _hovered_id != -1:
		_on_node_hovered(_hovered_id)


# --- Textos ---

func _build_tooltip(node: PassiveNode) -> String:
	var alloc := _character.passives
	var tree := alloc.tree
	var title_color := PassiveTreeView.border_color(node)
	if node.theme != "" and node.kind != PassiveNode.Kind.CLASS_START:
		title_color = tree.theme_color(node.theme).lightened(0.2)
	var subtitle := PassiveNode.kind_label(node.kind)
	if node.cluster != "":
		subtitle += " · " + tree.cluster_name(node.cluster)
	elif node.kind == PassiveNode.Kind.MINOR:
		subtitle += " · camino"
	var t := "[b][color=#%s]%s[/color][/b]\n[color=#8a8293]%s[/color]\n" % [
		title_color.to_html(false), node.title, subtitle]
	for m in node.mods:
		t += "• %s\n" % m.describe()
	if node.flavor != "":
		t += "\n[i][color=#a08f6a]%s[/color][/i]\n" % node.flavor
	t += "\n"
	if node.kind == PassiveNode.Kind.CLASS_START:
		t += "[color=#8a8293]Punto de inicio[/color]"
	elif alloc.is_allocated(node.id):
		if alloc.can_refund(node.id):
			t += "[color=#8a8293]Click derecho para quitar[/color]"
		else:
			t += "[color=#e06c6c]No se puede quitar: desconectaría otros nodos[/color]"
	else:
		var cost := alloc.find_path(node.id).size()
		if cost == 0:
			t += "[color=#e06c6c]No alcanzable[/color]"
		elif cost > _character.passive_points_available():
			t += "[color=#e06c6c]Coste: %d punto(s). No tienes suficientes[/color]" % cost
		else:
			t += "[color=#6fb36b]Coste: %d punto(s). Click izquierdo para asignar[/color]" % cost
	return t


func _build_stats_text() -> String:
	var s := _character.stats
	var c := _character.class_def
	var t := "[font_size=22][b]%s[/b][/font_size]\n[i][color=#a08f6a]%s[/color][/i]\n" % [c["name"], c["description"]]
	if not _character.ascendancy_def.is_empty():
		var a := _character.ascendancy_def
		t += "\n[b][color=#d9a441]%s[/color][/b]\n[i][color=#a08f6a]%s[/color][/i]\n" % [a["name"], a["description"]]
		var passives: Array = a.get("passives", [])
		for i in _character.ascendancy_nodes:
			t += "[b]%s[/b]\n" % passives[i]["name"]
			for md in passives[i].get("mods", []):
				t += "   • %s\n" % Modifier.from_dict(md).describe()
		if _character.ascendancy_points_available() > 0:
			t += "[color=#ffd84a]Tienes %d punto(s) de ascendencia: pulsa el medallón.[/color]\n" % _character.ascendancy_points_available()
	elif _character.can_choose_ascendancy():
		t += "\n[color=#ffd84a]Ya puedes elegir tu ascendencia: pulsa el medallón junto a tu clase.[/color]\n"

	t += _tree_summary()
	t += "\n[b]Atributos[/b]\n"
	t += _line("Fuerza", "%d" % s.get_value(Stat.STRENGTH))
	t += _line("Destreza", "%d" % s.get_value(Stat.DEXTERITY))
	t += _line("Inteligencia", "%d" % s.get_value(Stat.INTELLIGENCE))

	t += "\n[b]Defensa[/b]\n"
	t += _line("Vida", "%d" % s.get_value(Stat.LIFE))
	t += _line("Maná", "%d" % s.get_value(Stat.MANA))
	t += _line("Escudo de energía", "%d" % s.get_value(Stat.ENERGY_SHIELD))
	t += _line("Regeneración de vida", "%.1f/s" % s.get_value(Stat.LIFE_REGEN))
	t += _line("Armadura", "%d" % s.get_value(Stat.ARMOUR))
	t += _line("Evasión", "%d" % s.get_value(Stat.EVASION))
	t += _line("Bloqueo", "%d%%" % s.get_value(Stat.BLOCK_CHANCE))
	for res in [Stat.FIRE_RES, Stat.COLD_RES, Stat.LIGHTNING_RES, Stat.CHAOS_RES]:
		var raw := s.get_value(res)
		var shown := minf(raw, Stat.RESISTANCE_CAP)
		var extra := "  [color=#8a8293](%d%% sin tope)[/color]" % raw if raw > Stat.RESISTANCE_CAP else ""
		t += _line(Stat.display_name(res), "%d%%%s" % [shown, extra])

	t += "\n[b]Ofensiva[/b]\n"
	t += _damage_line("Daño físico (cuerpo a cuerpo)", Stat.PHYSICAL_DAMAGE, [Stat.TAG_ATTACK, Stat.TAG_MELEE])
	t += _damage_line("Daño físico (proyectiles)", Stat.PHYSICAL_DAMAGE, [Stat.TAG_ATTACK, Stat.TAG_PROJECTILE])
	t += _damage_line("Daño de fuego (hechizos)", Stat.FIRE_DAMAGE, [Stat.TAG_SPELL])
	t += _damage_line("Daño de frío (hechizos)", Stat.COLD_DAMAGE, [Stat.TAG_SPELL])
	t += _damage_line("Daño de rayo (hechizos)", Stat.LIGHTNING_DAMAGE, [Stat.TAG_SPELL])
	t += _damage_line("Daño de caos", Stat.CHAOS_DAMAGE, [])
	t += _damage_line("Daño de esbirros", Stat.MINION_DAMAGE, [])
	t += _line("Velocidad de ataque", _total_pct(Stat.ATTACK_SPEED))
	t += _line("Velocidad de lanzamiento", _total_pct(Stat.CAST_SPEED))
	t += _line("Prob. de crítico", _total_pct(Stat.CRIT_CHANCE))
	t += _line("Multiplicador de crítico", "%d%%" % s.get_value(Stat.CRIT_MULTIPLIER))
	t += _line("Precisión", "%d" % s.get_value(Stat.ACCURACY))
	t += _line("Área de efecto", _total_pct(Stat.AREA_OF_EFFECT))
	t += _line("Velocidad de movimiento", "%d%%" % s.get_value(Stat.MOVEMENT_SPEED))
	t += _line("Robo de vida", "%.1f%%" % s.get_value(Stat.LIFE_LEECH))
	return t


## Suma de todo lo asignado en el árbol, agrupado por efecto (como el resumen de PoE).
func _tree_summary() -> String:
	var totals := {}   # "stat|tipo|tags" -> [Modifier de ejemplo, suma]
	for m in _character.passives.collect_modifiers():
		var tag_names := PackedStringArray()
		for tag in m.tags:
			tag_names.append(String(tag))
		tag_names.sort()
		var key := "%s|%d|%s" % [m.stat, m.type, ",".join(tag_names)]
		if totals.has(key):
			totals[key][1] += m.value
		else:
			totals[key] = [m, m.value]
	if totals.is_empty():
		return "\n[b]Bonificaciones del árbol[/b]\n[color=#8a8293]Nada asignado todavía. Tu potencial, intacto.[/color]\n"
	var lines: Array = []
	for key in totals:
		var sample: Modifier = totals[key][0]
		var total := Modifier.new(sample.stat, sample.type, totals[key][1], sample.tags)
		lines.append(total.describe())
	lines.sort()
	return "\n[b]Bonificaciones del árbol[/b]  [color=#8a8293](%d pasivas)[/color]\n[color=#8888ff]%s[/color]\n" % [
		_character.passives.spent_points(), "\n".join(PackedStringArray(lines))]


# --- Búsqueda ---

## Palabras con las que el buscador también encuentra cada temática: los
## estados por su nombre («veneno», «sangrado», «congelar»...) y los aliados por
## lo que son («torreta», «golem», «aura»...).
const THEME_KEYWORDS := {
	"ignicion": "quemar quemado quemadura incendiar arder estado alterado",
	"sobrecarga": "electrocutar electrocutado electrocucion descarga chispa estado alterado",
	"criogenia": "helar helado congelar congelado congelacion escarcha hielo estado alterado",
	"toxinas": "veneno envenenar envenenado toxico estado alterado",
	"hemorragia": "sangrar sangrado sangrando sangre estado alterado",
	"automatizacion": "torreta dron drones mina automata automatas invocacion invocaciones aliado aliados",
	"legion": "aliado aliados invocacion invocaciones golem esbirro esbirros aura auras reserva",
}

func _on_search_changed(text: String) -> void:
	_search_matches.clear()
	_search_index = -1
	var query := _normalize(text.strip_edges())
	if query.length() >= 2:
		var tree := _character.passives.tree
		for id in tree.nodes:
			var n: PassiveNode = tree.nodes[id]
			var haystack := "%s %s %s %s" % [n.title, tree.theme_name(n.theme), tree.cluster_name(n.cluster), THEME_KEYWORDS.get(n.theme, "")]
			for m in n.mods:
				haystack += " " + m.describe()
			if _normalize(haystack).contains(query):
				_search_matches.append(id)
	_view.set_search(_search_matches)
	_search_label.text = "" if query.length() < 2 else "%d coincidencias" % _search_matches.size()


func _focus_next_match() -> void:
	if _search_matches.is_empty():
		return
	_search_index = (_search_index + 1) % _search_matches.size()
	_view.center_on(_character.passives.tree.get_node_data(_search_matches[_search_index]).position)


## Minúsculas y sin tildes, para que "critico" encuentre "Crítico".
static func _normalize(text: String) -> String:
	var t := text.to_lower()
	for pair in [["á", "a"], ["é", "e"], ["í", "i"], ["ó", "o"], ["ú", "u"], ["ü", "u"], ["ñ", "n"]]:
		t = t.replace(pair[0], pair[1])
	return t


func _line(label: String, value: String) -> String:
	return "%s: [color=#e8d9b0]%s[/color]\n" % [label, value]


func _damage_line(label: String, stat: StringName, tags: Array) -> String:
	var b := _character.stats.get_breakdown(stat, tags)
	return _line(label, "%s aumento · ×%.2f más" % [_signed_pct(b.increased), b.more])


## Modificador total (aumentos y más combinados) sobre una base del 100%.
func _total_pct(stat: StringName) -> String:
	var b := _character.stats.get_breakdown(stat)
	return _signed_pct(((1.0 + b.increased / 100.0) * b.more - 1.0) * 100.0)


static func _signed_pct(v: float) -> String:
	return "%s%d%%" % ["+" if v >= 0.0 else "", roundi(v)]
