class_name ScreenTransition
extends CanvasLayer
## Transición entre pantallas (T96): un barrido de píxeles (cuadros que se encienden
## en diagonal con algo de azar) que tapa la pantalla, cambia de escena y se retira.
## Vive en la raíz del árbol, así que sobrevive al cambio de escena.

const CELL := 40.0
const COVER_TIME := 0.38
const REVEAL_TIME := 0.42
const COLOR := Color("07060a")
## T183: el fotograma que sigue a un cambio de escena pesado trae un delta enorme; el
## barrido nunca avanza más que esto por fotograma, para que el destape se vea entero.
const MAX_STEP := 1.0 / 30.0
## Fotogramas que espera tapado tras el cambio antes de destapar (la escena nueva se asienta).
const SETTLE_FRAMES := 2

var _t := 0.0
var _phase := "cover"   # cover → (cambio) → settle → reveal
var _settle := 0
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
	Sfx.play("lay_whoosh", -20.0)   # T183: el barrido suena, muy bajo


## Cuánto avanza el barrido con un delta: nunca más que MAX_STEP (T183).
static func step(delta: float) -> float:
	return clampf(delta, 0.0, MAX_STEP)


func _process(delta: float) -> void:
	if _phase == "settle":
		_settle += 1
		if _settle >= SETTLE_FRAMES:
			_phase = "reveal"
			_t = 0.0
		return
	_t += step(delta)
	if _phase == "cover" and _t >= COVER_TIME:
		_phase = "settle"
		_settle = 0
		get_tree().change_scene_to_file(_target)
	elif _phase == "reveal" and _t >= REVEAL_TIME:
		queue_free()
	_rect.queue_redraw()


## Proporción tapada en este instante: sube al tapar, se queda entera mientras la
## escena nueva se asienta y baja al destapar.
func coverage() -> float:
	match _phase:
		"cover": return clampf(_t / COVER_TIME, 0.0, 1.0)
		"settle": return 1.0
	return 1.0 - clampf(_t / REVEAL_TIME, 0.0, 1.0)


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
