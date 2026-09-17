extends SceneTree
## QA fixture: plays a real Endless run on each Legendary/Mythic arena skin and writes one contact
## sheet of three frames per skin, ~0.7 s apart, so the animated scenery can be judged side by side.
##
## Usage (repo root; a real window, not headless):
##   WISP_ISOLATED_SAVE=1 "$GODOT" --path . --resolution 540x1170 \
##     --script res://tools/godot/render_endless_scenery_sheet.gd -- <out.png> [skin_id ...] \
##     [--band=v0,v1] [--tile=width]
## Default skins: every Legendary and Mythic skin in catalog order. Columns are skins, rows are the
## three frames; `--band` crops each frame to a screen height range (0-1) for a close look, and
## then skins are rows and frames columns. Frames stay in memory (no frame PNGs are written).

const CATALOG_PATH: String = "res://data/endless/default_endless_catalog.tres"
const GAME_WORLD_PATH: String = "res://scenes/gameplay/game_world.tscn"
const TILE_WIDTH: int = 190
const FRAME_COUNT: int = 3
## Seconds between the captured frames of one skin.
const FRAME_GAP_SECONDS: float = 0.7
## Seconds a run plays before the first capture (enemies on the floor).
const SETTLE_SECONDS: float = 3.0


func _init() -> void:
	call_deferred(&"_run")


func _run() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	var out_path: String = args[0] if args.size() > 0 else "res://logs/endless/scenery_sheet.png"
	var ids: PackedStringArray = []
	var band := Vector2(0.0, 1.0)
	var tile_width: int = TILE_WIDTH
	for arg: String in args.slice(1):
		if arg.begins_with("--band="):
			var parts: PackedStringArray = arg.trim_prefix("--band=").split(",")
			band = Vector2(float(parts[0]), float(parts[1]))
		elif arg.begins_with("--tile="):
			tile_width = int(arg.trim_prefix("--tile="))
		else:
			ids.append(arg)
	var catalog := load(CATALOG_PATH) as EndlessCatalog
	var skins: Array[ArenaSkinData] = []
	for skin: ArenaSkinData in catalog.skins:
		var wanted: bool = skin.skin_id in ids if not ids.is_empty() \
			else skin.tier >= ArenaSkinData.Tier.LEGENDARY
		if wanted:
			skins.append(skin)
	if out_path.begins_with("res://"):
		out_path = ProjectSettings.globalize_path(out_path)
	DirAccess.make_dir_recursive_absolute(out_path.get_base_dir())
	var columns: Array[Array] = []
	for skin: ArenaSkinData in skins:
		var game := (load(GAME_WORLD_PATH) as PackedScene).instantiate() as GameWorld
		game.auto_pause_on_focus_loss = false
		var no_rifts: Array[RiftData] = []
		var reaper_only: Array[StringName] = [&"reaper"]
		var profile := RunProfile.endless(catalog, skin, no_rifts, reaper_only, null)
		profile.run_seed = 714
		game.configure_run(profile)
		root.add_child(game)
		await create_timer(SETTLE_SECONDS).timeout
		var frames: Array[Image] = []
		for frame: int in FRAME_COUNT:
			if frame > 0:
				await create_timer(FRAME_GAP_SECONDS).timeout
			await process_frame
			var image: Image = root.get_texture().get_image()
			var top: int = roundi(band.x * image.get_height())
			image = image.get_region(Rect2i(0, top, image.get_width(), roundi(band.y * image.get_height()) - top))
			var height: int = roundi(float(tile_width) * image.get_height() / image.get_width())
			image.resize(tile_width, height, Image.INTERPOLATE_LANCZOS)
			image.convert(Image.FORMAT_RGBA8)
			frames.append(image)
		columns.append(frames)
		print("render_endless_scenery_sheet: %s" % skin.skin_id)
		game.queue_free()
		await process_frame
		await process_frame
	if columns.is_empty():
		push_error("render_endless_scenery_sheet: no skins")
		quit(1)
		return
	var tile_height: int = (columns[0][0] as Image).get_height()
	# Full frames: skins across, frames down. Bands: skins down, frames across.
	var banded: bool = band != Vector2(0.0, 1.0)
	var across: int = FRAME_COUNT if banded else columns.size()
	var down: int = columns.size() if banded else FRAME_COUNT
	var sheet := Image.create_empty(
		tile_width * across + across - 1, tile_height * down + down - 1, false, Image.FORMAT_RGBA8
	)
	sheet.fill(Color.BLACK)
	for skin_index: int in columns.size():
		for frame: int in FRAME_COUNT:
			var tile: Image = columns[skin_index][frame] as Image
			var cell := Vector2i(frame, skin_index) if banded else Vector2i(skin_index, frame)
			sheet.blit_rect(
				tile, Rect2i(Vector2i.ZERO, tile.get_size()),
				Vector2i(cell.x * (tile_width + 1), cell.y * (tile_height + 1))
			)
	sheet.save_png(out_path)
	print("render_endless_scenery_sheet: sheet -> %s" % out_path)
	quit(0)
