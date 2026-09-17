class_name DevUnlock
extends RefCounted
## Developer-only helpers that unlock progression so features can be reached without playing.
##
## Debug builds only: every call routes through `SaveManagerService.debug_*`, which refuse to act
## unless `OS.is_debug_build()`. GDD §13 forbids debug panels in a release, so the Settings card
## that exposes these is hidden in release too.

const RIFTS: RiftCatalog = preload("res://data/rifts/default_catalog.tres")
const TRIALS: TrialCatalog = preload("res://data/trials/default_catalog.tres")
## Rift Points handed out by the "give Rift Points" action.
const RP_GRANT: int = 5000


## Unlocks every Rift by banking level 1 of each one, which opens the next (ADR-0013).
##
## Deeper progress is kept: a Rift already cleared past level 1 is left alone.
static func unlock_rifts(save: SaveManagerService) -> bool:
	if save == null or not save.debug_tools_allowed():
		return false
	var unlocked: bool = true
	for rift: RiftData in RIFTS.load_rifts():
		var banked: int = maxi(1, save.get_rift_level(rift.rift_id))
		unlocked = save.debug_set_rift_level(rift.rift_id, banked) and unlocked
	return unlocked


## Owns every cosmetic form.
static func unlock_forms(save: SaveManagerService) -> bool:
	return save != null and save.debug_unlock_all_forms()


## Completes the whole Trials ladder.
static func complete_trials(save: SaveManagerService) -> bool:
	if save == null:
		return false
	var progress: Dictionary = {}
	for trial: TrialData in TRIALS.load_trials():
		progress[String(trial.trial_id)] = trial.target
	return save.debug_set_trials(maxi(1, TRIALS.get_tier_count()), progress)


## Adds a pile of Rift Points.
static func grant_rift_points(save: SaveManagerService) -> bool:
	if save == null or not save.debug_tools_allowed():
		return false
	return save.add_rift_points(RP_GRANT)


## Runs every unlock above in one go.
static func unlock_everything(save: SaveManagerService) -> bool:
	if save == null or not save.debug_tools_allowed():
		return false
	unlock_rifts(save)
	unlock_forms(save)
	complete_trials(save)
	grant_rift_points(save)
	return true
