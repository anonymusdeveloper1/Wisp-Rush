// Endless scenery particles (ArenaAmbience): soft sprites faded by the scenery mask, so a particle
// can never show over the floor + rim tolerance whatever its path (GDD §8). Premultiplied blend
// handles both additive light (additive = 1) and normal smoke (additive = 0) in one shader.
shader_type canvas_item;
render_mode blend_premul_alpha;

// Scenery weight (mask B) from which particles may show: B reaches 1 at the rim tolerance.
const float PARTICLE_GATE_START = 0.96;

uniform sampler2D scenery_mask : filter_linear, repeat_disable;
// Canvas-space rectangle of the background image: xy origin, zw size.
uniform vec4 image_rect = vec4(0.0, 0.0, 1.0, 1.0);
uniform float additive = 1.0;

varying vec2 scenery_uv;

void vertex() {
	// MODEL_MATRIX includes the particle's own transform, so this is its canvas position.
	vec2 world = (MODEL_MATRIX * vec4(VERTEX, 0.0, 1.0)).xy;
	scenery_uv = (world - image_rect.xy) / image_rect.zw;
}

void fragment() {
	// COLOR already holds the sprite texture times the particle colour.
	vec4 sprite = COLOR;
	float inside = step(0.0, scenery_uv.x) * step(scenery_uv.x, 1.0) * step(0.0, scenery_uv.y) * step(scenery_uv.y, 1.0);
	float gate = smoothstep(PARTICLE_GATE_START, 1.0, texture(scenery_mask, scenery_uv).b) * inside;
	float alpha = sprite.a * gate;
	COLOR = vec4(sprite.rgb * alpha, alpha * (1.0 - additive));
}
