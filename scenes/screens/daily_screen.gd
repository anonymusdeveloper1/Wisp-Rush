class_name DailyScreen
extends Control
## Offline daily-run screen: today's portal, arena and seed, best, three local goal rows and Play.
##
## The daily run plays on Endless rules in the arena of the day, which the seed line names.
##
## Layout follows the redesign v1 handoff board (Daily Rift panel) and styles everything through
## theme type variations (docs/systems/ui_design_system.md). Each goal row is the scene's
## `ChallengeLabel<n>` Label, whose text is the goal title (tests read it at
## Margin/Content/Challenges/ChallengeLabel<n>). The row frame (icon, description, slim bar,
## "x / y" and a Rift Points reward plate) is built in code as the label's child and drawn behind it
## with `show_behind_parent`: a tab stop indents the title into the frame's text column and the
## frame reaches above the label by its top content margin, so the title sits inside the frame.
## Goal states differ in wording and shading, not in hue alone: in progress ("12 / 25"),
## complete (amber "COMPLETE", reward still pending) and claimed (cyan "CLAIMED", row dimmed).

## Requests today's seeded run through Main.
signal play_daily_requested(date_key: String, seed: int)
## Requests return to the Home screen.
signal back_requested

## Vertical gap between two goal row frames (design px).
const ROW_GAP: int = 16
## Gap between a row's icon, text column and reward plate (design px).
const ROW_SEPARATION: int = 20
## Square size of a goal row's icon (design px).
const GOAL_ICON_SIZE: float = 84.0
## Square size of the Rift Points icon inside a reward plate (design px).
const REWARD_ICON_SIZE: float = 40.0
## Font size of a goal row's description line.
const DESCRIPTION_FONT_SIZE: int = 28
## Font size of the "x / y" / state text in a goal row.
const COUNT_FONT_SIZE: int = 32
## Font size of a goal row's reward value.
const REWARD_FONT_SIZE: int = 34
## Font size of the daily completion bonus line in the portal card.
const DAILY_BONUS_FONT_SIZE: int = 30
## Opacity of the void shade over the menu background.
const SHADE_ALPHA: float = 0.35
## Opacity of icons and reward plates whose reward was already claimed.
const CLAIMED_ALPHA: float = 0.45

const _RP_ICON: Texture2D = preload("res://assets/art/ui/system/02_soul_shards.png")
const _FALLBACK_GOAL_ICON: Texture2D = preload("res://assets/art/ui/system/13_daily.png")
const _GOAL_ICONS: Dictionary[StringName, Texture2D] = {
	&"kills": preload("res://assets/art/ui/system/18_reaper.png"),
	&"multi_kill_dashes": preload("res://assets/art/ui/system/05_play.png"),
	&"wave": preload("res://assets/art/ui/system/13_daily.png"),
	&"highest_combo": preload("res://assets/art/ui/system/03_combo_chain.png"),
	&"rp_collected": preload("res://assets/art/ui/system/02_soul_shards.png"),
	&"bosses": preload("res://assets/art/ui/system/18_reaper.png"),
	&"rapid_ricochets": preload("res://assets/art/ui/system/07_restart.png"),
}
const _MONTHS: Array[String] = [
	"JANUARY", "FEBRUARY", "MARCH", "APRIL", "MAY", "JUNE",
	"JULY", "AUGUST", "SEPTEMBER", "OCTOBER", "NOVEMBER", "DECEMBER",
]

var _date_key: String = ""
var _seed: int = 1
## Display name of today's arena skin; empty hides it from the seed line.
var _arena_name: String = ""
var _snapshot: Dictionary = {}
var _row_top_margin: float = 0.0
var _row_frames: Array[PanelContainer] = []
var _row_icons: Array[TextureRect] = []
var _row_descriptions: Array[Label] = []
var _row_bars: Array[ProgressBar] = []
var _row_counts: Array[Label] = []
var _row_plates: Array[PanelContainer] = []
var _row_rewards: Array[Label] = []

@onready var _shade: ColorRect = $Shade
@onready var _safe_margin: MarginContainer = $Margin
@onready var _challenges: VBoxContainer = $Margin/Content/Challenges
@onready var _date_label: Label = %DateLabel
@onready var _seed_label: Label = %SeedLabel
@onready var _best_label: Label = %BestLabel
@onready var _reward_label: Label = %RewardLabel
@onready var _reward_icon: TextureRect = %RewardIcon
@onready var _challenge_labels: Array[Label] = [
	%ChallengeLabel0,
	%ChallengeLabel1,
	%ChallengeLabel2,
]
@onready var _play_button: Button = %PlayButton
@onready var _back_button: Button = %BackButton


func _ready() -> void:
	_shade.color = Color(Palette.VOID_CHARCOAL, SHADE_ALPHA)
	_apply_safe_area()
	for label: Label in _challenge_labels:
		_build_goal_row(label)
	# The frames reach _row_top_margin above their labels, so the gap has to cover that overhang.
	_challenges.add_theme_constant_override(&"separation", roundi(_row_top_margin) + ROW_GAP)
	_reward_label.add_theme_font_size_override(&"font_size", DAILY_BONUS_FONT_SIZE)
	_play_button.pressed.connect(
		func() -> void: play_daily_requested.emit(_date_key, _seed)
	)
	_back_button.pressed.connect(func() -> void: back_requested.emit())
	_apply_snapshot()
	_play_button.grab_focus()
	print("[Daily] ready | date=%s seed=%d" % [_date_key, _seed])


## Supplies today's identity, the arena of the day and all persistent progress used by the screen.
func setup(date_key: String, seed: int, snapshot: Dictionary, arena_name: String = "") -> void:
	_date_key = date_key
	_seed = maxi(1, seed)
	_arena_name = arena_name
	_snapshot = snapshot.duplicate(true)
	if is_node_ready():
		_apply_snapshot()


func _apply_snapshot() -> void:
	if not is_node_ready():
		return
	_date_label.text = _format_date(_date_key)
	_seed_label.text = "RIFT SEED  ·  %010d" % _seed
	if not _arena_name.is_empty():
		_seed_label.text = "%s  ·  SEED %010d" % [_arena_name.to_upper(), _seed]
	var daily_state: Dictionary = _snapshot.get(&"daily_state", {}) as Dictionary
	var best_scores: Dictionary = daily_state.get(&"best_scores", {}) as Dictionary
	var completed_dates: Array = daily_state.get(&"completed_dates", []) as Array
	_best_label.text = _group_digits(int(best_scores.get(_date_key, 0)))
	var bonus_claimed: bool = _date_key in completed_dates
	_reward_label.text = (
		"DAILY BONUS CLAIMED"
		if bonus_claimed
		else "%s FOR FINISHING TODAY'S RIFT" % RiftPoints.format_gain(
			ChallengeTracker.DAILY_COMPLETION_REWARD
		)
	)
	_reward_label.theme_type_variation = &"CaptionLabel" if bonus_claimed else &"AmberValueLabel"
	_reward_icon.modulate = Color(1.0, 1.0, 1.0, CLAIMED_ALPHA if bonus_claimed else 1.0)

	var challenge_state: Dictionary = _snapshot.get(&"challenge_state", {}) as Dictionary
	var date_state: Dictionary = challenge_state.get(_date_key, {}) as Dictionary
	var progress: Dictionary = date_state.get(&"progress", {}) as Dictionary
	var claimed: Array = date_state.get(&"claimed", []) as Array
	var definitions: Array[Dictionary] = ChallengeTracker.get_challenges(_date_key)
	for index: int in mini(definitions.size(), _challenge_labels.size()):
		var definition: Dictionary = definitions[index]
		var challenge_id: String = str(definition[&"id"])
		var current: int = maxi(0, int(progress.get(challenge_id, 0)))
		_apply_goal(index, definition, current, challenge_id in claimed)
	for index: int in _challenge_labels.size():
		_fit_goal_row(_challenge_labels[index], _row_frames[index])


## Fills goal row [param index] and shows its in-progress, complete or claimed state.
func _apply_goal(index: int, definition: Dictionary, current: int, is_claimed: bool) -> void:
	var target: int = maxi(1, int(definition[&"target"]))
	var shown: int = mini(target, current)
	var is_complete: bool = is_claimed or shown >= target
	var label: Label = _challenge_labels[index]
	label.text = "\t%s" % str(definition[&"title"])
	label.self_modulate = Palette.TEXT_MUTED if is_claimed else Color.WHITE
	var metric: StringName = StringName(str(definition.get(&"metric", "")))
	_row_icons[index].texture = _GOAL_ICONS.get(metric, _FALLBACK_GOAL_ICON)
	_row_icons[index].modulate = Color(1.0, 1.0, 1.0, CLAIMED_ALPHA if is_claimed else 1.0)
	_row_descriptions[index].text = str(definition[&"description"])
	_row_bars[index].max_value = float(target)
	_row_bars[index].value = float(target if is_complete else shown)
	var count: Label = _row_counts[index]
	count.remove_theme_color_override(&"font_color")
	if is_claimed:
		count.text = "CLAIMED"
		count.theme_type_variation = &"ValueLabel"
		count.add_theme_color_override(&"font_color", Palette.SOUL_CYAN)
	elif is_complete:
		count.text = "COMPLETE"
		count.theme_type_variation = &"AmberValueLabel"
	else:
		count.text = "%d / %d" % [shown, target]
		count.theme_type_variation = &"ValueLabel"
	_row_rewards[index].text = RiftPoints.format_gain(int(definition[&"reward"]))
	_row_plates[index].modulate = Color(1.0, 1.0, 1.0, CLAIMED_ALPHA if is_claimed else 1.0)


## Builds the framed row behind [param label]; the label keeps drawing the goal title.
func _build_goal_row(label: Label) -> void:
	label.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var frame := PanelContainer.new()
	frame.name = &"Row"
	frame.show_behind_parent = true
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_child(frame)
	var style: StyleBox = frame.get_theme_stylebox(&"panel")
	_row_top_margin = style.get_margin(SIDE_TOP)
	frame.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	frame.offset_top = -_row_top_margin
	frame.grow_vertical = Control.GROW_DIRECTION_END
	label.tab_stops = PackedFloat32Array(
		[style.get_margin(SIDE_LEFT) + GOAL_ICON_SIZE + float(ROW_SEPARATION)]
	)

	var row := HBoxContainer.new()
	row.add_theme_constant_override(&"separation", ROW_SEPARATION)
	frame.add_child(row)
	var icon := _make_icon(_FALLBACK_GOAL_ICON, GOAL_ICON_SIZE)
	row.add_child(icon)

	var column := VBoxContainer.new()
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	column.add_theme_constant_override(&"separation", 4)
	row.add_child(column)
	var title_space := Control.new()
	title_space.custom_minimum_size.y = float(label.get_line_height())
	title_space.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_child(title_space)
	var description := Label.new()
	description.theme_type_variation = &"CaptionLabel"
	description.add_theme_font_size_override(&"font_size", DESCRIPTION_FONT_SIZE)
	description.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	column.add_child(description)
	var bar_row := HBoxContainer.new()
	bar_row.add_theme_constant_override(&"separation", 14)
	column.add_child(bar_row)
	var bar := ProgressBar.new()
	bar.theme_type_variation = &"SlimProgressBar"
	bar.show_percentage = false
	bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bar_row.add_child(bar)
	var count := Label.new()
	count.theme_type_variation = &"ValueLabel"
	count.add_theme_font_size_override(&"font_size", COUNT_FONT_SIZE)
	count.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	bar_row.add_child(count)

	var plate := PanelContainer.new()
	plate.theme_type_variation = &"PanelPlate"
	plate.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	plate.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(plate)
	var plate_row := HBoxContainer.new()
	plate_row.add_theme_constant_override(&"separation", 8)
	plate.add_child(plate_row)
	plate_row.add_child(_make_icon(_RP_ICON, REWARD_ICON_SIZE))
	var reward := Label.new()
	reward.theme_type_variation = &"AmberValueLabel"
	reward.add_theme_font_size_override(&"font_size", REWARD_FONT_SIZE)
	reward.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	plate_row.add_child(reward)

	frame.minimum_size_changed.connect(_fit_goal_row.bind(label, frame))
	_row_frames.append(frame)
	_row_icons.append(icon)
	_row_descriptions.append(description)
	_row_bars.append(bar)
	_row_counts.append(count)
	_row_plates.append(plate)
	_row_rewards.append(reward)


## Sizes [param label] so its row frame (which starts _row_top_margin above it) fits exactly.
func _fit_goal_row(label: Label, frame: PanelContainer) -> void:
	label.custom_minimum_size.y = maxf(0.0, frame.get_combined_minimum_size().y - _row_top_margin)


## Grows Margin by the device's safe-area insets (notches, home indicator) on phones.
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


static func _make_icon(texture: Texture2D, size: float) -> TextureRect:
	var icon := TextureRect.new()
	icon.texture = texture
	icon.custom_minimum_size = Vector2(size, size)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return icon


## Turns a YYYY-MM-DD key into "SEPTEMBER 11, 2026"; unknown shapes are shown unchanged.
static func _format_date(date_key: String) -> String:
	var parts: PackedStringArray = date_key.split("-")
	if parts.size() != 3 or not parts[1].is_valid_int() or not parts[2].is_valid_int():
		return date_key
	var month: int = parts[1].to_int()
	if month < 1 or month > _MONTHS.size():
		return date_key
	return "%s %d, %s" % [_MONTHS[month - 1], parts[2].to_int(), parts[0]]


## Formats a non-negative score with thousands separators ("8,420").
static func _group_digits(value: int) -> String:
	var digits: String = str(maxi(0, value))
	var grouped: String = ""
	while digits.length() > 3:
		grouped = "," + digits.right(3) + grouped
		digits = digits.left(digits.length() - 3)
	return digits + grouped
