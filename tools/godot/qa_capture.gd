extends SceneTree
## QA capture: builds one screen with representative data at the current window size and saves a
## PNG of the real viewport (not MovieWriter), so layouts can be checked per aspect ratio.
##
## Usage (normally driven by tools/qa_matrix.sh):
##   WISP_ISOLATED_SAVE=1 Godot --path . --resolution 390x844 \
##     --script res://tools/godot/qa_capture.gd -- <screen> <out.png>
## Set WISP_CHARACTER to capture Home with a specific equipped form; otherwise the sample form is used.
## Screens: home, shop_wisps (the Shop's CHARACTERS page), shop_deals (its SHOP page), daily,
## trials, stats, settings, results, game, pause, pickups, tutorial, and endless_<skin_id> (an
## Endless run on that arena).

const GAME_WORLD_PATH: String = "res://scenes/gameplay/game_world.tscn"
const TUTORIAL_PATH: String = "res://scenes/tutorial/tutorial_screen.tscn"
const ENDLESS_CATALOG_PATH: String = "res://data/endless/default_endless_catalog.tres"


func _init() -> void:
	call_deferred(&"_run")


func _run() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	if args.size() < 2:
		push_error("qa_capture: expected -- <screen> <out.png>")
		quit(2)
		return
	var screen: String = args[0]
	var out_path: String = args[1]
	var settle_frames: int = await _build(screen)
	if settle_frames < 0:
		push_error("qa_capture: unknown screen '%s'" % screen)
		quit(2)
		return
	for frame: int in settle_frames + 2:
		await process_frame
	# Optional bottom-of-page capture of the SHOP page (the Rift Points packs on a short phone).
	if screen == "shop_deals" and args.size() > 2 and args[2] == "bottom":
		var shop := root.find_child("ShopScreen", true, false) as ShopScreen
		var page := shop.get_node(^"%ShopPage") as ScrollContainer
		page.scroll_vertical = int(page.get_v_scroll_bar().max_value)
		await process_frame
		await process_frame
	# Not RenderingServer.frame_post_draw: macOS stops drawing covered windows, so it may never fire.
	var image: Image = root.get_texture().get_image()
	var error: Error = image.save_png(out_path)
	print("qa_capture: %s %dx%d -> %s" % [screen, image.get_width(), image.get_height(), out_path])
	quit(0 if error == OK else 1)


## Adds the requested screen to the tree and returns how many frames to let it settle.
func _build(screen: String) -> int:
	var snapshot: Dictionary = _sample_snapshot()
	if screen.begins_with("endless_"):
		return _build_endless(StringName(screen.trim_prefix("endless_")))
	match screen:
		"home":
			# The isolated save may still need the Tutorial; build Home directly for layout QA.
			var home := _add_screen("res://scenes/screens/home_screen.tscn") as HomeScreen
			var forms := load("res://data/forms/default_catalog.tres") as FormCatalog
			var form_id := StringName(OS.get_environment("WISP_CHARACTER"))
			if form_id.is_empty():
				form_id = StringName(str(snapshot.get(&"equipped_form", String(FormCatalog.DEFAULT_FORM_ID))))
			home.setup(snapshot, forms.get_form(form_id))
			return 20
		"daily":
			var daily := _add_screen("res://scenes/screens/daily_screen.tscn") as DailyScreen
			var date_key: String = ChallengeTracker.get_date_key()
			daily.setup(date_key, ChallengeTracker.get_daily_seed(date_key), snapshot)
			return 20
		"trials":
			var trials := _add_screen("res://scenes/screens/trials_screen.tscn") as TrialsScreen
			# Rank 8 shows the renamed HOARDER trial (Rift Points collected) with banked progress.
			trials.setup(8, {"t08_rp_collected_m": 31, "t08_wave": 12})
			return 20
		"stats":
			var stats := _add_screen("res://scenes/screens/statistics_screen.tscn") as StatisticsScreen
			stats.setup(snapshot)
			return 20
		"settings":
			_add_screen("res://scenes/screens/settings_screen.tscn")
			return 20
		"shop_wisps", "shop_deals":
			var shop := _add_screen("res://scenes/screens/shop_screen.tscn") as ShopScreen
			shop.setup(snapshot, ShopScreen.TAB_WISPS if screen == "shop_wisps" else ShopScreen.TAB_SHOP)
			return 20
		"results":
			var results := _add_screen("res://scenes/screens/results_screen.tscn") as ResultsScreen
			results.setup({
				&"score": 12840,
				&"best_score": 48210,
				&"kills": 96,
				&"highest_combo": 14,
				&"wave": 7,
				&"multi_kill_dashes": 11,
				&"bosses": 1,
				&"rp_collected": 18,
				&"rp_performance": 32,
				&"rp_rewards": 115,
				&"rp_earned": 165,
				&"rift_points_total": 1353,
			})
			return 20
		"tutorial":
			# The Tutorial screen mid-demo of its first lesson (ghost hand, caption, SKIP).
			_add_screen(TUTORIAL_PATH)
			return 150
		"game", "pause", "pickups":
			var game := (load(GAME_WORLD_PATH) as PackedScene).instantiate() as GameWorld
			game.run_seed = 714
			# Capture windows steal focus from each other; only the "pause" shot should be paused.
			game.auto_pause_on_focus_loss = false
			root.add_child(game)
			if screen == "pause":
				for frame: int in 60:
					await process_frame
				game.handle_back()
				return 10
			if screen == "pickups":
				for frame: int in 10:
					await process_frame
				game.set_soul_ward_stock(25)
				game.activate_soul_ward()
				for id: StringName in RunItemHud.TIMED_IDS:
					game.activate_item(id)
				return 60
			return 150 if screen == "game" else 40
	return -1


## An Endless run on `skin_id` (Reaper-only pool, fixed seed) settled long enough for wave one.
func _build_endless(skin_id: StringName) -> int:
	var catalog := load(ENDLESS_CATALOG_PATH) as EndlessCatalog
	var skin: ArenaSkinData = catalog.get_skin(skin_id)
	if skin == null or skin.skin_id != skin_id:
		return -1
	var game := (load(GAME_WORLD_PATH) as PackedScene).instantiate() as GameWorld
	game.auto_pause_on_focus_loss = false
	var no_rosters: Array[EndlessRoster] = []
	var reaper_only: Array[StringName] = [&"reaper"]
	var profile := RunProfile.endless(catalog, skin, no_rosters, reaper_only, null)
	profile.run_seed = 714
	game.configure_run(profile)
	root.add_child(game)
	return 180


func _add_screen(path: String) -> Node:
	var node: Node = (load(path) as PackedScene).instantiate()
	root.add_child(node)
	return node


func _sample_snapshot() -> Dictionary:
	return {
		&"best_score": 48210,
		&"highest_wave": 9,
		&"highest_combo": 23,
		&"total_runs": 41,
		&"total_kills": 1873,
		&"total_multi_kills": 212,
		&"bosses_defeated": 2,
		&"play_time_seconds": 5480.0,
		&"rift_points": 1320,
		&"item_stock": {"soul_ward": 25, "rift_magnet": 5, "fortune_star": 10},
		&"next_run_item": "rift_magnet",
		&"owned_forms": ["patchvile", "verdant_shade", "scarlet"],
		&"equipped_form": "scarlet",
		&"owned_arena_skins": ["sci_fi_simulation_v1"],
		&"equipped_arena_skin": "sci_fi_simulation_v1",
		&"tutorial_completed": true,
		&"challenge_state": {},
		&"daily_state": {&"completed_dates": [], &"best_scores": {}},
	}
