class_name ReaperTuning
extends Resource
## Data-driven health, timing, geometry and rewards for the recurring Reaper encounter.

## Source width used to scale authored pixels to the live viewport.
@export_range(320.0, 2160.0, 1.0) var design_width: float = 1080.0
## Health in the first encounter; two equal health bands feed each phase.
@export_range(3, 30, 3) var base_health: int = 6
## Health added for each later encounter.
@export_range(0, 12, 1) var health_per_encounter: int = 2
## Skippable entrance duration in seconds.
@export_range(0.4, 3.0, 0.05) var intro_duration: float = 1.2
## Delay between exposed-core attempts in seconds.
@export_range(0.1, 3.0, 0.05) var recovery_duration: float = 0.65
## Visible attack-warning duration in seconds.
@export_range(0.45, 2.0, 0.05) var warning_duration: float = 0.8
## Scythe danger duration in seconds.
@export_range(0.15, 1.5, 0.05) var sweep_duration: float = 0.4
## Teleport-arrival danger duration in seconds.
@export_range(0.15, 1.5, 0.05) var teleport_attack_duration: float = 0.3
## Death-corridor danger duration in seconds.
@export_range(0.2, 2.0, 0.05) var corridor_duration: float = 0.6
## Exposed-core window in seconds.
@export_range(0.5, 3.0, 0.05) var exposed_duration: float = 1.15
## Multiplier removed from phase timings for each later encounter.
@export_range(0.0, 0.2, 0.01) var speedup_per_encounter: float = 0.07
## Lowest timing multiplier across recurring encounters.
@export_range(0.5, 1.0, 0.01) var minimum_timing_multiplier: float = 0.72
## Visible boss diameter in design pixels.
@export_range(120.0, 600.0, 1.0) var sprite_diameter: float = 310.0
## Radius of the exposed core's swept hit circle in design pixels.
@export_range(20.0, 160.0, 1.0) var core_radius: float = 52.0
## Scythe-tip orbit radius in design pixels.
@export_range(80.0, 420.0, 1.0) var sweep_radius: float = 220.0
## Scythe-tip damaging radius in design pixels.
@export_range(20.0, 120.0, 1.0) var sweep_blade_radius: float = 46.0
## Death-corridor half width in design pixels.
@export_range(20.0, 120.0, 1.0) var lane_radius: float = 46.0
## Score awarded after the final dissolve.
@export_range(100, 10000, 50) var score_reward: int = 1500
## Rift Points awarded after victory.
@export_range(1, 100, 1) var rp_reward: int = 25
## XP awarded after victory.
@export_range(1, 1000, 1) var experience_reward: int = 60
## Seconds reserved for the victory pulse before endless waves resume.
@export_range(0.4, 3.0, 0.05) var victory_duration: float = 1.0
