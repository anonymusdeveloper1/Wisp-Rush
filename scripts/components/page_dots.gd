class_name PageDots
extends Control
## Row of pixel-art page diamonds showing position in a FocusCarousel; the current one is lit amber.
##
## Drawn from the UI kit's page diamonds (nearest-filtered, whole design pixels) rather than from
## text glyphs, so it never depends on the font carrying bullet characters. Follows the carousel's
## continuous scroll: the lit diamond cross-fades between neighbours during a drag instead of
## scaling, which would break the pixel grid. Locked entries use the kit's locked diamond, so a
## player sees at a glance how much of a collection is still sealed.

const IDLE_TEXTURE: Texture2D = preload("res://assets/ui/theme/icons/page_diamond_idle.tres")
const ACTIVE_TEXTURE: Texture2D = preload("res://assets/ui/theme/icons/page_diamond_active.tres")
const LOCKED_TEXTURE: Texture2D = preload("res://assets/ui/theme/icons/page_diamond_locked.tres")

## Number of entries.
@export var count: int = 0:
	set(value):
		count = maxi(0, value)
		update_minimum_size()
		queue_redraw()
## Continuous position, usually FocusCarousel.get_scroll().
@export var position_value: float = 0.0:
	set(value):
		position_value = value
		queue_redraw()
## Distance in design pixels between neighbouring entry centres (keep it a multiple of 4).
@export var dot_spacing: float = 32.0

## Indices drawn as locked diamonds (for example locked forms).
var hollow: PackedInt32Array = PackedInt32Array():
	set(value):
		hollow = value
		queue_redraw()


func _get_minimum_size() -> Vector2:
	return Vector2(dot_spacing * maxf(1.0, float(count)), IDLE_TEXTURE.get_size().y)


func _draw() -> void:
	if count <= 0:
		return
	var cell: Vector2 = IDLE_TEXTURE.get_size()
	var total: float = dot_spacing * float(count - 1)
	var start_x: float = size.x * 0.5 - total * 0.5 - cell.x * 0.5
	var y: float = roundf((size.y - cell.y) * 0.5)
	for index: int in count:
		var at := Vector2(roundf(start_x + dot_spacing * float(index)), y)
		draw_texture(LOCKED_TEXTURE if index in hollow else IDLE_TEXTURE, at)
		var closeness: float = 1.0 - minf(absf(float(index) - position_value), 1.0)
		if closeness > 0.0:
			draw_texture(ACTIVE_TEXTURE, at, Color(1.0, 1.0, 1.0, closeness))
