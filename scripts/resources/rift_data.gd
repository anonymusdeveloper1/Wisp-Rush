class_name RiftData
extends Resource
## Data-driven identity, unlock gate, backdrop and rule twist for one playable arena.
##
## A Rift is not a reskin: `rule_key` names the one mechanical twist that makes it play differently
## from the Obsidian Garden baseline. GameWorld reads the key at run start; everything else here is
## presentation for the Rift map.

## Stable identifier stored in progression data.
@export var rift_id: StringName
## Player-facing arena name.
@export var display_name: String
## Short flavour text shown on the Rift map node.
@export_multiline var description: String
## One-line player-facing statement of this Rift's rule twist.
@export var rule_summary: String
## Mechanical hook GameWorld switches on; `&"none"` is the unmodified baseline arena.
@export var rule_key: StringName = &"none"
## Full-bleed gameplay backdrop.
@export var background: Texture2D
## Playable floor as a polygon in background-texture UV space, generated from the art.
##
## Derived from this Rift's painted floor by `tools/art/extract_floor_polygons.py` — never
## hand-edited. A shared rectangle was honest for the rectangular arenas and wrong for the oval
## ones, where its corners sat in the lava and on the ice pillars. Empty falls back to the legacy
## rectangle so a Rift without a baked polygon still plays.
@export var floor_polygon: PackedVector2Array = PackedVector2Array()
## Lifetime highest wave required to unlock; zero is always available.
@export_range(0, 999, 1) var unlock_wave: int = 0
## Map-node accent colour; use a Palette constant, never a raw literal.
@export var accent: Color = Color.WHITE

@export_group("Difficulty")
## Where this Rift sits on the ladder, 1 (Obsidian Garden) to 5 (Reaper's Court).
@export_range(1, 5, 1) var difficulty_tier: int = 1
## Levels the player clears inside this Rift before it becomes endless.
@export_range(1, 20, 1) var level_count: int = 8
## Waves survived per level before this Rift's boss appears.
@export_range(1, 20, 1) var waves_per_level: int = 4
## Threat-budget multiplier at level 1. Kept near 1.0 in every Rift so level 1 is always approachable.
@export_range(0.4, 2.0, 0.01) var level_one_threat: float = 1.0
## Extra threat multiplier added per level; higher tiers ramp harder, not just higher.
@export_range(0.0, 1.0, 0.01) var threat_per_level: float = 0.15
## Enemy movement-speed multiplier applied throughout this Rift.
@export_range(0.5, 2.0, 0.01) var enemy_speed_scale: float = 1.0

@export_group("Roster")
## Replaces authored formation enemy kinds with this Rift's own roster, so the twenty formations
## stay reusable while each arena fields different threats. Empty means the base roster.
@export var enemy_substitutions: Dictionary[StringName, StringName] = {}
## Boss encountered at the end of every level in this Rift.
@export var boss_id: StringName = &"reaper"


## Whether a lifetime best wave clears this Rift's unlock gate.
func is_unlocked(highest_wave: int) -> bool:
	return highest_wave >= unlock_wave


## Threat-budget multiplier for a one-based level inside this Rift.
##
## Level 1 is deliberately close to 1.0 in every Rift - the owner's rule is that each arena starts
## easy - so the ladder's bite comes from `threat_per_level`, which grows with the tier.
func get_threat_multiplier(level: int) -> float:
	var clamped: int = clampi(level, 1, level_count)
	return level_one_threat + float(clamped - 1) * threat_per_level


## Maps one authored formation enemy kind onto this Rift's roster.
func substitute_enemy(base_kind: StringName) -> StringName:
	return enemy_substitutions.get(base_kind, base_kind)


## Whether this Rift has a baked floor polygon, or must fall back to the legacy rectangle.
func has_floor_polygon() -> bool:
	return floor_polygon.size() >= 3


## Total waves to clear every level in this Rift, for progress display.
func get_total_waves() -> int:
	return level_count * waves_per_level


## Returns authoring failures so the whole catalog can be checked without opening the editor.
func validate() -> PackedStringArray:
	var failures := PackedStringArray()
	if rift_id.is_empty():
		failures.append("rift id is empty")
	if display_name.is_empty():
		failures.append("display name is empty")
	if rule_summary.is_empty():
		failures.append("rule summary is empty")
	if background == null:
		failures.append("background is missing")
	if floor_polygon.size() > 0 and floor_polygon.size() < 3:
		failures.append("floor polygon needs at least three points")
	for point: Vector2 in floor_polygon:
		if point.x < 0.0 or point.x > 1.0 or point.y < 0.0 or point.y > 1.0:
			failures.append("floor polygon point %s is outside UV space" % point)
			break
	if unlock_wave < 0:
		failures.append("unlock wave is negative")
	return failures
