class_name GrimgrinTuning
extends Resource
## Grimgrin, the Hollow Ronin's numbers. The fight itself is the owner's
## (docs/specs/enemies_v2/boss_melee.md); every starting value in `data/bosses/grimgrin_tuning.tres` is
## Claude's proposal for the owner's phone test (2026-09-27).
##
## Distances are design pixels at [member design_width]; the boss scales them to the live arena.

@export_range(320.0, 2160.0, 1.0) var design_width: float = 1080.0

@export_group("Size")
## His standing height, feet to hood tip, at the design width.
@export_range(80.0, 600.0, 1.0) var standing_height: float = 290.0
## Radius of the circle a Wisp dash must cross to hit him, as a share of his standing height.
@export_range(0.1, 0.6, 0.01) var hit_radius_ratio: float = 0.3

@export_group("Health")
@export_range(1, 99, 1) var base_health: int = 12
@export_range(0, 20, 1) var health_per_encounter: int = 3
## How much a hit counts while both his katanas are planted in the wall (owner: more damage).
@export_range(1, 5, 1) var planted_hit_value: int = 2

@export_group("Movement")
## Seconds he stays on screen before his first move.
@export_range(0.0, 5.0, 0.05) var intro_duration: float = 1.1
## Random rest on a wall between moves (owner: unpredictable).
@export_range(0.05, 3.0, 0.05) var rest_min: float = 0.45
@export_range(0.05, 3.0, 0.05) var rest_max: float = 0.95
## Seconds his eyes and glow flare on his wall before each dash: the warning (owner, 2026-09-27).
@export_range(0.1, 2.0, 0.05) var dash_warning_duration: float = 0.5
## Flight speed of his wall-to-wall dash (owner, 2026-09-27: half the first test's 1500, so the
## flight, the time to hit him, lasts longer).
@export_range(200.0, 6000.0, 10.0) var dash_speed: float = 750.0
## Share of his height a landing keeps between him and the Wisp.
@export_range(0.0, 3.0, 0.05) var landing_clearance: float = 1.2

@export_group("The fast attack")
## Chance, after a rest, that his dash is the fast attack instead of the slow one (owner, 2026-09-28:
## sometimes). An ill-wall dash is never the fast attack.
@export_range(0.0, 1.0, 0.01) var fast_attack_chance: float = 0.3
## Seconds after one fast attack before the next can start, and before the first one.
@export_range(0.0, 20.0, 0.1) var fast_attack_cooldown: float = 4.0
@export_range(0.0, 20.0, 0.1) var first_fast_attack_delay: float = 3.0
## Seconds his crimson warning holds his wall before the fast attack (owner, 2026-09-28: its own
## warning, longer than the slow dash's).
@export_range(0.1, 3.0, 0.05) var fast_warning_duration: float = 0.8
## Flight speed of the fast attack (owner, 2026-09-28: the first test's speed).
@export_range(200.0, 6000.0, 10.0) var fast_dash_speed: float = 1500.0
## Radius of the circle around him that hurts the Wisp during the fast attack, as a share of his
## standing height.
@export_range(0.05, 0.6, 0.01) var fast_danger_ratio: float = 0.25

@export_group("The ill wall")
## Chance, after a rest, that he goes for the Wisp's wall (owner: not every time).
@export_range(0.0, 1.0, 0.01) var ill_wall_chance: float = 0.35
## Seconds after one ill wall before the next can start, and before the first one.
@export_range(0.0, 20.0, 0.1) var ill_wall_cooldown: float = 3.5
@export_range(0.0, 20.0, 0.1) var first_ill_wall_delay: float = 2.5
## Seconds the rot takes to cover the wall: the warning.
@export_range(0.1, 5.0, 0.05) var rot_spread_duration: float = 1.1
## Seconds the whole wall stays deadly.
@export_range(0.1, 5.0, 0.05) var rot_deadly_duration: float = 1.3
## Half width of the deadly wall band, as a share of the Wisp's collision radius.
@export_range(0.1, 2.0, 0.05) var rot_lane_ratio: float = 0.6

@export_group("Death's Grin (second half)")
## Health share at or below which the second half starts.
@export_range(0.05, 0.95, 0.05) var second_half_health: float = 0.5
@export_range(0.0, 1.0, 0.01) var grin_chance: float = 0.5
@export_range(0.0, 30.0, 0.1) var grin_cooldown: float = 6.0
## Seconds the mark waits for the Wisp's next landing before it fades.
@export_range(0.5, 10.0, 0.1) var grin_mark_duration: float = 4.0
## The marked wall rots faster ("at once").
@export_range(0.1, 5.0, 0.05) var grin_rot_spread_duration: float = 0.55
@export_range(0.1, 5.0, 0.05) var grin_rot_deadly_duration: float = 1.0

@export_group("Spawns (owner: regular enemies spawn at random)")
@export_range(0.5, 20.0, 0.1) var spawn_interval_min: float = 3.8
@export_range(0.5, 20.0, 0.1) var spawn_interval_max: float = 5.2
@export_range(0, 6, 1) var spawn_count: int = 1
@export_range(0, 6, 1) var second_half_spawn_count: int = 2
@export_range(0, 12, 1) var max_live_enemies: int = 4

@export_group("Rewards")
@export var score_reward: int = 1500
@export var rp_reward: int = 25
@export var experience_reward: int = 60
@export_range(0.2, 5.0, 0.05) var victory_duration: float = 1.0
