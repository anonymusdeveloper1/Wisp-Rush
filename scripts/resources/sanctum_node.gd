class_name SanctumNode
extends Resource
## One permanent upgrade in the Soul Sanctum: identity, cost curve and its mechanical hook.
##
## Sanctum nodes are the only permanent power in the game. GDD §6 requires that they must not
## trivialise a fresh start, so `is_combat_power` marks the nodes that count against the budget
## `SanctumCatalog` enforces; economy and convenience nodes are deliberately excluded.

## Stable identifier stored in progression data.
@export var node_id: StringName
## Player-facing name.
@export var display_name: String
## Short description; `{value}` is replaced with the value at the next level.
@export_multiline var description_template: String
## Mechanical hook GameWorld applies at run start.
@export var effect_key: StringName
## Levels that can be purchased.
@export_range(1, 10, 1) var max_level: int = 1
## Effect value added per purchased level, in the unit named by `unit`.
@export var value_per_level: float = 0.0
## Unit label shown next to the value (for example "%", "s", "fragment").
@export var unit: String = ""
## Shard cost of the first level.
@export_range(0, 100000, 10) var cost_first_level: int = 100
## Extra shards added to each subsequent level's cost.
@export_range(0, 100000, 10) var cost_step: int = 100
## Node that must be fully maxed before this one unlocks. Empty means a root node.
@export var prerequisite_id: StringName = &""
## Whether this node grants direct combat power and so counts against the power budget.
@export var is_combat_power: bool = true
## Icon shown on the Sanctum node.
@export var icon: Texture2D


## Total effect value at a given purchased level.
func get_value(level: int) -> float:
	return value_per_level * float(clampi(level, 0, max_level))


## Shard cost to buy the next level, or -1 when the node is already maxed.
func get_cost(current_level: int) -> int:
	if current_level >= max_level:
		return -1
	return cost_first_level + cost_step * current_level


## Total shards to take this node from nothing to maximum.
func get_total_cost() -> int:
	var total: int = 0
	for level: int in max_level:
		total += cost_first_level + cost_step * level
	return total


## Player-facing description for the next level, with `{value}` substituted.
func get_next_description(current_level: int) -> String:
	var next_value: float = get_value(mini(current_level + 1, max_level))
	var text: String = "%s%s" % [String.num(next_value, 2).trim_suffix(".00"), unit]
	return description_template.replace("{value}", text)


## Returns authoring failures so the whole tree can be checked without opening the editor.
func validate() -> PackedStringArray:
	var failures := PackedStringArray()
	if node_id.is_empty():
		failures.append("node id is empty")
	if display_name.is_empty():
		failures.append("display name is empty")
	if effect_key.is_empty():
		failures.append("effect key is empty")
	if not description_template.contains("{value}"):
		failures.append("description template has no {value} placeholder")
	if is_zero_approx(value_per_level):
		failures.append("value per level is zero")
	if cost_first_level <= 0:
		failures.append("first level is free")
	if prerequisite_id == node_id:
		failures.append("node is its own prerequisite")
	return failures
