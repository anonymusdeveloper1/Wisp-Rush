shader_type canvas_item;
// Hanging cloth of a layered arena (Stitchwarden's Vigil): a wind wave travels from the root to the
// tip. Each texel shifts across the cloth by whole texels, more towards the tip, so the root stays
// put, the tip lags and the art stays on its pixel grid. Texels over the floor are dropped, so the
// cloth never covers the playfield however it moves.

// Seconds of animation. The scene script advances it, so a paused run or Reduced Motion holds it.
uniform float time_s = 0.0;
// The texture's size, the cloth's root and its tip, in texels.
uniform vec2 texture_texels = vec2(64.0, 64.0);
uniform vec2 root_texel = vec2(0.0, 0.0);
uniform vec2 tip_texel = vec2(0.0, 64.0);
// The floor in this texture's texels (x, y, width, height): nothing is drawn there.
uniform vec4 clip_rect = vec4(0.0);
// Largest shift at the tip, in texels.
uniform float amplitude = 3.0;
// Texels between two crests along the cloth, and crests passing per second.
uniform float wavelength = 48.0;
uniform float speed = 0.6;
// Offsets one panel's wave from the other's.
uniform float phase = 0.0;
// Small response to the doll turning; the root remains fixed at the shoulder.
uniform vec2 motion_texels = vec2(0.0);

varying vec4 vertex_color;

void vertex() {
	vertex_color = COLOR;
}

void fragment() {
	vec2 texel = floor(UV * texture_texels) + 0.5;
	vec2 axis = tip_texel - root_texel;
	float cloth_length = max(length(axis), 1.0);
	vec2 along = axis / cloth_length;
	vec2 across = vec2(-along.y, along.x);
	float distance_along = dot(texel - root_texel, along);
	float reach = clamp(distance_along / cloth_length, 0.0, 1.0);
	float wave = sin(6.2831853 * (distance_along / wavelength - time_s * speed) + phase);
	float response = motion_texels.x + motion_texels.y * 0.3;
	float shift = floor(reach * reach * (amplitude * wave + response) + 0.5);
	vec2 source = texel - across * shift;
	vec4 color = vec4(0.0);
	if (all(greaterThanEqual(source, vec2(0.0))) && all(lessThan(source, texture_texels))) {
		color = texture(TEXTURE, source / texture_texels);
	}
	if (all(greaterThanEqual(texel, clip_rect.xy)) && all(lessThan(texel, clip_rect.xy + clip_rect.zw))) {
		color.a = 0.0;
	}
	COLOR = color * vertex_color;
}
