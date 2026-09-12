class_name TutorialOverlay
extends Control
## Non-blocking first-run instruction card owned by GameWorld.

## Card height band in design px: the card spans from (inset + CARD_TOP_GAP) to (inset + CARD_BOTTOM_GAP)
## above the bottom edge, so it clears the home indicator on notched phones.
const CARD_BOTTOM_GAP: float = 91.0
const CARD_TOP_GAP: float = 313.0

var _fade_tween: Tween

@onready var _guide_margin: MarginContainer = $GuideMargin
@onready var _panel: PanelContainer = %Panel
@onready var _step_label: Label = %StepLabel
@onready var _instruction_label: Label = %InstructionLabel


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	visible = false
	modulate.a = 0.0
	_panel.pivot_offset = _panel.size * 0.5


## Positions the card above the bottom safe-area inset (design px, already including GameWorld's
## base margin), so it moves up on phones with a home indicator. Called from GameWorld's HUD layout.
func set_bottom_inset(inset: float) -> void:
	_guide_margin.offset_top = -(inset + CARD_TOP_GAP)
	_guide_margin.offset_bottom = -(inset + CARD_BOTTOM_GAP)


## Displays one tutorial instruction without blocking world input.
func show_step(message: String, step: int, total: int) -> void:
	_step_label.text = "RIFT LESSON  %d / %d" % [step, total]
	_instruction_label.text = message
	_show_card(false)


## Displays a short completion celebration, then dismisses the card.
func show_completion(message: String) -> void:
	_step_label.text = "LESSON COMPLETE"
	_instruction_label.text = message
	_show_card(true)


func _show_card(auto_hide: bool) -> void:
	if _fade_tween != null and _fade_tween.is_valid():
		_fade_tween.kill()
	visible = true
	modulate.a = 0.0
	_panel.scale = Vector2(0.94, 0.94)
	_panel.pivot_offset = _panel.size * 0.5
	_fade_tween = create_tween().set_parallel(true)
	_fade_tween.tween_property(self, "modulate:a", 1.0, 0.18)
	_fade_tween.tween_property(_panel, "scale", Vector2.ONE, 0.24).set_trans(
		Tween.TRANS_BACK
	).set_ease(Tween.EASE_OUT)
	if auto_hide:
		_fade_tween.chain().tween_interval(0.85)
		_fade_tween.chain().tween_property(self, "modulate:a", 0.0, 0.3)
		_fade_tween.chain().tween_callback(func() -> void: visible = false)
