class_name AppearancePreview
extends Control
## Muestra la figura de un personaje a cualquier tamaño (creador, lista de personajes).

var appearance: Dictionary = CharacterAppearance.default():
	set(value):
		appearance = value
		queue_redraw()
var facing := Vector2.DOWN:
	set(value):
		facing = value
		queue_redraw()


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _draw() -> void:
	# La figura mide ~46 unidades (con cresta); se escala para llenar el control.
	var scale := minf(size.x / 30.0, size.y / 50.0)
	var feet := Vector2(size.x / 2.0, size.y - 4.0 * scale)
	CharacterAppearance.draw(self, feet, scale, appearance, facing)
