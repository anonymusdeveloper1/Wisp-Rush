// Endless arena scenery (ArenaAmbience, ArenaSceneryData): one pass over the painted background.
// Grade (scenery only, floor gets saturation with its luminance kept), emissive light on the
// painting's own light sources, small UV distortion, and the skin's set piece, light sweep and
// shooting stars. Everything but the floor saturation is gated by the mask's scenery weight, so
// nothing moves or brightens over the floor + rim tolerance (GDD §8, §9).
// Cost: three mask/background reads (four inside a SWIRL set piece), no loops.
shader_type canvas_item;

const vec2 CANVAS_PX = vec2(941.0, 1672.0);
const float ZONE_ALPHA_STEP = 28.0;
// Scenery weight (mask B) from which light and motion may start: B reaches 1 at the rim tolerance.
const float MOTION_GATE_START = 0.96;
const vec3 LUMA = vec3(0.299, 0.587, 0.114);

uniform sampler2D scenery_mask : filter_linear, repeat_disable;
// The same texture, nearest-sampled, so zone ids (alpha) are never blended.
uniform sampler2D scenery_zone_ids : filter_nearest, repeat_disable;
// 0 under Reduced Motion and in Shop thumbnails: no distortion, sparkle, pulses, flares or sweeps.
uniform float motion = 0.0;
// Seconds; driven by ArenaAmbience so it freezes with the paused run.
uniform float scenery_time = 0.0;

uniform float scenery_saturation = 1.0;
uniform float scenery_contrast = 1.0;
uniform float scenery_exposure = 1.0;
uniform vec4 shadow_lift = vec4(1.0, 1.0, 1.0, 0.0);
uniform vec4 highlight_lift = vec4(1.0, 1.0, 1.0, 0.0);
uniform float floor_saturation = 1.0;

// Per zone (index = zone id, 0 = none).
uniform vec4 zone_light[8];      // rgb tint (time-cycled), a level (time-animated)
uniform vec4 zone_alt[8];        // rgb alt colour, a spatial colour shift share
uniform vec4 zone_fx[8];         // x twinkle, y travel share, z travel cycles, w shift cycles
uniform vec4 zone_rates[8];      // x twinkle Hz, y travel Hz, z shift Hz, w sweep weight
uniform vec4 zone_warp[8];       // x amplitude px, y Hz, z cycles per 1000 px
uniform vec4 zone_warp_mode[8];  // weights: ripple, shimmer, wave, roil

uniform int piece_kind = 0;              // 0 none, 1 corona, 2 swirl
uniform vec4 piece_shape = vec4(0.0);    // centre px xy, radius px, extent px
uniform vec4 piece_color = vec4(0.0);
uniform vec4 piece_params = vec4(0.0);   // corona: rays, rotation rad, level, sharpness; swirl: swing rad, phase 0-1, core level
uniform vec4 piece_flare = vec4(0.0);    // angle rad, level, length px, half-width rad
uniform vec4 flare_color = vec4(0.0);

uniform vec4 sweep = vec4(0.0);          // angle rad, band centre px along the direction, half-width px, level
uniform vec4 sweep_color = vec4(1.0);
uniform vec4 streak = vec4(0.0);         // head px xy, heading rad, level
uniform vec4 streak_shape = vec4(1.0);   // tail length px, core width px
uniform vec4 streak_color = vec4(1.0);

// Vertex colour and modulate only: in fragment() COLOR already includes the texture.
varying vec4 modulate;

float hash12(vec2 p) {
	vec3 p3 = fract(vec3(p.xyx) * 0.1031);
	p3 += dot(p3, p3.yzx + 33.33);
	return fract((p3.x + p3.y) * p3.z);
}

vec2 rotate_about(vec2 px, vec2 centre, float angle) {
	vec2 d = px - centre;
	float c = cos(angle);
	float s = sin(angle);
	return centre + vec2(c * d.x - s * d.y, s * d.x + c * d.y);
}

void vertex() {
	modulate = COLOR;
}

void fragment() {
	vec2 px = UV * CANVAS_PX;
	vec4 mask = texture(scenery_mask, UV);
	int id = clamp(int(floor((1.0 - texture(scenery_zone_ids, UV).a) * 255.0 / ZONE_ALPHA_STEP + 0.5)), 0, 7);
	float gate = smoothstep(MOTION_GATE_START, 1.0, mask.b);
	float t = scenery_time;

	// Distortion: sums of slow sines per mode, scaled by the zone amplitude and mask G.
	vec4 warp = zone_warp[id];
	vec4 mode = zone_warp_mode[id];
	float k = warp.z * TAU / 1000.0;
	float ph = t * warp.y * TAU;
	vec2 ripple = vec2(sin(px.y * k * 1.9 + ph) + 0.5 * sin(px.x * k * 0.7 - ph * 0.8),
		0.6 * sin(px.x * k * 1.3 + px.y * k * 0.4 - ph * 1.1));
	vec2 shimmer = vec2(sin(px.y * k * 2.6 + ph * 1.7) * (0.6 + 0.4 * sin(px.x * k * 0.9 - ph * 0.6)),
		0.3 * sin(px.x * k * 1.8 + ph * 1.3));
	vec2 wave = vec2(0.2 * sin(px.y * k * 0.8 - ph * 0.5),
		sin(px.x * k + ph) + 0.45 * sin(px.x * k * 2.1 - ph * 1.4));
	vec2 roil = vec2(sin(px.y * k + ph) + 0.6 * sin((px.x + px.y) * k * 0.7 - ph * 0.7),
		0.7 * sin(px.x * k * 0.9 - ph * 0.9) + 0.3 * sin(px.y * k * 1.6 + ph * 0.4));
	vec2 offset_px = (ripple * mode.x + shimmer * mode.y + wave * mode.z + roil * mode.w)
		* warp.x * mask.g * gate * motion;
	vec4 base = textureLod(TEXTURE, (px + offset_px) / CANVAS_PX, 0.0);

	if (piece_kind == 2) {
		// Swirl: two rotated copies cross-faded on a sawtooth, so the region seems to turn forever
		// without its rotation ever accumulating (flow-map technique).
		float r = length(px - piece_shape.xy);
		float fall = (1.0 - smoothstep(piece_shape.z * 0.5, piece_shape.z, r)) * gate * mask.g;
		float swing = piece_params.x * fall * (1.25 - 0.5 * min(r / piece_shape.z, 1.0)) * motion;
		float p1 = piece_params.y;
		float p2 = fract(p1 + 0.5);
		vec2 a = rotate_about(px, piece_shape.xy, (p1 - 0.5) * swing) + offset_px;
		vec2 b = rotate_about(px, piece_shape.xy, (p2 - 0.5) * swing) + offset_px;
		vec4 turned = mix(textureLod(TEXTURE, a / CANVAS_PX, 0.0), textureLod(TEXTURE, b / CANVAS_PX, 0.0),
			abs(2.0 * p1 - 1.0));
		base = mix(base, turned, smoothstep(0.0, 0.02, fall * motion));
	}

	// Grade: the floor keeps its luminance; scenery gains saturation, contrast and split-tone.
	vec3 color = base.rgb;
	float luma = dot(color, LUMA);
	float scenery = smoothstep(0.0, 1.0, mask.b);
	vec3 floor_color = mix(vec3(luma), color, floor_saturation);
	vec3 graded = mix(vec3(luma), color, scenery_saturation);
	graded = (graded - 0.28) * scenery_contrast + 0.28;
	float highlight = smoothstep(0.08, 0.6, luma);
	vec3 shadow_tone = mix(vec3(1.0), shadow_lift.rgb / max(dot(shadow_lift.rgb, LUMA), 0.05), shadow_lift.a);
	vec3 highlight_tone = mix(vec3(1.0), highlight_lift.rgb / max(dot(highlight_lift.rgb, LUMA), 0.05), highlight_lift.a);
	graded *= mix(shadow_tone, highlight_tone, highlight) * scenery_exposure;
	color = clamp(mix(floor_color, max(graded, vec3(0.0)), scenery), 0.0, 1.0);

	// Emissive light on the painting's own light sources (mask R).
	vec4 light = zone_light[id];
	vec4 alt = zone_alt[id];
	vec4 fx = zone_fx[id];
	vec4 rates = zone_rates[id];
	vec2 canvas_uv = px / CANVAS_PX;
	float shift = alt.a * (0.5 + 0.5 * sin((canvas_uv.x + canvas_uv.y * 0.35) * fx.w * TAU - t * rates.z * TAU * motion));
	vec3 tint = mix(light.rgb, alt.rgb, shift);
	float cell = hash12(floor(px / 3.0));
	float sparkle = 0.5 + 0.5 * sin(t * rates.x * TAU * (0.6 + 0.8 * cell) + cell * TAU);
	float twinkle = mix(1.0, 0.2 + 1.2 * sparkle * sparkle, fx.x * motion);
	float pulse = 0.5 + 0.5 * sin(canvas_uv.y * fx.z * TAU - t * rates.y * TAU);
	float travel = mix(1.0, 0.35 + 1.3 * pulse * pulse, fx.y * motion);
	vec3 glow = tint * (mask.r * gate * light.a * twinkle * travel);

	if (piece_kind == 1) {
		// Corona: counter-rotating ray sets and a halo just outside the disc, plus a flare lobe.
		vec2 d = px - piece_shape.xy;
		float r = length(d);
		float angle = atan(d.y, d.x);
		float outside = smoothstep(piece_shape.z * 0.97, piece_shape.z * 1.06, r);
		float reach = max(r - piece_shape.z, 0.0) / max(piece_shape.w, 1.0);
		float rays_a = pow(0.5 + 0.5 * sin(angle * piece_params.x + piece_params.y), piece_params.w);
		float rays_b = pow(0.5 + 0.5 * sin(angle * floor(piece_params.x * 0.6) - piece_params.y * 1.7 + 1.3), piece_params.w);
		float rays = (rays_a * 0.65 + rays_b * 0.55) * (0.75 + 0.25 * sin(angle * 3.0 - piece_params.y * 0.4 + reach * 4.0));
		float corona = outside * (rays * exp(-reach * 2.2) + 0.6 * exp(-reach * 5.0)) * piece_params.z;
		float off_angle = abs(mod(angle - piece_flare.x + PI, TAU) - PI);
		float lobe = exp(-off_angle * off_angle / max(piece_flare.w * piece_flare.w, 1e-4))
			* outside * exp(-max(r - piece_shape.z, 0.0) / max(piece_flare.z, 1.0));
		glow += (piece_color.rgb * corona + flare_color.rgb * lobe * piece_flare.y * motion) * gate;
	} else if (piece_kind == 2) {
		float r = length(px - piece_shape.xy) / max(piece_shape.z, 1.0);
		float core = 1.0 - smoothstep(0.0, 1.0, r);
		glow += piece_color.rgb * piece_params.z * core * core * gate;
	}

	// Light sweep: a soft band that lights existing detail (glints, god rays).
	vec2 sweep_dir = vec2(cos(sweep.x), sin(sweep.x));
	float along = dot(px, sweep_dir) - sweep.y;
	float band = exp(-along * along / max(sweep.z * sweep.z, 1.0));
	glow += sweep_color.rgb * band * sweep.w * rates.w * gate * motion * (0.12 + 1.4 * pow(luma, 1.6));

	// Shooting star: a fading tail behind a soft head.
	if (streak.w > 0.0) {
		vec2 heading = vec2(cos(streak.z), sin(streak.z));
		vec2 rel = px - streak.xy;
		float behind = -dot(rel, heading);
		float side = dot(rel, vec2(-heading.y, heading.x));
		float tail = step(0.0, behind) * max(1.0 - behind / max(streak_shape.x, 1.0), 0.0);
		float width2 = streak_shape.y * streak_shape.y;
		float line = tail * tail * exp(-side * side / width2);
		float head = exp(-dot(rel, rel) / (width2 * 9.0));
		glow += streak_color.rgb * (line + head) * streak.w * gate * motion;
	}

	// Additive light that eases off on already bright pixels (bloom-like, no hard clipping).
	color += glow * (1.0 - 0.55 * color);
	COLOR = vec4(color, base.a) * modulate;
}
