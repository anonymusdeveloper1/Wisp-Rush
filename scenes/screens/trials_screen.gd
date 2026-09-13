class_name TrialsScreen
extends Control
## Trials: the three persistent goals the player is working on, and the ladder rank they feed.

## The player left the Trials screen.
signal back_requested

var _rank: int = 1
var _progress: Dictionary = {}

@onready var _list: VBoxContainer = %TrialList
@onready var _rank_label: Label = %RankLabel
@onready var _back_button: Button = %BackButton


func _ready() -> void:
	_back_button.pressed.connect(func() -> void: back_requested.emit())
	_apply()


## Rebuilds the active tier from the banked rank and progress.
##
## Safe before or after the screen enters the tree; see RiftMapScreen.setup() for why.
func setup(rank: int, progress: Dictionary) -> void:
	_rank = maxi(1, rank)
	_progress = progress.duplicate()
	if is_node_ready():
		_apply()


func _apply() -> void:
	var complete: bool = TrialTracker.is_ladder_complete(_rank, _progress)
	_rank_label.text = "ALL TRIALS CLEARED" if complete else "RANK %d" % _rank
	_build_rows()


func _build_rows() -> void:
	for child: Node in _list.get_children():
		child.queue_free()
	for trial: TrialData in TrialTracker.get_active_trials(_rank):
		_list.add_child(_build_row(trial))


func _build_row(trial: TrialData) -> Control:
	var banked: int = maxi(0, int(_progress.get(String(trial.trial_id), 0)))
	var done: bool = trial.is_complete(banked)

	var box := VBoxContainer.new()
	box.add_theme_constant_override(&"separation", 8)

	var title := Label.new()
	title.theme_type_variation = &"ValueLabel"
	title.add_theme_font_size_override(&"font_size", 36)
	title.text = "%s%s" % [trial.title, "  ✓" if done else ""]
	box.add_child(title)

	var body := Label.new()
	body.theme_type_variation = &"CaptionLabel"
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.text = trial.description
	box.add_child(body)

	var bar := ProgressBar.new()
	bar.theme_type_variation = &"SlimProgressBar"
	bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	bar.max_value = trial.target
	bar.value = banked
	bar.show_percentage = false
	box.add_child(bar)

	var footer := Label.new()
	footer.theme_type_variation = &"CaptionLabel"
	footer.text = "%d / %d   •   %d SHARDS" % [banked, trial.target, trial.reward_shards]
	box.add_child(footer)

	box.modulate = Color(1.0, 1.0, 1.0, 0.6) if done else Color.WHITE
	return box
