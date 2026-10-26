class_name ScreenTransition
extends CanvasLayer
## Transición entre pantallas (T96): un barrido de píxeles (cuadros que se encienden
## en diagonal con algo de azar) que tapa la pantalla, cambia de escena y se retira.
## Vive en la raíz del árbol, así que sobrevive al cambio de escena.

const CELL := 40.0
const COVER_TIME := 0.38
const REVEAL_TIME := 0.42
const COLOR := Color("07060a")

var _t := 0.0
var _phase := "cover"   # cover → (cambio) → reveal
var _target := ""
var _rect: Control


## Cambia a la escena `path` con el barrido. Si ya hay una transición en marcha, nada.
static func change_scene(tree: SceneTree, path: String) -> void:
	for child in tree.root.get_children():
		if child is ScreenTransition:
			return
	var tr := ScreenTransition.new()
	tr._target = path
	tree.root.add_child(tr)


## Cuándo (0..1 del barrido) se enciende la celda (col, row): en diagonal desde arriba
## a la izquierda, con un poco de ruido fijo por celda para que no sea una línea recta.
static func cell_threshold(col: int, row: int, cols: int, rows: int) -> float:
	var diagonal := float(col + row) / maxf(1.0, float(cols + rows - 2))
	var noise := fposmod(sin(col * 12.9898 + row * 78.233) * 43758.5453, 1.0)
	return clampf(diagonal * 0.8 + noise * 0.2, 0.0, 1.0)


func _ready() -> void:
	layer = 120
	process_mode = Node.PROCESS_MODE_ALWAYS
	_rect = Control.new()
	_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	_rect.mouse_filter = Control.MOUSE_FILTER_STOP   # nada de clicks a medio barrido
	_rect.draw.connect(_draw_cells)
	add_child(_rect)


func _process(delta: float) -> void:
	_t += delta
	if _phase == "cover" and _t >= COVER_TIME:
		_phase = "reveal"
		_t = 0.0
		get_tree().change_scene_to_file(_target)
	elif _phase == "reveal" and _t >= REVEAL_TIME:
		queue_free()
	_rect.queue_redraw()


## Proporción tapada en este instante: sube al tapar y baja al destapar.
func coverage() -> float:
	return clampf(_t / COVER_TIME, 0.0, 1.0) if _phase == "cover" else 1.0 - clampf(_t / REVEAL_TIME, 0.0, 1.0)


func _draw_cells() -> void:
	var view := _rect.size
	var cols := ceili(view.x / CELL)
	var rows := ceili(view.y / CELL)
	var k := coverage()
	for row in rows:
		for col in cols:
			var th := cell_threshold(col, row, cols, rows)
			# Cada celda crece de un punto al cuadro entero en un 25 % del barrido.
			var grow := clampf((k - th * 0.75) / 0.25, 0.0, 1.0)
			if grow <= 0.0:
				continue
			var s := CELL * grow
			var center := Vector2(col + 0.5, row + 0.5) * CELL
			_rect.draw_rect(Rect2(center - Vector2(s, s) / 2.0, Vector2(s, s)).grow(0.5), COLOR)
