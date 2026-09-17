class_name UpgradeTray
extends Control
## Compact bottom card tray offering three mutations while the run keeps going (no pause).
##
## GameWorld calls down: `present` slides the tray up from the bottom (above the safe-area inset and
## any host lift) with three `CardButton` cards, `dismiss` slides it away, `set_suspended` hides it
## under the pause menu. The tray only reports a pick (`choice_selected`, exactly once per
## presentation); banking, calm moments, slow motion and the timeout live in GameWorld
## (docs/systems/mutations.md). The root ignores the mouse so arena swipes outside the panel reach the
## Wisp; the panel stops every touch on it, so a card tap never starts a dash.

## Emitted once per presentation with the picked mutation identifier.
signal choice_selected(mutation_id: StringName)

## Gap in design px between the tray and the screen sides.
const SIDE_MARGIN: float = 12.0
## Design px the hidden tray sits below the screen edge, so its frame never peeks in.
const HIDDEN_OVERSHOOT: float = 24.0

var _choices: Array[MutationData] = []
var _locked: bool = true
var _open: bool = false
var _suspended: bool = false
## 0 = hidden below the screen, 1 = resting above the bottom inset.
var _reveal: float = 0.0
var _bottom_inset: float = 0.0
var _slide_tween: Tween
var _buttons: Array[Button] = []
var _highlights: Array[NinePatchRect] = []
var _icons: Array[TextureRect] = []
var _names: Array[Label] = []
var _descriptions: Array[Label] = []
var _levels: Array[Label] = []

@onready var _panel: MarginContainer = %TrayPanel
@onready var _timeout_bar: ProgressBar = %TimeoutBar


func _ready() -> void:
	_buttons = [%Choice0, %Choice1, %Choice2]
	_highlights = [%Highlight0, %Highlight1, %Highlight2]
	_icons = [%Icon0, %Icon1, %Icon2]
	_names = [%Name0, %Name1, %Name2]
	_descriptions = [%Description0, %Description1, %Description2]
	_levels = [%Level0, %Level1, %Level2]
	for index: int in _buttons.size():
		_buttons[index].pressed.connect(_on_choice_pressed.bind(index))
		# Cards never take focus (focus_mode none), so a keyboard dash can never press one.
		_buttons[index].mouse_entered.connect(_set_highlight.bind(index))
	resized.connect(_apply_layout)
	_panel.minimum_size_changed.connect(_apply_layout)
	visible = false


## Shows [param choices] with their [param current_levels]. Slides up over [param slide_seconds]
## real seconds (0 = appear at once); a tray already up swaps in the new cards and slides them in.
func present(
	choices: Array[MutationData],
	current_levels: Dictionary[StringName, int],
	slide_seconds: float,
) -> void:
	_choices = choices.duplicate()
	_locked = _choices.is_empty()
	_open = true
	for index: int in _buttons.size():
		var available: bool = index < _choices.size()
		_buttons[index].visible = available
		_buttons[index].disabled = not available
		if not available:
			continue
		var mutation: MutationData = _choices[index]
		var current_level: int = current_levels.get(mutation.mutation_id, 0)
		_icons[index].texture = mutation.icon
		_names[index].text = mutation.display_name
		_descriptions[index].text = mutation.get_next_description(current_level)
		_levels[index].text = "LEVEL %d  →  %d" % [current_level, current_level + 1]
	_set_highlight(-1)
	set_timeout_share(1.0)
	visible = not _suspended
	_slide_to(1.0, slide_seconds, true)


## Locks the cards and slides the tray away over [param slide_seconds] real seconds (0 = at once).
func dismiss(slide_seconds: float) -> void:
	_locked = true
	_open = false
	_set_highlight(-1)
	for button: Button in _buttons:
		button.disabled = true
	if not visible or _suspended:
		_slide_to(0.0, 0.0, false)
		visible = false
		return
	_slide_to(0.0, slide_seconds, false)


## Hides the tray under the pause menu ([param suspended] true) and shows it again, fully up, after.
func set_suspended(suspended: bool) -> void:
	if _suspended == suspended:
		return
	_suspended = suspended
	if suspended:
		_kill_slide()
		visible = false
	elif _open:
		visible = true
		_slide_to(1.0, 0.0, false)


## Accepts a visible card by index exactly once per presentation; buttons and checks use it. Refused
## while the cards still slide in, so a quick second tap cannot pick from the next set by accident.
func choose_index(index: int) -> bool:
	if not is_settled() or index < 0 or index >= _choices.size():
		return false
	_locked = true
	for button: Button in _buttons:
		button.disabled = true
	_set_highlight(index)
	choice_selected.emit(_choices[index].mutation_id)
	return true


## Whether cards are presented (sliding in or resting); false once dismissed.
func is_open() -> bool:
	return _open


## Whether the tray rests fully up and accepts a pick.
func is_settled() -> bool:
	return _open and not _locked and not _suspended and is_equal_approx(_reveal, 1.0)


## Currently presented identifiers, for UI and automated verification.
func get_presented_choice_ids() -> Array[StringName]:
	var ids: Array[StringName] = []
	for mutation: MutationData in _choices:
		ids.append(mutation.mutation_id)
	return ids


## Global (canvas) rect of card [param index], for the tutorial hand; empty when not shown.
func get_card_rect(index: int) -> Rect2:
	if index < 0 or index >= _buttons.size() or not _buttons[index].is_visible_in_tree():
		return Rect2()
	return _buttons[index].get_global_rect()


## Design px between the screen bottom and the tray: the HUD safe margin plus any host lift.
func set_bottom_inset(inset: float) -> void:
	_bottom_inset = maxf(0.0, inset)
	_apply_layout()


## Fills the slim timeout bar to [param share] (1 = just presented, 0 = about to slide away).
func set_timeout_share(share: float) -> void:
	_timeout_bar.value = clampf(share, 0.0, 1.0) * _timeout_bar.max_value


func _slide_to(target: float, seconds: float, from_hidden: bool) -> void:
	_kill_slide()
	if from_hidden and seconds > 0.0:
		_set_reveal(0.0)
	if seconds <= 0.0:
		_set_reveal(target)
		if target <= 0.0:
			visible = false
		return
	# Real seconds: the world runs in slow motion while the tray is up.
	_slide_tween = create_tween().set_ignore_time_scale(true)
	_slide_tween.tween_method(_set_reveal, _reveal, target, seconds).set_trans(
		Tween.TRANS_CUBIC
	).set_ease(Tween.EASE_OUT if target > 0.0 else Tween.EASE_IN)
	if target <= 0.0:
		_slide_tween.tween_callback(func() -> void: visible = _open and not _suspended)


func _kill_slide() -> void:
	if _slide_tween != null and _slide_tween.is_valid():
		_slide_tween.kill()
	_slide_tween = null


func _set_reveal(value: float) -> void:
	_reveal = clampf(value, 0.0, 1.0)
	_apply_layout()


func _apply_layout() -> void:
	if not is_node_ready():
		return
	var panel_height: float = _panel.get_combined_minimum_size().y
	var width: float = maxf(0.0, size.x - SIDE_MARGIN * 2.0)
	var rest_y: float = size.y - _bottom_inset - panel_height
	var hidden_y: float = size.y + HIDDEN_OVERSHOOT
	_panel.size = Vector2(width, panel_height)
	_panel.position = Vector2(SIDE_MARGIN, lerpf(hidden_y, rest_y, _reveal))


func _set_highlight(index: int) -> void:
	for card: int in _highlights.size():
		_highlights[card].visible = card == index


func _on_choice_pressed(index: int) -> void:
	choose_index(index)
