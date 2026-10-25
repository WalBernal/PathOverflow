extends SceneTree
## Genera los atlas de PixelIcons (T75): assets/sprites/icons/icons32.png,
## icons16.png y data/pixel_icons.json (clave → índice). Cada glifo (SkillIcon,
## StatusIcon y RamIcon, sin fondo) se pinta en un SubViewport del tamaño final y
## se pasa a pixel art: alfa sin degradados, colores en paleta de 16 niveles por
## canal y contorno oscuro de 1 px. "Arte de programador", como los objetos: para
## usar iconos dibujados a mano, sustituye los PNG manteniendo la cuadrícula.
##
## Necesita ventana (no --headless, que no dibuja):
##   Godot_v4.7.2-stable_win64.exe --path . -s res://tools/generate_pixel_icons.gd

const COLUMNS := 16
const SIZES := [32, 16]
const OUT_DIR := "res://assets/sprites/icons/"
const OUT_JSON := "res://data/pixel_icons.json"
const OUTLINE := Color("0d0b10")
const ALPHA_CUT := 0.4
const LEVELS := 15.0


func _initialize() -> void:
	_run.call_deferred()


## [clave, pintor(ci, rect)] de todos los iconos.
func entries() -> Array:
	var out: Array = []
	var db := ItemDatabase.load_from_dir()
	var skills: Dictionary = db.skills.skills
	for id in skills:
		var def: Dictionary = skills[id]
		out.append(["skill:" + id, func(ci: CanvasItem, r: Rect2) -> void: SkillIcon.draw(ci, r, def, false, false)])
	for id in Ailments.ALL + ["stun", "corrupt", "taunt", "reserve"]:
		out.append(["status:" + id, func(ci: CanvasItem, r: Rect2) -> void: StatusIcon.draw(ci, r, id, r.size.x < 24.0, 1.0, false)])
	var families := {}
	for id in db.skills.rams:
		families[RamModule.family_of(id)] = true
	for fam in families:
		out.append(["ram:" + fam, func(ci: CanvasItem, r: Rect2) -> void: RamIcon.draw_glyph(ci, r, fam, Color.WHITE, true)])
	return out


func _run() -> void:
	var list := entries()
	var map := {}
	for k in list.size():
		map[list[k][0]] = k
	var rows := int(ceil(list.size() / float(COLUMNS)))
	for size: int in SIZES:
		var atlas := Image.create(COLUMNS * size, rows * size, false, Image.FORMAT_RGBA8)
		for k in list.size():
			var img := await _render(list[k][1], size)
			atlas.blit_rect(pixelate(img), Rect2i(0, 0, size, size), Vector2i((k % COLUMNS) * size, (k / COLUMNS) * size))
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT_DIR))
		atlas.save_png(OUT_DIR + "icons%d.png" % size)
	var f := FileAccess.open(OUT_JSON, FileAccess.WRITE)
	f.store_string(JSON.stringify({"_doc": "Generado por tools/generate_pixel_icons.gd: clave → índice en icons32.png / icons16.png.",
		"columns": COLUMNS, "icons": map}, "\t"))
	f.close()
	print("iconos: %d" % list.size())
	quit()


func _render(painter: Callable, size: int) -> Image:
	var vp := SubViewport.new()
	vp.size = Vector2i(size, size)
	vp.transparent_bg = true
	vp.render_target_update_mode = SubViewport.UPDATE_ONCE
	var canvas := Control.new()
	canvas.size = Vector2(size, size)
	var margin := 1.0 if size <= 16 else 2.0
	canvas.draw.connect(func() -> void: painter.call(canvas, Rect2(margin, margin, size - 2.0 * margin, size - 2.0 * margin)))
	vp.add_child(canvas)
	root.add_child(vp)
	await process_frame
	await process_frame
	await process_frame
	var img := vp.get_texture().get_image()
	vp.queue_free()
	img.convert(Image.FORMAT_RGBA8)
	return img


## A pixel art: alfa todo o nada, paleta reducida y contorno de 1 px alrededor.
static func pixelate(src: Image) -> Image:
	var w := src.get_width()
	var h := src.get_height()
	var out := Image.create(w, h, false, Image.FORMAT_RGBA8)
	var solid := PackedByteArray()
	solid.resize(w * h)
	for y in h:
		for x in w:
			var c := src.get_pixel(x, y)
			if c.a >= ALPHA_CUT:
				# Sin premultiplicar: el color real del píxel semitransparente del borde.
				var q := Color(snappedf(clampf(c.r / maxf(c.a, 0.01), 0.0, 1.0), 1.0 / LEVELS), snappedf(clampf(c.g / maxf(c.a, 0.01), 0.0, 1.0), 1.0 / LEVELS),
					snappedf(clampf(c.b / maxf(c.a, 0.01), 0.0, 1.0), 1.0 / LEVELS), 1.0)
				out.set_pixel(x, y, q)
				solid[y * w + x] = 1
	for y in h:
		for x in w:
			if solid[y * w + x] == 1:
				continue
			for d in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
				var nx: int = x + d.x
				var ny: int = y + d.y
				if nx >= 0 and ny >= 0 and nx < w and ny < h and solid[ny * w + nx] == 1:
					out.set_pixel(x, y, OUTLINE)
					break
	return out
