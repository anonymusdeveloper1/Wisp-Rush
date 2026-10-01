shader_type canvas_item;
render_mode blend_add;
// A dagger slash drawn procedurally on a square (WholeFrameCharacterVisual's attack slash): a
// crescent that sweeps across the front of a character flying up its frame, bright at its leading
// edge and thickest in the middle, then fades. No texture is read; UV (0..1) is the square.

uniform vec4 core_color : source_color = vec4(1.0, 0.97, 0.9, 1.0);
uniform vec4 edge_color : source_color = vec4(0.86, 0.72, 0.55, 1.0);
// 0..1: how far the sweep has travelled along the arc.
uniform float progress : hint_range(0.0, 1.0) = 0.0;
// 0..1: overall strength, for the fade after the sweep.
uniform float strength : hint_range(0.0, 1.0) = 0.0;
// The arc, in degrees from the front (UV up), and its band as a share of the square's half-size.
uniform float arc_from = 115.0;
uniform float arc_to = -115.0;
uniform float inner = 0.58;
uniform float outer = 0.96;
// Sweep the other way, for a drawing shown mirrored.
uniform bool mirror = false;

void fragment() {
	vec2 uv = mirror ? vec2(1.0 - UV.x, UV.y) : UV;
	vec2 p = (uv - vec2(0.5)) * 2.0;
	float r = length(p);
	float a = degrees(atan(p.x, -p.y));
	float t = (a - arc_from) / (arc_to - arc_from);
	// Thickest in the middle of the arc, tapering to points at both ends.
	float taper = sin(clamp(t, 0.0, 1.0) * PI);
	float half_band = (outer - inner) * 0.5 * taper;
	float centre = (inner + outer) * 0.5;
	float band = 1.0 - smoothstep(half_band * 0.55, half_band + 0.015, abs(r - centre));
	// Only the part already swept shows; the fresh edge is brightest and the tail fades behind it.
	float swept = step(0.0, t) * (1.0 - smoothstep(progress, progress + 0.04, t));
	float trail = smoothstep(progress - 0.75, progress, t);
	float lead = 1.0 - smoothstep(0.0, 0.12, abs(t - progress));
	float heat = clamp(1.0 - abs(r - centre) / max(half_band, 0.001), 0.0, 1.0);
	vec3 rgb = mix(edge_color.rgb, core_color.rgb, heat) * (0.75 + 0.6 * lead);
	float alpha = band * swept * mix(0.35, 1.0, trail) * strength;
	COLOR = vec4(rgb * alpha, alpha);
}
