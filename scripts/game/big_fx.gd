class_name BigFx
extends Node2D
## Efectos grandes con partículas de GPU (T98): cada explosión o nova de las
## habilidades (SkillController.burst_effects) suelta una ráfaga de GPUParticles2D
## de su color hacia fuera. Respeta el presupuesto de partículas de la calidad
## gráfica (GraphicsQuality): en baja no hay, y si no cabe una ráfaga, no sale.

const LIFETIME := 0.65

var skills: SkillController
var _live: Array[Dictionary] = []   # {node, amount, until}
var _time := 0.0


## Partículas de una ráfaga según su radio (más grande, más), dentro de unos límites.
static func burst_amount(radius: float) -> int:
	return clampi(roundi(radius * 0.5), 16, 110)


func live_particles() -> int:
	var total := 0
	for l in _live:
		total += int(l["amount"])
	return total


func _process(delta: float) -> void:
	_time += delta
	for k in range(_live.size() - 1, -1, -1):
		if _time >= float(_live[k]["until"]):
			(_live[k]["node"] as Node).queue_free()
			_live.remove_at(k)
	if skills == null:
		return
	for e in skills.burst_effects():
		e["big_fx"] = true   # una sola ráfaga por efecto
		spawn_burst(e["pos"], float(e["radius"]), e["color"])


## Suelta una ráfaga en `pos` si cabe en el presupuesto. Devuelve si salió.
func spawn_burst(pos: Vector2, radius: float, color: Color) -> bool:
	var amount := burst_amount(radius)
	if not GraphicsQuality.fits_particles(live_particles(), amount):
		return false
	var p := GPUParticles2D.new()
	p.amount = amount
	p.lifetime = LIFETIME
	p.one_shot = true
	p.explosiveness = 0.92
	p.local_coords = false
	p.position = pos
	var m := ParticleProcessMaterial.new()
	m.direction = Vector3(1, 0, 0)
	m.spread = 180.0
	m.gravity = Vector3.ZERO
	m.initial_velocity_min = radius * 1.4
	m.initial_velocity_max = radius * 2.6
	m.damping_min = radius * 1.5
	m.damping_max = radius * 2.5
	m.scale_min = 2.0
	m.scale_max = 4.5
	m.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	m.emission_sphere_radius = radius * 0.15
	var ramp := Gradient.new()
	ramp.set_color(0, Color(color.lightened(0.5), 1.0))
	ramp.set_color(1, Color(color, 0.0))
	var tex := GradientTexture1D.new()
	tex.gradient = ramp
	m.color_ramp = tex
	p.process_material = m
	add_child(p)
	p.emitting = true
	_live.append({"node": p, "amount": amount, "until": _time + LIFETIME + 0.2})
	return true
