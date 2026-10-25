class_name ItemTooltip
extends PanelContainer
## Tooltip flotante de objetos que sigue al ratón. Con `compare`, muestra cómo
## cambiarían las cifras del personaje al equiparlo (verde mejora, rojo empeora)
## y, al lado, otro tooltip con lo que llevas equipado en esa ranura.

const WIDTH := 360.0
const GREY := "8a8293"
const MOD_COLOR := "8888ff"
const FLAVOR_COLOR := "af6025"
const SET_ACTIVE := "1ba01b"
const UP := "6fb36b"
const DOWN := "e06c6c"

var _label: RichTextLabel
## Tooltip del objeto equipado (comparación lado a lado); lo coloca este.
var _side: ItemTooltip
var _is_side := false


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	visible = false
	visibility_changed.connect(func() -> void:
		if not visible and _side:
			_side.hide())
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
	# En coordenadas de pantalla: la interfaz puede estar escalada (GameUI).
	var view := get_viewport_rect().size
	var shown := size * get_global_transform().get_scale()
	var mouse := get_viewport().get_mouse_position()
	var pos := mouse + Vector2(20, 20)
	if pos.x + shown.x > view.x:
		pos.x = mouse.x - shown.x - 20.0
	pos.y = clampf(pos.y, 4.0, maxf(4.0, view.y - shown.y - 4.0))
	pos.x = clampf(pos.x, 4.0, maxf(4.0, view.x - shown.x - 4.0))
	global_position = pos
	if _side and _side.visible:
		# El equipado, al lado: a la izquierda si cabe; si no, a la derecha.
		var side_shown := _side.size * _side.get_global_transform().get_scale()
		var side_pos := Vector2(pos.x - side_shown.x - 8.0, pos.y)
		if side_pos.x < 4.0:
			side_pos.x = pos.x + shown.x + 8.0
		side_pos.y = clampf(side_pos.y, 4.0, maxf(4.0, view.y - side_shown.y - 4.0))
		_side.global_position = side_pos


func show_item(item: Item, character: CharacterData, compare: bool) -> void:
	if item == null:
		hide()
		return
	var border: StyleBoxFlat = get_theme_stylebox("panel")
	border.border_color = Rarity.item_color(item.rarity).darkened(0.3)
	_label.text = build_text(item, character, compare)
	if _is_side:
		_label.text = "[center][color=#%s]· Equipado ahora ·[/color][/center]\n%s" % [GREY, _label.text]
	reset_size()
	show()
	_update_side(item, character, compare)


## Muestra (o esconde) al lado el objeto que llevas en la ranura donde iría `item`.
func _update_side(item: Item, character: CharacterData, compare: bool) -> void:
	if _is_side:
		return
	var equipped: Item = null
	if compare and character and item.is_equipment():
		equipped = character.inventory.equipped(character.inventory.target_slot_for(item))
	if equipped == null or equipped == item:
		if _side:
			_side.hide()
		return
	if _side == null:
		_side = ItemTooltip.new()
		_side._is_side = true
		get_parent().add_child(_side)
	_side.show_item(equipped, character, false)


static func build_text(item: Item, character: CharacterData, compare: bool) -> String:
	if item is Motherboard:
		return _motherboard_text(item as Motherboard, character)
	if item is RamModule:
		return _ram_text(item as RamModule)
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
		mods.append("%s  [color=#%s](%s T%d)[/color]" % [Item.describe_mod(a), GREY,
			"P" if a["kind"] == "prefix" else "S", a["tier_rank"]])
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
		t += _section(_comparison(item, character))
	return t.strip_edges()


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


static func _comparison(item: Item, character: CharacterData) -> String:
	var before := character.summary()
	var after := character.preview_equip(item)
	var lines := PackedStringArray()
	for key in before:
		var delta: float = after[key] - before[key]
		if absf(delta) < 0.05:
			continue
		var amount := "%.1f" % absf(delta) if absf(delta) < 10.0 and not is_equal_approx(delta, roundf(delta)) else "%d" % roundi(absf(delta))
		lines.append("[color=#%s]%s%s %s[/color]" % [UP if delta > 0.0 else DOWN, "+" if delta > 0.0 else "-", amount, key])
	if lines.is_empty():
		return "[color=#%s]Al equiparlo: sin cambios en las cifras principales[/color]" % GREY
	return "[color=#%s]Al equiparlo:[/color]\n%s" % [GREY, "\n".join(lines)]
