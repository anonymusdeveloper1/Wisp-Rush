class_name TrialData
extends Resource
## One persistent goal in the Trials ladder: what it measures, the target, and its Rift Points reward.
##
## Distinct from the date-seeded daily challenges in `ChallengeTracker`: Trials never rotate or
## expire, they are cleared once and banked forever, and they escalate by tier.

## Stable identifier stored in progression data.
@export var trial_id: StringName
## Short uppercase title in the game's voice.
@export var title: String
## One-line player-facing description.
@export var description: String
## Run-summary key this trial reads. Must exist in the GameWorld run summary.
@export var metric: StringName
## Value the metric must reach.
@export_range(1, 1000000, 1) var target: int = 1
## Rift Points granted once when the trial completes.
@export_range(0, 10000, 5) var reward_points: int = 15
## One-based ladder tier; three trials share each tier.
@export_range(1, 50, 1) var tier: int = 1
## True when progress accumulates across runs; false when a single run must hit the target.
@export var cumulative: bool = false


## Progress after one run, given the progress already banked.
##
## Cumulative trials add the run's value; single-run trials keep the best run seen, so a weak run
## can never undo a strong one.
func advance(current_progress: int, run_value: int) -> int:
	var value: int = maxi(0, run_value)
	if cumulative:
		return mini(target, maxi(0, current_progress) + value)
	return mini(target, maxi(maxi(0, current_progress), value))


## Whether banked progress satisfies this trial.
func is_complete(progress: int) -> bool:
	return progress >= target


## Returns authoring failures so the ladder can be checked without opening the editor.
func validate() -> PackedStringArray:
	var failures := PackedStringArray()
	if trial_id.is_empty():
		failures.append("trial id is empty")
	if title.is_empty():
		failures.append("title is empty")
	if metric.is_empty():
		failures.append("metric is empty")
	if target <= 0:
		failures.append("target must be positive")
	if reward_points < 0:
		failures.append("reward is negative")
	return failures
