extends Node
## Composition root: boot loading, navigation between screens, back handling and app lifecycle.
##
## Owns no game state: persistent progress lives in the SaveManager autoload, sound in the Audio
## autoload and run state in GameWorld. Screen scenes are streamed in by the Loading screen.

const LOADING_SCREEN: PackedScene = preload("res://scenes/screens/loading_screen.tscn")
const FORM_CATALOG: FormCatalog = preload("res://data/forms/default_catalog.tres")
const RIFT_CATALOG: RiftCatalog = preload("res://data/rifts/default_catalog.tres")
const SANCTUM_CATALOG: SanctumCatalog = preload("res://data/sanctum/default_catalog.tres")
## Screen scenes streamed in at boot, keyed by screen id.
const SCREEN_PATHS: Dictionary[StringName, String] = {
	&"home": "res://scenes/screens/home_screen.tscn",
	&"forms": "res://scenes/screens/forms_screen.tscn",
	&"daily": "res://scenes/screens/daily_screen.tscn",
	&"rift_map": "res://scenes/screens/rift_map_screen.tscn",
	&"sanctum": "res://scenes/screens/sanctum_screen.tscn",
	&"trials": "res://scenes/screens/trials_screen.tscn",
	&"statistics": "res://scenes/screens/statistics_screen.tscn",
	&"settings": "res://scenes/screens/settings_screen.tscn",
	&"game": "res://scenes/gameplay/game_world.tscn",
	&"results": "res://scenes/screens/results_screen.tscn",
}
## Seconds the dark veil takes to reveal each new screen.
const FADE_SECONDS: float = 0.22
## Colour of the screen-change veil (void charcoal, matches the loading screen and clear colour).
const FADE_COLOR: Color = Palette.VOID_CHARCOAL

var _current_screen: Node
var _active_daily_date: String = ""
var _save_manager: SaveManagerService
var _scenes: Dictionary[StringName, PackedScene] = {}
var _fader: ColorRect


func _ready() -> void:
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
	_create_fader()
	var version: String = Engine.get_version_info()["string"]
	print("[Main] boot ok | godot=%s" % version)
	_show_loading()


func _notification(what: int) -> void:
	match what:
		NOTIFICATION_WM_GO_BACK_REQUEST:
			_handle_back()
		NOTIFICATION_APPLICATION_PAUSED, NOTIFICATION_APPLICATION_FOCUS_OUT:
			SoundFx.set_interrupted(true)
		NOTIFICATION_APPLICATION_RESUMED, NOTIFICATION_APPLICATION_FOCUS_IN:
			if is_inside_tree():
				SoundFx.set_interrupted(get_tree().paused)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"ui_cancel") and not _current_screen is GameWorld:
		get_viewport().set_input_as_handled()
		_handle_back()


func _handle_back() -> void:
	if _current_screen == null or _current_screen is LoadingScreen:
		return
	if _current_screen.has_method(&"handle_back") and bool(_current_screen.call(&"handle_back")):
		return
	if _current_screen is HomeScreen:
		if OS.has_feature("mobile"):
			get_tree().quit()
		return
	_show_home()


func _show_loading() -> void:
	var loading := LOADING_SCREEN.instantiate() as LoadingScreen
	loading.finished.connect(_on_loading_finished)
	_replace_screen(loading)
	var wait_for_audio: bool = DisplayServer.get_name() != "headless" and SoundFx.audio() != null
	loading.begin(PackedStringArray(SCREEN_PATHS.values()), wait_for_audio)


func _on_loading_finished(resources: Dictionary) -> void:
	for key: StringName in SCREEN_PATHS:
		var scene := resources.get(SCREEN_PATHS[key]) as PackedScene
		if scene != null:
			_scenes[key] = scene
	var audio: AudioService = SoundFx.audio()
	if audio != null:
		audio.start_music()
	_show_home.call_deferred()


func _instantiate(key: StringName) -> Node:
	if not _scenes.has(key):
		_scenes[key] = load(SCREEN_PATHS[key]) as PackedScene
	return _scenes[key].instantiate()


func _show_home() -> void:
	get_tree().paused = false
	_active_daily_date = ""
	SoundFx.music_state(0.0, false)
	var snapshot: Dictionary = _save_manager.get_snapshot()
	var home := _instantiate(&"home") as HomeScreen
	home.play_requested.connect(_show_game)
	home.forms_requested.connect(_show_forms)
	home.daily_requested.connect(_show_daily)
	home.rift_map_requested.connect(_show_rift_map)
	home.sanctum_requested.connect(_show_sanctum)
	home.trials_requested.connect(_show_trials)
	home.statistics_requested.connect(_show_statistics)
	home.settings_requested.connect(_show_settings)
	_replace_screen(home)
	home.setup(snapshot, FORM_CATALOG.get_form(StringName(snapshot[&"equipped_form"])))


func _show_forms() -> void:
	var snapshot: Dictionary = _save_manager.get_snapshot()
	var forms := _instantiate(&"forms") as FormsScreen
	forms.back_requested.connect(_show_home)
	forms.purchase_requested.connect(_on_form_purchase_requested)
	forms.equip_requested.connect(_on_form_equip_requested)
	forms.setup(
		int(snapshot[&"soul_shards"]),
		snapshot[&"owned_forms"] as Array,
		StringName(snapshot[&"equipped_form"]),
		int(snapshot[&"bosses_defeated"]),
	)
	_replace_screen(forms)


func _show_trials() -> void:
	var trials := _instantiate(&"trials") as TrialsScreen
	trials.back_requested.connect(_show_home)
	trials.setup(_save_manager.get_trial_rank(), _save_manager.get_trial_progress())
	_replace_screen(trials)


func _show_sanctum() -> void:
	var sanctum := _instantiate(&"sanctum") as SanctumScreen
	sanctum.back_requested.connect(_show_home)
	sanctum.purchase_requested.connect(_on_sanctum_purchase_requested)
	_refresh_sanctum_screen(sanctum, "")
	_replace_screen(sanctum)


## Buys one Sanctum level, enforcing cost and prerequisites before touching the save.
func _on_sanctum_purchase_requested(node_id: StringName) -> void:
	var sanctum := _current_screen as SanctumScreen
	if sanctum == null:
		return
	var node: SanctumNode = SANCTUM_CATALOG.get_node_by_id(node_id)
	if node == null:
		_refresh_sanctum_screen(sanctum, "UNKNOWN RITE")
		return
	var levels: Dictionary = _save_manager.get_sanctum_levels()
	var level: int = int(levels.get(String(node_id), 0))
	var cost: int = node.get_cost(level)
	if cost < 0:
		_refresh_sanctum_screen(sanctum, "ALREADY AWAKENED")
		return
	if not SANCTUM_CATALOG.is_unlocked(node, levels):
		_refresh_sanctum_screen(sanctum, "SEALED — MASTER ITS ROOT FIRST")
		return
	if int(_save_manager.get_snapshot()[&"soul_shards"]) < cost:
		_refresh_sanctum_screen(sanctum, "NOT ENOUGH SHARDS")
		return
	if _save_manager.purchase_sanctum_level(node_id, cost, node.max_level):
		_refresh_sanctum_screen(sanctum, "%s AWAKENED" % node.display_name, true)
	else:
		_refresh_sanctum_screen(sanctum, "THE RITE FAILED")


func _refresh_sanctum_screen(
		sanctum: SanctumScreen,
		message: String,
		success: bool = false,
	) -> void:
	var snapshot: Dictionary = _save_manager.get_snapshot()
	sanctum.setup(int(snapshot[&"soul_shards"]), _save_manager.get_sanctum_levels())
	if not message.is_empty():
		sanctum.show_feedback(message, success)


func _show_rift_map() -> void:
	var rift_map := _instantiate(&"rift_map") as RiftMapScreen
	rift_map.back_requested.connect(_show_home)
	rift_map.play_requested.connect(_on_rift_play_requested)
	rift_map.setup(_save_manager.get_snapshot())
	_replace_screen(rift_map)


## Persists the chosen Rift first, so a run and any restart both read it from the save.
func _on_rift_play_requested(rift_id: StringName) -> void:
	_save_manager.select_rift(rift_id)
	_show_game()


func _show_daily() -> void:
	var date_key: String = ChallengeTracker.get_date_key()
	var daily := _instantiate(&"daily") as DailyScreen
	daily.back_requested.connect(_show_home)
	daily.play_daily_requested.connect(_show_game)
	daily.setup(
		date_key,
		ChallengeTracker.get_daily_seed(date_key),
		_save_manager.get_snapshot(),
	)
	_replace_screen(daily)


func _show_statistics() -> void:
	var statistics := _instantiate(&"statistics") as StatisticsScreen
	statistics.back_requested.connect(_show_home)
	statistics.setup(_save_manager.get_snapshot())
	_replace_screen(statistics)


func _show_settings() -> void:
	var settings := _instantiate(&"settings") as SettingsScreen
	settings.back_requested.connect(_show_home)
	_replace_screen(settings)


func _show_game(daily_date: String = "", daily_seed: int = 0) -> void:
	var snapshot: Dictionary = _save_manager.get_snapshot()
	_active_daily_date = daily_date
	var game := _instantiate(&"game") as GameWorld
	game.tutorial_enabled = not bool(snapshot[&"tutorial_completed"])
	game.run_seed = daily_seed
	game.configure_run_profile(
		FORM_CATALOG.get_form(StringName(snapshot[&"equipped_form"])),
		daily_date,
		RIFT_CATALOG.get_rift(StringName(str(snapshot.get(&"selected_rift", "")))),
		# Resume at the level after the deepest one cleared in this Rift.
		_save_manager.get_rift_level(
			StringName(str(snapshot.get(&"selected_rift", "")))
		) + 1,
		_save_manager.get_sanctum_levels(),
	)
	game.home_requested.connect(_show_home)
	game.restart_requested.connect(_restart_run)
	game.tutorial_completed.connect(_on_tutorial_completed)
	game.run_ended.connect(_show_results)
	_replace_screen(game)


func _restart_run() -> void:
	if _active_daily_date.is_empty():
		_show_game()
	else:
		_show_game(
			_active_daily_date,
			ChallengeTracker.get_daily_seed(_active_daily_date),
		)


func _show_results(summary: Dictionary) -> void:
	SoundFx.music_state(0.0, false)
	_save_manager.record_run(summary)
	var snapshot: Dictionary = _save_manager.get_snapshot()
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
	display_summary[&"best_score"] = int(snapshot[&"best_score"])
	display_summary[&"total_soul_shards"] = int(snapshot[&"soul_shards"])
	display_summary[&"challenge_reward"] = (
		int(challenge_result[&"reward_shards"])
		+ int(trial_result[&"reward_shards"])
		+ int(depth_result[&"reward_shards"])
	)
	display_summary[&"depth_reward"] = int(depth_result[&"reward_shards"])
	display_summary[&"trial_rank"] = int(trial_result[&"rank"])
	display_summary[&"trials_completed"] = (
		trial_result[&"completed"] as PackedStringArray
	).size()
	var results := _instantiate(&"results") as ResultsScreen
	results.restart_requested.connect(_restart_run)
	results.home_requested.connect(_show_home)
	results.forms_requested.connect(_show_forms)
	_replace_screen(results)
	results.setup(display_summary)


func _on_tutorial_completed() -> void:
	_save_manager.mark_tutorial_completed()


func _on_form_purchase_requested(form_id: StringName) -> void:
	var form: FormData = FORM_CATALOG.get_form(form_id)
	var purchased: bool = _save_manager.purchase_form(
		form.form_id,
		form.price,
		form.requires_boss_victory,
	)
	SoundFx.play(&"ui_purchase" if purchased else &"ui_error")
	_refresh_forms_screen(
		"%s CLAIMED" % form.display_name if purchased else "FORM COULD NOT BE CLAIMED",
		purchased,
	)


func _on_form_equip_requested(form_id: StringName) -> void:
	var form: FormData = FORM_CATALOG.get_form(form_id)
	var equipped: bool = _save_manager.equip_form(form.form_id)
	_refresh_forms_screen(
		"%s EQUIPPED" % form.display_name if equipped else "FORM COULD NOT BE EQUIPPED",
		equipped,
	)


func _refresh_forms_screen(message: String, success: bool) -> void:
	if not _current_screen is FormsScreen:
		return
	var forms := _current_screen as FormsScreen
	var snapshot: Dictionary = _save_manager.get_snapshot()
	forms.setup(
		int(snapshot[&"soul_shards"]),
		snapshot[&"owned_forms"] as Array,
		StringName(snapshot[&"equipped_form"]),
		int(snapshot[&"bosses_defeated"]),
	)
	forms.show_feedback(message, success)


func _replace_screen(next_screen: Node) -> void:
	if _current_screen != null:
		remove_child(_current_screen)
		_current_screen.queue_free()
	_current_screen = next_screen
	add_child(_current_screen)
	SoundFx.bind_buttons(_current_screen)
	UiJuice.bind_press_feedback(_current_screen)
	_fade_in()


## Adds the screen-change veil as an internal child so `get_child(0)` stays the current screen.
func _create_fader() -> void:
	var fade_layer := CanvasLayer.new()
	fade_layer.layer = 90
	fade_layer.process_mode = Node.PROCESS_MODE_ALWAYS
	_fader = ColorRect.new()
	_fader.color = FADE_COLOR
	_fader.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fader.set_anchors_preset(Control.PRESET_FULL_RECT)
	_fader.modulate.a = 0.0
	fade_layer.add_child(_fader)
	add_child(fade_layer, false, Node.INTERNAL_MODE_BACK)


func _fade_in() -> void:
	if _fader == null:
		return
	_fader.modulate.a = 1.0
	var tween: Tween = _fader.create_tween()
	tween.tween_property(_fader, "modulate:a", 0.0, FADE_SECONDS).set_trans(
		Tween.TRANS_QUAD
	).set_ease(Tween.EASE_OUT)
