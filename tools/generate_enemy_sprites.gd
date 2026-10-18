extends SceneTree
## Genera assets/sprites/enemies/enemies.png: pixel art procedural de los
## enemigos (4 fotogramas de animación por fila, 32×32 cada uno).
##
## Uso:  Godot_v4.7.2-stable_win64_console.exe --headless --path . -s res://tools/generate_enemy_sprites.gd
##
## Es arte de programador para tener algo legible ya. Cuando haya sprites
## dibujados a mano, basta con sustituir el PNG respetando la cuadrícula
## (columnas = fotogramas, filas = tipos; ver data/enemies.json → sprite_row).

const S := 32
const FRAMES := 4
const OUT := "res://assets/sprites/enemies/enemies.png"
const OUTLINE := Color("0d0b10")
const SHADOW := Color(0, 0, 0, 0.35)

var img: Image
var ox := 0  # origen del fotograma actual
var oy := 0


func _initialize() -> void:
	var rows: Array[Callable] = [_bug, _zombie_process, _memory_leak, _worm, _daemon]
	img = Image.create_empty(S * FRAMES, S * rows.size(), false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	for row in rows.size():
		for f in FRAMES:
			ox = f * S
			oy = row * S
			_ellipse(16, 29, 9, 2, SHADOW)
			rows[row].call(f)
			_outline()
	img.save_png(ProjectSettings.globalize_path(OUT))
	print("Escrito %s (%dx%d)" % [OUT, img.get_width(), img.get_height()])
	quit()


# --- Primitivas (coordenadas locales al fotograma) ---

func _px(x: int, y: int, c: Color) -> void:
	if x < 0 or y < 0 or x >= S or y >= S:
		return
	if c.a < 1.0:
		c = img.get_pixel(ox + x, oy + y).blend(c)
	img.set_pixel(ox + x, oy + y, c)


func _rect(x0: int, y0: int, x1: int, y1: int, c: Color) -> void:
	for y in range(y0, y1 + 1):
		for x in range(x0, x1 + 1):
			_px(x, y, c)


func _ellipse(cx: float, cy: float, rx: float, ry: float, c: Color) -> void:
	for y in range(int(cy - ry) - 1, int(cy + ry) + 2):
		for x in range(int(cx - rx) - 1, int(cx + rx) + 2):
			var dx := (x + 0.5 - cx) / rx
			var dy := (y + 0.5 - cy) / ry
			if dx * dx + dy * dy <= 1.0:
				_px(x, y, c)


func _line(x0: int, y0: int, x1: int, y1: int, c: Color) -> void:
	var steps := maxi(absi(x1 - x0), absi(y1 - y0))
	for i in steps + 1:
		var t := float(i) / maxf(1.0, steps)
		_px(roundi(lerpf(x0, x1, t)), roundi(lerpf(y0, y1, t)), c)


## Contorno oscuro de 1 px alrededor de lo opaco, para que se lea sobre el suelo.
func _outline() -> void:
	var solid := {}
	for y in S:
		for x in S:
			if img.get_pixel(ox + x, oy + y).a >= 0.5:
				solid[Vector2i(x, y)] = true
	for y in S:
		for x in S:
			if solid.has(Vector2i(x, y)):
				continue
			for d in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
				if solid.has(Vector2i(x, y) + d):
					img.set_pixel(ox + x, oy + y, OUTLINE)
					break


# --- Enemigos (todos miran a la derecha; el shader los voltea) ---

## Bug: escarabajo con patas que se alternan.
func _bug(f: int) -> void:
	var bob := f % 2
	var shell := Color("3b5b2e")
	for i in 3:
		var x := 11 + i * 5
		var off := -2 if (f + i) % 2 == 0 else 2
		_line(x, 23, x + off, 27, Color("1a1a1a"))
	_ellipse(15, 19 + bob, 9, 6, shell)
	_ellipse(13, 17 + bob, 5, 2, Color("5c8a45"))
	_line(15, 14 + bob, 15, 24 + bob, shell.darkened(0.4))
	_ellipse(25, 20 + bob, 3.5, 3.5, Color("22301c"))
	_px(27, 19 + bob, Color("ff4040"))
	_px(26, 19 + bob, Color("ff4040"))
	var wiggle := 1 if f < 2 else 0
	_line(26, 17 + bob, 29, 12 + wiggle, Color("1a1a1a"))
	_line(24, 17 + bob, 25, 11 + wiggle, Color("1a1a1a"))


## Proceso zombi: humanoide con un monitor CRT por cabeza y los brazos al frente.
func _zombie_process(f: int) -> void:
	var stride: int = [-2, 0, 2, 0][f]
	var skin := Color("6b8f5e")
	var clothes := Color("4a4a5a")
	_rect(12 + stride, 22, 14 + stride, 28, clothes.darkened(0.3))
	_rect(17 - stride, 22, 19 - stride, 28, clothes.darkened(0.3))
	_rect(11, 13, 20, 22, clothes)
	_rect(12, 18, 14, 20, clothes.darkened(0.45))  # roto
	var arm := 14 + (f % 2)
	_rect(19, arm, 27, arm + 2, skin)
	_rect(15, 11, 17, 12, Color("8a8a8a"))  # soporte del monitor
	_rect(10, 2, 21, 11, Color("b8b8b0"))
	_rect(11, 3, 20, 9, Color("10200f"))
	var green := Color("3cff6a")
	if f % 2 == 0:  # una "Z" parpadeante
		_line(13, 4, 17, 4, green)
		_line(17, 4, 13, 8, green)
		_line(13, 8, 17, 8, green)
	else:
		_rect(18, 7, 19, 8, green)  # cursor


## Memory leak: limo que se aplasta y deja gotas detrás.
func _memory_leak(f: int) -> void:
	var rx: float = [9.0, 10.0, 11.0, 10.0][f]
	var ry: float = [7.5, 6.5, 5.5, 6.5][f]
	var cy := 28.0 - ry
	var body := Color("7b4bd6")
	_ellipse(4 + f, 27, 1.5, 1.2, body.darkened(0.2))
	_ellipse(1 + f * 2 % 5, 28, 1.0, 1.0, body.darkened(0.3))
	_ellipse(16, cy, rx, ry, body)
	_ellipse(13, cy - ry * 0.45, rx * 0.45, ry * 0.3, Color("a07cf0"))
	for side in [-3, 3]:
		_rect(18 + side, int(cy) - 1, 19 + side, int(cy), Color.WHITE)
		_px(19 + side, int(cy), Color.BLACK)


## Gusano de red: segmentos que ondulan.
func _worm(f: int) -> void:
	var phase := f * PI / 2.0
	for i in 6:
		var x := 6.0 + i * 4.0
		var y := 23.0 + sin(phase + i * 0.9) * 2.5
		var r := 3.0 if i < 5 else 4.2
		_ellipse(x, y, r, r, Color("c86b7a") if i % 2 == 0 else Color("b05a69"))
		_px(int(x) - 1, int(y - r) + 1, Color("e89aa6"))
	var head_y := 23.0 + sin(phase + 5 * 0.9) * 2.5
	_px(28, int(head_y) - 1, Color.BLACK)
	_line(30, int(head_y), 31, int(head_y) - 2, Color("e8d9b0"))
	_line(30, int(head_y) + 1, 31, int(head_y) + 3, Color("e8d9b0"))


## Daemon: demonio con cuernos, para jefes únicos.
func _daemon(f: int) -> void:
	var stride: int = [-2, 0, 2, 0][f]
	var bob := 1 if f % 2 == 1 else 0
	var skin := Color("7a1f2b")
	_rect(12 + stride, 22, 14 + stride, 28, skin.darkened(0.4))
	_rect(18 - stride, 22, 20 - stride, 28, skin.darkened(0.4))
	_rect(10, 12 + bob, 22, 23, skin)
	_rect(13, 15 + bob, 19, 20, skin.lightened(0.15))
	_rect(22, 14 + bob, 26, 16 + bob, skin)
	_line(26, 16 + bob, 28, 18 + bob, Color("e8d9b0"))  # garras
	_ellipse(16, 8 + bob, 5.5, 5, skin)
	_line(12, 5 + bob, 9, 0 + bob, Color("e8d9b0"))
	_line(20, 5 + bob, 23, 0 + bob, Color("e8d9b0"))
	_px(15, 8 + bob, Color("ffcc00"))
	_px(18, 8 + bob, Color("ffcc00"))
	_line(10, 20, 5, 24 + bob, skin.darkened(0.2))  # cola
