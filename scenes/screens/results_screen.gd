class_name ResultsScreen
extends Control
## End-of-run summary of a finished Endless or daily run.
##
## Redesign v1 layout (handoff board panel 6, STYLE_GUIDE "Results"): the outcome banner (`WAVE w`)
## with the mode and arena name and the depth reward banner when one was paid, the score as a hero
## AmberValueLabel over a code-drawn amber sunburst, personal best on a plate (or NEW BEST), run
## metrics as three icon tiles, the Rift Points breakdown (collected, performance, rewards, then the
## run total and the new balance), then WATCH AD • DOUBLE RP when a rewarded ad is ready (ADR-0029),
## the PLAY AGAIN PrimaryButton above the quieter Home row
## (CHARACTERS stays hidden, as it always has for these runs). All styling comes from the project
## theme's type variations; the few colours drawn in code come from Palette. The `Panel` node keeps
## its path but draws no frame itself.

## Emitted when the player replays the same run profile (PLAY AGAIN, a daily rerun).
signal restart_requested
## Emitted when the player leaves the run flow for Home.
signal home_requested
## Emitted when the player taps CHARACTERS; Main opens the Shop's CHARACTERS tab.
signal wisps_requested
## Emitted when the player taps WATCH AD • DOUBLE RP; Main shows the rewarded ad and banks the bonus.
signal double_rp_requested

## Text shown on the best plate when this run set (or tied) the personal best.
const NEW_BEST_TEXT: String = "NEW BEST"
## Number of rays in the sunburst behind the score (alternating long/short).
const GLOW_RAY_COUNT: int = 20
## Angular width of one ray, in radians.
const GLOW_RAY_WIDTH: float = 0.075
## Horizontal/vertical reach of the long rays, as a factor of the score label's height.
const GLOW_REACH: Vector2 = Vector2(2.0, 0.95)
## Short rays reach this fraction of the long ones.
const GLOW_SHORT_RAY: float = 0.62
## Peak alpha of the rays and of the soft core behind the digits.
const GLOW_RAY_ALPHA: float = 0.42
const GLOW_CORE_ALPHA: float = 0.26
## Breathing pulse of the sunburst (skipped with reduced motion).
const GLOW_PULSE_SPEED: float = 2.4
const GLOW_PULSE_DEPTH: float = 0.14
## Slow sunburst rotation in radians per second (skipped with reduced motion).
const GLOW_SPIN_SPEED: float = 0.06
const GLOW_CORE_SEGMENTS: int = 32
## Tallest the (invisible) Panel may grow on tall phones, in design px. The expanding spacers in
## Content take the extra height (most of it above the buttons), so the info block stays grouped
## near the top and Restart stays low, in thumb reach.
const MAX_LAYOUT_HEIGHT: float = 2000.0

var _summary: Dictionary = {}
var _animation_time: float = 0.0
var _reduced_motion: bool = false

@onready var _safe_margin: MarginContainer = $SafeMargin
@onready var _panel: PanelContainer = $SafeMargin/Center/Panel
@onready var _title: Label = %Title
@onready var _arena_name: Label = %ArenaName
@onready var _unlock_banner: Label = %UnlockBanner
@onready var _score_glow: Control = %ScoreGlow
@onready var _score_value: Label = %ScoreValue
@onready var _best_caption: Label = %BestCaption
@onready var _best_value: Label = %BestValue
@onready var _kills_value: Label = %KillsValue
@onready var _combo_value: Label = %ComboValue
@onready var _wave_value: Label = %WaveValue
@onready var _run_stats: Label = %RunStats
@onready var _collected_value: Label = %CollectedValue
@onready var _performance_value: Label = %PerformanceValue
@onready var _rewards_value: Label = %RewardsValue
@onready var _total_value: Label = %TotalValue
@onready var _balance_value: Label = %BalanceValue
@onready var _restart_button: Button = %RestartButton
@onready var _home_button: Button = %HomeButton
@onready var _forms_button: Button = %FormsButton
@onready var _double_rp_button: Button = %DoubleRpButton


func _ready() -> void:
	_restart_button.pressed.connect(func() -> void: restart_requested.emit())
	_home_button.pressed.connect(func() -> void: home_requested.emit())
	_forms_button.pressed.connect(func() -> void: wisps_requested.emit())
	_double_rp_button.pressed.connect(_on_double_rp_pressed)
	_score_glow.draw.connect(_draw_score_glow)
	_reduced_motion = _read_reduced_motion()
	set_process(not _reduced_motion)
	_apply_safe_area()
	_safe_margin.resized.connect(_fit_height)
	_fit_height()
	_restart_button.grab_focus()
	_apply_summary()
	print("[Results] ready")


func _process(delta: float) -> void:
	_animation_time += delta
	_score_glow.queue_redraw()


## Supplies the completed run values displayed by this screen.
##
## Rift Points keys: `rp_collected` and `rp_performance` from GameWorld, `rp_rewards` (challenges,
## Trials and depth milestones), `rp_earned` (the balance change) and `rift_points_total` from Main.
## Also `mode` from GameWorld and `arena_name` and `depth_reward` from Main.
func setup(run_summary: Dictionary) -> void:
	_summary = run_summary.duplicate(true)
	if is_node_ready():
		_apply_summary()


## Offers the rewarded double (owner 2026-10-05, ADR-0029): the button shows [param amount], the Rift
## Points the ad would add; 0 hides it. Main calls it once a rewarded ad is ready.
func set_double_rp_offer(amount: int) -> void:
	_double_rp_button.visible = amount > 0
	_double_rp_button.disabled = false
	_double_rp_button.text = "WATCH AD  •  DOUBLE RP  %s" % RiftPoints.format_gain(amount)


## After the ad: [param added] Rift Points banked shows the button as done; 0 hides it.
func finish_double_rp(added: int) -> void:
	_double_rp_button.disabled = true
	_double_rp_button.visible = added > 0
	_double_rp_button.text = "DOUBLED  %s" % RiftPoints.format_gain(added)


func _on_double_rp_pressed() -> void:
	_double_rp_button.disabled = true
	double_rp_requested.emit()


## Text of the primary button (PLAY AGAIN).
func get_primary_text() -> String:
	return _restart_button.text


## Rift Points the screen shows as this run's total: the balance change Main measured.
func get_displayed_rp_total() -> int:
	return _displayed_rp_total()


func _apply_summary() -> void:
	if not is_node_ready():
		return
	_apply_outcome()
	var score: int = int(_summary.get(&"score", 0))
	var best: int = int(_summary.get(&"best_score", 0))
	var is_new_best: bool = score > 0 and score >= best
	_score_value.text = "%06d" % score
	_best_caption.visible = not is_new_best
	_best_value.text = NEW_BEST_TEXT if is_new_best else "%06d" % best
	_kills_value.text = str(int(_summary.get(&"kills", 0)))
	_combo_value.text = "×%d" % int(_summary.get(&"highest_combo", 0))
	_wave_value.text = "%02d" % int(_summary.get(&"wave", 1))
	var multi_reaps: int = int(_summary.get(&"multi_kill_dashes", 0))
	var bosses: int = int(_summary.get(&"bosses", 0))
	_run_stats.text = "%d MULTI-REAP%s   •   %d BOSS%s" % [
		multi_reaps,
		"" if multi_reaps == 1 else "S",
		bosses,
		"" if bosses == 1 else "ES",
	]
	_collected_value.text = RiftPoints.format_gain(int(_summary.get(&"rp_collected", 0)))
	_performance_value.text = RiftPoints.format_gain(int(_summary.get(&"rp_performance", 0)))
	_rewards_value.text = RiftPoints.format_gain(int(_summary.get(&"rp_rewards", 0)))
	_total_value.text = RiftPoints.format_gain(_displayed_rp_total())
	_balance_value.text = RiftPoints.format(int(_summary.get(&"rift_points_total", 0)))


func _displayed_rp_total() -> int:
	if _summary.has(&"rp_earned"):
		return maxi(0, int(_summary[&"rp_earned"]))
	return (
		maxi(0, int(_summary.get(&"rp_collected", 0)))
		+ maxi(0, int(_summary.get(&"rp_performance", 0)))
		+ maxi(0, int(_summary.get(&"rp_rewards", 0)))
	)


## Banner, mode and arena name, depth reward banner and the primary button.
func _apply_outcome() -> void:
	_forms_button.visible = false
	var arena_name: String = str(_summary.get(&"arena_name", "")).to_upper()
	var is_endless: bool = str(_summary.get(&"mode", "")) == String(RunProfile.MODE_ENDLESS)
	var mode_name: String = "ENDLESS" if is_endless else "DAILY RUN"
	_arena_name.text = mode_name if arena_name.is_empty() else "%s  •  %s" % [mode_name, arena_name]
	_arena_name.visible = true
	var depth_reward: int = int(_summary.get(&"depth_reward", 0))
	_unlock_banner.text = (
		"DEPTH REWARD  %s" % RiftPoints.format_gain(depth_reward) if depth_reward > 0 else ""
	)
	_unlock_banner.visible = depth_reward > 0
	_title.text = "WAVE %d" % maxi(1, int(_summary.get(&"wave", 1)))
	_restart_button.text = "PLAY AGAIN"


## Soft amber core plus alternating long/short rays, drawn behind the score digits.
func _draw_score_glow() -> void:
	if _score_glow.size.x <= 0.0 or _score_glow.size.y <= 0.0:
		return
	var center: Vector2 = _score_glow.size * 0.5
	var reach: Vector2 = GLOW_REACH * _score_glow.size.y
	var pulse: float = 1.0
	var spin: float = 0.0
	if not _reduced_motion:
		pulse += sin(_animation_time * GLOW_PULSE_SPEED) * GLOW_PULSE_DEPTH
		spin = _animation_time * GLOW_SPIN_SPEED
	var inner := Color(Palette.WARNING_AMBER, GLOW_RAY_ALPHA * pulse)
	var outer := Color(Palette.WARNING_AMBER, 0.0)
	for ray: int in GLOW_RAY_COUNT:
		var angle: float = spin + TAU * float(ray) / float(GLOW_RAY_COUNT)
		var length: float = 1.0 if ray % 2 == 0 else GLOW_SHORT_RAY
		var left := Vector2.from_angle(angle - GLOW_RAY_WIDTH) * reach * length
		var right := Vector2.from_angle(angle + GLOW_RAY_WIDTH) * reach * length
		_score_glow.draw_polygon(
			PackedVector2Array([center, center + left, center + right]),
			PackedColorArray([inner, outer, outer]),
		)
	# Soft core as a triangle fan (one triangle per segment keeps every polygon non-degenerate).
	var core_colors := PackedColorArray([
		Color(Palette.WARNING_AMBER, GLOW_CORE_ALPHA * pulse), outer, outer,
	])
	var core_reach: Vector2 = reach * Vector2(0.62, 0.55)
	for segment: int in GLOW_CORE_SEGMENTS:
		var a: float = TAU * float(segment) / float(GLOW_CORE_SEGMENTS)
		var b: float = TAU * float(segment + 1) / float(GLOW_CORE_SEGMENTS)
		_score_glow.draw_polygon(
			PackedVector2Array([
				center,
				center + Vector2.from_angle(a) * core_reach,
				center + Vector2.from_angle(b) * core_reach,
			]),
			core_colors,
		)


## Stretches the Panel to the safe height (capped) so the spacers can push the buttons down.
func _fit_height() -> void:
	var margins: int = (
		_safe_margin.get_theme_constant(&"margin_top")
		+ _safe_margin.get_theme_constant(&"margin_bottom")
	)
	var available: float = _safe_margin.size.y - float(margins)
	_panel.custom_minimum_size.y = clampf(available, 0.0, MAX_LAYOUT_HEIGHT)


## Reads the player's reduced-motion setting; false when SaveManager is unavailable (F6 runs).
func _read_reduced_motion() -> bool:
	var save_manager: Node = get_node_or_null(^"/root/SaveManager")
	if save_manager == null or not save_manager.has_method(&"get_settings"):
		return false
	var settings: Dictionary = save_manager.call(&"get_settings") as Dictionary
	return bool(settings.get(&"reduced_motion", false))


## Grows SafeMargin by the device's safe-area insets (notches, home indicator) on phones.
func _apply_safe_area() -> void:
	if not OS.has_feature("mobile"):
		return
	var safe_area: Rect2i = DisplayServer.get_display_safe_area()
	var window_size: Vector2i = DisplayServer.window_get_size()
	if safe_area.size.x <= 0 or safe_area.size.y <= 0 or window_size.x <= 0 or window_size.y <= 0:
		return
	var to_view: Vector2 = get_viewport_rect().size / Vector2(window_size)
	var insets: Dictionary[StringName, float] = {
		&"margin_left": float(safe_area.position.x) * to_view.x,
		&"margin_top": float(safe_area.position.y) * to_view.y,
		&"margin_right": float(window_size.x - safe_area.end.x) * to_view.x,
		&"margin_bottom": float(window_size.y - safe_area.end.y) * to_view.y,
	}
	for key: StringName in insets:
		var base: int = _safe_margin.get_theme_constant(key)
		_safe_margin.add_theme_constant_override(key, base + maxi(0, roundi(insets[key])))
