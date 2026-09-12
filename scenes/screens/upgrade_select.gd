class_name UpgradeSelect
extends Control
## Always-processing three-card mutation overlay that accepts exactly one choice per presentation.
##
## Cards use the theme's CardButton frame; the focused or hovered card also shows the magenta
## "selected" card frame (redesign v1: magenta = selection) through its Highlight overlay.

## Emitted once with the selected mutation identifier.
signal choice_selected(mutation_id: StringName)

var _choices: Array[MutationData] = []
var _locked: bool = true
var _buttons: Array[Button] = []
var _highlights: Array[NinePatchRect] = []
var _icons: Array[TextureRect] = []
var _names: Array[Label] = []
var _descriptions: Array[Label] = []
var _levels: Array[Label] = []


func _ready() -> void:
	_buttons = [%Choice0, %Choice1, %Choice2]
	_highlights = [%Highlight0, %Highlight1, %Highlight2]
	_icons = [%Icon0, %Icon1, %Icon2]
	_names = [%Name0, %Name1, %Name2]
	_descriptions = [%Description0, %Description1, %Description2]
	_levels = [%Level0, %Level1, %Level2]
	for index: int in _buttons.size():
		_buttons[index].pressed.connect(_on_choice_pressed.bind(index))
		_buttons[index].focus_entered.connect(_set_highlight.bind(index))
		_buttons[index].mouse_entered.connect(_set_highlight.bind(index))
	visible = false


## Opens the overlay with distinct mutation choices and their current run levels.
func present(choices: Array[MutationData], current_levels: Dictionary[StringName, int]) -> void:
	_choices = choices.duplicate()
	_locked = false
	visible = true
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
	if not _choices.is_empty():
		_buttons[0].grab_focus()
		_set_highlight(0)


## Hides and locks the overlay after GameWorld resumes play.
func dismiss() -> void:
	_locked = true
	visible = false
	_set_highlight(-1)


## Selects a visible choice by index; used by buttons and deterministic live checks.
func choose_index(index: int) -> bool:
	if _locked or index < 0 or index >= _choices.size():
		return false
	_locked = true
	for button: Button in _buttons:
		button.disabled = true
	_set_highlight(index)
	choice_selected.emit(_choices[index].mutation_id)
	return true


## Returns the currently displayed identifiers for UI and automated verification.
func get_presented_choice_ids() -> Array[StringName]:
	var ids: Array[StringName] = []
	for mutation: MutationData in _choices:
		ids.append(mutation.mutation_id)
	return ids


func _set_highlight(index: int) -> void:
	for card: int in _highlights.size():
		_highlights[card].visible = card == index


func _on_choice_pressed(index: int) -> void:
	choose_index(index)
