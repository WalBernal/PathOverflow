class_name UpdateCheck
extends Node
## Aviso de actualización (T140): en la pantalla de título pregunta, sin bloquear y con
## tiempo límite, si hay una versión más nueva. Lee un latest.json publicado junto a cada
## APK en GitHub Releases ({version, url, notes}; tools/publicar_version.ps1 lo prepara)
## desde application/config/update_url de project.godot. Nunca descarga ni instala nada:
## si hay una nueva, avisa (`found`) y el botón abre la descarga en el navegador.
## Se apaga en Pausa → Gráficos y datos → «Buscar actualizaciones».

signal found(info: Dictionary)

const TIMEOUT := 6.0

var _http: HTTPRequest


static func enabled() -> bool:
	return bool(GameSettings.get_value("interface", "check_updates", true))


static func set_enabled(on: bool) -> void:
	GameSettings.set_value("interface", "check_updates", on)


static func url() -> String:
	return String(ProjectSettings.get_setting("application/config/update_url", ""))


## Pregunta (si está encendido y hay dirección). Sin red o con error, no pasa nada.
func check() -> void:
	if not enabled() or url() == "" or _http != null:
		return
	_http = HTTPRequest.new()
	_http.timeout = TIMEOUT
	_http.max_redirects = 8   # releases/latest/download/... redirige al archivo
	add_child(_http)
	_http.request_completed.connect(_on_completed)
	if _http.request(url()) != OK:
		_http.queue_free()
		_http = null


func _on_completed(result: int, code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	_http.queue_free()
	_http = null
	if result != HTTPRequest.RESULT_SUCCESS or code != 200:
		return
	var info := newer(body.get_string_from_utf8(), GameVersion.full())
	if not info.is_empty():
		found.emit(info)


## El latest.json si trae una versión más nueva que `current` (y una dirección de
## descarga https), o vacío.
static func newer(json_text: String, current: String) -> Dictionary:
	var data: Variant = JSON.parse_string(json_text)
	if not (data is Dictionary):
		return {}
	var v := String(data.get("version", ""))
	var link := String(data.get("url", ""))
	if v == "" or not link.begins_with("https://") or compare(v, current) <= 0:
		return {}
	return {"version": v, "url": link, "notes": String(data.get("notes", ""))}


## -1, 0 o 1 según `a` sea menor, igual o mayor que `b` («3.10.0» > «3.9.2»).
static func compare(a: String, b: String) -> int:
	var pa := a.split(".")
	var pb := b.split(".")
	for k in maxi(pa.size(), pb.size()):
		var x := int(pa[k]) if k < pa.size() else 0
		var y := int(pb[k]) if k < pb.size() else 0
		if x != y:
			return 1 if x > y else -1
	return 0
