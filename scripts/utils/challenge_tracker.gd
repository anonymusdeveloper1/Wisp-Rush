class_name ChallengeTracker
extends RefCounted
## Produces deterministic offline goals and safely applies one completed run to their progress.

const DAILY_COMPLETION_REWARD: int = 10
const CHALLENGE_COUNT: int = 3
const _SEED_MODULUS: int = 2147483647
const _POOL: Array[Dictionary] = [
	{
		&"id": &"soul_reaper",
		&"title": "SOUL REAPER",
		&"description": "Defeat 25 enemies",
		&"metric": &"kills",
		&"target": 25,
		&"reward": 15,
		&"mode": &"sum",
	},
	{
		&"id": &"chain_master",
		&"title": "CHAIN MASTER",
		&"description": "Complete 5 multi-reap dashes",
		&"metric": &"multi_kill_dashes",
		&"target": 5,
		&"reward": 20,
		&"mode": &"sum",
	},
	{
		&"id": &"rift_diver",
		&"title": "RIFT DIVER",
		&"description": "Reach wave 5",
		&"metric": &"wave",
		&"target": 5,
		&"reward": 20,
		&"mode": &"max",
	},
	{
		&"id": &"unbroken_chain",
		&"title": "UNBROKEN CHAIN",
		&"description": "Reach a 10× combo",
		&"metric": &"highest_combo",
		&"target": 10,
		&"reward": 15,
		&"mode": &"max",
	},
	{
		&"id": &"shard_seeker",
		&"title": "SHARD SEEKER",
		&"description": "Collect 8 Soul Shards",
		&"metric": &"soul_shards",
		&"target": 8,
		&"reward": 15,
		&"mode": &"sum",
	},
	{
		&"id": &"reaper_bane",
		&"title": "REAPER'S BANE",
		&"description": "Defeat the Reaper",
		&"metric": &"bosses",
		&"target": 1,
		&"reward": 25,
		&"mode": &"sum",
	},
	{
		&"id": &"ricochet",
		&"title": "RICOCHET",
		&"description": "Land 4 rapid redirects",
		&"metric": &"rapid_ricochets",
		&"target": 4,
		&"reward": 15,
		&"mode": &"sum",
	},
]


## Returns a local calendar key in YYYY-MM-DD form; an explicit clock dictionary aids tests.
static func get_date_key(datetime: Dictionary = {}) -> String:
	var local_time: Dictionary = datetime
	if local_time.is_empty():
		local_time = Time.get_datetime_dict_from_system()
	return "%04d-%02d-%02d" % [
		int(local_time.get(&"year", 1970)),
		int(local_time.get(&"month", 1)),
		int(local_time.get(&"day", 1)),
	]


## Converts a date key to a stable positive 31-bit seed without network or process hash state.
static func get_daily_seed(date_key: String) -> int:
	var hash_value: int = 5381
	for index: int in date_key.length():
		hash_value = (hash_value * 33 + date_key.unicode_at(index)) % _SEED_MODULUS
	return maxi(1, hash_value)


## Returns exactly three definitions selected and ordered by the date seed.
static func get_challenges(date_key: String) -> Array[Dictionary]:
	var indices: Array[int] = []
	for index: int in _POOL.size():
		indices.append(index)
	var random := RandomNumberGenerator.new()
	random.seed = get_daily_seed(date_key) + 739
	for index: int in range(indices.size() - 1, 0, -1):
		var swap_index: int = random.randi_range(0, index)
		var previous: int = indices[index]
		indices[index] = indices[swap_index]
		indices[swap_index] = previous
	var result: Array[Dictionary] = []
	for index: int in CHALLENGE_COUNT:
		result.append(_POOL[indices[index]].duplicate(true))
	return result


## Applies run metrics, returns deduplicated rewards and replacement persistence dictionaries.
static func apply_run(
		summary: Dictionary,
		challenge_state: Dictionary,
		daily_state: Dictionary,
		date_key: String,
		is_daily: bool,
	) -> Dictionary:
	var next_challenges: Dictionary = challenge_state.duplicate(true)
	var date_state: Dictionary = {}
	if next_challenges.get(date_key) is Dictionary:
		date_state = (next_challenges[date_key] as Dictionary).duplicate(true)
	var progress: Dictionary = {}
	if date_state.get(&"progress") is Dictionary:
		progress = (date_state[&"progress"] as Dictionary).duplicate(true)
	var claimed: Array[String] = []
	if date_state.get(&"claimed") is Array:
		for value: Variant in date_state[&"claimed"] as Array:
			var claimed_id: String = str(value)
			if claimed_id not in claimed:
				claimed.append(claimed_id)

	var reward_shards: int = 0
	var completed_ids: Array[String] = []
	for definition: Dictionary in get_challenges(date_key):
		var challenge_id: String = str(definition[&"id"])
		var metric: StringName = definition[&"metric"] as StringName
		var contribution: int = maxi(0, int(summary.get(metric, 0)))
		var previous: int = maxi(0, int(progress.get(challenge_id, 0)))
		var updated: int = contribution if definition[&"mode"] == &"max" else previous + contribution
		if definition[&"mode"] == &"max":
			updated = maxi(previous, contribution)
		updated = mini(updated, int(definition[&"target"]))
		progress[challenge_id] = updated
		if updated >= int(definition[&"target"]) and challenge_id not in claimed:
			claimed.append(challenge_id)
			completed_ids.append(challenge_id)
			reward_shards += int(definition[&"reward"])
	date_state[&"progress"] = progress
	date_state[&"claimed"] = claimed
	next_challenges[date_key] = date_state

	var next_daily: Dictionary = daily_state.duplicate(true)
	var completed_dates: Array[String] = []
	if next_daily.get(&"completed_dates") is Array:
		for value: Variant in next_daily[&"completed_dates"] as Array:
			var completed_date: String = str(value)
			if completed_date not in completed_dates:
				completed_dates.append(completed_date)
	var best_scores: Dictionary = {}
	if next_daily.get(&"best_scores") is Dictionary:
		best_scores = (next_daily[&"best_scores"] as Dictionary).duplicate(true)
	var daily_rewarded: bool = false
	if is_daily:
		best_scores[date_key] = maxi(
			int(best_scores.get(date_key, 0)),
			maxi(0, int(summary.get(&"score", 0))),
		)
		if date_key not in completed_dates:
			completed_dates.append(date_key)
			reward_shards += DAILY_COMPLETION_REWARD
			daily_rewarded = true
	next_daily[&"completed_dates"] = completed_dates
	next_daily[&"best_scores"] = best_scores
	return {
		&"challenge_state": next_challenges,
		&"daily_state": next_daily,
		&"reward_shards": reward_shards,
		&"completed_ids": completed_ids,
		&"daily_rewarded": daily_rewarded,
	}
