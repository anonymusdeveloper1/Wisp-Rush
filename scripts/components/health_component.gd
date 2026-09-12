class_name HealthComponent
extends Node
## Reusable clamped integer health state with change and one-shot depletion signals.

## Emitted after configure, reset, damage or healing changes the current value.
signal health_changed(current_health: int, maximum_health: int)
## Emitted once when current health first transitions from above zero to zero.
signal depleted

## Default maximum health before an owning system configures the component.
@export_range(1, 100, 1) var maximum_health: int = 1

var _current_health: int = 1
var _depleted_emitted: bool = false


func _ready() -> void:
	reset()


## Sets maximum health to at least one and optionally refills to that maximum.
func configure(new_maximum: int, refill: bool = true) -> void:
	maximum_health = maxi(1, new_maximum)
	if refill:
		_current_health = maximum_health
	else:
		_current_health = clampi(_current_health, 0, maximum_health)
	_depleted_emitted = _current_health <= 0
	health_changed.emit(_current_health, maximum_health)


## Restores current health to maximum and clears the depletion latch.
func reset() -> void:
	_current_health = maxi(1, maximum_health)
	_depleted_emitted = false
	health_changed.emit(_current_health, maximum_health)


## Applies non-negative damage and returns whether current health changed.
func apply_damage(amount: int) -> bool:
	if amount <= 0 or _current_health <= 0:
		return false
	var previous_health: int = _current_health
	_current_health = maxi(0, _current_health - amount)
	health_changed.emit(_current_health, maximum_health)
	if previous_health > 0 and _current_health == 0 and not _depleted_emitted:
		_depleted_emitted = true
		depleted.emit()
	return true


## Restores non-negative health, clamped to maximum, and returns whether it changed.
func heal(amount: int) -> bool:
	if amount <= 0 or _current_health >= maximum_health:
		return false
	_current_health = mini(maximum_health, _current_health + amount)
	if _current_health > 0:
		_depleted_emitted = false
	health_changed.emit(_current_health, maximum_health)
	return true


## Returns the current health value in the inclusive range 0–maximum.
func get_current_health() -> int:
	return _current_health


## Returns whether current health has reached zero.
func is_depleted() -> bool:
	return _current_health <= 0
