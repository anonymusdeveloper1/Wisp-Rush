shader_type canvas_item;
// The same body texture supplies a separate hood piece that turns with the face rig.
// The remaining scarf, shoulder ribbons and tunic move in a slow wind; the gloves stay on the rail.
// All sampling stays on the sprite's texel grid.
uniform vec2 texture_texels = vec2(206.0, 101.0);
uniform vec2 shift_texels = vec2(0.0);
uniform float time_s = 0.0;
uniform bool hood_piece = false;

varying vec4 vertex_color;

void vertex() {
	vertex_color = COLOR;
}

void fragment() {
	vec2 texel = floor(UV * texture_texels) + 0.5;
	vec2 hood_center = vec2(texture_texels.x * 0.5, texture_texels.y * 0.31);
	float hood_column = step(82.0, texel.x) * (1.0 - step(179.0, texel.x));
	float head_pixels = hood_column * (1.0 - step(49.0, texel.y));
	float body_cut = hood_column * (1.0 - step(44.0, texel.y));
	if (hood_piece) {
		COLOR = texture(TEXTURE, texel / texture_texels) * vertex_color * head_pixels;
	} else {
	float side = abs(texel.x - hood_center.x) / (texture_texels.x * 0.5);
	float scarf_band = smoothstep(texture_texels.y * 0.30, texture_texels.y * 0.44, texel.y)
		* (1.0 - smoothstep(texture_texels.y * 0.66, texture_texels.y * 0.82, texel.y));
	float scarf_weight = scarf_band * (0.45 + 0.55 * side);
	float shoulder_band = smoothstep(texture_texels.y * 0.43, texture_texels.y * 0.58, texel.y)
		* (1.0 - smoothstep(texture_texels.y * 0.75, texture_texels.y * 0.94, texel.y));
	float shoulder_weight = shoulder_band * smoothstep(0.20, 0.55, side);
	float glove_lock = smoothstep(texture_texels.y * 0.54, texture_texels.y * 0.63, texel.y)
		* smoothstep(0.26, 0.40, side);
	float cloth_weight = (scarf_weight + shoulder_weight * 0.65) * (1.0 - glove_lock);
	float tunic_weight = smoothstep(texture_texels.y * 0.53, texture_texels.y * 0.72, texel.y)
		* (1.0 - smoothstep(texture_texels.y * 0.82, texture_texels.y * 0.98, texel.y))
		* (1.0 - smoothstep(0.28, 0.55, side));
	vec2 follow = scarf_weight * shift_texels * 0.5
		+ shoulder_weight * shift_texels * 0.25 + tunic_weight * shift_texels * 0.2;
	vec2 wind = vec2(
		2.0 * sin(time_s * 1.25 + texel.x * 0.075 + texel.y * 0.035),
		0.8 * sin(time_s * 1.65 + texel.x * 0.052)
	) * cloth_weight;
	wind.x += 0.7 * sin(time_s * 0.8 + texel.y * 0.09) * tunic_weight;
	vec2 source = floor(texel - follow - wind) + 0.5;
	vec4 color = vec4(0.0);
	if (all(greaterThanEqual(source, vec2(0.0))) && all(lessThan(source, texture_texels))) {
		color = texture(TEXTURE, source / texture_texels);
	}
	COLOR = color * vertex_color * (1.0 - body_cut);
	}
}
