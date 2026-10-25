class_name LoreLog
extends AcceptDialog
## Registro del lore coleccionable (Pausa → Archivos encontrados): la lista de
## commits, logs y correos encontrados a la izquierda y el elegido a la derecha.

var character: CharacterData
var _list: ItemList
var _text: RichTextLabel
var _notes: Array = []


func _init(p_character: CharacterData = null) -> void:
	character = p_character
	title = "Archivos encontrados"
	ok_button_text = "Cerrar"
	theme = UiStyle.make_theme()
	min_size = Vector2i(820, 480)
	var split := HSplitContainer.new()
	add_child(split)
	_list = ItemList.new()
	_list.custom_minimum_size = Vector2(300, 400)
	_list.item_selected.connect(_show)
	split.add_child(_list)
	_text = RichTextLabel.new()
	_text.bbcode_enabled = true
	_text.custom_minimum_size = Vector2(480, 400)
	_text.add_theme_font_size_override("normal_font_size", 15)
	_text.add_theme_font_size_override("mono_font_size", 14)
	split.add_child(_text)
	close_requested.connect(queue_free)
	confirmed.connect(queue_free)
	refresh()


func refresh() -> void:
	_list.clear()
	_notes = LoreNotes.found(character) if character else []
	for n in _notes:
		var idx := _list.add_item("%s · %s" % [LoreNotes.KIND_NAMES.get(n["kind"], "Archivo"), n["title"]])
		_list.set_item_custom_fg_color(idx, LoreNotes.KIND_COLORS.get(n["kind"], UiStyle.TEXT))
	if _notes.is_empty():
		_text.text = "[i]Todavía no has encontrado nada. Busca commits perdidos, logs y correos por las zonas: brillan en el suelo.[/i]"
	else:
		_list.select(0)
		_show(0)
	title = "Archivos encontrados (%d/%d)" % [_notes.size(), LoreNotes.all().size()]


func _show(index: int) -> void:
	if index < 0 or index >= _notes.size():
		return
	var n: Dictionary = _notes[index]
	var color: Color = LoreNotes.KIND_COLORS.get(n["kind"], UiStyle.ACCENT)
	_text.text = "[color=#%s][b]%s[/b][/color]\n\n[code]%s[/code]" % [color.to_html(false), n["title"], LoreNotes.text_of(n, character)]
