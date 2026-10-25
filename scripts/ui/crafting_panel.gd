class_name CraftingPanel
extends AcceptDialog
## Mesa de crafteo de Mario: eliges un objeto equipado, ves sus afijos y usas o
## compras parches (Crafting). El hotfix fija el afijo elegido en la lista.

var character: CharacterData
var generator: ItemGenerator
var _slot_pick: OptionButton
var _affix_pick: OptionButton
var _text: RichTextLabel
var _msg: Label
var _rows: VBoxContainer
var _slots: Array[String] = []


func _init(p_character: CharacterData = null, p_generator: ItemGenerator = null) -> void:
	character = p_character
	generator = p_generator
	title = "Mesa de crafteo de Mario"
	ok_button_text = "Cerrar"
	theme = UiStyle.make_theme()
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	box.custom_minimum_size = Vector2(620, 0)
	add_child(box)
	box.add_child(UiStyle.label("Elige un objeto equipado. Los únicos, de conjunto, placas y RAM no se craftean.", 12, UiStyle.MUTED))
	_slot_pick = OptionButton.new()
	_slot_pick.item_selected.connect(func(_i: int) -> void: _refresh())
	box.add_child(_slot_pick)
	_text = RichTextLabel.new()
	_text.bbcode_enabled = true
	_text.fit_content = true
	_text.custom_minimum_size = Vector2(600, 120)
	box.add_child(_text)
	var lock_row := HBoxContainer.new()
	lock_row.add_child(UiStyle.label("Afijo para el hotfix:", 13))
	_affix_pick = OptionButton.new()
	_affix_pick.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lock_row.add_child(_affix_pick)
	box.add_child(lock_row)
	_rows = VBoxContainer.new()
	_rows.add_theme_constant_override("separation", 4)
	box.add_child(_rows)
	_msg = UiStyle.label("", 13, UiStyle.ACCENT)
	_msg.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(_msg)
	close_requested.connect(queue_free)
	confirmed.connect(queue_free)
	if character:
		_fill_slots()


func _fill_slots() -> void:
	_slot_pick.clear()
	_slots.clear()
	for slot in Inventory.EQUIP_SLOTS:
		var it: Item = character.inventory.equipped(slot)
		if it:
			_slots.append(slot)
			_slot_pick.add_item("%s: %s" % [Inventory.SLOT_NAMES.get(slot, slot), it.display_name()])
	_refresh()


func selected_item() -> Item:
	if _slot_pick.selected < 0 or _slot_pick.selected >= _slots.size():
		return null
	return character.inventory.equipped(_slots[_slot_pick.selected])


func _refresh() -> void:
	var item := selected_item()
	_affix_pick.clear()
	if item == null:
		_text.text = "[i]No llevas nada equipado.[/i]"
	else:
		var lines := PackedStringArray(["[b][color=#%s]%s[/color][/b]  (%s)" % [Rarity.item_color(item.rarity).to_html(false), item.display_name(),
			Rarity.ITEM_INFO[item.rarity]["name"]]])
		for k in item.affixes.size():
			var a: Dictionary = item.affixes[k]
			lines.append("%s%s" % [Item.describe_mod(a), "  [color=#ff8a5a][fijado][/color]" if a.get("locked", false) else ""])
			_affix_pick.add_item(Item.describe_mod(a))
		if not Crafting.craftable(item):
			lines.append("[color=#e0a060]Este objeto no se puede craftear.[/color]")
		_text.text = "\n".join(lines)
	for ch in _rows.get_children():
		_rows.remove_child(ch)
		ch.queue_free()
	for kind in Crafting.KINDS:
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 8)
		var name_label := UiStyle.label("%s (tienes %d)" % [Crafting.NAMES[kind], Crafting.count(character, kind)], 13, Crafting.COLORS[kind])
		name_label.custom_minimum_size.x = 280
		name_label.tooltip_text = Crafting.DESCRIPTIONS[kind]
		name_label.mouse_filter = Control.MOUSE_FILTER_PASS
		row.add_child(name_label)
		row.add_child(UiStyle.button("Usar", _use.bind(kind), 80))
		row.add_child(UiStyle.button("Comprar (%d fichas)" % Crafting.price(kind, character.level), _buy.bind(kind), 170))
		_rows.add_child(row)


func _use(kind: String) -> void:
	var item := selected_item()
	var why := Crafting.apply(character, item, kind, generator, _affix_pick.selected)
	_msg.text = why if why != "" else "Mario: «Listo. %s»" % Crafting.DESCRIPTIONS[kind]
	if why == "":
		Sfx.play("coin")
		character.inventory.changed.emit()
	_fill_slots_keep()


func _buy(kind: String) -> void:
	if Crafting.buy(character, kind):
		_msg.text = "Compraste un %s." % Crafting.NAMES[kind].to_lower()
	else:
		_msg.text = "Mario: «Son %d fichas. Yo también tengo que comer»." % Crafting.price(kind, character.level)
	_refresh()


## Rehace la lista (el nombre del objeto puede cambiar) sin perder la selección.
func _fill_slots_keep() -> void:
	var keep := _slot_pick.selected
	_fill_slots()
	if keep >= 0 and keep < _slot_pick.item_count:
		_slot_pick.select(keep)
		_refresh()
