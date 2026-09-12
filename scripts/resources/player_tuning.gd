class_name PlayerTuning
extends Resource
## Data-driven starting values for Wisp gesture, dash, health, impact and focus behaviour.

## Horizontal design coordinate baseline used to scale movement and distances.
@export_range(1.0, 4096.0, 1.0) var design_width: float = 1080.0
## Wisp dash speed in pixels per second at [member design_width].
@export_range(100.0, 10000.0, 10.0) var dash_speed: float = 4400.0
## Intentional release-to-motion anticipation in seconds.
@export_range(0.0, 0.25, 0.001) var windup_duration: float = 0.065
## Wall-impact animation lock in seconds.
@export_range(0.05, 0.3, 0.005) var wall_impact_duration: float = 0.14
## Enemy/hazard slowdown duration in seconds after wall impact.
@export_range(0.0, 1.0, 0.01) var focus_duration: float = 0.32
## Enemy/hazard simulation multiplier during focus, from 0.0 to 1.0.
@export_range(0.05, 1.0, 0.01) var focus_world_speed: float = 0.32
## Minimum accepted drag length in pixels at the design-width baseline.
@export_range(1.0, 128.0, 1.0) var minimum_swipe_distance: float = 28.0
## Player collision radius as a proportion of the live viewport width.
@export_range(0.01, 0.08, 0.001) var radius_viewport_ratio: float = 0.03
## Smallest collision radius in live viewport pixels.
@export_range(1.0, 64.0, 1.0) var minimum_radius: float = 18.0
## Largest collision radius in live viewport pixels.
@export_range(8.0, 96.0, 1.0) var maximum_radius: float = 46.0
## Extra slice-corridor radius in pixels at the design-width baseline.
@export_range(0.0, 96.0, 1.0) var blade_bonus: float = 14.0
## Reform duration in seconds before the first input becomes available.
@export_range(0.0, 1.0, 0.01) var spawn_duration: float = 0.42
## Starting and maximum Soul Fragments before run upgrades.
@export_range(1, 20, 1) var maximum_health: int = 3
## Non-lethal hurt reaction duration in seconds.
@export_range(0.05, 1.0, 0.01) var hurt_duration: float = 0.22
## Post-contact invulnerability duration in seconds.
@export_range(0.1, 3.0, 0.05) var invulnerability_duration: float = 0.9
## Death-dissolve duration in seconds before Results may appear.
@export_range(0.1, 2.0, 0.05) var death_duration: float = 0.55
