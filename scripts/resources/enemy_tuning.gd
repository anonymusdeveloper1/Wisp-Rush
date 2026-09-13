class_name EnemyTuning
extends Resource
## Shared data schema for an enemy's movement, collision, durability and rewards.

## Horizontal design coordinate baseline used to scale movement and size.
@export_range(1.0, 4096.0, 1.0) var design_width: float = 1080.0
## Movement speed in pixels per second at [member design_width].
@export_range(0.0, 1000.0, 1.0) var movement_speed: float = 72.0
## Maximum steering rate in radians per second.
@export_range(0.0, 20.0, 0.1) var turn_speed: float = 3.0
## Collision-circle radius in pixels at [member design_width].
@export_range(1.0, 128.0, 1.0) var collision_radius: float = 34.0
## Displayed sprite diameter in pixels at [member design_width].
@export_range(8.0, 512.0, 1.0) var sprite_diameter: float = 118.0
## Damage required to defeat this enemy.
@export_range(1, 100, 1) var maximum_health: int = 1
## Run score awarded on defeat.
@export_range(0, 10000, 1) var score_reward: int = 15
## Run experience awarded on defeat.
@export_range(0, 1000, 1) var experience_reward: int = 10
## Wave-director threat cost for one instance.
@export_range(1, 20, 1) var threat_cost: int = 1
## Chance from 0.0 to 1.0 to drop one run Soul Shard on defeat.
@export_range(0.0, 1.0, 0.01) var shard_drop_chance: float = 0.1
## Arrival telegraph duration in seconds before the enemy becomes active.
@export_range(0.1, 3.0, 0.05) var telegraph_duration: float = 0.6
## Hit-to-dissolve presentation duration in seconds.
@export_range(0.05, 1.0, 0.01) var dissolve_duration: float = 0.28
## Seconds between archetype-specific dart or charge actions.
@export_range(0.1, 10.0, 0.05) var action_interval: float = 1.5
## Visible action warning duration in seconds.
@export_range(0.1, 2.0, 0.05) var action_telegraph: float = 0.4
## Archetype-specific fast movement duration in seconds.
@export_range(0.1, 3.0, 0.05) var action_duration: float = 0.5
## Speed multiplier during an archetype-specific dart or charge.
@export_range(1.0, 8.0, 0.1) var action_speed_multiplier: float = 3.0

@export_group("Rift behaviours")
## Enemy kind each death spawns, for splitters like the Cinder Shade. Empty means no split.
@export var split_kind: StringName = &""
## How many children a lethal hit spawns.
@export_range(0, 4, 1) var split_count: int = 0
## Sprite and collision multiplier applied to spawned children.
@export_range(0.2, 1.0, 0.05) var split_scale: float = 0.6
## Frontal arc, in degrees, that blocks dash damage entirely. Zero means no shield.
@export_range(0.0, 300.0, 5.0) var shield_arc_degrees: float = 0.0
## Distance between a tethered pair's two bodies at design width. Zero means no tether.
@export_range(0.0, 600.0, 1.0) var tether_length: float = 0.0
