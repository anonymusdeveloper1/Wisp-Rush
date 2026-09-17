class_name RunFeelTuning
extends Resource
## Starting values for visible momentum, shard auto-collect, the slow-motion finisher and RUSH mode.
##
## Rules live in GDD §5.6; these are the §14 #27 starting values, to be tuned on a device. Read by
## GameWorld (meter, RUSH, finisher, sweeps) and WispPlayer (momentum visuals). See
## docs/systems/rush_mode.md.

@export_group("Momentum")
## Long-trail length multiplier at maximum chain momentum (1.0 at no momentum).
@export_range(1.0, 4.0, 0.05) var trail_length_at_max: float = 1.8
## Trail alpha at maximum chain momentum; no momentum keeps each trail's normal alpha.
@export_range(0.0, 1.0, 0.01) var trail_alpha_at_max: float = 1.0
## Share of `PlayerTuning.momentum_max` (0..1) at which faint speed lines show for the dash.
@export_range(0.0, 1.0, 0.01) var speed_lines_at: float = 1.0
## Dash sound pitch added per chain momentum step.
@export_range(0.0, 0.2, 0.005) var dash_pitch_per_step: float = 0.04
## Streak glow behind the dashing Wisp: size in Wisp radii at no momentum and at maximum.
@export_range(0.5, 12.0, 0.1) var streak_glow_size: float = 3.0
@export_range(0.5, 16.0, 0.1) var streak_glow_size_at_max: float = 5.5
## Streak glow alpha at no momentum and at maximum.
@export_range(0.0, 1.0, 0.01) var streak_glow_alpha: float = 0.18
@export_range(0.0, 1.0, 0.01) var streak_glow_alpha_at_max: float = 0.55
## Number of speed lines, their length in Wisp radii and their alpha.
@export_range(0, 12, 1) var speed_line_count: int = 4
@export_range(1.0, 20.0, 0.5) var speed_line_length: float = 6.0
@export_range(0.0, 1.0, 0.01) var speed_line_alpha: float = 0.32

@export_group("Auto-collect")
## Seconds a swept shard takes to reach the Wisp.
@export_range(0.05, 2.0, 0.01) var sweep_seconds: float = 0.35
## Faster sweep under Reduced Motion (the shards still fly: it is information).
@export_range(0.02, 2.0, 0.01) var reduced_motion_sweep_seconds: float = 0.15
## Most chimes one sweep plays, however many shards fly.
@export_range(1, 20, 1) var sweep_sound_cap: int = 6
## Pitch added per chime of a sweep's rising run.
@export_range(0.0, 0.5, 0.01) var sweep_pitch_step: float = 0.05
## Seconds between chimes of one sweep's run.
@export_range(0.0, 0.5, 0.01) var sweep_chime_interval: float = 0.05

@export_group("Finisher")
## Kills in one dash that trigger the finisher, at that kill.
@export_range(2, 20, 1) var finisher_kills: int = 5
## Engine time scale during the finisher.
@export_range(0.05, 1.0, 0.01) var finisher_time_scale: float = 0.3
## Finisher length in real seconds (time scale ignored).
@export_range(0.05, 2.0, 0.01) var finisher_seconds: float = 0.4
## Game seconds before another field clear may trigger a finisher.
@export_range(0.0, 60.0, 0.5) var field_clear_cooldown: float = 6.0
## Peak alpha of the Soul White flash on the world shade.
@export_range(0.0, 1.0, 0.01) var finisher_flash_alpha: float = 0.3
## Screen-shake trauma added by a finisher.
@export_range(0.0, 1.0, 0.01) var finisher_trauma: float = 0.25
## Pitch of the finisher's low `pulse` sound.
@export_range(0.25, 2.0, 0.01) var finisher_pulse_pitch: float = 0.6

@export_group("RUSH")
## Meter capacity; RUSH starts when the meter reaches it.
@export_range(1.0, 1000.0, 1.0) var meter_max: float = 100.0
## Meter added per kill.
@export_range(0.0, 100.0, 0.5) var per_kill: float = 4.0
## Extra meter for every kill after the first in the same dash.
@export_range(0.0, 100.0, 0.5) var per_extra_dash_kill: float = 4.0
## Meter added per boss core hit.
@export_range(0.0, 100.0, 0.5) var per_boss_hit: float = 10.0
## Meter removed when the Wisp takes damage (outside RUSH).
@export_range(0.0, 100.0, 0.5) var damage_drain: float = 0.0
## RUSH length in game seconds.
@export_range(0.5, 30.0, 0.1) var duration: float = 6.0
## The Wisp glow flickers for this many final seconds of RUSH.
@export_range(0.0, 10.0, 0.1) var warning_seconds: float = 1.0
## Dash speed multiplier during RUSH; composes with momentum and mutations.
@export_range(1.0, 3.0, 0.05) var speed_multiplier: float = 1.3
## Score multiplier during RUSH; composes with Void Velocity.
@export_range(1.0, 10.0, 0.1) var score_multiplier: float = 2.0
## Whether RUSH blocks all damage: enemies, hazards and boss attacks.
@export var blocks_damage: bool = true
## Screen-shake trauma when RUSH starts.
@export_range(0.0, 1.0, 0.01) var start_trauma: float = 0.5
## Seconds a kill's soul orb takes to fly to the meter; also how fast the bar catches up.
@export_range(0.05, 1.5, 0.01) var orb_flight_seconds: float = 0.3
## Peak alpha of the screen-edge glow during RUSH.
@export_range(0.0, 1.0, 0.01) var edge_glow_alpha: float = 0.28
## Pulses per second of the full meter, the edge glow and the warning flicker.
@export_range(0.1, 20.0, 0.1) var pulse_rate: float = 3.0
@export_range(1.0, 40.0, 0.5) var warning_flicker_rate: float = 14.0
## Volume offset of the soft `pulse` sound that ends RUSH.
@export_range(-24.0, 6.0, 0.5) var end_sound_volume_db: float = -6.0


## Momentum visual level 0..1 from chain momentum and `PlayerTuning.momentum_max`.
static func momentum_level(momentum: float, momentum_max: float) -> float:
	if momentum_max <= 0.0:
		return 0.0
	return clampf(momentum / momentum_max, 0.0, 1.0)


## RUSH meter gained by one kill that is the [param dash_kill_index]-th kill of its dash (1-based;
## 0 when the kill has no dash).
func get_kill_fill(dash_kill_index: int) -> float:
	return per_kill + (per_extra_dash_kill if dash_kill_index > 1 else 0.0)
