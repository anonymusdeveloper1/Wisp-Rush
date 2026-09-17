extends SceneTree
## Developer unlock helpers: what they unlock, and that they are debug-build gated.

const SAVE_SCRIPT: Script = preload("res://scripts/autoload/save_manager.gd")
const SETTINGS_SCENE: PackedScene = preload("res://scenes/screens/settings_screen.tscn")
const RIFTS: RiftCatalog = preload("res://data/rifts/default_catalog.tres")
const TRIALS: TrialCatalog = preload("res://data/trials/default_catalog.tres")

var _failures: int = 0


func _init() -> void:
	call_deferred(&"_run")


func _fail(message: String) -> void:
	_failures += 1
	push_error("dev_unlock: %s" % message)


func _fresh_save() -> SaveManagerService:
	var root_dir: String = "user://codex_dev_%d" % Time.get_ticks_usec()
	var save := SAVE_SCRIPT.new() as SaveManagerService
	save.configure_storage_paths(
		root_dir + "/save.json", root_dir + "/tmp.json", root_dir + "/backup.json"
	)
	root.add_child(save)
	return save


func _run() -> void:
	var save: SaveManagerService = _fresh_save()

	# These tests only make sense in a debug build, which is how the suite runs.
	if not save.debug_tools_allowed():
		_fail("debug tools are not allowed in a debug build")
		quit(_failures)
		return

	# --- Nothing unlocked to begin with.
	var snapshot: Dictionary = save.get_snapshot()
	for rift: RiftData in RIFTS.load_rifts():
		if rift.unlock_wave > 0 and rift.is_unlocked(int(snapshot[&"highest_wave"])):
			_fail("%s was unlocked on a fresh save" % rift.rift_id)

	# --- Rifts.
	if not DevUnlock.unlock_rifts(save):
		_fail("unlock_rifts failed")
	var wave: int = int(save.get_snapshot()[&"highest_wave"])
	for rift: RiftData in RIFTS.load_rifts():
		if not rift.is_unlocked(wave):
			_fail("%s still locked at wave %d" % [rift.rift_id, wave])
		if save.get_rift_level(rift.rift_id) <= 0:
			_fail("%s has no level progress after unlock" % rift.rift_id)

	# --- Forms.
	if not DevUnlock.unlock_forms(save):
		_fail("unlock_forms failed")
	var owned: Array = save.get_snapshot()[&"owned_forms"] as Array
	for form_id: String in SaveManagerService.VALID_FORM_IDS:
		if form_id not in owned:
			_fail("form %s was not unlocked" % form_id)

	# --- Trials.
	if not DevUnlock.complete_trials(save):
		_fail("complete_trials failed")
	if save.get_trial_rank() != TRIALS.get_tier_count():
		_fail("trial rank is %d, expected %d" % [
			save.get_trial_rank(), TRIALS.get_tier_count(),
		])
	if not TrialTracker.is_ladder_complete(save.get_trial_rank(), save.get_trial_progress()):
		_fail("the ladder did not read as complete")

	# --- Rift Points.
	var before: int = int(save.get_snapshot()[&"rift_points"])
	if not DevUnlock.grant_rift_points(save):
		_fail("grant_rift_points failed")
	if int(save.get_snapshot()[&"rift_points"]) != before + DevUnlock.RP_GRANT:
		_fail("the Rift Points grant did not land exactly")

	# --- The combined action on a clean save.
	var everything: SaveManagerService = _fresh_save()
	if not DevUnlock.unlock_everything(everything):
		_fail("unlock_everything failed")
	var final: Dictionary = everything.get_snapshot()
	if (final[&"owned_forms"] as Array).size() != SaveManagerService.VALID_FORM_IDS.size():
		_fail("unlock_everything did not grant every form")
	if int(final[&"highest_wave"]) < DevUnlock.get_unlock_wave():
		_fail("unlock_everything did not raise the best wave")
	if int(final[&"rift_points"]) < DevUnlock.RP_GRANT:
		_fail("unlock_everything granted no Rift Points")

	# --- Guards: a null save must be refused rather than crash.
	if DevUnlock.unlock_everything(null):
		_fail("unlock_everything accepted a null save")
	if DevUnlock.grant_rift_points(null) or DevUnlock.unlock_forms(null):
		_fail("a helper accepted a null save")
	if everything.debug_set_rift_level(&"not_a_rift", 5):
		_fail("an unknown rift id was accepted")

	# --- The Settings card exists in a debug build and is wired.
	var settings := SETTINGS_SCENE.instantiate() as SettingsScreen
	root.add_child(settings)
	await process_frame
	var groups := settings.get_node_or_null("%Groups") as VBoxContainer
	if groups == null:
		_fail("Settings has no Groups container")
	else:
		var found: int = 0
		for card: Node in groups.get_children():
			for row: Node in card.get_children():
				for child: Node in row.get_children():
					if child is Label and (child as Label).text.begins_with("DEVELOPER"):
						found += 1
					if child is Button and (child as Button).text.to_upper().contains("SANCTUM"):
						_fail("the developer card still offers a Sanctum action")
					if child is Button and (child as Button).text.to_upper().contains("SHARD"):
						_fail("the developer card still names shards: %s" % (child as Button).text)
		if found != 1:
			_fail("expected exactly one developer card, found %d" % found)
	settings.queue_free()
	await process_frame

	if _failures == 0:
		print("dev_unlock: rifts, forms, trials, Rift Points, guards and the card validated")
	quit(_failures)
