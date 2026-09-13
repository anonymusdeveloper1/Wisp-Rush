class_name PageDots
extends Control
## Row of small diamonds showing position in a FocusCarousel; the current one is larger and lit.
##
## Drawn rather than built from text glyphs, so it never depends on the font carrying bullet
## characters. Follows the carousel's continuous scroll, so it slides during a drag. Locked entries
## can be drawn hollow, so a player sees at a glance how much of a collection is still sealed.

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
## Diamond radius in design pixels for an idle entry.
@export var dot_radius: float = 7.0
## Distance in design pixels between neighbouring entry centres.
@export var dot_spacing: float = 34.0

## Indices drawn as hollow outlines (for example locked forms or Rifts).
var hollow: PackedInt32Array = PackedInt32Array():
	set(value):
		hollow = value
		queue_redraw()


func _get_minimum_size() -> Vector2:
	return Vector2(dot_spacing * maxf(1.0, float(count)), dot_radius * 4.0)


func _draw() -> void:
	if count <= 0:
		return
	var total: float = dot_spacing * float(count - 1)
	var start_x: float = size.x * 0.5 - total * 0.5
	var y: float = size.y * 0.5
	for index: int in count:
		var closeness: float = 1.0 - minf(absf(float(index) - position_value), 1.0)
		var radius: float = dot_radius * lerpf(1.0, 1.7, closeness)
		var colour: Color = Palette.TEXT_MUTED.lerp(Palette.SOUL_CYAN, closeness)
		var centre := Vector2(start_x + dot_spacing * float(index), y)
		var points := PackedVector2Array([
			centre + Vector2(0.0, -radius),
			centre + Vector2(radius, 0.0),
			centre + Vector2(0.0, radius),
			centre + Vector2(-radius, 0.0),
		])
		if index in hollow and closeness < 0.5:
			var outline := points.duplicate()
			outline.append(points[0])
			draw_polyline(outline, Color(colour, 0.8), 2.0, true)
		else:
			draw_colored_polygon(points, colour)
