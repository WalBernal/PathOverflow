class_name IsoGround
extends Node2D
## Suelo isométrico de marcador de posición: solo dibuja la rejilla visible
## alrededor de la cámara. Cuando haya arte, se sustituye por un TileMapLayer
## con TileSet de forma isométrica (128×64).

const TILE := Vector2(128.0, 64.0)
const LINE_COLOR := Color("221e29")


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	var cam := get_viewport().get_camera_2d()
	var center := cam.get_screen_center_position() if cam else Vector2.ZERO
	var cam_zoom := cam.zoom if cam else Vector2.ONE
	var half := get_viewport_rect().size * 0.5 / cam_zoom + TILE * 2.0
	var rect := Rect2(center - half, half * 2.0)
	# Dos familias de rectas y = ±0.5·x + c, separadas TILE.y en vertical.
	for slope in [0.5, -0.5]:
		var cs: Array[float] = []
		for corner in [rect.position, rect.end, Vector2(rect.position.x, rect.end.y), Vector2(rect.end.x, rect.position.y)]:
			cs.append(corner.y - slope * corner.x)
		var c := floorf(cs.min() / TILE.y) * TILE.y
		var c_max: float = cs.max()
		while c <= c_max:
			draw_line(Vector2(rect.position.x, slope * rect.position.x + c),
				Vector2(rect.end.x, slope * rect.end.x + c), LINE_COLOR, 1.0)
			c += TILE.y
