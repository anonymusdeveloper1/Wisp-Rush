class_name EndlessCatalog
extends Resource
## The Endless arena, the default one, Endless tuning and the enemy mixes and bosses Endless waves
## draw from. The game has one arena, SIMULATION (owner 2026-10-05, ADR-0027); `skins` keeps the list
## shape the save and the daily run read.

## Every arena (one: SIMULATION).
@export var skins: Array[ArenaSkinData] = []
## Skin every save owns and falls back to.
@export var default_skin_id: StringName = &""
## Boss cadence, per-cycle difficulty and the daily pool.
@export var tuning: EndlessTuning
## Enemy mixes Endless waves draw from, in pick order; each brings its boss to the boss pool.
@export var rosters: Array[EndlessRoster] = []


## The skin with `skin_id`, or the default when the id is unknown.
func get_skin(skin_id: StringName) -> ArenaSkinData:
	var fallback: ArenaSkinData = null
	for skin: ArenaSkinData in skins:
		if skin == null:
			continue
		if skin.skin_id == skin_id:
			return skin
		if skin.skin_id == default_skin_id:
			fallback = skin
	if fallback == null and not skins.is_empty():
		fallback = skins[0]
	return fallback


## Every enemy mix, in pick order.
func get_rosters() -> Array[EndlessRoster]:
	return rosters.duplicate()


## The mixes with these ids, in the given order; unknown ids are skipped.
func get_rosters_by_id(roster_ids: Array[StringName]) -> Array[EndlessRoster]:
	var found: Array[EndlessRoster] = []
	for roster_id: StringName in roster_ids:
		for roster: EndlessRoster in rosters:
			if roster != null and roster.roster_id == roster_id:
				found.append(roster)
				break
	return found


## Bosses Endless may send: every mix's boss, in pick order, no repeats.
func get_boss_ids() -> Array[StringName]:
	var ids: Array[StringName] = []
	for roster: EndlessRoster in rosters:
		if roster != null and roster.boss_id not in ids:
			ids.append(roster.boss_id)
	return ids


## Deterministic arena for a YYYY-MM-DD date from every arena, ignoring ownership.
func get_arena_of_the_day(date_key: String) -> ArenaSkinData:
	var pool: Array[ArenaSkinData] = []
	for skin: ArenaSkinData in skins:
		if skin != null:
			pool.append(skin)
	if pool.is_empty():
		return null
	return pool[posmod(ChallengeTracker.get_daily_seed(date_key), pool.size())]


## Returns id, default-arena, arena, roster and tuning authoring failures.
func validate() -> PackedStringArray:
	var failures := PackedStringArray()
	if tuning == null:
		failures.append("tuning is missing")
	if skins.is_empty():
		failures.append("catalog has no arenas")
	var seen: Dictionary[StringName, bool] = {}
	for skin: ArenaSkinData in skins:
		if skin == null:
			failures.append("catalog has an empty arena slot")
			continue
		if seen.has(skin.skin_id):
			failures.append("duplicate arena id %s" % skin.skin_id)
		seen[skin.skin_id] = true
		for failure: String in skin.validate():
			failures.append("%s: %s" % [skin.skin_id, failure])
	var roster_ids: Dictionary[StringName, bool] = {}
	for roster: EndlessRoster in rosters:
		if roster == null:
			failures.append("catalog has an empty roster slot")
			continue
		if roster_ids.has(roster.roster_id):
			failures.append("duplicate roster id %s" % roster.roster_id)
		roster_ids[roster.roster_id] = true
		for failure: String in roster.validate():
			failures.append("%s: %s" % [roster.roster_id, failure])
	if tuning != null:
		for roster_id: StringName in tuning.daily_roster_ids:
			if not roster_ids.has(roster_id):
				failures.append("daily roster %s is not in the catalog" % roster_id)
	if not seen.has(default_skin_id):
		failures.append("default arena %s is not in the catalog" % default_skin_id)
	return failures
