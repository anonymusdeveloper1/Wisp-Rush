class_name Haptics
extends RefCounted
## Settings-gated vibration pulses for touch devices; silently does nothing on desktop.
##
## Durations follow the GDD feel targets: light for launches, medium for multi-reaps, heavy for
## damage and boss beats. The player's Haptics toggle (SaveManager settings) always wins.

const LIGHT_MS: int = 12
const MEDIUM_MS: int = 28
const HEAVY_MS: int = 70


## Vibrates once for `duration_ms` at `amplitude` (0..1) when haptics are enabled on a mobile device.
static func pulse(duration_ms: int, amplitude: float = 0.5) -> void:
	if not OS.has_feature("mobile") or not is_enabled():
		return
	Input.vibrate_handheld(duration_ms, clampf(amplitude, 0.05, 1.0))


## Returns the persisted Haptics setting (true when no SaveManager is available).
static func is_enabled() -> bool:
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null:
		return true
	var save_manager := tree.root.get_node_or_null(^"SaveManager") as SaveManagerService
	return save_manager == null or bool(save_manager.get_settings().get(&"haptics", true))
