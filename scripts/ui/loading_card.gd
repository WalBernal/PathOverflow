class_name LoadingCard
extends CanvasLayer
## Pantalla de carga entre zonas (T96): una ilustración de la zona (procedural, con
## los colores de su estilo y una silueta según su borde: racks, acantilados, agua,
## muros, lava, árboles o vacío), su nombre y un consejo. Aparece al viajar, se
## queda un momento y se desvanece. T168: con el estilo del panel de datos y, debajo,
## un registro de arranque («compilando zona… OK») con su progreso de 0 a 100 %.

## Pasos del registro de arranque; cada uno se marca OK al llegar el progreso a su parte.
const BOOT_STEPS := ["montando el sistema de archivos de la zona", "compilando zona", "cargando procesos hostiles",
	"sembrando botín en la memoria", "enlazando waypoints"]

const TIPS_PATH := "res://data/loading_tips.json"
const HOLD := 0.75
const FADE := 0.45
## Las capturas la apagan para no tapar lo que quieren fotografiar.
static var enabled := true
static var _tips: Array = []

var zone_name := ""
var subtitle := ""
var style := ""
var tip := ""
var _t := 0.0
var _rect: Control
var _seed := 0


static func tips() -> Array:
	if _tips.is_empty() and FileAccess.file_exists(TIPS_PATH):
		var data = JSON.parse_string(FileAccess.get_file_as_string(TIPS_PATH))
		if data is Dictionary:
			_tips = data.get("tips", [])
	return _tips


## Consejo para una visita: cambia de una zona a otra, pero es fijo para la misma semilla.
static func tip_for(seed_value: int) -> String:
	var all := tips()
	return "" if all.is_empty() else String(all[posmod(seed_value, all.size())])


## Silueta de la ilustración según el borde de la zona (Zone.STYLES[style].edge).
static func silhouette_for(style_id: String) -> String:
	var edge := String(Zone.STYLES.get(style_id, {}).get("edge", ""))
	match edge:
		"racks": return "racks"
		"cliff": return "mountains"
		"water": return "waves"
		"wall": return "arches"
		"lava": return "lava"
		"thicket": return "trees"
		"void": return "stars"
	return "tents"


## Progreso de la carga (0..100 %) en el instante `t`: se llena durante HOLD.
static func progress_at(t: float) -> int:
	return clampi(roundi(t / HOLD * 100.0), 0, 100)


## Líneas del registro de arranque con un progreso: las ya hechas con «[ OK ]», la que
## está en marcha con «[ .. ]»; al 100 %, todas OK y «listo».
static func boot_lines(zone: String, progress: int) -> Array:
	var out := []
	var n := BOOT_STEPS.size()
	for k in n:
		var start := k * 100 / n
		if progress < start:
			break
		var done := progress >= (k + 1) * 100 / n
		var text := String(BOOT_STEPS[k]) + (": " + zone if k == 1 else "") + ("… OK" if done else "…")
		out.append(["OK" if done else "..", text])
	if progress >= 100:
		out.append(["OK", "listo (100 %)"])
	return out


## Opacidad en el instante `t`: entera durante HOLD y luego se desvanece en FADE.
static func alpha_at(t: float) -> float:
	return 1.0 if t <= HOLD else clampf(1.0 - (t - HOLD) / FADE, 0.0, 1.0)


func _ready() -> void:
	layer = 110
	_seed = hash(zone_name)
	if tip == "":
		tip = tip_for(_seed + Time.get_ticks_msec() / 1000)
	_rect = Control.new()
	_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_rect.draw.connect(_draw_card)
	add_child(_rect)


func _process(delta: float) -> void:
	_t += delta
	if _t >= HOLD + FADE:
		queue_free()
		return
	_rect.modulate.a = alpha_at(_t)
	_rect.queue_redraw()


func _draw_card() -> void:
	var view := _rect.size
	var colors: Dictionary = Zone.STYLES.get(style, {"ground": "1c1922", "outside": "07060a"})
	var sky := Color(colors.get("outside", "07060a"))
	var ground := Color(colors.get("ground", "1c1922"))
	UiStyle.draw_background(_rect, view)
	# Ilustración: una postal ancha arriba, en una tarjeta.
	var art := Rect2(Vector2(view.x * 0.14, view.y * 0.08), Vector2(view.x * 0.72, view.y * 0.42))
	var card := StyleBoxFlat.new()
	card.bg_color = UiStyle.PANEL
	card.border_color = UiStyle.BORDER
	card.set_border_width_all(1)
	card.set_corner_radius_all(UiStyle.RADIUS)
	card.shadow_color = Color(0, 0, 0, 0.5)
	card.shadow_size = 12
	_rect.draw_style_box(card, art.grow(10.0))
	for k in 24:
		var y := art.position.y + art.size.y * k / 24.0
		_rect.draw_rect(Rect2(art.position.x, y, art.size.x, art.size.y / 24.0 + 1.0), sky.lerp(ground.lightened(0.12), float(k) / 23.0))
	_draw_silhouette(art, ground)
	for k in 6:   # viñeta
		_rect.draw_rect(art.grow(-k * 3.0), Color(0, 0, 0, 0.12), false, 3.0)
	_rect.draw_rect(Rect2(art.position + Vector2(0, -10), Vector2(64, 3)), UiStyle.ACCENT)
	UiStyle.draw_graph_motif(_rect, art.end + Vector2(-8, -10))
	var font := _rect.get_theme_default_font()
	var mono := UiStyle.mono_font()
	var title_y := art.end.y + 56.0
	_rect.draw_string_outline(font, Vector2(0, title_y), zone_name, HORIZONTAL_ALIGNMENT_CENTER, view.x, 38, 8, Color.BLACK)
	_rect.draw_string(font, Vector2(0, title_y), zone_name, HORIZONTAL_ALIGNMENT_CENTER, view.x, 38, UiStyle.TEXT)
	if subtitle != "":
		_rect.draw_string(font, Vector2(0, title_y + 28.0), subtitle, HORIZONTAL_ALIGNMENT_CENTER, view.x, 17, UiStyle.MUTED)
	# Registro de arranque (T168), en una consola.
	var progress := progress_at(_t)
	var log_box := Rect2(view.x * 0.27, title_y + 46.0, view.x * 0.46, 26.0 + 20.0 * (BOOT_STEPS.size() + 1))
	card.bg_color = Color(UiStyle.BG, 0.92)
	card.shadow_size = 0
	card.set_corner_radius_all(8)
	_rect.draw_style_box(card, log_box)
	var y := log_box.position.y + 24.0
	for line in boot_lines(zone_name, progress):
		var ok: bool = line[0] == "OK"
		_rect.draw_string(mono, Vector2(log_box.position.x + 14.0, y), "[%s]" % ("  OK  " if ok else "  ..  "), HORIZONTAL_ALIGNMENT_LEFT, -1, 14, UiStyle.OK if ok else UiStyle.WARN)
		_rect.draw_string(mono, Vector2(log_box.position.x + 90.0, y), String(line[1]), HORIZONTAL_ALIGNMENT_LEFT, log_box.size.x - 100.0, 14, UiStyle.TEXT if ok else UiStyle.MUTED)
		y += 20.0
	if tip != "":
		_rect.draw_string(font, Vector2(view.x * 0.15, view.y - 62.0), "// consejo: " + tip, HORIZONTAL_ALIGNMENT_CENTER, view.x * 0.7, 16, UiStyle.MUTED)
	# Barra de progreso redondeada con su porcentaje.
	var bar := Rect2(view.x * 0.32, view.y - 36.0, view.x * 0.32, 8.0)
	var track := StyleBoxFlat.new()
	track.bg_color = UiStyle.PANEL_LIGHT
	track.set_corner_radius_all(4)
	_rect.draw_style_box(track, bar)
	if progress > 0:
		track.bg_color = UiStyle.ACCENT
		_rect.draw_style_box(track, Rect2(bar.position, Vector2(maxf(8.0, bar.size.x * progress / 100.0), bar.size.y)))
	_rect.draw_string(mono, Vector2(bar.end.x + 12.0, bar.end.y + 1.0), "%d %%" % progress, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, UiStyle.ACCENT)


## Silueta en primer plano según el tipo de zona, siempre la misma para la misma zona.
func _draw_silhouette(art: Rect2, ground: Color) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = _seed
	var dark := ground.darkened(0.6)
	var base_y := art.end.y
	match silhouette_for(style):
		"racks":
			var x := art.position.x
			while x < art.end.x:
				var w := rng.randf_range(40, 80)
				var h := rng.randf_range(0.3, 0.7) * art.size.y
				_rect.draw_rect(Rect2(x, base_y - h, w, h), dark)
				for r in int(h / 14.0):
					if rng.randf() < 0.6:
						_rect.draw_rect(Rect2(x + w - 12, base_y - h + 6 + r * 14, 4, 3), Color(0.3, 1.0, 0.5, 0.7))
				x += w + rng.randf_range(4, 18)
		"mountains", "arches":
			var pts := PackedVector2Array([Vector2(art.position.x, base_y)])
			var steps := 9
			for k in steps + 1:
				var px := art.position.x + art.size.x * k / steps
				pts.append(Vector2(px, base_y - rng.randf_range(0.25, 0.6) * art.size.y))
			pts.append(Vector2(art.end.x, base_y))
			_rect.draw_colored_polygon(pts, dark)
			if silhouette_for(style) == "arches":
				for k in 4:
					var cx := art.position.x + art.size.x * (k + 0.5) / 4.0
					_rect.draw_circle(Vector2(cx, base_y - art.size.y * 0.18), art.size.y * 0.12, ground.darkened(0.2))
		"waves", "lava":
			var glow := Color(1.0, 0.45, 0.15, 0.8) if silhouette_for(style) == "lava" else Color(0.5, 0.8, 1.0, 0.35)
			for row in 5:
				var y := base_y - art.size.y * 0.06 * (row + 1)
				var pts := PackedVector2Array()
				for k in 41:
					var px := art.position.x + art.size.x * k / 40.0
					pts.append(Vector2(px, y + sin(k * 0.7 + row + _t * 2.0) * 4.0))
				_rect.draw_polyline(pts, Color(glow, glow.a * (1.0 - row * 0.18)), 2.0, true)
			_rect.draw_rect(Rect2(art.position.x, base_y - art.size.y * 0.05, art.size.x, art.size.y * 0.05), dark)
		"trees":
			for k in 14:
				var px := art.position.x + rng.randf() * art.size.x
				var h := rng.randf_range(0.3, 0.75) * art.size.y
				_rect.draw_colored_polygon(PackedVector2Array([Vector2(px - h * 0.22, base_y), Vector2(px, base_y - h), Vector2(px + h * 0.22, base_y)]), dark)
		"stars":
			for k in 90:
				var p := art.position + Vector2(rng.randf() * art.size.x, rng.randf() * art.size.y * 0.8)
				_rect.draw_rect(Rect2(p, Vector2(2, 2)), Color(0.8, 0.85, 1.0, rng.randf_range(0.2, 0.9)))
			_rect.draw_rect(Rect2(art.position.x, base_y - art.size.y * 0.1, art.size.x, art.size.y * 0.1), dark)
		_:
			for k in 5:
				var px := art.position.x + art.size.x * (k + 0.5) / 5.0
				var h := art.size.y * 0.3
				_rect.draw_colored_polygon(PackedVector2Array([Vector2(px - h * 0.6, base_y), Vector2(px, base_y - h), Vector2(px + h * 0.6, base_y)]), dark)
			_rect.draw_circle(Vector2(art.get_center().x, base_y - art.size.y * 0.06), art.size.y * 0.05, Color(1.0, 0.6, 0.2, 0.9))
