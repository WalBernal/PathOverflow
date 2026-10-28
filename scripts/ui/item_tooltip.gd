class_name ItemTooltip
extends PanelContainer
## Tooltip flotante de objetos que sigue al ratón. Con `compare`, muestra cómo
## cambiarían las cifras del personaje al equiparlo (verde mejora, rojo empeora)
## y, al lado, otro tooltip con lo que llevas equipado en esa ranura.

const WIDTH := 360.0
## Lo más que se encoge un tooltip (con su comparación) para caber en alto (T142).
const MIN_FIT := 0.6
const GREY := "8a8293"
const MOD_COLOR := "8888ff"
const FLAVOR_COLOR := "af6025"
const SET_ACTIVE := "1ba01b"
const UP := "6fb36b"
const DOWN := "e06c6c"

var _label: RichTextLabel
## Tooltips de lo equipado (comparación lado a lado; dos si es un anillo y
## llevas dos); los coloca este.
var _sides: Array[ItemTooltip] = []
var _is_side := false
## Copia fijada (F o Y del mando): se queda quieta en pantalla hasta soltarla.
var _frozen := false
var _pinned: ItemTooltip
var _item: Item
var _character: CharacterData
var _compare := false
## Lo que pidió quien lo abrió (sin contar Alt) y si Alt estaba pulsada.
var _requested_compare := false
var _alt_held := false


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	visible = false
	visibility_changed.connect(func() -> void:
		if not visible:
			for s in _sides:
				s.hide())
	tree_exiting.connect(func() -> void:
		for s in _sides:
			s.queue_free())
	var style := StyleBoxFlat.new()
	style.bg_color = Color("0d0b10f5")
	style.set_border_width_all(1)
	style.border_color = Color("3a3442")
	style.set_content_margin_all(10)
	add_theme_stylebox_override("panel", style)
	_label = RichTextLabel.new()
	_label.bbcode_enabled = true
	_label.fit_content = true
	_label.custom_minimum_size = Vector2(WIDTH, 0)
	_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_label)


func _process(_delta: float) -> void:
	if not visible or _is_side:
		return
	# Alt (T79): comparación rápida con lo equipado en cualquier tooltip (alijo,
	# tienda, suelo, lo ya equipado); al soltarla vuelve a como estaba.
	var alt := Input.is_key_pressed(KEY_ALT)
	if _item and _item.is_equipment() and alt != _alt_held:
		_alt_held = alt
		var keep := _requested_compare
		show_item(_item, _character, keep or alt)
		_requested_compare = keep
	# En coordenadas de pantalla: la interfaz puede estar escalada (GameUI).
	var view := get_viewport_rect().size
	# T142: lo equipado va al lado si cabe a lo ancho y, si no (pantalla estrecha con la
	# interfaz grande), debajo; y si no cabe en alto, todo se encoge (hasta MIN_FIT) en
	# vez de salirse por abajo.
	var open_sides := _sides.filter(func(s: ItemTooltip) -> bool: return s.visible)
	var parent_scale := (get_parent() as CanvasItem).get_global_transform().get_scale().y if get_parent() is CanvasItem else 1.0
	var sides_w := 0.0
	var sides_h := 0.0
	for s: ItemTooltip in open_sides:
		sides_w = maxf(sides_w, s.size.x)
		sides_h += s.size.y + 8.0
	var stacked := not open_sides.is_empty() and (size.x + sides_w + 24.0) * parent_scale > view.x
	var total := size.y + sides_h if stacked else maxf(size.y, sides_h - 8.0)
	var fit := clampf((view.y - 8.0) / maxf(1.0, total * parent_scale), MIN_FIT, 1.0)
	scale = Vector2(fit, fit)
	for s in _sides:
		s.scale = scale
	var shown := size * get_global_transform().get_scale()
	var pos := global_position
	if not _frozen:
		var mouse := get_viewport().get_mouse_position()
		pos = mouse + Vector2(20, 20)
		if pos.x + shown.x > view.x:
			pos.x = mouse.x - shown.x - 20.0
		pos.y = clampf(pos.y, 4.0, maxf(4.0, view.y - total * parent_scale * fit - 4.0))
		pos.x = clampf(pos.x, 4.0, maxf(4.0, view.x - shown.x - 4.0))
		global_position = pos
	if stacked:
		var below := pos.y + shown.y + 8.0 * fit * parent_scale
		for side: ItemTooltip in open_sides:
			side.global_position = Vector2(pos.x, below)
			below += side.size.y * side.get_global_transform().get_scale().y + 8.0 * fit * parent_scale
		return
	# Lo equipado, al lado: a la izquierda si cabe; si no, a la derecha. Dos
	# anillos van uno debajo del otro.
	var y := pos.y
	for side in _sides:
		if not side.visible:
			continue
		var side_shown := side.size * side.get_global_transform().get_scale()
		var side_pos := Vector2(pos.x - side_shown.x - 8.0, y)
		if side_pos.x < 4.0:
			side_pos.x = pos.x + shown.x + 8.0
		side_pos.y = clampf(side_pos.y, 4.0, maxf(4.0, view.y - side_shown.y - 4.0))
		side.global_position = side_pos
		y = side_pos.y + side_shown.y + 8.0


func show_item(item: Item, character: CharacterData, compare: bool) -> void:
	if item == null:
		hide()
		return
	_item = item
	_character = character
	_compare = compare
	_requested_compare = compare
	if not _is_side and Input.is_key_pressed(KEY_ALT) and wants_compare(item):
		_compare = true   # con Alt pulsada, ya sale comparando
		compare = true
	_alt_held = Input.is_key_pressed(KEY_ALT)
	var border: StyleBoxFlat = get_theme_stylebox("panel")
	border.border_color = Rarity.item_color(item.rarity).darkened(0.3)
	_label.text = build_text(item, character, compare)
	if _is_side:
		_label.text = "[center][color=#%s]· Equipado ahora ·[/color][/center]\n%s" % [GREY, _label.text]
	elif _frozen:
		_label.text = "[center][color=#%s]· Fijado (F o Y para soltarlo) ·[/color][/center]\n%s" % [GREY, _label.text]
	reset_size()
	var was_visible := visible
	show()
	if not was_visible:
		UiMotion.fade_in(self)   # aparece con un fundido (T97)
	_update_sides(item, character, compare)


## Muestra (o esconde) al lado lo que llevas en las ranuras contra las que se compara.
func _update_sides(item: Item, character: CharacterData, compare: bool) -> void:
	if _is_side:
		return
	var equipped: Array[Item] = []
	if compare and character and item.is_equipment():
		for s in compare_slots(item, character):
			var e: Item = character.inventory.equipped(s)
			if e != null and e != item:
				equipped.append(e)
	elif compare and character and item is Motherboard:   # la de la misma habilidad en tu barra (T127)
		var rival := board_rival(item as Motherboard, character)
		if rival:
			equipped.append(rival)
	while _sides.size() < equipped.size():
		var side := ItemTooltip.new()
		side._is_side = true
		get_parent().add_child(side)
		_sides.append(side)
	for i in _sides.size():
		if i < equipped.size():
			_sides[i].show_item(equipped[i], character, false)
		else:
			_sides[i].hide()


## F (o Y con el cursor de mando): deja una copia quieta de lo que se ve, con su
## comparación, para poder mover el cursor; otra vez la quita. True si quedó fijada.
func toggle_pin() -> bool:
	if unpin():
		return false
	if not visible or _item == null or _is_side or _frozen:
		return false
	_pinned = ItemTooltip.new()
	_pinned._frozen = true
	get_parent().add_child(_pinned)
	_pinned.global_position = global_position
	_pinned.show_item(_item, _character, _compare)
	return true


## Quita la copia fijada, si la hay. True si había una.
func unpin() -> bool:
	if _pinned == null or not is_instance_valid(_pinned):
		_pinned = null
		return false
	_pinned.queue_free()
	_pinned = null
	return true


func is_pinned() -> bool:
	return _pinned != null and is_instance_valid(_pinned)


static func build_text(item: Item, character: CharacterData, compare: bool) -> String:
	if item is Motherboard:
		var bt := _motherboard_text(item as Motherboard, character)
		if compare and character:   # contra la de la misma habilidad en tu barra (T127)
			bt += "\n" + _section(board_comparison(item as Motherboard, board_rival(item as Motherboard, character), character))
		return bt.strip_edges()
	if item is RamModule:
		var rt := _ram_text(item as RamModule)
		if compare and character:   # qué haría en cada placa de tu barra (T127)
			rt += "\n" + _section(ram_comparison(item as RamModule, character))
		return rt.strip_edges()
	if item is Flask:
		return _flask_text(item as Flask, character)
	if item is KeyItem:
		return "[center][color=#%s][b]%s[/b][/color]\n[color=#%s]Objeto clave[/color][/center]\n%s" % [
			KeyItem.COLOR.to_html(false), item.display_name(), GREY,
			_section("[i][color=#a08f6a]%s[/color][/i]" % (item as KeyItem).description())]
	var color := Rarity.item_color(item.rarity).to_html(false)
	var t := "[center][color=#%s][b]%s[/b][/color]\n" % [color, item.display_name()]
	if item.rarity != Rarity.Item.NORMAL and item.rarity != Rarity.Item.MAGIC:
		t += "[color=#%s]%s[/color]\n" % [color, item.base["name"]]
	t += "[color=#%s]%s · %s[/color][/center]\n" % [GREY, Rarity.item_name(item.rarity), Inventory.SLOT_NAMES.get(_slot_key(item), item.slot())]

	t += _section(_base_lines(item))
	t += "[color=#%s]Nivel de objeto: %d   ·   Requiere nivel %d[/color]\n" % [GREY, item.item_level, item.required_level()]
	var req := item.attribute_requirements()
	if not req.is_empty():
		var parts := PackedStringArray()
		var missing := character.missing_attributes(item) if character else {}
		for a in req:
			parts.append("[color=#%s]%s %d[/color]" % [DOWN if missing.has(a) else GREY, Item.ATTR_NAMES[a], req[a]])
		t += "[color=#%s]Requiere:[/color] %s\n" % [GREY, "  ·  ".join(parts)]
	if character and character.level < item.required_level():
		t += "[color=#%s]Nivel insuficiente[/color]\n" % DOWN
	elif character and not character.missing_attributes(item).is_empty():
		var lack := PackedStringArray()
		for a in character.missing_attributes(item):
			lack.append("%d de %s" % [character.missing_attributes(item)[a], Item.ATTR_NAMES[a]])
		t += "[color=#%s]Te faltan %s[/color]\n" % [DOWN, " y ".join(lack)]

	var implicits := PackedStringArray()
	for m in item.implicit_mods():
		implicits.append(Item.describe_mod(m))
	t += _section("\n".join(implicits))

	var mods := PackedStringArray()
	for a in item.affixes:
		mods.append("%s  [color=#%s](%s T%d)[/color]%s" % [Item.describe_mod(a), GREY,
			"P" if a["kind"] == "prefix" else "S", a["tier_rank"], "  [color=#ff8a5a][fijado][/color]" if a.get("locked", false) else ""])
	for m in item.fixed_mods:
		mods.append(Item.describe_mod(m))
	if item is ExpansionChip and not (item as ExpansionChip).transform_map().is_empty():
		mods.append((item as ExpansionChip).transform_text())
	t += _section("[color=#%s]%s[/color]" % [MOD_COLOR, "\n".join(mods)] if not mods.is_empty() else "")

	if not item.set_def.is_empty():
		t += _section(_set_lines(item, character))
	if item.unique_def.has("flavor"):
		t += _section("[i][color=#%s]%s[/color][/i]" % [FLAVOR_COLOR, item.unique_def["flavor"]])
	if compare and character:
		var slots := compare_slots(item, character)
		if slots.size() == 2:   # un anillo con los dos puestos: contra cada uno
			for s in slots:
				t += _section(_comparison(item, character, s))
		else:
			t += _section(_comparison(item, character))
	return t.strip_edges()


## ¿Se compara este objeto con lo equipado? Equipo, placas y RAM (T127).
static func wants_compare(item: Item) -> bool:
	return item != null and (item.is_equipment() or item is Motherboard or item is RamModule)


## La placa de tu barra contra la que se compara `board`: la de la misma habilidad (null
## si no la llevas o si `board` es esa misma).
static func board_rival(board: Motherboard, character: CharacterData) -> Motherboard:
	if character == null or character.inventory.boards.has(board):
		return null
	for b in character.inventory.boards:
		if b is Motherboard and b != board and String(b.skill_def.get("id", "")) == String(board.skill_def.get("id", "")):
			return b
	return null


## Una línea de diferencia: +/- en verde si mejora y en rojo si empeora (`lower_is_better`
## para el coste y el enfriamiento).
static func _delta_line(label: String, before: float, after: float, lower_is_better := false, fmt := "%d") -> String:
	var delta := after - before
	if absf(delta) < 0.005:
		return ""
	var good := delta < 0.0 if lower_is_better else delta > 0.0
	var pct := ("  (%+.0f %%)" % (delta / absf(before) * 100.0)) if absf(before) > 0.0001 else ""
	return "[color=#%s]%s: %s → %s%s[/color]" % [UP if good else DOWN, label, fmt % before, fmt % after, pct]


## Placa contra la de tu barra: DPS, coste, usos/s, radio, proyectiles, enfriamiento,
## nivel y ranuras, con lo que mejora en verde y lo que empeora en rojo.
static func board_comparison(board: Motherboard, rival: Motherboard, character: CharacterData) -> String:
	if character == null:
		return ""
	if character.inventory.boards.has(board):
		return ""
	if rival == null:
		return "[color=#%s]No llevas esta habilidad en la barra: arrástrala a una casilla (K) para usarla.[/color]" % GREY
	var a := SkillCalc.compute(rival, character)
	var b := SkillCalc.compute(board, character)
	var lines := PackedStringArray()
	for row in [["DPS", "dps", false, "%d"], ["Coste de maná", "mana_cost", true, "%d"], ["Usos/s", "uses_per_second", false, "%.2f"],
			["Radio", "radius", false, "%d"], ["Proyectiles", "projectiles", false, "%d"], ["Enfriamiento", "cooldown", true, "%.1f s"]]:
		var l := _delta_line(row[0], float(a.get(row[1], 0.0)), float(b.get(row[1], 0.0)), row[2], row[3])
		if l != "":
			lines.append(l)
	var lv := _delta_line("Nivel", rival.level, board.level)
	if lv != "":
		lines.append(lv)
	var sl := _delta_line("Ranuras", rival.slots.size(), board.slots.size())
	if sl != "":
		lines.append(sl)
	if lines.is_empty():
		return "[color=#%s]Frente a la de tu barra: igual en las cifras principales.[/color]" % GREY
	return "[color=#%s]Frente a la de tu barra:[/color]\n%s" % [GREY, "\n".join(lines)]


## RAM contra tus placas: en cada placa de la barra que la admite, el DPS si la instalas
## en una ranura libre de su generación (o que no hay sitio).
static func ram_comparison(ram: RamModule, character: CharacterData) -> String:
	if character == null:
		return ""
	var lines := PackedStringArray()
	for board in character.inventory.boards:
		if not board is Motherboard or not ram.supports(board.skill_def):
			continue
		var name := String(board.skill_def.get("name", board.display_name()))
		var slot: int = board.free_slot_for(ram)
		if slot == -1:
			lines.append("[color=#%s]%s: sin ranura %s libre[/color]" % [GREY, name, ram.generation()])
			continue
		var p := SkillCalc.compute(board, character)
		var trial := Motherboard.new(board.skill_def, board.level, board.slots)
		trial.rams = board.rams.duplicate()
		trial.install(ram, slot)
		var l := _delta_line("%s, DPS" % name, float(p.get("dps", 0.0)), float(SkillCalc.compute(trial, character).get("dps", 0.0)))
		lines.append(l if l != "" else "[color=#%s]%s: no cambia su DPS[/color]" % [GREY, name])
	if lines.is_empty():
		return "[color=#%s]Ninguna placa de tu barra la admite.[/color]" % GREY
	return "[color=#%s]En tus placas:[/color]\n%s" % [GREY, "\n".join(lines)]


## Ranuras contra las que se compara: las dos de anillo si llevas dos anillos;
## si no, la ranura donde iría.
static func compare_slots(item: Item, character: CharacterData) -> Array[String]:
	var inv := character.inventory
	if item.slot() == "ring" and inv.equipment.has("ring_left") and inv.equipment.has("ring_right"):
		var out: Array[String] = []
		for s in ["ring_left", "ring_right"]:
			if inv.equipped(s) != item:
				out.append(s)
		return out
	return [inv.target_slot_for(item)]


static func _tag_list(tags: Array) -> String:
	return SkillTags.bbcode(tags)


static func _motherboard_text(board: Motherboard, character: CharacterData) -> String:
	var skill := board.skill_def
	var t := "[center][color=#%s][b]%s[/b][/color]\n[color=#%s]Placa base · Nivel %d[/color]\n%s[/center]\n" % [
		Motherboard.COLOR.to_html(false), board.display_name(), GREY, board.level, _tag_list(skill.get("tags", []))]
	t += _section("[i][color=#a08f6a]%s[/color][/i]" % skill.get("description", ""))
	# Progreso de la placa: experiencia, mejoras por nivel y hitos.
	var xp_line := "Nivel [color=#e8d9b0]%d[/color] / %d" % [board.level, Motherboard.MAX_LEVEL]
	if board.level < Motherboard.MAX_LEVEL:
		xp_line += "  ·  Experiencia [color=#e8d9b0]%d / %d[/color]" % [board.experience, board.experience_to_next()]
	var hits := PackedStringArray()
	for m in SkillCalc.MILESTONES:
		hits.append(("[color=#6fd36b]✔ nv. %d[/color]" if board.level >= m else "[color=#8a8293]nv. %d[/color]") % m)
	t += _section("%s\n[color=#8a8293]Cada nivel: más daño, +1 %% de área y duración, -1 %% de enfriamiento.[/color]\nHitos (%s): %s" % [
		xp_line, SkillCalc.milestone_text(skill), "  ".join(hits)])
	if character:
		var p := SkillCalc.compute(board, character)
		var lines := PackedStringArray()
		if p["max_damage"] > 0.0:
			lines.append("Daño: [color=#e8d9b0]%d-%d[/color]  ·  Crítico: [color=#e8d9b0]%.1f%%[/color]" % [p["min_damage"], p["max_damage"], p["crit_chance"]])
		if String(p.get("converted_from", "")) != "":
			lines.append("Daño convertido: [color=#e8d9b0]%s → %s[/color]" % [RamModule.DAMAGE_TYPE_NAMES.get(p["converted_from"], ""),
				RamModule.DAMAGE_TYPE_NAMES.get(p["damage_type"], "")])
		if p["kind"] in SkillController.CHANNEL_KINDS:
			lines.append("Canalizado: [color=#7fa8e0]%d de maná por segundo[/color]  ·  [color=#e8d9b0]%.2f[/color] golpes/s mientras la mantienes" % [p["mana_cost"], p["uses_per_second"]])
		else:
			lines.append("Coste: [color=#7fa8e0]%d de maná[/color]  ·  [color=#e8d9b0]%.2f[/color] usos/s" % [p["mana_cost"], p["uses_per_second"]])
		if p["radius"] > 0.0:
			lines.append("Radio: [color=#e8d9b0]%d[/color]" % p["radius"])
		if p["projectiles"] > 0:
			lines.append("Proyectiles: [color=#e8d9b0]%d[/color]  ·  Atraviesan: [color=#e8d9b0]%d[/color]" % [p["projectiles"], p["pierce"]])
		if p["cooldown"] > 0.0:
			lines.append("Enfriamiento: [color=#e8d9b0]%.1f s[/color]" % p["cooldown"])
		if p["repeats"] > 0:
			lines.append("Se repite [color=#e8d9b0]%d[/color] vez más" % p["repeats"])
		if p["kind"] == "unit":
			lines.append("[color=#9ad0ff]Persistente[/color]: hasta [color=#e8d9b0]%d[/color] a la vez · vida [color=#e8d9b0]%d[/color] · reserva [color=#7fa8e0]%d %%[/color] del maná cada una" % [
				p["max_units"], p["unit_life"], roundi(p["reserve"])])
		if not (p.get("owner_buff", []) as Array).is_empty():
			var buff_lines := PackedStringArray()
			for md in p["owner_buff"]:
				buff_lines.append(Modifier.from_dict(md).describe())
			lines.append("[color=#c8a878]Mientras viva, te da:[/color] [color=#%s]%s[/color]" % [MOD_COLOR, " · ".join(buff_lines)])
		if p["automaton_speed"] != 1.0:
			lines.append("Velocidad de autómata: [color=#e8d9b0]×%.2f[/color]" % p["automaton_speed"])
		if not p["ailments"].is_empty():
			var parts := PackedStringArray()
			for id in Ailments.ALL:
				if p["ailments"].has(id):
					parts.append("[color=#%s]%d %% %s[/color]" % [Ailments.color(id).to_html(false), roundi(p["ailments"][id]), Ailments.display_name(id).to_lower()])
			lines.append("Estados: " + " · ".join(parts))
		t += _section("\n".join(lines))
	var slots := PackedStringArray()
	for i in board.slots.size():
		var gen: String = board.slots[i]
		var gen_color: String = RamModule.GENERATION_COLORS[gen].to_html(false)
		var ram: RamModule = board.rams[i]
		var content := "[color=#%s]vacía[/color]" % GREY
		if ram:
			var active := ram.supports(board.skill_def)
			content = "[color=#%s]%s[/color]" % [gen_color if active else DOWN, ram.def["name"]]
			if not active:
				content += " [color=#%s](no compatible: no hace nada)[/color]" % GREY
		slots.append("[color=#%s]%s[/color]  %s" % [gen_color, gen, content])
	t += _section("[color=#%s]Ranuras DIMM (%d):[/color]\n%s" % [GREY, board.slots.size(), "\n".join(slots)])
	return t.strip_edges()


static func _ram_text(ram: RamModule) -> String:
	var color := ram.display_color().to_html(false)
	var t := "[center][color=#%s][b]%s[/b][/color]\n[color=#%s]Módulo RAM · %s[/color][/center]\n" % [
		color, ram.def["name"], GREY, ram.generation()]
	t += _section("[i][color=#a08f6a]%s[/color][/i]" % ram.def.get("description", ""))
	t += _section("[color=#%s]%s[/color]" % [MOD_COLOR, "\n".join(ram.effect_lines())])
	# RAM de asistencia: explica qué hace cada estado que puede aplicar.
	var helps := PackedStringArray()
	for md in ram.def.get("mods", []):
		for id in Ailments.ALL:
			if String(md.get("stat", "")) == String(Ailments.CHANCE_STAT[id]):
				helps.append("[color=#%s]%s[/color]: %s" % [Ailments.color(id).to_html(false), Ailments.display_name(id), Ailments.description(id)])
	if not helps.is_empty():
		t += _section("\n".join(helps))
	var compat := PackedStringArray()
	var required: Array = ram.def.get("requires_tags", [])
	compat.append("Funciona con: %s" % ("cualquier habilidad" if required.is_empty() else "habilidades con " + _tag_list(required)))
	var excluded: Array = ram.def.get("excludes_tags", [])
	if not excluded.is_empty():
		compat.append("No funciona con: " + _tag_list(excluded))
	compat.append("Se instala en ranuras %s de una placa base (K)." % ram.generation())
	t += _section("[color=#%s]%s[/color]" % [GREY, "\n".join(compat)])
	return t.strip_edges()


static func _flask_text(flask: Flask, character: CharacterData) -> String:
	var color := flask.display_color().to_html(false)
	var t := "[center][color=#%s][b]%s[/b][/color]\n[color=#%s]%s · Requiere nivel %d[/color][/center]\n" % [
		color, flask.display_name(), GREY, Flask.KIND_NAMES[flask.kind()], flask.required_level()]
	if character and character.level < flask.required_level():
		t += "[color=#%s]Nivel insuficiente[/color]\n" % DOWN
	t += _section("[color=#%s]%s[/color]" % [MOD_COLOR, "\n".join(flask.effect_lines())])
	t += _section("Cargas: [color=#e8d9b0]%d / %d[/color]  ·  Usos: [color=#e8d9b0]%d[/color]" % [flask.charges, flask.max_charges(), flask.uses_left()])
	t += _section("[i][color=#a08f6a]%s[/color][/i]" % flask.def.get("description", ""))
	t += _section("[color=#%s]Click o arrastra al cinturón de pociones (teclas 1-5). Matar enemigos recarga las cargas.[/color]" % GREY)
	return t.strip_edges()


static func _slot_key(item: Item) -> String:
	return "ring_left" if item.slot() == "ring" else item.slot()


static func _section(body: String) -> String:
	if body.strip_edges() == "":
		return ""
	return "[color=#3a3442]────────────────────[/color]\n%s\n" % body


static func _base_lines(item: Item) -> String:
	var lines := PackedStringArray()
	if item.is_weapon():
		lines.append("Daño físico: [color=#e8d9b0]%d-%d[/color]" % [item.physical_min, item.physical_max])
		lines.append("Ataques por segundo: [color=#e8d9b0]%.2f[/color]" % item.attacks_per_second)
		lines.append("Prob. de crítico: [color=#e8d9b0]%.1f%%[/color]" % item.crit_chance)
	if item.armour > 0.0:
		lines.append("Armadura: [color=#e8d9b0]%d[/color]" % item.armour)
	if item.evasion > 0.0:
		lines.append("Evasión: [color=#e8d9b0]%d[/color]" % item.evasion)
	if item.energy_shield > 0.0:
		lines.append("Escudo de energía: [color=#e8d9b0]%d[/color]" % item.energy_shield)
	return "\n".join(lines)


static func _set_lines(item: Item, character: CharacterData) -> String:
	var set_def := item.set_def
	var count: int = character.equipped_set_counts().get(set_def["id"], 0) if character else 0
	var lines := PackedStringArray()
	lines.append("[color=#%s]%s (%d/%d equipadas)[/color]" % [SET_ACTIVE, set_def["name"], count, set_def["pieces"].size()])
	for threshold in set_def["bonuses"]:
		var active := count >= int(threshold)
		for md in set_def["bonuses"][threshold]:
			lines.append("[color=#%s](%s) %s[/color]" % [SET_ACTIVE if active else GREY, threshold, Modifier.from_dict(md).describe()])
	return "\n".join(lines)


static func _comparison(item: Item, character: CharacterData, slot := "") -> String:
	var before := character.summary()
	var after := character.preview_equip(item, slot)
	var title := "Al equiparlo" if slot == "" else "En lugar del %s" % {"ring_left": "anillo izquierdo", "ring_right": "anillo derecho"}.get(slot, Inventory.SLOT_NAMES.get(slot, slot).to_lower())
	var lines := PackedStringArray()
	for key in before:
		var delta: float = after[key] - before[key]
		if absf(delta) < 0.05:
			continue
		var amount := "%.1f" % absf(delta) if absf(delta) < 10.0 and not is_equal_approx(delta, roundf(delta)) else "%d" % roundi(absf(delta))
		lines.append("[color=#%s]%s%s %s[/color]" % [UP if delta > 0.0 else DOWN, "+" if delta > 0.0 else "-", amount, key])
	if lines.is_empty():
		return "[color=#%s]%s: sin cambios en las cifras principales[/color]" % [GREY, title]
	return "[color=#%s]%s:[/color]\n%s" % [GREY, title, "\n".join(lines)]
