class_name SplitVoidCrystal
extends HazardActor
## Indestructible warned obstacle that truncates dash corridors through its narrow body.


func blocks_dash() -> bool:
	return state == State.ACTIVE


func _advance_hazard(scaled_delta: float) -> void:
	_sprite.rotation = sin(Time.get_ticks_msec() * 0.0015) * 0.025
	_warning.rotation += scaled_delta * 0.25
