extends SceneTree
## QA fixture: plays a few seconds of an Endless run on every arena skin in one window and writes
## contact sheets of the real renders (Wisp, enemies, telegraphs, scenery ambience).
##
## Usage (repo root; a real window, not headless):
##   WISP_ISOLATED_SAVE=1 "$GODOT" --path . --resolution 540x1170 \
##     --script res://tools/godot/render_endless_skins_sheet.gd -- [skins_per_sheet] [frames]
## Writes logs/endless/run_sheet_<n>.png (5 columns, catalog order, 270 px tiles); no frame PNGs.

const CATALOG_PATH: String = "res://data/endless/default_endless_catalog.tres"
const GAME_WORLD_PATH: String = "res://scenes/gameplay/game_world.tscn"
const OUT_PATTERN: String = "res://logs/endless/run_sheet_%d.png"
const COLUMNS: int = 5
const TILE_WIDTH: int = 270


func _init() -> void:
	call_deferred(&"_run")


func _run() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	var per_sheet: int = int(args[0]) if args.size() > 0 else 15
	var frames: int = int(args[1]) if args.size() > 1 else 180
	var catalog := load(CATALOG_PATH) as EndlessCatalog
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://logs/endless"))
	var tiles: Array[Image] = []
	var sheet_index: int = 1
	for skin: ArenaSkinData in catalog.skins:
		var game := (load(GAME_WORLD_PATH) as PackedScene).instantiate() as GameWorld
		game.auto_pause_on_focus_loss = false
		var no_rifts: Array[RiftData] = []
		var reaper_only: Array[StringName] = [&"reaper"]
		var profile := RunProfile.endless(catalog, skin, no_rifts, reaper_only, null)
		profile.run_seed = 714
		game.configure_run(profile)
		root.add_child(game)
		for frame: int in frames:
			await process_frame
		var image: Image = root.get_texture().get_image()
		var height: int = roundi(float(TILE_WIDTH) * image.get_height() / image.get_width())
		image.resize(TILE_WIDTH, height, Image.INTERPOLATE_LANCZOS)
		tiles.append(image)
		print("render_endless_skins_sheet: %s" % skin.skin_id)
		game.queue_free()
		await process_frame
		await process_frame
		if tiles.size() == per_sheet or skin == catalog.skins.back():
			_save_sheet(tiles, sheet_index)
			tiles.clear()
			sheet_index += 1
	quit(0)


func _save_sheet(tiles: Array[Image], index: int) -> void:
	var tile_height: int = tiles[0].get_height()
	var rows: int = ceili(float(tiles.size()) / COLUMNS)
	var sheet := Image.create_empty(TILE_WIDTH * COLUMNS, tile_height * rows, false, Image.FORMAT_RGBA8)
	sheet.fill(Color.BLACK)
	for tile_index: int in tiles.size():
		var tile: Image = tiles[tile_index]
		tile.convert(Image.FORMAT_RGBA8)
		sheet.blit_rect(
			tile,
			Rect2i(Vector2i.ZERO, tile.get_size()),
			Vector2i((tile_index % COLUMNS) * TILE_WIDTH, (tile_index / COLUMNS) * tile_height),
		)
	var path: String = ProjectSettings.globalize_path(OUT_PATTERN % index)
	sheet.save_png(path)
	print("render_endless_skins_sheet: sheet -> %s" % path)
