class_name EndlessTuning
extends Resource
## Boss cadence, per-cycle difficulty and the fixed daily pool for Endless rules.
##
## A cycle is one boss beaten: cycle 0 is the start of the run. Starting values are in
## docs/systems/endless_mode.md and are tuning, not rules.

## Waves between boss encounters; the boss arrives on every multiple of this.
@export_range(1, 20, 1) var boss_wave_interval: int = 4
## WaveDirector threat multiplier at cycle 0, added per cycle, and its ceiling.
@export_range(0.25, 4.0, 0.01) var threat_start: float = 1.0
@export_range(0.0, 1.0, 0.01) var threat_per_cycle: float = 0.18
@export_range(0.25, 4.0, 0.01) var threat_cap: float = 3.0
## Continuous spawning: the next formation arrives while at most this many enemies are alive, and a
## spent wave starts the next at once, so Endless never goes quiet (owner 2026-09-15).
@export_range(0, 12, 1) var refill_live_enemies: int = 2
## Enemy movement-speed multiplier at cycle 0, added per cycle, and its ceiling.
@export_range(0.5, 2.0, 0.01) var speed_scale_start: float = 1.0
@export_range(0.0, 0.5, 0.01) var speed_scale_per_cycle: float = 0.04
@export_range(0.5, 2.0, 0.01) var speed_scale_cap: float = 1.3
## Rifts whose rosters the daily run draws from, whatever the player has cleared.
@export var daily_roster_rift_ids: Array[StringName] = [&"obsidian_garden"]
## Bosses the daily run draws from, whatever the player has beaten.
@export var daily_boss_ids: Array[StringName] = [&"reaper"]


## Threat multiplier after `cycle` bosses.
func get_threat_multiplier(cycle: int) -> float:
	return minf(threat_cap, threat_start + float(maxi(0, cycle)) * threat_per_cycle)


## Enemy speed multiplier after `cycle` bosses.
func get_speed_scale(cycle: int) -> float:
	return minf(speed_scale_cap, speed_scale_start + float(maxi(0, cycle)) * speed_scale_per_cycle)
