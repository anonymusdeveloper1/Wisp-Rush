class_name UiJuice
extends RefCounted
## Light UI feedback: buttons dip to 95 % while pressed and spring back on release.

const BOUND_META: StringName = &"ui_juice_bound"
const PRESSED_SCALE := Vector2(0.95, 0.95)


## Adds press feedback once to every button under `root`, except buttons marked with
## `SoundFx.SKIP_META` (they own their presentation, e.g. upgrade cards).
static func bind_press_feedback(root: Node) -> void:
	for node: Node in root.find_children("*", "BaseButton", true, false):
		var button := node as BaseButton
		if button.has_meta(BOUND_META) or button.has_meta(SoundFx.SKIP_META):
			continue
		button.set_meta(BOUND_META, true)
		button.button_down.connect(
			func() -> void: UiJuice._animate(button, PRESSED_SCALE, 0.06, Tween.TRANS_QUAD)
		)
		button.button_up.connect(
			func() -> void: UiJuice._animate(button, Vector2.ONE, 0.16, Tween.TRANS_BACK)
		)


static func _animate(
		button: BaseButton,
		target: Vector2,
		duration: float,
		transition: Tween.TransitionType,
	) -> void:
	if not is_instance_valid(button) or not button.is_inside_tree():
		return
	button.pivot_offset = button.size * 0.5
	var tween: Tween = button.create_tween()
	tween.tween_property(button, "scale", target, duration).set_trans(transition).set_ease(
		Tween.EASE_OUT
	)
