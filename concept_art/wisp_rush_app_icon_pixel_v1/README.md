# Wisp Rush pixel-art game icon — source pack

The owner supplied the Home-screen Wisp Rush logo as the identity reference. The v4 artwork was approved for the game icon on 2026-09-25. This folder remains the icon source pack; the generated runtime copies live in `assets/art/branding/app_icon/`. The Godot and Android splash screens use the separate, backgroundless Home logo with its repaired opaque face.

**Current runtime source: v4 with a dark-stone background.** The owner felt the character in v1 was too close, so v2 gave it more dark space. V3 added the exact two-line title, **WISP RUSH**, below the mascot. V4 adds a subdued pixel-stone courtyard behind the named composition. Earlier versions remain for comparison.

## Deliverables

- `wisp_rush_app_icon_1024.png` — final square, opaque RGB icon master; 1024 × 1024; 40 colors; exact 4 × 4 pixel blocks. The broken wisp's stitched hood, X-button eye, amber eye, and restrained cyan flames stay legible at launcher size.
- `wisp_rush_app_icon_preview_128.png` — small-size readability preview, not an additional design.
- `wisp_rush_app_icon_1024_v2.png` — revised 1024 px icon master with the artwork about 10% smaller within the square; same 40-color pixel palette.
- `wisp_rush_app_icon_preview_128_v2.png` — revised launcher-size preview.
- `wisp_rush_app_icon_1024_v3_named.png` — 1024 px icon master with the broken wisp above the two-line WISP RUSH title; 59 colors on the same 4 px grid.
- `wisp_rush_app_icon_preview_128_v3_named.png` — launcher-size preview of v3.
- `wisp_rush_app_icon_1024_v4_background.png` — current 1024 px RGB icon master with dark stone ruins and the corrected brown cloth face; 64 colors on the 4 px grid.
- `wisp_rush_app_icon_preview_128_v4_background.png` — current launcher-size preview.
- `icon_generated_raw.png` — original ImageGen draft retained for provenance. Use the processed v4 master for runtime builds; raw drafts are not game-ready.
- `icon_zoomout_generated_raw.png` — edited ImageGen draft behind v2; postprocessed by `build_icon_v2.py`.
- `icon_named_generated_raw.png` — ImageGen title-layout draft behind v3; postprocessed by `build_icon_v3.py`.
- `icon_background_generated_raw.png` — ImageGen environmental-background draft behind v4; postprocessed by `build_icon_v4.py`.
- `icon_brown_face_generated_raw.png` — reference-guided brown-face edit; only its face pixels are used, preserving the approved v4 composition and title.
- `home_logo_reference.png` — owner-provided Home logo used as the visual reference.
- `build_icon.py` — deterministic Pillow postprocess; run `python concept_art/wisp_rush_app_icon_pixel_v1/build_icon.py` from the repo root.
- `build_icon_v2.py` — rebuilds v2 from its raw edit, using v1's 40 colors to keep the cyan and amber accents; run it from the repo root.
- `build_icon_v3.py` — rebuilds v3 from its raw draft, using the Home wordmark's palette and a hard 4 px grid; run it from the repo root.
- `build_icon_v4.py` — rebuilds v4 from its raw draft on a hard 4 px grid with a 64-color palette, then inserts the brown face using that palette; run it from the repo root.

The head and major details sit inside a generous square margin for rounded-square launcher masks. V4 includes the game name and a quiet dark-stone setting; the separate Home wordmark keeps its original layout.

## Generation

Mode: Codex built-in ImageGen, followed by deterministic Pillow processing. The attached Home logo served as a **reference**, not an instruction source or edit target. The raw draft was sampled to a 256 × 256 art grid, flattened over solid void charcoal, reduced to 40 colors without dithering, then enlarged 4× with nearest-neighbor sampling. The final file has no alpha, antialiasing, blur, or smooth gradient pixels.

For v2, the built-in ImageGen edit reduced the character's framing. Its edited artwork was fit into 180 × 180 pixels on the same 256 × 256 art grid, centered, mapped to the v1 40-color palette, and enlarged 4× nearest. That preserves the bright cyan flames after palette reduction.

For v3, ImageGen composed the v2 character with the Home logo's two-line lettering. The draft was cropped to its visible bounds, fit into 220 × 220 pixels on the 256 × 256 art grid, centered over void charcoal, mapped to the Home wordmark's 64-color palette (59 colors used), and enlarged 4× nearest. The final title visibly reads **WISP RUSH**.

For v4, ImageGen edited the named icon using the pixel Home background as a setting reference. The full-bleed draft was flattened over void charcoal, sampled to 256 × 256, quantized to 64 colors without dithering, and enlarged 4× nearest. The final master is opaque and every 4 × 4 block is one solid color.

The owner later pointed out that the original broken wisp has a brown stitched-cloth head. A new ImageGen edit used that original character as its color and seam reference. `build_icon_v4.py` transfers only the face inside the hood from that edit onto the approved v4 layout, maps it to v4's existing 64-color palette, and keeps the background, title, and other mascot pixels intact. Rebuild runtime launcher assets with `python tools/art/make_app_icon.py` afterward.

### Exact generation prompt

> Create one new square Wisp Rush game icon, using the attached Home-screen logo ONLY as the character identity reference. Center a large close-up of the same broken wisp: asymmetrical torn ivory stitched hood, deep charcoal face opening, left circular button eye marked with an X, right luminous amber eye, and ragged scarf edge. Keep both eyes readable at small app-icon size. Place the head over a simple near-black obsidian stone square with a few angular charcoal stone shapes and two small cyan soul flames as secondary accents. Use the Home logo's warm ivory, amber, dark stone, and restrained cyan palette. Composition must remain safely within a central 80% area for rounded-square mobile app masking. No letters, no words, no WISP RUSH text, no extra characters, no border badge, no scenery clutter. STRICT 2D PIXEL ART ONLY: aligned square pixel grid, chunky deliberate pixel clusters, limited palette, crisp hard edges, no antialiasing, no gradients, no blur, no painterly rendering, no 3D. Output a single finished square icon illustration.

### Exact v2 edit prompt

> Edit the supplied Wisp Rush square game icon with ONE compositional change: make the entire broken-wisp character artwork, cyan flames, and angular dark stone shapes about 16% smaller and centered, creating noticeably more uninterrupted dark charcoal space around all sides. Keep the same square canvas, flat dark background, pose, stitched ivory hood, X-button eye, amber eye, scarf, two cyan flames, pixel colors, and lighting. Do not redesign the face or hood, move features relative to one another, add new details, add letters or words, or change the style. STRICT 2D PIXEL ART ONLY: aligned square pixel grid, limited palette, crisp hard edges, no antialiasing, gradients, blur, painterly rendering, or 3D. The edited image must remain legible at 128px icon size.

### Exact v3 edit prompt

> Edit the FIRST reference, the square Wisp Rush game icon. Add the game name from the SECOND reference, using its recognizable warm stitched ivory pixel-art lettering. Arrange the broken-wisp hooded head and its two cyan soul flames in the upper 58% of the square and the title in the lower 30% as exactly two centered lines: WISP on line one, RUSH on line two. Exact spelling must be WISP RUSH, with no other text. Keep a generous dark margin around the whole composition for launcher-icon masks. Preserve the character identity: torn ivory stitched hood, X-button eye on the left, glowing amber eye on the right, ragged scarf. Keep the flat near-black obsidian background, restrained cyan/amber details, and the Home logo's color palette. Do not add a border, extra character, or scenic clutter. STRICT 2D PIXEL ART ONLY: uniform aligned square pixel grid, limited palette, crisp hard edges, no antialiasing, gradients, blur, painterly rendering, or 3D. The mascot and both words should remain distinguishable at 128px.

### Exact v4 edit prompt

> Edit the FIRST image, the square Wisp Rush app icon with the exact two-line WISP RUSH title. Keep the broken-wisp mascot and both words in the same positions, sizes, shapes, and colors. Add a full-bleed environmental BACKGROUND behind them, borrowing the dark obsidian courtyard language of the SECOND reference: chunky pixel-stone arch fragments near the outer left and right edges, distant ruined silhouettes, a few very dim teal rune pixels, and subtle dark slate floor blocks at the bottom. The center immediately behind the ivory character and lettering must remain quiet, near-black, and high contrast; background detail must not cross or obscure the mascot, cyan flames, or any letter. Maintain comfortable outer margins for mobile rounded-square masks. Do not add new characters, new text, extra flames, borders, or badges. EXACT text must remain WISP on the first line and RUSH on the second. STRICT 2D PIXEL ART ONLY: aligned square pixel grid, limited palette, crisp hard edges, no antialiasing, gradients, blur, painterly texture, or 3D. The whole icon should read clearly at 128px.

## Integration status

**Implemented on 2026-09-25.** `python tools/art/make_app_icon.py` builds the project icon and Android launcher/adaptive layers from the v4 master. It builds separate, smaller transparent splash logos from `concept_art/wisp_rush_home_pixel_v1/wisp_rush_logo_clean.png`: `assets/art/branding/wisp_rush_splash_logo.png` for the Godot boot splash and `assets/art/branding/app_icon/android_splash_icon_432.png` for Android system splash. The Home/loading logo retains its own larger asset. Earlier v1–v3 source variants remain here for comparison.
