class_name PlayerSprite
extends Node2D
## El personaje dibujado con las hojas por capas (T102a, PlayerSheet): cuerpo,
## detalles fijos, arma, pelo, barba y accesorio, uno encima de otro, teñidos con
## los colores del creador (shader player_layers). Sus pies van en (0, 0).
## Uso: `appearance = …` y, cada fotograma, `set_pose(facing, pose, walk_phase)`.

const SHADER := preload("res://assets/shaders/player_layers.gdshader")
## Orden de dibujo: [capa, es máscara].
const ORDER := [["body", true], ["body_fixed", false], ["weapon", false], ["hair", true], ["beard", true],
	["accessory", true], ["accessory_fixed", false]]

var appearance: Dictionary = CharacterAppearance.default():
	set(value):
		appearance = CharacterAppearance.sanitize(value)
		_apply_palette()
var tint := Color(0, 0, 0, 0):
	set(value):
		tint = value
		for l in _layers:
			(l.material as ShaderMaterial).set_shader_parameter("tint", value)
var sprite_scale := 1.0

var _layers: Array[_Layer] = []
var _facing := Vector2.DOWN
var _pose := {}
var _walk := -1.0
static var _textures := {}


static func texture_of(layer: String) -> Texture2D:
	if not _textures.has(layer):
		var path := PlayerSheet.DIR_PATH + layer + ".png"
		_textures[layer] = load(path) if ResourceLoader.exists(path) else null
	return _textures[layer]


## ¿Están horneadas las hojas? (Sin ellas, quien lo use dibuja como siempre.)
static func available() -> bool:
	return texture_of("body") != null


func _ready() -> void:
	for entry in ORDER:
		var l := _Layer.new()
		l.name = entry[0]
		l.texture = texture_of(entry[0])
		var m := ShaderMaterial.new()
		m.shader = SHADER
		m.set_shader_parameter("mask", entry[1])
		l.material = m
		l.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		add_child(l)
		_layers.append(l)
	_apply_palette()
	set_pose(_facing, _pose, _walk)


func _apply_palette() -> void:
	for l in _layers:
		var m := l.material as ShaderMaterial
		m.set_shader_parameter("skin", Color(appearance["skin_tone"]))
		m.set_shader_parameter("outfit", Color(appearance["outfit_color"]))
		m.set_shader_parameter("accent", Color(appearance["accent_color"]))
		m.set_shader_parameter("hair", Color(appearance.get("beard_color", appearance["hair_color"])) if String(l.name) == "beard" else Color(appearance["hair_color"]))
		m.set_shader_parameter("eyes", Color(appearance["eye_color"]))
	_refresh()


## Pose del dibujo de siempre (CharacterAppearance.draw): estado, avance, tiempo y arma.
func set_pose(facing: Vector2, pose: Dictionary, walk_phase := -1.0) -> void:
	_facing = facing
	_pose = pose
	_walk = walk_phase
	_refresh()


## Qué celda de cada capa toca ahora: [variante o -1 si no se dibuja, dirección, columna, voltear].
func cells() -> Dictionary:
	var d: Array = PlayerSheet.dir_for(_facing)
	var weapon := String(_pose.get("weapon", ""))
	var col := PlayerSheet.column_for(String(_pose.get("state", "idle")), weapon, float(_pose.get("t", 0.0)), float(_pose.get("time", 0.0)), _walk)
	var a := appearance
	return {
		"body": 0, "body_fixed": 0,
		"weapon": PlayerSheet.WEAPONS.find(weapon),
		"hair": int(a["hair"]),
		"beard": int(a["beard"]) - 1, "accessory": int(a["accessory"]) - 1, "accessory_fixed": int(a["accessory"]) - 1,
		"_dir": d[0], "_flip": d[1], "_col": col,
	}


func _refresh() -> void:
	if _layers.is_empty():
		return
	var c := cells()
	var width: float = CharacterAppearance.BODY_WIDTH[int(appearance["body"])]
	var height := float(appearance.get("height", 1.0))
	for l in _layers:
		var key := String(l.name)
		var variant: int = c[key]
		l.visible = variant >= 0 and l.texture != null
		l.region = PlayerSheet.region(maxi(0, variant), c["_dir"], c["_col"])
		var body_part := key in ["body", "body_fixed"]
		l.scale = Vector2((-1.0 if c["_flip"] else 1.0) * (width if body_part else 1.0), height) * sprite_scale
		l.queue_redraw()


## Una capa: dibuja su celda con los pies en el origen.
class _Layer extends Node2D:
	var texture: Texture2D
	var region := Rect2()

	func _draw() -> void:
		if texture != null:
			draw_texture_rect_region(texture, Rect2(-PlayerSheet.FEET, region.size), region)
