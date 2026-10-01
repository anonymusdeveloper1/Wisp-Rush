shader_type canvas_item;
// A mild top taper on the decorative frame gives depth without moving the rectangular floor or walls.
uniform float texture_width = 158.0;
uniform float group_top_y = -27.0;
uniform float floor_height = 264.0;
uniform float taper = 0.035;

void vertex() {
	float group_y = group_top_y + VERTEX.y;
	float upper = clamp(1.0 - group_y / floor_height, 0.0, 1.0);
	float width_at_y = 1.0 - taper * upper;
	VERTEX.x = texture_width * 0.5 + (VERTEX.x - texture_width * 0.5) * width_at_y;
}
