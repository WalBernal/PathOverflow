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
	var rows: Array[Callable] = [_bug, _zombie_process, _memory_leak, _worm, _daemon, _spam_bot, _thread, _node_modules, _troll, _irq, _mutex, _wild_pointer, _twin_thread, _init_fork, _init_core,
		_rootkit, _ghost_process, _bios_sentinel, _firmware_worm, _electromigration, _capacitor, _fw_update,
		_beep_code, _jumper, _swollen_battery, _bad_sector, _option_rom, _watchdog]
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


## Bot de spam: sobre volador con alas de papel y una antena; dispara correos.
func _spam_bot(f: int) -> void:
	var bob: int = [0, -1, -2, -1][f]
	var paper := Color("e8e4d8")
	var flap := 1 if f % 2 == 0 else -2
	_line(9, 15 + bob, 3, 10 + bob + flap, paper.darkened(0.15))   # ala izquierda
	_line(9, 16 + bob, 4, 13 + bob + flap, paper.darkened(0.15))
	_rect(8, 12 + bob, 24, 23 + bob, paper)
	_line(8, 12 + bob, 16, 18 + bob, paper.darkened(0.3))        # solapa
	_line(24, 12 + bob, 16, 18 + bob, paper.darkened(0.3))
	_ellipse(16, 18 + bob, 2, 2, Color("d03030"))                 # sello
	_line(16, 12 + bob, 16, 7 + bob, Color("5a5a62"))             # antena
	_px(16, 6 + bob, Color("ffd84a") if f < 2 else Color("ff4040"))
	_px(12, 20 + bob, Color("1a1a1a"))
	_px(20, 20 + bob, Color("1a1a1a"))


## Hilo desbocado: bobina de hilo con patas rápidas y una aguja delante.
func _thread(f: int) -> void:
	var legs: Array = [[-3, 3], [0, 0], [3, -3], [0, 0]][f]
	_line(13, 22, 11 + legs[0], 28, Color("1a1a1a"))
	_line(19, 22, 21 + legs[1], 28, Color("1a1a1a"))
	_rect(10, 10, 22, 23, Color("8a5a3a"))                        # carrete
	_rect(11, 12, 21, 21, Color("4b8bd6"))                        # hilo enrollado
	for y in [13, 15, 17, 19]:
		_line(11, y, 21, y + 1, Color("6fa8f0"))
	_rect(9, 9, 23, 10, Color("6a4028"))
	_rect(9, 23, 23, 24, Color("6a4028"))
	_line(23, 16, 30, 15, Color("c8c8d0"))                        # aguja
	_px(18, 14, Color.WHITE)
	_px(20, 14, Color.WHITE)
	_line(10, 17, 4 - f, 19 + (f % 2), Color("6fa8f0"))           # hilo suelto


## node_modules: caja de cartón gigante, abultada, llena de dependencias.
func _node_modules(f: int) -> void:
	var squash: int = [0, 1, 0, -1][f]
	var box := Color("9a7448")
	_rect(4, 9 + squash, 27, 28, box)
	_rect(4, 9 + squash, 27, 11 + squash, box.lightened(0.15))
	_line(4, 9 + squash, 0, 5 + squash, box.lightened(0.1))      # solapas abiertas
	_line(27, 9 + squash, 31, 5 + squash, box.lightened(0.1))
	# Dependencias asomando por arriba (cajitas de colores).
	_rect(8, 4 + squash, 12, 8 + squash, Color("5cb85c"))
	_rect(14, 2 + squash, 19, 8 + squash, Color("c84b4b"))
	_rect(21, 5 + squash, 25, 8 + squash, Color("4b8bd6"))
	_rect(9, 15, 22, 17, box.darkened(0.35))                      # etiqueta
	_px(12, 21, Color("ffcc00"))
	_px(19, 21, Color("ffcc00"))
	_line(11, 24, 20, 24, box.darkened(0.5))


## Troll de foro: criatura verde con un teclado en llamas.
func _troll(f: int) -> void:
	var stride: int = [-2, 0, 2, 0][f]
	var skin := Color("5f8a3a")
	_rect(11 + stride, 22, 13 + stride, 28, skin.darkened(0.35))
	_rect(18 - stride, 22, 20 - stride, 28, skin.darkened(0.35))
	_ellipse(16, 17, 8, 7, Color("6a3a7a"))                       # sudadera
	_ellipse(16, 8, 6, 5.5, skin)
	_px(14, 7, Color("ffcc00"))
	_px(18, 7, Color("ffcc00"))
	_line(13, 11, 19, 11, Color("1a1a1a"))                        # sonrisa trol
	_px(12, 10, Color("1a1a1a"))
	_px(20, 10, Color("1a1a1a"))
	_rect(21, 16, 29, 19, Color("2a2a30"))                        # teclado
	var flame := [Color("e0652f"), Color("f0a030"), Color("ffe070")]
	for k in 3:
		_px(23 + k * 2, 15 - (f + k) % 3, flame[(f + k) % 3])
		_px(23 + k * 2, 14 - (f + k) % 2, flame[k])


## Interrupción (IRQ): chispa eléctrica flotante con un "!" dentro.
func _irq(f: int) -> void:
	var bob: int = [0, -1, -2, -1][f]
	var core := Color("e8e040")
	for k in 6:
		var a := TAU * k / 6.0 + f * 0.4
		_line(16, 16 + bob, 16 + int(cos(a) * 12.0), 16 + bob + int(sin(a) * 12.0), Color("f0a020"))
	_ellipse(16, 16 + bob, 7, 7, core)
	_rect(15, 11 + bob, 17, 17 + bob, Color("2a2a30"))
	_rect(15, 19 + bob, 17, 20 + bob, Color("2a2a30"))


## Candado Mutex: candado de hierro gordo con un "1" (bloqueado).
func _mutex(f: int) -> void:
	var iron := Color("7a7e88")
	for x in range(9, 24):
		for y in range(5, 15):
			var d := Vector2(x + 0.5 - 16, y + 0.5 - 14).length()
			if d <= 7.5 and d >= 4.5 and y < 14:
				_px(x, y, iron.lightened(0.15))
	_rect(6, 13, 26, 28, iron)
	_rect(6, 13, 26, 14, iron.lightened(0.25))
	_ellipse(16, 20, 2.5, 2.5, Color("1a1a1e"))
	_rect(15, 21, 17, 25, Color("1a1a1e"))
	_px(9 + f, 16, Color("e06c6c"))   # luz de "ocupado"


## Puntero Salvaje: flecha glitcheada que deja copias desplazadas.
func _wild_pointer(f: int) -> void:
	var c := Color("c08aff")
	var shift: int = [0, 2, -2, 1][f]
	for k in 3:
		var col: Color = [Color(1, 0.2, 0.4, 0.5), Color(0.2, 1, 0.9, 0.5), c][k]
		var o: int = (k - 1) * shift
		_line(6 + o, 24, 22 + o, 8, col)
		_line(7 + o, 24, 23 + o, 8, col)
		_line(22 + o, 8, 14 + o, 9, col)
		_line(22 + o, 8, 21 + o, 16, col)
	_ellipse(9, 22, 2.5, 2.5, Color("1a1a1e"))   # el "*" del puntero
	_px(9, 22, c)


## Hilo gemelo: autómata de hierro con un número de turno en el pecho.
func _twin_thread(f: int) -> void:
	var stride: int = [-2, 0, 2, 0][f]
	var metal := Color("5a6a7a")
	_rect(11 + stride, 22, 13 + stride, 28, metal.darkened(0.4))
	_rect(18 - stride, 22, 20 - stride, 28, metal.darkened(0.4))
	_rect(9, 11, 22, 23, metal)
	_rect(12, 14, 19, 20, Color("1a2030"))
	_line(14, 15, 16, 15, Color("6fd3c8"))   # "="
	_line(14, 18, 17, 18, Color("6fd3c8"))
	_rect(12, 4, 19, 10, metal.lightened(0.15))
	_px(14, 7, Color("6fd3c8"))
	_px(17, 7, Color("6fd3c8"))
	_line(22, 13, 27, 17 + (f % 2), metal)       # brazo-pistón
	_rect(4, 15, 8, 18, Color("8a5a2a"))          # engranaje


## Copia de init: versión pequeña y translúcida del núcleo.
func _init_fork(f: int) -> void:
	var bob: int = [0, -1, 0, 1][f]
	_ellipse(16, 18 + bob, 7, 7, Color(0.9, 0.35, 0.2, 0.75))
	_ellipse(16, 18 + bob, 3, 3, Color("ffd870"))
	for k in 4:
		var a := TAU * k / 4.0 + f * 0.5
		_px(16 + int(cos(a) * 10.0), 18 + bob + int(sin(a) * 10.0), Color("ffd870"))


## init (PID 1): núcleo-procesador con patas de pines y un ojo incandescente.
func _init_core(f: int) -> void:
	var glow: Color = [Color("ff8a3a"), Color("ffb050"), Color("ffd870"), Color("ffb050")][f]
	for k in 5:
		_line(6 + k * 5, 26, 5 + k * 5, 30, Color("c0a060"))   # pines
		_line(6 + k * 5, 6, 5 + k * 5, 2, Color("c0a060"))
	_rect(4, 6, 27, 26, Color("2a2a30"))
	_rect(6, 8, 25, 24, Color("3a3a44"))
	_ellipse(16, 16, 6, 6, glow)
	_ellipse(16, 16, 2.5, 2.5, Color("1a0a08"))
	_line(8, 10, 12, 10, Color("8a8a96"))
	_px(23, 22, glow)

# --- Acto III: el Silicio Profundo ---

## Rootkit: figura encapuchada que flota, con un bastón-prompt «$» que brilla.
func _rootkit(f: int) -> void:
	var hover: int = [0, -1, -2, -1][f]
	var robe := Color("2a1f3a")
	for y in range(10, 27):
		var w := 4 + (y - 10) / 2
		_rect(15 - w, y + hover, 15 + w, y + hover, robe)
	_ellipse(15, 9 + hover, 5, 5, robe.lightened(0.1))
	_ellipse(16, 10 + hover, 3, 3, Color("0a0810"))
	_px(17, 10 + hover, Color("b07aff"))
	_line(24, 6 + hover, 24, 26 + hover, Color("6a5a40"))
	var glow: Color = [Color("7a4ad9"), Color("a06aff"), Color("c08aff"), Color("a06aff")][f]
	_rect(22, 3 + hover, 26, 6 + hover, glow)
	_px(24, 4 + hover, Color.WHITE)
	_line(11, 18 + hover, 19, 18 + hover, Color("7a4ad9"))   # cinturón de código


## Proceso fantasma: espectro pequeño y translúcido con ojos de «?».
func _ghost_process(f: int) -> void:
	var bob: int = [0, -1, 0, 1][f]
	var c := Color(0.75, 0.7, 1.0, 0.75)
	_ellipse(16, 15 + bob, 7, 7, c)
	_rect(9, 15 + bob, 23, 22 + bob, c)
	for k in 4:   # borde ondulado
		var x := 10 + k * 4
		_rect(x, 23 + bob + (k + f) % 2, x + 2, 24 + bob + (k + f) % 2, c)
	_px(13, 14 + bob, Color("1a1430"))
	_px(18, 14 + bob, Color("1a1430"))
	_px(13, 13 + bob, Color("1a1430"))
	_px(18, 13 + bob, Color("1a1430"))


## Centinela del BIOS: pantalla azul flotante con un ojo y antenas.
func _bios_sentinel(f: int) -> void:
	var hover: int = [0, -1, -1, 0][f]
	_rect(6, 7 + hover, 25, 21 + hover, Color("2a3a6a"))
	_rect(8, 9 + hover, 23, 19 + hover, Color("1040b0"))
	for k in 3:
		_line(9, 11 + k * 3 + hover, 13 + k * 3, 11 + k * 3 + hover, Color("d0d8ff"))
	var eye: Color = [Color("5cd0ff"), Color("9ae8ff"), Color("5cd0ff"), Color("2a8aaa")][f]
	_ellipse(19, 14 + hover, 3, 3, eye)
	_px(19, 14 + hover, Color.WHITE)
	_line(9, 7 + hover, 7, 3 + hover, Color("8a8a96"))
	_line(22, 7 + hover, 24, 3 + hover, Color("8a8a96"))
	_rect(13, 22 + hover, 18, 24 + hover, Color("3a3f4a"))   # soporte


## Gusano de firmware: babosa verde hecha de chips, que gotea.
func _firmware_worm(f: int) -> void:
	var wave: int = [0, 1, 0, -1][f]
	var body := Color("3a7a3a")
	for k in 5:
		var x := 6 + k * 4
		_ellipse(x, 21 + (wave if k % 2 == 0 else -wave), 4, 4, body.lightened(k * 0.04))
		_px(x, 19 + (wave if k % 2 == 0 else -wave), Color("c0a060"))   # patita de chip
	_ellipse(26, 19 + wave, 4.5, 4.5, body.lightened(0.2))
	_px(27, 18 + wave, Color("e8ff6a"))
	_px(25, 27, Color("6fd36b"))   # gota
	_px(12, 27 - f % 2, Color("6fd36b"))


## Arco de electromigración: cable de cobre retorcido con chispas.
func _electromigration(f: int) -> void:
	var copper := Color("c87a3a")
	var pts := [[8, 26], [12, 18], [9, 12], [15, 7], [20, 12], [17, 19], [22, 26]]
	for k in pts.size() - 1:
		_line(pts[k][0], pts[k][1], pts[k + 1][0], pts[k + 1][1], copper)
		_line(pts[k][0] + 1, pts[k][1], pts[k + 1][0] + 1, pts[k + 1][1], copper.darkened(0.3))
	var spark: Color = [Color("ffd860"), Color("ff9a3a"), Color("ffffff"), Color("ff9a3a")][f]
	var s: Array = pts[f + 2]
	_px(s[0], s[1] - 2, spark)
	_px(s[0] + 1, s[1] - 3, spark)
	_px(s[0] - 1, s[1] - 1, spark)
	_ellipse(15, 7, 2.5, 2.5, Color("ffd860"))


## Condensador hinchado: cilindro con la tapa abombada a punto de reventar.
func _capacitor(f: int) -> void:
	var bulge: int = [0, 1, 2, 1][f]
	_rect(9, 9, 22, 26, Color("2a4a8a"))
	_rect(9, 9, 11, 26, Color("d0d0d8"))                # franja del polo negativo
	_ellipse(15.5, 9 - bulge * 0.5, 7 + bulge * 0.5, 2 + bulge, Color("a0a0a8"))
	_line(13, 8 - bulge, 18, 8 - bulge, Color("6a6a70"))   # la cruz de la tapa
	_line(15, 6 - bulge, 15, 10, Color("6a6a70"))
	_line(12, 27, 12, 30, Color("c0a060"))
	_line(19, 27, 19, 30, Color("c0a060"))
	_px(20, 15, Color("d0b040"))


## fw_update.exe: chip de memoria flash gigante con una barra de progreso por boca.
func _fw_update(f: int) -> void:
	for k in 6:
		_line(5 + k * 4, 4, 5 + k * 4, 1, Color("c0a060"))
		_line(5 + k * 4, 26, 5 + k * 4, 30, Color("c0a060"))
	_rect(3, 4, 28, 26, Color("1c1c22"))
	_rect(5, 6, 26, 24, Color("2a2a34"))
	var eye: Color = [Color("ff4a3a"), Color("ff8a3a"), Color("ffd060"), Color("ff8a3a")][f]
	_ellipse(11, 11, 2.5, 2.5, eye)
	_ellipse(20, 11, 2.5, 2.5, eye)
	_rect(7, 17, 24, 21, Color("0a0a0e"))
	_rect(8, 18, 8 + 3 + f * 4, 20, Color("3cff6a"))   # la barra de progreso avanza
	_px(26, 6, Color("5cd0ff"))


# --- Acto IV: el Setup de la BIOS ---

## Beep Code: un altavoz del POST con ondas de sonido que laten.
func _beep_code(f: int) -> void:
	var bob: int = [0, -1, 0, 1][f]
	_rect(8, 12 + bob, 14, 22 + bob, Color("3a3a42"))
	for y in range(9, 26):   # cono del altavoz
		var w := (y - 9) / 3
		if y >= 9 + bob and y <= 25 + bob:
			_line(14, y, 14 + mini(w, 6), y, Color("5a5a66"))
	_ellipse(12, 17 + bob, 2, 2, Color("ffe050"))
	for k in (f % 2) + 1:   # ondas
		_line(23 + k * 3, 12 + bob, 25 + k * 3, 17 + bob, Color("ffe050"))
		_line(25 + k * 3, 17 + bob, 23 + k * 3, 22 + bob, Color("ffe050"))


## Jumper suelto: un puente de plástico negro sobre dos pines dorados, saltando.
func _jumper(f: int) -> void:
	var hop: int = [0, -3, -4, -2][f]
	_rect(10, 10 + hop, 21, 20 + hop, Color("1a1a1e"))
	_rect(11, 11 + hop, 20, 13 + hop, Color("3a3a42"))
	_line(13, 21 + hop, 13, 27, Color("d0a040"))
	_line(18, 21 + hop, 18, 27, Color("d0a040"))
	_px(13, 16 + hop, Color("ffffff"))
	_px(18, 16 + hop, Color("ffffff"))


## Pila hinchada: una CR2032 abombada que gotea ácido.
func _swollen_battery(f: int) -> void:
	var swell: int = [0, 1, 2, 1][f]
	_ellipse(16, 18, 10 + swell * 0.5, 8 + swell, Color("b0b0b8"))
	_ellipse(16, 16 - swell * 0.5, 7, 4 + swell * 0.5, Color("d8d8e0"))
	_line(12, 16, 20, 16, Color("8a8a92"))
	_line(16, 13, 16, 19, Color("8a8a92"))   # el «+»
	_px(8, 24 + (f % 2), Color("a0ff60"))
	_px(23, 25 - (f % 2), Color("a0ff60"))


## Sector defectuoso: un cuadro de disco rojo con una X, que parpadea.
func _bad_sector(f: int) -> void:
	var lit := f % 2 == 0
	_rect(7, 9, 24, 26, Color("2a0a0a"))
	_rect(8, 10, 23, 25, Color("aa0000") if lit else Color("6a0000"))
	_line(9, 11, 22, 24, Color("ff5050") if lit else Color("aa2020"))
	_line(22, 11, 9, 24, Color("ff5050") if lit else Color("aa2020"))


## Option ROM: tarjeta de expansión con su chip y conector de pines.
func _option_rom(f: int) -> void:
	_rect(6, 8, 25, 22, Color("1a5a2a"))
	_rect(10, 11, 17, 18, Color("1c1c22"))
	for k in 8:
		_px(7 + k * 2, 24, Color("d0a040"))
		_px(7 + k * 2, 25, Color("d0a040"))
	var c: Color = [Color("55ffff"), Color("5555ff"), Color("ff55ff"), Color("55ff55")][f]
	_rect(19, 11, 22, 14, c)


## Watchdog Timer: un perro de reloj con la cuenta atrás en la panza.
func _watchdog(f: int) -> void:
	var step: int = [0, 1, 0, -1][f]
	_rect(8, 14, 23, 22, Color("6a4a30"))
	_rect(20, 9, 27, 16, Color("7a5a3a"))     # cabeza
	_px(25, 11, Color("ff6a40"))
	_line(8, 14, 5, 11, Color("6a4a30"))        # cola
	for x in [10, 14, 18, 21]:
		_line(x, 23, x + step, 27, Color("4a3220"))
	_rect(11, 16, 17, 20, Color("0a0a0e"))
	_line(12, 18, 12 + f, 18, Color("ff6a40"))   # la cuenta atrás
