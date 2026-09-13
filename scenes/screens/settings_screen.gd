class_name SettingsScreen
extends Control
## Player settings: volumes, haptics, reduced motion, shake, tutorial replay, about and reset.
##
## Works as a Home-level screen and as an overlay inside the paused run (process mode Always).
## Changes go through the SaveManager autoload, which validates, persists and emits
## `settings_changed`; Audio and GameWorld react to that signal. Slider saves are debounced.
## Styling comes from the project theme (redesign v1): PanelCard groups, SecondaryButton toggles
## whose pressed (cyan) state means ON, and a DangerButton reset behind an armed confirmation.

## Requests leaving Settings (Main returns Home; GameWorld closes its overlay).
signal back_requested
## Emitted after the player confirmed a full progress reset.
signal progress_reset

## Seconds a slider must rest before its value is saved.
const SAVE_DELAY: float = 0.35
## Seconds the reset confirmation stays disarmed so it cannot be pressed by accident.
const RESET_ARM_SECONDS: float = 1.5
## Opacity of the void-charcoal shade over the menu background.
const SHADE_ALPHA: float = 0.4
## Opacity of the dim behind the About and Reset dialogs.
const DIALOG_DIM_ALPHA: float = 0.86
## Back glyph used inside a run, where Back returns to the pause menu rather than Home.
const RUN_BACK_GLYPH: String = "‹"
## Keeps the glyph's line height under the 64 px icon it replaces, so the button stays square.
const RUN_BACK_GLYPH_SIZE: int = 44

## False inside an active run: hides the destructive progress reset.
@export var allow_progress_reset: bool = true

var _pending_changes: Dictionary = {}
var _save_countdown: float = -1.0
var _reset_arm_remaining: float = -1.0

@onready var _groups: VBoxContainer = %Groups
@onready var _shade: ColorRect = %Shade
@onready var _margin: MarginContainer = %Margin
@onready var _back_button: Button = %BackButton
@onready var _music_slider: HSlider = %MusicSlider
@onready var _music_value: Label = %MusicValue
@onready var _sfx_slider: HSlider = %SfxSlider
@onready var _sfx_value: Label = %SfxValue
@onready var _shake_slider: HSlider = %ShakeSlider
@onready var _shake_value: Label = %ShakeValue
@onready var _haptics_toggle: Button = %HapticsToggle
@onready var _reduced_motion_toggle: Button = %ReducedMotionToggle
@onready var _aim_arrow_toggle: Button = %AimArrowToggle
@onready var _tutorial_button: Button = %TutorialButton
@onready var _about_button: Button = %AboutButton
@onready var _reset_button: Button = %ResetButton
@onready var _feedback_label: Label = %FeedbackLabel
@onready var _about_panel: Control = %AboutPanel
@onready var _about_text: Label = %AboutText
@onready var _about_close_button: Button = %AboutCloseButton
@onready var _reset_panel: Control = %ResetPanel
@onready var _reset_confirm_button: Button = %ResetConfirmButton
@onready var _reset_cancel_button: Button = %ResetCancelButton


func _ready() -> void:
	_apply_palette()
	_apply_safe_area()
	if not allow_progress_reset:
		# Inside a run Back leads to the pause menu, so a Home glyph would promise the wrong thing.
		# Pin the square size of the icon version first; text alone would make it narrow and tall.
		_back_button.custom_minimum_size = _back_button.get_combined_minimum_size()
		_back_button.icon = null
		_back_button.text = RUN_BACK_GLYPH
		_back_button.add_theme_font_size_override(&"font_size", RUN_BACK_GLYPH_SIZE)
		_back_button.tooltip_text = "Back to the paused run"
	_back_button.pressed.connect(_on_back_button_pressed)
	_build_developer_card()
	_music_slider.value_changed.connect(
		func(value: float) -> void: _queue_change(&"music_volume", value)
	)
	_sfx_slider.value_changed.connect(
		func(value: float) -> void: _queue_change(&"sfx_volume", value)
	)
	_sfx_slider.drag_ended.connect(func(_changed: bool) -> void: SoundFx.play(&"shard_pickup"))
	_shake_slider.value_changed.connect(
		func(value: float) -> void: _queue_change(&"screen_shake", value)
	)
	_haptics_toggle.toggled.connect(
		func(enabled: bool) -> void: _queue_change(&"haptics", enabled, true)
	)
	_reduced_motion_toggle.toggled.connect(
		func(enabled: bool) -> void: _queue_change(&"reduced_motion", enabled, true)
	)
	_aim_arrow_toggle.toggled.connect(
		func(enabled: bool) -> void: _queue_change(&"aim_arrow", enabled, true)
	)
	_tutorial_button.pressed.connect(_on_tutorial_button_pressed)
	_about_button.pressed.connect(_on_about_button_pressed)
	_about_close_button.pressed.connect(_close_panels)
	_reset_button.pressed.connect(_on_reset_button_pressed)
	_reset_confirm_button.pressed.connect(_on_reset_confirm_button_pressed)
	_reset_cancel_button.pressed.connect(_close_panels)
	_reset_button.visible = allow_progress_reset
	_about_text.text = build_about_text()
	_about_panel.visible = false
	_reset_panel.visible = false
	_feedback_label.text = ""
	var save_manager: SaveManagerService = _get_save_manager()
	if save_manager != null:
		setup(save_manager.get_settings())
	_refresh_labels()
	_back_button.grab_focus()
	print("[Settings] ready | reset_allowed=%s" % allow_progress_reset)


func _process(delta: float) -> void:
	if _save_countdown >= 0.0:
		_save_countdown -= delta
		if _save_countdown < 0.0:
			_flush_changes()
	if _reset_arm_remaining >= 0.0:
		_reset_arm_remaining = maxf(0.0, _reset_arm_remaining - delta)
		_update_reset_arming()


func _exit_tree() -> void:
	_flush_changes()


## Shows `settings` in the controls without triggering saves.
func setup(settings: Dictionary) -> void:
	if not is_node_ready():
		return
	_music_slider.set_value_no_signal(float(settings.get(&"music_volume", _music_slider.value)))
	_sfx_slider.set_value_no_signal(float(settings.get(&"sfx_volume", _sfx_slider.value)))
	_shake_slider.set_value_no_signal(float(settings.get(&"screen_shake", _shake_slider.value)))
	_haptics_toggle.set_pressed_no_signal(bool(settings.get(&"haptics", true)))
	_reduced_motion_toggle.set_pressed_no_signal(bool(settings.get(&"reduced_motion", false)))
	_aim_arrow_toggle.set_pressed_no_signal(bool(settings.get(&"aim_arrow", true)))
	_refresh_labels()


## Closes an open panel first; returns false when the host should leave Settings.
func handle_back() -> bool:
	if _about_panel.visible or _reset_panel.visible:
		_close_panels()
		return true
	_flush_changes()
	return false


## Returns the Privacy & About copy shown by this screen.
static func build_about_text() -> String:
	var version: String = str(ProjectSettings.get_setting("application/config/version", "0.1.0"))
	var engine_version: String = Engine.get_version_info()["string"]
	return "\n".join([
		"WISP RUSH  •  VERSION %s" % version,
		"",
		"PRIVACY",
		"Wisp Rush plays fully offline. It has no accounts, ads, analytics or tracking and never "
		+ "sends data anywhere. Your progress and settings are stored only on this device; "
		+ "Reset Progress erases them.",
		"",
		"CREDITS",
		"Illustrations from the Wisp Rush asset pack. Sound is synthesized in-game.",
		"Made with Godot Engine %s (© Godot Engine contributors, MIT licence)." % engine_version,
	])


func _queue_change(key: StringName, value: Variant, immediate: bool = false) -> void:
	_pending_changes[key] = value
	_refresh_labels()
	if key == &"music_volume" or key == &"sfx_volume":
		var audio: AudioService = SoundFx.audio()
		if audio != null:
			audio.apply_settings({key: value})
	if immediate:
		_flush_changes()
	else:
		_save_countdown = SAVE_DELAY


func _flush_changes() -> void:
	if _pending_changes.is_empty():
		return
	var save_manager: SaveManagerService = _get_save_manager()
	if save_manager != null:
		save_manager.update_settings(_pending_changes)
	_pending_changes = {}
	_save_countdown = -1.0


func _refresh_labels() -> void:
	_music_value.text = "%d%%" % roundi(_music_slider.value * 100.0)
	_sfx_value.text = "%d%%" % roundi(_sfx_slider.value * 100.0)
	_shake_value.text = "%d%%" % roundi(_shake_slider.value * 100.0)
	# The pressed (cyan-lit) frame is the ON state; the word repeats it so hue is never the only cue.
	_haptics_toggle.text = "ON" if _haptics_toggle.button_pressed else "OFF"
	_reduced_motion_toggle.text = "ON" if _reduced_motion_toggle.button_pressed else "OFF"
	_aim_arrow_toggle.text = "ON" if _aim_arrow_toggle.button_pressed else "OFF"


func _update_reset_arming() -> void:
	var armed: bool = _reset_arm_remaining <= 0.0
	_reset_confirm_button.disabled = not armed
	_reset_confirm_button.text = (
		"ERASE EVERYTHING"
		if armed
		else "ERASE EVERYTHING  (%d)" % ceili(_reset_arm_remaining)
	)
	if armed:
		_reset_arm_remaining = -1.0


func _close_panels() -> void:
	_about_panel.visible = false
	_reset_panel.visible = false
	_reset_arm_remaining = -1.0
	_back_button.grab_focus()


func _apply_palette() -> void:
	_shade.color = Color(Palette.VOID_CHARCOAL, SHADE_ALPHA)
	_feedback_label.add_theme_color_override(&"font_color", Palette.SOUL_CYAN)
	for dialog: Control in [_about_panel, _reset_panel]:
		var dim := dialog.get_node(^"Dim") as ColorRect
		dim.color = Color(Palette.VOID_CHARCOAL, DIALOG_DIM_ALPHA)


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
		var base: int = _margin.get_theme_constant(key)
		_margin.add_theme_constant_override(key, base + maxi(0, roundi(insets[key])))


func _get_save_manager() -> SaveManagerService:
	if not is_inside_tree():
		return null
	return get_tree().root.get_node_or_null(^"SaveManager") as SaveManagerService


func _on_back_button_pressed() -> void:
	_flush_changes()
	back_requested.emit()


func _on_tutorial_button_pressed() -> void:
	var save_manager: SaveManagerService = _get_save_manager()
	if save_manager != null:
		save_manager.reset_tutorial()
	_feedback_label.text = "THE LESSON WILL PLAY ON YOUR NEXT RUN"


func _on_about_button_pressed() -> void:
	_about_panel.visible = true
	_about_close_button.grab_focus()


func _on_reset_button_pressed() -> void:
	_reset_panel.visible = true
	_reset_arm_remaining = RESET_ARM_SECONDS
	_update_reset_arming()
	_reset_cancel_button.grab_focus()


func _on_reset_confirm_button_pressed() -> void:
	if _reset_confirm_button.disabled:
		return
	_pending_changes = {}
	var save_manager: SaveManagerService = _get_save_manager()
	if save_manager != null:
		save_manager.reset_save()
		setup(save_manager.get_settings())
	_close_panels()
	_feedback_label.text = "ALL PROGRESS ERASED"
	progress_reset.emit()


## Appends a developer card that unlocks progression, in debug builds only.
##
## GDD §13 forbids debug panels in a release, so this returns immediately unless SaveManager says
## debug tools are allowed — and every action it calls refuses independently as well.
func _build_developer_card() -> void:
	var save := get_node_or_null(^"/root/SaveManager") as SaveManagerService
	if save == null or not save.debug_tools_allowed():
		return

	var card := PanelContainer.new()
	card.theme_type_variation = &"PanelCard"
	var rows := VBoxContainer.new()
	rows.add_theme_constant_override(&"separation", 10)
	card.add_child(rows)

	var caption := Label.new()
	caption.theme_type_variation = &"CaptionLabel"
	caption.text = "DEVELOPER  •  DEBUG BUILD ONLY"
	rows.add_child(caption)

	# label, tooltip, action
	var actions: Array[Array] = [
		["UNLOCK EVERYTHING", "Rifts, forms, Sanctum, Trials and shards",
			func() -> bool: return DevUnlock.unlock_everything(save)],
		["UNLOCK ALL RIFTS", "Raises the lifetime best wave past every gate",
			func() -> bool: return DevUnlock.unlock_rifts(save)],
		["UNLOCK ALL FORMS", "Owns all six cosmetic forms",
			func() -> bool: return DevUnlock.unlock_forms(save)],
		["MAX SOUL SANCTUM", "Every node at its maximum level",
			func() -> bool: return DevUnlock.max_sanctum(save)],
		["COMPLETE ALL TRIALS", "Finishes the whole ladder",
			func() -> bool: return DevUnlock.complete_trials(save)],
		["+%d SHARDS" % DevUnlock.SHARD_GRANT, "Adds Soul Shards",
			func() -> bool: return DevUnlock.grant_shards(save)],
	]
	for action: Array in actions:
		var button := Button.new()
		button.theme_type_variation = &"SecondaryButton"
		button.text = action[0] as String
		button.tooltip_text = action[1] as String
		button.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		var run: Callable = action[2] as Callable
		var label: String = action[0] as String
		button.pressed.connect(func() -> void: _on_developer_action(label, run))
		rows.add_child(button)

	_groups.add_child(card)
	UiJuice.bind_press_feedback(card)
	SoundFx.bind_buttons(card)


func _on_developer_action(label: String, run: Callable) -> void:
	var applied: bool = bool(run.call())
	_feedback_label.add_theme_color_override(
		&"font_color", Palette.SOUL_CYAN if applied else Palette.WARNING_AMBER
	)
	_feedback_label.text = "%s %s" % [label, "APPLIED" if applied else "REFUSED"]
