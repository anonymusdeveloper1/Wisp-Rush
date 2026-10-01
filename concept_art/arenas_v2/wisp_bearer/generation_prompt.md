# Wisp Bearer image generation

Mode: built-in ImageGen (stylized concept).

Input images:
- arena_layout_guide.png: layout reference only; never copy labels or bands.
- arena_floor_mask.png: floor/rim placement reference only.
- Previous dark-fantasy wisp arena: subject and mood reference.

Final prompt:
Create one Wisp Rush Endless arena painting for an opaque 1080 x 2400 portrait source. The colored guide and grayscale mask are layout references only; no guide text, bands, labels or outlines appear in the art. Paint a flat axis-aligned rectangular floor at x174-904, y659-1747 with a 40 px rim outside at x134-944, y619-1787. The floor is even, mid-dark, muted slate-teal stone with faint seams, no symbols, objects, holes, light pools, characters or shadows; the first 150 px inside every edge is as plain as the center. Nothing crosses the floor or rim. A single colossal cyan-white soul wisp holds the arena from behind, with its core below the bottom rim at about y1830-2000 and its two spectral arms rising outside the left and right rims. Sparse dark-fantasy cliff and ruin silhouettes surround it. Keep y0-240 sky only, y2160-2400 ground only, y240-560 subdued for the HUD, and important frame details inside 60 px side margins and y240-2160. Use crisp pixel-inspired contours, painterly depth only at the perimeter, no machine, no text or UI.

The generated backplate was fitted deterministically by build_source.py against the project mask to make source.png.
