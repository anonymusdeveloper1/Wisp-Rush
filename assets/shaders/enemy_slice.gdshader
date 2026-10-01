shader_type canvas_item;
// One half of a sliced enemy (WholeFrameEnemy's kill): keeps only the pixels on one side of a cut
// line through the sprite's centre. The test runs on the sprite's local position, not its UV, so an
// atlas region or a mirrored frame cuts the same way.

// Direction of the cut in the sprite's local space.
uniform vec2 cut_direction = vec2(1.0, 0.0);
// +1 keeps one side of the line, -1 the other.
uniform float side = 1.0;

varying vec2 local_position;

void vertex() {
	local_position = VERTEX;
}

void fragment() {
	vec2 normal = vec2(-cut_direction.y, cut_direction.x);
	if (dot(local_position, normal) * side < 0.0) {
		discard;
	}
}
