class_name TechDebtPanel
extends AcceptDialog
## Pausa → Deuda técnica: el árbol de fin de juego (TechDebt). La raíz arriba y
## una columna por rama; un clic toma el nodo y otro lo paga (si nada depende de él).

var character: CharacterData
var _box: VBoxContainer


func _init(p_character: CharacterData = null) -> void:
	character = p_character
	title = "Deuda técnica"
	ok_button_text = "Cerrar"
	theme = UiStyle.make_theme()
	_box = VBoxContainer.new()
	_box.add_theme_constant_override("separation", 8)
	_box.custom_minimum_size = Vector2(760, 0)
	add_child(_box)
	close_requested.connect(queue_free)
	confirmed.connect(queue_free)
	_refresh()


func _refresh() -> void:
	for child in _box.get_children():
		_box.remove_child(child)
		child.queue_free()
	if character == null:
		return
	if not TechDebt.unlocked(character):
		var locked := UiStyle.label("Se abre al terminar el Acto IV. Cada nodo da un bono fuerte... y una penalización que te llevas con él.", 14, UiStyle.MUTED)
		locked.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_box.add_child(locked)
		return
	var info := UiStyle.label("Puntos libres: %d de %d  (1 + nivel del atlas + 1 por cada %d oleadas de tu récord, hasta %d)" % [
		TechDebt.free_points(character), TechDebt.total_points(character), TechDebt.WAVES_PER_POINT, TechDebt.MAX_WAVE_POINTS], 14, UiStyle.GOLD)
	info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_box.add_child(info)
	_box.add_child(UiStyle.label("Clic: tomar el nodo. Otro clic: pagar la deuda (solo si nada de lo que tienes depende de él).", 12, UiStyle.MUTED))
	var root_row := HBoxContainer.new()
	root_row.alignment = BoxContainer.ALIGNMENT_CENTER
	root_row.add_child(_node_button(TechDebt.NODES[0]))
	_box.add_child(root_row)
	var cols := HBoxContainer.new()
	cols.add_theme_constant_override("separation", 10)
	_box.add_child(cols)
	for branch in TechDebt.BRANCHES:
		var col := VBoxContainer.new()
		col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		col.add_child(UiStyle.label(TechDebt.BRANCHES[branch], 14, UiStyle.ACCENT))
		for n in TechDebt.NODES:
			if n["branch"] == branch:
				col.add_child(_node_button(n))
		cols.add_child(col)


func _node_button(n: Dictionary) -> Button:
	var id: String = n["id"]
	var have := TechDebt.allocated(character).has(id)
	var b := UiStyle.button(("[x] " if have else "") + String(n["name"]), _toggle.bind(id), 240)
	b.tooltip_text = TechDebt.describe(id)
	b.disabled = not (TechDebt.can_refund(character, id) if have else TechDebt.can_allocate(character, id))
	if have:
		b.add_theme_color_override("font_color", Color("6fd36b"))
		b.add_theme_color_override("font_disabled_color", Color("4f9a4c"))
	return b


func _toggle(id: String) -> void:
	if TechDebt.allocated(character).has(id):
		TechDebt.refund(character, id)
	else:
		TechDebt.allocate(character, id)
	_refresh()
