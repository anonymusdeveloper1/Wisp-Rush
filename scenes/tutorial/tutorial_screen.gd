class_name TutorialScreen
extends Control
## The Tutorial screen: every base mechanic in "show, then you try" lessons, easiest first.
##
## Hosts a GameWorld configured with `RunProfile.tutorial` (the Endless floor template under the
## default skin; no waves, run end or recording) and a TutorialDirector running the lessons of
## `data/tutorial/default_tutorial.tres`. Above the arena sit the step counter with progress dots
## and a one-line caption; the code-drawn ghost hand sits above the HUD too, so it can tap upgrade
## cards. SKIP is always visible and, like Android back and Escape, asks "SKIP THE TUTORIAL?" first. Main decides where `finished` leads (Home on first
## launch, the Rift Map on a replay) and marks the tutorial completed.

## The tutorial ended: every lesson passed ([param skipped] false) or the player confirmed SKIP.
signal finished(skipped: bool)

const GAME_SCENE: PackedScene = preload("res://scenes/gameplay/game_world.tscn")
## Used only when the screen runs without Main (F6): the Endless catalog for the fallback profile.
const FALLBACK_ENDLESS_CATALOG: EndlessCatalog = preload(
	"res://data/endless/default_endless_catalog.tres"
)
## Height in design px of the band holding the step counter and caption, above the bottom margin.
const GUIDE_BAND_HEIGHT: float = 210.0
## Caption pop when it changes: start scale and seconds (skipped under Reduced Motion).
const CAPTION_POP_SCALE: float = 0.94
const CAPTION_POP_SECONDS: float = 0.22

## Lessons, captions, placements and timings.
@export var catalog: TutorialCatalog

var _profile: RunProfile
var _game: GameWorld
var _finished: bool = false
var _paused_by_confirm: bool = false
var _reduced_motion: bool = false
var _caption_tween: Tween

@onready var _director: TutorialDirector = %Director
@onready var _ghost_hand: TutorialGhostHand = %GhostHand
@onready var _skip_button: Button = %SkipButton
@onready var _guide_margin: MarginContainer = %GuideMargin
@onready var _guide_panel: PanelContainer = %GuidePanel
@onready var _step_label: Label = %StepLabel
@onready var _dots: PageDots = %Dots
@onready var _caption_label: Label = %CaptionLabel
@onready var _skip_confirm: Control = %SkipConfirm
@onready var _confirm_dim: ColorRect = %ConfirmDim
@onready var _skip_confirm_button: Button = %SkipConfirmButton
@onready var _skip_cancel_button: Button = %SkipCancelButton


func _ready() -> void:
	_reduced_motion = _read_reduced_motion()
	_confirm_dim.color = Palette.SCRIM
	_skip_confirm.visible = false
	_skip_button.pressed.connect(open_skip_confirm)
	_skip_confirm_button.pressed.connect(_on_skip_confirmed)
	_skip_cancel_button.pressed.connect(close_skip_confirm)
	_director.lesson_started.connect(_on_lesson_started)
	_director.caption_changed.connect(_on_caption_changed)
	_director.completion_started.connect(_on_completion_started)
	_director.completed.connect(_finish.bind(false))
	get_viewport().size_changed.connect(_layout)
	_game = GAME_SCENE.instantiate() as GameWorld
	# The tutorial cannot be lost, so leaving the app never needs the pause menu.
	_game.auto_pause_on_focus_loss = false
	_game.configure_run(_profile if _profile != null else _fallback_profile())
	add_child(_game)
	move_child(_game, 0)
	_layout()
	if catalog == null:
		push_error("TutorialScreen has no TutorialCatalog")
		return
	_director.start.call_deferred(_game, _ghost_hand, catalog, _reduced_motion)
	print("[Tutorial] screen ready | lessons=%d" % catalog.lessons.size())


## Sets the arena profile Main built (`RunProfile.tutorial`); call before adding to the tree.
func setup(profile: RunProfile) -> void:
	_profile = profile


## Android back / Escape: opens the skip confirm, or closes it when it is already open.
func handle_back() -> bool:
	if _finished:
		return true
	if _skip_confirm.visible:
		close_skip_confirm()
	else:
		open_skip_confirm()
	return true


## Shows "SKIP THE TUTORIAL?" and freezes the arena under it.
func open_skip_confirm() -> void:
	if _finished or _skip_confirm.visible:
		return
	_skip_confirm.visible = true
	# Pausing under the confirm clears the aim path and lit enemies, like the run's own pause.
	if is_instance_valid(_game):
		_game.cancel_player_aim()
	_paused_by_confirm = not get_tree().paused
	if _paused_by_confirm:
		get_tree().paused = true
	_skip_cancel_button.grab_focus()


## Closes the confirm and resumes the arena (unless something else had paused it).
func close_skip_confirm() -> void:
	if not _skip_confirm.visible:
		return
	_skip_confirm.visible = false
	if _paused_by_confirm:
		get_tree().paused = false
	_paused_by_confirm = false


## Whether the skip confirm is open.
func is_skip_confirm_open() -> bool:
	return _skip_confirm.visible


## The hosted arena, for tools and fixtures.
func get_game() -> GameWorld:
	return _game


## The lesson director, for tools and fixtures.
func get_director() -> TutorialDirector:
	return _director


func _on_skip_confirmed() -> void:
	print("[Tutorial] skipped at lesson %d" % (_director.get_lesson_index() + 1))
	_finish(true)


func _finish(skipped: bool) -> void:
	if _finished:
		return
	_finished = true
	_director.stop()
	_skip_confirm.visible = false
	_skip_button.disabled = true
	if is_instance_valid(_game):
		_game.set_player_input_enabled(false)
		# A tutorial being left never keeps simulating under the screen transition.
		_game.process_mode = Node.PROCESS_MODE_DISABLED
	# The skip confirm may have paused the tree; the next screen must not inherit it.
	get_tree().paused = false
	finished.emit(skipped)


func _on_lesson_started(index: int, count: int, lesson: TutorialLessonData) -> void:
	_step_label.text = "LESSON %d / %d  •  %s" % [index + 1, count, lesson.title]
	_dots.count = count
	_dots.position_value = float(index)
	var ahead := PackedInt32Array()
	for later: int in range(index + 1, count):
		ahead.append(later)
	_dots.hollow = ahead


func _on_caption_changed(text: String) -> void:
	_caption_label.text = text
	if _reduced_motion:
		return
	if _caption_tween != null and _caption_tween.is_valid():
		_caption_tween.kill()
	_guide_panel.pivot_offset = _guide_panel.size * 0.5
	_guide_panel.scale = Vector2.ONE * CAPTION_POP_SCALE
	_caption_tween = create_tween()
	_caption_tween.tween_property(
		_guide_panel, "scale", Vector2.ONE, CAPTION_POP_SECONDS
	).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _on_completion_started() -> void:
	var count: int = _director.get_lesson_count()
	_step_label.text = "TUTORIAL  •  %d / %d" % [count, count]
	_dots.position_value = float(maxi(0, count - 1))
	_dots.hollow = PackedInt32Array()
	_skip_button.disabled = true


## Lines the SKIP button and guide band up with the HUD's safe margins.
func _layout() -> void:
	if not is_instance_valid(_game):
		return
	var margins: Vector4 = _game.get_safe_margins()
	var skip_size: Vector2 = _skip_button.get_combined_minimum_size()
	_skip_button.offset_left = -(margins.z + skip_size.x)
	_skip_button.offset_right = -margins.z
	_skip_button.offset_top = margins.y
	_skip_button.offset_bottom = margins.y + skip_size.y
	_guide_margin.offset_top = -(margins.w + GUIDE_BAND_HEIGHT)
	_guide_margin.offset_bottom = -margins.w
	# The upgrade card tray slides up above the caption band, so the caption stays readable.
	_game.set_upgrade_tray_lift(GUIDE_BAND_HEIGHT)


func _fallback_profile() -> RunProfile:
	var skin_id: StringName = catalog.arena_skin_id if catalog != null else &""
	return RunProfile.tutorial(
		FALLBACK_ENDLESS_CATALOG, FALLBACK_ENDLESS_CATALOG.get_skin(skin_id), null
	)


func _read_reduced_motion() -> bool:
	var save_manager := get_node_or_null(^"/root/SaveManager") as SaveManagerService
	return save_manager != null and bool(save_manager.get_settings().get(&"reduced_motion", false))
