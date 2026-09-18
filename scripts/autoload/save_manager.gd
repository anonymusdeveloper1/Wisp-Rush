class_name SaveManagerService
extends Node
## Owns versioned local progression with validation, migration and atomic backup rotation.

## Emitted after persistent progression changes and a save succeeds.
signal progression_changed(snapshot: Dictionary)
## Emitted after settings change and save, with the full validated settings.
signal settings_changed(settings: Dictionary)

const SCHEMA_VERSION: int = 8
const DEFAULT_SAVE_PATH: String = "user://wisp_rush_save.json"
const DEFAULT_TEMP_PATH: String = "user://wisp_rush_save.tmp.json"
const DEFAULT_BACKUP_PATH: String = "user://wisp_rush_save.backup.json"
## Isolated storage for automated runs (see uses_isolated_storage) so they never touch real progress.
const TEST_SAVE_PATH: String = "user://test_runs/wisp_rush_save.json"
const TEST_TEMP_PATH: String = "user://test_runs/wisp_rush_save.tmp.json"
const TEST_BACKUP_PATH: String = "user://test_runs/wisp_rush_save.backup.json"
## Cosmetic kinds the Shop sells, for `purchase_cosmetic`, `equip_cosmetic`, `owns_cosmetic`.
const KIND_FORM: StringName = &"form"
const KIND_DASH_STYLE: StringName = &"dash_style"
const KIND_ARENA_SKIN: StringName = &"arena_skin"
## Dash style ids come from this catalog. It holds no textures, so the autoload can load it at boot;
## the form and arena catalogs pull in art, so their ids stay listed below and must match the data.
const DASH_STYLE_CATALOG: DashStyleCatalog = preload(
	"res://data/dash_styles/default_dash_style_catalog.tres"
)
## Form identifiers accepted from disk; must match data/forms/default_catalog.tres.
const VALID_FORM_IDS: Array[String] = [
	"void",
	"ash",
	"venom",
	"bloodmoon",
	"frost",
	"eclipse",
	"veyra",
	"rook",
	"morrow",
]
## Rift identifiers accepted from disk; must match data/rifts/default_catalog.tres.
const VALID_RIFT_IDS: Array[String] = [
	"obsidian_garden",
	"shattered_rift",
	"ember_hollow",
	"frozen_choir",
	"reapers_court",
]
const DEFAULT_RIFT_ID: String = "obsidian_garden"
## Endless arena skin ids accepted from disk, in catalog order; must match
## data/endless/default_endless_catalog.tres (test_endless_catalog checks it).
const VALID_ARENA_SKIN_IDS: Array[String] = [
	"astral_observatory",
	"drowned_sanctum",
	"moonpetal_shrine",
	"monastery_yard",
	"dusk_sandstone",
	"slate_cliffs",
	"cold_forge",
	"bamboo_deck",
	"basalt_shore",
	"windswept_hill",
	"rain_rooftops",
	"rootwood_clearing",
	"clockwork_bastion",
	"sky_harbor",
	"quartz_grotto",
	"fungal_hollow",
	"library_of_echoes",
	"old_colosseum",
	"storm_lighthouse",
	"lantern_market",
	"titans_palm",
	"clocktower_crown",
	"storm_anvil",
	"world_tree_crown",
	"galleon_wreck",
	"eclipse_sanctum",
	"starforged_citadel",
	"abyssal_gate",
	"aurora_throne",
	"dragon_skull_throne",
]
## Skin every save owns and unknown ids fall back to (`EndlessCatalog.default_skin_id`).
const DEFAULT_ARENA_SKIN_ID: String = "astral_observatory"
## Retired arena skin ids and the skin that replaces them when a save is sanitized.
const RETIRED_ARENA_SKIN_IDS: Dictionary[String, String] = {
	"placeholder_void_slate": DEFAULT_ARENA_SKIN_ID,
}
## Consent values accepted from disk; anything else falls back to "unknown".
const VALID_CONSENT_STATES: Array[String] = ["unknown", "granted", "denied"]
## Waves that pay a one-time depth reward, and the Rift Points each pays. Keyed on the lifetime
## `highest_wave`; story runs never pass wave 4, so only Endless and daily runs reach them.
const DEPTH_MILESTONES: Array[int] = [5, 10, 15, 20, 25]
const DEPTH_REWARDS: Array[int] = [25, 50, 100, 175, 300]
const MAX_COUNTER: int = 2000000000
## Rift Points cost of each purchased Soul Sanctum level, per node id: index 0 is level 1.
## Frozen at removal, ADR-0013. Resolved from res://data/sanctum/*.tres (SanctumNode.get_cost)
## before that data was deleted; the v6 migration refunds these and nothing else.
const SANCTUM_REFUND_COSTS: Dictionary[String, Array] = {
	"keen_edge": [200, 320, 440],
	"swift_soul": [200, 320, 440],
	"shard_finder": [150, 240, 330, 420],
	"rift_scholar": [160, 260, 360],
	"soul_magnet": [140, 230, 320],
	"long_chain": [180, 310, 440],
	"warded_soul": [220, 370, 520],
	"first_gift": [900],
	"soul_reserve": [1500],
}
## Ids renamed with the currency in v6 (ADR-0013): Trials progress and daily challenge ids.
const V6_TRIAL_RENAMES: Dictionary[String, String] = {"t08_soul_shards_m": "t08_rp_collected_m"}
const V6_CHALLENGE_RENAMES: Dictionary[String, String] = {"shard_seeker": "rp_seeker"}

var _data: Dictionary = {}
var _save_path: String = DEFAULT_SAVE_PATH
var _temp_path: String = DEFAULT_TEMP_PATH
var _backup_path: String = DEFAULT_BACKUP_PATH
var _main_was_valid: bool = false
var _play_time_since_save: float = 0.0


func _ready() -> void:
	# Explicit configure_storage_paths() calls (tests with their own files) take precedence.
	if _save_path == DEFAULT_SAVE_PATH and uses_isolated_storage():
		configure_storage_paths(TEST_SAVE_PATH, TEST_TEMP_PATH, TEST_BACKUP_PATH)
	reload()


## Returns true for automated runs that must never touch the owner's real progress: `--script`
## test runs (a scripted SceneTree replaces the main loop; the shipped game never does) and tool
## runs that export `WISP_ISOLATED_SAVE=1` (tools/validate.sh, tools/screenshot.sh).
static func uses_isolated_storage() -> bool:
	if OS.get_environment("WISP_ISOLATED_SAVE") == "1":
		return true
	var main_loop: MainLoop = Engine.get_main_loop()
	return main_loop != null and main_loop.get_script() != null


func _process(delta: float) -> void:
	_play_time_since_save += maxf(0.0, delta)


func _notification(what: int) -> void:
	if what in [
		NOTIFICATION_APPLICATION_FOCUS_OUT,
		NOTIFICATION_APPLICATION_PAUSED,
		NOTIFICATION_WM_CLOSE_REQUEST,
	]:
		save_now()


func _exit_tree() -> void:
	if not _data.is_empty():
		save_now()


## Replaces storage paths before reload; intended for isolated automated verification.
func configure_storage_paths(save_path: String, temp_path: String, backup_path: String) -> void:
	assert(not save_path.is_empty() and not temp_path.is_empty() and not backup_path.is_empty())
	_save_path = save_path
	_temp_path = temp_path
	_backup_path = backup_path


## Reloads main, then backup, then safe defaults; returns the validated snapshot.
func reload() -> Dictionary:
	_play_time_since_save = 0.0
	var main_result: Dictionary = _read_save_file(_save_path)
	if bool(main_result.get(&"valid", false)):
		var main_data: Dictionary = main_result[&"data"] as Dictionary
		_data = _validate_and_migrate(main_data)
		_main_was_valid = true
		_persist_if_migrated(main_data)
		return get_snapshot()
	var backup_result: Dictionary = _read_save_file(_backup_path)
	if bool(backup_result.get(&"valid", false)):
		var backup_data: Dictionary = backup_result[&"data"] as Dictionary
		_data = _validate_and_migrate(backup_data)
		_main_was_valid = false
		push_warning("SaveManager recovered progression from the last valid backup")
		_persist_if_migrated(backup_data)
		return get_snapshot()
	_data = _make_defaults()
	_main_was_valid = false
	return get_snapshot()


## Returns a deep copy so callers cannot mutate persistent state without a save boundary.
func get_snapshot() -> Dictionary:
	return _data.duplicate(true)


## Atomically writes current state and preserves the previous valid main as backup.
func save_now() -> bool:
	if _data.is_empty():
		_data = _make_defaults()
	_commit_play_time()
	_data[&"schema_version"] = SCHEMA_VERSION
	if not _ensure_parent_directory(_save_path):
		return false
	if not _write_json(_temp_path, _data):
		return false
	var absolute_main: String = ProjectSettings.globalize_path(_save_path)
	var absolute_temp: String = ProjectSettings.globalize_path(_temp_path)
	var absolute_backup: String = ProjectSettings.globalize_path(_backup_path)
	if FileAccess.file_exists(_save_path):
		if _main_was_valid:
			if FileAccess.file_exists(_backup_path):
				DirAccess.remove_absolute(absolute_backup)
			var backup_error: Error = DirAccess.rename_absolute(absolute_main, absolute_backup)
			if backup_error != OK:
				push_error("SaveManager could not rotate the valid backup: %s" % backup_error)
				DirAccess.remove_absolute(absolute_temp)
				return false
		else:
			DirAccess.remove_absolute(absolute_main)
	var replace_error: Error = DirAccess.rename_absolute(absolute_temp, absolute_main)
	if replace_error != OK:
		push_error("SaveManager could not install the new save: %s" % replace_error)
		if not FileAccess.file_exists(_save_path) and FileAccess.file_exists(_backup_path):
			DirAccess.rename_absolute(absolute_backup, absolute_main)
		return false
	_main_was_valid = true
	return true


## Resets all progression to safe defaults and immediately saves it.
func reset_save() -> bool:
	_data = _make_defaults()
	_play_time_since_save = 0.0
	_main_was_valid = FileAccess.file_exists(_save_path)
	var saved: bool = save_now()
	if saved:
		progression_changed.emit(get_snapshot())
		settings_changed.emit(get_settings())
	return saved


## Returns a copy of the validated player settings.
func get_settings() -> Dictionary:
	var settings: Dictionary = _data.get(&"settings", _make_defaults()[&"settings"]) as Dictionary
	return settings.duplicate(true)


## Merges `changes` into the settings, validates, saves and emits `settings_changed`.
func update_settings(changes: Dictionary) -> bool:
	var merged: Dictionary = get_settings()
	for key: Variant in changes:
		merged[StringName(str(key))] = changes[key]
	_data[&"settings"] = _sanitize_settings(merged)
	var saved: bool = _save_and_emit()
	settings_changed.emit(get_settings())
	return saved


## Persists that the Tutorial screen was finished or skipped, so launches open Home from now on
## (replays from the Rift Map never clear it).
func mark_tutorial_completed() -> bool:
	if bool(_data.get(&"tutorial_completed", false)):
		return true
	_data[&"tutorial_completed"] = true
	return _save_and_emit()


## Updates lifetime statistics and adds rewards earned in one completed run.
func record_run(summary: Dictionary) -> bool:
	_data[&"best_score"] = maxi(
		int(_data.get(&"best_score", 0)),
		maxi(0, int(summary.get(&"score", 0))),
	)
	_data[&"highest_wave"] = maxi(
		int(_data.get(&"highest_wave", 1)),
		maxi(1, int(summary.get(&"wave", 1))),
	)
	_data[&"highest_combo"] = maxi(
		int(_data.get(&"highest_combo", 0)),
		maxi(0, int(summary.get(&"highest_combo", 0))),
	)
	_data[&"total_runs"] = _clamped_add(int(_data.get(&"total_runs", 0)), 1)
	_data[&"total_kills"] = _clamped_add(
		int(_data.get(&"total_kills", 0)),
		maxi(0, int(summary.get(&"kills", 0))),
	)
	_data[&"total_multi_kills"] = _clamped_add(
		int(_data.get(&"total_multi_kills", 0)),
		maxi(0, int(summary.get(&"multi_kill_dashes", 0))),
	)
	_data[&"bosses_defeated"] = _clamped_add(
		int(_data.get(&"bosses_defeated", 0)),
		maxi(0, int(summary.get(&"bosses", 0))),
	)
	# Endless owns its bests and run count; a daily run keeps only `daily_state` (via challenges).
	if str(summary.get(&"mode", "")) == "endless":
		_data[&"endless_best_score"] = maxi(
			int(_data.get(&"endless_best_score", 0)), maxi(0, int(summary.get(&"score", 0)))
		)
		_data[&"endless_best_wave"] = maxi(
			int(_data.get(&"endless_best_wave", 0)), maxi(1, int(summary.get(&"wave", 1)))
		)
		_data[&"endless_runs"] = _clamped_add(int(_data.get(&"endless_runs", 0)), 1)
	# The run's own Rift Points: pickups and boss rewards, the score-based performance bonus and the
	# level-clear bonus. Challenge, Trial and depth rewards arrive through their own calls, so nothing
	# is paid twice.
	_data[&"rift_points"] = _clamped_add(
		int(_data.get(&"rift_points", 0)),
		clampi(int(summary.get(&"rp_collected", 0)), 0, MAX_COUNTER)
			+ clampi(int(summary.get(&"rp_performance", 0)), 0, MAX_COUNTER)
			+ clampi(int(summary.get(&"rp_clear_bonus", 0)), 0, MAX_COUNTER),
	)
	var rift_id: String = str(summary.get(&"rift", DEFAULT_RIFT_ID))
	if rift_id in VALID_RIFT_IDS:
		var bests: Dictionary = _data.get(&"rift_bests", {}) as Dictionary
		bests[rift_id] = maxi(
			int(bests.get(rift_id, 0)),
			maxi(0, int(summary.get(&"score", 0))),
		)
		_data[&"rift_bests"] = bests
		# Only a story victory banks its level; `highest_wave` above stays a lifetime statistic.
		var cleared: int = clampi(int(summary.get(&"rift_levels_cleared", 0)), 0, MAX_COUNTER)
		if bool(summary.get(&"level_cleared", false)) and cleared > 0:
			var levels: Dictionary = _data.get(&"rift_levels", {}) as Dictionary
			levels[rift_id] = maxi(int(levels.get(rift_id, 0)), cleared)
			_data[&"rift_levels"] = levels
	return _save_and_emit()


## Adds a non-negative Rift Points reward to the persistent balance.
func add_rift_points(amount: int) -> bool:
	if amount <= 0:
		return false
	_data[&"rift_points"] = _clamped_add(int(_data.get(&"rift_points", 0)), amount)
	return _save_and_emit()


## Current Rift Points balance.
func get_rift_points() -> int:
	return maxi(0, int(_data.get(&"rift_points", 0)))


## Stores validated challenge/daily progress and adds its already-deduplicated `reward_points`.
func apply_challenge_result(result: Dictionary) -> bool:
	_data[&"challenge_state"] = _sanitize_challenge_state(
		result.get(&"challenge_state", {}) as Dictionary
	)
	_data[&"daily_state"] = _sanitize_daily_state(result.get(&"daily_state", {}) as Dictionary)
	var reward: int = clampi(int(result.get(&"reward_points", 0)), 0, 1000)
	_data[&"rift_points"] = _clamped_add(int(_data.get(&"rift_points", 0)), reward)
	return _save_and_emit()


## Buys one cosmetic of `kind` with Rift Points and equips it (buying equips).
##
## Refused without spending when the kind or id is unknown, the item is already owned, the price is
## negative or above the balance, or `requirement_met` is false (the caller reads the gate from the
## item's data, e.g. Eclipse's boss victory). Arena skins are also refused until Endless opens.
func purchase_cosmetic(
	kind: StringName, item_id: StringName, price: int, requirement_met: bool
) -> bool:
	if not _is_cosmetic_kind(kind):
		return false
	var id_text: String = String(item_id)
	var owned: Array = _owned_cosmetics(kind)
	if (
		id_text not in _valid_cosmetic_ids(kind)
		or id_text in owned
		or price < 0
		or get_rift_points() < price
		or not requirement_met
	):
		return false
	owned.append(id_text)
	_data[_owned_key(kind)] = owned
	_data[_equipped_key(kind)] = id_text
	_data[&"rift_points"] = get_rift_points() - price
	return _save_and_emit()


## Equips one owned cosmetic of `kind`.
func equip_cosmetic(kind: StringName, item_id: StringName) -> bool:
	if not owns_cosmetic(kind, item_id):
		return false
	_data[_equipped_key(kind)] = String(item_id)
	return _save_and_emit()


## Whether the save owns the cosmetic `item_id` of `kind`.
func owns_cosmetic(kind: StringName, item_id: StringName) -> bool:
	if not _is_cosmetic_kind(kind):
		return false
	var id_text: String = String(item_id)
	return id_text in _valid_cosmetic_ids(kind) and id_text in _owned_cosmetics(kind)


func _is_cosmetic_kind(kind: StringName) -> bool:
	return kind in [KIND_FORM, KIND_DASH_STYLE, KIND_ARENA_SKIN]


func _owned_cosmetics(kind: StringName) -> Array:
	var owned: Variant = _data.get(_owned_key(kind), [])
	return owned as Array if owned is Array else []


func _owned_key(kind: StringName) -> StringName:
	match kind:
		KIND_FORM:
			return &"owned_forms"
		KIND_DASH_STYLE:
			return &"owned_dash_styles"
	return &"owned_arena_skins"


func _equipped_key(kind: StringName) -> StringName:
	match kind:
		KIND_FORM:
			return &"equipped_form"
		KIND_DASH_STYLE:
			return &"equipped_dash_style"
	return &"equipped_arena_skin"


func _valid_cosmetic_ids(kind: StringName) -> Array[String]:
	match kind:
		KIND_FORM:
			return VALID_FORM_IDS
		KIND_DASH_STYLE:
			return DASH_STYLE_CATALOG.get_style_ids()
	return VALID_ARENA_SKIN_IDS


## Owned ids of one kind read from disk: known ids only, no duplicates, the default always first;
## the equipped id falls back to the default when it is not owned.
func _sanitize_cosmetic(
	raw: Dictionary, result: Dictionary, kind: StringName, default_id: String
) -> void:
	var valid: Array[String] = _valid_cosmetic_ids(kind)
	var owned: Array[String] = [default_id]
	if raw.get(_owned_key(kind)) is Array:
		for value: Variant in raw[_owned_key(kind)] as Array:
			var id_text: String = _current_cosmetic_id(kind, str(value))
			if id_text in valid and id_text not in owned:
				owned.append(id_text)
	result[_owned_key(kind)] = owned
	var equipped: String = _current_cosmetic_id(
		kind, str(raw.get(_equipped_key(kind), default_id))
	)
	result[_equipped_key(kind)] = equipped if equipped in owned else default_id


## Maps a retired cosmetic id to its replacement; other ids pass through unchanged.
func _current_cosmetic_id(kind: StringName, id_text: String) -> String:
	if kind == KIND_ARENA_SKIN:
		return str(RETIRED_ARENA_SKIN_IDS.get(id_text, id_text))
	return id_text


## Selects one known Rift as the arena the next run will use.
func select_rift(rift_id: StringName) -> bool:
	var id_text: String = String(rift_id)
	if id_text not in VALID_RIFT_IDS:
		return false
	_data[&"selected_rift"] = id_text
	return _save_and_emit()


## Whether developer unlock helpers are permitted. Always false in an exported release build.
##
## GDD §13 forbids debug panels in the release, so every `debug_*` method below refuses to do
## anything unless this is true, and the Settings card that calls them is hidden too.
func debug_tools_allowed() -> bool:
	return OS.is_debug_build()


## Grants every cosmetic form without spending Rift Points.
func debug_unlock_all_forms() -> bool:
	if not debug_tools_allowed():
		return false
	_data[&"owned_forms"] = VALID_FORM_IDS.duplicate()
	return _save_and_emit()


## Writes the Trials ladder rank and progress directly.
func debug_set_trials(rank: int, progress: Dictionary) -> bool:
	if not debug_tools_allowed():
		return false
	_data[&"trial_rank"] = clampi(rank, 1, 999)
	_data[&"trial_progress"] = _sanitize_id_counts(progress)
	return _save_and_emit()


## Sets the cleared Rift level for one Rift, so the map shows progress without playing.
func debug_set_rift_level(rift_id: StringName, level: int) -> bool:
	if not debug_tools_allowed():
		return false
	var id_text: String = String(rift_id)
	if id_text not in VALID_RIFT_IDS:
		return false
	var levels: Dictionary = _data.get(&"rift_levels", {}) as Dictionary
	levels[id_text] = clampi(level, 0, MAX_COUNTER)
	_data[&"rift_levels"] = levels
	return _save_and_emit()


func _save_and_emit() -> bool:
	var saved: bool = save_now()
	if saved:
		progression_changed.emit(get_snapshot())
	return saved


func _make_defaults() -> Dictionary:
	return {
		&"schema_version": SCHEMA_VERSION,
		&"best_score": 0,
		&"highest_wave": 1,
		&"highest_combo": 0,
		&"total_runs": 0,
		&"total_kills": 0,
		&"total_multi_kills": 0,
		&"bosses_defeated": 0,
		&"play_time_seconds": 0.0,
		&"rift_points": 0,
		&"owned_forms": ["void"],
		&"equipped_form": "void",
		&"tutorial_completed": false,
		&"selected_rift": DEFAULT_RIFT_ID,
		&"rift_bests": {},
		&"rift_levels": {},
		&"endless_best_score": 0,
		&"endless_best_wave": 0,
		&"endless_runs": 0,
		&"owned_arena_skins": [DEFAULT_ARENA_SKIN_ID],
		&"equipped_arena_skin": DEFAULT_ARENA_SKIN_ID,
		&"owned_dash_styles": [String(DashStyleCatalog.DEFAULT_STYLE_ID)],
		&"equipped_dash_style": String(DashStyleCatalog.DEFAULT_STYLE_ID),
		&"trial_rank": 1,
		&"trial_progress": {},
		&"claimed_depth": 0,
		&"ads_removed": false,
		&"consent_state": "unknown",
		&"challenge_state": {},
		&"daily_state": {&"completed_dates": [], &"best_scores": {}},
		&"settings": {
			&"music_volume": 0.8,
			&"sfx_volume": 0.9,
			&"haptics": true,
			&"reduced_motion": false,
			&"screen_shake": 1.0,
			&"aim_arrow": true,
			&"aim_assist": true,
		},
	}


func _validate_and_migrate(source: Dictionary) -> Dictionary:
	var raw: Dictionary = source.duplicate(true)
	var version: int = _stored_version(raw)
	if version <= 0:
		raw = _migrate_v0(raw)
		version = 5
	elif version > SCHEMA_VERSION:
		push_warning("SaveManager found a future schema; preserving recognized safe fields")
	if version < 6:
		raw = _migrate_to_v6(raw)
	# v6 -> v7 adds the Endless fields and v7 -> v8 the dash style fields; their defaults below are
	# the migration.
	var result: Dictionary = _make_defaults()
	for key: StringName in [
		&"best_score",
		&"highest_combo",
		&"total_runs",
		&"total_kills",
		&"total_multi_kills",
		&"bosses_defeated",
		&"rift_points",
		&"endless_best_score",
		&"endless_best_wave",
		&"endless_runs",
	]:
		result[key] = _safe_int(raw.get(key, result[key]), int(result[key]), 0, MAX_COUNTER)
	result[&"highest_wave"] = _safe_int(raw.get(&"highest_wave", 1), 1, 1, MAX_COUNTER)
	result[&"play_time_seconds"] = _safe_float(
		raw.get(&"play_time_seconds", 0.0),
		0.0,
		0.0,
		315360000.0,
	)
	result[&"tutorial_completed"] = (
		raw[&"tutorial_completed"] if raw.get(&"tutorial_completed") is bool else false
	)
	_sanitize_cosmetic(raw, result, KIND_FORM, "void")
	_sanitize_cosmetic(raw, result, KIND_DASH_STYLE, String(DashStyleCatalog.DEFAULT_STYLE_ID))
	_sanitize_cosmetic(raw, result, KIND_ARENA_SKIN, DEFAULT_ARENA_SKIN_ID)
	var selected_rift: String = str(raw.get(&"selected_rift", DEFAULT_RIFT_ID))
	result[&"selected_rift"] = (
		selected_rift if selected_rift in VALID_RIFT_IDS else DEFAULT_RIFT_ID
	)
	if raw.get(&"rift_bests") is Dictionary:
		result[&"rift_bests"] = _sanitize_rift_bests(raw[&"rift_bests"] as Dictionary)
	if raw.get(&"rift_levels") is Dictionary:
		result[&"rift_levels"] = _sanitize_rift_bests(raw[&"rift_levels"] as Dictionary)
	result[&"trial_rank"] = _safe_int(raw.get(&"trial_rank", 1), 1, 1, 999)
	result[&"claimed_depth"] = _safe_int(raw.get(&"claimed_depth", 0), 0, 0, 9999)
	result[&"ads_removed"] = raw[&"ads_removed"] if raw.get(&"ads_removed") is bool else false
	var consent: String = str(raw.get(&"consent_state", "unknown"))
	result[&"consent_state"] = consent if consent in VALID_CONSENT_STATES else "unknown"
	if raw.get(&"trial_progress") is Dictionary:
		result[&"trial_progress"] = _sanitize_id_counts(
			raw[&"trial_progress"] as Dictionary
		)
	if raw.get(&"challenge_state") is Dictionary:
		result[&"challenge_state"] = _sanitize_challenge_state(
			raw[&"challenge_state"] as Dictionary
		)
	if raw.get(&"daily_state") is Dictionary:
		result[&"daily_state"] = _sanitize_daily_state(raw[&"daily_state"] as Dictionary)
	if raw.get(&"settings") is Dictionary:
		result[&"settings"] = _sanitize_settings(raw[&"settings"] as Dictionary)
	return result


## Stored schema version, or 0 when it is missing or not a number.
func _stored_version(raw: Dictionary) -> int:
	var value: Variant = raw.get(&"schema_version", 0)
	return int(value) if value is int or value is float else 0


## Writes a save loaded from an older schema back out at once, so a migration runs exactly once
## on disk. Future schemas are left untouched.
func _persist_if_migrated(source: Dictionary) -> void:
	if _stored_version(source) < SCHEMA_VERSION:
		save_now()


## v0 (pre-versioned) names → the v5 shape; `_migrate_to_v6` runs next.
func _migrate_v0(old_data: Dictionary) -> Dictionary:
	var migrated: Dictionary = old_data.duplicate(true)
	migrated[&"schema_version"] = 5
	if old_data.has(&"high_score"):
		migrated[&"best_score"] = old_data[&"high_score"]
	if old_data.has(&"currency"):
		migrated[&"soul_shards"] = old_data[&"currency"]
	if old_data.has(&"tutorial_seen"):
		migrated[&"tutorial_completed"] = old_data[&"tutorial_seen"]
	if old_data.has(&"unlocked_forms"):
		migrated[&"owned_forms"] = old_data[&"unlocked_forms"]
	if old_data.has(&"selected_form"):
		migrated[&"equipped_form"] = old_data[&"selected_form"]
	return migrated


## v1–v5 → v6 (ADR-0013): Soul Shards become Rift Points and the Soul Sanctum is refunded.
##
## `soul_shards` carries over as `rift_points`, plus the frozen cost of every Sanctum level the save
## bought (unknown ids refund nothing, levels above a node's cap refund only up to the cap), and
## `sanctum_levels` is dropped. Ids renamed with the currency keep their banked progress. Every
## other key passes through to validation unchanged.
func _migrate_to_v6(old_data: Dictionary) -> Dictionary:
	var migrated: Dictionary = old_data.duplicate(true)
	var balance: int = _safe_int(old_data.get(&"soul_shards", 0), 0, 0, MAX_COUNTER)
	var refund: int = 0
	if old_data.get(&"sanctum_levels") is Dictionary:
		refund = _sanctum_refund(old_data[&"sanctum_levels"] as Dictionary)
	migrated[&"rift_points"] = _clamped_add(balance, refund)
	migrated.erase(&"soul_shards")
	migrated.erase(&"sanctum_levels")
	if migrated.get(&"trial_progress") is Dictionary:
		var progress: Dictionary = migrated[&"trial_progress"] as Dictionary
		for old_id: String in V6_TRIAL_RENAMES:
			if progress.has(old_id):
				progress[V6_TRIAL_RENAMES[old_id]] = progress[old_id]
				progress.erase(old_id)
	if migrated.get(&"challenge_state") is Dictionary:
		for date_state: Variant in (migrated[&"challenge_state"] as Dictionary).values():
			if date_state is Dictionary:
				_rename_challenge_ids(date_state as Dictionary)
	migrated[&"schema_version"] = 6
	return migrated


## Rift Points refunded for Sanctum levels, from the frozen SANCTUM_REFUND_COSTS table.
func _sanctum_refund(levels: Dictionary) -> int:
	var refund: int = 0
	for key: Variant in levels.keys():
		var costs: Array = SANCTUM_REFUND_COSTS.get(str(key), []) as Array
		var level: int = _safe_int(levels[key], 0, 0, costs.size())
		for index: int in level:
			refund += int(costs[index])
	return refund


func _rename_challenge_ids(date_state: Dictionary) -> void:
	if date_state.get(&"progress") is Dictionary:
		var progress: Dictionary = date_state[&"progress"] as Dictionary
		for old_id: String in V6_CHALLENGE_RENAMES:
			if progress.has(old_id):
				progress[V6_CHALLENGE_RENAMES[old_id]] = progress[old_id]
				progress.erase(old_id)
	if date_state.get(&"claimed") is Array:
		var claimed: Array = date_state[&"claimed"] as Array
		for index: int in claimed.size():
			var id_text: String = str(claimed[index])
			if V6_CHALLENGE_RENAMES.has(id_text):
				claimed[index] = V6_CHALLENGE_RENAMES[id_text]


## Whether the player owns the Remove Ads purchase.
func has_removed_ads() -> bool:
	return bool(_data.get(&"ads_removed", false))


## Marks ads removed. Remove Ads carries no currency (ADR-0013), so purchase and restore both
## change nothing else.
func grant_remove_ads() -> bool:
	_data[&"ads_removed"] = true
	return _save_and_emit()


## Stored advertising consent decision.
func get_consent_state() -> String:
	var state: String = str(_data.get(&"consent_state", "unknown"))
	return state if state in VALID_CONSENT_STATES else "unknown"


## Records an advertising consent decision.
func set_consent_state(state: String) -> bool:
	if state not in VALID_CONSENT_STATES:
		return false
	_data[&"consent_state"] = state
	return _save_and_emit()


## Pays every unclaimed depth milestone up to the deepest wave ever reached.
##
## Milestones are one-time and keyed on the lifetime `highest_wave`, so replaying a shallow run
## never pays again and a single deep run can collect several at once.
func claim_depth_milestones() -> Dictionary:
	var reached: int = maxi(1, int(_data.get(&"highest_wave", 1)))
	var claimed: int = maxi(0, int(_data.get(&"claimed_depth", 0)))
	var reward: int = 0
	var waves := PackedInt32Array()
	for index: int in DEPTH_MILESTONES.size():
		var wave: int = DEPTH_MILESTONES[index]
		if wave <= claimed or wave > reached:
			continue
		reward += DEPTH_REWARDS[index]
		waves.append(wave)
		claimed = wave
	if reward <= 0:
		return {&"reward_points": 0, &"waves": waves}
	_data[&"claimed_depth"] = claimed
	_data[&"rift_points"] = _clamped_add(int(_data.get(&"rift_points", 0)), reward)
	_save_and_emit()
	return {&"reward_points": reward, &"waves": waves}


## Deepest milestone wave already paid out.
func get_claimed_depth() -> int:
	return maxi(0, int(_data.get(&"claimed_depth", 0)))


## Current Trials ladder tier, one-based.
func get_trial_rank() -> int:
	return maxi(1, int(_data.get(&"trial_rank", 1)))


## Banked progress for every Trial the player has touched.
func get_trial_progress() -> Dictionary:
	return (_data.get(&"trial_progress", {}) as Dictionary).duplicate()


## Stores a TrialTracker result and pays out its `reward_points`.
func apply_trial_result(result: Dictionary) -> bool:
	_data[&"trial_rank"] = _safe_int(result.get(&"rank", 1), 1, 1, 999)
	if result.get(&"progress") is Dictionary:
		_data[&"trial_progress"] = _sanitize_id_counts(
			result[&"progress"] as Dictionary
		)
	var reward: int = clampi(int(result.get(&"reward_points", 0)), 0, 10000)
	if reward > 0:
		_data[&"rift_points"] = _clamped_add(int(_data.get(&"rift_points", 0)), reward)
	return _save_and_emit()


## Keeps id-to-count maps sane: non-negative, bounded. Used for Trial progress; unknown ids are
## ignored by the catalog when applied.
func _sanitize_id_counts(source: Dictionary) -> Dictionary:
	var result: Dictionary = {}
	for key: Variant in source.keys():
		var id_text: String = str(key)
		if id_text.is_empty():
			continue
		result[id_text] = _safe_int(source[key], 0, 0, MAX_COUNTER)
	return result


## Highest level cleared in one Rift; zero means the player has not finished level 1 yet.
func get_rift_level(rift_id: StringName) -> int:
	var levels: Dictionary = _data.get(&"rift_levels", {}) as Dictionary
	return maxi(0, int(levels.get(String(rift_id), 0)))


## Keeps only known rift ids mapped to sane best scores; drops anything else.
func _sanitize_rift_bests(source: Dictionary) -> Dictionary:
	var result: Dictionary = {}
	for key: Variant in source.keys():
		var id_text: String = str(key)
		if id_text not in VALID_RIFT_IDS:
			continue
		result[id_text] = _safe_int(source[key], 0, 0, MAX_COUNTER)
	return result


func _sanitize_challenge_state(source: Dictionary) -> Dictionary:
	var result: Dictionary = {}
	var accepted_dates: int = 0
	for date_key: Variant in source.keys():
		if accepted_dates >= 400 or not source[date_key] is Dictionary:
			continue
		var entry: Dictionary = source[date_key] as Dictionary
		var progress: Dictionary = {}
		if entry.get(&"progress") is Dictionary:
			for challenge_id: Variant in (entry[&"progress"] as Dictionary).keys():
				progress[str(challenge_id)] = _safe_int(
					(entry[&"progress"] as Dictionary)[challenge_id],
					0,
					0,
					1000000,
				)
		var claimed: Array[String] = []
		if entry.get(&"claimed") is Array:
			for challenge_id: Variant in entry[&"claimed"] as Array:
				var id_text: String = str(challenge_id)
				if not id_text.is_empty() and id_text not in claimed:
					claimed.append(id_text)
		result[str(date_key)] = {&"progress": progress, &"claimed": claimed}
		accepted_dates += 1
	return result


func _sanitize_daily_state(source: Dictionary) -> Dictionary:
	var completed: Array[String] = []
	if source.get(&"completed_dates") is Array:
		for value: Variant in source[&"completed_dates"] as Array:
			var date_text: String = str(value)
			if not date_text.is_empty() and date_text not in completed and completed.size() < 400:
				completed.append(date_text)
	var best_scores: Dictionary = {}
	if source.get(&"best_scores") is Dictionary:
		for date_key: Variant in (source[&"best_scores"] as Dictionary).keys():
			if best_scores.size() >= 400:
				break
			best_scores[str(date_key)] = _safe_int(
				(source[&"best_scores"] as Dictionary)[date_key],
				0,
				0,
				MAX_COUNTER,
			)
	return {&"completed_dates": completed, &"best_scores": best_scores}


func _sanitize_settings(source: Dictionary) -> Dictionary:
	var defaults: Dictionary = _make_defaults()[&"settings"]
	return {
		&"music_volume": _safe_float(source.get(&"music_volume", 0.8), 0.8, 0.0, 1.0),
		&"sfx_volume": _safe_float(source.get(&"sfx_volume", 0.9), 0.9, 0.0, 1.0),
		# The full aim line became a direction arrow (owner decision). A new key, deliberately:
		# every existing save held the old line's default of OFF, which would hide the arrow.
		&"aim_arrow": (
			source[&"aim_arrow"] if source.get(&"aim_arrow") is bool else defaults[&"aim_arrow"]
		),
		# Gentle aim assist (owner decision 2026-09-15); saves without the key read the ON default.
		&"aim_assist": (
			source[&"aim_assist"] if source.get(&"aim_assist") is bool else defaults[&"aim_assist"]
		),
		&"haptics": source[&"haptics"] if source.get(&"haptics") is bool else defaults[&"haptics"],
		&"reduced_motion": (
			source[&"reduced_motion"]
			if source.get(&"reduced_motion") is bool
			else defaults[&"reduced_motion"]
		),
		&"screen_shake": _safe_float(source.get(&"screen_shake", 1.0), 1.0, 0.0, 1.0),
	}


func _read_save_file(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {&"valid": false}
	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {&"valid": false}
	var json := JSON.new()
	var parse_error: Error = json.parse(file.get_as_text())
	file.close()
	if parse_error != OK or not json.data is Dictionary:
		return {&"valid": false}
	return {&"valid": true, &"data": json.data as Dictionary}


func _write_json(path: String, value: Dictionary) -> bool:
	var file: FileAccess = FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		push_error("SaveManager could not open temporary save: %s" % FileAccess.get_open_error())
		return false
	file.store_string(JSON.stringify(value, "\t"))
	file.flush()
	file.close()
	return true


func _ensure_parent_directory(path: String) -> bool:
	var absolute_directory: String = ProjectSettings.globalize_path(path.get_base_dir())
	var error: Error = DirAccess.make_dir_recursive_absolute(absolute_directory)
	if error != OK and error != ERR_ALREADY_EXISTS:
		push_error("SaveManager could not create save directory: %s" % error)
		return false
	return true


func _commit_play_time() -> void:
	if _play_time_since_save <= 0.0:
		return
	_data[&"play_time_seconds"] = clampf(
		float(_data.get(&"play_time_seconds", 0.0)) + _play_time_since_save,
		0.0,
		315360000.0,
	)
	_play_time_since_save = 0.0


func _safe_int(value: Variant, fallback: int, minimum: int, maximum: int) -> int:
	if value is int or value is float:
		return clampi(int(value), minimum, maximum)
	return fallback


func _safe_float(value: Variant, fallback: float, minimum: float, maximum: float) -> float:
	if value is int or value is float:
		return clampf(float(value), minimum, maximum)
	return fallback


func _clamped_add(current: int, amount: int) -> int:
	return clampi(current + amount, 0, MAX_COUNTER)
