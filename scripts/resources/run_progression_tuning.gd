class_name RunProgressionTuning
extends Resource
## XP curve, mutation catalog and shared reward-effect values for one endless run.

## Ordered paths to all selectable MutationData Resources.
@export var mutation_paths: PackedStringArray = PackedStringArray()
## XP required for run level two.
@export_range(1, 1000, 1) var base_xp_threshold: int = 30
## Multiplicative XP threshold growth per completed level.
@export_range(1.0, 3.0, 0.01) var xp_growth: float = 1.32
## Wide Reap corridor increase per level as a fraction.
@export_range(0.1, 0.5, 0.01) var wide_reap_per_level: float = 0.27
## Void Velocity dash-speed increase per level as a fraction.
@export_range(0.02, 0.25, 0.01) var velocity_per_level: float = 0.1
## Score bonus per Void Velocity level as a fraction.
@export_range(0.0, 0.25, 0.01) var velocity_score_bonus: float = 0.05
## Base Death Pulse radius in design-width pixels.
@export_range(40.0, 400.0, 1.0) var pulse_base_radius: float = 120.0
## Added Death Pulse radius per level in design-width pixels.
@export_range(10.0, 200.0, 1.0) var pulse_radius_per_level: float = 55.0
## Cold Wake slow duration at level one in seconds.
@export_range(0.2, 5.0, 0.1) var cold_wake_base_duration: float = 1.2
## Added Cold Wake duration per later level in seconds.
@export_range(0.0, 2.0, 0.05) var cold_wake_duration_per_level: float = 0.3
## Enemy speed multiplier while affected by Cold Wake.
@export_range(0.1, 0.9, 0.05) var cold_wake_speed: float = 0.55
## Base kill streak before Reaper's Gift heals one fragment.
@export_range(10, 100, 1) var gift_base_streak: int = 33
## Kill-streak reduction per Reaper's Gift level.
@export_range(1, 10, 1) var gift_reduction_per_level: int = 3
## Lowest allowed Reaper's Gift kill streak.
@export_range(5, 50, 1) var gift_minimum_streak: int = 15
## Base attraction radius for dropped Soul Shards in design-width pixels.
@export_range(40.0, 600.0, 1.0) var shard_attraction_radius: float = 150.0
## Added attraction radius per Soul Hunger level in design-width pixels.
@export_range(0.0, 200.0, 1.0) var hunger_attraction_per_level: float = 35.0
