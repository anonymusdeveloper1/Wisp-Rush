// Shared helpers for a 3D arena's effects (ADR-0023): value noise, a camera-facing billboard, and
// the floor mask that keeps every effect off the playable floor.

// A hash without sin(), which loses precision (and turns blocky) once its input grows large.
float arena_hash(vec2 p) {
	vec3 p3 = fract(vec3(p.xyx) * 0.1031);
	p3 += dot(p3, p3.yzx + 33.33);
	return fract((p3.x + p3.y) * p3.z);
}

float arena_noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	vec2 u = f * f * (3.0 - 2.0 * f);
	float a = arena_hash(i);
	float b = arena_hash(i + vec2(1.0, 0.0));
	float c = arena_hash(i + vec2(0.0, 1.0));
	float d = arena_hash(i + vec2(1.0, 1.0));
	return mix(mix(a, b, u.x), mix(c, d, u.x), u.y);
}

float arena_fbm(vec2 p) {
	float sum = 0.0;
	float amplitude = 0.5;
	for (int i = 0; i < 5; i++) {
		sum += amplitude * arena_noise(p);
		p = p * 2.03 + vec2(17.1, 9.2);
		amplitude *= 0.5;
	}
	return sum;
}

// The model-view matrix of a quad that faces the camera, keeping the node's (or particle's) scale.
mat4 arena_billboard(mat4 view, mat4 inv_view, mat4 model) {
	mat4 facing = view * mat4(inv_view[0], inv_view[1], inv_view[2], model[3]);
	return facing * mat4(
		vec4(length(model[0].xyz), 0.0, 0.0, 0.0),
		vec4(0.0, length(model[1].xyz), 0.0, 0.0),
		vec4(0.0, 0.0, length(model[2].xyz), 0.0),
		vec4(0.0, 0.0, 0.0, 1.0));
}

// True where a world point lies over the playable floor: inside its rectangle (x0, y0, x1, y1) and
// in front of its plane. Effects discard those fragments, so nothing is ever drawn over play.
bool arena_over_floor(vec3 world, vec4 floor_rect, float floor_z) {
	return world.x > floor_rect.x && world.x < floor_rect.z
		&& world.y > floor_rect.y && world.y < floor_rect.w
		&& world.z > floor_z - 0.03;
}
