class_name EconomyTuning
extends Resource
## Rift Points payouts that do not come from a pickup: the performance bonus.
##
## Rift Points (RP) are the only currency and are earned only by playing (ADR-0013, GDD §6). Values
## here are starting values pending device calibration (GDD §14 #16, docs/systems/shop.md).

## Run score that pays one performance Rift Point (integer division, rounded down).
@export_range(1, 100000, 1) var score_per_rift_point: int = 200
## True while these values are a headless bot estimate awaiting the device pass (ROADMAP M6, M10).
## A release must not ship with it set; the GameWorld run-end log names it.
@export var placeholder: bool = true


## Performance bonus for a finished run: `score / score_per_rift_point`, never negative.
@warning_ignore("integer_division")
func get_performance_points(score: int) -> int:
	return maxi(0, score) / maxi(1, score_per_rift_point)

