class_name TrialTracker
extends RefCounted
## Applies a finished run to the persistent Trials ladder and reports rank-ups and rewards.
##
## Pure and stateless: it takes the banked rank and progress, returns the new ones, and never
## touches SaveManager itself. That keeps the ladder testable without a running game.

const CATALOG: TrialCatalog = preload("res://data/trials/default_catalog.tres")


## Applies one run summary to the ladder.
##
## Returns `rank`, `progress`, `reward_points`, `completed` (trial ids finished by this run) and
## `ranked_up`. A tier only advances once all three of its trials are complete, and the ladder
## stops at the last authored tier rather than running off the end.
static func apply_run(rank: int, progress: Dictionary, summary: Dictionary) -> Dictionary:
	var current_rank: int = maxi(1, rank)
	var banked: Dictionary = progress.duplicate()
	var reward: int = 0
	var completed: PackedStringArray = PackedStringArray()
	var ranked_up: bool = false
	var tier_count: int = CATALOG.get_tier_count()

	# A single run can finish a tier and start biting into the next, so keep going while it does.
	while current_rank <= tier_count:
		var tier: Array[TrialData] = CATALOG.get_tier(current_rank)
		if tier.is_empty():
			break
		var tier_done: bool = true
		for trial: TrialData in tier:
			var key: String = String(trial.trial_id)
			var before: int = maxi(0, int(banked.get(key, 0)))
			if trial.is_complete(before):
				continue
			var run_value: int = maxi(0, int(summary.get(trial.metric, 0)))
			var after: int = trial.advance(before, run_value)
			banked[key] = after
			if trial.is_complete(after):
				reward += trial.reward_points
				completed.append(key)
			else:
				tier_done = false
		if not tier_done:
			break
		if current_rank >= tier_count:
			# Ladder finished; stay on the last tier rather than advancing past it.
			break
		current_rank += 1
		ranked_up = true

	return {
		&"rank": current_rank,
		&"progress": banked,
		&"reward_points": reward,
		&"completed": completed,
		&"ranked_up": ranked_up,
	}


## The three trials the player is currently working on.
static func get_active_trials(rank: int) -> Array[TrialData]:
	return CATALOG.get_tier(clampi(rank, 1, maxi(1, CATALOG.get_tier_count())))


## Whether every authored tier has been cleared.
static func is_ladder_complete(rank: int, progress: Dictionary) -> bool:
	var tier_count: int = CATALOG.get_tier_count()
	if rank < tier_count:
		return false
	for trial: TrialData in CATALOG.get_tier(tier_count):
		if not trial.is_complete(int(progress.get(String(trial.trial_id), 0))):
			return false
	return true
