extends SceneTree
## Renders an arena scene (an [ArenaVisual]) to a still image: the Shop picture of a layered or 3D
## arena, and the floor it drew there.
##
## Usage (repo root; a real window, not headless - a 3D arena needs a renderer):
##   "$GODOT" --path . --script res://tools/godot/render_arena_still.gd -- \
##     scene=res://scenes/arenas/chained_colossus_3d.tscn out=concept_art/arenas_v2/chained_colossus_3d/source.png
## Options: `size=` (default 941x1672, the Shop still's canvas, `EndlessCatalog.BACKGROUND_SIZE`),
## `safe_top=` the HUD's safe top in design px (default 0), `frames=` frames rendered before the
## capture so the motion and effects have started (default 90). A relative `out=` is from the repo
## root. Prints `ARENA_STILL: {...}` with the floor rectangle as drawn in the still's pixels, for the
## arena's `arena.json` (an arena with a zoom intro is captured on its opening shot, so that floor is
## smaller than the one it plays on, which is printed as `play_floor_rect_px`).

func _init() -> void:
	call_deferred(&"_run")


func _run() -> void:
	var options: Dictionary = {}
	for arg: String in OS.get_cmdline_user_args():
		var pair: PackedStringArray = arg.split("=", true, 1)
		if pair.size() == 2:
			options[pair[0]] = pair[1]
	var scene := load(str(options.get("scene", ""))) as PackedScene
	var out_path: String = str(options.get("out", ""))
	if scene == null or out_path.is_empty():
		push_error("[render_arena_still] needs scene=res://... and out=path.png")
		quit(1)
		return
	var size_text: PackedStringArray = str(options.get("size", "941x1672")).split("x")
	var size := Vector2i(int(size_text[0]), int(size_text[1]))
	var safe_top: float = float(options.get("safe_top", "0"))
	var frames: int = int(options.get("frames", "90"))
	var port := SubViewport.new()
	port.size = size
	port.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(port)
	var visual := scene.instantiate() as ArenaVisual
	if visual == null:
		push_error("[render_arena_still] %s is not an ArenaVisual" % scene.resource_path)
		quit(1)
		return
	port.add_child(visual)
	await process_frame
	var play_rect: Rect2 = visual.fit(Vector2(size), safe_top)
	var floor_rect: Rect2 = visual.get_drawn_floor_rect()
	for i: int in frames:
		await process_frame
	await RenderingServer.frame_post_draw
	var image: Image = port.get_texture().get_image()
	image.convert(Image.FORMAT_RGB8)
	var path: String = out_path
	if path.is_relative_path():
		path = ProjectSettings.globalize_path("res://").path_join(out_path)
	var error: Error = image.save_png(path)
	print("ARENA_STILL: ", JSON.stringify({
		"scene": scene.resource_path,
		"out": out_path,
		"size": [size.x, size.y],
		"safe_top": safe_top,
		"floor_rect_px": [floor_rect.position.x, floor_rect.position.y, floor_rect.end.x, floor_rect.end.y],
		"play_floor_rect_px": [play_rect.position.x, play_rect.position.y, play_rect.end.x, play_rect.end.y],
		"saved": error == OK,
	}))
	quit(0 if error == OK else 1)
