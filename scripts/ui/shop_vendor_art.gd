class_name ShopVendorArt
extends Control
## El comerciante dibujado en la tienda (T71), en pixel art a mano: Nacho con su
## gabardina (cerrada, entreabierta y abierta de par en par, con la mercancía
## colgando del forro) o Aída detrás de su puesto ordenado. Al abrir la tienda
## pasa por los tres cuadros y suena la tela; al hablar mueve la boca.

const PX := 4.0
const GRID := Vector2i(26, 42)
const FRAMES := 3
const FRAME_TIME := 0.09
## Colores (Nacho: los de su aspecto en npcs.json; la gabardina, algo más clara para que se lea).
const SKIN := Color("c68642")
const HAIR := Color("2a1d14")
const COAT := Color("8a6233")
const COAT_DARK := Color("5e4120")
const COAT_LIGHT := Color("a87b45")
const LINING := Color("4a2353")
const LINING_DARK := Color("33173a")
const SHIRT := Color("c9c2b0")
const HAT := Color("3b2c1e")
const GOLD := Color("f2c14e")
const AIDA_SKIN := Color("e0ac69")
const AIDA_HAIR := Color("3a2418")
const AIDA_TOP := Color("3f6e8c")
const WOOD := Color("6b4a2b")
const FELT := Color("2f5d3a")

var vendor := "nacho"
## 0 = gabardina cerrada, 1 = entreabierta, 2 = abierta (Aída: la mano baja, a media altura, arriba).
var frame := 2:
	set(v):
		frame = clampi(v, 0, FRAMES - 1)
		queue_redraw()
var talking := false:
	set(v):
		talking = v
		queue_redraw()
var _talk_tween: Tween

static var _cloth_cache: Dictionary = {}


func _init() -> void:
	custom_minimum_size = Vector2(GRID) * PX
	mouse_filter = Control.MOUSE_FILTER_IGNORE


## Abre la gabardina (o el puesto): tres cuadros y el sonido de la tela.
func play_open() -> void:
	if vendor == "nacho":
		play_cloth(true)
	if not is_inside_tree():
		frame = FRAMES - 1
		return
	frame = 0
	var tw := create_tween()
	for f in range(1, FRAMES):
		tw.tween_interval(FRAME_TIME)
		tw.tween_callback(func() -> void: frame = f)


## Mueve la boca un rato (lo que dura la frase, más o menos).
func talk(seconds := 0.9) -> void:
	if _talk_tween:
		_talk_tween.kill()
	talking = true
	if not is_inside_tree():
		talking = false
		return
	_talk_tween = create_tween()
	var steps := int(seconds / 0.12)
	for k in steps:
		_talk_tween.tween_interval(0.12)
		_talk_tween.tween_callback(func() -> void: talking = not talking)
	_talk_tween.tween_callback(func() -> void: talking = false)


func _draw() -> void:
	if vendor == "aida":
		_draw_aida()
	else:
		_draw_nacho()


func _px(x: float, y: float, w: float, h: float, c: Color) -> void:
	draw_rect(Rect2(x * PX, y * PX, w * PX, h * PX), c)


func _draw_nacho() -> void:
	# Sombrero, cara con gafas de sol, barba de tres días y media sonrisa.
	_px(8, 1, 10, 3, HAT)
	_px(8, 3, 10, 1, Color("7a2a2a"))
	_px(6, 4, 14, 1, HAT)
	_px(9, 5, 8, 7, SKIN)
	_px(8, 5, 1, 4, HAIR)
	_px(17, 5, 1, 4, HAIR)
	_px(9, 7, 3, 2, Color("111111"))
	_px(14, 7, 3, 2, Color("111111"))
	_px(12, 7, 2, 1, Color("111111"))
	_px(10, 7, 1, 1, Color("8899aa"))
	_px(10, 10, 6, 2, SKIN.darkened(0.25))
	if talking:
		_px(12, 10, 3, 2, Color("3a1010"))
	else:
		_px(12, 10, 3, 1, Color("3a1010"))
		_px(15, 9, 1, 1, Color("3a1010"))
	_px(11, 12, 4, 1, SKIN.darkened(0.1))
	# Piernas y zapatos (iguales en los tres cuadros).
	_px(8, 38, 4, 3, Color("2b2b38"))
	_px(14, 38, 4, 3, Color("2b2b38"))
	_px(7, 41, 5, 1, Color("1a1410"))
	_px(14, 41, 5, 1, Color("1a1410"))
	match frame:
		0:
			_px(6, 13, 14, 25, COAT)
			_px(12, 16, 1, 22, COAT_DARK)
			_px(8, 13, 3, 3, COAT_LIGHT)
			_px(15, 13, 3, 3, COAT_LIGHT)
			_px(6, 26, 14, 2, COAT_DARK)
			_px(12, 26, 2, 2, GOLD)
			for y in [18, 22, 31]:
				_px(10, y, 1, 1, COAT_DARK)
				_px(15, y, 1, 1, COAT_DARK)
			_px(4, 14, 2, 18, COAT)
			_px(20, 14, 2, 18, COAT)
			_px(4, 32, 2, 2, SKIN)
			_px(20, 32, 2, 2, SKIN)
		1:
			_px(6, 13, 14, 25, COAT)
			_px(8, 15, 2, 23, LINING)
			_px(16, 15, 2, 23, LINING)
			_px(10, 14, 6, 24, SHIRT)
			_px(10, 26, 6, 2, COAT_DARK)
			_px(8, 13, 3, 2, COAT_LIGHT)
			_px(15, 13, 3, 2, COAT_LIGHT)
			_px(8, 19, 2, 1, GOLD)      # algo brilla dentro
			_px(16, 23, 2, 1, Color("6fd36b"))
			_px(4, 14, 2, 16, COAT)
			_px(20, 14, 2, 16, COAT)
			_px(5, 30, 3, 2, SKIN)      # las manos agarran los bordes
			_px(18, 30, 3, 2, SKIN)
		_:
			# Abierta de par en par: los brazos estiran las solapas y el forro enseña la mercancía.
			_px(9, 13, 8, 2, COAT)
			_px(10, 15, 6, 23, SHIRT)
			_px(10, 26, 6, 2, COAT_DARK)
			_px(1, 12, 8, 2, COAT)
			_px(17, 12, 8, 2, COAT)
			_px(0, 12, 1, 2, SKIN)
			_px(25, 12, 1, 2, SKIN)
			for side in [0, 17]:
				_px(side, 14, 9, 24, COAT)
				_px(side + 1, 14, 7, 23, LINING)
				_px(side + 1, 36, 7, 1, LINING_DARK)
			# Lo que cuelga: RAM en el lado izquierdo, placas y relojes a la derecha.
			for y in [16, 21]:
				_px(3, y - 1, 1, 1, Color("9a9aa8"))   # gancho
				_px(2, y, 5, 2, Color("2f8a4a"))
				_px(2, y + 2, 5, 1, GOLD)
			_px(3, 26, 1, 1, Color("9a9aa8"))
			_px(2, 27, 5, 4, Color("2a4d7a"))
			_px(3, 28, 2, 2, Color("111111"))
			_px(2, 33, 5, 2, LINING_DARK)            # bolsillo
			for y in [16, 20, 24]:
				_px(21, y - 1, 1, 1, Color("9a9aa8"))
				_px(20, y, 3, 2, GOLD if y != 20 else Color("c0c0c8"))
			_px(19, 28, 5, 3, Color("2a4d7a"))
			_px(20, 29, 1, 1, Color("e06c6c"))
			_px(19, 33, 5, 2, LINING_DARK)


func _draw_aida() -> void:
	# Toldo de rayas, Aída con coleta y gafas, y la mesa con el equipo bien puesto.
	for k in 13:
		_px(k * 2, 0, 2, 3, Color("c94c4c") if k % 2 == 0 else Color("e8e0d0"))
	_px(0, 3, 26, 1, Color("8a3030"))
	_px(9, 7, 8, 7, AIDA_SKIN)
	_px(8, 6, 10, 2, AIDA_HAIR)
	_px(8, 8, 1, 5, AIDA_HAIR)
	_px(17, 8, 2, 7, AIDA_HAIR)
	_px(10, 9, 2, 2, Color("222222"))
	_px(14, 9, 2, 2, Color("222222"))
	_px(12, 9, 2, 1, Color("222222"))
	_px(12, 12, 2, 1 if not talking else 2, Color("7a2a2a"))
	_px(11, 14, 4, 1, AIDA_SKIN.darkened(0.1))
	_px(7, 15, 12, 14, AIDA_TOP)
	_px(11, 15, 4, 2, AIDA_TOP.lightened(0.2))
	_px(5, 16, 2, 10, AIDA_TOP)
	var hand_y := 26 - frame * 5   # 26, 21, 16: se ajusta las gafas
	_px(19, hand_y, 2, 26 - hand_y + 2, AIDA_TOP)
	_px(19, hand_y - 1, 2, 2, AIDA_SKIN)
	_px(5, 26, 2, 2, AIDA_SKIN)
	_px(0, 29, 26, 3, FELT)
	_px(0, 32, 26, 2, WOOD)
	_px(1, 34, 2, 8, WOOD)
	_px(23, 34, 2, 8, WOOD)
	# Equipo alineado: casco, guantes, botas, anillo.
	_px(2, 26, 4, 3, Color("8d8d99"))
	_px(8, 27, 3, 2, Color("6b4a2b"))
	_px(15, 27, 4, 2, Color("4a3a2a"))
	_px(21, 27, 2, 2, GOLD)


## Sonido de tela (sintetizado: ruido filtrado con un barrido) al abrir o cerrar la gabardina.
static func cloth_stream(opening: bool) -> AudioStreamWAV:
	if _cloth_cache.has(opening):
		return _cloth_cache[opening]
	var rate := 22050
	var n := int(rate * 0.3)
	var data := PackedByteArray()
	data.resize(n * 2)
	var rng := RandomNumberGenerator.new()
	rng.seed = 71 if opening else 17
	var lp := 0.0
	for i in n:
		var t := float(i) / n
		var env := sin(PI * t) * (0.6 + 0.4 * sin(TAU * 3.0 * t))   # dos o tres frufrús
		var cutoff := lerpf(0.06, 0.3, t if opening else 1.0 - t)
		lp += (rng.randf_range(-1.0, 1.0) - lp) * cutoff
		data.encode_s16(i * 2, int(clampf(lp * env * 1.6, -1.0, 1.0) * 20000.0))
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = rate
	wav.data = data
	_cloth_cache[opening] = wav
	return wav


static func play_cloth(opening: bool) -> void:
	var volume := Sfx.sfx_volume()
	if not Sfx.sfx_enabled() or volume <= 0.001:
		return
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null or tree.root == null:
		return
	var p := AudioStreamPlayer.new()
	p.stream = cloth_stream(opening)
	p.volume_db = -8.0 + linear_to_db(volume)
	p.process_mode = Node.PROCESS_MODE_ALWAYS
	tree.root.add_child(p)
	p.finished.connect(p.queue_free)
	p.play()
