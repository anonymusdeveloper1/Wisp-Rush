class_name TrialCatalog
extends Resource
## The Trials ladder: tiers of three goals, cleared together to rank up.

## Trials presented at once, and therefore trials per tier.
const TRIALS_PER_TIER: int = 3
## Run-summary keys a trial may read. Anything else would silently never progress.
const VALID_METRICS: Array[StringName] = [
	&"score", &"kills", &"highest_combo", &"wave", &"multi_kill_dashes",
	&"rapid_ricochets", &"bosses", &"soul_shards", &"run_level", &"rift_levels_cleared",
]

## Trial `.tres` paths in ladder order; every consecutive group of three forms one tier.
@export var trial_paths: PackedStringArray = PackedStringArray()


## Loads every configured trial while reporting malformed paths.
func load_trials() -> Array[TrialData]:
	var trials: Array[TrialData] = []
	for path: String in trial_paths:
		var resource: Resource = load(path)
		if resource is TrialData:
			trials.append(resource as TrialData)
		else:
			push_error("TrialCatalog could not load TrialData: %s" % path)
	return trials


## Highest tier the ladder defines.
func get_tier_count() -> int:
	return load_trials().size() / TRIALS_PER_TIER


## The three trials for a one-based tier, or an empty array past the end of the ladder.
func get_tier(tier: int) -> Array[TrialData]:
	var trials: Array[TrialData] = load_trials()
	var start: int = (maxi(1, tier) - 1) * TRIALS_PER_TIER
	var result: Array[TrialData] = []
	for offset: int in TRIALS_PER_TIER:
		var index: int = start + offset
		if index < trials.size():
			result.append(trials[index])
	return result


## Returns count, duplicate, metric, escalation and per-trial authoring failures.
func validate() -> PackedStringArray:
	var failures := PackedStringArray()
	var trials: Array[TrialData] = load_trials()
	if trials.is_empty():
		failures.append("catalog has no trials")
	if trials.size() % TRIALS_PER_TIER != 0:
		failures.append("trial count %d is not a whole number of tiers" % trials.size())
	var seen: Dictionary[StringName, bool] = {}
	for index: int in trials.size():
		var trial: TrialData = trials[index]
		if seen.has(trial.trial_id):
			failures.append("duplicate trial id %s" % trial.trial_id)
		seen[trial.trial_id] = true
		if trial.metric not in VALID_METRICS:
			failures.append("%s reads unknown metric %s" % [trial.trial_id, trial.metric])
		var expected_tier: int = index / TRIALS_PER_TIER + 1
		if trial.tier != expected_tier:
			failures.append("%s is tier %d but sits in tier %d" % [
				trial.trial_id, trial.tier, expected_tier,
			])
		for failure: String in trial.validate():
			failures.append("%s: %s" % [trial.trial_id, failure])
	# Rewards must not shrink as the ladder gets harder.
	var previous_reward: int = 0
	for tier: int in get_tier_count():
		var total: int = 0
		for trial: TrialData in get_tier(tier + 1):
			total += trial.reward_shards
		if total < previous_reward:
			failures.append("tier %d rewards less than the tier before it" % (tier + 1))
		previous_reward = total
	return failures
