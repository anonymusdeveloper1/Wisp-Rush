extends SceneTree
## Deterministic daily rotation, accumulation and one-shot reward checks.


func _init() -> void:
	var failures: int = 0
	var date_key := "2026-09-11"
	var same_seed: int = ChallengeTracker.get_daily_seed(date_key)
	if same_seed <= 0 or same_seed != ChallengeTracker.get_daily_seed(date_key):
		failures += 1
		push_error("challenge_tracker: seed was not stable and positive")
	var first: Array[Dictionary] = ChallengeTracker.get_challenges(date_key)
	var repeated: Array[Dictionary] = ChallengeTracker.get_challenges(date_key)
	if first.size() != 3 or first != repeated:
		failures += 1
		push_error("challenge_tracker: same date did not return the same three goals")
	var found_rotation: bool = false
	for day: int in range(12, 25):
		if ChallengeTracker.get_challenges("2026-09-%02d" % day) != first:
			found_rotation = true
			break
	if not found_rotation:
		failures += 1
		push_error("challenge_tracker: nearby dates never rotated the goals")

	var summary: Dictionary = {
		&"score": 400,
		&"kills": 100,
		&"multi_kill_dashes": 100,
		&"wave": 100,
		&"highest_combo": 100,
		&"rp_collected": 100,
		&"bosses": 10,
		&"rapid_ricochets": 100,
	}
	var result: Dictionary = ChallengeTracker.apply_run(summary, {}, {}, date_key, true)
	var expected_reward: int = ChallengeTracker.DAILY_COMPLETION_REWARD
	for definition: Dictionary in first:
		expected_reward += int(definition[&"reward"])
	if int(result[&"reward_points"]) != expected_reward:
		failures += 1
		push_error("challenge_tracker: completion reward total was incorrect")
	var repeated_result: Dictionary = ChallengeTracker.apply_run(
		summary,
		result[&"challenge_state"],
		result[&"daily_state"],
		date_key,
		true,
	)
	if int(repeated_result[&"reward_points"]) != 0:
		failures += 1
		push_error("challenge_tracker: already claimed rewards repeated")
	if ChallengeTracker.get_date_key({&"year": 2026, &"month": 9, &"day": 3}) != "2026-09-03":
		failures += 1
		push_error("challenge_tracker: calendar key formatting was incorrect")
	if failures == 0:
		print("challenge_tracker: daily seed, rotation and one-shot rewards passed")
	quit(failures)
