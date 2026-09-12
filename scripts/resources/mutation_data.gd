class_name MutationData
extends Resource
## Data-driven identity, cap, icon and next-level presentation for one run mutation.

## Stable identifier used by run logic.
@export var mutation_id: StringName
## Player-facing mutation name.
@export var display_name: String
## Concise copy containing an optional `{value}` token.
@export_multiline var description_template: String
## Highest selectable level for this mutation.
@export_range(1, 99, 1) var max_level: int = 5
## Display value before applying per-level growth.
@export var base_value: float = 0.0
## Display value added for each selected level.
@export var value_per_level: float = 1.0
## Supplied production mutation icon.
@export var icon: Texture2D


## Returns the numeric display value for a one-based mutation level.
func get_value_for_level(level: int) -> float:
	return base_value + value_per_level * float(clampi(level, 0, max_level))


## Returns concise effect copy for the next selectable level.
func get_next_description(current_level: int) -> String:
	var next_level: int = mini(max_level, current_level + 1)
	var value: float = get_value_for_level(next_level)
	var value_text: String = "%.1f" % value
	if is_equal_approx(value, roundf(value)):
		value_text = str(roundi(value))
	return description_template.replace("{value}", value_text)
