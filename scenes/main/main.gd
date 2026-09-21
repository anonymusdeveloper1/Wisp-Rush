extends Node
## Composition root: boot loading, navigation between screens, back handling and app lifecycle.
##
## Owns no game state: persistent progress lives in the SaveManager autoload, sound in the Audio
## autoload and run state in GameWorld. Screen scenes are streamed in by the Loading screen.
##
## Cover, then build (owner report 2026-09-16): with transitions on, a navigation request never
## builds at the tap. A dark veil covers the screen at once, the next screen is built and added on a
## later frame under it, draws COVER_DRAW_FRAMES frames fully covered (first-draw costs land behind
## the veil), then the veil lifts while the screen glides in. PLAY and Rift Map ENTER also prewarm the
## run beneath the run loading screen. `get_child(0)` is the current screen, except during a run
## loading prewarm, when it is the held GameWorld and the loading screen draws over it from an
## internal CanvasLayer; `is_navigating()` tells tools a change is still pending.

const LOADING_SCREEN: PackedScene = preload("res://scenes/screens/loading_screen.tscn")
const FORM_CATALOG: FormCatalog = preload("res://data/forms/default_catalog.tres")
const RIFT_CATALOG: RiftCatalog = preload("res://data/rifts/default_catalog.tres")
const ENDLESS_CATALOG: EndlessCatalog = preload("res://data/endless/default_endless_catalog.tres")
const DASH_STYLE_CATALOG: DashStyleCatalog = preload(
	"res://data/dash_styles/default_dash_style_catalog.tres"
)
const TUTORIAL_CATALOG: TutorialCatalog = preload("res://data/tutorial/default_tutorial.tres")
## Screen scenes streamed in at boot, keyed by screen id.
const SCREEN_PATHS: Dictionary[StringName, String] = {
	&"home": "res://scenes/screens/home_screen.tscn",
	&"daily": "res://scenes/screens/daily_screen.tscn",
	&"rift_map": "res://scenes/screens/rift_map_screen.tscn",
	&"trials": "res://scenes/screens/trials_screen.tscn",
	&"statistics": "res://scenes/screens/statistics_screen.tscn",
	&"settings": "res://scenes/screens/settings_screen.tscn",
	&"shop": "res://scenes/screens/shop_screen.tscn",
	&"game": "res://scenes/gameplay/game_world.tscn",
	&"results": "res://scenes/screens/results_screen.tscn",
	&"tutorial": "res://scenes/tutorial/tutorial_screen.tscn",
}
## Seconds the dark veil takes to cover the old screen after a navigation request.
const COVER_SECONDS: float = 0.12
## Seconds the veil takes to lift off the new screen (ease-out cubic) while it glides in.
const TRANSITION_SECONDS: float = 0.28
## Reduced Motion: a shorter plain reveal with no glide.
const REDUCED_TRANSITION_SECONDS: float = 0.14
## Horizontal glide of the incoming screen in design pixels: from the right going deeper, from the
## left returning Home. GameWorld and the Tutorial (which hosts one) never glide: their arena maths
## works in screen space.
const TRANSITION_GLIDE: float = 90.0
## Longest step the transition clock takes per frame, so a slow build frame never skips the animation.
const TRANSITION_MAX_STEP: float = 1.0 / 30.0
## Frames a new screen draws fully covered before the veil lifts.
const COVER_DRAW_FRAMES: int = 2
## CanvasLayer of the veil: above every screen's own layers (run HUD 10, Tutorial up to 12).
const VEIL_LAYER: int = 100
## CanvasLayer a run loading screen moves to while the run prewarms: over the whole run, under the veil.
const LOADING_COVER_LAYER: int = 99
## Steps the run loading bar waits for beyond its art: build the run, add and warm it, draw it covered.
const RUN_PREWARM_STEPS: int = 3

enum NavPhase { IDLE, COVERING, BUILT, REVEALING }

## Animate screen changes. Off in headless runs so tests see screens change at once.
var transitions_enabled: bool = DisplayServer.get_name() != "headless"

var _current_screen: Node
## Profile of the run on screen or just finished; restarts and Results' next steps build from it.
var _active_profile: RunProfile
## Shop tab the SHOP button opens: the last one viewed this session.
var _shop_tab: StringName = ShopScreen.TAB_WISPS
## The Shop on screen was opened from Results, so its back returns there.
var _shop_from_results: bool = false
## What the last Results screen showed, so a Shop opened from it can return without re-banking.
var _last_results_summary: Dictionary = {}
var _save_manager: SaveManagerService
var _scenes: Dictionary[StringName, PackedScene] = {}
var _switch_started_usec: int = 0
## Home is built once and kept: rebuilding it cost ~190 ms plus ~190 ms to first draw on device.
var _home: HomeScreen
## Rift and form data loaded behind the boot screen and kept (`_kept_paths`), so Home, the Rift Map
## and run starts never reload them (271 ms for the Rift Map on desktop before). The Rifts also keep
## the loading screen's background pool cached.
var _kept_resources: Array[Resource] = []
var _veil: ColorRect
## Holds the run loading screen above the run prewarming beneath it (`_prewarm_run`).
var _loading_cover: CanvasLayer
var _nav_phase: NavPhase = NavPhase.IDLE
## The latest navigation request not built yet (latest wins).
var _nav_request: Callable = Callable()
## True while Main runs a queued request, so the builders it calls build instead of queueing again.
var _nav_building: bool = false
var _nav_alpha: float = 0.0
var _nav_draw_frames: int = 0
var _nav_reveal_time: float = 0.0
var _nav_reveal_seconds: float = TRANSITION_SECONDS
var _nav_glide: float = 0.0
var _nav_last_usec: int = 0
var _nav_started_usec: int = 0
var _nav_build_ms: float = 0.0
var _nav_worst_ms: float = 0.0
## The run built beneath the run loading screen.
var _prewarm_game: GameWorld
var _prewarm_ready: bool = false


## Seconds until the next display refresh-rate check ([FramePacing]).
var _pacing_countdown: float = FramePacing.POLL_SECONDS


func _ready() -> void:
	# Step the simulation at the screen's own refresh rate, so a dash is redrawn at a fresh position
	# every frame on a 90 or 120 Hz phone instead of holding each one for two ([FramePacing]).
	var physics_hz: int = FramePacing.match_display()
	_save_manager = get_node("/root/SaveManager") as SaveManagerService
	assert(_save_manager != null, "Main requires the SaveManager autoload")
	var audio: AudioService = SoundFx.audio()
	if audio != null:
		audio.apply_settings(_save_manager.get_settings())
		if not _save_manager.settings_changed.is_connected(audio.apply_settings):
			_save_manager.settings_changed.connect(audio.apply_settings)
	if OS.is_debug_build() and get_tree().root.get_node_or_null(^"DebugOverlay") == null:
		var overlay := DebugOverlay.new()
		overlay.name = "DebugOverlay"
		get_tree().root.add_child.call_deferred(overlay)
	var version: String = Engine.get_version_info()["string"]
	print("[Main] boot ok | godot=%s | physics=%d Hz" % [version, physics_hz])
	_build_veil()
	_show_loading()


## Adaptive phone displays change refresh rate while the game runs, so the simulation rate follows
## them instead of being fixed at whatever the screen happened to be doing at boot.
func _process(delta: float) -> void:
	_pacing_countdown -= delta
	if _pacing_countdown > 0.0:
		return
	_pacing_countdown = FramePacing.POLL_SECONDS
	var changed: int = FramePacing.poll()
	if changed > 0:
		print("[Main] physics rate now %d Hz (display changed)" % changed)


func _notification(what: int) -> void:
	match what:
		NOTIFICATION_WM_GO_BACK_REQUEST:
			_handle_back()
		NOTIFICATION_APPLICATION_PAUSED, NOTIFICATION_APPLICATION_FOCUS_OUT:
			SoundFx.set_interrupted(true)
		NOTIFICATION_APPLICATION_RESUMED, NOTIFICATION_APPLICATION_FOCUS_IN:
			if is_inside_tree():
				SoundFx.set_interrupted(get_tree().paused)
		NOTIFICATION_PREDELETE:
			# The kept Home is not a child while another screen is up, so nothing else frees it.
			if is_instance_valid(_home) and _home.get_parent() == null:
				_home.free()


func _input(event: InputEvent) -> void:
	# No new press lands while a screen change covers, builds or reveals (double taps included).
	if _nav_phase != NavPhase.IDLE and event.is_pressed():
		get_viewport().set_input_as_handled()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"ui_cancel") and not _current_screen is GameWorld:
		get_viewport().set_input_as_handled()
		_handle_back()


func _handle_back() -> void:
	if _current_screen == null or _current_screen is LoadingScreen or _nav_phase != NavPhase.IDLE:
		return
	if _current_screen.has_method(&"handle_back") and bool(_current_screen.call(&"handle_back")):
		return
	if _current_screen is HomeScreen:
		if OS.has_feature("mobile"):
			get_tree().quit()
		return
	if _current_screen is ShopScreen:
		_on_shop_back_requested()
		return
	_show_home()


func _show_loading() -> void:
	_switch_started_usec = Time.get_ticks_usec()
	var loading := LOADING_SCREEN.instantiate() as LoadingScreen
	loading.finished.connect(_on_loading_finished)
	_replace_screen(loading)
	var wait_for_audio: bool = DisplayServer.get_name() != "headless" and SoundFx.audio() != null
	var paths := PackedStringArray(SCREEN_PATHS.values())
	paths.append_array(_kept_paths())
	loading.begin(paths, wait_for_audio)


func _on_loading_finished(resources: Dictionary) -> void:
	for key: StringName in SCREEN_PATHS:
		var scene := resources.get(SCREEN_PATHS[key]) as PackedScene
		if scene != null:
			_scenes[key] = scene
	for path: String in _kept_paths():
		var kept := resources.get(path) as Resource
		if kept != null:
			_kept_resources.append(kept)
	var audio: AudioService = SoundFx.audio()
	if audio != null:
		audio.start_music()
	_show_first_screen.call_deferred()


## Data the catalogs `load()` by path on every lookup (Rifts with their art, Wisp forms with their
## portraits): loaded behind the boot screen and kept referenced, so those lookups hit the cache.
##
## The equipped character's menu frames ride along. A whole-frame character's menu sheet is a few
## thousand pixels square, and loading it the moment Home first drew one cost ~700 ms on the phone;
## behind the loading bar nobody sees it. Only the *equipped* one is warmed — warming the whole
## roster would hold every character's sheet at once, which is the bill the Shop's lazy cards were
## built to avoid.
func _kept_paths() -> PackedStringArray:
	var paths := PackedStringArray(RIFT_CATALOG.rift_paths)
	paths.append_array(FORM_CATALOG.form_paths)
	var equipped: FormData = FORM_CATALOG.get_form(
		StringName(str(_save_manager.get_snapshot()[&"equipped_form"]))
	)
	if equipped != null and not equipped.menu_frames_path.is_empty():
		paths.append(equipped.menu_frames_path)
	return paths


## First launch (owner decision 2026-09-15): the Tutorial until finished or skipped, then Home.
func _show_first_screen() -> void:
	if bool(_save_manager.get_snapshot()[&"tutorial_completed"]):
		_show_home()
	else:
		_show_tutorial(false)


func _instantiate(key: StringName) -> Node:
	if not _scenes.has(key):
		_scenes[key] = load(SCREEN_PATHS[key]) as PackedScene
	return _scenes[key].instantiate()


func _show_home() -> void:
	if _defer_navigation(_show_home):
		return
	get_tree().paused = false
	_active_profile = null
	_last_results_summary = {}
	SoundFx.music_state(0.0, false)
	var snapshot: Dictionary = _save_manager.get_snapshot()
	if _home == null:
		_home = _instantiate(&"home") as HomeScreen
		_home.play_requested.connect(_on_play_requested)
		_home.wisps_requested.connect(_show_shop.bind(ShopScreen.TAB_WISPS))
		_home.daily_requested.connect(_show_daily)
		_home.rift_map_requested.connect(_show_rift_map)
		_home.trials_requested.connect(_show_trials)
		_home.statistics_requested.connect(_show_statistics)
		_home.settings_requested.connect(_show_settings)
		# SHOP reopens the last tab viewed; NO ADS opens its own tab.
		_home.shop_requested.connect(_show_shop)
		_home.remove_ads_requested.connect(_show_shop.bind(ShopScreen.TAB_NO_ADS))
	if _home == _current_screen:
		_home.setup(snapshot, FORM_CATALOG.get_form(StringName(snapshot[&"equipped_form"])))
		return
	_replace_screen(_home)
	_home.setup(snapshot, FORM_CATALOG.get_form(StringName(snapshot[&"equipped_form"])))


func _show_trials() -> void:
	if _defer_navigation(_show_trials):
		return
	var trials := _instantiate(&"trials") as TrialsScreen
	trials.back_requested.connect(_show_home)
	trials.setup(_save_manager.get_trial_rank(), _save_manager.get_trial_progress())
	_replace_screen(trials)


func _show_rift_map() -> void:
	if _defer_navigation(_show_rift_map):
		return
	var rift_map := _instantiate(&"rift_map") as RiftMapScreen
	rift_map.back_requested.connect(_show_home)
	rift_map.play_requested.connect(_on_rift_play_requested)
	rift_map.tutorial_requested.connect(_show_tutorial.bind(true))
	rift_map.setup(_save_manager.get_snapshot())
	_replace_screen(rift_map)


## Opens the Tutorial on the default Endless arena. [param from_rift_map] is a replay, which
## returns to the Rift Map; otherwise (first launch) it leads Home.
func _show_tutorial(from_rift_map: bool) -> void:
	if _defer_navigation(_show_tutorial.bind(from_rift_map)):
		return
	get_tree().paused = false
	_active_profile = null
	SoundFx.music_state(0.0, false)
	var snapshot: Dictionary = _save_manager.get_snapshot()
	var tutorial := _instantiate(&"tutorial") as TutorialScreen
	tutorial.setup(RunProfile.tutorial(
		ENDLESS_CATALOG,
		ENDLESS_CATALOG.get_skin(TUTORIAL_CATALOG.arena_skin_id),
		_equipped_form(snapshot),
	))
	tutorial.finished.connect(_on_tutorial_finished.bind(from_rift_map))
	_replace_screen(tutorial)


## Finishing or skipping marks the tutorial completed (first launch never repeats), then routes.
func _on_tutorial_finished(skipped: bool, from_rift_map: bool) -> void:
	_save_manager.mark_tutorial_completed()
	print("[Main] tutorial %s | next=%s" % [
		"skipped" if skipped else "finished", "rift_map" if from_rift_map else "home",
	])
	if from_rift_map:
		_show_rift_map()
	else:
		_show_home()


## Persists the chosen Rift first, then plays its next level (a mastered Rift replays its last).
func _on_rift_play_requested(rift_id: StringName) -> void:
	if _defer_navigation(_on_rift_play_requested.bind(rift_id)):
		return
	_save_manager.select_rift(rift_id)
	_start_story(RIFT_CATALOG.get_rift(rift_id), 0, true)


## Story runs start only from the Rift Map (RIFTS) or a Results follow-up; PLAY is Endless.


## Starts a story run in `rift` at `level`, or at its next level when `level` is zero; with
## [param with_loading] the run loading screen comes first (Rift Map ENTER).
func _start_story(rift: RiftData, level: int = 0, with_loading: bool = false) -> void:
	if _defer_navigation(_start_story.bind(rift, level, with_loading)):
		return
	var snapshot: Dictionary = _save_manager.get_snapshot()
	var levels: Dictionary = snapshot[&"rift_levels"] as Dictionary
	if not ContentUnlocks.is_rift_unlocked(rift, levels):
		rift = RIFT_CATALOG.get_rift(RiftCatalog.DEFAULT_RIFT_ID)
		level = 0
	var story_level: int = level if level > 0 else ContentUnlocks.get_next_level(rift, levels)
	var profile := RunProfile.story(rift, story_level, levels, _equipped_form(snapshot))
	if with_loading and transitions_enabled:
		_show_run_loading(
			profile, PackedStringArray(), rift.display_name.to_upper(), "LEVEL %d" % story_level
		)
	else:
		_show_game(profile)


## PLAY (owner decision 2026-09-15): always Endless, open from the first launch, on the equipped skin,
## with every Rift's enemies and bosses whatever the story progress.
func _on_play_requested(with_loading: bool = true) -> void:
	if _defer_navigation(_on_play_requested.bind(with_loading)):
		return
	var snapshot: Dictionary = _save_manager.get_snapshot()
	var skin: ArenaSkinData = ENDLESS_CATALOG.get_skin(
		StringName(str(snapshot.get(&"equipped_arena_skin", "")))
	)
	var profile := RunProfile.endless(
		ENDLESS_CATALOG,
		skin,
		_rifts_by_id(ContentUnlocks.get_endless_roster_rift_ids(RIFT_CATALOG)),
		ContentUnlocks.get_endless_boss_ids(RIFT_CATALOG),
		_equipped_form(snapshot),
	)
	var paths := PackedStringArray()
	if skin != null and not skin.background_path.is_empty():
		paths.append(skin.background_path)
	if with_loading and transitions_enabled:
		_show_run_loading(profile, paths, "ENDLESS", skin.display_name if skin != null else "")
	else:
		_show_game(profile)


## Today's daily run: Endless rules, the date seed, the fixed daily pool and the arena of the day.
## Player progress and skin ownership are ignored, so every save plays the same run on a date.
func _on_daily_play_requested(date_key: String, daily_seed: int) -> void:
	if _defer_navigation(_on_daily_play_requested.bind(date_key, daily_seed)):
		return
	var snapshot: Dictionary = _save_manager.get_snapshot()
	var tuning: EndlessTuning = ENDLESS_CATALOG.tuning
	_show_game(RunProfile.daily(
		ENDLESS_CATALOG,
		ENDLESS_CATALOG.get_arena_of_the_day(date_key),
		_rifts_by_id(tuning.daily_roster_rift_ids),
		tuning.daily_boss_ids,
		date_key,
		daily_seed,
		_equipped_form(snapshot),
	))


func _rifts_by_id(rift_ids: Array[StringName]) -> Array[RiftData]:
	var rifts: Array[RiftData] = []
	for rift_id: StringName in rift_ids:
		rifts.append(RIFT_CATALOG.get_rift(rift_id))
	return rifts


func _equipped_form(snapshot: Dictionary) -> FormData:
	return FORM_CATALOG.get_form(StringName(str(snapshot[&"equipped_form"])))


func _show_daily() -> void:
	if _defer_navigation(_show_daily):
		return
	var date_key: String = ChallengeTracker.get_date_key()
	var daily := _instantiate(&"daily") as DailyScreen
	daily.back_requested.connect(_show_home)
	daily.play_daily_requested.connect(_on_daily_play_requested)
	var arena: ArenaSkinData = ENDLESS_CATALOG.get_arena_of_the_day(date_key)
	daily.setup(
		date_key,
		ChallengeTracker.get_daily_seed(date_key),
		_save_manager.get_snapshot(),
		arena.display_name if arena != null else "",
	)
	_replace_screen(daily)


func _show_statistics() -> void:
	if _defer_navigation(_show_statistics):
		return
	var statistics := _instantiate(&"statistics") as StatisticsScreen
	statistics.back_requested.connect(_show_home)
	statistics.setup(_save_manager.get_snapshot())
	_replace_screen(statistics)


func _show_settings() -> void:
	if _defer_navigation(_show_settings):
		return
	var settings := _instantiate(&"settings") as SettingsScreen
	settings.back_requested.connect(_show_home)
	_replace_screen(settings)


## Opens the Shop on `tab` (empty: the last tab viewed this session). Back returns to Results when
## `from_results`, otherwise Home.
func _show_shop(tab: StringName = &"", from_results: bool = false) -> void:
	if _defer_navigation(_show_shop.bind(tab, from_results)):
		return
	if not tab.is_empty():
		_shop_tab = tab
	_shop_from_results = from_results and not _last_results_summary.is_empty()
	var shop := _instantiate(&"shop") as ShopScreen
	shop.back_requested.connect(_on_shop_back_requested)
	shop.tab_changed.connect(func(new_tab: StringName) -> void: _shop_tab = new_tab)
	shop.purchase_requested.connect(_on_cosmetic_purchase_requested)
	shop.equip_requested.connect(_on_cosmetic_equip_requested)
	shop.store_purchase_requested.connect(_on_shop_purchase_requested)
	shop.restore_requested.connect(_on_shop_restore_requested)
	shop.setup(_shop_snapshot(), _shop_tab)
	_replace_screen(shop)


func _on_shop_back_requested() -> void:
	if _shop_from_results and not _last_results_summary.is_empty():
		_present_results(_last_results_summary)
	else:
		_show_home()


## The save snapshot plus store availability, which the Shop needs and the save does not hold.
func _shop_snapshot() -> Dictionary:
	var snapshot: Dictionary = _save_manager.get_snapshot()
	var monetisation: MonetisationService = _monetisation()
	snapshot[&"store_available"] = monetisation != null and monetisation.is_store_available()
	return snapshot


## Buys a form, dash style or arena skin with Rift Points; buying equips it.
func _on_cosmetic_purchase_requested(kind: StringName, item_id: StringName) -> void:
	var item: Dictionary = _cosmetic_info(kind, item_id)
	var purchased: bool = not item.is_empty() and _save_manager.purchase_cosmetic(
		kind, item_id, int(item[&"price"]), bool(item[&"requirement_met"])
	)
	SoundFx.play(&"ui_purchase" if purchased else &"ui_error")
	_refresh_shop_screen(
		"%s EQUIPPED" % item[&"name"] if purchased else "THAT COULD NOT BE BOUGHT",
		purchased,
	)


func _on_cosmetic_equip_requested(kind: StringName, item_id: StringName) -> void:
	var item: Dictionary = _cosmetic_info(kind, item_id)
	var equipped: bool = not item.is_empty() and _save_manager.equip_cosmetic(kind, item_id)
	SoundFx.play(&"ui_confirm" if equipped else &"ui_error")
	_refresh_shop_screen(
		"%s EQUIPPED" % item[&"name"] if equipped else "THAT COULD NOT BE EQUIPPED",
		equipped,
	)


## Name, price and whether the purchase gate is met for a catalog item; empty for an unknown id.
func _cosmetic_info(kind: StringName, item_id: StringName) -> Dictionary:
	var snapshot: Dictionary = _save_manager.get_snapshot()
	match kind:
		SaveManagerService.KIND_FORM:
			var form: FormData = FORM_CATALOG.get_form(item_id)
			if form.form_id != item_id:
				return {}
			return {
				&"name": form.display_name,
				&"price": form.price,
				&"requirement_met": (
					not form.requires_boss_victory or int(snapshot[&"bosses_defeated"]) > 0
				),
			}
		SaveManagerService.KIND_DASH_STYLE:
			var style: DashStyleData = DASH_STYLE_CATALOG.get_style(item_id)
			if style == null or style.style_id != item_id:
				return {}
			return {&"name": style.display_name, &"price": style.price, &"requirement_met": true}
		SaveManagerService.KIND_ARENA_SKIN:
			var skin: ArenaSkinData = ENDLESS_CATALOG.get_skin(item_id)
			if skin == null or skin.skin_id != item_id:
				return {}
			return {
				&"name": skin.display_name,
				&"price": skin.price,
				&"requirement_met": true,
			}
	return {}


## Runs a Remove Ads purchase through the Monetisation autoload; the screen itself only ever asks.
func _on_shop_purchase_requested(product_id: StringName) -> void:
	if not _current_screen is ShopScreen:
		return
	var monetisation: MonetisationService = _monetisation()
	var purchased: bool = (
		monetisation != null
		and product_id == MonetisationService.PRODUCT_REMOVE_ADS
		and monetisation.purchase_remove_ads()
	)
	SoundFx.play(&"ui_purchase" if purchased else &"ui_error")
	_refresh_shop_screen("ADS REMOVED" if purchased else "THE PURCHASE DID NOT COMPLETE", purchased)


func _on_shop_restore_requested() -> void:
	if not _current_screen is ShopScreen:
		return
	var monetisation: MonetisationService = _monetisation()
	var restored: bool = monetisation != null and monetisation.restore_purchases()
	SoundFx.play(&"ui_purchase" if restored else &"ui_error")
	_refresh_shop_screen("PURCHASES RESTORED" if restored else "NOTHING TO RESTORE", restored)


## Re-reads the save into the Shop on screen, on its current tab, and shows `message`.
func _refresh_shop_screen(message: String, success: bool) -> void:
	var shop := _current_screen as ShopScreen
	if shop == null:
		return
	shop.setup(_shop_snapshot(), shop.get_tab())
	if not message.is_empty():
		shop.show_feedback(message, success)


func _monetisation() -> MonetisationService:
	return get_node_or_null(^"/root/Monetisation") as MonetisationService


## Run loading screen (owner 2026-09-16) before PLAY and Rift Map ENTER: names the arena, loads
## [param paths] (the Endless background) on worker threads, then builds and warms the run beneath
## it (`_prewarm_run`) and reveals that run once the bar completes; nothing is built after the bar.
func _show_run_loading(
		profile: RunProfile,
		paths: PackedStringArray,
		heading: String,
		subheading: String,
	) -> void:
	if _defer_navigation(_show_run_loading.bind(profile, paths, heading, subheading)):
		return
	var loading := LOADING_SCREEN.instantiate() as LoadingScreen
	loading.resources_loaded.connect(_prewarm_run.bind(loading, profile), CONNECT_ONE_SHOT)
	loading.finished.connect(_reveal_prewarmed_run.bind(loading, profile), CONNECT_ONE_SHOT)
	_replace_screen(loading)
	loading.begin_run(paths, heading, subheading, RUN_PREWARM_STEPS)


## Builds the run under the run loading screen, one bar step per frame: build and configure it; add
## it held and frozen, plus one of every enemy kind; then let it draw covered. The loading screen
## moves onto `_loading_cover` so it draws over the whole run (HUD layers included).
func _prewarm_run(_resources: Dictionary, loading: LoadingScreen, profile: RunProfile) -> void:
	var tree: SceneTree = get_tree()
	await tree.process_frame
	if loading != _current_screen:
		return
	var build_usec: int = Time.get_ticks_usec()
	var game: GameWorld = _build_game(profile)
	var build_ms: float = float(Time.get_ticks_usec() - build_usec) / 1000.0
	loading.complete_step()
	await tree.process_frame
	if loading != _current_screen:
		game.free()
		return
	var add_usec: int = Time.get_ticks_usec()
	loading.reparent(_loading_cover, false)
	_prewarm_game = game
	_prewarm_ready = false
	add_child(game)
	game.warm_up_render()
	var add_ms: float = float(Time.get_ticks_usec() - add_usec) / 1000.0
	loading.complete_step()
	for _frame: int in COVER_DRAW_FRAMES + 1:
		await tree.process_frame
	if game != _prewarm_game:
		return
	_prewarm_ready = true
	loading.complete_step()
	print("[Main] run prewarm | build %.1f ms · add+ready+warm %.1f ms" % [build_ms, add_ms])


## The run loading bar completed: covers it, then makes the prewarmed run the screen and reveals it.
func _reveal_prewarmed_run(
		_resources: Dictionary,
		loading: LoadingScreen,
		profile: RunProfile,
	) -> void:
	if loading != _current_screen:
		return
	if _defer_navigation(_reveal_prewarmed_run.bind(_resources, loading, profile)):
		return
	var game: GameWorld = _prewarm_game if _prewarm_ready else null
	if game == null:
		_discard_prewarm()
		_replace_screen(_build_game(profile))
		return
	_prewarm_game = null
	_prewarm_ready = false
	_replace_screen(game)


## Starts a run from a profile Main built; GameWorld never picks the Rift or level itself.
func _show_game(profile: RunProfile) -> void:
	if _defer_navigation(_show_game.bind(profile)):
		return
	_replace_screen(_build_game(profile))


## A configured GameWorld for `profile`, not yet in the tree. With transitions on it is held and
## frozen until Main reveals it (`GameWorld.hold_start`).
func _build_game(profile: RunProfile) -> GameWorld:
	var snapshot: Dictionary = _save_manager.get_snapshot()
	profile.dash_style = DASH_STYLE_CATALOG.get_style(
		StringName(str(snapshot.get(&"equipped_dash_style", "")))
	)
	_active_profile = profile
	var game := _instantiate(&"game") as GameWorld
	game.run_seed = profile.run_seed
	game.configure_run(profile)
	game.home_requested.connect(_show_home)
	game.restart_requested.connect(_restart_run)
	game.run_ended.connect(_show_results)
	if transitions_enabled:
		game.hold_start()
		game.process_mode = Node.PROCESS_MODE_DISABLED
	return game


## Replays the same profile: the same daily run, Endless rebuilt on the equipped skin, or the same Rift level with first-clear eligibility re-read from the save (a replay of a
## level just cleared pays the repeat bonus).
func _restart_run() -> void:
	var profile: RunProfile = _active_profile
	if profile == null:
		_on_play_requested(false)
	elif profile.is_story():
		_start_story(profile.rift, profile.level)
	elif profile.mode == RunProfile.MODE_ENDLESS:
		_on_play_requested(false)
	else:
		_on_daily_play_requested(profile.daily_date_key, profile.run_seed)


## Results' NEXT LEVEL: the next level of the Rift just played.
func _on_next_level_requested() -> void:
	if _active_profile == null or not _active_profile.is_story():
		_start_story(RIFT_CATALOG.get_rift(RiftCatalog.DEFAULT_RIFT_ID))
		return
	_start_story(_active_profile.rift)


## Results' ENTER <RIFT>: selects the Rift this clear opened and plays its next level.
func _on_enter_rift_requested(rift_id: StringName) -> void:
	_on_rift_play_requested(rift_id)


## Banks a finished run, then shows Results with the Rift Points breakdown.
##
## Every source reaches the balance exactly once: `record_run` adds the run's collected and
## performance RP, then challenges, Trials and depth milestones each pay their own reward. Results
## shows the balance change measured around all four, so what it displays is what was added.
func _show_results(summary: Dictionary) -> void:
	SoundFx.music_state(0.0, false)
	var balance_before: int = _save_manager.get_rift_points()
	var levels_before: Dictionary = (
		_save_manager.get_snapshot()[&"rift_levels"] as Dictionary
	).duplicate()
	_save_manager.record_run(summary)
	var snapshot: Dictionary = _save_manager.get_snapshot()
	# A clear that opens a Rift makes it the selection, so the Rift Map opens on it.
	var opened: Array[StringName] = ContentUnlocks.get_newly_unlocked(
		levels_before, snapshot[&"rift_levels"] as Dictionary, RIFT_CATALOG
	)
	if not opened.is_empty():
		_save_manager.select_rift(opened[0])
		snapshot = _save_manager.get_snapshot()
	var challenge_date: String = str(summary.get(&"daily_date", ""))
	if challenge_date.is_empty():
		challenge_date = ChallengeTracker.get_date_key()
	var challenge_result: Dictionary = ChallengeTracker.apply_run(
		summary,
		snapshot[&"challenge_state"] as Dictionary,
		snapshot[&"daily_state"] as Dictionary,
		challenge_date,
		bool(summary.get(&"is_daily", false)),
	)
	_save_manager.apply_challenge_result(challenge_result)
	# Trials are the persistent ladder; challenges above are the date-seeded daily rotation.
	var trial_result: Dictionary = TrialTracker.apply_run(
		_save_manager.get_trial_rank(),
		_save_manager.get_trial_progress(),
		summary,
	)
	_save_manager.apply_trial_result(trial_result)
	# Depth milestones are keyed on the lifetime best wave, so record_run must land first.
	var depth_result: Dictionary = _save_manager.claim_depth_milestones()
	snapshot = _save_manager.get_snapshot()
	var display_summary: Dictionary = summary.duplicate(true)
	display_summary[&"best_score"] = _mode_best_score(summary, snapshot)
	display_summary[&"rift_points_total"] = int(snapshot[&"rift_points"])
	display_summary[&"rp_rewards"] = (
		int(challenge_result[&"reward_points"])
		+ int(trial_result[&"reward_points"])
		+ int(depth_result[&"reward_points"])
	)
	display_summary[&"rp_earned"] = int(snapshot[&"rift_points"]) - balance_before
	var parts: int = (
		maxi(0, int(summary.get(&"rp_collected", 0)))
		+ maxi(0, int(summary.get(&"rp_performance", 0)))
		+ maxi(0, int(summary.get(&"rp_clear_bonus", 0)))
		+ int(display_summary[&"rp_rewards"])
	)
	if int(display_summary[&"rp_earned"]) != parts:
		# Only the balance cap should ever cause this; anything else means a source paid twice.
		push_warning("[Main] Results RP total %d != collected + performance + clear + rewards %d" % [
			int(display_summary[&"rp_earned"]), parts,
		])
	display_summary[&"depth_reward"] = int(depth_result[&"reward_points"])
	display_summary[&"trial_rank"] = int(trial_result[&"rank"])
	display_summary[&"trials_completed"] = (
		trial_result[&"completed"] as PackedStringArray
	).size()
	if str(summary.get(&"mode", "")) == String(RunProfile.MODE_STORY):
		var played: RiftData = RIFT_CATALOG.get_rift(StringName(str(summary.get(&"rift", ""))))
		display_summary[&"rift_name"] = played.display_name
		display_summary[&"mastered"] = ContentUnlocks.is_mastered(
			played, snapshot[&"rift_levels"] as Dictionary
		)
	else:
		var arena: ArenaSkinData = ENDLESS_CATALOG.get_skin(
			StringName(str(summary.get(&"skin_id", "")))
		)
		display_summary[&"arena_name"] = arena.display_name if arena != null else ""
	var opened_names := PackedStringArray()
	for rift_id: StringName in opened:
		opened_names.append(RIFT_CATALOG.get_rift(rift_id).display_name)
	display_summary[&"opened_rift_ids"] = opened
	display_summary[&"opened_rift_names"] = opened_names
	_present_results(display_summary)


## Shows Results for a run already banked; also how a Shop opened from Results returns to it.
func _present_results(display_summary: Dictionary) -> void:
	if _defer_navigation(_present_results.bind(display_summary)):
		return
	_last_results_summary = display_summary
	var results := _instantiate(&"results") as ResultsScreen
	results.restart_requested.connect(_restart_run)
	results.next_level_requested.connect(_on_next_level_requested)
	results.enter_rift_requested.connect(_on_enter_rift_requested)
	results.home_requested.connect(_show_home)
	results.wisps_requested.connect(_show_shop.bind(ShopScreen.TAB_WISPS, true))
	_replace_screen(results)
	results.setup(display_summary)


## The best score Results compares against: Endless's own best, today's daily best, or the
## lifetime best for a story run.
func _mode_best_score(summary: Dictionary, snapshot: Dictionary) -> int:
	match str(summary.get(&"mode", "")):
		"endless":
			return int(snapshot.get(&"endless_best_score", 0))
		"daily":
			var daily_state: Dictionary = snapshot.get(&"daily_state", {}) as Dictionary
			var bests: Dictionary = daily_state.get(&"best_scores", {}) as Dictionary
			var date_key: String = str(summary.get(&"daily_date", ""))
			return maxi(int(bests.get(date_key, 0)), int(summary.get(&"score", 0)))
	return int(snapshot[&"best_score"])


## Whether a screen change is queued, covering, building or revealing, or a loading screen is still
## up (a run may be prewarming beneath it). Tools and tests wait on it.
func is_navigating() -> bool:
	return _nav_phase != NavPhase.IDLE or _nav_request.is_valid() or _current_screen is LoadingScreen


## Makes `next_screen` the only regular child and releases the old screen: freed, or only detached
## for the kept Home. With transitions on this only runs under the veil (`_defer_navigation`).
func _replace_screen(next_screen: Node) -> void:
	var previous: Node = _current_screen
	if previous == next_screen:
		return
	if _prewarm_game != null and next_screen != _prewarm_game:
		_discard_prewarm()
	if previous != null and previous.get_parent() == self:
		remove_child(previous)
	_current_screen = next_screen
	if next_screen.get_parent() != self:
		add_child(next_screen)
	SoundFx.bind_buttons(next_screen)
	UiJuice.bind_press_feedback(next_screen)
	if previous != null:
		_release_screen(previous)
	if (
		OS.is_debug_build()
		and DisplayServer.get_name() != "headless"
		and not _nav_building
		and _switch_started_usec > 0
	):
		# A change outside the veil (the boot screen): measured from its own stamp.
		var ms: float = float(Time.get_ticks_usec() - _switch_started_usec) / 1000.0
		_report_switch(str(next_screen.name), ms, ms, 0.0)
	_switch_started_usec = 0


## Navigation entry for every screen builder: with transitions on, queues [param request] (latest
## wins), starts the veil at once and returns true; the builder then runs on a later frame, fully
## covered. Returns false when the caller should build now: transitions off, no screen yet, or Main
## is already running the queued request.
func _defer_navigation(request: Callable) -> bool:
	if _nav_building or not transitions_enabled or _current_screen == null or not is_inside_tree():
		return false
	_nav_request = request
	if _nav_phase == NavPhase.IDLE or _nav_phase == NavPhase.REVEALING:
		if _nav_phase == NavPhase.IDLE:
			_nav_started_usec = Time.get_ticks_usec()
			_nav_worst_ms = 0.0
		_nav_phase = NavPhase.COVERING
		_nav_last_usec = Time.get_ticks_usec()
		_veil.visible = true
		var tree: SceneTree = get_tree()
		if not tree.process_frame.is_connected(_step_navigation):
			tree.process_frame.connect(_step_navigation)
	return true


func _step_navigation() -> void:
	var now_usec: int = Time.get_ticks_usec()
	var frame_ms: float = float(now_usec - _nav_last_usec) / 1000.0
	_nav_last_usec = now_usec
	_nav_worst_ms = maxf(_nav_worst_ms, frame_ms)
	var step: float = minf(frame_ms / 1000.0, TRANSITION_MAX_STEP)
	match _nav_phase:
		NavPhase.COVERING:
			_nav_alpha = minf(1.0, _nav_alpha + step / COVER_SECONDS)
			if _nav_alpha >= 1.0:
				_run_navigation_request()
		NavPhase.BUILT:
			_nav_draw_frames -= 1
			if _nav_draw_frames <= 0:
				if _nav_request.is_valid():
					_run_navigation_request()
				else:
					_begin_reveal()
		NavPhase.REVEALING:
			_nav_reveal_time += step
			var progress: float = clampf(_nav_reveal_time / maxf(_nav_reveal_seconds, 0.001), 0.0, 1.0)
			# Ease-out cubic: the screen shows quickly, then settles gently.
			var eased: float = 1.0 - pow(1.0 - progress, 3.0)
			_nav_alpha = 1.0 - eased
			var incoming := _current_screen as Control
			if incoming != null:
				incoming.position.x = _nav_glide * (1.0 - eased)
			if progress >= 1.0:
				_end_navigation()
	_veil.modulate.a = _nav_alpha


## Runs the queued builder under the full veil and starts counting its covered draw frames.
func _run_navigation_request() -> void:
	var request: Callable = _nav_request
	_nav_request = Callable()
	var previous: Node = _current_screen
	var previous_control := previous as Control
	if previous_control != null:
		previous_control.position.x = 0.0
	var build_usec: int = Time.get_ticks_usec()
	_nav_building = true
	if request.is_valid():
		request.call()
	_nav_building = false
	_nav_build_ms = float(Time.get_ticks_usec() - build_usec) / 1000.0
	_nav_alpha = 1.0
	_nav_phase = NavPhase.BUILT
	_nav_draw_frames = COVER_DRAW_FRAMES
	var reduced_motion: bool = bool(_save_manager.get_settings().get(&"reduced_motion", false))
	_nav_reveal_seconds = REDUCED_TRANSITION_SECONDS if reduced_motion else TRANSITION_SECONDS
	_nav_glide = 0.0
	var incoming := _current_screen as Control
	if (
		incoming != null
		and incoming != previous
		and not reduced_motion
		and not incoming is GameWorld
		and not incoming is TutorialScreen
	):
		_nav_glide = -TRANSITION_GLIDE if incoming == _home else TRANSITION_GLIDE
	if incoming != null:
		incoming.position.x = _nav_glide


## The new screen has drawn covered: a held run starts now, and the veil begins to lift.
func _begin_reveal() -> void:
	_nav_phase = NavPhase.REVEALING
	_nav_reveal_time = 0.0
	var game := _current_screen as GameWorld
	if game != null and game.is_start_held():
		game.process_mode = Node.PROCESS_MODE_INHERIT
		game.release_start()


func _end_navigation() -> void:
	_nav_phase = NavPhase.IDLE
	_nav_alpha = 0.0
	_veil.visible = false
	_veil.modulate.a = 0.0
	var tree: SceneTree = get_tree()
	if tree.process_frame.is_connected(_step_navigation):
		tree.process_frame.disconnect(_step_navigation)
	var incoming := _current_screen as Control
	if incoming != null:
		incoming.position.x = 0.0
	if OS.is_debug_build() and DisplayServer.get_name() != "headless" and _current_screen != null:
		var total_ms: float = float(Time.get_ticks_usec() - _nav_started_usec) / 1000.0
		_report_switch(str(_current_screen.name), _nav_build_ms, total_ms, _nav_worst_ms)


## The dark veil every screen change passes under: a full-screen void-charcoal rect on its own
## CanvasLayer above every screen, an internal child so `get_child` never sees it. Also builds the
## (empty) loading cover layer just beneath it.
func _build_veil() -> void:
	var layer := CanvasLayer.new()
	layer.name = "NavigationVeil"
	layer.layer = VEIL_LAYER
	_veil = ColorRect.new()
	_veil.name = "Veil"
	_veil.color = Palette.VOID_CHARCOAL
	_veil.set_anchors_preset(Control.PRESET_FULL_RECT)
	_veil.mouse_filter = Control.MOUSE_FILTER_STOP
	_veil.modulate.a = 0.0
	_veil.visible = false
	layer.add_child(_veil)
	add_child(layer, false, Node.INTERNAL_MODE_FRONT)
	_loading_cover = CanvasLayer.new()
	_loading_cover.name = "LoadingCover"
	_loading_cover.layer = LOADING_COVER_LAYER
	add_child(_loading_cover, false, Node.INTERNAL_MODE_FRONT)


## Frees a run prewarmed under a loading screen that is no longer wanted.
func _discard_prewarm() -> void:
	var game: GameWorld = _prewarm_game
	_prewarm_game = null
	_prewarm_ready = false
	if is_instance_valid(game):
		if game.get_parent() != null:
			game.get_parent().remove_child(game)
		game.queue_free()


## Frees a screen that has left, except the kept Home, which is only detached.
func _release_screen(screen: Node) -> void:
	if screen == _home:
		if screen.get_parent() != null:
			screen.get_parent().remove_child(screen)
		return
	screen.queue_free()


## Debug builds: logs a screen change so navigation hitches show up in logcat - time building under
## the veil, request to fully revealed, the worst frame while it ran, and the worst of the next 20.
func _report_switch(screen_name: String, build_ms: float, total_ms: float, worst_ms: float) -> void:
	var worst_after_ms: float = 0.0
	var last_usec: int = Time.get_ticks_usec()
	for frame: int in 20:
		await get_tree().process_frame
		var now_usec: int = Time.get_ticks_usec()
		worst_after_ms = maxf(worst_after_ms, float(now_usec - last_usec) / 1000.0)
		last_usec = now_usec
	print(
		"[Main] switch %s | build %.1f ms · tap to revealed %.1f ms · worst frame %.1f ms · worst of next 20 %.1f ms"
		% [screen_name, build_ms, total_ms, worst_ms, worst_after_ms]
	)
