extends SceneTree
## Cloud save sync rules (owner 2026-10-05: the newest save wins; ADR-0030), through a stand-in cloud:
## a phone that never synced takes the cloud save, a real change uploads, an incidental save (the
## consent stored at launch) does not, a newer cloud save replaces an older phone save and a newer
## phone save replaces an older cloud one, an unreachable cloud changes nothing, and bytes that are
## not a save never replace progress.

const SAVE_SCRIPT: Script = preload("res://scripts/autoload/save_manager.gd")
const CLOUD_SCRIPT: Script = preload("res://scripts/autoload/cloud_save_service.gd")


## A signed-in cloud holding at most one snapshot.
class FakeCloud extends CloudSaveService.Provider:
	var reachable: bool = true
	var stored: PackedByteArray = PackedByteArray()
	var modified_ms: int = 0
	var writes: int = 0

	func start() -> bool:
		return true

	func sign_in() -> bool:
		return true

	func is_signed_in() -> bool:
		return true

	func load_save(_name: String) -> Dictionary:
		if not reachable:
			return {}
		return {&"found": not stored.is_empty(), &"bytes": stored, &"modified_ms": modified_ms}

	func write_save(_name: String, bytes: PackedByteArray, _description: String, _progress: int) -> bool:
		if not reachable:
			return false
		stored = bytes
		modified_ms = int(Time.get_unix_time_from_system() * 1000.0)
		writes += 1
		return true


var _failures: int = 0
var _dir: String = ""


func _init() -> void:
	call_deferred(&"_run")


func _fail(message: String) -> void:
	_failures += 1
	push_error("cloud_save: %s" % message)


func _make_save(tag: String) -> SaveManagerService:
	var save := SAVE_SCRIPT.new() as SaveManagerService
	save.configure_storage_paths(
		_dir + "/%s_save.json" % tag, _dir + "/%s_tmp.json" % tag, _dir + "/%s_backup.json" % tag
	)
	root.add_child(save)
	save.reset_save()
	return save


func _make_cloud(save: SaveManagerService, cloud: FakeCloud, tag: String) -> CloudSaveService:
	var service := CLOUD_SCRIPT.new() as CloudSaveService
	root.add_child(service)
	service.set_save_manager(save)
	service.set_provider(cloud)
	service.configure_meta_path(_dir + "/%s_cloud_sync.json" % tag)
	return service


## A save from "another phone": the same save format with its own Rift Points.
func _other_phone_bytes(rift_points: int) -> PackedByteArray:
	var other := _make_save("other_%d" % rift_points)
	other.add_rift_points(rift_points)
	var bytes: PackedByteArray = other.export_cloud_save()
	other.queue_free()
	return bytes


func _run() -> void:
	_dir = "user://test_runs/cloud_%d" % Time.get_ticks_usec()
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(_dir))
	var now_ms: int = int(Time.get_unix_time_from_system() * 1000.0)

	# --- A phone that never synced (a reinstall) takes the cloud save, even after a fresh change.
	var cloud := FakeCloud.new()
	cloud.stored = _other_phone_bytes(500)
	cloud.modified_ms = now_ms - 60_000
	var save := _make_save("phone")
	save.mark_tutorial_completed()
	var service := _make_cloud(save, cloud, "phone")
	var restored: Array[bool] = [false]
	service.save_restored.connect(func() -> void: restored[0] = true)
	await service.start()
	if save.get_rift_points() != 500 or not restored[0]:
		_fail("a never-synced phone did not take the cloud save (%d RP)" % save.get_rift_points())
	if cloud.writes != 0:
		_fail("taking the cloud save also uploaded")

	# --- A real change uploads; an incidental save (consent stored at launch) does not.
	save.set_consent_state("granted")
	await service.upload_if_changed()
	if cloud.writes != 0:
		_fail("storing consent counted as progress and uploaded")
	await process_frame
	save.add_rift_points(10)
	await service.upload_if_changed()
	if cloud.writes != 1:
		_fail("a real change did not upload (%d writes)" % cloud.writes)
	else:
		var probe := _make_save("probe")
		probe.import_cloud_save(cloud.stored)
		if probe.get_rift_points() != 510:
			_fail("the upload did not carry the new balance (%d RP)" % probe.get_rift_points())
		probe.queue_free()

	# --- Another phone saved after this phone's last sync, and this phone has nothing newer: the
	# cloud save wins. (Times are set explicitly, all in the past.)
	var t0: int = int(Time.get_unix_time_from_system() * 1000.0)
	service._synced_cloud_ms = t0 - 10_000
	service._local_change_ms = t0 - 20_000
	cloud.stored = _other_phone_bytes(999)
	cloud.modified_ms = t0 - 5_000
	await service.sync()
	if save.get_rift_points() != 999:
		_fail("a newer cloud save did not replace this phone's (%d RP)" % save.get_rift_points())

	# --- Another phone saved, then this phone changed later: this phone's save wins and uploads.
	cloud.stored = _other_phone_bytes(111)
	cloud.modified_ms = t0 - 2_000
	save.add_rift_points(1)
	var writes_before: int = cloud.writes
	await service.sync()
	if save.get_rift_points() != 1000 or cloud.writes != writes_before + 1:
		_fail("a newer phone save did not win (%d RP, %d writes)" % [
			save.get_rift_points(), cloud.writes - writes_before,
		])

	# --- An unreachable cloud changes nothing.
	cloud.reachable = false
	var balance: int = save.get_rift_points()
	if await service.sync() or save.get_rift_points() != balance:
		_fail("an unreachable cloud changed the save or reported success")
	cloud.reachable = true

	# --- A fresh phone whose cloud copy is not a save keeps its own progress.
	var broken := FakeCloud.new()
	broken.stored = "not a save".to_utf8_buffer()
	broken.modified_ms = now_ms
	var fresh := _make_save("fresh")
	fresh.add_rift_points(42)
	var fresh_service := _make_cloud(fresh, broken, "fresh")
	await fresh_service.start()
	if fresh.get_rift_points() != 42:
		_fail("bytes that are not a save replaced progress (%d RP)" % fresh.get_rift_points())

	# --- No cloud save yet: this phone's save is uploaded.
	var empty := FakeCloud.new()
	var first := _make_save("first")
	first.add_rift_points(7)
	var first_service := _make_cloud(first, empty, "first")
	await first_service.start()
	if empty.writes != 1:
		_fail("a phone with no cloud save yet did not upload (%d writes)" % empty.writes)

	if _failures == 0:
		print("cloud_save: first sync, real vs incidental changes, newest wins both ways, unreachable, invalid, first upload OK")
	quit(_failures)
