class_name GameVersion
## Versión del juego (T139): application/config/version de project.godot, la única
## fuente (tools/exportar_android.ps1 la copia al APK). Se ve abajo a la derecha en
## la pantalla de título y en la pausa.


static func full() -> String:
	return String(ProjectSettings.get_setting("application/config/version", "0.0.0"))


## «v3.1» (sin el «.0» del final), o «v3.1.2».
static func short(version := "") -> String:
	var parts := (version if version != "" else full()).split(".")
	while parts.size() > 2 and parts[parts.size() - 1] == "0":
		parts.remove_at(parts.size() - 1)
	return "v" + ".".join(parts)


## Etiqueta discreta abajo a la derecha de `parent` (que ocupa la pantalla).
static func add_label(parent: Control) -> Label:
	var l := UiStyle.label(short(), 13, UiStyle.MUTED)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	l.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
	l.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	l.grow_vertical = Control.GROW_DIRECTION_BEGIN
	l.offset_right = -12.0
	l.offset_bottom = -8.0
	parent.add_child(l)
	return l
