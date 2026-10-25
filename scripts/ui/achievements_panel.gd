class_name AchievementsPanel
extends AcceptDialog
## Pausa → Logros y cosméticos: la lista de logros (conseguidos o no, con su
## recompensa) y qué sombrero, aura y pisadas llevas puestos.

var character: CharacterData


func _init(p_character: CharacterData = null) -> void:
	character = p_character
	title = "Logros y cosméticos"
	ok_button_text = "Cerrar"
	theme = UiStyle.make_theme()
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 6)
	box.custom_minimum_size = Vector2(620, 0)
	add_child(box)
	close_requested.connect(queue_free)
	confirmed.connect(queue_free)
	if character == null:
		return
	var got := Achievements.unlocked_ids(character)
	box.add_child(UiStyle.label("Logros: %d/%d" % [got.size(), Achievements.DEFS.size()], 15, UiStyle.GOLD))
	for def in Achievements.DEFS:
		var done: bool = got.has(def["id"])
		var reward: String = Achievements.COSMETICS[def["reward"][0]][def["reward"][1]]
		var l := UiStyle.label("%s %s — %s  (premio: %s)" % ["[x]" if done else "[ ]", def["name"], def["text"], reward], 13,
			UiStyle.TEXT if done else UiStyle.MUTED)
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		box.add_child(l)
	box.add_child(UiStyle.section_header("Cosméticos"))
	for slot in Achievements.SLOTS:
		var row := HBoxContainer.new()
		var name_label := UiStyle.label(Achievements.SLOT_NAMES[slot], 13)
		name_label.custom_minimum_size.x = 120
		row.add_child(name_label)
		var pick := OptionButton.new()
		pick.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var ids: Array = [""] + Achievements.available(character, slot)
		for id in ids:
			pick.add_item("Ninguno" if id == "" else Achievements.COSMETICS[slot][id])
		pick.select(maxi(0, ids.find(Achievements.equipped(character, slot))))
		pick.item_selected.connect(func(i: int) -> void: Achievements.equip(character, slot, ids[i]))
		row.add_child(pick)
		box.add_child(row)
