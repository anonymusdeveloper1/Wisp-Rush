class_name MenuVideoData
extends Resource
## A character's menu performance as a pre-rendered video, placed where its sprite loop was drawn.
##
## Generated with the video by `tools/art/extract_menu_video.py`; never edit it by hand. The stream
## is Ogg Theora — Godot's only core video codec — and Theora carries no alpha, so every frame is
## packed: premultiplied colour in the left half, the matte as grey in the right half.
## `assets/shaders/packed_alpha_video.gdshader` puts the two back together.
## [WholeFrameCharacterVisual] plays it on Home and the Shop card instead of `storefront_idle`
## (ADR-0016).

## The packed stream: twice as wide as it is tall.
@export var stream: VideoStream
## Side of the square the video is drawn in, in rig pixels, chosen so the character stands the same
## height as the sprite loop it replaces.
@export_range(1.0, 4096.0, 0.1) var side: float = 384.0
## Where the centre of that square sits relative to the rig origin, in rig pixels.
@export var offset: Vector2 = Vector2.ZERO
## Decoded matte levels that mean fully transparent and fully opaque. The encoder writes 0 and 1;
## these absorb whatever a decoder's range conversion lifts or clips, so the background can never
## show as a faint box.
@export_range(0.0, 1.0, 0.001) var alpha_floor: float = 0.0
@export_range(0.0, 1.0, 0.001) var alpha_ceiling: float = 1.0
## Length of one loop in seconds, for tests and the QA fixtures.
@export_range(0.0, 60.0, 0.001) var loop_seconds: float = 0.0


## Returns authoring failures so a bad regeneration fails loudly instead of drawing nothing.
func validate() -> PackedStringArray:
	var failures := PackedStringArray()
	if stream == null:
		failures.append("menu video has no stream")
	if side <= 0.0:
		failures.append("menu video side must be positive")
	if alpha_ceiling <= alpha_floor:
		failures.append("menu video alpha ceiling must be above its floor")
	return failures
