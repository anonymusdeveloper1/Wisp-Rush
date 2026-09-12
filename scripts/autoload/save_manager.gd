class_name SaveManagerService
extends Node
## Owns versioned local progression with validation, migration and atomic backup rotation.

## Emitted after persistent progression changes and a save succeeds.
signal progression_changed(snapshot: Dictionary)
## Emitted after settings change and save, with the full validated settings.
signal settings_changed(settings: Dictionary)

const SCHEMA_VERSION: int = 1
const DEFAULT_SAVE_PATH: String = "user://wisp_rush_save.json"
const DEFAULT_TEMP_PATH: String = "user://wisp_rush_save.tmp.json"
const DEFAULT_BACKUP_PATH: String = "user://wisp_rush_save.backup.json"
## Isolated storage for automated runs (see uses_isolated_storage) so they never touch real progress.
const TEST_SAVE_PATH: String = "user://test_runs/wisp_rush_save.json"
const TEST_TEMP_PATH: String = "user://test_runs/wisp_rush_save.tmp.json"
const TEST_BACKUP_PATH: String = "user://test_runs/wisp_rush_save.backup.json"
const VALID_FORM_IDS: Array[String] = [
	"void",
	"ash",
	"venom",
	"bloodmoon",
	"frost",
	"eclipse",
]
const MAX_COUNTER: int = 2000000000

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
		_data = _validate_and_migrate(main_result[&"data"] as Dictionary)
		_main_was_valid = true
		return get_snapshot()
	var backup_result: Dictionary = _read_save_file(_backup_path)
	if bool(backup_result.get(&"valid", false)):
		_data = _validate_and_migrate(backup_result[&"data"] as Dictionary)
		_main_was_valid = false
		push_warning("SaveManager recovered progression from the last valid backup")
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


## Clears first-run lesson completion so the next run replays the tutorial.
func reset_tutorial() -> bool:
	_data[&"tutorial_completed"] = false
	return _save_and_emit()


## Persists completion of the integrated first-run lesson.
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
	_data[&"soul_shards"] = _clamped_add(
		int(_data.get(&"soul_shards", 0)),
		maxi(0, int(summary.get(&"soul_shards", 0))),
	)
	return _save_and_emit()


## Adds a non-negative challenge or daily reward to the persistent balance.
func add_soul_shards(amount: int) -> bool:
	if amount <= 0:
		return false
	_data[&"soul_shards"] = _clamped_add(int(_data.get(&"soul_shards", 0)), amount)
	return _save_and_emit()


## Stores validated challenge/daily progress and adds its already-deduplicated reward.
func apply_challenge_result(result: Dictionary) -> bool:
	_data[&"challenge_state"] = _sanitize_challenge_state(
		result.get(&"challenge_state", {}) as Dictionary
	)
	_data[&"daily_state"] = _sanitize_daily_state(result.get(&"daily_state", {}) as Dictionary)
	var reward: int = clampi(int(result.get(&"reward_shards", 0)), 0, 1000)
	_data[&"soul_shards"] = _clamped_add(int(_data.get(&"soul_shards", 0)), reward)
	return _save_and_emit()


## Purchases one valid form when balance and boss requirement permit it.
func purchase_form(form_id: StringName, price: int, requires_boss: bool = false) -> bool:
	var id_text: String = String(form_id)
	var owned: Array = _data.get(&"owned_forms", ["void"]) as Array
	if (
		id_text not in VALID_FORM_IDS
		or id_text in owned
		or price < 0
		or int(_data.get(&"soul_shards", 0)) < price
		or (requires_boss and int(_data.get(&"bosses_defeated", 0)) <= 0)
	):
		return false
	owned.append(id_text)
	_data[&"owned_forms"] = owned
	_data[&"soul_shards"] = int(_data.get(&"soul_shards", 0)) - price
	return _save_and_emit()


## Equips one owned valid form.
func equip_form(form_id: StringName) -> bool:
	var id_text: String = String(form_id)
	var owned: Array = _data.get(&"owned_forms", ["void"]) as Array
	if id_text not in VALID_FORM_IDS or id_text not in owned:
		return false
	_data[&"equipped_form"] = id_text
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
		&"soul_shards": 0,
		&"owned_forms": ["void"],
		&"equipped_form": "void",
		&"tutorial_completed": false,
		&"challenge_state": {},
		&"daily_state": {&"completed_dates": [], &"best_scores": {}},
		&"settings": {
			&"music_volume": 0.8,
			&"sfx_volume": 0.9,
			&"haptics": true,
			&"reduced_motion": false,
			&"screen_shake": 1.0,
		},
	}


func _validate_and_migrate(source: Dictionary) -> Dictionary:
	var raw: Dictionary = source.duplicate(true)
	var version: int = int(raw.get(&"schema_version", 0))
	if version <= 0:
		raw = _migrate_v0(raw)
	elif version > SCHEMA_VERSION:
		push_warning("SaveManager found a future schema; preserving recognized safe fields")
	var result: Dictionary = _make_defaults()
	for key: StringName in [
		&"best_score",
		&"highest_combo",
		&"total_runs",
		&"total_kills",
		&"total_multi_kills",
		&"bosses_defeated",
		&"soul_shards",
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
	var owned: Array[String] = ["void"]
	if raw.get(&"owned_forms") is Array:
		for value: Variant in raw[&"owned_forms"] as Array:
			var id_text: String = str(value)
			if id_text in VALID_FORM_IDS and id_text not in owned:
				owned.append(id_text)
	result[&"owned_forms"] = owned
	var equipped: String = str(raw.get(&"equipped_form", "void"))
	result[&"equipped_form"] = equipped if equipped in owned else "void"
	if raw.get(&"challenge_state") is Dictionary:
		result[&"challenge_state"] = _sanitize_challenge_state(
			raw[&"challenge_state"] as Dictionary
		)
	if raw.get(&"daily_state") is Dictionary:
		result[&"daily_state"] = _sanitize_daily_state(raw[&"daily_state"] as Dictionary)
	if raw.get(&"settings") is Dictionary:
		result[&"settings"] = _sanitize_settings(raw[&"settings"] as Dictionary)
	return result


func _migrate_v0(old_data: Dictionary) -> Dictionary:
	var migrated: Dictionary = old_data.duplicate(true)
	migrated[&"schema_version"] = SCHEMA_VERSION
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
