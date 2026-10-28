extends Control
## Editor de la historia: personajes y sus conversaciones, prólogo, escenas,
## misiones y tutorial, con vista previa, deshacer, búsqueda y validación.
## Guarda en data/*.json (con copia del anterior en user://story_backups/) y
## puede abrir el juego y generar el ejecutable.
##
## Uso: doble click en «Editor de historia.bat», o
##   Godot_v4.7.2-stable_win64.exe --path . res://tools/story_editor.tscn
##
## Lo guardado se aplica al abrir el juego desde el proyecto («Probar el juego»).
## El ejecutable lleva los datos dentro: hay que volver a generarlo.

const FILES := {
	"npcs": "res://data/npcs.json",
	"prologue": "res://data/prologue.json",
	"cutscenes": "res://data/cutscenes.json",
	"quests": "res://data/quests.json",
	"tutorial": "res://data/tutorial.json",
}
const FILE_NAMES := {"npcs": "personajes", "prologue": "prólogo", "cutscenes": "escenas", "quests": "misiones", "tutorial": "tutorial"}
const BACKUP_DIR := "user://story_backups/"
const EXPORT_PATH := "build/PathOverflow.exe"
const UNDO_LIMIT := 60
const STYLES := ["", "boss", "console", "system", "phone"]
const STYLE_NAMES := ["normal", "jefe", "consola", "sistema", "teléfono"]
const EFFECTS := ["glitch", "shake", "blackout", "fade_in", "dino", "lights_flicker", "fans", "rafa_stands", "shock"]
const EFFECT_NAMES := ["Glitch de pantalla", "Temblor", "Fundido a negro", "Volver a ver (fundido)", "El dinosaurio sin conexión",
	"Luces que parpadean", "Ventiladores", "Rafa se levanta", "Descarga eléctrica"]
## Acciones de las respuestas, en lenguaje llano. Campos: los que se piden en el formulario.
const ACTIONS := [
	["", "No hace nada más", []],
	["start_quest", "Empieza una misión", ["quest"]],
	["quest_advance", "Entrega o avanza una misión", ["quest"]],
	["give_item", "Da una placa base o una RAM concreta", ["kind", "id"]],
	["give_random", "Da un objeto al azar", ["rarity"]],
	["give_matching_ram", "Da una RAM que encaje con tus placas", []],
	["refill", "Rellena vida, maná y pociones", []],
	["open_shop", "Abre la tienda", []],
	["recycle_normals", "Recicla los objetos normales", []],
	["set_flag", "Solo apunta una marca", []],
]
const RARITIES := ["normal", "magic", "rare", "unique", "flask", "ram"]
const RARITY_NAMES := ["normal", "mágico", "raro", "único", "una poción", "una RAM"]
## Avisos del prólogo, con el nombre que se ve en el editor.
const PROMPT_NAMES := {"to_hallway": "Calle → entrar a la UAdeO", "to_office": "Pasillo → puerta de Informática", "window": "Pasillo → caja de trámites",
	"tv": "Pasillo → la TV", "talk_rafa": "Oficina → hablar con Rafa", "rack": "Oficina → rack negro (tras contratarse)"}
const PLACE_NAMES := {"calle": "La calle (malecón)", "pasillo": "El pasillo de la UAdeO", "oficina": "La oficina de Informática"}
const HIRE_NAMES := {"title": "Título de la ventana", "question": "Pregunta", "yes": "Botón «Sí»", "no": "Botón «No»", "no_sure": "Al pasar el ratón por «No»",
	"refuse_error": "Error al pulsar «No»", "no_gives_up": "El «No» se rinde"}
const HINT_NAMES := {"controls": "Controles (abajo)", "skip_again": "Al pulsar Esc", "continue": "Al terminar la introducción"}
const PROLOGUE_SCENES := {"prologo_rafa": "Rafa y la libreta de gatitos", "prologo_ventanilla": "La caja de trámites", "prologo_tv": "La TV del pasillo",
	"prologo_incidente": "Se cae el SICE", "prologo_trato": "El trato", "prologo_mario": "Llegan Mario y Aida", "prologo_descarga": "La descarga"}
const HELP := "[b]Cómo se usa[/b]\n\n1. Elige un personaje a la izquierda.\n2. En el centro está su conversación como un guion: cada [color=#d9a441]tarjeta[/color] es algo que dice él; debajo, las [color=#8ab8ff]respuestas[/color] que puede elegir el jugador y a qué tarjeta llevan.\n3. «＋ tema nuevo» en una respuesta crea la tarjeta a la que lleva. «⚙» abre lo avanzado: cuándo aparece una respuesta y qué hace (dar un objeto, empezar una misión...).\n4. A la derecha, la [color=#6fd36b]vista previa[/color]: pulsa respuestas para recorrer la conversación; la tarjeta se resalta.\n5. Ctrl+Z deshace. Ctrl+S guarda. «Buscar» encuentra cualquier frase.\n6. «Probar el juego» abre el juego con lo guardado; «Generar ejecutable» crea build/PathOverflow.exe.\n\nLos textos admiten [b]negrita[/b], [i]cursiva[/i], [color=#e06c6c]color[/color] con BBCode, y {jugador} se cambia por el nombre del personaje."

var data := {}
var dirty := {}
var _history := {}         # archivo -> [instantáneas JSON]
var _snap_due := {}        # archivo -> segundos hasta guardar la instantánea
var _skills_db: SkillDatabase
var _status: Label
var _tabs: TabContainer
var _log: RichTextLabel
var _build_button: Button
var _build_thread: Thread
var _reload_armed := false
var _search_box: LineEdit
var _search_popup: PopupPanel
var _search_list: ItemList

# Personajes.
var _npc_list: ItemList
var _npc_search: LineEdit
var _npc_id := ""
var _node_id := ""
var _npc_scroll: ScrollContainer
var _npc_box: VBoxContainer
var _cards := {}           # nodo -> tarjeta
var _card_titles := {}     # nodo -> Label del título
var _open_advanced := {}   # "nodo#opción" -> true (⚙ abierto)
var _preview_text: RichTextLabel
var _preview_options: VBoxContainer
var _preview_node := ""
var _portrait: Control

# Escenas, misiones, tutorial, prólogo.
var _cut_list: ItemList
var _cut_id := ""
var _cut_box: VBoxContainer
var _quest_list: ItemList
var _quest_id := ""
var _quest_box: VBoxContainer
var _tutorial_box: VBoxContainer
var _prologue_box: VBoxContainer


func _ready() -> void:
	get_window().title = "Path Overflow · Editor de historia"
	get_window().min_size = Vector2i(1280, 760)
	get_tree().auto_accept_quit = false
	theme = UiStyle.make_theme()
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_skills_db = SkillDatabase.load_from_dir()
	load_all()
	_build_ui()
	_refresh_all()
	_set_status("Listo. %d personajes, %d escenas, %d misiones. Pulsa «?» si es tu primera vez." % [npcs().size(), cutscenes().size(), quests().size()])
	if OS.get_cmdline_user_args().has("captura"):
		_self_capture.call_deferred()
	if OS.get_cmdline_user_args().has("autoprueba"):
		_self_test.call_deferred()


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		if is_dirty():
			_ask_save_before_quit()
		else:
			get_tree().quit()


func _process(delta: float) -> void:
	for f in _snap_due.keys():
		_snap_due[f] = float(_snap_due[f]) - delta
		if float(_snap_due[f]) <= 0.0:
			_snap_due.erase(f)
			_push_snapshot(f)


# --- Datos ---

func load_all() -> void:
	for key in FILES:
		var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(FILES[key])) if FileAccess.file_exists(FILES[key]) else null
		data[key] = parsed if parsed is Dictionary else {}
		dirty[key] = false
		_history[key] = [JSON.stringify(data[key], "", false)]
	_snap_due.clear()


func npcs() -> Dictionary:
	return _ensure(data["npcs"], "npcs")


func dialogues() -> Dictionary:
	return _ensure(data["npcs"], "dialogues")


func cutscenes() -> Dictionary:
	return _ensure(data["cutscenes"], "cutscenes")


func quests() -> Dictionary:
	return _ensure(data["quests"], "quests")


static func _ensure(d: Dictionary, key: String) -> Dictionary:
	if not d.get(key) is Dictionary:
		d[key] = {}
	return d[key]


func is_dirty() -> bool:
	for k in dirty:
		if dirty[k]:
			return true
	return false


## Marca el archivo como cambiado; la instantánea para deshacer se toma al
## dejar de escribir (0,6 s), así cada palabra no es un paso de deshacer.
func _touch(file: String) -> void:
	_snap_due[file] = 0.6
	_change_seq += 1
	_last_change[file] = _change_seq
	if not dirty.get(file, false):
		dirty[file] = true
		_set_status("Cambios sin guardar en %s." % FILE_NAMES[file])


func _push_snapshot(file: String) -> void:
	var snap := JSON.stringify(data[file], "", false)
	var hist: Array = _history[file]
	if hist.is_empty() or hist.back() != snap:
		hist.append(snap)
		if hist.size() > UNDO_LIMIT:
			hist.pop_front()


## Deshace el último cambio (del archivo que cambió más recientemente).
func undo() -> bool:
	for f in _snap_due.keys():
		_push_snapshot(f)
	_snap_due.clear()
	var best := ""
	for f in _history:
		if (_history[f] as Array).size() > 1:
			best = f if best == "" or _last_change.get(f, 0) > _last_change.get(best, 0) else best
	if best == "":
		_set_status("No hay nada que deshacer.")
		return false
	var hist: Array = _history[best]
	hist.pop_back()
	data[best] = JSON.parse_string(hist.back())
	dirty[best] = true
	_refresh_all()
	_set_status("Deshecho un cambio en %s." % FILE_NAMES[best])
	return true


var _last_change := {}   # archivo -> número del último cambio
var _change_seq := 0


## Guarda los archivos cambiados (con copia de seguridad del anterior).
func save_all() -> PackedStringArray:
	var saved := PackedStringArray()
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(BACKUP_DIR))
	var stamp := Time.get_datetime_string_from_system().replace(":", "-")
	for key in FILES:
		if not dirty[key]:
			continue
		var path: String = FILES[key]
		if FileAccess.file_exists(path):
			var backup := FileAccess.open(BACKUP_DIR + "%s_%s.json" % [key, stamp], FileAccess.WRITE)
			if backup:
				backup.store_string(FileAccess.get_file_as_string(path))
		var f := FileAccess.open(path, FileAccess.WRITE)
		if f == null:
			_log_line("[color=#e06c6c]No se pudo escribir %s[/color]" % path)
			continue
		f.store_string(to_json(data[key]) + "\n")
		f.close()
		dirty[key] = false
		saved.append(FILE_NAMES[key])
	return saved


## JSON legible: dos espacios, enteros sin «.0» y listas cortas en una línea.
static func to_json(v: Variant, indent := "") -> String:
	var inner := indent + "  "
	match typeof(v):
		TYPE_DICTIONARY:
			var d: Dictionary = v
			if d.is_empty():
				return "{}"
			var parts := PackedStringArray()
			for k in d:
				parts.append(inner + JSON.stringify(str(k)) + ": " + to_json(d[k], inner))
			return "{\n" + ",\n".join(parts) + "\n" + indent + "}"
		TYPE_ARRAY:
			var a: Array = v
			if a.is_empty():
				return "[]"
			var simple := a.all(func(x: Variant) -> bool: return not (x is Dictionary or x is Array))
			if simple:
				var flat := PackedStringArray()
				for x in a:
					flat.append(to_json(x))
				var line := "[" + ", ".join(flat) + "]"
				if line.length() <= 110:
					return line
			var rows := PackedStringArray()
			for x in a:
				rows.append(inner + to_json(x, inner))
			return "[\n" + ",\n".join(rows) + "\n" + indent + "]"
		TYPE_FLOAT:
			var f: float = v
			if is_equal_approx(f, roundf(f)) and absf(f) < 1.0e15:
				return str(int(roundf(f)))
			return JSON.stringify(f)
	return JSON.stringify(v)


## JSON en una línea, con las claves en su orden y enteros sin «.0» (campos de texto).
static func compact_json(v: Variant) -> String:
	var re := RegEx.create_from_string("(?<=[\\d])\\.0(?=[,\\]}]|$)")
	return re.sub(JSON.stringify(v, "", false), "", true)


## Problemas de referencias: tarjetas, personajes, diálogos y misiones que no existen.
func validate() -> PackedStringArray:
	var out := PackedStringArray()
	for nid in npcs():
		var did := String(npcs()[nid].get("dialogue", ""))
		if did != "" and not dialogues().has(did):
			out.append("%s usa la conversación «%s», que no existe." % [_npc_name(nid), did])
	for did in dialogues():
		var dl: Dictionary = dialogues()[did]
		var nodes: Dictionary = dl.get("nodes", {})
		var who := _owner_name(did)
		if not nodes.has(String(dl.get("start", ""))):
			out.append("%s: el saludo inicial («%s») no existe." % [who, dl.get("start", "")])
		for node_id in nodes:
			var node: Dictionary = nodes[node_id]
			var nxt := String(node.get("next", ""))
			if nxt != "" and not nodes.has(nxt):
				out.append("%s, tarjeta «%s»: «Continuar» lleva a «%s», que no existe." % [who, node_id, nxt])
			if String(node.get("text", "")).strip_edges() == "":
				out.append("%s, tarjeta «%s»: no tiene texto." % [who, node_id])
			for o in node.get("options", []):
				var target := String(o.get("next", ""))
				if target != "" and not nodes.has(target):
					out.append("%s, tarjeta «%s»: la respuesta «%s» lleva a «%s», que no existe." % [who, node_id, o.get("text", ""), target])
				if String(o.get("text", "")).strip_edges() == "":
					out.append("%s, tarjeta «%s»: hay una respuesta sin texto." % [who, node_id])
	for cid in cutscenes():
		for s in cutscenes()[cid].get("steps", []):
			var sp := String(s.get("speaker", ""))
			if sp != "" and sp != "player" and not npcs().has(sp):
				out.append("Escena «%s»: habla «%s», que no es un personaje." % [cid, sp])
	for qid in quests():
		var q: Dictionary = quests()[qid]
		if q.has("giver") and not npcs().has(String(q["giver"])):
			out.append("Misión «%s»: la da «%s», que no es un personaje." % [q.get("name", qid), q["giver"]])
		if q.has("starts_after") and not quests().has(String(q["starts_after"])):
			out.append("Misión «%s»: empieza tras «%s», que no existe." % [q.get("name", qid), q["starts_after"]])
		for st in q.get("steps", []):
			if String(st.get("type", "")) in ["talk", "turn_in"] and not npcs().has(String(st.get("npc", ""))):
				out.append("Misión «%s»: el paso «%s» habla con «%s», que no es un personaje." % [q.get("name", qid), st.get("text", ""), st.get("npc", "")])
	if (data["prologue"].get("intro", []) as Array).is_empty():
		out.append("Prólogo: la introducción está vacía.")
	return out


func _npc_name(nid: String) -> String:
	return String(npcs().get(nid, {}).get("name", nid))


func _owner_name(did: String) -> String:
	for nid in npcs():
		if String(npcs()[nid].get("dialogue", "")) == did:
			return _npc_name(nid)
	return "Conversación «%s»" % did


# --- Interfaz general ---

func _build_ui() -> void:
	var bg := ColorRect.new()
	bg.color = UiStyle.BG
	add_child(bg)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var margin := MarginContainer.new()
	add_child(margin)
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 12)
	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 8)
	margin.add_child(root)
	var bar := HBoxContainer.new()
	bar.add_theme_constant_override("separation", 8)
	root.add_child(bar)
	bar.add_child(UiStyle.label("Editor de historia", 24, UiStyle.ACCENT))
	_search_box = _line("", func(_t: String) -> void: pass, "Buscar una frase en toda la historia...")
	_search_box.custom_minimum_size.x = 300
	_search_box.text_submitted.connect(func(t: String) -> void: _global_search(t))
	bar.add_child(_search_box)
	bar.add_child(_small_button("Buscar", "Busca en personajes, prólogo, escenas, misiones y tutorial", func() -> void: _global_search(_search_box.text)))
	_status = UiStyle.label("", 13, UiStyle.MUTED)
	_status.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_status.clip_text = true
	bar.add_child(_status)
	bar.add_child(_small_button("↶ Deshacer", "Deshace el último cambio (Ctrl+Z)", func() -> void: undo()))
	bar.add_child(UiStyle.button("Guardar", _on_save, 110))
	bar.add_child(UiStyle.button("Revisar", _on_validate, 100))
	bar.add_child(UiStyle.button("Probar el juego", _on_play, 140))
	_build_button = UiStyle.button("Generar ejecutable", _on_build, 170)
	bar.add_child(_build_button)
	bar.add_child(UiStyle.button("?", _show_help, 40))
	_tabs = TabContainer.new()
	_tabs.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(_tabs)
	_tabs.add_child(_build_npc_tab())
	_tabs.add_child(_build_prologue_tab())
	_tabs.add_child(_build_cutscene_tab())
	_tabs.add_child(_build_quest_tab())
	var tut := ScrollContainer.new()
	tut.name = "Tutorial"
	tut.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_tutorial_box = VBoxContainer.new()
	_tutorial_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_tutorial_box.add_theme_constant_override("separation", 6)
	tut.add_child(_tutorial_box)
	_tabs.add_child(tut)
	_log = RichTextLabel.new()
	_log.name = "Registro"
	_log.bbcode_enabled = true
	_log.scroll_following = true
	_log.selection_enabled = true
	_tabs.add_child(_log)
	_search_popup = PopupPanel.new()
	_search_popup.add_theme_stylebox_override("panel", UiStyle.window_style())
	_search_list = ItemList.new()
	_search_list.custom_minimum_size = Vector2(760, 380)
	_search_list.item_activated.connect(_jump_to_result)
	_search_list.item_clicked.connect(func(i: int, _p: Vector2, _b: int) -> void: _jump_to_result(i))
	_search_popup.add_child(_search_list)
	add_child(_search_popup)
	_log_line("Los cambios se guardan en data/*.json. Antes de escribir se copia el archivo anterior en %s." % ProjectSettings.globalize_path(BACKUP_DIR))


func _refresh_all() -> void:
	_refresh_npc_list()
	_refresh_cut_list()
	_refresh_quest_list()
	_build_tutorial()
	_build_prologue()


func _unhandled_key_input(event: InputEvent) -> void:
	var k := event as InputEventKey
	if k == null or not k.pressed or not k.ctrl_pressed:
		return
	if k.keycode == KEY_S:
		_on_save()
		get_viewport().set_input_as_handled()
	elif k.keycode == KEY_Z:
		undo()
		get_viewport().set_input_as_handled()
	elif k.keycode == KEY_F:
		_search_box.grab_focus()
		get_viewport().set_input_as_handled()


func _set_status(text: String) -> void:
	if _status:
		_status.text = text


func _log_line(text: String) -> void:
	if _log:
		_log.append_text("[color=#8a8293]%s[/color]  %s\n" % [Time.get_time_string_from_system(), text])


func _show_help() -> void:
	var dlg := AcceptDialog.new()
	dlg.title = "Guía rápida"
	var t := RichTextLabel.new()
	t.bbcode_enabled = true
	t.fit_content = true
	t.custom_minimum_size = Vector2(620, 0)
	t.text = HELP
	dlg.add_child(t)
	add_child(dlg)
	dlg.popup_centered(Vector2i(680, 420))


func _on_save() -> void:
	var problems := validate()
	var saved := save_all()
	if saved.is_empty():
		_set_status("No hay cambios que guardar.")
		return
	_set_status("Guardado: %s.%s" % [", ".join(saved), "  Ojo: %d avisos (pulsa Revisar)." % problems.size() if not problems.is_empty() else ""])
	_log_line("[color=#6fd36b]Guardado[/color]: " + ", ".join(saved))
	for p in problems:
		_log_line("[color=#e0b050]Aviso[/color]: " + p)


func _on_validate() -> void:
	var problems := validate()
	if problems.is_empty():
		_set_status("Todo en orden: no hay respuestas que lleven a ninguna parte.")
		_log_line("[color=#6fd36b]Revisión correcta.[/color]")
		return
	_set_status("%d avisos (ver Registro)." % problems.size())
	for p in problems:
		_log_line("[color=#e0b050]Aviso[/color]: " + p)
	_tabs.current_tab = _tabs.get_tab_count() - 1


func _on_play() -> void:
	if is_dirty():
		_on_save()
	var pid := OS.create_process(OS.get_executable_path(), ["--path", ProjectSettings.globalize_path("res://")])
	_log_line("Juego abierto desde el proyecto (pid %d): usa lo recién guardado." % pid)


## Exportación en un hilo (tarda): guarda antes, y al acabar cuenta el resultado.
func _on_build() -> void:
	if _build_thread and _build_thread.is_alive():
		return
	if is_dirty():
		_on_save()
	var problems := validate()
	if not problems.is_empty():
		_log_line("[color=#e0b050]Se genera igualmente, pero hay %d avisos.[/color]" % problems.size())
	_build_button.disabled = true
	_build_button.text = "Generando..."
	_set_status("Generando build/PathOverflow.exe (un minuto o dos)...")
	_log_line("Exportando con %s" % OS.get_executable_path())
	_build_thread = Thread.new()
	_build_thread.start(_export_worker)


func _export_worker() -> void:
	var output: Array = []
	var args := ["--headless", "--path", ProjectSettings.globalize_path("res://"), "--export-release", "Windows", EXPORT_PATH]
	var code := OS.execute(OS.get_executable_path(), args, output, true)
	_export_done.call_deferred(code, "\n".join(PackedStringArray(output)))


func _export_done(code: int, output: String) -> void:
	_build_thread.wait_to_finish()
	_build_button.disabled = false
	_build_button.text = "Generar ejecutable"
	var exe := ProjectSettings.globalize_path("res://") + EXPORT_PATH
	var errors := PackedStringArray()
	for line in output.split("\n"):
		if line.contains("ERROR"):
			errors.append(line.strip_edges())
	if code == 0 and FileAccess.file_exists(exe):
		var mb := FileAccess.get_file_as_bytes(exe).size() / 1048576.0
		_set_status("Ejecutable generado: %s (%.0f MB)." % [EXPORT_PATH, mb])
		_log_line("[color=#6fd36b]Build correcta[/color]: %s (%.0f MB)" % [exe, mb])
	else:
		_set_status("La exportación falló (código %d): mira el Registro." % code)
		_log_line("[color=#e06c6c]Build fallida (código %d)[/color]" % code)
	for e in errors.slice(0, 12):
		_log_line("[color=#e06c6c]%s[/color]" % e)


func _ask_save_before_quit() -> void:
	var dlg := ConfirmationDialog.new()
	dlg.title = "Cambios sin guardar"
	dlg.dialog_text = "Hay cambios sin guardar. ¿Guardarlos antes de salir?"
	dlg.ok_button_text = "Guardar y salir"
	dlg.add_button("Salir sin guardar", true, "discard")
	dlg.confirmed.connect(func() -> void:
		save_all()
		get_tree().quit())
	dlg.custom_action.connect(func(_a: StringName) -> void: get_tree().quit())
	add_child(dlg)
	dlg.popup_centered()


# --- Búsqueda en toda la historia ---

## Resultados: [{text, tab, npc?, node?, cut?, quest?}].
func search(query: String) -> Array[Dictionary]:
	var q := query.strip_edges().to_lower()
	var out: Array[Dictionary] = []
	if q == "":
		return out
	for nid in npcs():
		var did := String(npcs()[nid].get("dialogue", ""))
		var nodes: Dictionary = dialogues().get(did, {}).get("nodes", {})
		for node_id in nodes:
			var node: Dictionary = nodes[node_id]
			var hay := as_text(node.get("text", "")) + " " + as_text(node.get("again", ""))
			for o in node.get("options", []):
				hay += " " + String(o.get("text", ""))
			if hay.to_lower().contains(q) or _npc_name(nid).to_lower().contains(q):
				out.append({"text": "%s · %s: %s" % [_npc_name(nid), _node_title(dialogues()[did], node_id), _snip(String(node.get("text", "")), q)],
					"tab": 0, "npc": nid, "node": node_id})
	for section in ["intro", "console"]:
		for line in data["prologue"].get(section, []):
			if String(line).to_lower().contains(q):
				out.append({"text": "Prólogo · %s: %s" % ["introducción" if section == "intro" else "consola", _snip(String(line), q)], "tab": 1})
	for cid in cutscenes():
		for s in cutscenes()[cid].get("steps", []):
			if String(s.get("text", "")).to_lower().contains(q):
				out.append({"text": "Escena %s · %s: %s" % [cid, s.get("speaker", s.get("name", "")), _snip(String(s["text"]), q)],
					"tab": 1 if String(cid).begins_with("prologo_") else 2, "cut": cid})
	for qid in quests():
		var qd: Dictionary = quests()[qid]
		var hay := String(qd.get("name", "")) + " " + String(qd.get("description", ""))
		for st in qd.get("steps", []):
			hay += " " + String(st.get("text", ""))
		if hay.to_lower().contains(q):
			out.append({"text": "Misión · %s" % qd.get("name", qid), "tab": 3, "quest": qid})
	for st in data["tutorial"].get("steps", []):
		if String(st.get("text", "")).to_lower().contains(q):
			out.append({"text": "Tutorial · %s: %s" % [st.get("id", ""), _snip(String(st["text"]), q)], "tab": 4})
	return out


static func _snip(text: String, q: String) -> String:
	var flat := text.replace("\n", " ")
	var at := flat.to_lower().find(q)
	var from := maxi(0, at - 30)
	return ("..." if from > 0 else "") + flat.substr(from, 110)


var _results: Array[Dictionary] = []


func _global_search(query: String) -> void:
	_results = search(query)
	_search_list.clear()
	for r in _results:
		_search_list.add_item(r["text"])
	if _results.is_empty():
		_set_status("No se encontró «%s»." % query)
		return
	_set_status("%d resultados para «%s»." % [_results.size(), query])
	_search_popup.popup(Rect2i(Vector2i(int(_search_box.global_position.x), int(_search_box.global_position.y + 40)), Vector2i(780, 400)))


func _jump_to_result(i: int) -> void:
	var r: Dictionary = _results[i]
	_search_popup.hide()
	_tabs.current_tab = int(r["tab"])
	if r.has("npc"):
		_npc_id = String(r["npc"])
		_node_id = String(r["node"])
		_preview_node = _node_id
		_refresh_npc_list()
		_scroll_to_card.call_deferred(_node_id)
	elif r.has("cut") and int(r["tab"]) == 2:
		_cut_id = String(r["cut"])
		_refresh_cut_list()
	elif r.has("quest"):
		_quest_id = String(r["quest"])
		_refresh_quest_list()


# --- Ayudantes de controles ---

func _row(parent: Control, label_text: String, control: Control, label_width := 160.0) -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	var l := UiStyle.label(label_text, 13, UiStyle.MUTED)
	l.custom_minimum_size.x = label_width
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	row.add_child(l)
	control.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(control)
	parent.add_child(row)
	return row


func _line(text: String, on_change: Callable, placeholder := "") -> LineEdit:
	var e := LineEdit.new()
	e.text = text
	e.placeholder_text = placeholder
	e.text_changed.connect(on_change)
	return e


func _area(text: String, on_change: Callable, height := 70.0) -> TextEdit:
	var t := TextEdit.new()
	t.text = text
	t.custom_minimum_size = Vector2(200, height)
	t.wrap_mode = TextEdit.LINE_WRAPPING_BOUNDARY
	t.scroll_fit_content_height = true
	t.text_changed.connect(func() -> void: on_change.call(t.text))
	return t


func _option(items: Array, selected: String, on_change: Callable, labels: Array = []) -> OptionButton:
	var o := OptionButton.new()
	var values := items.duplicate()
	for k in values.size():
		o.add_item(String(labels[k]) if k < labels.size() else String(values[k]))
		if String(values[k]) == selected:
			o.select(k)
	if o.selected == -1 and selected != "":
		o.add_item(selected + " (?)")
		values.append(selected)
		o.select(values.size() - 1)
	o.item_selected.connect(func(i: int) -> void: on_change.call(String(values[i])))
	return o


func _spin(value: float, lo: float, hi: float, step: float, on_change: Callable) -> SpinBox:
	var s := SpinBox.new()
	s.min_value = lo
	s.max_value = hi
	s.step = step
	s.value = value
	s.value_changed.connect(on_change)
	return s


## Campo de texto con JSON (datos de pasos de misión y recompensas): rojo si no es válido.
func _json_line(value: Variant, on_change: Callable, placeholder := "") -> LineEdit:
	var e := LineEdit.new()
	e.text = compact_json(value) if value != null else ""
	e.placeholder_text = placeholder
	e.text_changed.connect(func(t: String) -> void:
		if t.strip_edges() == "":
			e.remove_theme_color_override("font_color")
			on_change.call(null)
			return
		var parsed: Variant = JSON.parse_string(t)
		if parsed == null:
			e.add_theme_color_override("font_color", UiStyle.DANGER)
			return
		e.remove_theme_color_override("font_color")
		on_change.call(parsed))
	return e


func _small_button(text: String, tip: String, cb: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.tooltip_text = tip
	b.focus_mode = Control.FOCUS_NONE
	b.pressed.connect(cb)
	return b


## Sección plegable: un botón con ▸/▾ que muestra u oculta su contenido.
func _foldable(parent: Control, title: String, open := false) -> VBoxContainer:
	var head := Button.new()
	head.flat = true
	head.alignment = HORIZONTAL_ALIGNMENT_LEFT
	head.focus_mode = Control.FOCUS_NONE
	head.add_theme_color_override("font_color", UiStyle.ACCENT)
	parent.add_child(head)
	var body := VBoxContainer.new()
	body.add_theme_constant_override("separation", 6)
	body.visible = open
	parent.add_child(body)
	var refresh := func() -> void: head.text = ("▾ " if body.visible else "▸ ") + title
	refresh.call()
	head.pressed.connect(func() -> void:
		body.visible = not body.visible
		refresh.call())
	return body


static func _clear(box: Node) -> void:
	for ch in box.get_children():
		box.remove_child(ch)
		ch.queue_free()


static func _new_id(base: String, taken: Dictionary) -> String:
	var id := base
	var k := 2
	while taken.has(id):
		id = "%s_%d" % [base, k]
		k += 1
	return id


static func _lines(t: String) -> Array:
	var out: Array = []
	for l in t.split("\n"):
		if l.strip_edges() != "":
			out.append(l.strip_edges())
	return out


## Un texto que puede ser una frase o una lista de frases (una sale al azar): una por línea.
static func as_text(v: Variant) -> String:
	if v is Array:
		return "\n".join(PackedStringArray((v as Array).map(func(x: Variant) -> String: return str(x))))
	return "" if v == null else str(v)


static func _short(text: String, n := 42) -> String:
	var flat := text.replace("\n", " ").strip_edges()
	return flat if flat.length() <= n else flat.left(n - 1) + "…"


# --- Personajes y conversaciones ---

func _build_npc_tab() -> Control:
	var split := HSplitContainer.new()
	split.name = "Personajes"
	var left := VBoxContainer.new()
	left.custom_minimum_size.x = 230
	split.add_child(left)
	_npc_search = _line("", func(_t: String) -> void: _refresh_npc_list(), "Filtrar personajes...")
	left.add_child(_npc_search)
	_npc_list = ItemList.new()
	_npc_list.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_npc_list.item_selected.connect(func(i: int) -> void:
		_npc_id = String(_npc_list.get_item_metadata(i))
		_node_id = ""
		_preview_node = ""
		_show_npc())
	left.add_child(_npc_list)
	var nb := HBoxContainer.new()
	left.add_child(nb)
	nb.add_child(_small_button("＋ Personaje", "Crea un personaje nuevo con una conversación de ejemplo", _add_npc))
	nb.add_child(_small_button("Borrar", "Borra el personaje (su conversación se queda en el archivo)", _delete_npc))
	var right := HSplitContainer.new()
	split.add_child(right)
	_npc_scroll = ScrollContainer.new()
	_npc_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_npc_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_npc_scroll.custom_minimum_size.x = 600
	right.add_child(_npc_scroll)
	_npc_box = VBoxContainer.new()
	_npc_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_npc_box.add_theme_constant_override("separation", 8)
	_npc_scroll.add_child(_npc_box)
	var prev := PanelContainer.new()
	prev.add_theme_stylebox_override("panel", UiStyle.inset_style())
	prev.custom_minimum_size.x = 360
	right.add_child(prev)
	var pv := VBoxContainer.new()
	pv.add_theme_constant_override("separation", 8)
	prev.add_child(pv)
	pv.add_child(UiStyle.section_header("Vista previa: así se ve en el juego"))
	_portrait = Control.new()
	_portrait.custom_minimum_size = Vector2(120, 130)
	_portrait.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_portrait.draw.connect(_draw_portrait)
	pv.add_child(_portrait)
	_preview_text = RichTextLabel.new()
	_preview_text.bbcode_enabled = true
	_preview_text.fit_content = true
	_preview_text.custom_minimum_size = Vector2(320, 60)
	pv.add_child(_preview_text)
	_preview_options = VBoxContainer.new()
	pv.add_child(_preview_options)
	pv.add_child(_small_button("↺ Empezar de nuevo", "Vuelve al saludo inicial", func() -> void:
		_preview_node = ""
		_show_preview()))
	return split


func _refresh_npc_list() -> void:
	if _npc_list == null:
		return
	_npc_list.clear()
	var q := _npc_search.text.to_lower() if _npc_search else ""
	for nid in npcs():
		var name := _npc_name(nid)
		if q != "" and not (name.to_lower().contains(q) or String(nid).contains(q)):
			continue
		var i := _npc_list.add_item(name)
		_npc_list.set_item_metadata(i, nid)
		_npc_list.set_item_tooltip(i, "id: %s" % nid)
		_npc_list.set_item_custom_fg_color(i, Color(npcs()[nid].get("color", "e8d9b0")))
		if nid == _npc_id:
			_npc_list.select(i)
	if (_npc_id == "" or not npcs().has(_npc_id)) and _npc_list.item_count > 0:
		_npc_list.select(0)
		_npc_id = String(_npc_list.get_item_metadata(0))
	_show_npc()


func _add_npc() -> void:
	var nid := _new_id("nuevo_personaje", npcs())
	var did := _new_id(nid, dialogues())
	npcs()[nid] = {"name": "Nuevo personaje", "dialogue": did, "appearance": CharacterAppearance.default(),
		"voice": {"pitch": 1.0, "rate": 1.0, "gender": "male"}, "color": "d9a441"}
	dialogues()[did] = {"start": "hola", "greeting_again": [], "menu": [],
		"nodes": {"hola": {"text": "Hola. Todavía no tengo guion.", "options": [{"text": "Adiós.", "next": ""}]}}}
	_npc_id = nid
	_node_id = "hola"
	_touch("npcs")
	_refresh_npc_list()
	_log_line("Personaje nuevo «%s». Para que aparezca en una zona hay que colocarlo en data/act*.json → npcs." % nid)


func _delete_npc() -> void:
	if _npc_id == "" or not npcs().has(_npc_id):
		return
	_log_line("Personaje «%s» borrado (Ctrl+Z para recuperarlo)." % _npc_name(_npc_id))
	npcs().erase(_npc_id)
	_npc_id = ""
	_touch("npcs")
	_refresh_npc_list()


func _dialogue() -> Dictionary:
	if _npc_id == "" or not npcs().has(_npc_id):
		return {}
	return dialogues().get(String(npcs()[_npc_id].get("dialogue", "")), {})


## Título de una tarjeta en lenguaje llano: el saludo, o la respuesta que lleva a ella.
func _node_title(dl: Dictionary, node_id: String) -> String:
	if node_id == String(dl.get("start", "")):
		return "Saludo inicial"
	var nodes: Dictionary = dl.get("nodes", {})
	for k in nodes:
		for o in nodes[k].get("options", []):
			if String(o.get("next", "")) == node_id and String(o.get("text", "")).strip_edges() != "":
				return "«%s»" % _short(String(o["text"]), 50)
	for k in nodes:
		if String(nodes[k].get("next", "")) == node_id:
			return "(sigue de %s)" % _node_title(dl, k) if k != node_id else "Tema suelto"
	return "Tema suelto (nadie lleva aquí)"


## Tarjetas en el orden de la conversación (desde el saludo); las sueltas, al final.
func flow_order(dl: Dictionary) -> Array:
	var nodes: Dictionary = dl.get("nodes", {})
	var order: Array = []
	var queue: Array = [String(dl.get("start", ""))]
	while not queue.is_empty():
		var n: String = queue.pop_front()
		if n == "" or not nodes.has(n) or order.has(n):
			continue
		order.append(n)
		if String(nodes[n].get("next", "")) != "":
			queue.append(String(nodes[n]["next"]))
		for o in nodes[n].get("options", []):
			queue.append(String(o.get("next", "")))
	for n in nodes:
		if not order.has(n):
			order.append(n)
	return order


func _show_npc() -> void:
	if _npc_box == null:
		return
	var keep_scroll := _npc_scroll.scroll_vertical
	_clear(_npc_box)
	_cards.clear()
	_card_titles.clear()
	if _npc_id == "" or not npcs().has(_npc_id):
		_npc_box.add_child(UiStyle.label("Elige un personaje a la izquierda.", 14, UiStyle.MUTED))
		_show_preview()
		return
	var npc: Dictionary = npcs()[_npc_id]
	# Cabecera: nombre y color, lo más usado; voz y conversación, plegadas.
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 8)
	_npc_box.add_child(head)
	var name_edit := _line(String(npc.get("name", "")), func(t: String) -> void:
		npc["name"] = t
		_touch("npcs")
		_portrait.queue_redraw()
		_show_preview(), "Nombre del personaje")
	name_edit.add_theme_font_size_override("font_size", 20)
	name_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(name_edit)
	var color := ColorPickerButton.new()
	color.color = Color(npc.get("color", "d9a441"))
	color.custom_minimum_size = Vector2(60, 34)
	color.tooltip_text = "Color del nombre en los diálogos"
	color.color_changed.connect(func(c: Color) -> void:
		npc["color"] = c.to_html(false)
		_touch("npcs")
		_show_preview())
	head.add_child(color)
	var more := _foldable(_npc_box, "Voz y conversación que usa")
	var voice: Dictionary = _ensure(npc, "voice")
	var vrow := HBoxContainer.new()
	vrow.add_theme_constant_override("separation", 6)
	vrow.add_child(UiStyle.label("tono", 12, UiStyle.MUTED))
	vrow.add_child(_spin(float(voice.get("pitch", 1.0)), 0.5, 2.0, 0.05, func(v: float) -> void:
		voice["pitch"] = v
		_touch("npcs")))
	vrow.add_child(UiStyle.label("velocidad", 12, UiStyle.MUTED))
	vrow.add_child(_spin(float(voice.get("rate", 1.0)), 0.5, 2.0, 0.05, func(v: float) -> void:
		voice["rate"] = v
		_touch("npcs")))
	vrow.add_child(_option(["male", "female"], String(voice.get("gender", "male")), func(g: String) -> void:
		voice["gender"] = g
		_touch("npcs"), ["voz masculina", "voz femenina"]))
	_row(more, "Voz del narrador", vrow)
	var dlg_ids := dialogues().keys()
	var dlg_labels: Array = dlg_ids.map(func(d: String) -> String: return "%s (%s)" % [_owner_name(d), d])
	_row(more, "Conversación", _option(dlg_ids, String(npc.get("dialogue", "")), func(d: String) -> void:
		npc["dialogue"] = d
		_node_id = ""
		_touch("npcs")
		_show_npc.call_deferred(), dlg_labels))
	var dl := _dialogue()
	if dl.is_empty():
		_npc_box.add_child(UiStyle.label("Este personaje no tiene conversación.", 13, UiStyle.DANGER))
		_show_preview()
		return
	var nodes: Dictionary = _ensure(dl, "nodes")
	var greet := _foldable(_npc_box, "Saludos al volver y frases cortas del menú")
	_row(greet, "Al volver a hablarle\n(una por línea; sale una al azar)", _area("\n".join(PackedStringArray(dl.get("greeting_again", []))), func(t: String) -> void:
		dl["greeting_again"] = _lines(t)
		_touch("npcs"), 60.0))
	_row(greet, "Al volver al menú\n(una por línea)", _area("\n".join(PackedStringArray(dl.get("menu", []))), func(t: String) -> void:
		dl["menu"] = _lines(t)
		_touch("npcs"), 60.0))
	var guide := UiStyle.label("Cada tarjeta es algo que dice %s; debajo, lo que puede responder el jugador y adónde lleva cada respuesta." % _npc_name(_npc_id), 13, UiStyle.MUTED)
	guide.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_npc_box.add_child(guide)
	if _node_id == "" or not nodes.has(_node_id):
		_node_id = String(dl.get("start", ""))
	for node_id in flow_order(dl):
		var card := _node_card(dl, nodes, String(node_id))
		_cards[node_id] = card
		_npc_box.add_child(card)
	_npc_box.add_child(_small_button("＋ Tarjeta suelta", "Una tarjeta nueva sin conectar (luego enlázala desde una respuesta)", func() -> void:
		var nid := _new_id("tema", nodes)
		nodes[nid] = {"text": "", "options": [{"text": "Volver.", "next": String(dl.get("start", ""))}]}
		_node_id = nid
		_touch("npcs")
		_show_npc()
		_scroll_to_card.call_deferred(nid)))
	_show_preview()
	_portrait.queue_redraw()
	_restore_scroll.call_deferred(keep_scroll)


func _restore_scroll(v: int) -> void:
	_npc_scroll.scroll_vertical = v


func _scroll_to_card(node_id: String) -> void:
	if _cards.has(node_id) and is_instance_valid(_cards[node_id]):
		_npc_scroll.ensure_control_visible(_cards[node_id])
	_highlight_card(node_id)


func _highlight_card(node_id: String) -> void:
	_node_id = node_id
	for k in _cards:
		if is_instance_valid(_cards[k]):
			(_cards[k] as PanelContainer).add_theme_stylebox_override("panel", UiStyle.inset_style(UiStyle.ACCENT if k == node_id else Color("2e2836")))


func _refresh_titles() -> void:
	var dl := _dialogue()
	for k in _card_titles:
		if is_instance_valid(_card_titles[k]):
			_card_titles[k].text = _node_title(dl, k)


## Destinos posibles de una respuesta, con nombres legibles.
func _targets(dl: Dictionary) -> Array:
	var values: Array = [""]
	var labels: Array = ["✖ Cerrar la conversación"]
	for k in flow_order(dl):
		values.append(k)
		labels.append("→ " + _node_title(dl, k))
	return [values, labels]


## Una tarjeta: lo que dice el personaje y las respuestas del jugador.
func _node_card(dl: Dictionary, nodes: Dictionary, node_id: String) -> PanelContainer:
	var node: Dictionary = nodes[node_id]
	var card := PanelContainer.new()
	card.add_theme_stylebox_override("panel", UiStyle.inset_style(UiStyle.ACCENT if node_id == _node_id else Color("2e2836")))
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 5)
	card.add_child(box)
	var top := HBoxContainer.new()
	box.add_child(top)
	var title := UiStyle.label(_node_title(dl, node_id), 15, UiStyle.ACCENT)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(title)
	_card_titles[node_id] = title
	var id_label := UiStyle.label(node_id, 11, UiStyle.MUTED)
	id_label.tooltip_text = "Nombre interno de la tarjeta (no se ve en el juego)"
	top.add_child(id_label)
	top.add_child(_small_button("👁", "Verla en la vista previa", func() -> void:
		_preview_node = node_id
		_highlight_card(node_id)
		_show_preview()))
	if node_id != String(dl.get("start", "")):
		top.add_child(_small_button("🗑", "Borrar esta tarjeta (Ctrl+Z la recupera)", func() -> void:
			nodes.erase(node_id)
			for k in nodes:
				for o in nodes[k].get("options", []):
					if String(o.get("next", "")) == node_id:
						o["next"] = ""
				if String(nodes[k].get("next", "")) == node_id:
					nodes[k].erase("next")
			_touch("npcs")
			_show_npc()))
	var says := UiStyle.label("%s dice:" % _npc_name(_npc_id), 12, UiStyle.MUTED)
	box.add_child(says)
	var text := _area(String(node.get("text", "")), func(t: String) -> void:
		node["text"] = t
		_touch("npcs")
		if _preview_node == node_id:
			_show_preview(), 64.0)
	text.focus_entered.connect(func() -> void:
		if _preview_node != node_id:
			_preview_node = node_id
			_highlight_card(node_id)
			_show_preview())
	box.add_child(text)
	var opts: Array = node.get("options", [])
	node["options"] = opts
	if not opts.is_empty():
		box.add_child(UiStyle.label("El jugador puede responder:", 12, UiStyle.MUTED))
	var tg := _targets(dl)
	for k in opts.size():
		box.add_child(_answer_row(dl, nodes, node_id, opts, k, tg))
	var add := HBoxContainer.new()
	add.add_theme_constant_override("separation", 6)
	box.add_child(add)
	add.add_child(_small_button("＋ Respuesta", "Una respuesta más (cierra la conversación hasta que elijas adónde lleva)", func() -> void:
		opts.append({"text": "", "next": ""})
		_touch("npcs")
		_show_npc()))
	add.add_child(_small_button("＋ Respuesta con tema nuevo", "Una respuesta que lleva a una tarjeta nueva", func() -> void:
		var nid := _new_id("tema", nodes)
		nodes[nid] = {"text": "", "options": [{"text": "Volver.", "next": String(dl.get("start", ""))}]}
		opts.append({"text": "", "next": nid})
		_node_id = nid
		_touch("npcs")
		_show_npc()
		_scroll_to_card.call_deferred(nid)))
	var extra := _foldable(box, "Más: texto al releer y botón «Continuar»", node.has("again") or node.has("next"))
	var again_was_list: bool = node.get("again") is Array
	_row(extra, "Si ya se leyó, dice\n(opcional; varias líneas = una al azar)", _area(as_text(node.get("again", "")), func(t: String) -> void:
		var lines := _lines(t)
		if lines.is_empty():
			node.erase("again")
		elif lines.size() > 1 or again_was_list:
			node["again"] = lines
		else:
			node["again"] = t.strip_edges()
		_touch("npcs"), 44.0))
	var cont_values: Array = [""] + (tg[0] as Array).slice(1)
	var cont_labels: Array = ["(sin «Continuar»)"] + (tg[1] as Array).slice(1)
	_row(extra, "Botón «Continuar» lleva a\n(si no hay respuestas)", _option(cont_values, String(node.get("next", "")), func(n: String) -> void:
		if n == "":
			node.erase("next")
		else:
			node["next"] = n
		_touch("npcs")
		_show_preview(), cont_labels))
	return card


## Una respuesta: texto, adónde lleva y, tras «⚙», cuándo aparece y qué hace.
func _answer_row(dl: Dictionary, nodes: Dictionary, node_id: String, opts: Array, k: int, tg: Array) -> Control:
	var o: Dictionary = opts[k]
	var wrap := VBoxContainer.new()
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 5)
	wrap.add_child(row)
	var bullet := UiStyle.label("▸", 13, Color("8ab8ff"))
	row.add_child(bullet)
	var text := _line(String(o.get("text", "")), func(t: String) -> void:
		o["text"] = t
		_touch("npcs")
		_refresh_titles()
		_show_preview(), "Lo que dice el jugador")
	text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(text)
	var dest := _option(tg[0], String(o.get("next", "")), func(n: String) -> void:
		o["next"] = n
		_touch("npcs")
		_refresh_titles()
		_show_preview(), tg[1])
	dest.custom_minimum_size.x = 270
	dest.fit_to_longest_item = false
	dest.clip_text = true   # todas las filas igual de anchas
	dest.tooltip_text = "Adónde lleva esta respuesta"
	row.add_child(dest)
	row.add_child(_small_button("＋", "Crear un tema nuevo para esta respuesta", func() -> void:
		var nid := _new_id("tema", nodes)
		nodes[nid] = {"text": "", "options": [{"text": "Volver.", "next": node_id}]}
		o["next"] = nid
		_node_id = nid
		_touch("npcs")
		_show_npc()
		_scroll_to_card.call_deferred(nid)))
	var key := "%s#%d" % [node_id, k]
	var has_extra := o.has("requires_flag") or o.has("hides_if_flag") or o.has("action")
	var gear := _small_button("⚙" + ("•" if has_extra else ""), "Cuándo aparece y qué hace al elegirla", func() -> void: pass)
	row.add_child(gear)
	row.add_child(_small_button("↑", "Subir", func() -> void:
		if k > 0:
			opts.insert(k - 1, opts.pop_at(k))
			_touch("npcs")
			_show_npc()))
	row.add_child(_small_button("↓", "Bajar", func() -> void:
		if k < opts.size() - 1:
			opts.insert(k + 1, opts.pop_at(k))
			_touch("npcs")
			_show_npc()))
	row.add_child(_small_button("✕", "Quitar esta respuesta", func() -> void:
		opts.remove_at(k)
		_touch("npcs")
		_show_npc()))
	var adv := _advanced_box(o)
	adv.visible = _open_advanced.has(key)
	wrap.add_child(adv)
	gear.pressed.connect(func() -> void:
		adv.visible = not adv.visible
		if adv.visible:
			_open_advanced[key] = true
		else:
			_open_advanced.erase(key))
	return wrap


## Lo avanzado de una respuesta, con formularios en vez de JSON.
func _advanced_box(o: Dictionary) -> VBoxContainer:
	var adv := VBoxContainer.new()
	adv.add_theme_constant_override("separation", 4)
	var pad := MarginContainer.new()
	pad.add_theme_constant_override("margin_left", 22)
	var inner := VBoxContainer.new()
	inner.add_theme_constant_override("separation", 4)
	pad.add_child(inner)
	adv.add_child(pad)
	_row(inner, "Solo aparece si tiene la marca", _flag_edit(o, "requires_flag", "(siempre)"), 210.0)
	_row(inner, "Desaparece si tiene la marca", _flag_edit(o, "hides_if_flag", "(nunca)"), 210.0)
	var action: Dictionary = o.get("action", {})
	var fields := VBoxContainer.new()
	var types: Array = ACTIONS.map(func(a: Array) -> String: return a[0])
	var names: Array = ACTIONS.map(func(a: Array) -> String: return a[1])
	_row(inner, "Al elegirla", _option(types, String(action.get("type", "")), func(t: String) -> void:
		if t == "":
			o.erase("action")
		else:
			var keep_flag: Variant = (o.get("action", {}) as Dictionary).get("flag")
			o["action"] = {"type": t}
			if keep_flag != null:
				o["action"]["flag"] = keep_flag
		_touch("npcs")
		_action_fields(fields, o)
		_show_preview(), names), 210.0)
	inner.add_child(fields)
	_action_fields(fields, o)
	return adv


func _action_fields(box: VBoxContainer, o: Dictionary) -> void:
	_clear(box)
	if not o.has("action"):
		return
	var a: Dictionary = o["action"]
	var spec: Array = []
	for entry in ACTIONS:
		if entry[0] == a.get("type", ""):
			spec = entry[2]
	for field in spec:
		match field:
			"quest":
				var qids := quests().keys()
				_row(box, "Misión", _option(qids, String(a.get("quest", "")), func(v: String) -> void:
					a["quest"] = v
					_touch("npcs"), qids.map(func(q: String) -> String: return String(quests()[q].get("name", q)))), 210.0)
			"kind":
				_row(box, "Tipo", _option(["motherboard", "ram"], String(a.get("kind", "motherboard")), func(v: String) -> void:
					a["kind"] = v
					a.erase("id")
					_touch("npcs")
					_action_fields.call_deferred(box, o), ["placa base", "módulo RAM"]), 210.0)
			"id":
				var pool: Dictionary = _skills_db.skills if String(a.get("kind", "motherboard")) == "motherboard" else _skills_db.rams
				var ids := pool.keys()
				_row(box, "Cuál", _option(ids, String(a.get("id", "")), func(v: String) -> void:
					a["id"] = v
					_touch("npcs"), ids.map(func(i: String) -> String: return String(pool[i].get("name", i)))), 210.0)
			"rarity":
				_row(box, "Qué da", _option(RARITIES, String(a.get("rarity", "rare")), func(v: String) -> void:
					a["rarity"] = v
					_touch("npcs"), RARITY_NAMES), 210.0)
	_row(box, "Apunta la marca\n(para que no se repita)", _line(String(a.get("flag", "")), func(t: String) -> void:
		if t.strip_edges() == "":
			a.erase("flag")
		else:
			a["flag"] = t.strip_edges()
		_touch("npcs"), "(ninguna)"), 210.0)


func _flag_edit(o: Dictionary, key: String, placeholder: String) -> LineEdit:
	var e := _line(String(o.get(key, "")), func(t: String) -> void:
		if t.strip_edges() == "":
			o.erase(key)
		else:
			o[key] = t.strip_edges()
		_touch("npcs")
		_show_preview(), placeholder)
	e.tooltip_text = "Las marcas (banderas) se guardan en el personaje del jugador al hacer cosas: act1_complete, ada_regalo..."
	return e


func _draw_portrait() -> void:
	if _npc_id == "" or not npcs().has(_npc_id):
		return
	var npc: Dictionary = npcs()[_npc_id]
	var look := CharacterAppearance.sanitize(npc.get("appearance", CharacterAppearance.default()))
	_portrait.draw_rect(Rect2(Vector2.ZERO, _portrait.size), Color("0c0b0f"))
	CharacterAppearance.draw(_portrait, Vector2(_portrait.size.x / 2.0, _portrait.size.y - 12.0), 2.6, look)


func _show_preview() -> void:
	if _preview_text == null:
		return
	_clear(_preview_options)
	var dl := _dialogue()
	if dl.is_empty():
		_preview_text.text = ""
		return
	var nodes: Dictionary = dl.get("nodes", {})
	if _preview_node == "" or not nodes.has(_preview_node):
		_preview_node = String(dl.get("start", ""))
	var node: Dictionary = nodes.get(_preview_node, {})
	var npc: Dictionary = npcs()[_npc_id]
	_preview_text.text = "[color=#%s][b]%s[/b][/color]\n%s" % [String(npc.get("color", "d9a441")), npc.get("name", _npc_id),
		String(node.get("text", "")).replace("{jugador}", "Jugador")]
	var go := func(target: String) -> void:
		_preview_node = target
		_scroll_to_card(target)
		_show_preview()
	if String(node.get("next", "")) != "" and (node.get("options", []) as Array).is_empty():
		_preview_options.add_child(_small_button("Continuar →", "", go.bind(String(node["next"]))))
	for o in node.get("options", []):
		var notes := PackedStringArray()
		if o.has("requires_flag"):
			notes.append("solo con %s" % o["requires_flag"])
		if o.has("hides_if_flag"):
			notes.append("se oculta con %s" % o["hides_if_flag"])
		if o.has("action"):
			for entry in ACTIONS:
				if entry[0] == o["action"].get("type", ""):
					notes.append(String(entry[1]).to_lower())
		var b := _small_button(String(o.get("text", "")) + ("   [" + " · ".join(notes) + "]" if not notes.is_empty() else ""), "", func() -> void:
			var nxt := String(o.get("next", ""))
			if nxt == "":
				_preview_text.text += "\n\n[color=#8a8293](fin de la conversación)[/color]"
				_clear(_preview_options)
			else:
				go.call(nxt))
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		_preview_options.add_child(b)


# --- Prólogo ---

func _build_prologue_tab() -> Control:
	var scroll := ScrollContainer.new()
	scroll.name = "Prólogo"
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_prologue_box = VBoxContainer.new()
	_prologue_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_prologue_box.add_theme_constant_override("separation", 8)
	scroll.add_child(_prologue_box)
	return scroll


func _build_prologue() -> void:
	if _prologue_box == null:
		return
	_clear(_prologue_box)
	var p: Dictionary = data["prologue"]
	var intro := UiStyle.label("Todo lo que se lee en el prólogo, en orden: la introducción, los letreros y avisos, las conversaciones y la ventana de contratación.", 13, UiStyle.MUTED)
	intro.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_prologue_box.add_child(intro)
	var sec := _foldable(_prologue_box, "1. Introducción (texto que se escribe solo al empezar)", true)
	_row(sec, "Párrafos\n(una línea en blanco separa párrafos)", _area("\n".join(PackedStringArray(p.get("intro", []))), func(t: String) -> void:
		p["intro"] = Array(t.split("\n"))
		_touch("prologue"), 220.0))
	sec = _foldable(_prologue_box, "2. Letreros de cada sitio y avisos de los puntos de interés")
	var places: Dictionary = _ensure(p, "places")
	for k in PLACE_NAMES:
		_row(sec, PLACE_NAMES[k], _line(String(places.get(k, "")), func(t: String) -> void:
			places[k] = t
			_touch("prologue")), 260.0)
	var prompts: Dictionary = _ensure(p, "prompts")
	for k in PROMPT_NAMES:
		_row(sec, PROMPT_NAMES[k], _line(String(prompts.get(k, "")), func(t: String) -> void:
			prompts[k] = t
			_touch("prologue")), 260.0)
	sec = _foldable(_prologue_box, "3. Conversaciones del prólogo (Rafa, la TV, el incidente, Mario y Aida...)")
	for cid in cutscenes():
		if String(cid).begins_with("prologo_"):
			_prologue_scene(sec, String(cid))
	sec = _foldable(_prologue_box, "4. Ventana de contratación")
	var hire: Dictionary = _ensure(p, "hire")
	for k in HIRE_NAMES:
		var w: Control
		if k in ["question", "refuse_error"]:
			w = _area(String(hire.get(k, "")), func(t: String) -> void:
				hire[k] = t
				_touch("prologue"), 50.0)
		else:
			w = _line(String(hire.get(k, "")), func(t: String) -> void:
				hire[k] = t
				_touch("prologue"))
		_row(sec, HIRE_NAMES[k], w, 260.0)
	sec = _foldable(_prologue_box, "5. Consola roja del incidente (una línea por renglón)")
	_row(sec, "Líneas", _area("\n".join(PackedStringArray(p.get("console", []))), func(t: String) -> void:
		p["console"] = _lines(t)
		_touch("prologue"), 130.0))
	sec = _foldable(_prologue_box, "6. Ayudas en pantalla")
	var hints: Dictionary = _ensure(p, "hints")
	for k in HINT_NAMES:
		_row(sec, HINT_NAMES[k], _line(String(hints.get(k, "")), func(t: String) -> void:
			hints[k] = t
			_touch("prologue")), 260.0)


## Una escena del prólogo: solo sus líneas, editables en el sitio (los efectos se ven en gris).
func _prologue_scene(parent: Control, cid: String) -> void:
	var cs: Dictionary = cutscenes()[cid]
	var body := _foldable(parent, "%s  (%s)" % [PROLOGUE_SCENES.get(cid, cid), cid])
	for s in cs.get("steps", []):
		if s.has("effect"):
			body.add_child(UiStyle.label("    · efecto: %s" % s["effect"], 11, UiStyle.MUTED))
			continue
		var who := String(s.get("speaker", ""))
		var who_name := "Jugador" if who == "player" else (_npc_name(who) if who != "" else String(s.get("name", "?")))
		_row(body, who_name, _area(String(s.get("text", "")), func(t: String) -> void:
			s["text"] = t
			_touch("cutscenes"), 46.0), 180.0)
	body.add_child(UiStyle.label("Para añadir líneas o efectos, ábrela en la pestaña Escenas.", 11, UiStyle.MUTED))


# --- Escenas ---

func _build_cutscene_tab() -> Control:
	var split := HSplitContainer.new()
	split.name = "Escenas"
	var left := VBoxContainer.new()
	left.custom_minimum_size.x = 220
	split.add_child(left)
	_cut_list = ItemList.new()
	_cut_list.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_cut_list.item_selected.connect(func(i: int) -> void:
		_cut_id = String(_cut_list.get_item_metadata(i))
		_show_cutscene())
	left.add_child(_cut_list)
	var cb := HBoxContainer.new()
	left.add_child(cb)
	cb.add_child(_small_button("＋ Escena", "Escena nueva", func() -> void:
		var cid := _new_id("escena_nueva", cutscenes())
		cutscenes()[cid] = {"steps": [{"name": "Sistema", "style": "system", "text": "..."}], "on_finish": {}}
		_cut_id = cid
		_touch("cutscenes")
		_refresh_cut_list()))
	cb.add_child(_small_button("Borrar", "Borra la escena (Ctrl+Z la recupera)", func() -> void:
		cutscenes().erase(_cut_id)
		_cut_id = ""
		_touch("cutscenes")
		_refresh_cut_list()))
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	split.add_child(scroll)
	_cut_box = VBoxContainer.new()
	_cut_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_cut_box.add_theme_constant_override("separation", 6)
	scroll.add_child(_cut_box)
	return split


func _refresh_cut_list() -> void:
	if _cut_list == null:
		return
	_cut_list.clear()
	for cid in cutscenes():
		var i := _cut_list.add_item(String(PROLOGUE_SCENES.get(cid, cid)))
		_cut_list.set_item_metadata(i, cid)
		_cut_list.set_item_tooltip(i, String(cid))
		if cid == _cut_id:
			_cut_list.select(i)
	if (_cut_id == "" or not cutscenes().has(_cut_id)) and _cut_list.item_count > 0:
		_cut_list.select(0)
		_cut_id = String(_cut_list.get_item_metadata(0))
	_show_cutscene()


## La escena como un guion: cada paso es una fila (quién habla y qué dice, o un efecto).
func _show_cutscene() -> void:
	if _cut_box == null:
		return
	_clear(_cut_box)
	if _cut_id == "" or not cutscenes().has(_cut_id):
		return
	var cs: Dictionary = cutscenes()[_cut_id]
	var steps: Array = cs.get("steps", [])
	cs["steps"] = steps
	_cut_box.add_child(UiStyle.section_header("Escena «%s» · %d pasos" % [PROLOGUE_SCENES.get(_cut_id, _cut_id), steps.size()]))
	var speakers: Array = ["", "player"] + npcs().keys()
	var labels: Array = ["(nombre propio)", "el jugador"]
	for nid in npcs():
		labels.append(_npc_name(nid))
	for k in steps.size():
		_cut_box.add_child(_step_row(steps, k, speakers, labels))
	var add := HBoxContainer.new()
	add.add_theme_constant_override("separation", 6)
	_cut_box.add_child(add)
	add.add_child(_small_button("＋ Línea de diálogo", "", func() -> void:
		steps.append({"name": "Sistema", "style": "system", "text": ""})
		_touch("cutscenes")
		_show_cutscene()))
	add.add_child(_small_button("＋ Efecto", "Glitch, temblor, fundido...", func() -> void:
		steps.append({"effect": "glitch", "strength": 1.0, "time": 0.5})
		_touch("cutscenes")
		_show_cutscene()))
	var adv := _foldable(_cut_box, "Al terminar la escena (avanzado)")
	_row(adv, "Datos (JSON)", _json_line(cs.get("on_finish", {}), func(v: Variant) -> void:
		cs["on_finish"] = v if v is Dictionary else {}
		_touch("cutscenes"), "{\"set_flag\": \"...\", \"travel\": {\"zone\": \"...\", \"entry\": \"\"}}"))


func _step_row(steps: Array, k: int, speakers: Array, labels: Array) -> Control:
	var s: Dictionary = steps[k]
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", UiStyle.inset_style())
	var box := VBoxContainer.new()
	panel.add_child(box)
	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", 6)
	box.add_child(top)
	top.add_child(UiStyle.label("%d." % (k + 1), 13, UiStyle.ACCENT))
	if s.has("effect"):
		top.add_child(UiStyle.label("Efecto", 13, UiStyle.MUTED))
		top.add_child(_option(EFFECTS, String(s["effect"]), func(e: String) -> void:
			s["effect"] = e
			_touch("cutscenes"), EFFECT_NAMES))
		top.add_child(UiStyle.label("fuerza", 12, UiStyle.MUTED))
		top.add_child(_spin(float(s.get("strength", 1.0)), 0.0, 3.0, 0.1, func(v: float) -> void:
			s["strength"] = v
			_touch("cutscenes")))
		top.add_child(UiStyle.label("espera (s)", 12, UiStyle.MUTED))
		top.add_child(_spin(float(s.get("time", 0.5)), 0.0, 10.0, 0.1, func(v: float) -> void:
			s["time"] = v
			_touch("cutscenes")))
	else:
		top.add_child(UiStyle.label("Habla", 13, UiStyle.MUTED))
		top.add_child(_option(speakers, String(s.get("speaker", "")), func(sp: String) -> void:
			if sp == "":
				s.erase("speaker")
				s["name"] = String(s.get("name", "Sistema"))
			else:
				s["speaker"] = sp
				s.erase("name")
				s.erase("style")
			_touch("cutscenes")
			_show_cutscene(), labels))
		if not s.has("speaker"):
			var nm := _line(String(s.get("name", "")), func(t: String) -> void:
				s["name"] = t
				_touch("cutscenes"), "Nombre")
			nm.custom_minimum_size.x = 160
			top.add_child(nm)
			top.add_child(_option(STYLES, String(s.get("style", "")), func(st: String) -> void:
				if st == "":
					s.erase("style")
				else:
					s["style"] = st
				_touch("cutscenes"), STYLE_NAMES))
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(spacer)
	top.add_child(_small_button("↑", "Subir", func() -> void:
		if k > 0:
			steps.insert(k - 1, steps.pop_at(k))
			_touch("cutscenes")
			_show_cutscene()))
	top.add_child(_small_button("↓", "Bajar", func() -> void:
		if k < steps.size() - 1:
			steps.insert(k + 1, steps.pop_at(k))
			_touch("cutscenes")
			_show_cutscene()))
	top.add_child(_small_button("✕", "Quitar este paso", func() -> void:
		steps.remove_at(k)
		_touch("cutscenes")
		_show_cutscene()))
	if not s.has("effect") or String(s["effect"]) == "dino":
		box.add_child(_area(String(s.get("text", "")), func(t: String) -> void:
			if t.strip_edges() == "" and s.has("effect"):
				s.erase("text")
			else:
				s["text"] = t
			_touch("cutscenes"), 46.0))
	return panel


# --- Misiones ---

func _build_quest_tab() -> Control:
	var split := HSplitContainer.new()
	split.name = "Misiones"
	_quest_list = ItemList.new()
	_quest_list.custom_minimum_size.x = 240
	_quest_list.item_selected.connect(func(i: int) -> void:
		_quest_id = String(_quest_list.get_item_metadata(i))
		_show_quest())
	split.add_child(_quest_list)
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	split.add_child(scroll)
	_quest_box = VBoxContainer.new()
	_quest_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_quest_box.add_theme_constant_override("separation", 6)
	scroll.add_child(_quest_box)
	return split


func _refresh_quest_list() -> void:
	if _quest_list == null:
		return
	_quest_list.clear()
	for qid in quests():
		var q: Dictionary = quests()[qid]
		var i := _quest_list.add_item(("★ " if q.get("main", false) else "") + String(q.get("name", qid)))
		_quest_list.set_item_metadata(i, qid)
		if qid == _quest_id:
			_quest_list.select(i)
	if (_quest_id == "" or not quests().has(_quest_id)) and _quest_list.item_count > 0:
		_quest_list.select(0)
		_quest_id = String(_quest_list.get_item_metadata(0))
	_show_quest()


func _show_quest() -> void:
	if _quest_box == null:
		return
	_clear(_quest_box)
	if _quest_id == "" or not quests().has(_quest_id):
		return
	var q: Dictionary = quests()[_quest_id]
	_quest_box.add_child(UiStyle.section_header("Misión · %s" % _quest_id))
	_row(_quest_box, "Nombre", _line(String(q.get("name", "")), func(t: String) -> void:
		q["name"] = t
		_touch("quests")))
	_row(_quest_box, "Descripción", _area(String(q.get("description", "")), func(t: String) -> void:
		q["description"] = t
		_touch("quests"), 70.0))
	var givers: Array = [""] + npcs().keys()
	_row(_quest_box, "La ofrece", _option(givers, String(q.get("giver", "")), func(g: String) -> void:
		if g == "":
			q.erase("giver")
		else:
			q["giver"] = g
		_touch("quests"), ["(nadie: empieza sola o tras otra misión)"] + npcs().keys().map(func(n: String) -> String: return _npc_name(n))))
	_row(_quest_box, "Experiencia", _spin(float(q.get("experience", 0)), 0, 100000, 10, func(v: float) -> void:
		q["experience"] = int(v)
		_touch("quests")))
	_quest_box.add_child(UiStyle.label("Pasos (el texto es lo que se ve en el registro de misiones):", 13, UiStyle.MUTED))
	for st in q.get("steps", []):
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 6)
		var kind := UiStyle.label(String(st.get("type", "?")), 12, UiStyle.ACCENT)
		kind.custom_minimum_size.x = 90
		row.add_child(kind)
		var text := _line(String(st.get("text", "")), func(t: String) -> void:
			st["text"] = t
			_touch("quests"))
		text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(text)
		var extra := {}
		for k in st:
			if k != "type" and k != "text":
				extra[k] = st[k]
		var json := _json_line(extra, func(v: Variant) -> void:
			if not v is Dictionary:
				return
			for k in st.keys():
				if k != "type" and k != "text":
					st.erase(k)
			st.merge(v)
			_touch("quests"))
		json.custom_minimum_size.x = 260
		json.tooltip_text = "Datos del paso (npc, zone, flag, count, item...)."
		row.add_child(json)
		_quest_box.add_child(row)
	var adv := _foldable(_quest_box, "Recompensas (avanzado)")
	_row(adv, "Datos (JSON)", _json_line(q.get("rewards", []), func(v: Variant) -> void:
		if v is Array:
			q["rewards"] = v
			_touch("quests")))


# --- Tutorial ---

func _build_tutorial() -> void:
	if _tutorial_box == null:
		return
	_clear(_tutorial_box)
	var t: Dictionary = data["tutorial"]
	_tutorial_box.add_child(UiStyle.section_header("Tutorial del Sandbox"))
	_row(_tutorial_box, "Título", _line(String(t.get("title", "")), func(v: String) -> void:
		t["title"] = v
		_touch("tutorial")))
	for st in t.get("steps", []):
		_row(_tutorial_box, String(st.get("id", "?")), _area(String(st.get("text", "")), func(v: String) -> void:
			st["text"] = v
			_touch("tutorial"), 50.0))
		if st.has("text_touch"):   # versión con controles táctiles (T138)
			_row(_tutorial_box, "%s (celular)" % st.get("id", "?"), _area(String(st["text_touch"]), func(v: String) -> void:
				st["text_touch"] = v
				_touch("tutorial"), 50.0))
	_row(_tutorial_box, "Al terminar", _area(String(t.get("done", "")), func(v: String) -> void:
		t["done"] = v
		_touch("tutorial"), 50.0))


# --- Pruebas ---

## `-- captura`: guarda una imagen de cada pestaña en user://capturas/ y sale.
func _self_capture() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("user://capturas/"))
	for k in 4:
		_tabs.current_tab = k
		if k == 1:   # el prólogo con las conversaciones desplegadas
			for ch in _prologue_box.get_children():
				if ch is VBoxContainer:
					ch.visible = true
		await get_tree().create_timer(0.6).timeout
		get_viewport().get_texture().get_image().save_png(ProjectSettings.globalize_path("user://capturas/12%d_editor.png" % k))
	_tabs.current_tab = 0
	_global_search("constancia")
	await get_tree().create_timer(0.5).timeout
	get_viewport().get_texture().get_image().save_png(ProjectSettings.globalize_path("user://capturas/124_editor_busqueda.png"))
	get_tree().quit()


## `-- autoprueba`: cambia una frase y un texto del prólogo, guarda, comprueba los
## archivos, deshace con Ctrl+Z y genera el ejecutable con el botón.
func _self_test() -> void:
	var node: Dictionary = dialogues()["ada"]["nodes"]["hola"]
	var original := String(node["text"])
	node["text"] = original + " [autoprueba]"
	_touch("npcs")
	data["prologue"]["places"]["calle"] = String(data["prologue"]["places"]["calle"]) + " [autoprueba]"
	_touch("prologue")
	_on_save()
	print("autoprueba: guardado = ", FileAccess.get_file_as_string(FILES["npcs"]).contains("[autoprueba]")
		and FileAccess.get_file_as_string(FILES["prologue"]).contains("[autoprueba]"))
	undo()
	undo()
	_on_save()
	print("autoprueba: deshecho = ", not FileAccess.get_file_as_string(FILES["npcs"]).contains("[autoprueba]")
		and not FileAccess.get_file_as_string(FILES["prologue"]).contains("[autoprueba]"))
	_on_build()
	while _build_thread and _build_thread.is_alive():
		await get_tree().create_timer(0.5).timeout
	await get_tree().create_timer(0.5).timeout
	print("autoprueba: ", _status.text)
	get_tree().quit()
