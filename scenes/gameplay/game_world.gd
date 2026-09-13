class_name GameWorld
extends Control
## Coordinates the endless arena, tutorial, waves, combat, mutations, rewards and run summary.

## Emitted after the paused run requests a return to the Home screen.
signal home_requested
## Emitted after the Wisp death dissolve with the completed run statistics.
signal run_ended(summary: Dictionary)
## Emitted once when the player completes all three first-run lessons.
signal tutorial_completed
## Emitted when the player confirms restarting the run from the pause menu.
signal restart_requested

enum TutorialStep { DISABLED, FIRST_DASH, SINGLE_TARGET, CHAIN_TARGETS, COMPLETE }

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
const SANCTUM_CATALOG: SanctumCatalog = preload("res://data/sanctum/default_catalog.tres")
const HAZARD_SCENES: Dictionary = {
	&"split_crystal": preload("res://scenes/hazards/split_void_crystal.tscn"),
	&"spike_bloom": preload("res://scenes/hazards/spike_bloom.tscn"),
	&"blade_ring": preload("res://scenes/hazards/blade_ring.tscn"),
}
const SOUL_SHARD_SCENE: PackedScene = preload("res://scenes/pickups/soul_shard_pickup.tscn")
const REAPER_SCENE: PackedScene = preload("res://scenes/bosses/reaper_boss.tscn")
## Boss variants keyed by `RiftData.boss_id`; every Rift resolves to one of these.
const BOSS_VARIANTS: Dictionary = {
	&"reaper": preload("res://data/bosses/reaper.tres"),
	&"the_fracture": preload("res://data/bosses/the_fracture.tres"),
	&"cinder_maw": preload("res://data/bosses/cinder_maw.tres"),
	&"hollow_choir": preload("res://data/bosses/hollow_choir.tres"),
	&"reaper_ascended": preload("res://data/bosses/reaper_ascended.tres"),
}
const DEATH_PULSE_TEXTURE: Texture2D = preload("res://assets/art/vfx/06_death_pulse.png")
const COMBO_TIMEOUT: float = 2.2
const TUTORIAL_ENDLESS_DELAY: float = 0.75
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
## The painted stone floor of wisp_rush_arena_background.png in texture UV space (measured from the
## art): the largest rectangle inscribed in its octagon. The playfield is inset to this, so the Wisp
## always rests on stone instead of the void, the scenery or under the HUD.
const ARENA_FLOOR_UV := Rect2(0.145, 0.255, 0.700, 0.515)
## The playfield never shrinks below this fraction of the viewport, whatever the aspect ratio.
const ARENA_MIN_VIEWPORT_FRACTION := Vector2(0.70, 0.50)
## The playfield is inset by this multiple of the Wisp's collision radius, so its sprite stays
## visible at the wall. Defined once here and pushed down: it used to be repeated as a bare 1.35 in
## the player, the tutorial chain and the safe-reform search, which could silently disagree.
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
const HUD_BOSS_TOP: float = 262.0
const HUD_CALLOUT_TOP: float = 440.0
const HUD_FOCUS_TOP: float = 530.0
## World tint over the arena backdrop: calm run, Reaper encounter and the post-Reaper release.
const SHADE_CALM: Color = Color(Palette.VOID_CHARCOAL, 0.14)
const SHADE_BOSS: Color = Color(Palette.VOID_CHARCOAL * 0.8 + Palette.RIFT_MAGENTA * 0.2, 0.5)
const SHADE_VICTORY: Color = Color(Palette.SLATE_TEAL, 0.26)

## Enables the integrated three-step lesson for this run.
@export var tutorial_enabled: bool = true
## Deterministic run seed; zero derives one from the current clock.
@export var run_seed: int = 0
## Pause automatically when the app loses focus or is backgrounded (QA fixtures turn it off).
@export var auto_pause_on_focus_loss: bool = true

var _arena_rect: Rect2 = Rect2()
var _score: int = 0
var _combo: int = 0
var _highest_combo: int = 0
var _total_kills: int = 0
var _multi_kill_dashes: int = 0
var _rapid_ricochets: int = 0
var _soul_shards: int = 0
var _kill_streak: int = 0
var _bosses_defeated: int = 0
var _current_wave: int = 1
var _combo_remaining: float = 0.0
var _focus_remaining: float = 0.0
var _endless_start_remaining: float = -1.0
var _remaining_live_enemies: int = 0
var _run_over: bool = false
var _endless_started: bool = false
var _upgrade_pending: bool = false
var _boss_pending: bool = false
var _post_boss_remaining: float = -1.0
var _boss: ReaperBoss
var _tutorial_step: TutorialStep = TutorialStep.DISABLED
var _last_wall_impact_msec: int = -1
var _kills_by_dash: Dictionary[int, int] = {}
var _rapid_redirect_dashes: Dictionary[int, bool] = {}
var _link_remaining_by_event: Dictionary[int, int] = {}
var _random := RandomNumberGenerator.new()
var _callout_tween: Tween
var _cosmetic_form: FormData
var _rift: RiftData
## Rule twist for the active Rift; `&"none"` is the unmodified Obsidian Garden baseline.
var _rift_rule: StringName = &"none"
## One-based level being played in the active Rift; each boss defeat advances it.
var _rift_level: int = 1
## Deepest level cleared this run, banked into the save through the run summary.
var _rift_levels_cleared: int = 0
## Waves between boss encounters; the Rift overrides the baseline cadence.
var _boss_wave_interval: int = REAPER_WAVE_INTERVAL
## Playfield contraction from the `shrinking_floor` rule; 1.0 is the full painted floor.
var _arena_shrink: float = 1.0
## The active Rift's painted floor in screen space. Empty means fall back to the rectangle.
var _arena_polygon: PackedVector2Array = PackedVector2Array()
## `_arena_polygon` inset by the Wisp's radius: the wall a dash actually lands on.
var _landing_polygon: PackedVector2Array = PackedVector2Array()
## Boss reward multiplier from the `boss_rush` rule.
var _rift_reward_multiplier: float = 1.0
## Permanent Soul Sanctum bonuses resolved once at run start; never changes mid-run.
var _sanctum: SanctumEffects = SanctumEffects.new(null, {})
## Combo grace extended by the Sanctum's Long Chain node.
var _combo_timeout: float = COMBO_TIMEOUT
## The Shattered Rift's linked portal sprites; empty in every other Rift.
var _portals: Array[Sprite2D] = []
## Dash id already teleported, so one dash can never loop between the pair.
var _portal_used_dash_id: int = -1
var _daily_date_key: String = ""
var _vfx: VfxPool
## Splash played where the Wisp hits a wall.
var _wall_splash: WallSplashFx
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
@onready var _shard_count: Label = %ShardCount
@onready var _score_label: Label = %ScoreLabel
@onready var _score_plate: PanelContainer = %ScorePlate
@onready var _form_portrait: TextureRect = %FormPortrait
@onready var _wave_label: Label = %WaveLabel
@onready var _xp_bar: ProgressBar = %XPBar
@onready var _run_level_label: Label = %RunLevelLabel
@onready var _pause_button: Button = %PauseButton
@onready var _combo_label: Label = %ComboLabel
@onready var _focus_label: Label = %FocusLabel
@onready var _instruction_label: Label = %InstructionLabel
@onready var _boss_hud: PanelContainer = %BossHud
@onready var _boss_warning: Label = %BossWarning
@onready var _boss_bar: ProgressBar = %BossBar
@onready var _boss_phase_label: Label = %BossPhaseLabel
@onready var _tutorial_overlay: TutorialOverlay = %TutorialOverlay
@onready var _upgrade_select: UpgradeSelect = %UpgradeSelect
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
	_wave_director.formation_requested.connect(_on_formation_requested)
	_wave_director.wave_started.connect(_on_wave_started)
	_run_progression.experience_changed.connect(_on_experience_changed)
	_run_progression.level_ready.connect(_on_progression_level_ready)
	_run_progression.mutation_applied.connect(_on_mutation_applied)
	_upgrade_select.choice_selected.connect(_on_upgrade_choice_selected)
	_pause_button.pressed.connect(_on_pause_button_pressed)
	_resume_button.pressed.connect(_on_resume_button_pressed)
	_home_button.pressed.connect(_on_home_button_pressed)
	_restart_button.pressed.connect(_on_restart_button_pressed)
	_settings_button.pressed.connect(_open_settings_overlay)
	_confirm_yes_button.pressed.connect(_on_confirm_yes_button_pressed)
	_confirm_cancel_button.pressed.connect(_close_confirm)
	_pause_overlay.visible = false
	_confirm_overlay.visible = false
	_vfx = VfxPool.new()
	_vfx.name = "VfxPool"
	_effects_layer.add_sibling(_vfx)
	_wall_splash = WallSplashFx.new()
	_wall_splash.name = "WallSplashFx"
	# A persistent pool, so a sibling of EffectsLayer like VfxPool - EffectsLayer holds only the
	# transient per-effect nodes (such as Death Pulse), and code counts on that.
	_effects_layer.add_sibling(_wall_splash)
	_wall_splash.setup(_vfx)
	for button: Node in _upgrade_select.find_children("*", "BaseButton", true, false):
		button.set_meta(SoundFx.SKIP_META, true)
	var save_manager := get_node_or_null(^"/root/SaveManager") as SaveManagerService
	if save_manager != null:
		_apply_feel_settings(save_manager.get_settings())
		save_manager.settings_changed.connect(_apply_feel_settings)
	_upgrade_select.visible = false
	_world_shade.color = SHADE_CALM
	_combo_label.visible = false
	_focus_label.visible = false
	_boss_hud.visible = false
	_boss_warning.add_theme_color_override(&"font_color", Palette.RIFT_MAGENTA)
	if _cosmetic_form != null:
		_player.set_cosmetic_form(_cosmetic_form.texture, _cosmetic_form.tint)
		_form_portrait.texture = _cosmetic_form.texture
	_apply_rift()
	_apply_sanctum()
	# Clears per-run rewarded placement locks; a no-op on the shipped build (ADR-0009).
	var monetisation := get_node_or_null(^"/root/Monetisation") as MonetisationService
	if monetisation != null:
		monetisation.begin_run()
	_life_count.text = str(_player.get_current_health())
	_shard_count.text = "0"
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
	_update_endless_start(delta)
	_update_post_boss(delta)
	if _endless_started:
		_wave_director.set_run_context(
			_player.get_current_health(),
			_player.get_maximum_health(),
			_run_progression.get_total_mutation_levels(),
		)
		_wave_director.advance(delta, _remaining_live_enemies)
	if (
		_boss_pending
		and not _upgrade_pending
		and _player.state == WispPlayer.State.WAITING_AT_EDGE
	):
		_start_boss_encounter()
	if (
		_upgrade_pending
		and not _upgrade_select.visible
		and _player.state == WispPlayer.State.WAITING_AT_EDGE
	):
		_open_upgrade_selection()


func _physics_process(_delta: float) -> void:
	if get_tree().paused or _run_over:
		return
	_check_world_contacts()


func _unhandled_input(event: InputEvent) -> void:
	if _upgrade_select.visible:
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


## Returns the current one-based endless wave.
func get_current_wave() -> int:
	return _current_wave


## Returns run Soul Shards earned separately from score.
func get_soul_shards() -> int:
	return _soul_shards


## Returns completed dashes that defeated at least two enemies.
func get_multi_kill_dashes() -> int:
	return _multi_kill_dashes


## Returns Reaper encounters defeated during this run.
func get_bosses_defeated() -> int:
	return _bosses_defeated


## Returns whether the Reaper currently owns encounter flow.
func is_boss_active() -> bool:
	return is_instance_valid(_boss)


## Returns whether the integrated lesson has completed or was disabled.
func is_tutorial_complete() -> bool:
	return _tutorial_step == TutorialStep.DISABLED or _tutorial_step == TutorialStep.COMPLETE


## Adds run XP through the same progression path as enemy rewards.
func add_experience(amount: int) -> void:
	_grant_experience(amount)


## Returns the current run-only level for one mutation identifier.
func get_mutation_level(mutation_id: StringName) -> int:
	return _run_progression.get_mutation_level(mutation_id)


## Supplies persistent cosmetic presentation and optional daily-run identity before play begins.
func configure_run_profile(
	cosmetic_form: FormData,
	daily_date_key: String = "",
	rift: RiftData = null,
	rift_level: int = 1,
	sanctum_levels: Dictionary = {},
) -> void:
	_sanctum = SanctumEffects.new(SANCTUM_CATALOG, sanctum_levels)
	_combo_timeout = COMBO_TIMEOUT + _sanctum.get_value(&"combo_grace_bonus")
	_cosmetic_form = cosmetic_form
	_daily_date_key = daily_date_key
	_rift = rift
	_rift_level = maxi(1, rift_level)
	if is_node_ready() and _cosmetic_form != null:
		_player.set_cosmetic_form(_cosmetic_form.texture, _cosmetic_form.tint)
		_form_portrait.texture = _cosmetic_form.texture
	if is_node_ready():
		_apply_rift()
		_layout_for_viewport()


## Swaps in the active Rift's backdrop and latches its rule twist.
##
## Every Rift background shares the arena's native size, so ARENA_FLOOR_UV stays valid and
## _compute_arena_rect() derives the new playfield from the swapped texture automatically.
func _apply_rift() -> void:
	if _rift == null:
		return
	_rift_rule = _rift.rule_key
	if _rift.background != null:
		_background.texture = _rift.background
	_boss_wave_interval = maxi(1, _rift.waves_per_level)
	_rift_reward_multiplier = 1.0
	_arena_shrink = 1.0
	_build_portals()
	# Reaper's Court trades twice the boss cadence for twice the boss payout.
	if _rift_rule == &"boss_rush":
		_boss_wave_interval = maxi(1, _rift.waves_per_level / 2)
		_rift_reward_multiplier = BOSS_RUSH_REWARD_SCALE
	# Frozen Choir: the Wisp never quite stands still between dashes.
	_player.set_edge_drift(DRIFT_EDGE_SPEED if _rift_rule == &"drift" else 0.0)
	_apply_rift_difficulty()


## Creates or clears the Shattered Rift's linked portal pair.
func _build_portals() -> void:
	for portal: Sprite2D in _portals:
		if is_instance_valid(portal):
			portal.queue_free()
	_portals.clear()
	if _rift == null or _rift_rule != &"portals":
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
	if _rift == null or _rift_rule != &"shrinking_floor":
		return
	# Contract smoothly across the level, then reset when the next level's first wave begins.
	var step: int = posmod(wave - 1, maxi(1, _boss_wave_interval))
	var progress: float = float(step) / float(maxi(1, _boss_wave_interval))
	var shrink: float = lerpf(1.0, SHRINK_FLOOR_MINIMUM, progress)
	if is_equal_approx(shrink, _arena_shrink):
		return
	_arena_shrink = shrink
	_layout_for_viewport()


## Applies permanent Soul Sanctum bonuses once, before the first wave.
##
## Only additive, run-start effects live here. Anything that would mutate a shared tuning Resource
## is applied as a runtime field on the player instead, so the .tres on disk is never changed.
func _apply_sanctum() -> void:
	var bonus_health: int = _sanctum.get_count(&"bonus_max_health")
	if bonus_health > 0:
		_player.increase_maximum_health(bonus_health, bonus_health)
	var invulnerability: float = _sanctum.get_value(&"invulnerability_bonus")
	if invulnerability > 0.0:
		_player.set_bonus_invulnerability(invulnerability)
	_update_player_mutation_stats()
	_update_pickup_attraction()
	var starting: int = _sanctum.get_count(&"starting_mutations")
	for index: int in starting:
		_run_progression.grant_random_mutation()
	_update_player_mutation_stats()


## Pushes the current Rift and level difficulty into the wave director and live enemies.
##
## Called at run start and again after every boss defeat, because clearing a level raises the
## threat multiplier for the rest of the run.
func _apply_rift_difficulty() -> void:
	if _rift == null:
		return
	_wave_director.set_rift_threat_multiplier(_rift.get_threat_multiplier(_rift_level))


## Boss variant for the active Rift, falling back to the Reaper for unknown ids.
func _get_boss_variant() -> BossData:
	var id: StringName = _rift.boss_id if _rift != null else &"reaper"
	if not BOSS_VARIANTS.has(id):
		push_warning("Unknown boss id %s; falling back to the Reaper" % id)
		id = &"reaper"
	return BOSS_VARIANTS[id] as BossData


## Waves between boss encounters in the active Rift.
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


## Handles Android back and Escape: closes the topmost overlay, otherwise toggles pause.
## Always returns true because an active run consumes back presses.
func handle_back() -> bool:
	if _upgrade_select.visible or _run_over:
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
		and is_node_ready()
		and not _run_over
		and not get_tree().paused
	):
		_set_paused(true)


func _exit_tree() -> void:
	_reset_view_effects()
	SoundFx.set_interrupted(false)


func _layout_for_viewport() -> void:
	_arena_rect = _compute_arena_rect()
	for backdrop: Control in [_background, _world_shade]:
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
	# Header (board panel 2): form ring + lives/shards top-left, score plate centred, pause
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
	_instruction_label.offset_top = -(margins.w + 150.0)
	_instruction_label.offset_bottom = -(margins.w + 96.0)
	_tutorial_overlay.set_bottom_inset(margins.w)


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


## The active Rift's painted floor in screen space, contracted by the current shrink.
func _compute_arena_polygon() -> PackedVector2Array:
	if _rift == null or not _rift.has_floor_polygon():
		return PackedVector2Array()
	var polygon: PackedVector2Array = DashGeometry.polygon_from_uv(
		_rift.floor_polygon, _backdrop_image_rect()
	)
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
	if tutorial_enabled:
		_tutorial_step = TutorialStep.FIRST_DASH
		_instruction_label.visible = false
		_tutorial_overlay.show_step(
			"Drag to aim. Release to rush to the opposite edge.",
			1,
			3,
		)
		_wave_label.text = "RIFT 01  •  LESSON"
		print("[Tutorial] lesson 1 ready")
	else:
		_tutorial_step = TutorialStep.DISABLED
		_tutorial_overlay.visible = false
		_start_endless_run()


func _start_endless_run() -> void:
	if _endless_started or _run_over:
		return
	_endless_started = true
	_wave_director.start(run_seed)


func _update_endless_start(delta: float) -> void:
	if _endless_start_remaining < 0.0:
		return
	_endless_start_remaining -= delta
	if _endless_start_remaining <= 0.0:
		_endless_start_remaining = -1.0
		_start_endless_run()


func _update_post_boss(delta: float) -> void:
	if _post_boss_remaining < 0.0:
		return
	_post_boss_remaining -= delta
	if _post_boss_remaining <= 0.0:
		_post_boss_remaining = -1.0
		_world_shade.color = SHADE_CALM
		_wave_director.resume_after_boss()


func _update_boss_target() -> void:
	if is_instance_valid(_boss):
		_boss.set_target_position(_player.global_position)


func _on_wave_started(wave: int, threat_budget: int) -> void:
	_current_wave = wave
	_update_music_state()
	_clear_hazards()
	if wave >= _boss_wave_interval and wave % _boss_wave_interval == 0:
		_wave_director.suspend_for_boss()
		_boss_pending = true
		_wave_label.text = "LEVEL %d  •  REAPER APPROACHING" % _rift_level
		_show_callout("THE REAPER APPROACHES")
		return
	_update_rift_rules(wave)
	_wave_label.text = "LEVEL %d  •  WAVE %02d  •  THREAT %02d" % [
		_rift_level, wave, threat_budget,
	]
	if wave > 1:
		_show_callout("RIFT %02d" % wave)


func _start_boss_encounter() -> void:
	if is_instance_valid(_boss) or _run_over:
		return
	_boss_pending = false
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
	)
	_world_shade.color = SHADE_BOSS
	_boss_hud.visible = true
	_boss_warning.text = variant.display_name
	_show_callout(variant.display_name)
	SoundFx.play(&"reaper_appear")
	_update_music_state()


func _on_reaper_health_changed(current_health: int, maximum_health: int) -> void:
	if _boss_hud.visible and float(current_health) < _boss_bar.value:
		SoundFx.play(&"reaper_hit")
		if current_health <= 0:
			add_trauma(1.0)
			Haptics.pulse(Haptics.HEAVY_MS * 2, 1.0)
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
	shard_reward: int,
	) -> void:
	var victory_duration: float = 1.0
	var experience_reward: int = 0
	if is_instance_valid(_boss):
		victory_duration = _boss.tuning.victory_duration
		experience_reward = _boss.tuning.experience_reward
	_boss = null
	_bosses_defeated += 1
	_update_music_state()
	_score += _apply_velocity_score_bonus(roundi(float(score_reward) * _rift_reward_multiplier))
	_score_label.text = "%06d" % _score
	_award_soul_shards(roundi(float(shard_reward) * _rift_reward_multiplier))
	_grant_experience(experience_reward)
	_clear_enemies()
	_clear_hazards()
	_boss_hud.visible = false
	_rift_levels_cleared = maxi(_rift_levels_cleared, _rift_level)
	if _rift != null and _rift_level < _rift.level_count:
		_rift_level += 1
	_apply_rift_difficulty()
	_wave_label.text = "LEVEL %d CLEARED  •  RIFT DEEPENS" % _rift_levels_cleared
	_world_shade.color = SHADE_VICTORY
	_player.play_victory(victory_duration)
	_post_boss_remaining = victory_duration
	_show_callout("REAPER VANQUISHED  +%d" % score_reward)
	print("[GameWorld] Reaper defeated | count=%d" % _bosses_defeated)


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


## Spawns one enemy, optionally remapped onto the active Rift's roster.
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
	if apply_rift_roster and _rift != null:
		resolved = _rift.substitute_enemy(kind)
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


func _spawn_single_tutorial_target() -> void:
	_spawn_enemy(&"soul_wisp", _arena_rect.get_center(), false)
	print("[Tutorial] lesson 2 target spawned")


func _spawn_tutorial_chain() -> void:
	var far_edge: Vector2
	if _landing_polygon.size() >= 3:
		# Aim across the floor and cast on the landing polygon, so the lesson's third target never
		# sits past the point the dash will really stop at.
		var centre: Vector2 = DashGeometry.polygon_centroid(_landing_polygon)
		var aim: Vector2 = (centre - _player.global_position).normalized()
		far_edge = DashGeometry.ray_to_polygon_edge(
			_player.global_position, aim, _landing_polygon, 2.0
		)
	else:
		var bounds: Rect2 = _arena_rect.grow(-_player.get_collision_radius() * LANDING_INSET)
		var direction: Vector2 = (bounds.get_center() - _player.global_position).normalized()
		far_edge = DashGeometry.ray_to_rect_edge(_player.global_position, direction, bounds)
	for progress: float in [0.27, 0.5, 0.73]:
		_spawn_enemy(&"soul_wisp", _player.global_position.lerp(far_edge, progress), false)
	print("[Tutorial] lesson 3 chain spawned")


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
	if _combo <= 0:
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
	_dash_origin = _player.global_position
	_dash_direction = direction.normalized() if not direction.is_zero_approx() else Vector2.RIGHT
	SoundFx.play(&"dash")
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
	if _tutorial_step == TutorialStep.DISABLED and _instruction_label.modulate.a > 0.0:
		var instruction_tween: Tween = create_tween()
		instruction_tween.tween_property(_instruction_label, "modulate:a", 0.0, 0.45)


## A swipe turned the dash mid-flight: score the leg that ended without touching a wall.
##
## Without this the first leg's kills would sit in `_kills_by_dash` forever - never counted toward a
## multi-kill, never cleared - because only a wall impact resolves a dash.
func _on_player_dash_redirected(_world_position: Vector2, previous_dash_id: int) -> void:
	_redirect_pending = true
	_resolve_completed_dash(previous_dash_id, true)


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
	_advance_tutorial_after_impact(dash_kills)


func _on_player_obstacle_impacted(
		_world_position: Vector2,
		_impact_normal: Vector2,
		dash_id: int,
	) -> void:
	_resolve_completed_dash(dash_id)
	_show_callout("VOID CRYSTAL")
	SoundFx.play(&"wall_impact", 0.8)
	add_trauma(0.35)


func _resolve_completed_dash(dash_id: int, from_redirect: bool = false) -> int:
	var dash_kills: int = _kills_by_dash.get(dash_id, 0)
	_kills_by_dash.erase(dash_id)
	_link_remaining_by_event.erase(dash_id)
	# An empty WALL dash wastes the combo window. An empty redirect leg is a deliberate turn in open
	# floor; decaying the combo for each one would punish exactly the fast play redirect exists for.
	if dash_kills == 0 and _combo > 0 and not from_redirect:
		_combo_remaining *= 0.72
	if dash_kills >= 2:
		_multi_kill_dashes += 1
		var bonus: int = _apply_velocity_score_bonus(dash_kills * dash_kills * 10)
		_score += bonus
		_award_soul_shards(dash_kills / 3)
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


func _advance_tutorial_after_impact(dash_kills: int) -> void:
	match _tutorial_step:
		TutorialStep.FIRST_DASH:
			_tutorial_step = TutorialStep.SINGLE_TARGET
			_tutorial_overlay.show_step(
				"A target is forming. Rush through it when its ring fades.",
				2,
				3,
			)
			_spawn_single_tutorial_target()
		TutorialStep.SINGLE_TARGET:
			if dash_kills < 1:
				return
			_tutorial_step = TutorialStep.CHAIN_TARGETS
			_tutorial_overlay.show_step(
				"Line up all three souls and reap them in one rush.",
				3,
				3,
			)
			_spawn_tutorial_chain()
		TutorialStep.CHAIN_TARGETS:
			if dash_kills >= 3:
				_complete_tutorial()
				return
			_clear_enemies()
			_spawn_tutorial_chain()
			_tutorial_overlay.show_step(
				"One rush, all three. Re-aim through the full soul line.",
				3,
				3,
			)


func _complete_tutorial() -> void:
	_tutorial_step = TutorialStep.COMPLETE
	_tutorial_overlay.show_completion("The edge is yours. Keep the chain alive.")
	_endless_start_remaining = TUTORIAL_ENDLESS_DELAY
	tutorial_completed.emit()
	print("[Tutorial] complete")


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
	_combo_remaining = _combo_timeout
	_score += _apply_velocity_score_bonus(score_reward * _combo)
	if damage_event_id > 0:
		_kills_by_dash[damage_event_id] = _kills_by_dash.get(damage_event_id, 0) + 1
	_remaining_live_enemies = maxi(0, _remaining_live_enemies - 1)
	_spawn_split_children(enemy, world_position)
	SoundFx.multi_kill(int(_kills_by_dash.get(damage_event_id, 1)) if damage_event_id > 0 else 1)
	_play_kill_effects(world_position)
	_update_music_state()
	_grant_experience(experience_reward)
	_score_label.text = "%06d" % _score
	_combo_label.text = "×%d SOUL CHAIN" % _combo
	_style_callout(false)
	_combo_label.visible = _combo >= 2
	if _random.randf() <= enemy.get_shard_drop_chance():
		_spawn_soul_shard(world_position)
	_try_reapers_gift()
	_try_soul_link(enemy, world_position, damage_event_id)
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


func _apply_velocity_score_bonus(base_score: int) -> int:
	var velocity_level: int = _run_progression.get_mutation_level(&"void_velocity")
	return roundi(
		float(base_score)
		* (1.0 + float(velocity_level) * _run_progression.tuning.velocity_score_bonus)
	)


func _spawn_soul_shard(world_position: Vector2) -> void:
	var pickup := SOUL_SHARD_SCENE.instantiate() as SoulShardPickup
	pickup.configure(_player, _get_shard_attraction_radius(), _arena_rect.size.x)
	pickup.position = world_position
	pickup.collected.connect(_on_soul_shard_collected)
	_pickup_layer.add_child(pickup)


func _on_soul_shard_collected(amount: int) -> void:
	_award_soul_shards(amount)
	SoundFx.play(&"shard_pickup")


## Adds run XP with the Sanctum's Rift Scholar bonus applied. Every XP award goes through here.
func _grant_experience(amount: int) -> void:
	if amount <= 0:
		return
	_run_progression.add_experience(
		maxi(1, roundi(float(amount) * _sanctum.get_multiplier(&"experience_bonus")))
	)


func _award_soul_shards(amount: int) -> void:
	if amount <= 0:
		return
	# Shard Finder is applied here, the one place every shard award passes through.
	var granted: int = maxi(1, roundi(float(amount) * _sanctum.get_multiplier(&"shard_find_bonus")))
	_soul_shards += granted
	_shard_count.text = str(_soul_shards)


func _get_shard_attraction_radius() -> float:
	var magnet: float = _sanctum.get_multiplier(&"attraction_bonus")
	var hunger_level: int = _run_progression.get_mutation_level(&"soul_hunger")
	return (
		_run_progression.tuning.shard_attraction_radius
		+ float(hunger_level) * _run_progression.tuning.hunger_attraction_per_level
	) * magnet


func _update_pickup_attraction() -> void:
	if not is_node_ready():
		return
	for child: Node in _pickup_layer.get_children():
		if child is SoulShardPickup:
			(child as SoulShardPickup).configure(
				_player,
				_get_shard_attraction_radius(),
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


func _on_progression_level_ready() -> void:
	_upgrade_pending = true


func _open_upgrade_selection() -> void:
	var choices: Array[MutationData] = _run_progression.offer_choices(3)
	if choices.is_empty():
		_upgrade_pending = false
		return
	_player.cancel_active_aim()
	_upgrade_select.present(choices, _run_progression.get_levels())
	SoundFx.play(&"level_up")
	get_tree().paused = true


func _on_upgrade_choice_selected(mutation_id: StringName) -> void:
	if not _run_progression.apply_choice(mutation_id):
		return
	_upgrade_pending = _run_progression.has_pending_level()
	SoundFx.play(&"upgrade_choice")
	_upgrade_select.dismiss()
	get_tree().paused = false
	_pause_button.grab_focus()


func _on_mutation_applied(mutation_id: StringName, mutation_level: int) -> void:
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
		(1.0 + float(wide_level) * _run_progression.tuning.wide_reap_per_level)
			* _sanctum.get_multiplier(&"blade_width_bonus"),
		(1.0 + float(velocity_level) * _run_progression.tuning.velocity_per_level)
			* _sanctum.get_multiplier(&"dash_speed_bonus"),
	)


func _on_player_health_changed(current_health: int, _maximum_health: int) -> void:
	_life_count.text = str(current_health)


func _on_player_damaged(_current_health: int, _maximum_health: int) -> void:
	_combo = 0
	_combo_remaining = 0.0
	_kill_streak = 0
	_combo_label.visible = false
	_show_callout("SOUL FRACTURED")
	SoundFx.play(&"player_damage")
	add_trauma(0.75)
	Haptics.pulse(Haptics.HEAVY_MS, 0.9)
	_update_music_state()


func _on_player_died() -> void:
	if _run_over:
		return
	_run_over = true
	SoundFx.play(&"player_dissolve")
	SoundFx.music_state(0.0, false)
	_endless_start_remaining = -1.0
	_focus_remaining = 0.0
	_set_world_speed(0.1)
	_pause_button.disabled = true
	var summary: Dictionary = {
		&"score": _score,
		&"kills": _total_kills,
		&"highest_combo": _highest_combo,
		&"wave": _current_wave,
		&"multi_kill_dashes": _multi_kill_dashes,
		&"rapid_ricochets": _rapid_ricochets,
		&"bosses": _bosses_defeated,
		&"soul_shards": _soul_shards,
		&"run_level": _run_progression.get_run_level(),
		&"daily_date": _daily_date_key,
		&"is_daily": not _daily_date_key.is_empty(),
		&"rift": String(_rift.rift_id) if _rift != null else "obsidian_garden",
		&"rift_rule": String(_rift_rule),
		&"rift_level": _rift_level,
		&"rift_levels_cleared": _rift_levels_cleared,
	}
	print(
		"[GameWorld] run ended | score=%d kills=%d wave=%d shards=%d"
		% [_score, _total_kills, _current_wave, _soul_shards]
	)
	run_ended.emit(summary)


func _show_callout(text: String) -> void:
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
	_callout_tween.tween_property(_combo_label, "scale", Vector2.ONE, 0.16).set_trans(
		Tween.TRANS_BACK
	).set_ease(Tween.EASE_OUT)
	_callout_tween.tween_interval(0.65)
	_callout_tween.tween_property(_combo_label, "modulate:a", 0.0, 0.24)
	_callout_tween.tween_callback(func() -> void: _combo_label.visible = false)


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
	if _upgrade_select.visible:
		return
	_player.cancel_active_aim()
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
	_player.set_aim_arrow_enabled(bool(settings.get(&"aim_arrow", true)))
	_shake_strength = clampf(float(settings.get(&"screen_shake", 1.0)), 0.0, 1.0) * (
		REDUCED_MOTION_SHAKE if _reduced_motion else 1.0
	)
	if _shake_strength <= 0.0:
		_trauma = 0.0


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
	if _reduced_motion or Engine.time_scale < 1.0:
		return
	Engine.time_scale = HIT_STOP_TIME_SCALE
	get_tree().create_timer(HIT_STOP_SECONDS, true, false, true).timeout.connect(
		func() -> void: Engine.time_scale = 1.0
	)


func _reset_view_effects() -> void:
	_trauma = 0.0
	Engine.time_scale = 1.0
	_set_view_offset(Vector2.ZERO)


func _update_music_state() -> void:
	var intensity: float = clampf(
		float(_combo) / 12.0 + float(_current_wave - 1) * 0.07,
		0.0,
		1.0,
	)
	SoundFx.music_state(intensity, is_instance_valid(_boss) and not _run_over)


func _get_form_tint() -> Color:
	return _cosmetic_form.tint if _cosmetic_form != null else Palette.SOUL_CYAN


func _play_dash_trail() -> void:
	var radius: float = _player.get_collision_radius()
	var base_scale: float = radius * 4.2 / VFX_SOURCE_SIZE
	_vfx.play(
		DASH_TRAIL_SHORT,
		_dash_origin + _dash_direction * radius * 1.4,
		_dash_direction.angle(),
		Vector2.ONE * base_scale,
		Vector2(base_scale * 1.6, base_scale * 0.7),
		0.22,
		Color(_get_form_tint(), 0.85),
	)


func _play_impact_feedback(world_position: Vector2, inward_normal: Vector2, dash_kills: int) -> void:
	var radius: float = _player.get_collision_radius()
	var tint: Color = _get_form_tint()
	SoundFx.play(&"wall_impact", 1.0 + minf(0.25, float(dash_kills) * 0.05))
	if _dash_origin.distance_to(world_position) >= _arena_rect.size.y * 0.45:
		_vfx.play(
			DASH_TRAIL_LONG,
			world_position - _dash_direction * radius * 3.0,
			_dash_direction.angle(),
			Vector2.ONE * (radius * 5.5 / VFX_SOURCE_SIZE),
			Vector2(radius * 7.5 / VFX_SOURCE_SIZE, radius * 3.0 / VFX_SOURCE_SIZE),
			0.26,
			Color(tint, 0.8),
		)
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
