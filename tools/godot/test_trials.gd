extends SceneTree
## Trials ladder: catalog shape, progress rules, rank-up, rewards and persistence.

const CATALOG: TrialCatalog = preload("res://data/trials/default_catalog.tres")
const SAVE_SCRIPT: Script = preload("res://scripts/autoload/save_manager.gd")

var _failures: int = 0


func _init() -> void:
	call_deferred(&"_run")


func _fail(message: String) -> void:
	_failures += 1
	push_error("trials: %s" % message)


func _run() -> void:
	for failure: String in CATALOG.validate():
		_fail(failure)

	var trials: Array[TrialData] = CATALOG.load_trials()
	if trials.size() != 36:
		_fail("expected 36 trials, found %d" % trials.size())
	if CATALOG.get_tier_count() != 12:
		_fail("expected 12 tiers, found %d" % CATALOG.get_tier_count())
	if CATALOG.get_tier(1).size() != TrialCatalog.TRIALS_PER_TIER:
		_fail("tier 1 does not hold three trials")
	if not CATALOG.get_tier(999).is_empty():
		_fail("a tier past the ladder returned trials")

	# Difficulty must escalate: each tier's survival target beats the one before it.
	var previous_wave: int = 0
	for tier: int in CATALOG.get_tier_count():
		for trial: TrialData in CATALOG.get_tier(tier + 1):
			if trial.metric != &"wave":
				continue
			if trial.target <= previous_wave:
				_fail("tier %d wave target %d does not escalate" % [tier + 1, trial.target])
			previous_wave = trial.target

	# Progress semantics.
	var single: TrialData = null
	var cumulative: TrialData = null
	for trial: TrialData in trials:
		if trial.cumulative and cumulative == null:
			cumulative = trial
		if not trial.cumulative and single == null:
			single = trial
	if single == null or cumulative == null:
		_fail("the ladder needs both single-run and cumulative trials")
	else:
		# A weak run must never undo a strong one on a single-run trial.
		var high: int = single.advance(0, single.target - 1)
		if single.advance(high, 1) != high:
			_fail("a weak run lowered single-run progress")
		if single.advance(0, single.target * 5) != single.target:
			_fail("single-run progress was not capped at the target")
		# Cumulative progress adds up and still caps.
		var step: int = maxi(1, cumulative.target / 4)
		if cumulative.advance(step, step) != step * 2:
			_fail("cumulative progress did not accumulate")
		if cumulative.advance(cumulative.target, 999999) != cumulative.target:
			_fail("cumulative progress was not capped at the target")

	_check_ladder_progression()
	await _check_persistence()

	if _failures == 0:
		print("trials: 36 trials, 12 tiers, escalation, progress rules and rank-up validated")
	quit(_failures)


func _check_ladder_progression() -> void:
	# An empty run must move nothing.
	var idle: Dictionary = TrialTracker.apply_run(1, {}, {})
	if int(idle[&"rank"]) != 1 or int(idle[&"reward_shards"]) != 0:
		_fail("an empty run advanced the ladder")
	if bool(idle[&"ranked_up"]):
		_fail("an empty run reported a rank-up")

	# A run that satisfies every tier-1 target must clear the tier and pay all three rewards.
	var summary: Dictionary = {}
	var expected_reward: int = 0
	for trial: TrialData in CATALOG.get_tier(1):
		summary[trial.metric] = maxi(int(summary.get(trial.metric, 0)), trial.target)
		expected_reward += trial.reward_shards
	var cleared: Dictionary = TrialTracker.apply_run(1, {}, summary)
	if int(cleared[&"rank"]) != 2:
		_fail("clearing tier 1 did not rank up, got rank %d" % int(cleared[&"rank"]))
	if not bool(cleared[&"ranked_up"]):
		_fail("clearing tier 1 did not report a rank-up")
	if int(cleared[&"reward_shards"]) < expected_reward:
		_fail("tier 1 paid %d, expected at least %d" % [
			int(cleared[&"reward_shards"]), expected_reward,
		])
	if (cleared[&"completed"] as PackedStringArray).size() < TrialCatalog.TRIALS_PER_TIER:
		_fail("clearing tier 1 did not report three completions")

	# A completed trial must never pay out twice.
	var repeat: Dictionary = TrialTracker.apply_run(
		int(cleared[&"rank"]), cleared[&"progress"] as Dictionary, summary
	)
	for id_text: String in cleared[&"completed"] as PackedStringArray:
		if id_text in (repeat[&"completed"] as PackedStringArray):
			_fail("%s paid out twice" % id_text)

	# The ladder must stop at the last tier instead of running off the end.
	var last: int = CATALOG.get_tier_count()
	var huge: Dictionary = {}
	for metric: StringName in TrialCatalog.VALID_METRICS:
		huge[metric] = 1000000
	var capped: Dictionary = TrialTracker.apply_run(last, {}, huge)
	if int(capped[&"rank"]) > last:
		_fail("the ladder advanced past its last tier to %d" % int(capped[&"rank"]))
	if not TrialTracker.is_ladder_complete(int(capped[&"rank"]), capped[&"progress"] as Dictionary):
		_fail("a maximal run did not complete the final tier")
	if TrialTracker.get_active_trials(999).is_empty():
		_fail("an out-of-range rank returned no active trials")


func _check_persistence() -> void:
	var save := root.get_node_or_null(^"SaveManager") as SaveManagerService
	if save == null:
		_fail("SaveManager autoload is missing")
		return
	if not save.uses_isolated_storage():
		_fail("refusing to write the owner's real save")
		return
	if save.get_trial_rank() < 1:
		_fail("default trial rank is below one")

	var before: int = int(save.get_snapshot()[&"soul_shards"])
	var result: Dictionary = {
		&"rank": 3,
		&"progress": {"t01_wave": 4},
		&"reward_shards": 45,
	}
	if not save.apply_trial_result(result):
		_fail("applying a trial result failed")
	if save.get_trial_rank() != 3:
		_fail("trial rank did not persist")
	if int(save.get_trial_progress().get("t01_wave", 0)) != 4:
		_fail("trial progress did not persist")
	if int(save.get_snapshot()[&"soul_shards"]) != before + 45:
		_fail("the trial reward was not paid")
	# Cumulative targets run into the thousands, so progress must not be clamped low.
	save.apply_trial_result({&"rank": 3, &"progress": {"t12_score": 25000}, &"reward_shards": 0})
	if int(save.get_trial_progress().get("t12_score", 0)) != 25000:
		_fail("large trial progress was clamped away")

	_check_depth_milestones()


## Depth milestones must run against a private save: the shared isolated save persists between
## suite runs, so a previous run would already have banked them and the test would read as passing
## (or failing) for the wrong reason.
func _check_depth_milestones() -> void:
	var root_dir: String = "user://codex_depth_%d" % Time.get_ticks_usec()
	var save := SAVE_SCRIPT.new() as SaveManagerService
	save.configure_storage_paths(
		root_dir + "/save.json", root_dir + "/tmp.json", root_dir + "/backup.json"
	)
	root.add_child(save)

	if int(save.claim_depth_milestones()[&"reward_shards"]) != 0:
		_fail("a fresh save paid a depth milestone before any run")
	if save.get_claimed_depth() != 0:
		_fail("a fresh save reports claimed depth above zero")

	save.record_run({&"score": 1, &"wave": 12, &"rift": "obsidian_garden"})
	var deep: Dictionary = save.claim_depth_milestones()
	# Wave 12 clears the wave-5 and wave-10 milestones together.
	if int(deep[&"reward_shards"]) != 75:
		_fail("wave 12 paid %d shards, expected 75" % int(deep[&"reward_shards"]))
	if (deep[&"waves"] as PackedInt32Array).size() != 2:
		_fail("wave 12 reported %d milestones, expected 2"
			% (deep[&"waves"] as PackedInt32Array).size())
	if save.get_claimed_depth() != 10:
		_fail("claimed depth is %d, expected 10" % save.get_claimed_depth())

	# Claiming again, and replaying a shallower run, must both pay nothing.
	if int(save.claim_depth_milestones()[&"reward_shards"]) != 0:
		_fail("a depth milestone paid out twice")
	save.record_run({&"score": 1, &"wave": 3, &"rift": "obsidian_garden"})
	if int(save.claim_depth_milestones()[&"reward_shards"]) != 0:
		_fail("a shallow run re-paid a depth milestone")
