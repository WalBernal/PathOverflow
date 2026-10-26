class_name PassiveNode
extends RefCounted
## Un nodo del árbol pasivo (datos estáticos, compartidos por todos los personajes).

enum Kind { CLASS_START, MINOR, NOTABLE, KEYSTONE }

const KIND_BY_NAME := {
	"start": Kind.CLASS_START,
	"minor": Kind.MINOR,
	"notable": Kind.NOTABLE,
	"keystone": Kind.KEYSTONE,
}

var id := -1
var title := ""
var kind: Kind = Kind.MINOR
var position := Vector2.ZERO
var mods: Array[Modifier] = []
var flavor := ""
## Solo en nodos de inicio: la clase que empieza aquí.
var class_id := &""
## Temática (vida, fuego...), cluster al que pertenece ("" = nodo de viaje) e
## icono de notables y piedras angulares (data/passive_icons.json).
var theme := ""
var cluster := ""
var icon := ""
## Maestría (data/passive_masteries.json): opciones {name, mods: Array[Modifier]};
## con el nodo asignado se elige una (PassiveAllocation.mastery_choice). Vacío = nodo normal.
var choices: Array[Dictionary] = []
## Identidad (T84, data/passive_identity.json): notable de estilo de su clase (cambia
## cómo se juega), y constelación a la que pertenece con los atributos que pide.
var style := false
## Piedra angular «de cluster» (T84): sigue siendo el notable de su grupo, pero con
## ventaja y contra como las piedras angulares (se dibuja y se nombra como ellas).
var capstone := false
var constellation := ""
var requires: Dictionary = {}   # {"strength": 50, ...}


func is_mastery() -> bool:
	return not choices.is_empty()


func is_keystone() -> bool:
	return kind == Kind.KEYSTONE or capstone


static func from_dict(d: Dictionary) -> PassiveNode:
	var n := PassiveNode.new()
	n.id = int(d["id"])
	n.title = d.get("name", "")
	n.kind = KIND_BY_NAME.get(d.get("kind", "minor"), Kind.MINOR)
	n.position = Vector2(float(d["x"]), float(d["y"]))
	n.flavor = d.get("flavor", "")
	n.class_id = StringName(d.get("class_id", ""))
	n.theme = d.get("theme", "")
	n.cluster = d.get("cluster", "")
	n.icon = d.get("icon", "")
	for md in d.get("mods", []):
		n.mods.append(Modifier.from_dict(md, "tree"))
	return n


func label() -> String:
	if is_mastery():
		return "Maestría (elige 1 de %d)" % choices.size()
	if style:
		return "Notable de estilo"
	if capstone:
		return kind_label(Kind.KEYSTONE)
	return kind_label(kind)


static func kind_label(k: Kind) -> String:
	match k:
		Kind.CLASS_START:
			return "Inicio de clase"
		Kind.NOTABLE:
			return "Notable"
		Kind.KEYSTONE:
			return "Piedra angular"
	return "Pasiva menor"
