class_name FreezeWatch
## Detector de congelamientos: un hilo aparte comprueba que el juego siga
## avanzando. Si el hilo principal se queda más de STALL_SECONDS sin dar señal,
## escribe en user://logs/congelado.log qué estaba haciendo (las últimas "migas"
## que dejó el juego con mark()). Sirve para diagnosticar cuelgues sin error.

const STALL_SECONDS := 4.0
const LOG_PATH := "user://logs/congelado.log"
const TRAIL := 12

static var _mutex := Mutex.new()
static var _beat_ms := 0
static var _trail: PackedStringArray = []
static var _thread: Thread
static var _running := false


## Deja una miga (qué está haciendo el juego ahora).
static func mark(what: String) -> void:
	_mutex.lock()
	_trail.append("%.2f %s" % [Time.get_ticks_msec() / 1000.0, what])
	if _trail.size() > TRAIL:
		_trail.remove_at(0)
	_mutex.unlock()


## Latido del hilo principal (cada frame).
static func beat() -> void:
	_mutex.lock()
	_beat_ms = Time.get_ticks_msec()
	_mutex.unlock()


static func start() -> void:
	if _running or OS.has_feature("web"):
		return
	beat()
	_running = true
	_thread = Thread.new()
	_thread.start(_watch)


static func stop() -> void:
	if not _running:
		return
	_running = false
	_thread.wait_to_finish()
	_thread = null


static func _watch() -> void:
	var reported := false
	while _running:
		OS.delay_msec(500)
		_mutex.lock()
		var stalled := (Time.get_ticks_msec() - _beat_ms) / 1000.0
		var trail := _trail.duplicate()
		_mutex.unlock()
		if stalled >= STALL_SECONDS and not reported:
			reported = true
			_write(stalled, trail)
		elif stalled < STALL_SECONDS:
			reported = false


static func _write(stalled: float, trail: PackedStringArray) -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("user://logs"))
	var f := FileAccess.open(LOG_PATH, FileAccess.READ_WRITE if FileAccess.file_exists(LOG_PATH) else FileAccess.WRITE)
	if f == null:
		return
	f.seek_end()
	f.store_line("=== %s · el juego lleva %.1f s sin avanzar. Últimas acciones:" % [Time.get_datetime_string_from_system(), stalled])
	for line in trail:
		f.store_line("  " + line)
	f.close()
