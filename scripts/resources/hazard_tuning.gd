class_name HazardTuning
extends Resource
## Shared viewport scaling, collision and cycle values for one arena hazard type.

## Horizontal design coordinate baseline used to scale art and geometry.
@export_range(1.0, 4096.0, 1.0) var design_width: float = 1080.0
## Displayed sprite diameter in pixels at design width.
@export_range(16.0, 512.0, 1.0) var sprite_diameter: float = 150.0
## Solid dash-blocking radius in pixels at design width.
@export_range(0.0, 160.0, 1.0) var blocking_radius: float = 0.0
## Central dangerous radius in pixels at design width.
@export_range(0.0, 160.0, 1.0) var danger_radius: float = 36.0
## Arrival warning duration in seconds before the hazard can affect play.
@export_range(0.45, 2.0, 0.05) var arrival_telegraph: float = 0.6
## Harmless cycle duration in seconds.
@export_range(0.1, 5.0, 0.05) var safe_duration: float = 1.1
## Visible pre-danger pulse duration in seconds.
@export_range(0.2, 2.0, 0.05) var pulse_duration: float = 0.55
## Dangerous cycle duration in seconds.
@export_range(0.1, 5.0, 0.05) var active_duration: float = 0.85
## Blade-ring rotation speed in radians per second.
@export_range(0.0, 8.0, 0.05) var rotation_speed: float = 0.8
## Blade-ring orbit radius in pixels at design width.
@export_range(0.0, 180.0, 1.0) var orbit_radius: float = 62.0
## Individual rotating blade collision radius in pixels at design width.
@export_range(1.0, 80.0, 1.0) var blade_radius: float = 21.0
## Wave-director threat cost for placing this obstacle.
@export_range(1, 10, 1) var threat_cost: int = 2
