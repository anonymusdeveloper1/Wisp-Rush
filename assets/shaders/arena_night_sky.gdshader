shader_type spatial;
render_mode unshaded, fog_disabled, cull_disabled, shadows_disabled;
// A 3D arena's sky (ADR-0023): a quad fixed in front of the camera, behind everything, that fills
// the screen with a night gradient, faint high cloud and the moon. The arena's script sizes it and
// sets `aspect` (the screen's width over its height) and `scene_time` (paused with the run).

#include "res://assets/shaders/arena_3d_common.gdshaderinc"

// Colour at the top of the screen and toward its bottom.
uniform vec4 zenith_color : source_color = vec4(0.07, 0.10, 0.19, 1.0);
uniform vec4 horizon_color : source_color = vec4(0.36, 0.45, 0.60, 1.0);
// The moon's centre in screen UV (0..1, y down) and its radius as a share of the screen's height.
uniform vec2 moon_center = vec2(0.83, 0.15);
uniform float moon_radius = 0.028;
uniform vec4 moon_color : source_color = vec4(1.0, 0.97, 0.88, 1.0);
// Brightness of the moon's halo.
uniform float halo_strength = 0.35;
// Opacity of the faint high cloud.
uniform float high_cloud = 0.22;
uniform float aspect = 0.46;
uniform float scene_time = 0.0;

void fragment() {
	vec2 uv = UV;
	vec3 color = mix(zenith_color.rgb, horizon_color.rgb, smoothstep(0.0, 1.0, uv.y));
	vec2 q = vec2(uv.x * aspect, uv.y) * 5.0 + vec2(scene_time * 0.006, 0.0);
	float cloud = smoothstep(0.52, 0.8, arena_fbm(q)) * (1.0 - smoothstep(0.25, 0.7, uv.y));
	color = mix(color, horizon_color.rgb * 1.25, cloud * high_cloud);
	vec2 m = vec2((uv.x - moon_center.x) * aspect, uv.y - moon_center.y);
	float r = length(m) / moon_radius;
	float disc = 1.0 - smoothstep(0.94, 1.0, r);
	float craters = arena_fbm(m / moon_radius * 2.5 + vec2(3.0)) * 0.22;
	float halo = exp(-max(r - 1.0, 0.0) * 0.9) * halo_strength * (1.0 - disc);
	color = mix(color, moon_color.rgb * (1.05 - craters), disc);
	color += moon_color.rgb * halo;
	ALBEDO = color;
}
