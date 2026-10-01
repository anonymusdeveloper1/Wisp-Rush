# Wisp Rush pixel-art Home and wordmark (2026-09-23)

Source pack for the Home screen art. The owner supplied a broken-wisp character image and the earlier cyan-stone logo as visual references, then chose dark stone with warm details and required pixel art throughout. The Home plate deliberately contains no character: the live equipped character occupies the central pocket above the dais.

## Files

- `home_background_generated.png`: raw 940×1672 generated courtyard.
- `home_background_source.png`: final empty 940×1672 portrait courtyard on a 4 px grid with 64 RGB colors.
- `logo_generated.png`: raw 1536×1024 logo image.
- `logo_masked.png`: transparent logo before pixel-grid conversion.
- `wisp_rush_logo_clean.png`: final transparent logo source on a 4 px grid; the brown stitched face is opaque and the surrounding alpha is hard-edged.
- `logo_brown_face_generated.png`: reference-guided brown face edit; only its face pixels are used, so its altered background and lettering never enter the final logo.
- `repair_logo_face.py`: restores pixels lost by the original background mask, then applies the brown stitched face within the hood opening using the clean logo's existing palette. Re-run it after any new clean-logo extraction.

## Generation

Mode: Codex built-in ImageGen. The owner references informed the design; these outputs are new generations rather than edits of the supplied files. The logo's alpha was refined with an OpenCV GrabCut foreground mask. Both final sources were block-averaged to a 4 px grid, quantized to 64 RGB colors without dithering, and expanded with nearest-neighbor sampling; the logo alpha was thresholded to hard edges. This keeps a genuine square pixel grid instead of the generated images' blended colors. The runtime outputs come from `python tools/art/extract_redesign.py --only backgrounds brand_logo --no-contact`, using `tools/art/redesign_v1_slices.json`. Never edit the runtime PNGs directly.

On 2026-09-25 the face was found to be transparent because GrabCut treated it as background. The owner then corrected its color against the original character reference: the head is **brown cloth**, with a center seam and stitched smile. `repair_logo_face.py` first restores missing opaque face and stitch pixels, then maps the brown edit to the existing palette inside a tight face mask. It preserves the hood, title, and transparent surroundings. Run `python concept_art/wisp_rush_home_pixel_v1/repair_logo_face.py`, then `python tools/art/extract_redesign.py --only brand_logo --no-contact` to update the Home and loading logo. `python tools/art/make_app_icon.py` builds the smaller Godot and Android splash logos from this source without changing the Home size.

### Logo prompt

> Use case: logo-brand. Create a NEW title logo for the mobile pixel-art fantasy game Wisp Rush. STRICT PIXEL ART, like a polished 16-bit/32-bit RPG title screen: every edge and detail follows an obvious square pixel grid, hard edges, no painterly brush marks, no smooth gradients, no 3D rendering. Exact text WISP RUSH in two lines, WISP on top and RUSH below; broad blocky pixel-font letterforms, each letter completely clear at small phone size. Warm ivory and pale sandstone letters with a few dark stitched seams, charcoal/slate pixel drop shadow, tiny restrained cyan accent pixels, tiny amber accent pixels. A small simplified icon of the game's broken wisp above the title: tattered cream hood, round dark face, one dark button eye with an X stitch, one amber glowing eye; keep it compact so lettering dominates. Overall composition wide and compact for the top of a portrait phone home screen. Genuine transparent alpha outside the silhouette, no dark rectangle, no plaque, no background, no extra text or watermark. Limited 24–32 color palette. The whole logo should read as deliberate hand-placed pixel art, not rasterized smooth illustration.

### Background prompt

> Use case: stylized-concept. Create a production EMPTY pixel-art background plate for the portrait 9:16 mobile game Wisp Rush (target around 940x1672). STRICT hand-crafted 16-bit/32-bit fantasy pixel art: visible square pixel grid, chunky stepped edges, limited ~32-color palette, no painted brush texture, no smooth gradient, no photorealism, no 3D. Ancient dark obsidian courtyard suspended in a void, slate teal/charcoal tiles and ruined stone arches at the outer edges, distant blocky silhouettes and subtle mist bands. In the central lower-middle, at about 57% of image height, place a shallow circular stone RESTING DAIS with a faint repaired crack and stitched stone seam. Above the dais, 37–54% height, leave a large open low-detail dark space for the game's live equipped character, from tiny wisp to full-body hooded spirit. Character's feet will overlay the dais; no fixed figure in the artwork. Small amber pixel braziers on the far left and right around 44% height; sparse cyan rune pixels near upper side edges. Reserve top 20% dark/quiet for a separate logo, sides clear enough for menu buttons, bottom 25% dark/quiet for large Play and Rifts buttons. Repairs and stitched details stay mainly in the stone border and dais, never across the empty character space. Full bleed, vertically composed with safe crop margins. NO character, NO mascot, NO wisp, NO face, NO flame in the center, NO text, NO logo, NO UI, NO watermark. The result must unmistakably read as game pixel art at phone size.

## Screen alignment

`HomeScreen.HERO_STAGE_CENTER` is UV `(0.50, 0.49)`. `HomeAmbience` places its two brazier effects around `(0.075, 0.47)` and `(0.935, 0.47)`, runes near `(0.05, 0.31)` and `(0.95, 0.31)`, and dais effects around `(0.50, 0.61)`. The screenshot fixture is `res://tools/godot/render_character_home_showcase.tscn`.
