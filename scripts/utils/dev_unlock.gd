class_name DevUnlock
extends RefCounted
## Developer-only helpers that unlock progression so features can be reached without playing.
##
## Debug builds only: every call routes through `SaveManagerService.debug_*`, which refuse to act
## unless `OS.is_debug_build()`. GDD §13 forbids debug panels in a release, so the Settings card
## that exposes these is hidden in release too.

const RIFTS: RiftCatalog = preload("res://data/rifts/default_catalog.tres")
const SANCTUM: SanctumCatalog = preload("res://data/sanctum/default_catalog.tres")
const TRIALS: TrialCatalog = preload("res://data/trials/default_catalog.tres")
## Shards handed out by the "give shards" action.
const SHARD_GRANT: int = 5000
## Headroom above the deepest Rift gate, so every Rift reads as unlocked.
const WAVE_HEADROOM: int = 5


## Lifetime best wave needed to clear every Rift unlock gate.
static func get_unlock_wave() -> int:
	var deepest: int = 1
	for rift: RiftData in RIFTS.load_rifts():
		deepest = maxi(deepest, rift.unlock_wave)
	return deepest + WAVE_HEADROOM


## Unlocks every Rift by raising the lifetime best wave.
static func unlock_rifts(save: SaveManagerService) -> bool:
	if save == null:
		return false
	var unlocked: bool = save.debug_set_highest_wave(get_unlock_wave())
	# Show a little level progress too, so the map is not a wall of "LEVEL 1 / 8".
	for rift: RiftData in RIFTS.load_rifts():
		save.debug_set_rift_level(rift.rift_id, maxi(1, rift.level_count / 2))
	return unlocked


## Owns every cosmetic form.
static func unlock_forms(save: SaveManagerService) -> bool:
	return save != null and save.debug_unlock_all_forms()


## Maxes every Soul Sanctum node.
static func max_sanctum(save: SaveManagerService) -> bool:
	if save == null:
		return false
	var levels: Dictionary = {}
	for node: SanctumNode in SANCTUM.load_nodes():
		levels[String(node.node_id)] = node.max_level
	return save.debug_set_sanctum_levels(levels)


## Completes the whole Trials ladder.
static func complete_trials(save: SaveManagerService) -> bool:
	if save == null:
		return false
	var progress: Dictionary = {}
	for trial: TrialData in TRIALS.load_trials():
		progress[String(trial.trial_id)] = trial.target
	return save.debug_set_trials(maxi(1, TRIALS.get_tier_count()), progress)


## Adds a pile of Soul Shards.
static func grant_shards(save: SaveManagerService) -> bool:
	if save == null or not save.debug_tools_allowed():
		return false
	return save.add_soul_shards(SHARD_GRANT)


## Runs every unlock above in one go.
static func unlock_everything(save: SaveManagerService) -> bool:
	if save == null or not save.debug_tools_allowed():
		return false
	unlock_rifts(save)
	unlock_forms(save)
	max_sanctum(save)
	complete_trials(save)
	grant_shards(save)
	return true
