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
## Base attraction radius for dropped Rift Points shard pickups in design-width pixels.
## Chance, per enemy killed, that a Soul Vessel drops: the only way to gain a Soul Fragment
## besides Reaper's Gift. Deliberately rare — a run starts on one fragment and death is final.
@export_range(0.0, 1.0, 0.001) var soul_vessel_drop_chance: float = 0.012
@export_range(40.0, 600.0, 1.0) var shard_attraction_radius: float = 150.0
## Added attraction radius per Soul Hunger level in design-width pixels.
@export_range(0.0, 200.0, 1.0) var hunger_attraction_per_level: float = 35.0

@export_group("Upgrade offer")
## Engine time scale while the upgrade card tray is up (Reduced Motion keeps normal speed).
@export_range(0.05, 1.0, 0.01) var tray_time_scale: float = 0.3
## Real seconds the tray stays up without a pick before it slides away (the level stays banked).
@export_range(1.0, 30.0, 0.5) var tray_timeout: float = 6.0
## Share of the screen height the tray's bottom edge sits above the bottom safe margin, so the cards
## rest in the lower-middle of the screen instead of at the very bottom (owner 2026-09-15).
@export_range(0.0, 0.6, 0.01) var tray_raise_share: float = 0.1
## Real seconds the tray takes to slide up or away (instant under Reduced Motion).
@export_range(0.0, 1.0, 0.01) var tray_slide_seconds: float = 0.22
## Game seconds a calm moment (wave start, boss beaten, field clear) stays open for the tray to wait
## out a running combo or a dash; longer than the 2.2 s combo timeout, so a field clear still offers.
@export_range(0.5, 10.0, 0.1) var calm_window_seconds: float = 4.0
## UPGRADE button glow pulses per second and brightness swing while a level-up is banked (still under
## Reduced Motion).
@export_range(0.1, 6.0, 0.1) var button_pulse_rate: float = 1.2
@export_range(0.0, 1.0, 0.01) var button_pulse_amount: float = 0.35
