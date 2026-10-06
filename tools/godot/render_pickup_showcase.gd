extends SceneTree
## Portrait pickup/HUD fixture. -- <out.png> [arena_skin_id] renders the neutral arena or the given
## arena; both are SIMULATION, the one arena (ADR-0027).
## WISP_ISOLATED_SAVE=1 Godot --path . --resolution 390x844 --script
## res://tools/godot/render_pickup_showcase.gd -- logs/pickups.png sci_fi_simulation_v1

const GAME: PackedScene = preload("res://scenes/gameplay/game_world.tscn")
const CATALOG: EndlessCatalog = preload("res://data/endless/default_endless_catalog.tres")
const ITEMS: RunItemCatalog = preload("res://data/items/default_item_catalog.tres")


func _init() -> void:
	call_deferred(&"_run")


func _run() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	if args.is_empty():
		quit(2)
		return
	var game := GAME.instantiate() as GameWorld
	var profile := RunProfile.new()
	profile.mode = RunProfile.MODE_TUTORIAL
	if args.size() > 1:
		profile = RunProfile.tutorial(CATALOG, CATALOG.get_skin(StringName(args[1])), null)
	game.auto_pause_on_focus_loss = false
	game.configure_run(profile)
	root.add_child(game)
	for frame: int in 35:
		await process_frame
	game.set_soul_ward_stock(25)
	game.activate_soul_ward()
	for item_id: StringName in RunItemHud.TIMED_IDS:
		game.activate_item(item_id)
	for index: int in ITEMS.items.size():
		var uv := Vector2(0.2 + float(index % 4) * 0.2, 0.38 + float(index / 4) * 0.23)
		game.spawn_scripted_item(ITEMS.items[index].item_id, game.arena_to_world(uv))
	game._item_hud.refresh(game.get_run_items(), game.get_soul_ward_stock(), true)
	game._update_board_hud()
	game._combo_label.visible = false
	game.process_mode = Node.PROCESS_MODE_DISABLED
	for frame: int in 4:
		await process_frame
	var image: Image = root.get_texture().get_image()
	var error: Error = image.save_png(args[0])
	print("pickup_showcase: %dx%d -> %s" % [image.get_width(), image.get_height(), args[0]])
	quit(0 if error == OK else 1)
