class_name SoundFx
extends RefCounted
## Null-safe shortcuts to the `Audio` autoload so gameplay and UI code never crash without audio.
##
## Effect ids and music layers are documented in docs/systems/audio.md.

const BOUND_META: StringName = &"sound_fx_bound"
## Buttons carrying this meta key stay silent when bound (they play their own sound).
const SKIP_META: StringName = &"sound_fx_skip"


## Returns the Audio autoload, or null when it is not registered (e.g. isolated tests).
static func audio() -> AudioService:
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null:
		return null
	return tree.root.get_node_or_null(^"Audio") as AudioService


## Plays one synthesized effect by id.
static func play(id: StringName, pitch_scale: float = 1.0, volume_db: float = 0.0) -> void:
	var service: AudioService = audio()
	if service != null:
		service.play_sfx(id, pitch_scale, volume_db)


## Plays the stepped slice for the `step`-th kill of one dash (1 = first kill).
static func multi_kill(step: int) -> void:
	var service: AudioService = audio()
	if service != null:
		service.play_multi_kill(step)


## Sets the music layering: `intensity` 0..1 fades in the pulse, `boss` toggles the boss layer.
static func music_state(intensity: float, boss: bool) -> void:
	var service: AudioService = audio()
	if service != null:
		service.set_music_intensity(intensity)
		service.set_boss_music(boss)


## Ducks music during pause overlays and app interruptions.
static func set_interrupted(interrupted: bool) -> void:
	var service: AudioService = audio()
	if service != null:
		service.set_interrupted(interrupted)


## Connects a UI click to every button under `root` once: Back/Home/Close/Cancel buttons play
## `ui_back`, all others `ui_confirm`.
static func bind_buttons(root: Node) -> void:
	for node: Node in root.find_children("*", "BaseButton", true, false):
		var button := node as BaseButton
		if button.has_meta(BOUND_META) or button.has_meta(SKIP_META):
			continue
		button.set_meta(BOUND_META, true)
		var sound: StringName = &"ui_back" if _is_back_button(button.name) else &"ui_confirm"
		button.pressed.connect(func() -> void: SoundFx.play(sound))


static func _is_back_button(button_name: String) -> bool:
	for word: String in ["Back", "Home", "Close", "Cancel"]:
		if word in button_name:
			return true
	return false
