class_name SkillFx
## Firma visual de cada habilidad (T74): forma del proyectil, estela, destello al
## lanzar y estallido al golpear, en la rejilla de 2 px. Las habilidades sin firma
## propia usan la de su tipo de daño, así que de lejos ya se distingue un ping
## (rayo en zigzag) de un paquete (rectángulo con cabecera) o de una bola de fuego.
## Las partículas las pone ImpactFx (respeta «Menos destellos» y su tope); con
## muchos enemigos en pantalla, versión ligera: sin estelas y formas simples.

const GRID := 2.0
## Por tipo de daño: proyectil, estela, lanzamiento e impacto.
const BY_TYPE := {
	"fire": {"projectile": "fireball", "trail": "embers", "cast": "flare", "impact": "splash"},
	"cold": {"projectile": "shard", "trail": "frost", "cast": "frost", "impact": "shatter"},
	"lightning": {"projectile": "bolt", "trail": "sparks", "cast": "spark", "impact": "zapburst"},
	"chaos": {"projectile": "glob", "trail": "drips", "cast": "glitch", "impact": "splat"},
	"physical": {"projectile": "orb", "trail": "bits", "cast": "flick", "impact": "shards"},
}
## Las que tienen forma propia (lo que no ponen, lo toman de su tipo de daño).
const SIGNATURES := {
	"rafaga_de_paquetes": {"projectile": "packet"},
	"paquete_rastreador": {"projectile": "tracker", "trail": "dots"},
	"corrupcion_datos": {"projectile": "glitch"},
	"ping_letal": {"projectile": "bolt", "cast": "spark"},
	"torreta_ci": {"projectile": "bolt"},
	"cascada_css": {"projectile": "shard"},
}
## Cada cuánto suelta una partícula de estela un proyectil (s).
const TRAIL_EVERY := 0.035


## Firma de la habilidad del perfil `p`: {projectile, trail, cast, impact}.
static func signature(p: Dictionary) -> Dictionary:
	var dtype := String(p.get("damage_type", "physical"))
	var sig: Dictionary = BY_TYPE.get(dtype, BY_TYPE["physical"]).duplicate()
	sig.merge(SIGNATURES.get(String(p.get("id", "")), {}), true)
	return sig


static func _snap(v: Vector2) -> Vector2:
	return v.snapped(Vector2(GRID, GRID))


## Dibuja un proyectil con su forma. `light`: versión simple (muchos enemigos);
## `dim`: sin núcleos blancos (Menos destellos).
static func draw_projectile(ci: CanvasItem, pos: Vector2, dir: Vector2, color: Color, shape: String, time: float, light := false, dim := false) -> void:
	var at := _snap(pos)
	var core := color.lightened(0.25) if dim else color.lightened(0.6)
	if light:
		ci.draw_line(at - dir * 14.0, at, Color(color, 0.5), 4.0)
		ci.draw_rect(Rect2(at - Vector2(3, 3), Vector2(6, 6)), color)
		return
	var side := dir.orthogonal()
	match shape:
		"fireball":
			# Núcleo y llamitas de píxeles que tiemblan detrás.
			for k in 4:
				var jitter := Vector2(sin(time * 31.0 + k * 1.7), cos(time * 27.0 + k * 2.3)) * 2.5
				var q := _snap(at - dir * (4.0 + k * 4.0) + side * jitter.x + Vector2(0, jitter.y))
				var s := 6.0 - k
				ci.draw_rect(Rect2(q - Vector2(s, s) * 0.5, Vector2(s, s)), Color("ff8a2a" if k % 2 == 0 else "e0452f", 0.9 - k * 0.18))
			ci.draw_circle(at, 6.0, color)
			ci.draw_circle(at, 3.0, core)
		"shard":
			# Esquirla de hielo alargada con el filo claro.
			var tip := at + dir * 9.0
			var tail := at - dir * 9.0
			ci.draw_colored_polygon(PackedVector2Array([tip, at + side * 4.0, tail, at - side * 4.0]), color)
			ci.draw_line(tail, tip, Color(core, 0.9), 1.5)
			ci.draw_line(tail - dir * 6.0, tail, Color(color, 0.35), 3.0)
		"bolt":
			# Chispazo en zigzag que cambia de forma cada pocos cuadros.
			var pts := PackedVector2Array([at])
			var step := int(time * 30.0)
			for k in range(1, 5):
				var wob := sin(float(step + k) * 12.9898) * 5.0
				pts.append(_snap(at - dir * k * 6.0 + side * wob))
			ci.draw_polyline(pts, Color(color, 0.45), 5.0)
			ci.draw_polyline(pts, core, 2.0)
			ci.draw_rect(Rect2(at - Vector2(3, 3), Vector2(6, 6)), core)
		"glob":
			# Gota de caos que escurre.
			ci.draw_circle(at, 7.0, Color(color, 0.55))
			ci.draw_circle(at - dir * 2.0, 4.0, color)
			for k in 2:
				var drip := fmod(time * 2.0 + k * 0.5, 1.0)
				ci.draw_rect(Rect2(_snap(at + Vector2(-3 + k * 4, 4 + drip * 8.0)), Vector2(2, 2 + 2 * (1.0 - drip))), Color(color, 1.0 - drip))
		"glitch":
			ci.draw_circle(at, 7.0, Color(color, 0.6))
			ci.draw_rect(Rect2(at - Vector2(5, 2) + side * sin(time * 50.0) * 3.0, Vector2(10, 4)), Color(0.3, 1.0, 0.6, 0.7))
		"packet", "tracker":
			# Paquete: rectángulo en la dirección del vuelo con la cabecera más clara.
			# (Puntos girados a mano: sin draw_set_transform, que pisaría la transformación de quien dibuja.)
			var local := func(x: float, y: float) -> Vector2: return at + dir * x + side * y
			var quad := func(x0: float, x1: float, y0: float, y1: float) -> PackedVector2Array:
				return PackedVector2Array([local.call(x0, y0), local.call(x1, y0), local.call(x1, y1), local.call(x0, y1)])
			ci.draw_line(local.call(-22, 0), local.call(-6, 0), Color(color, 0.35), 3.0)
			ci.draw_colored_polygon(quad.call(-6, 6, -4, 4), color.darkened(0.2))
			ci.draw_colored_polygon(quad.call(2, 6, -4, 4), core)
			if shape == "tracker" and fmod(time * 4.0, 1.0) < 0.5:
				ci.draw_colored_polygon(quad.call(-4, -2, -8, -4), Color("ff6a6a"))   # la antena que parpadea
		_:
			ci.draw_line(at - dir * 18.0, at, Color(color, 0.5), 4.0, true)
			ci.draw_circle(at, 5.0, color)
