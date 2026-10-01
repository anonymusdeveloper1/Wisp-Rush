class_name EndlessRoster
extends Resource
## One entry of the Endless boss pool: an old enemy mix's name and the boss it brings.
##
## Moved out of the story Rifts when they were removed (owner, 2026-09-25). Since Enemies v2
## (2026-09-28) the mixes no longer change which enemies come (the run's `EnemyRamp` does) and their
## "<NAME> WAVE" callouts are gone; a roster now only carries its boss into the Endless pool, until
## the new bosses replace the old ones (owner: the old bosses stay for now).

## Stable identifier, used by `EndlessTuning.daily_roster_ids`.
@export var roster_id: StringName
## The old mix's name.
@export var display_name: String
## Boss this entry adds to the Endless boss pool.
@export var boss_id: StringName = &"reaper"


## Returns authoring failures so the catalog can be checked without opening the editor.
func validate() -> PackedStringArray:
	var failures := PackedStringArray()
	if roster_id.is_empty():
		failures.append("roster id is empty")
	if display_name.is_empty():
		failures.append("display name is empty")
	if boss_id.is_empty():
		failures.append("boss id is empty")
	return failures
