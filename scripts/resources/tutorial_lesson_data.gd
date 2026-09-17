class_name TutorialLessonData
extends Resource
## One Tutorial screen lesson: captions, what it spawns, the demonstrated swipes and its goal.
##
## Positions are arena UV (0..1 across the playfield rect, mapped onto the painted floor by
## `GameWorld.arena_to_world`), so a lesson reads the same on every phone. A demo swipe of
## `Vector2.ZERO` aims at the nearest live target (enemy, else the boss) at the moment it plays.

## Goal ids the TutorialDirector knows (`goal`).
const GOAL_WALL_DASH: StringName = &"wall_dash"
const GOAL_KILL: StringName = &"kill"
const GOAL_CHAIN: StringName = &"chain"
const GOAL_REDIRECT_KILL: StringName = &"redirect_kill"
const GOAL_SAFE_KILL: StringName = &"safe_kill"
const GOAL_UPGRADE: StringName = &"upgrade"
const GOAL_RUSH_KILL: StringName = &"rush_kill"
const GOAL_BOSS: StringName = &"boss"
const GOALS: Array[StringName] = [
	GOAL_WALL_DASH, GOAL_KILL, GOAL_CHAIN, GOAL_REDIRECT_KILL, GOAL_SAFE_KILL, GOAL_UPGRADE,
	GOAL_RUSH_KILL, GOAL_BOSS,
]

## Stable id, used in logs.
@export var lesson_id: StringName
## Short name under the step counter (`LESSON 3 / 9  •  CHAIN`), UPPERCASE.
@export var title: String
## One-line caption while the ghost hand demonstrates.
@export var demo_caption: String
## One-line caption while the player tries.
@export var try_caption: String
## Callout of the success beat.
@export var success_callout: String
## One of `GOALS`.
@export var goal: StringName = GOAL_WALL_DASH
## Kills one dash must reach for `GOAL_CHAIN`.
@export_range(1, 10, 1) var goal_count: int = 1
## Where the Wisp rests when the lesson (and each retry) starts, arena UV.
@export var player_start: Vector2 = Vector2(0.5, 1.0)
## Stationary enemy kind spawned at `enemy_positions`.
@export var enemy_kind: StringName = &"soul_wisp"
## Enemy positions, arena UV.
@export var enemy_positions: PackedVector2Array = PackedVector2Array()
## Extra targets spawned whenever RUSH starts or the field empties during RUSH (`GOAL_RUSH_KILL`).
@export var rush_positions: PackedVector2Array = PackedVector2Array()
## Hazard kind (`split_void_crystal`, `spike_bloom`, `blade_ring`); empty for none.
@export var hazard_kind: StringName = &""
## Hazard position, arena UV.
@export var hazard_position: Vector2 = Vector2(0.5, 0.5)
## Spawn the boss with `TutorialCatalog.boss_health` (`GOAL_BOSS`).
@export var spawns_boss: bool = false
## Demonstrated drag directions, in order; `Vector2.ZERO` aims at the nearest live target.
@export var demo_swipes: PackedVector2Array = PackedVector2Array([Vector2.UP])
## Index in `demo_swipes` released mid-dash (a redirect) right after the previous one; -1: none.
@export var redirect_swipe_index: int = -1
## Whether the demo drives the real Wisp; false shows the hand and aim only (the boss lesson).
@export var demo_drives_wisp: bool = true
## Whether the demo's own dash takes a hazard hit (reforming at `demo_hit_reform`) as it nears the
## hazard, so the Soul Fragment loss and the blink are always shown.
@export var demo_shows_hit: bool = false
## Where the demonstrated hit reforms the Wisp, arena UV.
@export var demo_hit_reform: Vector2 = Vector2(1.0, 0.7)
## Whether the arena is rebuilt between the demo and the try (false keeps a boss fight going).
@export var reset_after_demo: bool = true
## Whether a wall landing that misses the goal rebuilds the lesson for another attempt.
@export var retry_on_miss: bool = false
## HUD element the hand's focus ring points at: `&"health"`, `&"xp"`, `&"rush"` or empty.
@export var hud_focus: StringName = &""
## Kills and bosses grant XP (the upgrade lesson).
@export var experience_enabled: bool = false
## XP bar share the demo fills to (0 leaves it); the try fills the rest.
@export_range(0.0, 0.95, 0.05) var demo_experience_share: float = 0.0
## The demo fills the XP bar, asks for the lesson's calm moment and the ghost hand
## taps an upgrade card once the tray slides up (the upgrade lesson).
@export var demo_upgrade_tap: bool = false
## Kills drop a Rift Points shard each, swept to the Wisp when it lands.
@export var drops_shards: bool = false
## RUSH meter and mode are live (the RUSH lesson).
@export var rush_enabled: bool = false
## RUSH meter share (0..1 of `meter_max`) at the start of the demo and of every attempt.
@export_range(0.0, 0.99, 0.01) var rush_start_share: float = 0.0


## Returns authoring failures for this lesson.
func validate() -> PackedStringArray:
	var failures := PackedStringArray()
	if lesson_id.is_empty():
		failures.append("lesson id is empty")
	if demo_caption.is_empty() or try_caption.is_empty() or success_callout.is_empty():
		failures.append("%s: a caption is empty" % lesson_id)
	if goal not in GOALS:
		failures.append("%s: unknown goal %s" % [lesson_id, goal])
	if demo_swipes.is_empty():
		failures.append("%s: no demo swipes" % lesson_id)
	if redirect_swipe_index == 0 or redirect_swipe_index >= demo_swipes.size():
		failures.append("%s: redirect swipe index out of range" % lesson_id)
	if goal == GOAL_BOSS and not spawns_boss:
		failures.append("%s: a boss goal needs spawns_boss" % lesson_id)
	if demo_upgrade_tap and not demo_drives_wisp:
		failures.append("%s: an upgrade tap demo needs demo_drives_wisp" % lesson_id)
	return failures
