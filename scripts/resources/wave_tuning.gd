class_name WaveTuning
extends Resource
## Data-driven duration, budget growth and spawn spacing for the endless wave director.

## Active duration of each wave in seconds before remaining threats must be cleared.
@export_range(18.0, 25.0, 0.5) var wave_duration: float = 22.0
## Wave-one threat budget.
@export_range(1, 30, 1) var base_threat_budget: int = 6
## Additional threat budget per completed wave.
@export_range(0.0, 10.0, 0.1) var threat_growth_per_wave: float = 2.2
## Calm gap in seconds between cleared formations.
@export_range(0.0, 4.0, 0.05) var formation_gap: float = 0.7
## Minimum normalized distance allowed between a spawn and the Wisp.
@export_range(0.05, 0.5, 0.01) var safe_spawn_distance: float = 0.16
## Threat budget added after each Reaper victory.
@export_range(0, 30, 1) var post_boss_budget_bonus: int = 4
## Formation-gap multiplier applied per post-boss difficulty tier.
@export_range(0.5, 1.0, 0.01) var post_boss_gap_multiplier: float = 0.9
