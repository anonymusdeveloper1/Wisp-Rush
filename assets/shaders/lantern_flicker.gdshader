shader_type canvas_item;
// A layered arena's lantern (Stitchwarden's Vigil): its bright amber texels, the light, are scaled
// by `glow`, which the scene script swings each frame. The lantern's cage and chain keep their
// colour and nothing moves.

// Brightness of the light; 1 is the art as drawn.
uniform float glow = 1.0;

void fragment() {
	vec4 color = COLOR;
	float light = step(0.55, color.r) * step(color.b + 0.2, color.r) * step(0.3, color.g);
	color.rgb = mix(color.rgb, min(color.rgb * glow, vec3(1.0)), light);
	COLOR = color;
}
