extends CloudSaveService.Provider
## Google Play Games Saved Games through the godot-sdk-integrations Play Games plugin (owner
## 2026-10-05, ADR-0030). It talks to the plugin's Android singleton directly (its methods and
## signals, read from the plugin's own wrapper), so the game does not depend on the plugin's
## GDScript autoload. [CloudSaveService] creates it only on Android when the singleton exists, which
## needs the plugin enabled with the Play Games game ID from Play Console.

## Seconds to wait for Play Games before giving up on one request.
const TIMEOUT_SECONDS: float = 20.0

signal _authenticated(is_authenticated: bool)
signal _loaded(json_data: String)
signal _saved(is_saved: bool)

var _plugin: Object
var _signed_in: bool = false


func start() -> bool:
	_plugin = Engine.get_singleton(CloudSaveService.PLAY_GAMES_SINGLETON)
	if _plugin == null:
		return false
	_plugin.initialize()
	_plugin.connect("userAuthenticated", func(is_authenticated: bool) -> void:
		_signed_in = is_authenticated
		_authenticated.emit(is_authenticated))
	_plugin.connect("gameLoaded", func(json_data: String) -> void: _loaded.emit(json_data))
	_plugin.connect("gameSaved", func(is_saved: bool, _name: String, _description: String) -> void:
		_saved.emit(is_saved))
	_plugin.connect("conflictEmitted", func(json_data: String) -> void:
		print("[CloudSave] Play Games reported a snapshot conflict: %s" % json_data.left(200)))
	_plugin.isAuthenticated()
	_signed_in = await _wait(_authenticated, false)
	return _signed_in


func sign_in() -> bool:
	if _plugin == null:
		return false
	_plugin.signIn()
	_signed_in = await _wait(_authenticated, false)
	return _signed_in


func is_signed_in() -> bool:
	return _signed_in


func load_save(save_name: String) -> Dictionary:
	if not _signed_in:
		return {}
	# create_if_not_found: a player with no cloud save yet gets an empty snapshot back, so "no save"
	# is an answer. A time-out means the cloud was not reached, and then nothing may be overwritten.
	_plugin.loadGame(save_name, true)
	var json_data: Variant = await _wait(_loaded, null)
	if json_data == null:
		return {}
	var parsed: Variant = JSON.parse_string(str(json_data))
	if not parsed is Dictionary or (parsed as Dictionary).is_empty():
		return {}
	var snapshot := parsed as Dictionary
	var metadata: Dictionary = snapshot.get("metadata", {}) as Dictionary
	var content: Variant = snapshot.get("content", [])
	var bytes := PackedByteArray(content) if content is Array else PackedByteArray()
	return {
		&"found": not bytes.is_empty(),
		&"bytes": bytes,
		&"modified_ms": int(metadata.get("lastModifiedTimestamp", 0)),
	}


func write_save(save_name: String, bytes: PackedByteArray, description: String, progress: int) -> bool:
	if not _signed_in:
		return false
	_plugin.saveGame(save_name, description, bytes, 0, progress)
	return await _wait(_saved, false)


## Waits for [param done] or [constant TIMEOUT_SECONDS], whichever comes first; returns the signal's
## value, or [param fallback] on time-out.
func _wait(done: Signal, fallback: Variant) -> Variant:
	var tree := Engine.get_main_loop() as SceneTree
	var state := {&"value": fallback, &"finished": false}
	var finish := func(value: Variant = null) -> void:
		if state[&"finished"]:
			return
		state[&"finished"] = true
		state[&"value"] = value if value != null else fallback
	done.connect(finish, CONNECT_ONE_SHOT)
	var timer := tree.create_timer(TIMEOUT_SECONDS, true)
	while not state[&"finished"] and timer.time_left > 0.0:
		await tree.process_frame
	if done.is_connected(finish):
		done.disconnect(finish)
	return state[&"value"]
