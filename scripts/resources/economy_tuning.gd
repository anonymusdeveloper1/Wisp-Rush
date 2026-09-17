class_name EconomyTuning
extends Resource
## Rift Points payouts that do not come from a pickup: the performance and level-clear bonuses.
##
## Rift Points (RP) are the only currency and are earned only by playing (ADR-0013, GDD §6). Values
## here are starting values pending device calibration (GDD §14 #16, docs/systems/shop.md).

## Run score that pays one performance Rift Point (integer division, rounded down).
@export_range(1, 100000, 1) var score_per_rift_point: int = 200
## First clear of Rift level 1 pays this many Rift Points.
@export_range(0, 10000, 1) var level_clear_base: int = 20
## Each level above 1 adds this much to the first-clear bonus.
@export_range(0, 10000, 1) var level_clear_per_level: int = 10
## A repeat clear pays this fraction of the level's first-clear bonus (rounded).
@export_range(0.0, 1.0, 0.01) var repeat_clear_fraction: float = 0.25
## True while these values are a headless bot estimate awaiting the device pass (ROADMAP M6, M10).
## A release must not ship with it set; the GameWorld run-end log names it.
@export var placeholder: bool = true


## Performance bonus for a finished run: `score / score_per_rift_point`, never negative.
@warning_ignore("integer_division")
func get_performance_points(score: int) -> int:
	return maxi(0, score) / maxi(1, score_per_rift_point)


## Clear bonus for a one-based level: base + (level - 1) × per_level on a first clear, a
## `repeat_clear_fraction` of that on a repeat.
func get_level_clear_bonus(level: int, first_clear: bool) -> int:
	var full: int = maxi(0, level_clear_base + (maxi(1, level) - 1) * level_clear_per_level)
	return full if first_clear else roundi(float(full) * repeat_clear_fraction)
