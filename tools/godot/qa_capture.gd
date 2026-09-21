extends SceneTree
## QA capture: builds one screen with representative data at the current window size and saves a
## PNG of the real viewport (not MovieWriter), so layouts can be checked per aspect ratio.
##
## Usage (normally driven by tools/qa_matrix.sh):
##   WISP_ISOLATED_SAVE=1 Godot --path . --resolution 390x844 \
##     --script res://tools/godot/qa_capture.gd -- <screen> <out.png>
## Screens: home, shop_wisps, shop_arenas, shop_no_ads, rifts, rifts_locked, daily,
## trials, stats, settings, results, game, pause, upgrade, tutorial, and endless_<skin_id> (an
## Endless run on that arena skin, with its animated scenery).

const MAIN_SCENE_PATH: String = "res://scenes/main/main.tscn"
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
			var main: Node = (load(MAIN_SCENE_PATH) as PackedScene).instantiate()
			root.add_child(main)
			for frame: int in 900:
				if main.get_child_count() > 0 and main.get_child(0) is HomeScreen:
					break
				await process_frame
			return 20
		"rifts", "rifts_locked":
			var rifts := _add_screen("res://scenes/screens/rift_map_screen.tscn") as RiftMapScreen
			var rift_snapshot: Dictionary = snapshot.duplicate(true)
			rift_snapshot[&"selected_rift"] = "shattered_rift"
			rift_snapshot[&"rift_bests"] = {"obsidian_garden": 48210, "shattered_rift": 6120}
			rift_snapshot[&"rift_levels"] = {"obsidian_garden": 8, "shattered_rift": 3}
			rifts.setup(rift_snapshot)
			if screen == "rifts_locked":
				# Focus Ember Hollow (wave 10 gate) to check the lock card and disabled ENTER.
				(rifts.get_node("%Carousel") as FocusCarousel).select(2, false)
			return 30
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
		"shop_wisps", "shop_arenas", "shop_no_ads":
			var shop := _add_screen("res://scenes/screens/shop_screen.tscn") as ShopScreen
			shop.setup(snapshot, StringName(screen.trim_prefix("shop_")))
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
		"game", "pause", "upgrade":
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
			if screen == "upgrade":
				for frame: int in 10:
					await process_frame
				game.add_experience(1000)
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
	var no_rifts: Array[RiftData] = []
	var reaper_only: Array[StringName] = [&"reaper"]
	var profile := RunProfile.endless(catalog, skin, no_rifts, reaper_only, null)
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
		&"owned_forms": ["void", "eclipse", "ilyra"],
		&"equipped_form": "ilyra",
		# A Mythic arena equipped, so shop_arenas shows a card with the scenery grade and glow.
		&"owned_arena_skins": ["astral_observatory", "aurora_throne"],
		&"equipped_arena_skin": "aurora_throne",
		&"tutorial_completed": true,
		&"challenge_state": {},
		&"daily_state": {&"completed_dates": [], &"best_scores": {}},
	}
