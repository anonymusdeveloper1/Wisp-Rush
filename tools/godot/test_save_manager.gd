extends SceneTree
## Checks defaults, atomic round trip, backup recovery, type clamping and v0/v1/v5 migrations.

const SAVE_SCRIPT: Script = preload("res://scripts/autoload/save_manager.gd")


func _init() -> void:
	call_deferred(&"_run_checks")


func _run_checks() -> void:
	var failures: int = 0
	var test_root: String = "user://codex_save_test_%d" % Time.get_ticks_usec()
	var save_path: String = test_root + "/save.json"
	var temp_path: String = test_root + "/save.tmp.json"
	var backup_path: String = test_root + "/save.backup.json"
	var manager := SAVE_SCRIPT.new() as SaveManagerService
	manager.configure_storage_paths(save_path, temp_path, backup_path)
	root.add_child(manager)
	var defaults: Dictionary = manager.get_snapshot()
	if (
		defaults[&"schema_version"] != SaveManagerService.SCHEMA_VERSION
		or defaults[&"owned_forms"] != ["void"]
		or defaults[&"selected_rift"] != SaveManagerService.DEFAULT_RIFT_ID
		or defaults[&"rift_points"] != 0
		or defaults.has(&"soul_shards")
		or defaults.has(&"sanctum_levels")
		or not (defaults[&"rift_bests"] as Dictionary).is_empty()
		# The direction arrow replaced the aim line and is on by default.
		or not bool((defaults[&"settings"] as Dictionary)[&"aim_arrow"])
	):
		failures += 1
		push_error("save_manager: safe defaults failed")

	manager.add_rift_points(400)
	manager.mark_tutorial_completed()
	manager.record_run({
		&"score": 1200,
		&"wave": 6,
		&"highest_combo": 8,
		&"kills": 22,
		&"multi_kill_dashes": 4,
		&"bosses": 1,
		&"rp_collected": 35,
		&"rp_performance": 3,
	})
	if not manager.purchase_form(&"ash", 250) or not manager.equip_form(&"ash"):
		failures += 1
		push_error("save_manager: purchase/equip transaction failed")
	var saved: Dictionary = manager.get_snapshot()
	if (
		saved[&"best_score"] != 1200
		or saved[&"highest_wave"] != 6
		or saved[&"bosses_defeated"] != 1
		or saved[&"equipped_form"] != "ash"
		# 400 granted + 35 collected + 3 performance - 250 for Ash, each counted exactly once.
		or saved[&"rift_points"] != 188
	):
		failures += 1
		push_error("save_manager: run totals or balance failed")

	var reloaded := SAVE_SCRIPT.new() as SaveManagerService
	reloaded.configure_storage_paths(save_path, temp_path, backup_path)
	root.add_child(reloaded)
	if reloaded.get_snapshot()[&"equipped_form"] != "ash":
		failures += 1
		push_error("save_manager: disk round trip failed")

	# Corrupt the main file; reload must accept the previous valid backup instead.
	var corrupt: FileAccess = FileAccess.open(save_path, FileAccess.WRITE)
	corrupt.store_string("{broken")
	corrupt.close()
	var recovered: Dictionary = reloaded.reload()
	if recovered[&"best_score"] <= 0 or recovered[&"rift_points"] < 0:
		failures += 1
		push_error("save_manager: backup recovery failed")

	# A schema-zero save migrates renamed fields and rejects an unowned equipped form.
	var migration_root: String = test_root + "/migration"
	var migration_save: String = migration_root + "/save.json"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(migration_root))
	var legacy: FileAccess = FileAccess.open(migration_save, FileAccess.WRITE)
	legacy.store_string(JSON.stringify({
		"high_score": 777,
		"currency": 320,
		"tutorial_seen": true,
		"unlocked_forms": ["void", "venom", "invalid"],
		"selected_form": "venom",
		"highest_wave": -9,
	}))
	legacy.close()
	var migrated := SAVE_SCRIPT.new() as SaveManagerService
	migrated.configure_storage_paths(
		migration_save,
		migration_root + "/temp.json",
		migration_root + "/backup.json",
	)
	root.add_child(migrated)
	var migrated_data: Dictionary = migrated.get_snapshot()
	if (
		migrated_data[&"schema_version"] != SaveManagerService.SCHEMA_VERSION
		or migrated_data[&"best_score"] != 777
		or migrated_data[&"rift_points"] != 320
		or migrated_data[&"highest_wave"] != 1
		or migrated_data[&"equipped_form"] != "venom"
		or not migrated_data[&"tutorial_completed"]
	):
		failures += 1
		push_error("save_manager: v0 migration or validation failed")

	manager.queue_free()
	reloaded.queue_free()
	migrated.queue_free()
	await process_frame
	_remove_test_tree(test_root)
	var v1_root: String = "user://codex_save_v1_%d" % Time.get_ticks_usec()
	DirAccess.make_dir_recursive_absolute(v1_root)
	var v1_file := FileAccess.open(v1_root + "/save.json", FileAccess.WRITE)
	v1_file.store_string(JSON.stringify({
		"schema_version": 1,
		"best_score": 4200,
		"soul_shards": 55,
		"selected_rift": "frozen_choir",
	}))
	v1_file.close()
	var upgraded := SAVE_SCRIPT.new() as SaveManagerService
	upgraded.configure_storage_paths(
		v1_root + "/save.json",
		v1_root + "/temp.json",
		v1_root + "/backup.json",
	)
	root.add_child(upgraded)
	var upgraded_data: Dictionary = upgraded.get_snapshot()
	if (
		upgraded_data[&"schema_version"] != SaveManagerService.SCHEMA_VERSION
		or upgraded_data[&"best_score"] != 4200
		or upgraded_data[&"rift_points"] != 55
		or upgraded_data.has(&"soul_shards")
		or upgraded_data[&"selected_rift"] != "frozen_choir"
		or not (upgraded_data[&"rift_bests"] as Dictionary).is_empty()
	):
		failures += 1
		push_error("save_manager: v1 to v2 rift migration failed")

	upgraded.queue_free()
	await process_frame
	_remove_test_tree(v1_root)
	failures += await _check_v6_migration()

	if failures == 0:
		print("save_manager: atomic round trip, recovery, v0/v1 and v5 to v6 migration passed")
	quit(failures)


## A v5 save with Soul Shards and Sanctum levels becomes v6: Rift Points = shards + the frozen cost of
## every bought level, `sanctum_levels` gone, renamed ids kept, stable on reload; v6 round-trips.
func _check_v6_migration() -> int:
	var failures: int = 0
	var date_key: String = "2026-09-14"
	var v5_root: String = "user://codex_save_v5_%d" % Time.get_ticks_usec()
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(v5_root))
	var v5_file := FileAccess.open(v5_root + "/save.json", FileAccess.WRITE)
	v5_file.store_string(JSON.stringify({
		"schema_version": 5,
		"best_score": 9100,
		"soul_shards": 300,
		# keen_edge 1..2 = 200 + 320, soul_reserve 1 = 1500; unknown ids refund nothing and a level
		# above a node's cap refunds only up to the cap (first_gift caps at 1 = 900).
		"sanctum_levels": {"keen_edge": 2, "soul_reserve": 1, "not_a_node": 4, "first_gift": 7},
		"owned_forms": ["void", "ash"],
		"equipped_form": "ash",
		"trial_rank": 8,
		"trial_progress": {"t08_soul_shards_m": 31, "t01_wave": 4},
		"challenge_state": {date_key: {"progress": {"shard_seeker": 5}, "claimed": ["shard_seeker"]}},
		"ads_removed": true,
	}))
	v5_file.close()
	var expected_points: int = 300 + 200 + 320 + 1500 + 900
	var paths: PackedStringArray = [
		v5_root + "/save.json", v5_root + "/temp.json", v5_root + "/backup.json",
	]
	var first := SAVE_SCRIPT.new() as SaveManagerService
	first.configure_storage_paths(paths[0], paths[1], paths[2])
	root.add_child(first)
	var data: Dictionary = first.get_snapshot()
	var progress: Dictionary = data[&"trial_progress"] as Dictionary
	var day: Dictionary = (data[&"challenge_state"] as Dictionary).get(date_key, {}) as Dictionary
	if (
		data[&"schema_version"] != 6
		or data[&"rift_points"] != expected_points
		or data.has(&"soul_shards")
		or data.has(&"sanctum_levels")
		or data[&"best_score"] != 9100
		or data[&"equipped_form"] != "ash"
		or not bool(data[&"ads_removed"])
		or int(data[&"trial_rank"]) != 8
		or int(progress.get("t08_rp_collected_m", -1)) != 31
		or progress.has("t08_soul_shards_m")
		or int(progress.get("t01_wave", -1)) != 4
		or int((day.get(&"progress", {}) as Dictionary).get("rp_seeker", -1)) != 5
		or "rp_seeker" not in (day.get(&"claimed", []) as Array)
	):
		failures += 1
		push_error("save_manager: v5 to v6 migration failed: %s" % [data])

	# The migrated save was written back as v6, so a reload refunds nothing a second time.
	var on_disk := JSON.parse_string(FileAccess.get_file_as_string(paths[0])) as Dictionary
	if int(on_disk.get("schema_version", 0)) != 6 or on_disk.has("sanctum_levels"):
		failures += 1
		push_error("save_manager: the v6 migration was not persisted on load")
	var again: Dictionary = first.reload()
	var second := SAVE_SCRIPT.new() as SaveManagerService
	second.configure_storage_paths(paths[0], paths[1], paths[2])
	root.add_child(second)
	if (
		again[&"rift_points"] != expected_points
		or second.get_snapshot()[&"rift_points"] != expected_points
	):
		failures += 1
		push_error("save_manager: reloading a migrated save changed the balance")

	# A v6 save round-trips unchanged.
	second.add_rift_points(80)
	var third := SAVE_SCRIPT.new() as SaveManagerService
	third.configure_storage_paths(paths[0], paths[1], paths[2])
	root.add_child(third)
	if third.get_snapshot() != second.get_snapshot():
		failures += 1
		push_error("save_manager: a v6 save did not round-trip")

	# A save from a future schema is not migrated again: stray shard fields are ignored.
	var future_root: String = v5_root + "_future"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(future_root))
	var future_file := FileAccess.open(future_root + "/save.json", FileAccess.WRITE)
	future_file.store_string(JSON.stringify({
		"schema_version": 7,
		"rift_points": 40,
		"soul_shards": 999,
		"sanctum_levels": {"soul_reserve": 1},
	}))
	future_file.close()
	var future := SAVE_SCRIPT.new() as SaveManagerService
	future.configure_storage_paths(
		future_root + "/save.json", future_root + "/temp.json", future_root + "/backup.json"
	)
	root.add_child(future)
	if future.get_snapshot()[&"rift_points"] != 40:
		failures += 1
		push_error("save_manager: a future-schema save was migrated or refunded")

	for manager: SaveManagerService in [first, second, third, future]:
		manager.queue_free()
	await process_frame
	_remove_test_tree(v5_root)
	_remove_test_tree(future_root)
	return failures


func _remove_test_tree(test_root: String) -> void:
	var absolute_root: String = ProjectSettings.globalize_path(test_root)
	var directory: DirAccess = DirAccess.open(absolute_root)
	if directory == null:
		return
	directory.list_dir_begin()
	var name: String = directory.get_next()
	while not name.is_empty():
		if name != "." and name != "..":
			var child_path: String = absolute_root.path_join(name)
			if directory.current_is_dir():
				_remove_test_tree(test_root.path_join(name))
			else:
				DirAccess.remove_absolute(child_path)
		name = directory.get_next()
	directory.list_dir_end()
	DirAccess.remove_absolute(absolute_root)
