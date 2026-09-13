class_name BossData
extends Resource
## One boss variant: which atlas it wears, how tough it is, and its accent colour.
##
## Every Rift boss runs the same proven three-phase machine in `ReaperBoss`; only the presentation
## and tuning differ. That keeps four bosses to four data files instead of four state machines.

## Stable identifier referenced by `RiftData.boss_id`.
@export var boss_id: StringName
## Player-facing name used in callouts.
@export var display_name: String
## Animation set for this boss. Null keeps the scene's own frames (used by the base Reaper).
@export var frames: SpriteFrames
## Health, timing, geometry and rewards for this variant.
@export var tuning: ReaperTuning
## Sprite modulate, for variants that recolour a shared atlas rather than supplying a new one.
@export var tint: Color = Color.WHITE
## Accent used by boss UI and warnings.
@export var accent: Color = Color(0.694, 0.298, 0.851, 1.0)


## Returns authoring failures so the whole roster can be checked without opening the editor.
func validate() -> PackedStringArray:
	var failures := PackedStringArray()
	if boss_id.is_empty():
		failures.append("boss id is empty")
	if display_name.is_empty():
		failures.append("display name is empty")
	if tuning == null:
		failures.append("tuning is missing")
	return failures
