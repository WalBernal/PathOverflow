class_name LadderPanel
extends AcceptDialog
## Pausa → Récords (o Aída): tus mejores marcas y la tabla local de todos los
## personajes de este equipo, del banco de oleadas y del tiempo contra cada jefe.

var character: CharacterData


func _init(p_character: CharacterData = null) -> void:
	character = p_character
	title = "Récords"
	ok_button_text = "Cerrar"
	theme = UiStyle.make_theme()
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(640, 460)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(scroll)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 4)
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(box)
	close_requested.connect(queue_free)
	confirmed.connect(queue_free)
	var board := Ladder.load_board()
	var bosses := _boss_names()
	if character:
		var mine := Ladder.personal(character)
		box.add_child(UiStyle.section_header("Tus marcas"))
		var best := int(mine.get("best_wave", 0))
		box.add_child(UiStyle.label("Banco de oleadas: %s" % ("%d oleadas en %s" % [best, Ladder.format_time(float(mine["best_time"]))] if best > 0 else "sin intentar"), 13))
		for id in mine["bosses"]:
			box.add_child(UiStyle.label("%s: %s" % [bosses.get(id, id), Ladder.format_time(float(mine["bosses"][id]))], 13))
	box.add_child(UiStyle.section_header("Tabla local · banco de oleadas"))
	if board["waves"].is_empty():
		box.add_child(UiStyle.label("Nadie ha entrado todavía. Aída abre el banco en el campamento.", 13, UiStyle.MUTED))
	for i in board["waves"].size():
		var e: Dictionary = board["waves"][i]
		box.add_child(UiStyle.label("%d. %s (%s %d) — %d oleadas en %s · %s" % [i + 1, e["name"], e["class"], int(e["level"]), int(e["waves"]),
			Ladder.format_time(float(e["time"])), e["date"]], 13, UiStyle.GOLD if i == 0 else UiStyle.TEXT))
	for id in board["bosses"]:
		box.add_child(UiStyle.section_header("Tabla local · %s" % bosses.get(id, id)))
		var list: Array = board["bosses"][id]
		for i in list.size():
			var e: Dictionary = list[i]
			box.add_child(UiStyle.label("%d. %s (%s %d) — %s · %s" % [i + 1, e["name"], e["class"], int(e["level"]),
				Ladder.format_time(float(e["time"])), e["date"]], 13, UiStyle.GOLD if i == 0 else UiStyle.TEXT))


## Nombre de cada jefe de acto por su tipo de enemigo.
func _boss_names() -> Dictionary:
	var out: Dictionary = {}
	for id in GameData.zones:
		var boss = GameData.zones[id].get("boss")
		if boss is Dictionary:
			out[String(boss.get("type", ""))] = String(boss.get("name", boss.get("type", "")))
	return out
