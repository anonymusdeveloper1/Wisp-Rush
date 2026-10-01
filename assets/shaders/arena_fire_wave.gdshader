shader_type canvas_item;
// Moves the separate scythe-fire sprite on its pixel grid. The blade itself stays still.
uniform float time_s = 0.0;

varying vec4 vertex_color;

void vertex() {
	vertex_color = COLOR;
}

void fragment() {
	vec2 size = vec2(textureSize(TEXTURE, 0));
	vec2 texel = floor(UV * size) + 0.5;
	float rise = floor(sin(time_s * 8.0 + texel.x * 0.23) * 1.2 + 0.5);
	float sway = floor(sin(time_s * 5.7 + texel.y * 0.19) * 1.2 + 0.5);
	vec2 source = texel + vec2(sway, rise);
	vec4 color = vec4(0.0);
	if (all(greaterThanEqual(source, vec2(0.0))) && all(lessThan(source, size))) {
		color = texture(TEXTURE, source / size);
	}
	float ember = 0.92 + 0.08 * sin(time_s * 11.0 + texel.x * 0.37 + texel.y * 0.11);
	COLOR = vec4(color.rgb * ember, color.a) * vertex_color;
}
