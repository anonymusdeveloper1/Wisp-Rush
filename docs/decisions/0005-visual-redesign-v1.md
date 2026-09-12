# ADR-0005: Adopt visual redesign v1

> **Status:** Accepted · **Date:** 2026-09-11 · **Deciders:** owner (requested) + Claude Code

## Context
The first production art (violet/plum, owner asset pack v2) shipped with baked checkerboards, clipped
Reaper cells and a violet UI. A Codex agent then produced a complete redesign concept pack in
`concept_art/wisp_rush_redesign_v1/`: a new palette (charcoal/slate with soul cyan, warning amber and
rift magenta as information colours), a top-down obsidian sanctuary arena, new characters, VFX, a
stone UI frame kit, icons, a wordmark and a six-screen UX handoff board, with a style guide. The owner
asked to archive the current assets and redesign the game with the new UI/UX specs and assets.

## Options considered
1. **Hand-integrate files ad hoc** — fast for a few screens, but atlas slicing and checker cleanup
   would not be reproducible and scenes would drift from the style guide.
2. **Same-path replacement + reproducible pipeline + Theme-based design system** — archive the old
   art under an ignored folder, regenerate every runtime file at its existing path from the concept
   sheets with a scripted pipeline, then restyle screens through one Godot Theme.
3. **Keep both art sets switchable at runtime** — flexible, but doubles asset weight and QA for a
   design the owner has already chosen.

## Decision
Option 2.
- Legacy art moves to `assets/legacy_v1/` with a `.gdignore`, so nothing can reference or ship it;
  restoring is a folder move.
- `tools/art/extract_redesign.py` + `tools/art/redesign_v1_slices.json` regenerate `assets/art/` from
  the untouched concept sheets (cell slicing, checkerboard difference-matting, black→alpha for
  additive VFX, normalisation to the legacy canvas/occupancy so scale, pivots and collision fit hold).
- A project-wide Theme (`assets/ui/theme/wisp_theme.tres`) built from the frame kit, with named type
  variations, plus `Palette` colour constants, replaces per-node violet overrides
  ([ui_design_system.md](../systems/ui_design_system.md)).
- `STYLE_GUIDE.md` in the concept pack is the art/UX authority; GDD §9 summarises it.

## Consequences
- Scenes keep their node structure and tests; screens now depend on theme type variations.
- New art must enter through the pipeline (or be registered in `docs/ASSETS.md` with its source).
- Concept sheets stay in `concept_art/` as sources and are not part of runtime paths.
- The art licence question (GDD §14 #1) now applies to generated redesign art as well.
