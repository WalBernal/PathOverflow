extends Node
## Mide los FPS de las pantallas iniciales (T186): título, lista de personajes y creador,
## sin vsync ni tope de FPS, como en el celular (`movil`) o en PC. Imprime una línea por
## pantalla con los FPS medios y los milisegundos por fotograma.
##
## Uso:  Godot_v4.7.2-stable_win64_console.exe --path . res://tools/bench_screens.tscn
## Como en el celular:  --rendering-method mobile res://tools/bench_screens.tscn -- movil

const SCENES := {
	"titulo": "res://scenes/menu/title_screen.tscn",
	"personajes": "res://scenes/menu/main_menu.tscn",
	"creador": "res://scenes/menu/character_creation.tscn",
}
const WARMUP := 1.0
const MEASURE := 3.0

var _current: Node


func _ready() -> void:
	get_window().size = Vector2i(1600, 900)
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	Engine.max_fps = 0
	if OS.get_cmdline_user_args().has("movil"):
		GameSettings.force_mobile = true
		GraphicsQuality.level = int(GameSettings.MOBILE_DEFAULTS["graphics/quality"])
	print("renderizador: ", RenderingServer.get_current_rendering_method(), " · móvil: ", GameSettings.is_mobile())
	_run.call_deferred()


func _run() -> void:
	for key in SCENES:
		if _current:
			_current.queue_free()
		_current = load(SCENES[key]).instantiate()
		add_child(_current)
		await get_tree().create_timer(WARMUP).timeout
		var frames := 0
		var start := Time.get_ticks_usec()
		while Time.get_ticks_usec() - start < int(MEASURE * 1000000.0):
			await get_tree().process_frame
			frames += 1
		var secs := (Time.get_ticks_usec() - start) / 1000000.0
		print("%-11s %6.0f fps   %.2f ms/fotograma" % [key, frames / secs, secs * 1000.0 / maxi(frames, 1)])
	get_tree().quit()
