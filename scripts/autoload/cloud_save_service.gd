class_name CloudSaveService
extends Node
## Keeps the save on the player's Google account (owner 2026-10-05, ADR-0030): Google Play Games
## Saved Games on Android, so progress and everything bought survive a reinstall or a new phone.
##
## The game never talks to the Play Games SDK directly: it talks to an injected [CloudSaveService.Provider].
## The default reports no cloud, so on desktop and in tests nothing syncs. On Android, when the Play
## Games plugin's singleton exists, `_ready` installs the Play Games provider, which signs in silently
## at launch; Settings offers SIGN IN when that did not work.
##
## Sync (owner: the newest save wins): the whole save is one snapshot. At sign-in the snapshot is
## loaded and compared with this phone's save by time of the last real change: the newer one wins
## and the other side is replaced. A phone that has never synced takes the cloud save when there is
## one (a reinstall or a new phone), so a fresh install cannot overwrite the player's progress.
## After a real change the save is uploaded a few seconds later, and at once when the app is paused.

## The cloud copy changed this phone's save; screens showing progress should refresh.
signal save_restored
## Signed in or out, or a sync started or finished.
signal state_changed

## Name of the one snapshot that holds the save.
const SNAPSHOT_NAME: String = "wisp_rush_save"
## Engine singleton of the Play Games plugin on Android.
const PLAY_GAMES_SINGLETON: String = "GodotPlayGameServices"
## Loaded only on Android, so desktop runs and tests never touch the plugin.
const PLAY_GAMES_PROVIDER_PATH: String = "res://scripts/cloud/play_games_cloud_provider.gd"
## Seconds after a real change before the save is uploaded, so a burst of saves sends one upload.
const UPLOAD_DELAY_SECONDS: float = 5.0
## This phone's sync bookkeeping, beside the save.
const DEFAULT_META_PATH: String = "user://cloud_sync.json"
## Save fields that change without the player doing anything (consent is stored at every launch,
## play time with every save); they do not make the save newer.
const IGNORED_KEYS: Array[StringName] = [&"consent_state", &"play_time_seconds", &"schema_version"]


## Contract a cloud adapter implements; methods that talk to the cloud may wait (`await` them).
class Provider extends RefCounted:
	## Signs in silently. Returns whether the player is signed in.
	func start() -> bool:
		return false

	## Asks the player to sign in. Returns whether they are signed in.
	func sign_in() -> bool:
		return false

	func is_signed_in() -> bool:
		return false

	## Loads the snapshot: {`found`: bool, `bytes`: PackedByteArray, `modified_ms`: int}; an empty
	## Dictionary when the cloud could not be reached.
	func load_save(_name: String) -> Dictionary:
		return {}

	## Writes the snapshot. Returns whether it was stored.
	func write_save(_name: String, _bytes: PackedByteArray, _description: String, _progress: int) -> bool:
		return false


## The default on desktop and in tests: no cloud.
class NullProvider extends Provider:
	pass


var _provider: Provider = NullProvider.new()
var _save: SaveManagerService
var _meta_path: String = DEFAULT_META_PATH
## Cloud time (ms) of the snapshot this phone last uploaded or took; 0 = never synced.
var _synced_cloud_ms: int = 0
## Time (ms) of this phone's last real change to the save.
var _local_change_ms: int = 0
## Fingerprint of the save content that counts, to tell real changes from incidental saves.
var _fingerprint: int = 0
var _importing: bool = false
var _syncing: bool = false
var _upload_in: float = -1.0


func _ready() -> void:
	_save = get_node_or_null(^"/root/SaveManager") as SaveManagerService
	if _save != null:
		_save.progression_changed.connect(_on_progression_changed)
	set_process(false)
	if SaveManagerService.uses_isolated_storage():
		return
	_load_meta()
	if OS.get_name() == "Android" and Engine.has_singleton(PLAY_GAMES_SINGLETON):
		_start_play_games.call_deferred()


func _process(delta: float) -> void:
	if _upload_in < 0.0:
		set_process(false)
		return
	_upload_in -= delta
	if _upload_in <= 0.0:
		_upload_in = -1.0
		set_process(false)
		upload_if_changed()


func _notification(what: int) -> void:
	if what in [NOTIFICATION_APPLICATION_PAUSED, NOTIFICATION_APPLICATION_FOCUS_OUT]:
		upload_if_changed()


func _start_play_games() -> void:
	var provider := load(PLAY_GAMES_PROVIDER_PATH).new() as Provider
	if provider != null:
		set_provider(provider)
		await start()


## Injects a cloud adapter (Android at boot, a stand-in in tests).
func set_provider(provider: Provider) -> void:
	_provider = provider if provider != null else NullProvider.new()


## Uses [param save] instead of the SaveManager autoload (headless tests build their own).
func set_save_manager(save: SaveManagerService) -> void:
	if _save != null and _save.progression_changed.is_connected(_on_progression_changed):
		_save.progression_changed.disconnect(_on_progression_changed)
	_save = save
	if _save != null:
		_save.progression_changed.connect(_on_progression_changed)


## Points the bookkeeping file elsewhere and reads it (tests use their own).
func configure_meta_path(path: String) -> void:
	_meta_path = path
	_load_meta()


## Whether this build has a cloud at all (Settings hides the row when it has not).
func is_supported() -> bool:
	return not (_provider is NullProvider)


func is_signed_in() -> bool:
	return _provider.is_signed_in()


func is_syncing() -> bool:
	return _syncing


## Silent sign-in, then a sync. A coroutine.
func start() -> bool:
	var signed_in: bool = await _provider.start()
	state_changed.emit()
	print("[CloudSave] Play Games %s" % ("signed in" if signed_in else "not signed in"))
	if signed_in:
		await sync()
	return signed_in


## The player tapped SIGN IN in Settings. A coroutine.
func sign_in() -> bool:
	var signed_in: bool = await _provider.sign_in()
	state_changed.emit()
	if signed_in:
		await sync()
	return signed_in


## Compares the cloud snapshot with this phone's save; the newer one wins (see the class notes).
## Returns false when the cloud could not be reached. A coroutine.
func sync() -> bool:
	if _syncing or not _provider.is_signed_in():
		return false
	_syncing = true
	state_changed.emit()
	var cloud: Dictionary = await _provider.load_save(SNAPSHOT_NAME)
	var reached: bool = not cloud.is_empty()
	if reached:
		var found: bool = bool(cloud.get(&"found", false))
		var cloud_ms: int = int(cloud.get(&"modified_ms", 0))
		if not found:
			await _upload()
		elif _synced_cloud_ms == 0 or (cloud_ms > _synced_cloud_ms and _local_change_ms <= cloud_ms):
			_import(cloud.get(&"bytes", PackedByteArray()) as PackedByteArray, cloud_ms)
		elif _local_change_ms > _synced_cloud_ms or cloud_ms > _synced_cloud_ms:
			await _upload()
	_syncing = false
	state_changed.emit()
	return reached


## Uploads now if this phone changed the save since the last sync. A coroutine.
func upload_if_changed() -> void:
	if _provider.is_signed_in() and not _syncing and _local_change_ms > _synced_cloud_ms:
		await _upload()


func _upload() -> void:
	if _save == null:
		return
	var bytes: PackedByteArray = _save.export_cloud_save()
	var snapshot: Dictionary = _save.get_snapshot()
	var progress: int = int(snapshot.get(&"total_runs", 0))
	var stored: bool = await _provider.write_save(SNAPSHOT_NAME, bytes, "Wisp Rush progress", progress)
	if stored:
		_synced_cloud_ms = maxi(_now_ms(), _local_change_ms)
		_save_meta()
	print("[CloudSave] upload %s" % ("stored" if stored else "failed"))


func _import(bytes: PackedByteArray, cloud_ms: int) -> void:
	if _save == null:
		return
	_importing = true
	var imported: bool = _save.import_cloud_save(bytes)
	_importing = false
	if not imported:
		print("[CloudSave] the cloud snapshot is not a valid save; kept this phone's")
		return
	_fingerprint = _content_fingerprint(_save.get_snapshot())
	_synced_cloud_ms = cloud_ms
	_local_change_ms = mini(_local_change_ms, cloud_ms)
	_save_meta()
	print("[CloudSave] restored the cloud save")
	save_restored.emit()


func _on_progression_changed(snapshot: Dictionary) -> void:
	if _importing:
		return
	var fingerprint: int = _content_fingerprint(snapshot)
	if fingerprint == _fingerprint:
		return
	_fingerprint = fingerprint
	_local_change_ms = _now_ms()
	_save_meta()
	if _provider.is_signed_in():
		_upload_in = UPLOAD_DELAY_SECONDS
		set_process(true)


## Hash of the save without the fields that change on their own.
func _content_fingerprint(snapshot: Dictionary) -> int:
	var content: Dictionary = snapshot.duplicate(true)
	for key: StringName in IGNORED_KEYS:
		content.erase(key)
	return hash(JSON.stringify(content, "", true))


func _now_ms() -> int:
	return int(Time.get_unix_time_from_system() * 1000.0)


func _load_meta() -> void:
	_synced_cloud_ms = 0
	_local_change_ms = 0
	_fingerprint = 0
	if FileAccess.file_exists(_meta_path):
		var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(_meta_path))
		if parsed is Dictionary:
			_synced_cloud_ms = int((parsed as Dictionary).get("synced_cloud_ms", 0))
			_local_change_ms = int((parsed as Dictionary).get("local_change_ms", 0))
			_fingerprint = int((parsed as Dictionary).get("fingerprint", 0))
	if _fingerprint == 0 and _save != null:
		_fingerprint = _content_fingerprint(_save.get_snapshot())


func _save_meta() -> void:
	var file := FileAccess.open(_meta_path, FileAccess.WRITE)
	if file == null:
		return
	file.store_string(JSON.stringify({
		"synced_cloud_ms": _synced_cloud_ms,
		"local_change_ms": _local_change_ms,
		"fingerprint": _fingerprint,
	}))
	file.close()
