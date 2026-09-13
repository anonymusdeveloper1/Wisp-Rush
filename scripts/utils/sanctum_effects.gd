class_name SanctumEffects
extends RefCounted
## Resolves purchased Soul Sanctum levels into the flat effect values GameWorld applies at run start.
##
## Keeping this pure and separate means the tree can be re-costed or re-shaped in data without
## touching gameplay code, and the totals can be asserted in a headless test.

## Percentage effects are authored as whole percent; gameplay wants a fraction.
const PERCENT: float = 0.01

var _values: Dictionary[StringName, float] = {}


func _init(catalog: SanctumCatalog, levels: Dictionary) -> void:
	if catalog == null:
		return
	for node: SanctumNode in catalog.load_nodes():
		var level: int = clampi(int(levels.get(String(node.node_id), 0)), 0, node.max_level)
		if level <= 0:
			continue
		# Prerequisites are enforced at purchase time; a save that skipped one still resolves
		# safely, because every effect is additive and clamped by max_level above.
		var value: float = node.get_value(level)
		_values[node.effect_key] = _values.get(node.effect_key, 0.0) + value


## Raw authored total for one effect key, in its authored unit.
func get_value(effect_key: StringName) -> float:
	return _values.get(effect_key, 0.0)


## Multiplier form of a percentage effect, e.g. 6 % becomes 1.06.
func get_multiplier(effect_key: StringName) -> float:
	return 1.0 + get_value(effect_key) * PERCENT


## Whole-number form of a count effect, such as bonus fragments or starting mutations.
func get_count(effect_key: StringName) -> int:
	return int(round(get_value(effect_key)))


## Every resolved effect key, for tests and debug output.
func get_keys() -> Array[StringName]:
	return _values.keys()
