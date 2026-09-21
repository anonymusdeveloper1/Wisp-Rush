// Recombines a packed-alpha video frame: premultiplied colour in the left half, the matte as grey in
// the right half. Ogg Theora - Godot's only core video codec - has no alpha channel, so a character
// video is generated on flat magenta, keyed by tools/art/extract_menu_video.py and packed this way
// (ADR-0016). Drawn by the VideoStreamPlayer WholeFrameCharacterVisual adds on Home and the Shop.
shader_type canvas_item;
render_mode blend_premul_alpha;

// Decoded matte levels that mean fully transparent and fully opaque (MenuVideoData). They absorb any
// range conversion a decoder applies, so the background can never show as a faint box.
uniform float alpha_floor : hint_range(0.0, 1.0) = 0.0;
uniform float alpha_ceiling : hint_range(0.0, 1.0) = 1.0;

// Modulate and self-modulate, which Godot folds into COLOR before vertex() runs. Captured here
// because fragment() replaces COLOR outright, and a menu fade must still reach the video.
varying vec4 tint;

void vertex() {
	tint = COLOR;
}

void fragment() {
	float range = max(alpha_ceiling - alpha_floor, 0.001);
	float alpha = clamp((texture(TEXTURE, vec2(0.5 + UV.x * 0.5, UV.y)).r - alpha_floor) / range, 0.0, 1.0);
	vec3 colour = clamp((texture(TEXTURE, vec2(UV.x * 0.5, UV.y)).rgb - vec3(alpha_floor)) / range, 0.0, 1.0);
	// Premultiplied colour can never exceed its alpha; clamping to it removes any compression noise
	// the codec leaves on the black background, where alpha is 0.
	colour = min(colour, vec3(alpha));
	COLOR = vec4(colour * tint.rgb * tint.a, alpha * tint.a);
}
