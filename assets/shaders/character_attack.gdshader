shader_type canvas_item;
// The attack look of a whole-frame character (WholeFrameCharacterVisual): a glowing outline around
// the silhouette while it dashes, and a flash toward the glow colour on the contact frame. Both at 0
// draw the frame untouched. The outline samples neighbouring texels, which on a packed sheet stay
// inside the cell's transparent 8 px gutter as long as outline_px does.

uniform vec4 glow_color : source_color = vec4(1.0, 0.95, 0.86, 1.0);
// 0..1: how much of the outline shows.
uniform float outline : hint_range(0.0, 1.0) = 0.0;
// Outline width, in texels of the sheet.
uniform float outline_px : hint_range(0.0, 8.0) = 3.0;
// 0..1: how far the painted colour is pushed toward glow_color.
uniform float flash : hint_range(0.0, 1.0) = 0.0;

varying vec4 vertex_color;

void vertex() {
	vertex_color = COLOR;
}

void fragment() {
	vec4 base = COLOR;
	vec2 step = TEXTURE_PIXEL_SIZE * outline_px;
	float around = 0.0;
	around = max(around, texture(TEXTURE, UV + vec2(step.x, 0.0)).a);
	around = max(around, texture(TEXTURE, UV - vec2(step.x, 0.0)).a);
	around = max(around, texture(TEXTURE, UV + vec2(0.0, step.y)).a);
	around = max(around, texture(TEXTURE, UV - vec2(0.0, step.y)).a);
	around = max(around, texture(TEXTURE, UV + step * 0.7071).a);
	around = max(around, texture(TEXTURE, UV - step * 0.7071).a);
	around = max(around, texture(TEXTURE, UV + vec2(step.x, -step.y) * 0.7071).a);
	around = max(around, texture(TEXTURE, UV + vec2(-step.x, step.y) * 0.7071).a);
	float edge = clamp(around - base.a / max(vertex_color.a, 0.001), 0.0, 1.0) * outline;
	vec3 painted = mix(base.rgb, glow_color.rgb * vertex_color.rgb, flash);
	float alpha = max(base.a, edge * glow_color.a * vertex_color.a);
	vec3 rgb = mix(glow_color.rgb * vertex_color.rgb, painted, base.a / max(alpha, 0.001));
	COLOR = vec4(rgb, alpha);
}
