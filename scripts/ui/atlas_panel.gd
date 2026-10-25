class_name AtlasPanel
extends AcceptDialog
## Pantalla del atlas de incidentes: nivel del atlas, zonas completadas por acto
## y los mapas guardados (cada uno abre su incidente). También el incidente al azar.

var character: CharacterData
## Abre un incidente: Callable(map: Dictionary) ({} = al azar).
var on_open: Callable
var _box: VBoxContainer


func _init(p_character: CharacterData = null, p_on_open: Callable = Callable()) -> void:
	character = p_character
	on_open = p_on_open
	title = "Atlas de incidentes"
	ok_button_text = "Cerrar"
	theme = UiStyle.make_theme()
	_box = VBoxContainer.new()
	_box.add_theme_constant_override("separation", 6)
	_box.custom_minimum_size = Vector2(640, 0)
	add_child(_box)
	close_requested.connect(queue_free)
	confirmed.connect(queue_free)
	if character:
		refresh()


func refresh() -> void:
	for ch in _box.get_children():
		_box.remove_child(ch)
		ch.queue_free()
	var t := Atlas.tier(character)
	var done := Atlas.done(character)
	var to_next := Atlas.COMPLETIONS_PER_TIER - done.size() % Atlas.COMPLETIONS_PER_TIER
	_box.add_child(UiStyle.label("Nivel del atlas: %d  ·  incidentes +%d niveles y +%d %% de botín" % [t, Atlas.level_bonus(character),
		roundi(Atlas.loot_bonus(character) * 100.0)], 15, UiStyle.GOLD))
	_box.add_child(UiStyle.label(("Faltan %d zonas distintas para el siguiente nivel." % to_next) if t < Atlas.MAX_TIER else "Atlas al máximo.", 12, UiStyle.MUTED))
	# Zonas completadas por acto.
	var by_act := {}
	for id in Incidents.candidates(GameData.zones, character.level + 40):
		var act_name: String = GameData.act_of_zone(id["id"]).get("name", "")
		if not by_act.has(act_name):
			by_act[act_name] = []
		by_act[act_name].append(id)
	for act_name in by_act:
		var names := PackedStringArray()
		for z in by_act[act_name]:
			names.append(("[x] " if done.has(z["id"]) else "[ ] ") + String(z.get("name", z["id"])))
		var l := UiStyle.label("%s\n   %s" % [act_name, "   ".join(names)], 12)
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_box.add_child(l)
	_box.add_child(UiStyle.section_header("Mapas (%d/%d)" % [Atlas.maps(character).size(), Atlas.MAX_MAPS]))
	var list: Array = Atlas.maps(character)
	if list.is_empty():
		_box.add_child(UiStyle.label("No tienes mapas. Caen al completar incidentes y, a veces, de los élites de dentro.", 12, UiStyle.MUTED))
	for k in list.size():
		var m: Dictionary = list[k]
		var row := HBoxContainer.new()
		var mods := PackedStringArray()
		for id in m.get("mods", []):
			mods.append(Incidents.MODS.get(id, {}).get("name", id))
		var l := UiStyle.label("%s  ·  %s" % [m.get("name", "Mapa"), ", ".join(mods)], 13)
		l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(l)
		row.add_child(UiStyle.button("Abrir", _open_map.bind(k), 90))
		_box.add_child(row)
	_box.add_child(UiStyle.button("Incidente al azar", func() -> void: _open({}), 220))


func _open_map(index: int) -> void:
	_open(Atlas.take_map(character, index))


func _open(map: Dictionary) -> void:
	if on_open.is_valid():
		on_open.call(map)
	queue_free()
