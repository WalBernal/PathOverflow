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


static func kind_label(k: Kind) -> String:
	match k:
		Kind.CLASS_START:
			return "Inicio de clase"
		Kind.NOTABLE:
			return "Notable"
		Kind.KEYSTONE:
			return "Piedra angular"
	return "Pasiva menor"
