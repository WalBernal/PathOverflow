class_name FitScroll
extends ScrollContainer
## Área con desplazamiento que mide lo que queda de pantalla debajo de su ventana:
## si el contenido cabe, se ve entero (sin barra); si no (interfaz grande en una
## pantalla baja), se encoge y se desplaza. Se reajusta al abrir la ventana, al
## cambiar el contenido, la ventana o el tamaño de interfaz (grupo "fit_scroll").

## La ventana (PanelContainer) que contiene esta área.
var panel: Control
const MIN_HEIGHT := 120.0


func _init(p_panel: Control) -> void:
	panel = p_panel
	horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_to_group(&"fit_scroll")


func _ready() -> void:
	panel.visibility_changed.connect(fit.call_deferred)
	get_viewport().size_changed.connect(fit.call_deferred)
	if get_child_count() > 0:
		(get_child(0) as Control).minimum_size_changed.connect(fit.call_deferred)
	fit.call_deferred()


func fit() -> void:
	if get_child_count() == 0 or not is_instance_valid(panel) or not panel.visible:
		return
	var parent := panel.get_parent_control()
	if parent == null:
		return
	var content := get_child(0) as Control
	var full := content.get_combined_minimum_size().y
	var overhead := panel.get_combined_minimum_size().y - get_combined_minimum_size().y
	var avail := parent.size.y - panel.position.y - 10.0 - overhead
	var h := clampf(avail, MIN_HEIGHT, full)
	if not is_equal_approx(custom_minimum_size.y, h):
		custom_minimum_size = Vector2(content.get_combined_minimum_size().x, h)
		panel.reset_size()
