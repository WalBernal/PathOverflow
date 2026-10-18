class_name Modifier
extends RefCounted
## Un modificador de stat. Árbol, ascendencias, objetos, gemas y auras de
## enemigos producen todos Modifiers: el contenido nuevo es solo datos.

enum Type { FLAT, INCREASED, MORE }

const TYPE_BY_NAME := {
	"flat": Type.FLAT,
	"increased": Type.INCREASED,
	"more": Type.MORE,
}

var stat: StringName
var type: Type = Type.FLAT
var value := 0.0
## Tags requeridos: solo aplica si la consulta los incluye todos (ej. "spell").
var tags: Array[StringName] = []
## De dónde viene ("tree", "ascendancy", "item:<id>"...), para quitarlo luego.
var source := ""


func _init(p_stat := &"", p_type := Type.FLAT, p_value := 0.0, p_tags: Array = [], p_source := "") -> void:
	stat = p_stat
	type = p_type
	value = p_value
	tags.assign(p_tags)
	source = p_source


## Formato JSON: {"stat": "life", "type": "increased", "value": 10, "tags": ["spell"]}
static func from_dict(d: Dictionary, p_source := "") -> Modifier:
	var tag_list: Array = []
	for t in d.get("tags", []):
		tag_list.append(StringName(t))
	return Modifier.new(
		StringName(d.get("stat", "")),
		TYPE_BY_NAME.get(d.get("type", "flat"), Type.FLAT),
		float(d.get("value", 0.0)),
		tag_list,
		p_source)


func applies_to(query_tags: Array) -> bool:
	for t in tags:
		if not query_tags.has(t):
			return false
	return true


## Texto para tooltips, ej. "+10 de Fuerza", "8% de aumento de Vida máxima".
func describe() -> String:
	var stat_name := Stat.display_name(stat)
	var amount := _fmt(absf(value))
	var text := ""
	match type:
		Type.FLAT:
			var suffix := "%" if Stat.is_percent(stat) else ""
			text = "%s%s%s de %s" % ["+" if value >= 0.0 else "-", amount, suffix, stat_name]
		Type.INCREASED:
			text = "%s%% de %s de %s" % [amount, "aumento" if value >= 0.0 else "reducción", stat_name]
		Type.MORE:
			text = "%s%% %s de %s" % [amount, "más" if value >= 0.0 else "menos", stat_name]
	if not tags.is_empty():
		var names := PackedStringArray()
		for t in tags:
			names.append(Stat.tag_name(t))
		text += " (%s)" % ", ".join(names)
	return text


static func _fmt(v: float) -> String:
	return str(int(v)) if is_equal_approx(v, roundf(v)) else "%.1f" % v
