shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_never, blend_mix, shadows_disabled;
// A bank of soft clouds on a quad behind a 3D arena's model (ADR-0023): fractal noise, lit from
// above, dense at the quad's bottom and fading toward its top, drifting sideways with
// `scene_time` (paused with the run). The depth fog hazes the far banks.

#include "res://assets/shaders/arena_3d_common.gdshaderinc"

uniform vec4 light_color : source_color = vec4(0.84, 0.86, 0.9, 1.0);
uniform vec4 shade_color : source_color = vec4(0.3, 0.37, 0.5, 1.0);
// How much of the quad is cloud (0 none, 1 all) and how soft the cloud's edges are.
uniform float coverage = 0.5;
uniform float softness = 0.18;
// Cloud features per model unit, and the quad's size in model units (keeps them round).
uniform float scale = 2.2;
uniform vec2 quad_size = vec2(3.0, 1.0);
// Model units the bank drifts per second, and a per-bank offset.
uniform float drift = 0.02;
uniform float seed = 0.0;
// Share of the quad's height, from its top, over which the cloud fades in, and from its bottom over
// which it fades out (0 for a bank that reaches below the screen).
uniform float top_fade = 0.45;
uniform float bottom_fade = 0.0;
uniform float opacity = 1.0;
uniform float scene_time = 0.0;

void fragment() {
	vec2 p = UV * quad_size * scale + vec2(scene_time * drift * scale + seed * 13.0, seed * 7.0);
	float density = arena_fbm(p);
	float shape = smoothstep(coverage - softness, coverage + softness, density + (UV.y - 0.5) * 0.35);
	shape *= smoothstep(0.0, top_fade, UV.y);
	if (bottom_fade > 0.0) {
		shape *= 1.0 - smoothstep(1.0 - bottom_fade, 1.0, UV.y);
	}
	float above = arena_fbm(p + vec2(0.0, -0.18 * scale));
	float lit = clamp(0.55 + (density - above) * 2.5 + (1.0 - UV.y) * 0.25, 0.0, 1.0);
	ALBEDO = mix(shade_color.rgb, light_color.rgb, lit);
	ALPHA = clamp(shape * opacity, 0.0, 1.0);
}
