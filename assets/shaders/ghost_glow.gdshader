shader_type spatial;
render_mode blend_add, unshaded, cull_disabled, depth_draw_never, fog_disabled, shadows_disabled;
// A soft glow on a quad turned to the camera, for a 3D arena's glowing eye (ADR-0023): brightest at
// its centre, pulsing slowly with `pulse` (0..1, set by the arena's script with the breath).

#include "res://assets/shaders/arena_3d_common.gdshaderinc"

uniform vec4 glow_color : source_color = vec4(0.3, 1.0, 0.9, 1.0);
uniform float glow = 2.2;
// How far the light swings with the pulse (0 none, 1 full).
uniform float pulse_depth = 0.25;
uniform float pulse = 0.5;

void vertex() {
	MODELVIEW_MATRIX = arena_billboard(VIEW_MATRIX, INV_VIEW_MATRIX, MODEL_MATRIX);
	MODELVIEW_NORMAL_MATRIX = mat3(MODELVIEW_MATRIX);
}

void fragment() {
	float r = length(UV - vec2(0.5)) * 2.0;
	float light = exp(-r * r * 5.0) * (1.0 - smoothstep(0.8, 1.0, r));
	float strength = 1.0 - pulse_depth + pulse_depth * pulse;
	ALBEDO = glow_color.rgb * glow * strength;
	ALPHA = clamp(light, 0.0, 1.0);
}
