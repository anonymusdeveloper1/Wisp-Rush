extends SceneTree
## Checks defaults, atomic round trip, backup recovery, type clamping and v0 migration.

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
	if defaults[&"schema_version"] != 1 or defaults[&"owned_forms"] != ["void"]:
		failures += 1
		push_error("save_manager: safe defaults failed")

	manager.add_soul_shards(400)
	manager.mark_tutorial_completed()
	manager.record_run({
		&"score": 1200,
		&"wave": 6,
		&"highest_combo": 8,
		&"kills": 22,
		&"multi_kill_dashes": 4,
		&"bosses": 1,
		&"soul_shards": 35,
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
		or saved[&"soul_shards"] != 185
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
	if recovered[&"best_score"] <= 0 or recovered[&"soul_shards"] < 0:
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
		migrated_data[&"schema_version"] != 1
		or migrated_data[&"best_score"] != 777
		or migrated_data[&"soul_shards"] != 320
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
	if failures == 0:
		print("save_manager: atomic round trip, recovery and migration passed")
	quit(failures)


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
