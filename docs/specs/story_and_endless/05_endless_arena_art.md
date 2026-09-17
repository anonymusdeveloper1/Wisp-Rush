# Phase 5 — Endless arena skins: validate, extract and wire

> **Status:** ✅ done 2026-09-15 for all 30 skins of `skins_manifest.json` (owner decision: the catalog grew from three to thirty, tier prices, lossy import). Addition beyond this spec: code-rendered scenery ambience for Legendary and Mythic skins (`ArenaAmbience`, ADR-0014 addendum). Device run pending. Details: [endless_mode.md](../../systems/endless_mode.md).

> Part of [story_and_endless](README.md) · **Rules:** [ADR-0014](../../decisions/0014-endless-arenas-share-one-floor-template.md)
> (art contract), GDD §9, §14 #19 · **Art prompts:**
> [concept_art/wisp_rush_endless_v1/GENERATION_PROMPTS.md](../../../concept_art/wisp_rush_endless_v1/GENERATION_PROMPTS.md) ·
> **Touches:** [endless_mode.md](../../systems/endless_mode.md), [ASSETS.md](../../ASSETS.md)

## Goal
Replace the placeholder with three real Endless skins that match the floor template exactly, keep the
Wisp the brightest object on screen, and read well at every QA phone size.

## Inputs (from the owner)
`concept_art/wisp_rush_endless_v1/assets/01_endless_astral_observatory.png`,
`02_endless_drowned_sanctum.png` and `03_endless_moonpetal_shrine.png`, generated with
`floor_template_layout.png` attached. Stop and ask if any file is missing.

## Tasks
1. **Checker** `tools/art/check_endless_skin.py <png>...` (Pillow + numpy, like the other art tools).
   - Fail unless the image is 941×1672 RGB.
   - Estimate the painted floor with the heuristics in `tools/art/extract_floor_polygons.py` (import its
     functions; seed at the template centroid) and compare it with `floor_template.json`:
     - the painted floor covers at least 97 % of the template;
     - floor reaching more than `rim_tolerance_px` beyond the template is at most 3 % of the template area;
     - mean luminance inside the template is no more than 10 % above Obsidian Garden's runtime floor;
     - high-variance blobs (props) inside the template cover at most 1.5 % of its area.
   - Write `logs/endless/<name>_check.png` (template cyan, estimated floor orange, flagged blobs magenta),
     print a pass/fail line per metric, and exit 1 on any failure.
   - Calibrate the thresholds once: the placeholder must pass and a Rift background must fail on shape.
     Record the values in the script header.
2. **Review every overlay by eye.** A skin fails if the rim leaves the template band anywhere, or if
   anything inside the floor could read as an obstacle. Send failures back to the owner with the
   overlay and the fix-up prompt from GENERATION_PROMPTS.md.
3. **Extract** with `tools/art/extract_endless.py`, or a new section in `extract_rifts.py`: write
   `assets/art/environment/endless/<skin_id>.png`, applying a per-skin floor-dim and saturation table
   through a feathered **template** mask (not `ARENA_FLOOR_UV`). Never hand-edit the outputs.
4. **Data.** Add `res://data/endless/skins/{astral_observatory,drowned_sanctum,moonpetal_shrine}.tres`
   with names, descriptions and accents; starting prices 0 / 800 / 1,200; set
   `default_skin_id = astral_observatory`. Remove the placeholder from the catalog, but keep the tool option.
5. **Save.** Sanitizing moves `owned_arena_skins` / `equipped_arena_skin` entries for the placeholder to
   the default skin.
6. **QA.** Render Endless on every skin at the five QA sizes and check that:
   - the painted rim sits at the wall, so the Wisp rests on the floor edge;
   - the Wisp is the brightest small object;
   - amber telegraphs and magenta enemy cores read clearly;
   - nothing important is cropped at 20:9.

   Then do a device run on the owner's phone.

## Tests
`test_endless_catalog`: three skins, default `astral_observatory`, no placeholder skin in the catalog,
all 941×1672. The skin-equality check in `test_endless_mode` runs across all three skins.

## Docs
ASSETS.md rows (source: generated from the Endless v1 prompts; licence: generated art, confirm before
release — GDD §14 #1 and #21); endless_mode.md ✅ with the skin table; the status line of
GENERATION_PROMPTS.md; ROADMAP M10 spec 05 ✅ and the M6 placeholder line ✅; DEVLOG entry with the
checker numbers.

## Acceptance
- [ ] All three skins pass the checker and the eye review.
- [ ] No placeholder remains in the catalog, and saves move off it.
- [ ] QA sheets and a device run show the rim at the wall on every skin.
- [ ] `tools/validate.sh` OK · `tools/run_tests.sh` 0 failed.
