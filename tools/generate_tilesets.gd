extends SceneTree
## Genera assets/sprites/tiles/: por cada estilo de zona con suelo en pixel art,
## <estilo>.png (4 baldosas de 128×128 en fila: el suelo y tres variantes que encajan
## sin costuras) y <estilo>_edge.png (la banda del borde, 128×16, que se repite a lo
## largo del contorno del camino). Si se cambian por arte a mano con la misma
## cuadrícula, el juego usa el arte (ZoneArt los carga antes que lo procedural).
##
## Uso:  Godot_v4.7.2-stable_win64_console.exe --headless --path . -s res://tools/generate_tilesets.gd


func _initialize() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(ZoneArt.TILE_DIR))
	var n := 0
	for style in ZoneArt.STYLES:
		var s: Dictionary = Zone.STYLES.get(style, {})
		ZoneArt.tileset_image(style, false).save_png(ProjectSettings.globalize_path(ZoneArt.TILE_DIR + style + ".png"))
		ZoneArt.edge_image(style, Color(s.get("outside", "07060a")), String(s.get("edge", "")), false).save_png(
			ProjectSettings.globalize_path(ZoneArt.TILE_DIR + style + "_edge.png"))
		n += 1
	print("tilesets escritos: %d estilos en %s" % [n, ZoneArt.TILE_DIR])
	quit()
