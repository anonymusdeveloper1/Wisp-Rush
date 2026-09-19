class_name FramePacing
extends RefCounted
## Matches the simulation rate to the screen, so motion is smooth on any device.
##
## Godot moves things in [code]_physics_process[/code] at a fixed rate and draws once per screen
## refresh. When the screen refreshes faster than the simulation steps, a position is drawn more than
## once and fast motion — a dash — reads as judder: at 60 Hz physics on a 120 Hz phone every position
## is held for two frames. Stepping the simulation at the screen's own rate gives one fresh position
## per drawn frame, whatever the device does: 60, 90 or 120 Hz.
##
## The textbook alternative is Godot's physics interpolation, which renders in-between positions from
## a fixed 60 Hz simulation and is cheaper. It is not used here because every node animated per frame
## in [code]_process[/code] has to opt out of it, and this project animates the character rigs, arena
## and home ambience, the tutorial hand, the VFX pool and most screens that way — with it enabled the
## rig smoothness contract failed intermittently on Veyra and Ilyra (2026-09-18). Revisit it if the
## per-frame animation ever moves onto the physics tick.

## Never simulate slower than the rate the game was tuned at, nor faster than a phone's battery wants.
const MIN_HZ: int = 60
const MAX_HZ: int = 120


## How often [method poll] re-reads the screen, in seconds.
const POLL_SECONDS: float = 2.0


## Sets the physics tick rate from the screen's refresh rate and returns the rate chosen.
##
## Falls back to [constant MIN_HZ] when the display cannot report a rate, which is what headless runs
## and the automated tests get, so their simulation stays at the tuned, reproducible 60 Hz.
static func match_display() -> int:
	var chosen: int = wanted_rate()
	Engine.physics_ticks_per_second = chosen
	return chosen


## The rate the current screen asks for, clamped to the supported range.
static func wanted_rate() -> int:
	var refresh: float = DisplayServer.screen_get_refresh_rate()
	if refresh <= 0.0:
		return MIN_HZ
	return clampi(int(roundf(refresh)), MIN_HZ, MAX_HZ)


## Re-reads the screen and re-rates the simulation if it changed; returns the new rate, or 0.
##
## Phones with adaptive displays move between refresh rates while the game runs — a Galaxy S24 drops
## to 60 Hz for a static menu and climbs to 120 Hz once something moves — so reading the rate only at
## boot leaves the simulation mismatched for the rest of the session.
static func poll() -> int:
	var chosen: int = wanted_rate()
	if chosen == Engine.physics_ticks_per_second:
		return 0
	Engine.physics_ticks_per_second = chosen
	return chosen
