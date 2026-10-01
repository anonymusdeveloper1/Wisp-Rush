class_name UpgradeGlow
extends Node2D
## The little light on the character while upgrades are ready on a board arena (owner 2026-10-02,
## GDD §14 #71–#72, ADR-0024): stepped amber rings behind the Wisp, breathing slowly. Tapping the
## glowing character opens the upgrades (GameWorld). Drawn with hard edges, no blur; still under
## Reduced Motion.

## The outer ring's radius as a multiple of [member radius] (the Wisp's collision radius).
@export var radius_scale: float = 2.2
## Seconds per breath of the light.
@export var pulse_seconds: float = 1.2
## How many rings, outer to inner, each brighter than the one around it.
@export var rings: int = 3

## The Wisp's collision radius, design pixels; GameWorld keeps it current.
var radius: float = 40.0
## Holds the light steady (Reduced Motion).
var reduced_motion: bool = false
var _time: float = 0.0


func _process(delta: float) -> void:
	if not visible or reduced_motion:
		return
	_time += delta
	queue_redraw()


func _draw() -> void:
	var pulse: float = 0.0 if reduced_motion else 0.5 - 0.5 * cos(TAU * _time / maxf(pulse_seconds, 0.01))
	var outer: float = radius * radius_scale * (0.92 + 0.08 * pulse)
	for step: int in rings:
		var ring_radius: float = outer * (1.0 - 0.22 * float(step))
		draw_circle(Vector2.ZERO, ring_radius, Color(Palette.AMBER_LIGHT, 0.1 + 0.07 * float(step) + 0.06 * pulse))
