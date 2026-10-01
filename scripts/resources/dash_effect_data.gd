class_name DashEffectData
extends Resource
## One character's dash signature: the shape, colour and weight of the streak its dash leaves.
##
## Cosmetic only. Nothing here reaches dash speed, corridor width, the hitbox, timing, damage or
## scoring (GDD §9) — it decides what the launch and the flight look like and nothing else. A
## character without one falls back to the shared dash-style trail, so this is additive.
##
## It carries no art. [DashEffectFx] builds every signature from a [Line2D] ribbon, pooled
## [CPUParticles2D] sparks and the two dash-trail textures the game already ships, with the
## gradients and curves generated in code.

## The shape a dash draws. Each one is a different read at a glance, not a recolour.
enum Signature {
	RIBBON, ## One clean tapering streak along the travel line.
	BLADE_ARC, ## A single narrow cut, long and thin — a sword stroke.
	TWIN_ARC, ## Two ribbons bowed apart, one per hand: twin fan slashes.
	DUST_WAKE, ## A thin streak trailing a broad fan of slow dust.
	RUNE_WAKE, ## A streak with sparks that lag behind and tumble.
	SOUL_FLARE, ## A short bright streak with a radial burst at the launch point.
}

## Hues a saturated tint must stay clear of, so a dash never reads as a telegraph or an enemy.
## Mirrors [DashStyleData], which applied the same rule to the retired purchasable styles.
const RESERVED_HUES: Array[Color] = [Palette.WARNING_AMBER, Palette.RIFT_MAGENTA]
## A tint more saturated than this is checked against [constant RESERVED_HUES].
const MAX_RESERVED_SATURATION: float = 0.25
## Smallest hue distance, in degrees, a saturated tint must keep from every reserved hue.
const MIN_RESERVED_HUE_DISTANCE: float = 25.0
## Largest spark count one character may ask for, so a chained dash cannot flood the frame.
const MAX_SPARKS: int = 22

## Stable identifier, matching the character it belongs to.
@export var effect_id: StringName
## Which shape this dash draws.
@export var signature: Signature = Signature.RIBBON
## Colour of the streak along the travel line.
@export var trail_tint: Color = Color.WHITE
## Colour of the flash at the launch point.
@export var burst_tint: Color = Color.WHITE
## Colour of the sparks; ignored when [member spark_count] is zero.
@export var spark_tint: Color = Color.WHITE
## Sparks thrown per dash leg at full momentum, 0 for a signature that throws none.
@export_range(0, MAX_SPARKS, 1) var spark_count: int = 10
## Ribbon thickness at the head, as a share of the Wisp's collision radius.
@export_range(0.1, 3.0, 0.01) var ribbon_width: float = 0.9
## Seconds the ribbon takes to fade out.
@export_range(0.05, 1.2, 0.01) var ribbon_seconds: float = 0.28
## How far a [constant Signature.TWIN_ARC]'s two ribbons bow apart, in collision radii.
@export_range(0.0, 3.0, 0.05) var arc_spread: float = 0.9
## Multiplies the length of the shared launch burst; 0 drops it for a character whose rig already
## carries the whole read, so the two never stack into a smear.
@export_range(0.0, 2.0, 0.05) var burst_scale: float = 1.0
## Whether the Wisp's shared dash art plays for this character: the launch streak, the long streak
## where a long dash lands, and the momentum glow. That art is painted cyan, so a tint cannot turn
## it into the character's own colour; a character with its own attack effects turns it off
## (Patchvile, owner 2026-09-24). The signature above still draws.
@export var shared_trails: bool = true

## How a landing on a wall reads. [constant SPLASH] is the Wisp's: droplets, a splat on the wall and
## a flash, in the character's tint, over art painted cyan. [constant DUST] is a puff of dust rolling
## out along the wall and a few chips, in [member dust_tint], with none of the cyan art - for a
## character that lands on its feet (Patchvile, owner 2026-09-24).
enum Landing { SPLASH, DUST }
@export var landing: Landing = Landing.SPLASH
## Colour of a [constant Landing.DUST] landing.
@export var dust_tint: Color = Color(0.78, 0.72, 0.62, 1.0)


## True when [param tint] is saturated and sits within [constant MIN_RESERVED_HUE_DISTANCE] of a
## reserved hue.
static func is_reserved_tint(tint: Color) -> bool:
	if tint.s <= MAX_RESERVED_SATURATION:
		return false
	for reserved: Color in RESERVED_HUES:
		var distance: float = absf(tint.h - reserved.h) * 360.0
		if minf(distance, 360.0 - distance) < MIN_RESERVED_HUE_DISTANCE:
			return true
	return false


## Returns authoring failures, so the whole set can be checked without opening the editor.
func validate() -> PackedStringArray:
	var failures := PackedStringArray()
	if effect_id.is_empty():
		failures.append("dash effect id is empty")
	if spark_count < 0 or spark_count > MAX_SPARKS:
		failures.append("dash effect asks for %d sparks, the cap is %d" % [spark_count, MAX_SPARKS])
	for named: Array in [
		["trail", trail_tint], ["burst", burst_tint], ["spark", spark_tint], ["dust", dust_tint],
	]:
		if is_reserved_tint(named[1] as Color):
			failures.append("dash %s tint %s is too close to a reserved hue" % [
				named[0], (named[1] as Color).to_html(false),
			])
	return failures
