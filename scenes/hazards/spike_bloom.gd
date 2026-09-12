class_name SpikeBloom
extends HazardActor
## Fixed bloom that alternates a harmless closed bud, an amber-rimmed warning and a dangerous
## open crystal. Each state has its own art so meaning never relies on hue alone.

enum CycleState { SAFE, PULSING, DANGEROUS }

const CLOSED_TEXTURE: Texture2D = preload(
	"res://assets/art/environment/props/07_floor_spike_bloom_closed.png"
)
const WARNING_TEXTURE: Texture2D = preload(
	"res://assets/art/environment/props/07_floor_spike_bloom_warning.png"
)
const OPEN_TEXTURE: Texture2D = preload(
	"res://assets/art/environment/props/07_floor_spike_bloom.png"
)
## Scale pop when the bloom snaps open; it settles back to base size within a few frames.
const OPEN_POP_SCALE: float = 1.14
const OPEN_SETTLE_RATE: float = 12.0

var _cycle_state: CycleState = CycleState.SAFE
var _cycle_remaining: float = 0.0


func _on_became_active() -> void:
	_enter_safe()


func _advance_hazard(scaled_delta: float) -> void:
	_cycle_remaining -= scaled_delta
	match _cycle_state:
		CycleState.SAFE:
			if _cycle_remaining <= 0.0:
				_cycle_state = CycleState.PULSING
				_cycle_remaining = tuning.pulse_duration
				_sprite.texture = WARNING_TEXTURE
		CycleState.PULSING:
			var pulse: float = 1.0 + sin(_cycle_remaining * 28.0) * 0.06
			_sprite.scale = _base_sprite_scale * pulse
			if _cycle_remaining <= 0.0:
				_cycle_state = CycleState.DANGEROUS
				_cycle_remaining = tuning.active_duration
				_sprite.texture = OPEN_TEXTURE
				_sprite.scale = _base_sprite_scale * OPEN_POP_SCALE
		CycleState.DANGEROUS:
			_sprite.scale = _sprite.scale.lerp(
				_base_sprite_scale,
				minf(1.0, scaled_delta * OPEN_SETTLE_RATE),
			)
			if _cycle_remaining <= 0.0:
				_enter_safe()


func get_dangerous_circles() -> Array[Vector3]:
	if state != State.ACTIVE or _cycle_state != CycleState.DANGEROUS:
		return []
	return [Vector3(global_position.x, global_position.y, tuning.danger_radius * _viewport_scale)]


func _enter_safe() -> void:
	_cycle_state = CycleState.SAFE
	_cycle_remaining = tuning.safe_duration
	_sprite.texture = CLOSED_TEXTURE
	_sprite.scale = _base_sprite_scale
	_sprite.modulate = Color.WHITE
