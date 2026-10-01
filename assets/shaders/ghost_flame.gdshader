shader_type spatial;
render_mode blend_add, unshaded, cull_disabled, depth_draw_never, fog_disabled, shadows_disabled;
// One tongue of a 3D arena's blue ghost fire (ADR-0023): the draw pass of the flame particles, a
// quad turned to the camera with a wavering flame drawn in it, brightest at its core. The particle
// colour ramp fades it in and out; `glow` above 1 lets the environment's glow bloom it. Never drawn
// over the playable floor.

#include "res://assets/shaders/arena_3d_common.gdshaderinc"

uniform vec4 core_color : source_color = vec4(0.78, 1.0, 0.96, 1.0);
uniform vec4 edge_color : source_color = vec4(0.08, 0.86, 0.76, 1.0);
uniform float glow = 1.7;
uniform float scene_time = 0.0;
// The floor on the model's board (x0, y0, x1, y1) and its plane's depth.
uniform vec4 floor_rect = vec4(0.0);
uniform float floor_z = 0.0;

varying vec3 world_position;
varying float seed;

void vertex() {
	MODELVIEW_MATRIX = arena_billboard(VIEW_MATRIX, INV_VIEW_MATRIX, MODEL_MATRIX);
	MODELVIEW_NORMAL_MATRIX = mat3(MODELVIEW_MATRIX);
	world_position = (INV_VIEW_MATRIX * MODELVIEW_MATRIX * vec4(VERTEX, 1.0)).xyz;
	seed = arena_hash(MODEL_MATRIX[3].xy * 17.0 + float(INSTANCE_ID) * 0.37);
}

void fragment() {
	if (arena_over_floor(world_position, floor_rect, floor_z)) {
		discard;
	}
	// A soft wisp rather than a sharp tongue: a wide, blurred base that thins and curls as it rises,
	// broken up by drifting noise so neighbouring wisps melt into one another.
	vec2 p = vec2(UV.x - 0.5, 1.0 - UV.y);
	float t = scene_time * 1.2 + seed * 10.0;
	float sway = (arena_noise(vec2(p.y * 2.5 - t, seed * 9.0)) - 0.5) * 0.55 * p.y;
	float x = p.x + sway;
	float width = mix(0.46, 0.14, p.y);
	float body = 1.0 - smoothstep(0.0, width, abs(x));
	body *= smoothstep(0.0, 0.25, p.y) * (1.0 - smoothstep(0.45, 1.0, p.y));
	float wisps = arena_noise(vec2(x * 4.0 + seed * 5.0, p.y * 3.0 - t * 1.8));
	float shape = body * smoothstep(0.15, 0.85, wisps + (1.0 - p.y) * 0.4);
	float core = (1.0 - smoothstep(0.0, width * 0.7, abs(x))) * (1.0 - p.y);
	vec3 color = mix(edge_color.rgb, core_color.rgb, clamp(core, 0.0, 1.0));
	ALBEDO = color * glow * COLOR.rgb;
	ALPHA = clamp(shape * COLOR.a * 0.8, 0.0, 1.0);
}
