extends SceneTree
## Resume la telemetría local (user://telemetria.jsonl, ver Telemetry): por zona y
## por clase, visitas, tiempo, DPS medio, muertes por hora y enemigos por minuto.
## Sirve para ver dónde se muere mucho, dónde el DPS se queda corto o qué clase va
## por delante.
##
## Uso:  Godot_v4.7.2-stable_win64_console.exe --headless --path . -s res://tools/telemetry_summary.gd [-- clase=hacker zona=zona3 archivo=user://otro.jsonl]


func _initialize() -> void:
	var opts := {}
	for arg in OS.get_cmdline_user_args():
		var kv := String(arg).split("=", true, 1)
		if kv.size() == 2:
			opts[kv[0]] = kv[1]
	var records := Telemetry.read(String(opts.get("archivo", Telemetry.PATH)))
	if opts.has("clase"):
		records = records.filter(func(r: Dictionary) -> bool: return String(r.get("class", "")) == opts["clase"])
	if opts.has("zona"):
		records = records.filter(func(r: Dictionary) -> bool: return String(r.get("zone", "")) == opts["zona"])
	if records.is_empty():
		print("Sin registros en %s (juega con un personaje guardado y la opción «Registro local de partidas» activada)." % opts.get("archivo", Telemetry.PATH))
		quit()
		return
	print("Telemetría: %d visitas" % records.size())
	for key in ["zone", "class"]:
		print("")
		print("Por %s:" % ("zona" if key == "zone" else "clase"))
		print("  %-24s %7s %9s %8s %10s %10s" % ["", "visitas", "minutos", "DPS", "muertes/h", "enem./min"])
		var s := Telemetry.summarize(records, key)
		var keys := s.keys()
		keys.sort_custom(func(a, b) -> bool: return float(s[a]["deaths_per_hour"]) > float(s[b]["deaths_per_hour"]))
		for k in keys:
			var v: Dictionary = s[k]
			print("  %-24s %7d %9.1f %8d %10.1f %10.1f" % [k, v["visits"], float(v["seconds"]) / 60.0, v["dps"], v["deaths_per_hour"], v["kills_per_min"]])
	quit()
