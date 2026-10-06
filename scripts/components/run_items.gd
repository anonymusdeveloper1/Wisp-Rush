class_name RunItems
extends Node
## Run-local pickup effect timers; repeated pickups refresh duration without stacking strength.

## Active timers changed by activation, expiry or reset.
signal changed
## Emitted for timed effects and the immediate bomb; Ward stock belongs to the run host.
signal activated(item_id: StringName)

@export var catalog: RunItemCatalog
var _remaining: Dictionary[StringName, float] = {}


## Applies a known non-Ward pickup once. The host performs its live gameplay effect.
func activate(item_id: StringName) -> bool:
	var item: RunItemData = catalog.get_item(item_id)
	if item == null or item_id == RunItemCatalog.SOUL_WARD:
		return false
	if item.duration_seconds > 0.0:
		_remaining[item_id] = maxf(get_remaining(item_id), item.duration_seconds)
	activated.emit(item_id)
	changed.emit()
	return true


## Advances timers in unpaused game seconds and announces expiry once.
func advance(delta: float) -> void:
	var expired: bool = false
	for item_id: StringName in _remaining.keys():
		_remaining[item_id] = maxf(0.0, _remaining[item_id] - delta)
		if _remaining[item_id] <= 0.0:
			_remaining.erase(item_id)
			expired = true
	if expired:
		changed.emit()


## Remaining game seconds, or zero when inactive.
func get_remaining(item_id: StringName) -> float:
	return _remaining.get(item_id, 0.0)


## Whether the item's temporary effect is active.
func is_active(item_id: StringName) -> bool:
	return get_remaining(item_id) > 0.0


## Number of active temporary effects, for run context and presentation.
func get_active_count() -> int:
	return _remaining.size()


## Clears every temporary effect when a run or scripted lesson ends.
func clear() -> void:
	_remaining.clear()
	changed.emit()
