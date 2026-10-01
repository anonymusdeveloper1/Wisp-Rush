shader_type spatial;
render_mode blend_add, unshaded, cull_disabled, depth_draw_never, fog_disabled, shadows_disabled;
// A glowing ghost skull of a 3D arena (ADR-0023), drawn in code on a quad turned to the camera: a
// pale teal skull with dark eyes, nose and mouth, a flickering halo and a flame trailing up from it.
// `scene_time` (paused with the run) drives the flicker. Never drawn over the playable floor.

#include "res://assets/shaders/arena_3d_common.gdshaderinc"

uniform vec4 glow_color : source_color = vec4(0.2, 0.95, 0.82, 1.0);
uniform vec4 bone_color : source_color = vec4(0.8, 1.0, 0.96, 1.0);
uniform float glow = 2.0;
uniform float scene_time = 0.0;
uniform vec4 floor_rect = vec4(0.0);
uniform float floor_z = 0.0;

varying vec3 world_position;
varying float seed;

float circle(vec2 p, vec2 c, float r) {
	return length(p - c) - r;
}

float rounded_box(vec2 p, vec2 c, vec2 half_size, float r) {
	vec2 d = abs(p - c) - half_size + r;
	return length(max(d, 0.0)) + min(max(d.x, d.y), 0.0) - r;
}

void vertex() {
	MODELVIEW_MATRIX = arena_billboard(VIEW_MATRIX, INV_VIEW_MATRIX, MODEL_MATRIX);
	MODELVIEW_NORMAL_MATRIX = mat3(MODELVIEW_MATRIX);
	world_position = (INV_VIEW_MATRIX * MODELVIEW_MATRIX * vec4(VERTEX, 1.0)).xyz;
	seed = arena_hash(NODE_POSITION_WORLD.xy * 11.0);
}

void fragment() {
	if (arena_over_floor(world_position, floor_rect, floor_z)) {
		discard;
	}
	// -1..1 across the quad, y up; the skull sits in its lower half, the flame rises above it.
	vec2 p = vec2(UV.x - 0.5, 0.5 - UV.y) * 2.0;
	vec2 s = (p - vec2(0.0, -0.3)) * 1.6;
	float t = scene_time + seed * 20.0;
	float skull = min(circle(s, vec2(0.0, 0.06), 0.42), rounded_box(s, vec2(0.0, -0.34), vec2(0.25, 0.15), 0.08));
	float eyes = min(circle(s, vec2(-0.16, 0.0), 0.12), circle(s, vec2(0.16, 0.0), 0.12));
	float holes = min(min(eyes, rounded_box(s, vec2(0.0, -0.17), vec2(0.035, 0.06), 0.02)),
		rounded_box(s, vec2(0.0, -0.36), vec2(0.14, 0.022), 0.01));
	float fill = (1.0 - smoothstep(-0.02, 0.02, skull)) * smoothstep(-0.02, 0.02, holes);
	float halo = exp(-max(skull, 0.0) * 5.0) * 0.5;
	float n = arena_noise(vec2(p.x * 3.0 + seed * 4.0, p.y * 2.5 - t * 1.6));
	float rise = smoothstep(-0.1, 0.9, p.y) * (1.0 - smoothstep(0.85, 1.0, p.y));
	float tail = rise * (1.0 - smoothstep(0.12, 0.5, abs(p.x + (n - 0.5) * 0.45))) * n;
	float flicker = 0.85 + 0.15 * sin(t * 5.3);
	vec3 color = glow_color.rgb * (halo + tail) + bone_color.rgb * fill;
	ALBEDO = color * glow * flicker;
	ALPHA = clamp(fill + halo + tail, 0.0, 1.0);
}
