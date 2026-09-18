class_name GameWorld
extends Control
## Coordinates one run: waves, combat, mutations, bosses, rewards and the run summary.
##
## Main configures it with a `RunProfile`, whose `ArenaRules` decide the backdrop, floor, rule
## twist, roster, bosses and difficulty. A story run plays exactly one Rift level and ends in victory
## when that level's final boss falls; Endless and the daily run cycle bosses, harder each cycle,
## until death. Level-ups never interrupt: they bank silently and a bottom card tray slides up,
## with the world in slow motion, only at a calm moment (docs/systems/mutations.md). A scripted
## profile (`RunProfile.MODE_TUTORIAL`) starts no waves, never ends and never pauses itself: the
## Tutorial screen's director drives it through the scripted-run hooks and the run event signals below
## (docs/systems/tutorial.md). Real runs never teach.

## Emitted after the paused run requests a return to the Home screen.
signal home_requested
## Emitted with the run statistics after the Wisp death dissolve, or after a story level's victory beat.
signal run_ended(summary: Dictionary)
## Emitted when the player confirms restarting the run from the pause menu.
signal restart_requested
## Run events for observers such as the tutorial director. A dash (or redirect leg) launched.
signal dash_launched(from_redirect: bool)
## A dash leg finished with [param kills] enemies; [param ended_by] is `&"wall"`, `&"redirect"` or
## `&"obstacle"` (a void crystal stopped it).
signal dash_resolved(kills: int, ended_by: StringName)
## An enemy died at [param world_position]; [param dash_kill_index] is its place in the dash (0 when
## no dash killed it).
signal enemy_defeated(world_position: Vector2, dash_kill_index: int)
## The Wisp lost a Soul Fragment and has [param current_health] left.
signal player_damaged(current_health: int)
## The player picked [param mutation_id] on the upgrade card tray.
signal upgrade_chosen(mutation_id: StringName)
## RUSH mode started.
signal rush_started
## A boss encounter was won (after its dissolve).
signal boss_defeated

const ENEMY_SCENES: Dictionary = {
	&"soul_wisp": preload("res://scenes/enemies/soul_wisp.tscn"),
	&"shard_wraith": preload("res://scenes/enemies/shard_wraith.tscn"),
	&"bone_mote": preload("res://scenes/enemies/bone_mote.tscn"),
	&"cinder_shade": preload("res://scenes/enemies/cinder_shade.tscn"),
	&"warden": preload("res://scenes/enemies/warden.tscn"),
	&"rift_spawn": preload("res://scenes/enemies/rift_spawn.tscn"),
	&"echo": preload("res://scenes/enemies/echo.tscn"),
	&"slag_hulk": preload("res://scenes/enemies/slag_hulk.tscn"),
	&"frost_wisp": preload("res://scenes/enemies/frost_wisp.tscn"),
	&"court_shade": preload("res://scenes/enemies/court_shade.tscn"),
}
## Children spawned by a splitter never split again, so a chain cannot run away.
const SPLIT_SPREAD: float = 68.0
## Hard ceiling on concurrent enemies; splits are refused above it.
const MAX_LIVE_ENEMIES: int = 60
## Ember Hollow: the playfield contracts to this fraction by the last wave of a level.
const SHRINK_FLOOR_MINIMUM: float = 0.74
## Reaper's Court: boss rewards are doubled to pay for the doubled boss cadence.
const BOSS_RUSH_REWARD_SCALE: float = 2.0
## Frozen Choir: the Wisp slides along the edge it is resting on, in design px/s.
const DRIFT_EDGE_SPEED: float = 110.0
## Shattered Rift portal pair, in normalised playfield coordinates.
const PORTAL_A_UV := Vector2(0.26, 0.34)
const PORTAL_B_UV := Vector2(0.74, 0.66)
## Portal mouth radius in design pixels; a dash passing within this is swallowed.
const PORTAL_RADIUS: float = 74.0
const PORTAL_ENTRANCE_TEXTURE: Texture2D = preload(
	"res://assets/art/environment/props/10_void_portal_entrance_active.png"
)
const PORTAL_EXIT_TEXTURE: Texture2D = preload(
	"res://assets/art/environment/props/11_void_portal_exit_active.png"
)
const HAZARD_SCENES: Dictionary = {
	&"split_crystal": preload("res://scenes/hazards/split_void_crystal.tscn"),
	&"spike_bloom": preload("res://scenes/hazards/spike_bloom.tscn"),
	&"blade_ring": preload("res://scenes/hazards/blade_ring.tscn"),
}
## The Rift Points pickup; its scene keeps the soul shard name (the art is a shard).
const RP_PICKUP_SCENE: PackedScene = preload("res://scenes/pickups/soul_shard_pickup.tscn")
const REAPER_SCENE: PackedScene = preload("res://scenes/bosses/reaper_boss.tscn")
## Boss variants keyed by boss id (`RiftData.boss_id`, Endless pools); every pick resolves to one.
const BOSS_VARIANTS: Dictionary = {
	&"reaper": preload("res://data/bosses/reaper.tres"),
	&"the_fracture": preload("res://data/bosses/the_fracture.tres"),
	&"cinder_maw": preload("res://data/bosses/cinder_maw.tres"),
	&"hollow_choir": preload("res://data/bosses/hollow_choir.tres"),
	&"reaper_ascended": preload("res://data/bosses/reaper_ascended.tres"),
}
const DEATH_PULSE_TEXTURE: Texture2D = preload("res://assets/art/vfx/06_death_pulse.png")
const COMBO_TIMEOUT: float = 2.2
const RAPID_REDIRECT_WINDOW_MSEC: int = 550
const RAPID_REDIRECT_SCORE: int = 25
const PULSE_EVENT_OFFSET: int = 1000000
const REAPER_WAVE_INTERVAL: int = 4
const SETTINGS_SCENE: PackedScene = preload("res://scenes/screens/settings_screen.tscn")
const DASH_TRAIL_SHORT: Texture2D = preload("res://assets/art/vfx/01_dash_trail_short.png")
const DASH_TRAIL_LONG: Texture2D = preload("res://assets/art/vfx/02_dash_trail_long.png")
const WALL_IMPACT_LARGE: Texture2D = preload("res://assets/art/vfx/04_wall_impact_large.png")
const SOUL_SLICE: Texture2D = preload("res://assets/art/vfx/05_soul_slice.png")
const ENEMY_DISSOLVE: Texture2D = preload("res://assets/art/vfx/08_enemy_dissolve.png")
const VFX_SOURCE_SIZE: float = 362.0
## Maximum shake offset in design pixels (1080-wide arena) at full trauma.
const SHAKE_MAX_OFFSET: float = 12.0
## Trauma lost per second.
const TRAUMA_DECAY: float = 1.8
## Shake multiplier applied on top of Screen Shake when Reduced Motion is on.
const REDUCED_MOTION_SHAKE: float = 0.3
const HIT_STOP_SECONDS: float = 0.06
const HIT_STOP_TIME_SCALE: float = 0.08
## RUSH soul orb art and its size in Wisp radii at launch and on arrival.
const RUSH_ORB_TEXTURE: Texture2D = preload("res://assets/art/vfx/12_collectible_sparkle.png")
const RUSH_ORB_START_RADII: float = 1.6
const RUSH_ORB_END_RADII: float = 0.7
## The RUSH start callout grows past the normal callout size.
const RUSH_CALLOUT_SCALE: float = 1.5
## Gradient texture size in px for the RUSH screen-edge glow; the glow starts at this share of the
## half-screen radius.
const RUSH_EDGE_GLOW_TEXTURE_SIZE: int = 256
const RUSH_EDGE_GLOW_INNER: float = 0.62
## Brightness swing of the full RUSH bar pulse, and how fast its displayed fill catches up.
const RUSH_BAR_PULSE_AMOUNT: float = 0.3
const RUSH_BAR_CATCH_UP_RATE: float = 14.0
## The painted stone floor of wisp_rush_arena_background.png in texture UV space (measured from the
## art): the largest rectangle inscribed in its octagon. The playfield is inset to this, so the Wisp
## always rests on stone instead of the void, the scenery or under the HUD.
const ARENA_FLOOR_UV := Rect2(0.145, 0.255, 0.700, 0.515)
## The playfield never shrinks below this fraction of the viewport, whatever the aspect ratio.
const ARENA_MIN_VIEWPORT_FRACTION := Vector2(0.70, 0.50)
## The playfield is inset by this multiple of the Wisp's collision radius, so its sprite stays
## visible at the wall. Defined once here and pushed down: it used to be repeated as a bare 1.35 in
## the player and the safe-reform search, which could silently disagree.
const LANDING_INSET: float = 1.35
## Launch haptic: a crisp tick when a dash fires from rest or a wall. Redirects use a lighter one so
## a fast chain feels rhythmic rather than buzzy.
const LAUNCH_HAPTIC_MS: int = 18
const LAUNCH_HAPTIC_AMPLITUDE: float = 0.6
const REDIRECT_HAPTIC_MS: int = 10
const REDIRECT_HAPTIC_AMPLITUDE: float = 0.4
## Design pixels the backdrop extends past the viewport so shake never reveals its edges.
const BACKGROUND_OVERSCAN: float = 16.0
## HUD geometry in design pixels (1080-wide canvas), measured from the safe-area insets.
const HUD_RING_SIZE: float = 144.0
const HUD_PAUSE_SIZE: float = 112.0
const HUD_PLATE_TOP: float = 22.0
const HUD_WAVE_TOP: float = 150.0
const HUD_XP_TOP: float = 192.0
const HUD_LEVEL_TOP: float = 214.0
## RUSH row (label + slim bar) under the soul level; the boss panel and callouts sit below it.
const HUD_RUSH_TOP: float = 252.0
const HUD_RUSH_HEIGHT: float = 32.0
const HUD_BOSS_TOP: float = 296.0
const HUD_CALLOUT_TOP: float = 474.0
const HUD_FOCUS_TOP: float = 564.0
## UPGRADE button (tappable, shown while a level-up is banked): size and gap under the pause button.
const HUD_UPGRADE_BUTTON_SIZE: float = 132.0
const HUD_UPGRADE_BUTTON_GAP: float = 18.0
## Time-scale hold key of the upgrade card tray (`_hold_time_scale`).
const TIME_SCALE_HOLD_UPGRADE_TRAY: StringName = &"upgrade_tray"
## World tint over the arena backdrop: calm run, Reaper encounter and the post-Reaper release.
const SHADE_CALM: Color = Color(Palette.VOID_CHARCOAL, 0.14)
const SHADE_BOSS: Color = Color(Palette.VOID_CHARCOAL * 0.8 + Palette.RIFT_MAGENTA * 0.2, 0.5)
const SHADE_VICTORY: Color = Color(Palette.SLATE_TEAL, 0.26)

## Deterministic run seed; zero derives one from the current clock.
@export var run_seed: int = 0
## Pause automatically when the app loses focus or is backgrounded (QA fixtures turn it off).
@export var auto_pause_on_focus_loss: bool = true
## Rift Points payouts that are not pickups (performance bonus); see docs/systems/shop.md.
@export var economy_tuning: EconomyTuning
## Momentum visuals, shard sweep, finisher and RUSH values (GDD §5.6); defaults when unset.
@export var feel_tuning: RunFeelTuning

var _arena_rect: Rect2 = Rect2()
var _score: int = 0
var _combo: int = 0
var _highest_combo: int = 0
var _total_kills: int = 0
var _multi_kill_dashes: int = 0
var _rapid_ricochets: int = 0
## Rift Points collected this run: pickups, multi-reap and boss rewards (not the performance bonus).
var _rp_collected: int = 0
var _kill_streak: int = 0
var _bosses_defeated: int = 0
var _current_wave: int = 1
var _combo_remaining: float = 0.0
var _focus_remaining: float = 0.0
var _waves_start_remaining: float = -1.0
var _remaining_live_enemies: int = 0
var _run_over: bool = false
var _waves_started: bool = false
var _boss_pending: bool = false
var _post_boss_remaining: float = -1.0
var _boss: ReaperBoss
## Main's cover/prewarm: the arena is built and drawn but the run waits for `release_start()`.
var _start_held: bool = false
## `_begin_run` arrived while held and runs on release.
var _start_pending: bool = false
## Throwaway nodes `warm_up_render()` draws once under the cover; freed on release.
var _warm_nodes: Array[Node] = []
## Tutorial arena (`RunProfile.is_scripted`): no waves, no self-pause, the host owns back.
var _scripted: bool = false
## Whether kills and bosses grant XP; scripted lessons switch it (always on in real runs).
var _experience_enabled: bool = true
## Whether the RUSH meter fills and RUSH may start; scripted lessons switch it (on in real runs).
var _rush_enabled: bool = true
var _last_wall_impact_msec: int = -1
var _kills_by_dash: Dictionary[int, int] = {}
var _rapid_redirect_dashes: Dictionary[int, bool] = {}
var _link_remaining_by_event: Dictionary[int, int] = {}
var _random := RandomNumberGenerator.new()
var _callout_tween: Tween
var _cosmetic_form: FormData
## Equipped dash style: tints the dash trail and launch burst only; null plays the SOUL look.
var _dash_style: DashStyleData
## The arena this run plays under: a Rift level, or Endless rules. Never null.
var _arena_rules: ArenaRules = ArenaRules.new()
## Rule twist for the active arena; `&"none"` is the baseline (always, on Endless rules).
var _rift_rule: StringName = &"none"
## Animated scenery of Legendary/Mythic Endless skins: shader on the backdrop + glow particles.
var _ambience: ArenaAmbience
## `RunProfile.MODE_STORY`, `MODE_DAILY` or `MODE_ENDLESS`.
var _mode: StringName = RunProfile.MODE_STORY
## One-based story level being played (1 on Endless rules).
var _rift_level: int = 1
## Whether a story victory here would be this level's first clear (from the profile).
var _first_clear_possible: bool = false
## Set when the story level's final boss falls; the run then ends in victory after the beat.
var _level_cleared: bool = false
## Waves between boss encounters, from the arena rules.
var _boss_wave_interval: int = REAPER_WAVE_INTERVAL
## Playfield contraction from the `shrinking_floor` rule; 1.0 is the full painted floor.
var _arena_shrink: float = 1.0
## The active Rift's painted floor in screen space. Empty means fall back to the rectangle.
var _arena_polygon: PackedVector2Array = PackedVector2Array()
## `_arena_polygon` inset by the Wisp's radius: the wall a dash actually lands on.
var _landing_polygon: PackedVector2Array = PackedVector2Array()
## Boss reward multiplier from the `boss_rush` rule.
var _rift_reward_multiplier: float = 1.0
## The Shattered Rift's linked portal sprites; empty in every other Rift.
var _portals: Array[Sprite2D] = []
## Dash id already teleported, so one dash can never loop between the pair.
var _portal_used_dash_id: int = -1
var _daily_date_key: String = ""
var _vfx: VfxPool
## Splash played where the Wisp hits a wall.
var _wall_splash: WallSplashFx
## Aim preview path line and ×N count, fed by `WispPlayer.aim_preview_changed`.
var _aim_guide: AimGuide
## Whether any enemy may still be lit by the aim preview, so clearing walks the layer only once.
var _aim_highlight_active: bool = false
## Set between `dash_redirected` and the `dash_started` that follows it, to pick the lighter haptic.
var _redirect_pending: bool = false
var _settings_overlay: SettingsScreen
var _confirm_action: StringName = &""
var _dash_origin: Vector2 = Vector2.ZERO
var _dash_direction: Vector2 = Vector2.RIGHT
var _trauma: float = 0.0
var _shake_time: float = 0.0
var _shake_strength: float = 1.0
var _reduced_motion: bool = false
## Active time-scale requests by id; the lowest scale wins (see `_request_time_scale`).
var _time_scale_requests: Dictionary[int, float] = {}
var _next_time_scale_request_id: int = 0
## Held time scales by key, released explicitly (`_hold_time_scale`); they join the lowest-wins rule.
var _time_scale_holds: Dictionary[StringName, float] = {}
## Calm moments (wave start, boss beaten, field clear): each one gets a new id and a short window in
## which the banked upgrade cards may open; a moment whose cards were shown never offers again.
var _calm_moment_id: int = 0
var _calm_window_remaining: float = 0.0
var _upgrade_offer_spent_moment_id: int = 0
## Tutorial lesson asked for its calm moment (`request_upgrade_calm_moment`); cleared when cards open.
var _scripted_upgrade_calm_requested: bool = false
## Real seconds left before the open tray slides away on its own.
var _upgrade_tray_remaining: float = 0.0
## Extra design px a host screen lifts the tray above the bottom safe margin (tutorial caption band).
var _upgrade_tray_lift: float = 0.0
var _upgrade_button_pulse_time: float = 0.0
## World shade colour set by run state; the finisher flash blends over it.
var _shade_base_color: Color = SHADE_CALM
var _finisher_flash: float = 0.0
var _finisher_flash_tween: Tween
var _field_clear_cooldown_remaining: float = 0.0
## RUSH meter (0..meter_max), frozen while RUSH runs or RUSH is disabled (`set_rush_enabled`).
var _rush_meter: float = 0.0
## Game seconds of RUSH left; > 0 while RUSH mode is active.
var _rush_remaining: float = 0.0
var _rush_count: int = 0
## Bar fill shown on the HUD, and the fill the soul orbs have delivered so far (≤ `_rush_meter`).
var _rush_display: float = 0.0
var _rush_display_target: float = 0.0
var _rush_pulse_time: float = 0.0
var _rush_edge_glow: TextureRect

@onready var _enemy_layer: Node2D = %EnemyLayer
@onready var _hazard_layer: Node2D = %HazardLayer
@onready var _boss_layer: Node2D = %BossLayer
@onready var _pickup_layer: Node2D = %PickupLayer
@onready var _effects_layer: Node2D = %EffectsLayer
@onready var _player: WispPlayer = %WispPlayer
@onready var _wave_director: WaveDirector = %WaveDirector
@onready var _run_progression: RunProgression = %RunProgression
@onready var _world_shade: ColorRect = %WorldShade
@onready var _health_row: HBoxContainer = %HealthRow
@onready var _life_count: Label = %LifeCount
@onready var _rift_points_count: Label = %RiftPointsCount
@onready var _score_label: Label = %ScoreLabel
@onready var _score_plate: PanelContainer = %ScorePlate
@onready var _form_portrait: TextureRect = %FormPortrait
@onready var _wave_label: Label = %WaveLabel
@onready var _xp_bar: ProgressBar = %XPBar
@onready var _run_level_label: Label = %RunLevelLabel
@onready var _rush_row: HBoxContainer = %RushRow
@onready var _rush_bar: ProgressBar = %RushBar
@onready var _pause_button: Button = %PauseButton
@onready var _upgrade_button: Button = %UpgradeButton
@onready var _upgrade_count: Label = %UpgradeCount
@onready var _combo_label: Label = %ComboLabel
@onready var _focus_label: Label = %FocusLabel
@onready var _instruction_label: Label = %InstructionLabel
@onready var _boss_hud: PanelContainer = %BossHud
@onready var _boss_warning: Label = %BossWarning
@onready var _boss_bar: ProgressBar = %BossBar
@onready var _boss_phase_label: Label = %BossPhaseLabel
@onready var _upgrade_tray: UpgradeTray = %UpgradeTray
@onready var _pause_overlay: Control = %PauseOverlay
@onready var _resume_button: Button = %ResumeButton
@onready var _home_button: Button = %HomeButton
@onready var _restart_button: Button = %RestartButton
@onready var _settings_button: Button = %SettingsButton
@onready var _confirm_overlay: Control = %ConfirmOverlay
@onready var _confirm_title: Label = %ConfirmTitle
@onready var _confirm_yes_button: Button = %ConfirmYesButton
@onready var _confirm_cancel_button: Button = %ConfirmCancelButton
@onready var _background: TextureRect = %FullBleedBackground


func _ready() -> void:
	if run_seed == 0:
		run_seed = int(Time.get_unix_time_from_system()) ^ int(get_instance_id())
	_random.seed = run_seed
	get_viewport().size_changed.connect(_on_viewport_size_changed)
	_player.dash_started.connect(_on_player_dash_started)
	_player.dash_redirected.connect(_on_player_dash_redirected)
	_player.dash_segment_swept.connect(_on_player_dash_segment_swept)
	_player.wall_impacted.connect(_on_player_wall_impacted)
	_player.obstacle_impacted.connect(_on_player_obstacle_impacted)
	_player.focus_started.connect(_on_player_focus_started)
	_player.health_changed.connect(_on_player_health_changed)
	_player.damaged.connect(_on_player_damaged)
	_player.died.connect(_on_player_died)
	_player.aim_preview_changed.connect(_on_player_aim_preview_changed)
	# The one query handed down to the Wisp: its aim assist scores directions with it.
	_player.set_aim_target_counter(_count_aim_targets)
	_wave_director.formation_requested.connect(_on_formation_requested)
	_wave_director.wave_started.connect(_on_wave_started)
	_run_progression.experience_changed.connect(_on_experience_changed)
	_run_progression.level_ready.connect(_on_progression_level_ready)
	_run_progression.mutation_applied.connect(_on_mutation_applied)
	_upgrade_tray.choice_selected.connect(_on_upgrade_choice_selected)
	_pause_button.pressed.connect(_on_pause_button_pressed)
	_upgrade_button.pressed.connect(_on_upgrade_button_pressed)
	_resume_button.pressed.connect(_on_resume_button_pressed)
	_home_button.pressed.connect(_on_home_button_pressed)
	_restart_button.pressed.connect(_on_restart_button_pressed)
	_settings_button.pressed.connect(_open_settings_overlay)
	_confirm_yes_button.pressed.connect(_on_confirm_yes_button_pressed)
	_confirm_cancel_button.pressed.connect(_close_confirm)
	_pause_overlay.visible = false
	_confirm_overlay.visible = false
	_ambience = ArenaAmbience.new()
	_ambience.name = "ArenaAmbience"
	_ambience.set_anchors_preset(Control.PRESET_FULL_RECT)
	_ambience.process_mode = Node.PROCESS_MODE_PAUSABLE
	# Between the painted backdrop and WorldShade, so boss and victory shading tint its particles too.
	_background.add_sibling(_ambience)
	_vfx = VfxPool.new()
	_vfx.name = "VfxPool"
	_effects_layer.add_sibling(_vfx)
	_wall_splash = WallSplashFx.new()
	_wall_splash.name = "WallSplashFx"
	# A persistent pool, so a sibling of EffectsLayer like VfxPool - EffectsLayer holds only the
	# transient per-effect nodes (such as Death Pulse), and code counts on that.
	_effects_layer.add_sibling(_wall_splash)
	_wall_splash.setup(_vfx)
	_aim_guide = AimGuide.new()
	_aim_guide.name = "AimGuide"
	# Under enemies and hazards (lit rings and crystals read on top of the line), above the floor.
	_enemy_layer.add_sibling(_aim_guide)
	_enemy_layer.get_parent().move_child(_aim_guide, _enemy_layer.get_index())
	for button: Node in _upgrade_tray.find_children("*", "BaseButton", true, false):
		button.set_meta(SoundFx.SKIP_META, true)
	if feel_tuning == null:
		feel_tuning = RunFeelTuning.new()
	_build_rush_edge_glow()
	var save_manager := get_node_or_null(^"/root/SaveManager") as SaveManagerService
	if save_manager != null:
		_apply_feel_settings(save_manager.get_settings())
		save_manager.settings_changed.connect(_apply_feel_settings)
	_set_world_shade(SHADE_CALM)
	_combo_label.visible = false
	_focus_label.visible = false
	_boss_hud.visible = false
	_boss_warning.add_theme_color_override(&"font_color", Palette.RIFT_MAGENTA)
	if _cosmetic_form != null:
		_player.set_cosmetic_form(
			_cosmetic_form.texture,
			_cosmetic_form.tint,
			_cosmetic_form.visual_scene,
		)
		_form_portrait.texture = _cosmetic_form.texture
	_apply_arena()
	_update_player_mutation_stats()
	_player.set_momentum_presentation(feel_tuning, _get_dash_trail_tint())
	_rush_bar.max_value = feel_tuning.meter_max
	_refresh_rush_hud()
	# Clears per-run rewarded placement locks; a no-op on the shipped build (ADR-0009).
	var monetisation := get_node_or_null(^"/root/Monetisation") as MonetisationService
	if monetisation != null:
		monetisation.begin_run()
	_life_count.text = str(_player.get_current_health())
	_rift_points_count.text = "0"
	_layout_for_viewport()
	_run_progression.start(run_seed + 41)
	call_deferred(&"_begin_run")
	print("[GameWorld] ready | arena=%s seed=%d" % [_arena_rect.size, run_seed])


func _process(delta: float) -> void:
	if not get_tree().paused:
		_update_shake(delta)
	if get_tree().paused or _run_over:
		return
	_update_enemy_targets()
	_update_boss_target()
	_update_combo(delta)
	_update_focus(delta)
	_update_rush(delta)
	_field_clear_cooldown_remaining = maxf(0.0, _field_clear_cooldown_remaining - delta)
	_update_waves_start(delta)
	_update_post_boss(delta)
	if _waves_started:
		_wave_director.set_run_context(
			_player.get_current_health(),
			_player.get_maximum_health(),
			_run_progression.get_total_mutation_levels(),
		)
		_wave_director.advance(delta, _remaining_live_enemies)
	if (
		_boss_pending
		and not _upgrade_tray.is_open()
		and _player.state == WispPlayer.State.WAITING_AT_EDGE
	):
		_start_boss_encounter()
	_update_upgrade_offer(delta)


func _physics_process(_delta: float) -> void:
	if get_tree().paused or _run_over:
		return
	_check_world_contacts()


func _unhandled_input(event: InputEvent) -> void:
	# A scripted arena's host screen owns back and Escape (the tutorial's skip confirm).
	if _scripted:
		return
	if event.is_action_pressed(&"pause"):
		get_viewport().set_input_as_handled()
		handle_back()


## Returns the current run score.
func get_score() -> int:
	return _score


## Returns the current active combo before its timeout reaches zero.
func get_combo() -> int:
	return _combo


## Returns the highest combo reached during this run.
func get_highest_combo() -> int:
	return _highest_combo


## Returns the number of enemies defeated during this run.
func get_total_kills() -> int:
	return _total_kills


## Returns the current one-based wave.
func get_current_wave() -> int:
	return _current_wave


## Returns Rift Points collected this run (pickups, multi-reaps, bosses), separate from score.
func get_rp_collected() -> int:
	return _rp_collected


## Performance bonus the current score would pay if the run ended now.
func get_rp_performance() -> int:
	return economy_tuning.get_performance_points(_score) if economy_tuning != null else 0


## Returns completed dashes that defeated at least two enemies.
func get_multi_kill_dashes() -> int:
	return _multi_kill_dashes


## Returns Reaper encounters defeated during this run.
func get_bosses_defeated() -> int:
	return _bosses_defeated


## Whether RUSH mode is running (GDD §5.6).
func is_rush_active() -> bool:
	return _rush_remaining > 0.0


## RUSH meter, 0..`RunFeelTuning.meter_max`; full while RUSH runs, 0 after it ends.
func get_rush_meter() -> float:
	return _rush_meter


## Game seconds of RUSH left (0 when RUSH is off).
func get_rush_remaining() -> float:
	return _rush_remaining


## RUSH activations so far this run (also the summary's `rush_count`).
func get_rush_count() -> int:
	return _rush_count


## Returns whether the Reaper currently owns encounter flow.
func is_boss_active() -> bool:
	return is_instance_valid(_boss)


## Adds run XP through the same progression path as enemy rewards.
func add_experience(amount: int) -> void:
	_grant_experience(amount)


## Returns the current run-only level for one mutation identifier.
func get_mutation_level(mutation_id: StringName) -> int:
	return _run_progression.get_mutation_level(mutation_id)


## Holds the run start (Main's cover-then-build and run prewarm): the arena builds and draws, but the
## first wave, pause-on-focus-loss and the scripted-arena hand-off wait for [method release_start].
## Call before adding the node to the tree. Main also keeps a held run PROCESS_MODE_DISABLED while
## it is hidden, so no clock, input or timer ticks.
func hold_start() -> void:
	_start_held = true


## Whether the run start is still held by [method hold_start].
func is_start_held() -> bool:
	return _start_held


## While held and in the tree: draws one instance of every enemy kind and an additive VFX sprite
## inside the arena, so their first-draw (pipeline) costs are paid under a cover. Freed on release.
func warm_up_render() -> void:
	if not _start_held or not is_node_ready():
		return
	var centre: Vector2 = _arena_rect.get_center()
	var step: float = _arena_rect.size.x / float(ENEMY_SCENES.size() + 1)
	var index: int = 0
	for kind: StringName in ENEMY_SCENES:
		var enemy := (ENEMY_SCENES[kind] as PackedScene).instantiate() as Node2D
		enemy.name = "Warm_%s" % kind
		enemy.process_mode = Node.PROCESS_MODE_DISABLED
		_enemy_layer.add_child(enemy)
		index += 1
		enemy.global_position = Vector2(_arena_rect.position.x + step * float(index), centre.y)
		_warm_nodes.append(enemy)
	if _vfx != null:
		_vfx.play(DASH_TRAIL_SHORT, centre, 0.0, Vector2.ONE, Vector2.ONE, 60.0)


## Starts the held run: frees the warm-up nodes and runs the start `_ready` deferred. Main calls it
## as the run is revealed, after restoring the node's process mode.
func release_start() -> void:
	if not _start_held:
		return
	_start_held = false
	for node: Node in _warm_nodes:
		if is_instance_valid(node):
			node.get_parent().remove_child(node)
			node.queue_free()
	_warm_nodes.clear()
	if _vfx != null:
		_vfx.clear()
	if _start_pending:
		_start_pending = false
		_begin_run()


## Applies a run profile built by Main: mode, arena rules, seed, daily identity and cosmetic form.
##
## Call before adding the node to the tree so the seed applies; later calls still swap the Rift and
## form (fixtures do this).
func configure_run(profile: RunProfile) -> void:
	if profile == null:
		return
	_mode = profile.mode
	_scripted = profile.is_scripted()
	_cosmetic_form = profile.form
	_dash_style = profile.dash_style
	_daily_date_key = profile.daily_date_key
	_arena_rules = profile.create_arena_rules()
	_rift_level = maxi(1, profile.level) if profile.is_story() else 1
	_first_clear_possible = profile.first_clear_possible
	if profile.run_seed != 0 and not is_node_ready():
		run_seed = profile.run_seed
	if is_node_ready() and _cosmetic_form != null:
		_player.set_cosmetic_form(
			_cosmetic_form.texture,
			_cosmetic_form.tint,
			_cosmetic_form.visual_scene,
		)
		_form_portrait.texture = _cosmetic_form.texture
	if is_node_ready():
		_player.set_momentum_presentation(feel_tuning, _get_dash_trail_tint())
		_apply_arena()
		_layout_for_viewport()


## The animated scenery layer over the backdrop (no scenery unless the skin has it).
func get_arena_ambience() -> ArenaAmbience:
	return _ambience


## Run mode from the profile: `RunProfile.MODE_STORY`, `MODE_DAILY`, `MODE_ENDLESS` or
## `MODE_TUTORIAL`.
func get_run_mode() -> StringName:
	return _mode


## One-based Rift level this run plays.
func get_rift_level() -> int:
	return _rift_level


## Boss cycles completed: bosses beaten this run, which drives Endless difficulty.
func get_cycle() -> int:
	return _bosses_defeated


## The arena rules this run plays under.
func get_arena_rules() -> ArenaRules:
	return _arena_rules


## Whether this story run's level has been cleared (its final boss beaten).
func is_level_cleared() -> bool:
	return _level_cleared


## Swaps in the arena's backdrop and latches its rule twist and boss cadence.
##
## Every arena background (Rifts and Endless skins) shares the native 941x1672 size, so
## ARENA_FLOOR_UV stays valid and _compute_arena_rect() derives the playfield from the texture.
func _apply_arena() -> void:
	_rift_rule = _arena_rules.get_rule_key()
	var backdrop: Texture2D = _arena_rules.get_background()
	if backdrop != null:
		_background.texture = backdrop
	if _ambience != null:
		_ambience.configure(_arena_rules.get_scenery(), _background)
	_boss_wave_interval = maxi(1, _arena_rules.get_boss_wave_interval())
	_rift_reward_multiplier = 1.0
	_arena_shrink = 1.0
	_build_portals()
	# Reaper's Court trades twice the boss cadence (in its rules) for twice the boss payout.
	if _rift_rule == &"boss_rush":
		_rift_reward_multiplier = BOSS_RUSH_REWARD_SCALE
	# Frozen Choir: the Wisp never quite stands still between dashes.
	_player.set_edge_drift(DRIFT_EDGE_SPEED if _rift_rule == &"drift" else 0.0)
	_apply_arena_difficulty()


## Creates or clears the Shattered Rift's linked portal pair.
func _build_portals() -> void:
	for portal: Sprite2D in _portals:
		if is_instance_valid(portal):
			portal.queue_free()
	_portals.clear()
	if _rift_rule != &"portals":
		return
	for texture: Texture2D in [PORTAL_ENTRANCE_TEXTURE, PORTAL_EXIT_TEXTURE]:
		var portal := Sprite2D.new()
		portal.texture = texture
		portal.z_index = -1
		_hazard_layer.add_child(portal)
		_portals.append(portal)
	_layout_portals()


## Places the portal pair inside the current playfield and scales it to the viewport.
func _layout_portals() -> void:
	if _portals.size() != 2 or _arena_rect.size.x <= 0.0:
		return
	var scale_factor: float = _arena_rect.size.x / 1080.0
	var uvs: Array[Vector2] = [PORTAL_A_UV, PORTAL_B_UV]
	for index: int in _portals.size():
		var portal: Sprite2D = _portals[index]
		portal.global_position = _place_on_floor(
			_arena_rect.position + uvs[index] * _arena_rect.size,
			PORTAL_RADIUS * scale_factor * 1.4,
		)
		portal.scale = Vector2.ONE * (PORTAL_RADIUS * 2.4 / VFX_SOURCE_SIZE) * scale_factor


## Teleports a dash that crosses one portal to its pair, once per dash.
##
## Returns true when the dash was moved, so the caller stops applying this segment: everything
## beyond the portal mouth belongs to the new segment emitted from the exit.
func _try_portal_transit(segment_start: Vector2, segment_end: Vector2, dash_id: int) -> bool:
	if _portals.size() != 2 or dash_id == _portal_used_dash_id:
		return false
	var radius: float = PORTAL_RADIUS * (_arena_rect.size.x / 1080.0)
	for index: int in _portals.size():
		var portal: Sprite2D = _portals[index]
		if not is_instance_valid(portal):
			continue
		if DashGeometry.distance_to_segment(
			portal.global_position, segment_start, segment_end
		) > radius:
			continue
		var exit_portal: Sprite2D = _portals[1 - index]
		if not is_instance_valid(exit_portal):
			continue
		# Leave the exit mouth immediately so the pair cannot swallow the dash again.
		var direction: Vector2 = (segment_end - segment_start).normalized()
		var exit_point: Vector2 = exit_portal.global_position + direction * (radius * 1.15)
		if _player.teleport_dash_to(exit_point):
			_portal_used_dash_id = dash_id
			var flare: float = radius * 3.0 / VFX_SOURCE_SIZE
			_vfx.play(
				PORTAL_ENTRANCE_TEXTURE,
				portal.global_position,
				0.0,
				Vector2.ONE * flare,
				Vector2.ONE * flare * 1.7,
				0.24,
				Color(Palette.SOUL_CYAN, 0.9),
			)
			_vfx.play(
				PORTAL_EXIT_TEXTURE,
				exit_portal.global_position,
				0.0,
				Vector2.ONE * flare * 1.7,
				Vector2.ONE * flare,
				0.24,
				Color(Palette.RIFT_MAGENTA, 0.9),
			)
			SoundFx.play(&"dash")
			return true
	return false


## Applies per-wave rule effects for the active Rift.
##
## Only `shrinking_floor` varies within a level; the other rules are latched once at run start.
func _update_rift_rules(wave: int) -> void:
	if _rift_rule != &"shrinking_floor":
		return
	# Contract smoothly across the level (or across each boss cycle under boss rush).
	var step: int = posmod(wave - 1, maxi(1, _boss_wave_interval))
	var progress: float = float(step) / float(maxi(1, _boss_wave_interval))
	var shrink: float = lerpf(1.0, SHRINK_FLOOR_MINIMUM, progress)
	if is_equal_approx(shrink, _arena_shrink):
		return
	_arena_shrink = shrink
	_layout_for_viewport()


## Pushes the arena's difficulty for the current cycle into the wave director and live enemies.
##
## Called at run start, and after each Endless-rules boss, whose cycle raises threat and speed.
func _apply_arena_difficulty() -> void:
	_wave_director.set_rift_threat_multiplier(_arena_rules.get_threat_multiplier(_bosses_defeated))
	var speed_scale: float = _arena_rules.get_enemy_speed_scale(_bosses_defeated)
	for child: Node in _enemy_layer.get_children():
		if child is EnemyActor:
			(child as EnemyActor).set_speed_scale(speed_scale)


## Boss variant for this encounter, falling back to the Reaper for unknown ids.
func _get_boss_variant() -> BossData:
	var id: StringName = _arena_rules.get_boss_id(_bosses_defeated, run_seed)
	if not BOSS_VARIANTS.has(id):
		push_warning("Unknown boss id %s; falling back to the Reaper" % id)
		id = &"reaper"
	return BOSS_VARIANTS[id] as BossData


## Waves between boss encounters in the active arena (half a level under `boss_rush`).
func get_boss_wave_interval() -> int:
	return _boss_wave_interval


## Current playfield contraction from the `shrinking_floor` rule; 1.0 is the full floor.
func get_arena_shrink() -> float:
	return _arena_shrink


## Boss reward multiplier from the `boss_rush` rule.
func get_reward_multiplier() -> float:
	return _rift_reward_multiplier


## World positions of the active Rift's portal pair; empty when the Rift has none.
func get_portal_positions() -> PackedVector2Array:
	var points := PackedVector2Array()
	for portal: Sprite2D in _portals:
		if is_instance_valid(portal):
			points.append(portal.global_position)
	return points


## The active Rift's painted floor in screen space; empty when running on the legacy rectangle.
func get_arena_polygon() -> PackedVector2Array:
	return _arena_polygon


## The floor inset by the Wisp's radius — the wall a dash lands on, and where the Wisp may rest.
func get_landing_polygon() -> PackedVector2Array:
	return _landing_polygon


## The wall splash effect node, for tests.
func get_wall_splash_fx() -> WallSplashFx:
	return _wall_splash


## Live playfield rectangle, for tests and layout checks.
func get_arena_rect() -> Rect2:
	return _arena_rect


## Test hook: stops wave spawning and clears the arena, so a test starts from an empty playfield.
func debug_quiet_arena() -> void:
	_wave_director.suspend_for_boss()
	_clear_enemies()
	_clear_hazards()


## Test hook: spawns one enemy of an exact kind, bypassing the Rift roster remap.
func debug_spawn_enemy(kind: StringName, world_position: Vector2) -> EnemyActor:
	if not ENEMY_SCENES.has(kind):
		return null
	return _spawn_enemy(kind, world_position, false, false)


## Live enemies currently tracked by the wave accounting.
func debug_live_enemy_count() -> int:
	return _remaining_live_enemies


## Enemies actually present in the enemy layer.
func debug_enemy_layer_count() -> int:
	var total: int = 0
	for child: Node in _enemy_layer.get_children():
		if child is EnemyActor:
			total += 1
	return total


## Test hook: applies the per-wave rule effects for an arbitrary wave without waiting for it.
func debug_apply_rift_rules(wave: int) -> void:
	_update_rift_rules(wave)


# --- Scripted-run hooks: the Tutorial screen's director drives a `MODE_TUTORIAL` arena. ---


## Whether this arena is scripted (tutorial): no waves, run end, self-pause or recording.
func is_scripted() -> bool:
	return _scripted


## Screen point for [param arena_uv] (0..1 across the playfield rect), moved onto the painted floor
## [param margin] px clear of the wall.
func arena_to_world(arena_uv: Vector2, margin: float = 0.0) -> Vector2:
	return _place_on_floor(_arena_rect.position + _arena_rect.size * arena_uv, margin)


## Spawns one stationary enemy of exactly [param kind] at [param arena_uv] (`debug_spawn_enemy`).
func spawn_scripted_enemy(kind: StringName, arena_uv: Vector2) -> EnemyActor:
	return debug_spawn_enemy(kind, arena_to_world(arena_uv, _floor_margin()))


## Spawns one hazard of [param kind] at [param arena_uv].
func spawn_scripted_hazard(kind: StringName, arena_uv: Vector2) -> HazardActor:
	if not HAZARD_SCENES.has(kind):
		return null
	return _spawn_hazard(kind, arena_to_world(arena_uv, _floor_margin() * 2.0))


## Empties the arena for the next lesson step: enemies, hazards, any boss (freed without a defeat),
## floor shards (collected) and an open upgrade tray (its level stays banked).
func clear_scripted_arena() -> void:
	_scripted_upgrade_calm_requested = false
	_close_upgrade_tray(&"reset")
	debug_quiet_arena()
	if is_instance_valid(_boss):
		_boss.queue_free()
		_boss = null
		_boss_hud.visible = false
		_set_world_shade(SHADE_CALM)
		_update_music_state()
	_sweep_floor_shards(true)


## Starts a boss encounter now with [param health] (rounded to three phase bands).
func start_scripted_boss(health: int) -> void:
	_start_boss_encounter(health)


## Whether a boss is on the field with its core open to a hit.
func is_boss_core_exposed() -> bool:
	return is_instance_valid(_boss) and _boss.is_core_exposed()


## Nearest live target (active enemy, else the boss) to [param origin]; [param origin] when none.
func find_nearest_target(origin: Vector2) -> Vector2:
	var nearest: EnemyActor = _find_nearest_active_enemy(origin, null)
	if nearest != null:
		return nearest.global_position
	return _boss.global_position if is_instance_valid(_boss) else origin


## Turns XP from kills and bosses on or off (real runs keep it on).
func set_experience_enabled(enabled: bool) -> void:
	_experience_enabled = enabled


## Adds XP, bypassing `set_experience_enabled`, until the bar holds [param share] (0..1) of the next
## threshold; 1.0 banks a level-up; its cards wait for `request_upgrade_calm_moment`.
func set_experience_share(share: float) -> void:
	var target: int = ceili(float(_run_progression.get_xp_threshold()) * clampf(share, 0.0, 1.0))
	var missing: int = target - _run_progression.get_current_xp()
	if missing > 0:
		_run_progression.add_experience(missing)


## Turns the RUSH meter and RUSH mode on or off (row shown only while on); off ends a running RUSH.
func set_rush_enabled(enabled: bool) -> void:
	if not enabled:
		_end_rush(false)
	_rush_enabled = enabled
	if is_node_ready():
		_refresh_rush_hud()


## Sets the RUSH meter to [param value] (0..`meter_max`), ending a running RUSH first.
func set_rush_meter(value: float) -> void:
	_end_rush(false)
	_rush_meter = clampf(value, 0.0, feel_tuning.meter_max)
	_rush_display = _rush_meter
	_rush_display_target = _rush_meter
	_refresh_rush_hud()


## Restores every Soul Fragment.
func refill_health() -> void:
	_player.heal(_player.get_maximum_health())


## One hazard hit that reforms the Wisp at [param arena_uv] (demonstrations of damage).
func hit_player_at(arena_uv: Vector2) -> bool:
	return _player.take_hazard_damage(arena_to_world(arena_uv))


## Moves a resting Wisp to the wall point nearest [param arena_uv]; false while it cannot move.
func place_player(arena_uv: Vector2) -> bool:
	return _player.place_at_edge(arena_to_world(arena_uv))


## Turns player steering on or off (off while a demonstration drives the Wisp).
func set_player_input_enabled(enabled: bool) -> void:
	_player.set_input_enabled(enabled)


## Drops the Wisp's gesture in progress and its aim preview (a host modal such as the skip confirm).
func cancel_player_aim() -> void:
	_player.cancel_active_aim()


## Whether the Wisp rests at an edge, ready for a new dash.
func is_player_ready() -> bool:
	return _player.state in [WispPlayer.State.WAITING_AT_EDGE, WispPlayer.State.AIMING]


## Whether the Wisp is in its dash windup or flight.
func is_player_dashing() -> bool:
	return _player.state == WispPlayer.State.DASHING or _player.state == WispPlayer.State.WINDUP


## The Wisp's screen position.
func get_player_position() -> Vector2:
	return _player.global_position


## Shows the aim arrow for a demonstrated drag of [param drag_vector].
func demo_aim(drag_vector: Vector2) -> void:
	_player.preview_aim(drag_vector)


## Releases a demonstrated swipe of [param drag_vector] through the real Wisp.
func demo_swipe(drag_vector: Vector2) -> void:
	_player.perform_swipe(drag_vector)


## Drops one Rift Points shard at [param world_position].
func spawn_scripted_shard(world_position: Vector2) -> void:
	_spawn_rp_pickup(world_position)


## Flies every floor shard to the Wisp now.
func sweep_shards() -> void:
	_sweep_floor_shards()


## Screen rect of a HUD element to point at: `&"health"`, `&"xp"` or `&"rush"`; empty otherwise.
func get_hud_rect(element: StringName) -> Rect2:
	match element:
		&"health":
			return _health_row.get_global_rect()
		&"xp":
			return _xp_bar.get_global_rect().merge(_run_level_label.get_global_rect())
		&"rush":
			return _rush_row.get_global_rect()
	return Rect2()


## HUD safe margins in screen px (left, top, right, bottom), so a host overlay lines up with the HUD.
func get_safe_margins() -> Vector4:
	return _get_safe_margins()


## Shows a HUD callout (the success beat of a lesson); [param emphasis] scales it.
func show_callout(text: String, emphasis: float = 1.0) -> void:
	_show_callout(text, emphasis)


## The lesson's calm moment: banked upgrade cards slide up once the Wisp rests with no combo running
## (a scripted arena has no other calm moments). One request opens the tray at most once.
func request_upgrade_calm_moment() -> void:
	_scripted_upgrade_calm_requested = true


## Whether a lesson calm moment is still waiting to open the tray.
func has_upgrade_calm_request() -> bool:
	return _scripted_upgrade_calm_requested


## Level-ups banked and still spendable.
func get_banked_upgrades() -> int:
	return _run_progression.get_banked_levels()


## Whether the upgrade card tray is up (sliding in or resting).
func is_upgrade_tray_open() -> bool:
	return _upgrade_tray.is_open()


## Whether the tray rests fully up and accepts a pick (the tutorial hand taps then).
func is_upgrade_tray_settled() -> bool:
	return _upgrade_tray.is_settled()


## Screen rect of upgrade card [param index] while the tray is up; empty otherwise.
func get_upgrade_card_rect(index: int) -> Rect2:
	return _upgrade_tray.get_card_rect(index)


## Picks upgrade card [param index] as a tap would (the tutorial demo); false when refused.
func choose_upgrade_card(index: int) -> bool:
	return _upgrade_tray.choose_index(index)


## Lifts the upgrade tray [param lift] design px above the bottom safe margin (a host caption band).
func set_upgrade_tray_lift(lift: float) -> void:
	_upgrade_tray_lift = maxf(0.0, lift)
	if is_node_ready():
		_layout_safe_hud()


## Handles Android back and Escape: closes the topmost overlay, otherwise toggles pause.
## Always returns true because an active run consumes back presses.
func handle_back() -> bool:
	if _run_over:
		return true
	if _confirm_overlay.visible:
		_close_confirm()
	elif is_instance_valid(_settings_overlay):
		if not _settings_overlay.handle_back():
			_close_settings_overlay()
	else:
		_set_paused(not get_tree().paused)
	return true


## Adds screen-shake trauma (0..1); the offset grows with trauma², so small events stay subtle.
func add_trauma(amount: float) -> void:
	if _shake_strength <= 0.0:
		return
	_trauma = clampf(_trauma + amount, 0.0, 1.0)


## Returns the current screen-shake trauma (0..1).
func get_trauma() -> float:
	return _trauma


## Returns the effective shake multiplier from the Screen Shake and Reduced Motion settings.
func get_shake_strength() -> float:
	return _shake_strength


## Returns whether leaving now would discard meaningful progress (Restart/Home then confirm).
func is_run_meaningful() -> bool:
	return not _run_over and (_score > 0 or _total_kills > 0 or _current_wave > 1)


func _notification(what: int) -> void:
	if (
		(what == NOTIFICATION_APPLICATION_FOCUS_OUT or what == NOTIFICATION_APPLICATION_PAUSED)
		and auto_pause_on_focus_loss
		and not _scripted
		and not _start_held
		and is_node_ready()
		and not _run_over
		and not get_tree().paused
	):
		_set_paused(true)


func _exit_tree() -> void:
	_end_rush(false)
	_reset_view_effects()
	SoundFx.set_interrupted(false)


func _layout_for_viewport() -> void:
	_arena_rect = _compute_arena_rect()
	for backdrop: Control in [_background, _ambience, _world_shade]:
		backdrop.offset_left = -BACKGROUND_OVERSCAN
		backdrop.offset_top = -BACKGROUND_OVERSCAN
		backdrop.offset_right = BACKGROUND_OVERSCAN
		backdrop.offset_bottom = BACKGROUND_OVERSCAN
	# The rect stays the design-pixel scale and the distribution domain; the polygon is the wall.
	_player.set_arena_rect(_arena_rect)
	_arena_polygon = _compute_arena_polygon()
	_landing_polygon = DashGeometry.inset_polygon(
		_arena_polygon, _player.get_collision_radius() * LANDING_INSET
	)
	_player.set_arena_polygon(_landing_polygon)
	for child: Node in _enemy_layer.get_children():
		if child is EnemyActor:
			var enemy := child as EnemyActor
			enemy.set_arena_rect(_arena_rect)
			enemy.set_arena_polygon(_arena_polygon)
	for child: Node in _hazard_layer.get_children():
		if child is HazardActor:
			(child as HazardActor).set_viewport_width(_arena_rect.size.x)
	if is_instance_valid(_boss):
		_boss.set_arena_rect(_arena_rect)
		_boss.set_arena_polygon(_arena_polygon)
	_layout_portals()
	_update_pickup_attraction()
	_layout_safe_hud()


func _layout_safe_hud() -> void:
	# Header (board panel 2): form ring + lives/Rift Points top-left, score plate centred, pause
	# top-right; wave, slim XP bar and soul level stacked under the plate; boss health below.
	var margins: Vector4 = _get_safe_margins()
	var top: float = margins.y
	_health_row.offset_left = margins.x
	_health_row.offset_top = top
	_health_row.offset_right = margins.x + HUD_RING_SIZE + 190.0
	_health_row.offset_bottom = top + HUD_RING_SIZE
	var plate_height: float = _score_plate.get_combined_minimum_size().y
	_score_plate.offset_top = top + HUD_PLATE_TOP
	_score_plate.offset_bottom = top + HUD_PLATE_TOP + plate_height
	_wave_label.offset_top = top + HUD_WAVE_TOP
	_wave_label.offset_bottom = top + HUD_WAVE_TOP + 38.0
	_xp_bar.offset_top = top + HUD_XP_TOP
	_xp_bar.offset_bottom = top + HUD_XP_TOP + 18.0
	_run_level_label.offset_top = top + HUD_LEVEL_TOP
	_run_level_label.offset_bottom = top + HUD_LEVEL_TOP + 34.0
	_rush_row.offset_top = top + HUD_RUSH_TOP
	_rush_row.offset_bottom = top + HUD_RUSH_TOP + HUD_RUSH_HEIGHT
	_boss_hud.offset_top = top + HUD_BOSS_TOP
	_boss_hud.offset_bottom = top + HUD_BOSS_TOP + _boss_hud.get_combined_minimum_size().y
	_combo_label.offset_top = top + HUD_CALLOUT_TOP
	_combo_label.offset_bottom = top + HUD_CALLOUT_TOP + 80.0
	_focus_label.offset_top = top + HUD_FOCUS_TOP
	_focus_label.offset_bottom = top + HUD_FOCUS_TOP + 44.0
	_pause_button.offset_left = -(margins.z + HUD_PAUSE_SIZE)
	_pause_button.offset_top = top
	_pause_button.offset_right = -margins.z
	_pause_button.offset_bottom = top + HUD_PAUSE_SIZE
	var upgrade_top: float = top + HUD_PAUSE_SIZE + HUD_UPGRADE_BUTTON_GAP
	_upgrade_button.offset_left = -(margins.z + HUD_UPGRADE_BUTTON_SIZE)
	_upgrade_button.offset_top = upgrade_top
	_upgrade_button.offset_right = -margins.z
	_upgrade_button.offset_bottom = upgrade_top + HUD_UPGRADE_BUTTON_SIZE
	_instruction_label.offset_top = -(margins.w + 150.0)
	_instruction_label.offset_bottom = -(margins.w + 96.0)
	_upgrade_tray.set_bottom_inset(
		margins.w + _upgrade_tray_lift + size.y * _run_progression.tuning.tray_raise_share
	)


## Maps the painted floor of the cover-scaled backdrop into screen space and keeps it on screen.
## Screen-space rectangle the cover-scaled backdrop image occupies.
##
## Shared by the legacy floor rect and the Rift floor polygon so both are mapped through exactly
## the same transform; if they diverged, the wall and the art would disagree.
func _backdrop_image_rect() -> Rect2:
	var view: Rect2 = get_viewport_rect()
	var texture: Texture2D = _background.texture
	if texture == null or texture.get_size().x <= 0.0 or texture.get_size().y <= 0.0:
		return view
	var texture_size: Vector2 = texture.get_size()
	var cover: float = maxf(view.size.x / texture_size.x, view.size.y / texture_size.y)
	var image_size: Vector2 = texture_size * cover
	return Rect2(view.position + (view.size - image_size) * 0.5, image_size)


## Moves a point that should be on the floor onto the painted floor, [param margin] px clear.
##
## Formations, hazards and portals are authored in a unit square and mapped over the bounding
## rect, which is correct as a distribution domain but puts corner positions in the lava on an oval
## arena. Every placement routes through here so the rect stays the domain and the polygon decides
## legality. A no-op on the legacy rectangle.
func _place_on_floor(point: Vector2, margin: float = 0.0) -> Vector2:
	if _arena_polygon.size() < 3:
		return point
	if DashGeometry.is_inside_polygon(point, _arena_polygon):
		var boundary: Vector2 = DashGeometry.nearest_polygon_point(point, _arena_polygon)
		if point.distance_to(boundary) >= margin:
			return point
	return DashGeometry.clamp_to_polygon(point, _arena_polygon, margin)


## Clearance kept between a placed enemy and the painted wall, in screen pixels.
func _floor_margin() -> float:
	return maxf(12.0, _player.get_collision_radius() * 1.2)


## Points on the wall the Wisp may reform at after a hit, before threat scoring picks one.
##
## On a polygon floor these are sampled ON the landing polygon. Scoring rectangle points and then
## projecting the winner onto the polygon would move it somewhere the clearance search never
## measured - potentially right next to the threat it was chosen to avoid.
func _get_reform_candidates() -> Array[Vector2]:
	var candidates: Array[Vector2] = []
	if _landing_polygon.size() >= 3:
		var count: int = _landing_polygon.size()
		for index: int in count:
			var start: Vector2 = _landing_polygon[index]
			var end: Vector2 = _landing_polygon[(index + 1) % count]
			candidates.append(start)
			candidates.append((start + end) * 0.5)
		return candidates
	var bounds: Rect2 = _arena_rect.grow(-_player.get_collision_radius() * LANDING_INSET)
	for progress: float in [0.14, 0.5, 0.86]:
		candidates.append(Vector2(lerpf(bounds.position.x, bounds.end.x, progress), bounds.position.y))
		candidates.append(Vector2(lerpf(bounds.position.x, bounds.end.x, progress), bounds.end.y))
		candidates.append(Vector2(bounds.position.x, lerpf(bounds.position.y, bounds.end.y, progress)))
		candidates.append(Vector2(bounds.end.x, lerpf(bounds.position.y, bounds.end.y, progress)))
	return candidates


## The arena's floor (a Rift's painted floor or the Endless template) in screen space, contracted by
## the current shrink.
func _compute_arena_polygon() -> PackedVector2Array:
	var floor_uv: PackedVector2Array = _arena_rules.get_floor_polygon()
	if floor_uv.size() < 3:
		return PackedVector2Array()
	var polygon: PackedVector2Array = DashGeometry.polygon_from_uv(floor_uv, _backdrop_image_rect())
	if is_equal_approx(_arena_shrink, 1.0):
		return polygon
	# Ember Hollow's floor burns away; scale about the centroid so the shape is preserved.
	var centre: Vector2 = DashGeometry.polygon_centroid(polygon)
	var scaled := PackedVector2Array()
	for point: Vector2 in polygon:
		scaled.append(centre + (point - centre) * _arena_shrink)
	return scaled


func _compute_arena_rect() -> Rect2:
	var view: Rect2 = get_viewport_rect()
	var texture: Texture2D = _background.texture
	var rect: Rect2 = view
	if texture != null and texture.get_size().x > 0.0 and texture.get_size().y > 0.0:
		var image: Rect2 = _backdrop_image_rect()
		rect = Rect2(
			image.position + ARENA_FLOOR_UV.position * image.size,
			ARENA_FLOOR_UV.size * image.size,
		)
	# Ember Hollow's floor burns away: contract around the centre, before the safety floor below.
	if not is_equal_approx(_arena_shrink, 1.0):
		var centre: Vector2 = rect.get_center()
		rect.size *= _arena_shrink
		rect.position = centre - rect.size * 0.5
	var minimum: Vector2 = view.size * ARENA_MIN_VIEWPORT_FRACTION
	rect.size = rect.size.max(minimum)
	rect.position = rect.position.clamp(view.position, view.end - rect.size)
	return rect.intersection(view)


func _get_safe_margins() -> Vector4:
	# HUD margins live in screen space, not in the inset playfield.
	var view_size: Vector2 = get_viewport_rect().size
	var base_margin: float = clampf(view_size.x * 0.025, 18.0, 36.0)
	var result := Vector4(base_margin, base_margin, base_margin, base_margin)
	if OS.get_name() != "Android" and OS.get_name() != "iOS":
		return result
	var safe_area: Rect2i = DisplayServer.get_display_safe_area()
	var window_size: Vector2i = DisplayServer.window_get_size()
	if safe_area.size.x <= 0 or safe_area.size.y <= 0 or window_size.x <= 0 or window_size.y <= 0:
		return result
	var scale_factor := Vector2(
		view_size.x / float(window_size.x),
		view_size.y / float(window_size.y),
	)
	result.x = maxf(base_margin, float(safe_area.position.x) * scale_factor.x + base_margin)
	result.y = maxf(base_margin, float(safe_area.position.y) * scale_factor.y + base_margin)
	result.z = maxf(
		base_margin,
		float(window_size.x - safe_area.end.x) * scale_factor.x + base_margin,
	)
	result.w = maxf(
		base_margin,
		float(window_size.y - safe_area.end.y) * scale_factor.y + base_margin,
	)
	return result


func _begin_run() -> void:
	if not is_inside_tree():
		return
	if _start_held:
		_start_pending = true
		return
	if _scripted:
		# The Tutorial screen drives this arena: no waves, no pause button, its own instructions.
		_instruction_label.visible = false
		_pause_button.visible = false
		_wave_label.text = _hud_run_prefix()
		print("[GameWorld] scripted arena ready")
	else:
		_start_waves()
	_refresh_rush_hud()


func _start_waves() -> void:
	if _waves_started or _run_over:
		return
	_waves_started = true
	# Endless rules spawn continuously (never a quiet wait); story Rift levels keep timed waves.
	var endless_rules := _arena_rules as EndlessArenaRules
	var endless_tuning: EndlessTuning = endless_rules.get_tuning() if endless_rules != null else null
	_wave_director.set_continuous(
		endless_tuning.refill_live_enemies if endless_tuning != null else -1
	)
	_wave_director.start(run_seed)


func _update_waves_start(delta: float) -> void:
	if _waves_start_remaining < 0.0:
		return
	_waves_start_remaining -= delta
	if _waves_start_remaining <= 0.0:
		_waves_start_remaining = -1.0
		_start_waves()


func _update_post_boss(delta: float) -> void:
	if _post_boss_remaining < 0.0:
		return
	_post_boss_remaining -= delta
	if _post_boss_remaining <= 0.0:
		_post_boss_remaining = -1.0
		_set_world_shade(SHADE_CALM)
		_wave_director.resume_after_boss()
		_mark_calm_moment(&"boss_defeated")


func _update_boss_target() -> void:
	if is_instance_valid(_boss):
		_boss.set_target_position(_player.global_position)


func _on_wave_started(wave: int, threat_budget: int) -> void:
	_current_wave = wave
	_sweep_floor_shards()
	_update_music_state()
	_clear_hazards()
	if wave >= _boss_wave_interval and wave % _boss_wave_interval == 0:
		_wave_director.suspend_for_boss()
		_boss_pending = true
		_wave_label.text = "%s  •  REAPER APPROACHING" % _hud_run_prefix()
		_show_callout("THE REAPER APPROACHES")
		return
	_update_rift_rules(wave)
	if _mode == RunProfile.MODE_STORY:
		_wave_label.text = "LEVEL %d  •  WAVE %d / %d" % [_rift_level, wave, _get_waves_per_level()]
	else:
		_wave_label.text = "%s  •  WAVE %02d  •  THREAT %02d" % [
			_hud_run_prefix(), wave, threat_budget,
		]
	var roster_name: String = _arena_rules.get_roster_name(wave, run_seed)
	if not roster_name.is_empty():
		_show_callout("%s WAVE" % roster_name.to_upper())
	elif wave > 1:
		_show_callout("RIFT %02d" % wave)
	_mark_calm_moment(&"wave_start")


func _start_boss_encounter(health_override: int = 0) -> void:
	if is_instance_valid(_boss) or _run_over:
		return
	_boss_pending = false
	# Upgrade cards never stay up into a boss; a banked level waits for the boss to fall.
	_close_upgrade_tray(&"boss")
	_sweep_floor_shards()
	_clear_enemies()
	_clear_hazards()
	_boss = REAPER_SCENE.instantiate() as ReaperBoss
	var variant: BossData = _get_boss_variant()
	_boss_layer.add_child(_boss)
	_boss.configure_variant(variant)
	_boss.health_changed.connect(_on_reaper_health_changed)
	_boss.phase_changed.connect(_on_reaper_phase_changed)
	_boss.summon_requested.connect(_on_reaper_summon_requested)
	_boss.defeated.connect(_on_reaper_defeated)
	_boss.set_arena_polygon(_arena_polygon)
	_boss.configure(
		_arena_rect,
		_player.global_position,
		_bosses_defeated,
		run_seed + _current_wave * 101,
		health_override,
	)
	_set_world_shade(SHADE_BOSS)
	_boss_hud.visible = true
	_boss_warning.text = variant.display_name
	_show_callout(variant.display_name)
	SoundFx.play(&"reaper_appear")
	_update_music_state()


func _on_reaper_health_changed(current_health: int, maximum_health: int) -> void:
	if _boss_hud.visible and float(current_health) < _boss_bar.value:
		SoundFx.play(&"reaper_hit")
		_add_rush(feel_tuning.per_boss_hit)
		if current_health <= 0:
			add_trauma(1.0)
			Haptics.pulse(Haptics.HEAVY_MS * 2, 1.0)
			# A boss's killing blow always gets the finisher, before any victory beat.
			_play_finisher(&"boss")
		else:
			add_trauma(0.35)
			Haptics.pulse(Haptics.MEDIUM_MS, 0.6)
	_boss_bar.max_value = maxf(1.0, float(maximum_health))
	_boss_bar.value = float(current_health)


func _on_reaper_phase_changed(next_phase: int) -> void:
	var phase_name: String = "SCYTHE SWEEP"
	if next_phase == ReaperBoss.Phase.TELEPORT_HUNT:
		phase_name = "TELEPORT HUNT"
	elif next_phase == ReaperBoss.Phase.DEATH_CORRIDORS:
		phase_name = "DEATH CORRIDORS"
	_boss_phase_label.text = "PHASE %d  •  %s" % [next_phase, phase_name]
	if next_phase > 1:
		_show_callout("PHASE %d  •  %s" % [next_phase, phase_name])


func _on_reaper_summon_requested(world_positions: PackedVector2Array) -> void:
	for world_position: Vector2 in world_positions:
		var enemy: EnemyActor = _spawn_enemy(&"soul_wisp", world_position, true)
		enemy.set_last_edge_position(_player.global_position)


func _on_reaper_defeated(
	_world_position: Vector2,
	score_reward: int,
	rp_reward: int,
	) -> void:
	var victory_duration: float = 1.0
	var experience_reward: int = 0
	if is_instance_valid(_boss):
		victory_duration = _boss.tuning.victory_duration
		experience_reward = _boss.tuning.experience_reward
	_boss = null
	_bosses_defeated += 1
	_sweep_floor_shards()
	_update_music_state()
	_score += _apply_velocity_score_bonus(roundi(float(score_reward) * _rift_reward_multiplier))
	_score_label.text = "%06d" % _score
	_award_rift_points(roundi(float(rp_reward) * _rift_reward_multiplier))
	_grant_experience(experience_reward)
	_clear_enemies()
	_clear_hazards()
	_boss_hud.visible = false
	_set_world_shade(SHADE_VICTORY)
	_player.play_victory(victory_duration)
	_show_callout("REAPER VANQUISHED  +%d" % score_reward)
	print("[GameWorld] Reaper defeated | count=%d" % _bosses_defeated)
	if _is_final_boss_wave():
		_begin_level_victory(victory_duration)
		return
	boss_defeated.emit()
	if _scripted:
		_wave_label.text = "%s  •  BOSS DEFEATED" % _hud_run_prefix()
	elif _mode != RunProfile.MODE_STORY:
		# Endless rules never end on a boss: each victory starts a harder cycle.
		_apply_arena_difficulty()
		_wave_label.text = "CYCLE %d CLEARED  •  RIFT DEEPENS" % _bosses_defeated
	else:
		# Boss rush's mid-level boss: the level carries on.
		_wave_label.text = "LEVEL %d  •  BOSS DEFEATED" % _rift_level
	_post_boss_remaining = victory_duration


## Waves in one story level; the boss on the last one is the level's final boss.
func _get_waves_per_level() -> int:
	var waves: int = _arena_rules.get_level_waves()
	return waves if waves > 0 else _boss_wave_interval


## Whether the boss of the current wave is a story level's final boss (boss rush's mid boss is not).
func _is_final_boss_wave() -> bool:
	return _mode == RunProfile.MODE_STORY and _arena_rules.is_final_boss_wave(_current_wave)


## HUD prefix naming the run: the story level, Endless or the daily run.
func _hud_run_prefix() -> String:
	match _mode:
		RunProfile.MODE_STORY:
			return "LEVEL %d" % _rift_level
		RunProfile.MODE_ENDLESS:
			return "ENDLESS"
		RunProfile.MODE_TUTORIAL:
			return "TUTORIAL"
	return "DAILY"


## Clears the story level: the run is over at once (no input, pause or contact), and the summary is
## emitted through `run_ended` after the Wisp's victory beat.
func _begin_level_victory(victory_duration: float) -> void:
	_level_cleared = true
	_run_over = true
	_clear_aim_preview()
	_boss_pending = false
	_waves_start_remaining = -1.0
	_post_boss_remaining = -1.0
	_focus_remaining = 0.0
	_set_world_speed(1.0)
	_close_upgrade_tray(&"run_end", true)
	# Banked but unpicked level-ups are lost with the run.
	_refresh_upgrade_button()
	_clear_time_scale_requests()
	_end_rush(false)
	_player.cancel_active_aim()
	_pause_button.disabled = true
	_wave_label.text = "LEVEL %d CLEARED" % _rift_level
	_update_music_state()
	print("[GameWorld] level cleared | rift=%s level=%d" % [
		_arena_rules.get_rift_id(), _rift_level,
	])
	get_tree().create_timer(maxf(0.1, victory_duration)).timeout.connect(_finish_level_victory)


func _finish_level_victory() -> void:
	if not is_inside_tree():
		return
	SoundFx.music_state(0.0, false)
	_emit_run_end()


func _on_formation_requested(
		formation: FormationData,
		mirrored: bool,
		quarter_turns: int,
	) -> void:
	_clear_hazards()
	var positions: PackedVector2Array = formation.get_transformed_positions(
		mirrored,
		quarter_turns,
	)
	for index: int in formation.enemy_kinds.size():
		var world_position: Vector2 = _arena_rect.position + _arena_rect.size * positions[index]
		var placed: Vector2 = _place_on_floor(
			_ensure_spawn_clear(world_position), _floor_margin()
		)
		_spawn_enemy(formation.enemy_kinds[index], placed, true)
	if not formation.hazard_kind.is_empty():
		var hazard_normalized: Vector2 = formation.get_transformed_hazard_position(
			mirrored,
			quarter_turns,
		)
		_spawn_hazard(
			formation.hazard_kind,
			_place_on_floor(
				_arena_rect.position + _arena_rect.size * hazard_normalized, _floor_margin() * 2.0
			),
		)


func _ensure_spawn_clear(world_position: Vector2) -> Vector2:
	var minimum_distance: float = (
		_wave_director.tuning.safe_spawn_distance * minf(_arena_rect.size.x, _arena_rect.size.y)
	)
	if world_position.distance_to(_player.global_position) >= minimum_distance:
		return world_position
	var opposite: Vector2 = _arena_rect.position + _arena_rect.size - (
		world_position - _arena_rect.position
	)
	return _place_on_floor(opposite, _floor_margin())


## Spawns one enemy, optionally remapped onto the arena's roster for the current wave.
##
## `apply_rift_roster` must be false for split children: the roster remap is what turns a harmless
## `split_kind` into a splitter. In Ember Hollow `soul_wisp` maps to `cinder_shade`, whose own
## `split_kind` is `soul_wisp` — remapping a child there spawns two more splitters per death, which
## is an unbounded chain reaction.
func _spawn_enemy(
		kind: StringName,
		world_position: Vector2,
		movement_enabled: bool,
		apply_rift_roster: bool = true,
	) -> EnemyActor:
	var resolved: StringName = kind
	if apply_rift_roster:
		resolved = _arena_rules.substitute_enemy(kind, _current_wave, run_seed)
	assert(ENEMY_SCENES.has(resolved), "Unknown enemy kind: %s" % resolved)
	var scene := ENEMY_SCENES[resolved] as PackedScene
	var enemy := scene.instantiate() as EnemyActor
	enemy.movement_enabled = movement_enabled
	_enemy_layer.add_child(enemy)
	enemy.global_position = world_position
	enemy.set_arena_rect(_arena_rect)
	enemy.set_arena_polygon(_arena_polygon)
	enemy.set_target_position(_player.global_position)
	enemy.set_last_edge_position(_player.global_position)
	enemy.set_world_speed(0.32 if _focus_remaining > 0.0 else 1.0)
	enemy.set_speed_scale(_arena_rules.get_enemy_speed_scale(_bosses_defeated))
	enemy.killed.connect(_on_enemy_killed)
	_remaining_live_enemies += 1
	return enemy


## Spawns a splitter's children around its death point, clamped inside the playfield.
##
## Children are spawned with the Rift roster remap DISABLED, so `split_kind` is taken literally and
## a split can never produce another splitter. `test_rift_enemies.gd` also asserts that no Rift maps
## a `split_kind` onto a splitting enemy, so the invariant is checked from both directions.
func _spawn_split_children(enemy: EnemyActor, world_position: Vector2) -> void:
	if enemy == null or enemy.tuning == null:
		return
	var kind: StringName = enemy.tuning.split_kind
	var count: int = enemy.tuning.split_count
	if kind.is_empty() or count <= 0 or not ENEMY_SCENES.has(kind):
		return
	if _run_over or _boss_pending:
		return
	# Safety net independent of the invariant above, so a data mistake degrades instead of hanging.
	if _remaining_live_enemies >= MAX_LIVE_ENEMIES:
		return
	var spread: float = SPLIT_SPREAD * (_arena_rect.size.x / 1080.0)
	for index: int in count:
		var angle: float = TAU * (float(index) / float(count)) + randf() * 0.4
		var offset: Vector2 = Vector2.RIGHT.rotated(angle) * spread
		var spawn_point: Vector2 = _arena_rect.position + Vector2(
			clampf(world_position.x + offset.x - _arena_rect.position.x, 0.0, _arena_rect.size.x),
			clampf(world_position.y + offset.y - _arena_rect.position.y, 0.0, _arena_rect.size.y),
		)
		spawn_point = _place_on_floor(spawn_point, _floor_margin())
		var child: EnemyActor = _spawn_enemy(kind, spawn_point, true, false)
		child.scale = Vector2.ONE * enemy.tuning.split_scale


func _spawn_hazard(kind: StringName, world_position: Vector2) -> HazardActor:
	assert(HAZARD_SCENES.has(kind), "Unknown hazard kind: %s" % kind)
	var scene := HAZARD_SCENES[kind] as PackedScene
	var hazard := scene.instantiate() as HazardActor
	_hazard_layer.add_child(hazard)
	hazard.global_position = world_position
	hazard.set_viewport_width(_arena_rect.size.x)
	hazard.set_world_speed(0.32 if _focus_remaining > 0.0 else 1.0)
	return hazard


func _clear_enemies() -> void:
	for child: Node in _enemy_layer.get_children():
		if child is EnemyActor:
			child.queue_free()
	_remaining_live_enemies = 0


func _clear_hazards() -> void:
	for child: Node in _hazard_layer.get_children():
		if child is HazardActor:
			child.queue_free()


func _update_enemy_targets() -> void:
	for child: Node in _enemy_layer.get_children():
		if child is EnemyActor:
			(child as EnemyActor).set_target_position(_player.global_position)


func _check_world_contacts() -> void:
	if _player.is_vulnerable():
		for child: Node in _enemy_layer.get_children():
			if not child is EnemyActor:
				continue
			var enemy := child as EnemyActor
			if not enemy.is_contact_active():
				continue
			var contact_distance: float = (
				_player.get_collision_radius() + enemy.get_collision_radius()
			)
			if (
				_player.global_position.distance_squared_to(enemy.global_position)
				<= contact_distance ** 2
				and _player.take_contact_damage(_find_safest_edge_position())
			):
				print("[GameWorld] enemy contact | health=%d" % _player.get_current_health())
				return
	for child: Node in _hazard_layer.get_children():
		if not child is HazardActor:
			continue
		for circle: Vector3 in (child as HazardActor).get_dangerous_circles():
			var centre := Vector2(circle.x, circle.y)
			var radius: float = circle.z + _player.get_collision_radius()
			if (
				_player.global_position.distance_squared_to(centre) <= radius ** 2
				and _player.take_hazard_damage(_find_safest_edge_position())
			):
				print("[GameWorld] hazard contact | health=%d" % _player.get_current_health())
				return
	if is_instance_valid(_boss):
		for circle: Vector3 in _boss.get_dangerous_circles():
			var centre := Vector2(circle.x, circle.y)
			var radius: float = circle.z + _player.get_collision_radius()
			if (
				_player.global_position.distance_squared_to(centre) <= radius ** 2
				and _player.take_hazard_damage(_find_safest_edge_position())
			):
				print("[GameWorld] Reaper attack | health=%d" % _player.get_current_health())
				return
		for lane: PackedVector2Array in _boss.get_dangerous_lanes():
			if (
				DashGeometry.distance_to_segment(_player.global_position, lane[0], lane[1])
				<= _boss.get_lane_radius() + _player.get_collision_radius()
				and _player.take_hazard_damage(_find_safest_edge_position())
			):
				print("[GameWorld] Reaper corridor | health=%d" % _player.get_current_health())
				return


func _find_safest_edge_position() -> Vector2:
	var candidates: Array[Vector2] = _get_reform_candidates()
	var safest_position: Vector2 = candidates[0]
	var safest_clearance_squared: float = -1.0
	for candidate: Vector2 in candidates:
		var nearest_threat_squared: float = INF
		for child: Node in _enemy_layer.get_children():
			if child is EnemyActor and (child as EnemyActor).is_contact_active():
				nearest_threat_squared = minf(
					nearest_threat_squared,
					candidate.distance_squared_to((child as EnemyActor).global_position),
				)
		for child: Node in _hazard_layer.get_children():
			if not child is HazardActor:
				continue
			for circle: Vector3 in (child as HazardActor).get_dangerous_circles():
				nearest_threat_squared = minf(
					nearest_threat_squared,
					candidate.distance_squared_to(Vector2(circle.x, circle.y)),
				)
		if is_instance_valid(_boss):
			for circle: Vector3 in _boss.get_dangerous_circles():
				nearest_threat_squared = minf(
					nearest_threat_squared,
					candidate.distance_squared_to(Vector2(circle.x, circle.y)),
				)
			for lane: PackedVector2Array in _boss.get_dangerous_lanes():
				var lane_distance: float = DashGeometry.distance_to_segment(
					candidate,
					lane[0],
					lane[1],
				)
				nearest_threat_squared = minf(
					nearest_threat_squared,
					lane_distance * lane_distance,
				)
		if nearest_threat_squared > safest_clearance_squared:
			safest_clearance_squared = nearest_threat_squared
			safest_position = candidate
	return safest_position


func _update_combo(delta: float) -> void:
	# RUSH freezes the combo timer.
	if _combo <= 0 or is_rush_active():
		return
	_combo_remaining -= delta
	if _combo_remaining <= 0.0:
		_combo = 0
		_combo_label.visible = false
		_update_music_state()


func _update_focus(delta: float) -> void:
	if _focus_remaining <= 0.0:
		return
	_focus_remaining -= delta
	if _focus_remaining <= 0.0:
		_set_world_speed(1.0)
		_focus_label.visible = false


func _set_world_speed(multiplier: float) -> void:
	for child: Node in _enemy_layer.get_children():
		if child is EnemyActor:
			(child as EnemyActor).set_world_speed(multiplier)
	for child: Node in _hazard_layer.get_children():
		if child is HazardActor:
			(child as HazardActor).set_world_speed(multiplier)


func _on_viewport_size_changed() -> void:
	_layout_for_viewport()


func _on_player_dash_started(direction: Vector2, dash_id: int) -> void:
	# Keep playing: a swipe on the arena sends the cards away and the level stays banked.
	_close_upgrade_tray(&"swipe")
	_dash_origin = _player.global_position
	_dash_direction = direction.normalized() if not direction.is_zero_approx() else Vector2.RIGHT
	# Each chain momentum step raises the dash a little (GDD §5.6).
	SoundFx.play(
		&"dash", 1.0 + float(_player.get_momentum_steps()) * feel_tuning.dash_pitch_per_step
	)
	var from_redirect: bool = _redirect_pending
	_redirect_pending = false
	if from_redirect:
		Haptics.pulse(REDIRECT_HAPTIC_MS, REDIRECT_HAPTIC_AMPLITUDE)
	else:
		Haptics.pulse(LAUNCH_HAPTIC_MS, LAUNCH_HAPTIC_AMPLITUDE)
	_play_dash_trail()
	if is_instance_valid(_boss):
		_boss.skip_intro()
	# Only a launch off a wall counts as a rapid ricochet. A redirect never touches a wall, so without
	# this guard every mid-air leg within the window scored it again and inflated the Trials metric.
	if not from_redirect and _last_wall_impact_msec >= 0:
		var elapsed_msec: int = Time.get_ticks_msec() - _last_wall_impact_msec
		if elapsed_msec <= RAPID_REDIRECT_WINDOW_MSEC:
			_rapid_redirect_dashes[dash_id] = true
	var link_level: int = _run_progression.get_mutation_level(&"soul_link")
	if link_level > 0:
		_link_remaining_by_event[dash_id] = link_level
	dash_launched.emit(from_redirect)
	if _instruction_label.visible and _instruction_label.modulate.a > 0.0:
		var instruction_tween: Tween = create_tween()
		instruction_tween.tween_property(_instruction_label, "modulate:a", 0.0, 0.45)


## A swipe turned the dash mid-flight: score the leg that ended without touching a wall.
##
## Without this the first leg's kills would sit in `_kills_by_dash` forever - never counted toward a
## multi-kill, never cleared - because only a wall impact resolves a dash.
func _on_player_dash_redirected(_world_position: Vector2, previous_dash_id: int) -> void:
	_redirect_pending = true
	dash_resolved.emit(_resolve_completed_dash(previous_dash_id, true), &"redirect")


func _on_player_dash_segment_swept(
		segment_start: Vector2,
		segment_end: Vector2,
		dash_id: int,
		corridor_radius: float,
	) -> void:
	if _run_over:
		return
	# Track the TRUE travel direction from the swept motion itself. Redirects and windup retargets
	# change heading without a new `dash_started`, and slice/trail effects orient from this.
	var travel: Vector2 = segment_end - segment_start
	if travel.length_squared() > 0.01:
		_dash_direction = travel.normalized()
	# Portals consume the rest of this segment; the exit emits its own segments from next frame.
	if _try_portal_transit(segment_start, segment_end, dash_id):
		return
	var hazard_event: Dictionary = _find_dash_hazard_event(segment_start, segment_end)
	var hit_end: Vector2 = hazard_event.get(&"point", segment_end)
	var cold_level: int = _run_progression.get_mutation_level(&"cold_wake")
	for child: Node in _enemy_layer.get_children():
		if not child is EnemyActor:
			continue
		var enemy := child as EnemyActor
		if cold_level > 0 and enemy.is_contact_active():
			var cold_distance: float = DashGeometry.distance_to_segment(
				enemy.global_position,
				segment_start,
				hit_end,
			)
			if cold_distance <= corridor_radius + enemy.get_collision_radius():
				enemy.apply_slow(
					_run_progression.tuning.cold_wake_base_duration
					+ float(cold_level - 1)
					* _run_progression.tuning.cold_wake_duration_per_level,
					_run_progression.tuning.cold_wake_speed,
				)
		enemy.try_dash_hit(
			segment_start,
			hit_end,
			corridor_radius,
			_player.dash_damage,
			dash_id,
		)
	for child: Node in _pickup_layer.get_children():
		if child is SoulShardPickup:
			(child as SoulShardPickup).try_dash_collect(segment_start, hit_end, corridor_radius)
	if is_instance_valid(_boss):
		_boss.try_dash_hit(
			segment_start,
			hit_end,
			corridor_radius,
			_player.dash_damage,
			dash_id,
		)
	if hazard_event.is_empty():
		return
	var event_kind: StringName = hazard_event[&"kind"]
	var event_point: Vector2 = hazard_event[&"point"]
	var event_normal: Vector2 = hazard_event[&"normal"]
	if event_kind == &"block":
		_player.interrupt_dash_at(event_point, event_normal)
	else:
		_player.take_hazard_damage(_find_safest_edge_position())


## The Wisp's aim preview changed: draw the path and light every enemy that dash would slice.
##
## Owner decision 2026-09-15. [param direction] and [param landing] are already resolved and
## aim-assisted by the Wisp. Enemies are counted exactly as combat hits them (see
## [method _scan_aim_targets]); inactive previews, a finished run or a paused tree clear everything.
func _on_player_aim_preview_changed(
		origin: Vector2,
		direction: Vector2,
		landing: Vector2,
		active: bool,
	) -> void:
	if not active or _run_over or not is_inside_tree() or get_tree().paused:
		_clear_aim_preview()
		return
	var stop: Vector2 = _aim_stop_point(origin, landing)
	var count: int = _scan_aim_targets(origin, stop, _player.get_dash_corridor_radius(), true)
	_aim_guide.show_path(
		origin + direction * _player.get_aim_line_start_distance(),
		stop,
		count,
		_arena_rect,
		_arena_rect.size.x / 1080.0 if _arena_rect.has_area() else 1.0,
	)


## Hides the aim path and unlights every enemy (release, cancel, damage, pause, run end).
func _clear_aim_preview() -> void:
	if is_instance_valid(_aim_guide):
		_aim_guide.clear()
	if not _aim_highlight_active or not is_node_ready():
		return
	_aim_highlight_active = false
	for child: Node in _enemy_layer.get_children():
		if child is EnemyActor:
			(child as EnemyActor).set_targeted(false)


## Aim-assist counter handed to the Wisp: regular enemies a dash [param origin]→[param landing]
## with [param corridor_radius] would slice, stopping at the first dash-blocking hazard or portal.
func _count_aim_targets(origin: Vector2, landing: Vector2, corridor_radius: float) -> int:
	if _run_over or not is_node_ready():
		return 0
	return _scan_aim_targets(origin, _aim_stop_point(origin, landing), corridor_radius, false)


## Counts (and, with [param highlight], lights) the enemies a dash [param origin]→[param stop]
## would hit, through the same `EnemyActor.would_dash_hit` test that `try_dash_hit` uses (Warden
## shield arc and Rift Spawn tether included). Runs per sampled direction.
func _scan_aim_targets(
		origin: Vector2,
		stop: Vector2,
		corridor_radius: float,
		highlight: bool,
	) -> int:
	var count: int = 0
	var still: bool = _reduced_motion
	# Index walk instead of get_children(): no array allocated per sampled direction.
	for index: int in _enemy_layer.get_child_count():
		var enemy := _enemy_layer.get_child(index) as EnemyActor
		if enemy == null:
			continue
		var lit: bool = enemy.would_dash_hit(origin, stop, corridor_radius)
		if lit:
			count += 1
		if highlight:
			enemy.set_targeted(lit, still)
	if highlight:
		_aim_highlight_active = count > 0
	return count


## Where a previewed dash [param origin]→[param landing] really stops: the landing, or the first
## dash-blocking hazard (same entry radius as combat) or portal mouth on the way.
##
## Damaging hazards (spikes, blade rings, boss attacks) are deliberately NOT stops here: they
## cycle and rotate during the dash's flight, so a snapshot would flicker and mislead; they carry
## their own amber telegraphs. Past a portal the exit leg is not previewed.
func _aim_stop_point(origin: Vector2, landing: Vector2) -> Vector2:
	var earliest_t: float = 1.0
	var player_radius: float = _player.get_collision_radius()
	for index: int in _hazard_layer.get_child_count():
		var hazard := _hazard_layer.get_child(index) as HazardActor
		if hazard == null or not hazard.blocks_dash():
			continue
		earliest_t = minf(earliest_t, _segment_circle_entry_t(
			origin, landing, hazard.global_position, hazard.get_blocking_radius() + player_radius
		))
	if _portals.size() == 2:
		var portal_radius: float = PORTAL_RADIUS * (_arena_rect.size.x / 1080.0)
		for portal: Sprite2D in _portals:
			if is_instance_valid(portal):
				earliest_t = minf(earliest_t, _segment_circle_entry_t(
					origin, landing, portal.global_position, portal_radius
				))
	return origin.lerp(landing, earliest_t)


func _find_dash_hazard_event(segment_start: Vector2, segment_end: Vector2) -> Dictionary:
	var earliest_t: float = INF
	var result: Dictionary = {}
	for child: Node in _hazard_layer.get_children():
		if not child is HazardActor:
			continue
		var hazard := child as HazardActor
		if hazard.blocks_dash():
			var block_radius: float = hazard.get_blocking_radius() + _player.get_collision_radius()
			var block_t: float = _segment_circle_entry_t(
				segment_start,
				segment_end,
				hazard.global_position,
				block_radius,
			)
			if block_t < earliest_t:
				earliest_t = block_t
				var point: Vector2 = segment_start.lerp(segment_end, block_t)
				result = {
					&"kind": &"block",
					&"point": point,
					&"normal": (point - hazard.global_position).normalized(),
				}
		for circle: Vector3 in hazard.get_dangerous_circles():
			var centre := Vector2(circle.x, circle.y)
			var danger_t: float = _segment_circle_entry_t(
				segment_start,
				segment_end,
				centre,
				circle.z + _player.get_collision_radius(),
			)
			if danger_t < earliest_t:
				earliest_t = danger_t
				var point: Vector2 = segment_start.lerp(segment_end, danger_t)
				result = {
					&"kind": &"damage",
					&"point": point,
					&"normal": (point - centre).normalized(),
				}
	if is_instance_valid(_boss):
		for circle: Vector3 in _boss.get_dangerous_circles():
			var centre := Vector2(circle.x, circle.y)
			var danger_t: float = _segment_circle_entry_t(
				segment_start,
				segment_end,
				centre,
				circle.z + _player.get_collision_radius(),
			)
			if danger_t < earliest_t:
				earliest_t = danger_t
				var point: Vector2 = segment_start.lerp(segment_end, danger_t)
				result = {
					&"kind": &"damage",
					&"point": point,
					&"normal": (point - centre).normalized(),
				}
		for lane: PackedVector2Array in _boss.get_dangerous_lanes():
			var lane_t: float = _segment_lane_entry_t(
				segment_start,
				segment_end,
				lane[0],
				lane[1],
				_boss.get_lane_radius() + _player.get_collision_radius(),
			)
			if lane_t < earliest_t:
				earliest_t = lane_t
				var point: Vector2 = segment_start.lerp(segment_end, lane_t)
				result = {
					&"kind": &"damage",
					&"point": point,
					&"normal": Vector2.ZERO,
				}
	return result


func _segment_circle_entry_t(
		segment_start: Vector2,
		segment_end: Vector2,
		circle_centre: Vector2,
		radius: float,
	) -> float:
	var segment: Vector2 = segment_end - segment_start
	var length_squared: float = segment.length_squared()
	if length_squared <= 0.0001:
		return 0.0 if segment_start.distance_to(circle_centre) <= radius else INF
	var projection: float = clampf(
		(circle_centre - segment_start).dot(segment) / length_squared,
		0.0,
		1.0,
	)
	var closest: Vector2 = segment_start + segment * projection
	var closest_distance_squared: float = closest.distance_squared_to(circle_centre)
	var radius_squared: float = radius * radius
	if closest_distance_squared > radius_squared:
		return INF
	var half_chord_ratio: float = sqrt(
		maxf(0.0, radius_squared - closest_distance_squared) / length_squared
	)
	return clampf(projection - half_chord_ratio, 0.0, 1.0)


func _segment_lane_entry_t(
	segment_start: Vector2,
	segment_end: Vector2,
	lane_start: Vector2,
	lane_end: Vector2,
	radius: float,
	) -> float:
	if DashGeometry.distance_to_segment(segment_start, lane_start, lane_end) <= radius:
		return 0.0
	var length: float = maxf(segment_start.distance_to(segment_end), 0.001)
	var intersection: Variant = Geometry2D.segment_intersects_segment(
		segment_start,
		segment_end,
		lane_start,
		lane_end,
	)
	if intersection is Vector2:
		return segment_start.distance_to(intersection as Vector2) / length
	# True segment-to-segment closest approach. Testing only the start, the end and an exact crossing
	# misses a dash that passes within the corridor radius near a lane's END without crossing it -
	# and faster dashes (launch burst, momentum) make that gap far easier to slip through.
	var closest: PackedVector2Array = Geometry2D.get_closest_points_between_segments(
		segment_start,
		segment_end,
		lane_start,
		lane_end,
	)
	if closest[0].distance_to(closest[1]) <= radius:
		return segment_start.distance_to(closest[0]) / length
	return INF


func _on_player_wall_impacted(
		world_position: Vector2,
		inward_normal: Vector2,
		dash_id: int,
	) -> void:
	_last_wall_impact_msec = Time.get_ticks_msec()
	for child: Node in _enemy_layer.get_children():
		if child is EnemyActor:
			(child as EnemyActor).set_last_edge_position(world_position)
	if is_instance_valid(_boss):
		_boss.set_last_edge_position(world_position)
	var dash_kills: int = _resolve_completed_dash(dash_id)
	_play_wall_splash(world_position, inward_normal, dash_kills)
	_play_impact_feedback(world_position, inward_normal, dash_kills)
	_release_death_pulse(world_position, dash_id)
	dash_resolved.emit(dash_kills, &"wall")


func _on_player_obstacle_impacted(
		_world_position: Vector2,
		_impact_normal: Vector2,
		dash_id: int,
	) -> void:
	var dash_kills: int = _resolve_completed_dash(dash_id)
	_show_callout("VOID CRYSTAL")
	SoundFx.play(&"wall_impact", 0.8)
	add_trauma(0.35)
	dash_resolved.emit(dash_kills, &"obstacle")


func _resolve_completed_dash(dash_id: int, from_redirect: bool = false) -> int:
	var dash_kills: int = _kills_by_dash.get(dash_id, 0)
	_kills_by_dash.erase(dash_id)
	_link_remaining_by_event.erase(dash_id)
	# An empty WALL dash wastes the combo window. An empty redirect leg is a deliberate turn in open
	# floor; decaying the combo for each one would punish exactly the fast play redirect exists for.
	if dash_kills == 0 and _combo > 0 and not from_redirect and not is_rush_active():
		_combo_remaining *= 0.72
	if dash_kills >= 2:
		_multi_kill_dashes += 1
		var bonus: int = _apply_velocity_score_bonus(dash_kills * dash_kills * 10)
		_score += bonus
		_award_rift_points(dash_kills / 3)
		var label: String = "DOUBLE REAP" if dash_kills == 2 else "TRIPLE REAP"
		if dash_kills > 3:
			label = "%d REAP RICOCHET" % dash_kills
		_show_callout("%s  +%d" % [label, bonus])
	if _rapid_redirect_dashes.get(dash_id, false):
		_rapid_ricochets += 1
		_score += _apply_velocity_score_bonus(RAPID_REDIRECT_SCORE)
	_rapid_redirect_dashes.erase(dash_id)
	_score_label.text = "%06d" % _score
	return dash_kills


func _release_death_pulse(world_position: Vector2, dash_id: int) -> void:
	var pulse_level: int = _run_progression.get_mutation_level(&"death_pulse")
	if pulse_level <= 0:
		return
	var radius_design: float = (
		_run_progression.tuning.pulse_base_radius
		+ float(pulse_level) * _run_progression.tuning.pulse_radius_per_level
	)
	var radius: float = radius_design * (_arena_rect.size.x / 1080.0)
	var event_id: int = -PULSE_EVENT_OFFSET - dash_id
	for child: Node in _enemy_layer.get_children():
		if child is EnemyActor:
			var enemy := child as EnemyActor
			if enemy.global_position.distance_to(world_position) <= radius + enemy.get_collision_radius():
				enemy.try_direct_hit(maxi(1, (pulse_level + 1) / 3), event_id)
	var pulse := Sprite2D.new()
	pulse.texture = DEATH_PULSE_TEXTURE
	pulse.global_position = world_position
	pulse.modulate = Color(_get_form_tint(), 0.82)
	pulse.scale = Vector2.ONE * 0.05
	_effects_layer.add_child(pulse)
	var final_scale: Vector2 = Vector2.ONE * (radius * 2.0 / 362.0)
	var pulse_tween: Tween = create_tween().set_parallel(true)
	pulse_tween.tween_property(pulse, "scale", final_scale, 0.28).set_trans(
		Tween.TRANS_QUAD
	).set_ease(Tween.EASE_OUT)
	pulse_tween.tween_property(pulse, "modulate:a", 0.0, 0.28)
	pulse_tween.chain().tween_callback(pulse.queue_free)


func _on_player_focus_started(duration: float, world_speed: float) -> void:
	_focus_remaining = duration
	_set_world_speed(world_speed)
	_focus_label.visible = true
	_focus_label.modulate.a = 1.0


func _on_enemy_killed(
		enemy: EnemyActor,
		world_position: Vector2,
		score_reward: int,
		experience_reward: int,
		damage_event_id: int,
	) -> void:
	_combo += 1
	_highest_combo = maxi(_highest_combo, _combo)
	_total_kills += 1
	_kill_streak += 1
	_combo_remaining = COMBO_TIMEOUT
	_score += _apply_velocity_score_bonus(score_reward * _combo)
	var dash_kill_index: int = 0
	if damage_event_id > 0:
		dash_kill_index = _kills_by_dash.get(damage_event_id, 0) + 1
		_kills_by_dash[damage_event_id] = dash_kill_index
		_player.play_attack_visual()
	_remaining_live_enemies = maxi(0, _remaining_live_enemies - 1)
	_spawn_split_children(enemy, world_position)
	_fill_rush_from_kill(world_position, dash_kill_index)
	_try_kill_finisher(dash_kill_index)
	if _is_field_clear():
		_mark_calm_moment(&"field_clear")
	SoundFx.multi_kill(int(_kills_by_dash.get(damage_event_id, 1)) if damage_event_id > 0 else 1)
	_play_kill_effects(world_position)
	_update_music_state()
	_grant_experience(experience_reward)
	_score_label.text = "%06d" % _score
	_combo_label.text = "×%d SOUL CHAIN" % _combo
	_style_callout(false)
	_combo_label.visible = _combo >= 2
	if _random.randf() <= enemy.get_shard_drop_chance():
		_spawn_rp_pickup(world_position)
	_try_reapers_gift()
	_try_soul_link(enemy, world_position, damage_event_id)
	enemy_defeated.emit(world_position, dash_kill_index)
	print(
		"[GameWorld] enemy killed | event=%d score=%d combo=%d xp=%d"
		% [damage_event_id, _score, _combo, _run_progression.get_current_xp()]
	)


func _try_soul_link(
		killed_enemy: EnemyActor,
		world_position: Vector2,
		damage_event_id: int,
	) -> void:
	var links_remaining: int = _link_remaining_by_event.get(damage_event_id, 0)
	if links_remaining <= 0:
		return
	_link_remaining_by_event[damage_event_id] = links_remaining - 1
	var nearest: EnemyActor = _find_nearest_active_enemy(world_position, killed_enemy)
	if nearest != null:
		nearest.try_direct_hit(_player.dash_damage, damage_event_id)


func _find_nearest_active_enemy(origin: Vector2, excluded: EnemyActor) -> EnemyActor:
	var nearest: EnemyActor
	var nearest_distance_squared: float = INF
	for child: Node in _enemy_layer.get_children():
		if not child is EnemyActor or child == excluded:
			continue
		var enemy := child as EnemyActor
		if not enemy.is_contact_active():
			continue
		var distance_squared: float = origin.distance_squared_to(enemy.global_position)
		if distance_squared < nearest_distance_squared:
			nearest_distance_squared = distance_squared
			nearest = enemy
	return nearest


## The score choke point: Void Velocity's bonus, then RUSH's multiplier while it runs.
func _apply_velocity_score_bonus(base_score: int) -> int:
	var velocity_level: int = _run_progression.get_mutation_level(&"void_velocity")
	var rush_multiplier: float = feel_tuning.score_multiplier if is_rush_active() else 1.0
	return roundi(
		float(base_score)
		* (1.0 + float(velocity_level) * _run_progression.tuning.velocity_score_bonus)
		* rush_multiplier
	)


func _spawn_rp_pickup(world_position: Vector2) -> void:
	var pickup := RP_PICKUP_SCENE.instantiate() as SoulShardPickup
	pickup.configure(_player, _get_pickup_attraction_radius(), _arena_rect.size.x)
	pickup.position = world_position
	pickup.collected.connect(_on_rp_pickup_collected.bind(pickup))
	_pickup_layer.add_child(pickup)


func _on_rp_pickup_collected(amount: int, pickup: SoulShardPickup) -> void:
	_award_rift_points(amount)
	# Swept shards share one capped chime run (`_play_sweep_chimes`), never a sound each.
	if not is_instance_valid(pickup) or not pickup.is_auto_collected():
		SoundFx.play(&"shard_pickup")


## Adds run XP. Every XP award goes through here.
func _grant_experience(amount: int) -> void:
	if amount <= 0 or not _experience_enabled:
		return
	_run_progression.add_experience(amount)


## Adds Rift Points collected during the run; every in-run RP award passes through here.
func _award_rift_points(amount: int) -> void:
	if amount <= 0:
		return
	_rp_collected += amount
	_rift_points_count.text = RiftPoints.group_digits(_rp_collected)


func _get_pickup_attraction_radius() -> float:
	var hunger_level: int = _run_progression.get_mutation_level(&"soul_hunger")
	return (
		_run_progression.tuning.shard_attraction_radius
		+ float(hunger_level) * _run_progression.tuning.hunger_attraction_per_level
	)


func _update_pickup_attraction() -> void:
	if not is_node_ready():
		return
	for child: Node in _pickup_layer.get_children():
		if child is SoulShardPickup:
			(child as SoulShardPickup).configure(
				_player,
				_get_pickup_attraction_radius(),
				_arena_rect.size.x,
			)


func _try_reapers_gift() -> void:
	var gift_level: int = _run_progression.get_mutation_level(&"reapers_gift")
	if gift_level <= 0:
		return
	var threshold: int = maxi(
		_run_progression.tuning.gift_minimum_streak,
		_run_progression.tuning.gift_base_streak
		- gift_level * _run_progression.tuning.gift_reduction_per_level,
	)
	if _kill_streak >= threshold and _player.heal(1):
		_kill_streak = 0
		_show_callout("REAPER'S GIFT  +1")


func _on_experience_changed(current_xp: int, threshold: int, run_level: int) -> void:
	_xp_bar.max_value = maxf(1.0, float(threshold))
	_xp_bar.value = float(current_xp)
	_run_level_label.text = "SOUL LEVEL %d" % run_level


## A level-up never interrupts: it is banked silently until a calm moment offers the cards.
func _on_progression_level_ready() -> void:
	_refresh_upgrade_button()
	print("[GameWorld] level banked | banked=%d" % _run_progression.get_banked_levels())


## Starts a calm moment: a wave starting, a boss beaten (after the victory beat) or the field clear
## of regular enemies. Banked cards may open within `calm_window_seconds` once the rest is calm too.
func _mark_calm_moment(reason: StringName) -> void:
	if _run_over or _scripted:
		return
	_calm_moment_id += 1
	_calm_window_remaining = _run_progression.tuning.calm_window_seconds
	if _run_progression.get_banked_levels() > 0:
		print("[GameWorld] calm moment | reason=%s id=%d banked=%d" % [
			reason, _calm_moment_id, _run_progression.get_banked_levels(),
		])


## Counts the open tray's real-time timeout down, or opens the tray at a calm moment. Runs only
## while the tree is not paused and the run is not over.
func _update_upgrade_offer(delta: float) -> void:
	_pulse_upgrade_button(delta)
	if _upgrade_tray.is_open():
		# `delta` is scaled by the slow motion the tray itself holds; the timeout is real seconds.
		_upgrade_tray_remaining -= delta / maxf(Engine.time_scale, 0.01)
		_upgrade_tray.set_timeout_share(
			_upgrade_tray_remaining / maxf(0.01, _run_progression.tuning.tray_timeout)
		)
		if _upgrade_tray_remaining <= 0.0:
			_close_upgrade_tray(&"timeout")
		return
	_calm_window_remaining = maxf(0.0, _calm_window_remaining - delta)
	if _is_upgrade_calm():
		_open_upgrade_tray()


## Every rule of a calm moment (GDD §5.5): cards banked, free play (a tutorial lesson only on its own
## request), no boss pending, alive or in its victory beat, no RUSH, not paused, run not over, the
## Wisp resting at an edge, no combo running, and a calm moment whose cards were not shown yet.
func _is_upgrade_calm() -> bool:
	if _run_progression.get_banked_levels() <= 0:
		return false
	if _run_over or get_tree().paused or _pause_overlay.visible:
		return false
	if _boss_pending or is_instance_valid(_boss) or _post_boss_remaining >= 0.0:
		return false
	if is_rush_active() or _combo > 0:
		return false
	if _player.state != WispPlayer.State.WAITING_AT_EDGE:
		return false
	if _scripted:
		return _scripted_upgrade_calm_requested
	return _calm_window_remaining > 0.0 and _calm_moment_id != _upgrade_offer_spent_moment_id


## Slides the card tray up with the next three choices; the world runs at `tray_time_scale` while it
## is up (normal speed under Reduced Motion). Plays `level_up`.
func _open_upgrade_tray() -> void:
	var choices: Array[MutationData] = _run_progression.offer_choices(3)
	if choices.is_empty():
		return
	_scripted_upgrade_calm_requested = false
	_upgrade_offer_spent_moment_id = _calm_moment_id
	_present_upgrade_choices(choices)
	_refresh_upgrade_button()
	SoundFx.play(&"level_up")
	print("[GameWorld] upgrade tray open | banked=%d moment=%d" % [
		_run_progression.get_banked_levels(), _calm_moment_id,
	])


func _present_upgrade_choices(choices: Array[MutationData]) -> void:
	var tuning: RunProgressionTuning = _run_progression.tuning
	_upgrade_tray_remaining = tuning.tray_timeout
	_upgrade_tray.present(
		choices,
		_run_progression.get_levels(),
		0.0 if _reduced_motion else tuning.tray_slide_seconds,
	)
	if _reduced_motion:
		_release_time_scale(TIME_SCALE_HOLD_UPGRADE_TRAY)
	else:
		_hold_time_scale(TIME_SCALE_HOLD_UPGRADE_TRAY, tuning.tray_time_scale)


## Sends the tray away (if up) and releases its slow motion; any banked level stays banked. The calm
## moment it was opened for is spent, so the cards return only at the next one. [param instant] skips
## the slide (run end).
func _close_upgrade_tray(reason: StringName, instant: bool = false) -> void:
	_release_time_scale(TIME_SCALE_HOLD_UPGRADE_TRAY)
	if not _upgrade_tray.is_open():
		return
	_calm_window_remaining = 0.0
	_upgrade_tray.dismiss(
		0.0 if instant or _reduced_motion else _run_progression.tuning.tray_slide_seconds
	)
	_refresh_upgrade_button()
	print("[GameWorld] upgrade tray closed | reason=%s banked=%d" % [
		reason, _run_progression.get_banked_levels(),
	])


## A card was tapped: apply it once, then show the next banked set at once or close the tray.
func _on_upgrade_choice_selected(mutation_id: StringName) -> void:
	if not _run_progression.apply_choice(mutation_id):
		return
	SoundFx.play(&"upgrade_choice")
	var next_choices: Array[MutationData] = []
	if _run_progression.get_banked_levels() > 0:
		next_choices = _run_progression.offer_choices(3)
	if next_choices.is_empty():
		_close_upgrade_tray(&"picked")
	else:
		_present_upgrade_choices(next_choices)
	upgrade_chosen.emit(mutation_id)


## The UPGRADE button (owner 2026-09-15): tapping it opens the cards now, without waiting for a calm
## moment. Refused while paused, after the run ends or when the cards are already up.
func _on_upgrade_button_pressed() -> void:
	if _run_over or get_tree().paused or _upgrade_tray.is_open():
		return
	if _run_progression.get_banked_levels() <= 0:
		_refresh_upgrade_button()
		return
	_player.cancel_active_aim()
	_open_upgrade_tray()


## Shows the UPGRADE button while a level-up is banked and the cards are not up; ×N for several.
func _refresh_upgrade_button() -> void:
	if not is_node_ready():
		return
	var banked: int = _run_progression.get_banked_levels()
	_upgrade_button.visible = banked > 0 and not _run_over and not _upgrade_tray.is_open()
	_upgrade_count.visible = banked > 1
	_upgrade_count.text = "×%d" % banked
	if not _upgrade_button.visible:
		_upgrade_button.modulate = Color.WHITE


func _pulse_upgrade_button(delta: float) -> void:
	if not _upgrade_button.visible:
		return
	var brightness: float = 1.0
	if not _reduced_motion:
		var tuning: RunProgressionTuning = _run_progression.tuning
		_upgrade_button_pulse_time += delta / maxf(Engine.time_scale, 0.01)
		var phase: float = _upgrade_button_pulse_time * TAU * tuning.button_pulse_rate
		brightness = 1.0 + tuning.button_pulse_amount * (0.5 + 0.5 * sin(phase))
	_upgrade_button.modulate = Color(brightness, brightness, brightness, 1.0)


func _on_mutation_applied(mutation_id: StringName, mutation_level: int) -> void:
	_refresh_upgrade_button()
	if mutation_id == &"soul_vessel":
		_player.increase_maximum_health(1, 1)
	_update_player_mutation_stats()
	_update_pickup_attraction()
	var mutation: MutationData = _run_progression.get_mutation(mutation_id)
	_show_callout("%s  LV.%d" % [mutation.display_name, mutation_level])


func _update_player_mutation_stats() -> void:
	var hunger_level: int = _run_progression.get_mutation_level(&"soul_hunger")
	var wide_level: int = _run_progression.get_mutation_level(&"wide_reap")
	var velocity_level: int = _run_progression.get_mutation_level(&"void_velocity")
	_player.set_run_combat_modifiers(
		1 + hunger_level,
		1.0 + float(wide_level) * _run_progression.tuning.wide_reap_per_level,
		1.0 + float(velocity_level) * _run_progression.tuning.velocity_per_level,
	)


func _on_player_health_changed(current_health: int, _maximum_health: int) -> void:
	_life_count.text = str(current_health)


func _on_player_damaged(current_health: int, _maximum_health: int) -> void:
	if not is_rush_active():
		_rush_meter = maxf(0.0, _rush_meter - feel_tuning.damage_drain)
	if current_health <= 0:
		# The death dissolve is still playing: the shards reach the Wisp before the summary.
		_sweep_floor_shards()
	_combo = 0
	_combo_remaining = 0.0
	_kill_streak = 0
	_combo_label.visible = false
	_show_callout("SOUL FRACTURED")
	SoundFx.play(&"player_damage")
	add_trauma(0.75)
	Haptics.pulse(Haptics.HEAVY_MS, 0.9)
	_update_music_state()
	player_damaged.emit(current_health)


func _on_player_died() -> void:
	if _run_over:
		return
	_run_over = true
	_clear_aim_preview()
	_close_upgrade_tray(&"run_end", true)
	# Banked but unpicked level-ups are lost with the run.
	_clear_time_scale_requests()
	_end_rush(false)
	SoundFx.play(&"player_dissolve")
	SoundFx.music_state(0.0, false)
	_waves_start_remaining = -1.0
	_focus_remaining = 0.0
	_set_world_speed(0.1)
	_pause_button.disabled = true
	_emit_run_end()


## Builds the run summary (story fields included) and emits `run_ended` once.
func _emit_run_end() -> void:
	# Right before the summary: every shard still on the floor or in flight counts, once.
	_sweep_floor_shards(true)
	var victory: bool = _level_cleared
	var first_clear: bool = victory and _first_clear_possible
	var clear_bonus: int = 0
	if victory and economy_tuning != null:
		clear_bonus = economy_tuning.get_level_clear_bonus(_rift_level, first_clear)
	var summary: Dictionary = {
		&"score": _score,
		&"kills": _total_kills,
		&"highest_combo": _highest_combo,
		&"wave": _current_wave,
		&"multi_kill_dashes": _multi_kill_dashes,
		&"rapid_ricochets": _rapid_ricochets,
		&"bosses": _bosses_defeated,
		&"rp_collected": _rp_collected,
		&"rp_performance": get_rp_performance(),
		&"run_level": _run_progression.get_run_level(),
		&"daily_date": _daily_date_key,
		&"is_daily": _mode == RunProfile.MODE_DAILY,
		&"mode": String(_mode),
		# Empty on Endless rules, so Rift bests and level clears are never touched by those runs.
		&"rift": String(_arena_rules.get_rift_id()),
		&"skin_id": String(_arena_rules.get_skin_id()),
		&"cycle": _bosses_defeated,
		&"rift_rule": String(_rift_rule),
		&"level": _rift_level,
		&"victory": victory,
		&"level_cleared": victory,
		&"first_clear": first_clear,
		&"rp_clear_bonus": clear_bonus,
		# Trials read this cumulative count; one story run clears at most one level.
		&"level_clears": 1 if victory else 0,
		&"rift_levels_cleared": _rift_level if victory else 0,
		# RUSH activations this run, for future goals (no save field).
		&"rush_count": _rush_count,
	}
	print(
		"[GameWorld] run ended | mode=%s victory=%s score=%d kills=%d wave=%d rp_collected=%d rp_performance=%d rp_clear=%d%s"
		% [
			_mode, victory, _score, _total_kills, _current_wave, _rp_collected, get_rp_performance(),
			clear_bonus,
			" (economy placeholder)" if economy_tuning != null and economy_tuning.placeholder else "",
		]
	)
	run_ended.emit(summary)


func _show_callout(text: String, emphasis: float = 1.0) -> void:
	if _callout_tween != null and _callout_tween.is_valid():
		_callout_tween.kill()
	_combo_label.text = text
	# Callouts that award something ("+120", "+1") read as rewards: amber; the rest soul white.
	_style_callout(text.contains("+"))
	_combo_label.visible = true
	_combo_label.modulate = Color.WHITE
	_combo_label.scale = Vector2(0.82, 0.82)
	_combo_label.pivot_offset = _combo_label.size * 0.5
	_callout_tween = create_tween()
	_callout_tween.tween_property(_combo_label, "scale", Vector2.ONE * emphasis, 0.16).set_trans(
		Tween.TRANS_BACK
	).set_ease(Tween.EASE_OUT)
	_callout_tween.tween_interval(0.65)
	_callout_tween.tween_property(_combo_label, "modulate:a", 0.0, 0.24)
	_callout_tween.tween_callback(
		func() -> void:
			_combo_label.visible = false
			_combo_label.scale = Vector2.ONE
	)


func _style_callout(is_reward: bool) -> void:
	_combo_label.theme_type_variation = &"AmberValueLabel" if is_reward else &"TitleLabel"


## Plays the splash where the Wisp hit the wall. No wall highlight: the effect lives only at impact.
func _play_wall_splash(world_position: Vector2, inward_normal: Vector2, dash_kills: int) -> void:
	_wall_splash.play(
		world_position,
		inward_normal,
		1.0 + 0.35 * float(mini(dash_kills, 4)),
		_get_form_tint(),
		_arena_rect.size.x,
		_reduced_motion,
		# The Wisp's centre rests LANDING_INSET radii from the wall; this lands the splash on it.
		_player.get_collision_radius() * (LANDING_INSET - 0.1),
	)


func _set_paused(paused: bool) -> void:
	_player.cancel_active_aim()
	if paused:
		# Pause and interruptions never keep a slow-motion request or hold running under the menu.
		_clear_time_scale_requests()
	# The pause menu hides an open upgrade tray; resuming shows it again with its slow motion.
	_upgrade_tray.set_suspended(paused)
	if not paused and _upgrade_tray.is_open() and not _reduced_motion:
		_hold_time_scale(TIME_SCALE_HOLD_UPGRADE_TRAY, _run_progression.tuning.tray_time_scale)
	_pause_overlay.visible = paused
	get_tree().paused = paused
	SoundFx.set_interrupted(paused)
	if paused:
		_resume_button.grab_focus()
	else:
		_close_confirm()
		_close_settings_overlay()


func _on_pause_button_pressed() -> void:
	_set_paused(true)


func _on_resume_button_pressed() -> void:
	_set_paused(false)
	_pause_button.grab_focus()


func _on_home_button_pressed() -> void:
	if is_run_meaningful():
		_open_confirm(&"home")
	else:
		_leave_to_home()


func _on_restart_button_pressed() -> void:
	if is_run_meaningful():
		_open_confirm(&"restart")
	else:
		_restart_run()


func _leave_to_home() -> void:
	_set_paused(false)
	home_requested.emit()


func _restart_run() -> void:
	_set_paused(false)
	restart_requested.emit()


func _open_confirm(action: StringName) -> void:
	_confirm_action = action
	_confirm_title.text = "RESTART THIS RUN?" if action == &"restart" else "ABANDON THIS RUN?"
	_confirm_overlay.visible = true
	_confirm_cancel_button.grab_focus()


func _close_confirm() -> void:
	if not _confirm_overlay.visible:
		return
	_confirm_overlay.visible = false
	_confirm_action = &""
	if _pause_overlay.visible:
		_resume_button.grab_focus()


func _on_confirm_yes_button_pressed() -> void:
	var action: StringName = _confirm_action
	_confirm_overlay.visible = false
	_confirm_action = &""
	if action == &"restart":
		_restart_run()
	elif action == &"home":
		_leave_to_home()


func _open_settings_overlay() -> void:
	if is_instance_valid(_settings_overlay):
		return
	_settings_overlay = SETTINGS_SCENE.instantiate() as SettingsScreen
	_settings_overlay.allow_progress_reset = false
	_settings_overlay.back_requested.connect(_close_settings_overlay)
	_pause_overlay.get_parent().add_child(_settings_overlay)
	SoundFx.bind_buttons(_settings_overlay)
	UiJuice.bind_press_feedback(_settings_overlay)


func _close_settings_overlay() -> void:
	if not is_instance_valid(_settings_overlay):
		return
	_settings_overlay.queue_free()
	_settings_overlay = null
	if _pause_overlay.visible:
		_resume_button.grab_focus()


func _apply_feel_settings(settings: Dictionary) -> void:
	_reduced_motion = bool(settings.get(&"reduced_motion", false))
	_ambience.set_active(not _reduced_motion)
	_player.set_reduced_motion(_reduced_motion)
	_player.set_aim_arrow_enabled(bool(settings.get(&"aim_arrow", true)))
	_player.set_aim_assist_enabled(bool(settings.get(&"aim_assist", true)))
	_shake_strength = clampf(float(settings.get(&"screen_shake", 1.0)), 0.0, 1.0) * (
		REDUCED_MOTION_SHAKE if _reduced_motion else 1.0
	)
	if _shake_strength <= 0.0:
		_trauma = 0.0
	if _reduced_motion and is_instance_valid(_rush_edge_glow):
		_rush_edge_glow.visible = false


func _update_shake(delta: float) -> void:
	if _trauma <= 0.0:
		return
	_trauma = maxf(0.0, _trauma - TRAUMA_DECAY * delta)
	_shake_time += delta
	var magnitude: float = (
		SHAKE_MAX_OFFSET * (_arena_rect.size.x / 1080.0) * _shake_strength * _trauma * _trauma
	)
	_set_view_offset(Vector2(sin(_shake_time * 71.0), cos(_shake_time * 57.0 + 1.7)) * magnitude)


func _set_view_offset(offset: Vector2) -> void:
	var viewport: Viewport = get_viewport()
	if viewport == null:
		return
	var view: Transform2D = viewport.canvas_transform
	view.origin = offset
	viewport.canvas_transform = view


func _hit_stop() -> void:
	if _reduced_motion:
		return
	_request_time_scale(HIT_STOP_TIME_SCALE, HIT_STOP_SECONDS)


## The only writer of `Engine.time_scale` during a run: adds a request that lasts [param real_seconds]
## of real time (its timer ignores time scale). The lowest active scale wins; with no request left the
## scale is 1.0. One owner, because two writers race: a hit-stop ending would snap a slow-motion
## finisher back to full speed.
func _request_time_scale(scale: float, real_seconds: float) -> void:
	if real_seconds <= 0.0 or not is_inside_tree():
		return
	_next_time_scale_request_id += 1
	var request_id: int = _next_time_scale_request_id
	_time_scale_requests[request_id] = clampf(scale, 0.01, 1.0)
	get_tree().create_timer(real_seconds, true, false, true).timeout.connect(
		_expire_time_scale_request.bind(request_id)
	)
	_apply_time_scale()


func _expire_time_scale_request(request_id: int) -> void:
	if _time_scale_requests.erase(request_id):
		_apply_time_scale()


## Holds [param scale] under [param key] until `_release_time_scale(key)` (no timer): the upgrade tray
## keeps the world slow for as long as it is up. Holding a key again replaces its scale. Pause,
## interruption, run end, scene exit and `_reset_view_effects()` drop every hold.
func _hold_time_scale(key: StringName, scale: float) -> void:
	if not is_inside_tree():
		return
	_time_scale_holds[key] = clampf(scale, 0.01, 1.0)
	_apply_time_scale()


## Releases the hold under [param key]; the remaining requests and holds decide the scale.
func _release_time_scale(key: StringName) -> void:
	if _time_scale_holds.erase(key):
		_apply_time_scale()


## Drops every request and hold (pause, interruption, run end, view reset).
func _clear_time_scale_requests() -> void:
	if _time_scale_requests.is_empty() and _time_scale_holds.is_empty():
		return
	_time_scale_requests.clear()
	_time_scale_holds.clear()
	Engine.time_scale = 1.0


func _apply_time_scale() -> void:
	var scale: float = 1.0
	for requested: float in _time_scale_requests.values():
		scale = minf(scale, requested)
	for held: float in _time_scale_holds.values():
		scale = minf(scale, held)
	Engine.time_scale = scale


func _reset_view_effects() -> void:
	_trauma = 0.0
	_time_scale_requests.clear()
	_time_scale_holds.clear()
	Engine.time_scale = 1.0
	_set_view_offset(Vector2.ZERO)


func _update_music_state() -> void:
	var intensity: float = clampf(
		float(_combo) / 12.0 + float(_current_wave - 1) * 0.07,
		0.0,
		1.0,
	)
	if is_rush_active():
		intensity = 1.0
	SoundFx.music_state(intensity, is_instance_valid(_boss) and not _run_over)


func _get_form_tint() -> Color:
	return _cosmetic_form.tint if _cosmetic_form != null else Palette.SOUL_CYAN


## Launch burst tint: the equipped dash style's, or the form tint for SOUL.
func _get_dash_burst_tint() -> Color:
	if _dash_style == null or _dash_style.uses_form_tint:
		return _get_form_tint()
	return _dash_style.burst_tint


## Long trail tint: the equipped dash style's, or the form tint for SOUL.
func _get_dash_trail_tint() -> Color:
	if _dash_style == null or _dash_style.uses_form_tint:
		return _get_form_tint()
	return _dash_style.trail_tint


## Dash trails. Chain momentum (GDD §5.6) stretches them and raises their alpha: the launch burst when
## a dash starts, and the long trail ([param long_trail_end] set) where a long dash lands. Tints stay
## the dash style's.
func _play_dash_trail(long_trail_end: Variant = null) -> void:
	var radius: float = _player.get_collision_radius()
	var level: float = _player.get_momentum_visual_level()
	var length: float = lerpf(1.0, feel_tuning.trail_length_at_max, level)
	if long_trail_end is Vector2:
		_vfx.play(
			DASH_TRAIL_LONG,
			(long_trail_end as Vector2) - _dash_direction * radius * 3.0 * length,
			_dash_direction.angle(),
			Vector2(radius * 5.5 * length / VFX_SOURCE_SIZE, radius * 5.5 / VFX_SOURCE_SIZE),
			Vector2(radius * 7.5 * length / VFX_SOURCE_SIZE, radius * 3.0 / VFX_SOURCE_SIZE),
			0.26,
			Color(_get_dash_trail_tint(), lerpf(0.8, feel_tuning.trail_alpha_at_max, level)),
		)
		return
	var base_scale: float = radius * 4.2 / VFX_SOURCE_SIZE
	_vfx.play(
		DASH_TRAIL_SHORT,
		_dash_origin + _dash_direction * radius * 1.4 * length,
		_dash_direction.angle(),
		Vector2(base_scale * length, base_scale),
		Vector2(base_scale * 1.6 * length, base_scale * 0.7),
		0.22,
		Color(_get_dash_burst_tint(), lerpf(0.85, feel_tuning.trail_alpha_at_max, level)),
	)


func _play_impact_feedback(world_position: Vector2, inward_normal: Vector2, dash_kills: int) -> void:
	var radius: float = _player.get_collision_radius()
	var tint: Color = _get_form_tint()
	SoundFx.play(&"wall_impact", 1.0 + minf(0.25, float(dash_kills) * 0.05))
	if _dash_origin.distance_to(world_position) >= _arena_rect.size.y * 0.45:
		_play_dash_trail(world_position)
	if dash_kills >= 3:
		add_trauma(0.62)
		_hit_stop()
		Haptics.pulse(Haptics.MEDIUM_MS, 0.8)
		_vfx.play(
			WALL_IMPACT_LARGE,
			world_position,
			inward_normal.angle(),
			Vector2.ONE * (radius * 2.0 / VFX_SOURCE_SIZE),
			Vector2.ONE * (radius * 5.0 / VFX_SOURCE_SIZE),
			0.3,
			Color(tint, 0.95),
		)
	elif dash_kills == 2:
		add_trauma(0.52)
		Haptics.pulse(Haptics.MEDIUM_MS, 0.5)
	else:
		add_trauma(0.45)


func _play_kill_effects(world_position: Vector2) -> void:
	var radius: float = _player.get_collision_radius()
	_vfx.play(
		SOUL_SLICE,
		world_position,
		_dash_direction.angle(),
		Vector2.ONE * (radius * 2.2 / VFX_SOURCE_SIZE),
		Vector2.ONE * (radius * 3.0 / VFX_SOURCE_SIZE),
		0.18,
		Color(_get_form_tint(), 0.95),
	)
	_vfx.play(
		ENEMY_DISSOLVE,
		world_position,
		0.0,
		Vector2.ONE * (radius * 1.6 / VFX_SOURCE_SIZE),
		Vector2.ONE * (radius * 3.4 / VFX_SOURCE_SIZE),
		0.32,
		Color(1.0, 1.0, 1.0, 0.8),
	)


# --- RUSH mode and fast feel (GDD §5.6, docs/systems/rush_mode.md) --------------------------------


## Sets the run-state shade colour; a running finisher flash keeps blending over the new colour.
func _set_world_shade(color: Color) -> void:
	_shade_base_color = color
	_apply_world_shade()


func _set_finisher_flash(strength: float) -> void:
	_finisher_flash = clampf(strength, 0.0, 1.0)
	_apply_world_shade()


func _apply_world_shade() -> void:
	var flash_alpha: float = feel_tuning.finisher_flash_alpha if feel_tuning != null else 0.0
	var flash_color := Color(Palette.SOUL_WHITE, flash_alpha)
	_world_shade.color = _shade_base_color.lerp(flash_color, _finisher_flash)


## No regular enemy is alive during waves (split children count), with no boss pending or alive.
func _is_field_clear() -> bool:
	return (
		_remaining_live_enemies == 0
		and _waves_started
		and not _boss_pending
		and not is_instance_valid(_boss)
	)


## Free play: RUSH fills and starts and field-clear finishers may run. Always true in real runs; the
## tutorial switches it per lesson with `set_rush_enabled`.
func _is_free_play() -> bool:
	return _rush_enabled


## Kill-driven finishers: the kill that brings one dash to `finisher_kills` (mid-slice), or a kill that
## leaves no regular enemy alive during waves (not a scripted arena, not boss), at most once per cooldown.
func _try_kill_finisher(dash_kill_index: int) -> void:
	var multi_kill: bool = dash_kill_index == feel_tuning.finisher_kills
	var field_clear: bool = (
		_is_field_clear() and _is_free_play() and _field_clear_cooldown_remaining <= 0.0
	)
	if field_clear:
		_field_clear_cooldown_remaining = feel_tuning.field_clear_cooldown
	if multi_kill or field_clear:
		_play_finisher(&"multi_kill" if multi_kill else &"field_clear")


## Slow-motion finisher: ~0.4 s at ×0.3 through the time-scale owner, a light Soul White flash, a small
## trauma kick and a low `pulse`. Never under the pause menu or the upgrade choice; Reduced Motion
## keeps only the sound (and whatever callout the moment already shows).
func _play_finisher(reason: StringName) -> void:
	if _run_over or get_tree().paused or _upgrade_tray.is_open():
		return
	SoundFx.play(&"pulse", feel_tuning.finisher_pulse_pitch)
	print("[GameWorld] finisher | reason=%s reduced_motion=%s" % [reason, _reduced_motion])
	if _reduced_motion:
		return
	_request_time_scale(feel_tuning.finisher_time_scale, feel_tuning.finisher_seconds)
	add_trauma(feel_tuning.finisher_trauma)
	if _finisher_flash_tween != null and _finisher_flash_tween.is_valid():
		_finisher_flash_tween.kill()
	_set_finisher_flash(1.0)
	_finisher_flash_tween = create_tween().set_ignore_time_scale(true)
	_finisher_flash_tween.tween_method(_set_finisher_flash, 1.0, 0.0, feel_tuning.finisher_seconds)


## Meter from one kill (`per_kill`, plus `per_extra_dash_kill` after the dash's first) and its soul orb.
func _fill_rush_from_kill(world_position: Vector2, dash_kill_index: int) -> void:
	if not _can_fill_rush():
		return
	var amount: float = feel_tuning.get_kill_fill(dash_kill_index)
	_add_rush(amount, false)
	if _reduced_motion or not _rush_row.is_visible_in_tree():
		_on_rush_orb_landed(amount)
		return
	var radius: float = _player.get_collision_radius()
	var screen_target: Vector2 = _rush_bar.get_global_rect().get_center()
	var world_target: Vector2 = get_viewport().get_canvas_transform().affine_inverse() * screen_target
	_vfx.play_flight(
		RUSH_ORB_TEXTURE,
		world_position,
		world_target,
		Vector2.ONE * (radius * RUSH_ORB_START_RADII / VFX_SOURCE_SIZE),
		Vector2.ONE * (radius * RUSH_ORB_END_RADII / VFX_SOURCE_SIZE),
		feel_tuning.orb_flight_seconds,
		Color(_get_form_tint(), 0.95),
	)
	get_tree().create_timer(feel_tuning.orb_flight_seconds).timeout.connect(
		_on_rush_orb_landed.bind(amount)
	)


func _can_fill_rush() -> bool:
	return not _run_over and _is_free_play() and not is_rush_active()


## Adds meter; with [param show_now] the HUD fills at once (boss hits have no orb).
func _add_rush(amount: float, show_now: bool = true) -> void:
	if amount <= 0.0 or not _can_fill_rush():
		return
	_rush_meter = minf(feel_tuning.meter_max, _rush_meter + amount)
	if show_now:
		_on_rush_orb_landed(amount)


func _on_rush_orb_landed(amount: float) -> void:
	_rush_display_target = minf(_rush_meter, _rush_display_target + amount)


## Counts RUSH down in game time and starts it once the meter is full and play is free; a full meter
## waits out a disabled RUSH, pause and the upgrade tray (`_process` does not run while paused).
func _update_rush(delta: float) -> void:
	if is_rush_active():
		var remaining: float = _rush_remaining - delta
		if remaining <= 0.0:
			# End while _rush_remaining is still positive: _end_rush only empties the meter when it sees
			# RUSH active, and a full meter left behind would restart RUSH on the next frame.
			_end_rush(true)
		else:
			_rush_remaining = remaining
			_player.set_rush_visuals(true, _rush_remaining <= feel_tuning.warning_seconds)
	elif _rush_meter >= feel_tuning.meter_max and _can_start_rush():
		_start_rush()
	_update_rush_hud(delta)


func _can_start_rush() -> bool:
	return (
		not _run_over
		and _is_free_play()
		and not get_tree().paused
		and not _upgrade_tray.is_open()
		and not _pause_overlay.visible
	)


func _start_rush() -> void:
	_rush_remaining = feel_tuning.duration
	_rush_meter = feel_tuning.meter_max
	_rush_display_target = feel_tuning.meter_max
	_rush_count += 1
	_player.set_rush_speed_multiplier(feel_tuning.speed_multiplier)
	_player.set_damage_immune(feel_tuning.blocks_damage)
	_player.set_rush_visuals(true, false)
	_show_callout("RUSH", RUSH_CALLOUT_SCALE)
	Haptics.pulse(Haptics.HEAVY_MS, 1.0)
	add_trauma(feel_tuning.start_trauma)
	SoundFx.play(&"level_up")
	_update_music_state()
	rush_started.emit()
	print("[GameWorld] RUSH start | count=%d duration=%.1f" % [_rush_count, _rush_remaining])


## Ends RUSH: meter to 0 and every modifier restored. Safe to call when RUSH is off (run end, exit).
func _end_rush(play_sound: bool) -> void:
	var was_active: bool = is_rush_active()
	_rush_remaining = 0.0
	if is_instance_valid(_player):
		_player.set_rush_speed_multiplier(1.0)
		_player.set_damage_immune(false)
		_player.set_rush_visuals(false)
	if is_instance_valid(_rush_edge_glow):
		_rush_edge_glow.visible = false
	if not was_active:
		return
	_rush_meter = 0.0
	_rush_display_target = 0.0
	_rush_display = 0.0
	if play_sound and feel_tuning != null:
		SoundFx.play(&"pulse", 1.0, feel_tuning.end_sound_volume_db)
	if not _run_over:
		_update_music_state()
	if is_node_ready():
		_refresh_rush_hud()
	print("[GameWorld] RUSH end | count=%d" % _rush_count)


## Shows the RUSH row only in free play and syncs its bar.
func _refresh_rush_hud() -> void:
	_rush_row.visible = _is_free_play()
	_rush_bar.max_value = feel_tuning.meter_max
	_rush_bar.value = _rush_display


func _update_rush_hud(delta: float) -> void:
	var meter_max: float = feel_tuning.meter_max
	if is_rush_active():
		# While RUSH runs the bar drains with the time left.
		_rush_display = meter_max * _rush_remaining / maxf(0.01, feel_tuning.duration)
	elif _reduced_motion:
		_rush_display = _rush_meter
	else:
		_rush_display = lerpf(
			_rush_display, _rush_display_target, 1.0 - exp(-RUSH_BAR_CATCH_UP_RATE * delta)
		)
	_rush_bar.value = _rush_display
	var charged: bool = is_rush_active() or _rush_meter >= meter_max
	_rush_pulse_time += delta
	var brightness: float = 1.0
	if charged:
		# A pulse while full or running; static (but still brighter) under Reduced Motion.
		var wave: float = 0.5 + 0.5 * sin(_rush_pulse_time * TAU * feel_tuning.pulse_rate)
		brightness = 1.0 + RUSH_BAR_PULSE_AMOUNT * (0.5 if _reduced_motion else wave)
	_rush_row.modulate = Color(brightness, brightness, brightness, 1.0)
	var glow_on: bool = is_rush_active() and not _reduced_motion
	_rush_edge_glow.visible = glow_on
	if glow_on:
		var glow_wave: float = 0.5 + 0.5 * sin(_rush_pulse_time * TAU * feel_tuning.pulse_rate * 0.5)
		var glow_alpha: float = feel_tuning.edge_glow_alpha * (0.7 + 0.3 * glow_wave)
		_rush_edge_glow.modulate = Color(1.0, 1.0, 1.0, glow_alpha)


## Subtle screen-edge glow for RUSH: a full-screen radial gradient, transparent in the middle, under
## the HUD widgets. Built from `Palette`, not a per-node style.
func _build_rush_edge_glow() -> void:
	var gradient := Gradient.new()
	gradient.set_color(0, Color(Palette.SOUL_CYAN, 0.0))
	gradient.set_color(1, Color(Palette.SOUL_CYAN, 1.0))
	gradient.add_point(RUSH_EDGE_GLOW_INNER, Color(Palette.SOUL_CYAN, 0.0))
	var texture := GradientTexture2D.new()
	texture.gradient = gradient
	texture.fill = GradientTexture2D.FILL_RADIAL
	texture.fill_from = Vector2(0.5, 0.5)
	texture.fill_to = Vector2(1.0, 0.5)
	texture.width = RUSH_EDGE_GLOW_TEXTURE_SIZE
	texture.height = RUSH_EDGE_GLOW_TEXTURE_SIZE
	_rush_edge_glow = TextureRect.new()
	_rush_edge_glow.name = "RushEdgeGlow"
	_rush_edge_glow.texture = texture
	_rush_edge_glow.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_rush_edge_glow.stretch_mode = TextureRect.STRETCH_SCALE
	_rush_edge_glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_rush_edge_glow.visible = false
	var hud: Node = _pause_overlay.get_parent()
	hud.add_child(_rush_edge_glow)
	hud.move_child(_rush_edge_glow, 0)
	_rush_edge_glow.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)


## Auto-collect (GDD §5.6): every floor shard flies to the Wisp and collects through its `collected`
## signal, so `_award_rift_points` stays the only award path. [param immediate] collects at once
## (right before the run summary). One capped, rising chime run per sweep, never a sound per shard.
func _sweep_floor_shards(immediate: bool = false) -> void:
	if not is_node_ready():
		return
	var seconds: float = (
		feel_tuning.reduced_motion_sweep_seconds if _reduced_motion else feel_tuning.sweep_seconds
	)
	var shards: int = 0
	for child: Node in _pickup_layer.get_children():
		if not child is SoulShardPickup:
			continue
		var shard := child as SoulShardPickup
		if immediate:
			var already_flying: bool = shard.is_sweeping()
			if shard.collect_now() and not already_flying:
				shards += 1
		elif shard.sweep_to(_player, seconds):
			shards += 1
	if shards <= 0:
		return
	_play_sweep_chimes(shards)
	print("[GameWorld] shard sweep | shards=%d immediate=%s" % [shards, immediate])


func _play_sweep_chimes(shards: int) -> void:
	var chimes: int = mini(shards, feel_tuning.sweep_sound_cap)
	for index: int in chimes:
		var pitch: float = 1.0 + float(index) * feel_tuning.sweep_pitch_step
		var delay: float = float(index) * feel_tuning.sweep_chime_interval
		if delay <= 0.0 or not is_inside_tree():
			_play_sweep_chime(pitch)
		else:
			get_tree().create_timer(delay, false, false, true).timeout.connect(
				_play_sweep_chime.bind(pitch)
			)


func _play_sweep_chime(pitch: float) -> void:
	SoundFx.play(&"shard_pickup", pitch)
