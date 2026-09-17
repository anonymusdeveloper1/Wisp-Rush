# Asset Registry

> Rules for organising assets plus a registry of every asset pack/file in `assets/` — where it came
> from, its license and how it must be imported. **Every asset that enters the repo gets a row.**
>
> **Status: ✅ redesign v1 art in all runtime paths** ([ADR-0005](decisions/0005-visual-redesign-v1.md)).
> Runtime art under `assets/art/` is **generated** from `concept_art/wisp_rush_redesign_v1/` by
> `tools/art/extract_redesign.py` (+ `tools/art/redesign_v1_slices.json`, see `tools/art/README.md`):
> change the pipeline or the slice spec and re-run it — never hand-edit generated PNGs. The owner
> asset pack v2 is archived in `assets/legacy_v1/` (`.gdignore`, never imported or shipped).
> Release distribution remains blocked on the licence confirmation in [GDD.md](GDD.md) §14.

## Layout

```
assets/
├── art/
│   ├── characters/    player, enemies, NPCs (sprites / sheets / models)
│   ├── environment/   tiles, tilesets, backgrounds, props
│   ├── ui/            icons, panels, buttons, cursors
│   └── vfx/           particle textures, flashes, trails
├── audio/
│   ├── music/         looping tracks (.ogg)
│   └── sfx/           short effects (.wav, or .ogg if large)
├── fonts/             .ttf / .otf (+ license file)
└── shaders/           shared .gdshader files (feature-specific shaders live with their scene)
```

Sub-folders are created as needed; don't pre-create empty ones.

## Naming

- `snake_case`, descriptive, no spaces: `wisp_idle_sheet.png`, `ember_imp_run_sheet.png`.
- Variants get a numeric suffix: `sfx_dash_01.wav`, `sfx_dash_02.wav`.
- Prefix audio by kind: `music_<name>.ogg`, `sfx_<name>.wav`, `ui_<name>.wav`.
- Sprite sheets end in `_sheet`; record frame size in the registry notes (e.g. `32×32, 8 frames`).

## Import rules

- **Never hand-edit `*.import` files.** Change import settings in the editor (Import dock →
  Reimport) or via MCP, then commit the updated `.import` file.
- Pixel art (if the GDD chooses it): set Project Settings → Rendering → Textures → Canvas
  Textures → Default Texture Filter = **Nearest**, and disable mipmaps.
- Music `.ogg` → loop enabled in import settings. SFX `.wav` → no loop.
- Keep original source files (`.aseprite`, `.psd`, `.blend`) outside `assets/` or in a
  `.gdignore`'d `assets/_source/` folder so Godot doesn't import them.

## Intake procedure (when new assets arrive)

1. Inspect the pack: list files, formats, dimensions/frame sizes, included license/readme.
2. Sort into the layout above, renaming to the naming rules (keep a mapping in the registry notes
   if the originals had meaningful names).
3. Add a registry row per pack or file.
4. Run `tools/validate.sh` (imports everything, refreshes `docs/generated/PROJECT_MAP.md`).
5. Add a DEVLOG entry.

## Registry

| Path (file or folder) | Kind | Source / author | License | Import notes | Added |
|---|---|---|---|---|---|
| `res://icon.svg` | project icon | created during setup | project-owned | default | 2026-09-11 |
| `res://assets/art/branding/` | stacked wordmark logo, transparent app-icon master (`config/icon`), opaque store icon, splash master | redesign v1: `16_wordmark_logo` (Home/loading logo), `14_brand_mark` (app icon, store icon and splash on `#111521`); `17_game_emblem_icon` is kept in the concept pack unused (owner reverted the icon 2026-09-15) | generated art; confirm before release | logo 1318×956; boot splash set in project.godot | 2026-09-11 |
| `res://assets/art/environment/` | `wisp_rush_arena_background` (arena floor), `home_background`, `menu_background` | redesign v1 `02`, `03`, `04` | generated art; confirm before release | 941×1672 opaque; cover-scale, never letterbox; Home uses home, other menus use menu | 2026-09-11 |
| `res://assets/art/characters/` | Wisp 12, enemies 12, Reaper 8 (+ `09_gate_arrival`, `10_exposed_core`, `11_corridor_cast`, `12_stagger`), forms 6 | redesign v1 `05_v2`, `06_v2`, `07_v2`, `12` (checkerboard removed) | generated art; confirm before release | legacy canvases kept (362 / 444 / 512) and content normalised to legacy occupancy, so scale, pivots and collision fit hold | 2026-09-11 |
| `res://assets/art/environment/props/` (Rifts additions `10`–`16`) | void portal entrance/exit pairs, obsidian pillar (+ cracked), floor warning marker, crumble edge, rubble, rune tile | Rifts v1 pack `05` | generated art; confirm before release | 362×362, state pairs share one scale so switching state never pops | 2026-09-12 |
| `res://assets/art/characters/enemies/` (Rifts additions `13`–`24`) | Cinder Shade, Warden and Rift Spawn, four frames each (art only; no tuning or behaviour) | Rifts v1 pack `06` | generated art; confirm before release | 362×362, one scale per family | 2026-09-12 |
| `res://assets/art/environment/props/` | soul shard (+ cluster, soul spark), split crystal, spike bloom, blade ring (+ `_warning` / `_active` / `_closed` states), void portal | redesign v1 `08` (checkerboard removed) | generated art; confirm before release | legacy 04/05/10/11/12 have no redesign equivalent (archived only) | 2026-09-11 |
| `res://assets/art/environment/rifts/` | four Rift backdrops: shattered, ember hollow, frozen choir, reaper's court | Rifts v1 pack `01`–`04`, generated by the owner from `concept_art/wisp_rush_rifts_v1/GENERATION_PROMPTS.md` | generated art; confirm before release | **must stay 941×1672** or `ARENA_FLOOR_UV` (ADR-0006) misplaces the playfield; frozen choir floor dimmed 0.52 and saturation rescaled per Rift so the Wisp stays the brightest object | 2026-09-12 |
| `res://assets/art/characters/{the_fracture,cinder_maw}/` | 12-frame boss atlases for the Shattered Rift and Ember Hollow | Rifts v2 pack `08`, `09` | generated art; confirm before release | 444×444 canvas matching the Reaper; wired as `BossData` variants (ADR-0010) | 2026-09-12 |
| `res://assets/art/characters/hollow_choir/` | 12-frame second-boss atlas | Rifts v1 pack `07` | generated art; confirm before release | 444×444 canvas matching the Reaper; wired as a `BossData` variant | 2026-09-12 |
| `res://assets/art/environment/endless/<skin_id>.png` (30) and `thumbnails/<skin_id>.png` (30) | Endless arena backgrounds on the shared floor template, and 282×502 Shop card thumbnails | `python3 tools/art/extract_endless.py` from `concept_art/wisp_rush_endless_v1/assets` (checked by `check_endless_skin.py`) | generated art; licence to confirm before release (GDD §14 #1, #21) | 941×1672 opaque RGB; lossy import (quality 0.8, `set_endless_import_lossy.py`); referenced by `data/endless/skins/<skin_id>.tres` (`background_path`, `thumbnail`); never hand-edit | 2026-09-15 |
| `res://assets/art/environment/endless/masks/<skin_id>.png` (10) | Scenery masks of the Legendary/Mythic Endless skins: R emissive light sources, G distortion regions, B scenery weight (0 on the floor, 1 past the 48 px rim tolerance), A zone id | `python3 tools/art/endless_scenery.py` from the runtime backgrounds, the floor template and its `SCENERY` table | derived from the generated backgrounds; same licence note | 471×836 RGBA; lossy import q0.8 (`set_endless_import_lossy.py`), 1.1 MB source → 0.31 MB imported; referenced by `data/endless/skins/<skin_id>.tres` (`scenery.mask`); never hand-edit | 2026-09-16 |
| `concept_art/wisp_rush_endless_v1/assets/` | 30 final-source cosmetic Endless arena backgrounds and `skins_manifest.json` | Codex built-in ImageGen from `SKIN_SET_PROMPT.md` using `floor_template_layout.png` and the owner's playfield guide | generated art; confirm before release | 941×1672 opaque RGB PNG; source pack under `concept_art/.gdignore`, runtime-integrated 2026-09-15 through spec 05's checker/extraction (all 30); keep all 30 on the shared octagonal floor template | 2026-09-15 |
| `res://assets/art/vfx/` | 12 legacy effects + `13_victory_pulse` | redesign v1 `09` (black background → straight alpha) | generated art; confirm before release | normal blending is correct; additive would double-brighten | 2026-09-11 |
| `res://assets/art/ui/` | `system/` icons (10 legacy + `13_daily`…`18_reaper`), `mutations/` 8, `frames/` 13 frame-kit pieces | redesign v1 `11`, `13_v2`, `10` | generated art; confirm before release | `09_mute`, `12_store` dropped; frames feed the theme | 2026-09-11 |
| `res://assets/ui/theme/` | project Theme, nine-patch textures, ornaments | built from `assets/art/ui/frames/` by `assets/ui/theme/tools/*` | project-owned build | rebuild steps in [ui_design_system.md](systems/ui_design_system.md); never hand-edit the `.tres` | 2026-09-11 |
| `res://assets/legacy_v1/` | archived owner asset pack v2 (all rows below) | owner-supplied `Wisp Rush Godot Release MVP v2.zip` | not stated | `.gdignore` — restore = move back + delete `.gdignore` | 2026-09-11 |
| `legacy_v1/art/branding/` | logo, 2048² icon master, portrait splash master | owner-supplied `Wisp Rush Godot Release MVP v2.zip` | not stated; confirm before release | PNG; original names normalised from kebab-case | 2026-09-11 |
| `legacy_v1/art/environment/wisp_rush_arena_background.png` | full-bleed arena | same pack, `master-sheets/world/` | not stated; confirm before release | 941×1672 PNG; cover-scale and crop, never letterbox | 2026-09-11 |
| `legacy_v1/art/characters/wisp/` | 12 Wisp animation states | same pack, `individual-sprites/riftling/` | not stated; confirm before release | 362×362 RGBA frames; numeric order retained; runtime name is Wisp | 2026-09-11 |
| `legacy_v1/art/characters/enemies/` | 12 frames across three enemy families | same pack, `individual-sprites/enemies/` | not stated; confirm before release | 362×362 RGBA; Soul Wisp, Shard Wraith, Bone Mote | 2026-09-11 |
| `legacy_v1/art/characters/reaper/` | 8 Reaper boss states | same pack, `individual-sprites/reaper/` | not stated; confirm before release | 444×444 source cells exported as individual PNGs | 2026-09-11 |
| `legacy_v1/art/characters/forms/` | 6 cosmetic forms | same pack, `individual-sprites/forms/` | not stated; confirm before release | 512×512 RGBA; cosmetic visuals only | 2026-09-11 |
| `legacy_v1/art/environment/props/` | 12 pickup/obstacle/prop sprites | same pack, `individual-sprites/props/` | not stated; confirm before release | 362×362 RGBA | 2026-09-11 |
| `legacy_v1/art/vfx/` | 12 combat/teleport/collectible effects | same pack, `individual-sprites/vfx/` | not stated; confirm before release | 362×362 RGBA; pool frequent effects later | 2026-09-11 |
| `legacy_v1/art/ui/system/` | 12 system icons | same pack, `individual-sprites/ui/` | not stated; confirm before release | 362×362 RGBA; keep touch target larger than artwork | 2026-09-11 |
| `legacy_v1/art/ui/mutations/` | 8 mutation icons | same pack, `individual-sprites/mutations/` | not stated; confirm before release | 362×362 RGBA | 2026-09-11 |

## Intake provenance

- Source archive: owner-supplied `Wisp Rush Godot Release MVP v2.zip`, received 2026-09-11.
- Build prompt: standalone and archived copies are byte-identical (SHA-256
  `c174ff790b03ed583efac91ef2b44d46e2f6e80b727890800918a4b6fc0ab60b`).
- Imported runtime set: 86 PNG files (82 individual sprites, three branding masters, one arena).
- Original numeric prefixes are retained; hyphens changed to underscores for project naming rules.
- Master sprite sheets, platform convenience exports, contact sheets and all `reference/legacy-*`
  files remain outside `res://` and therefore cannot enter a game export.
- The pack contains no audio, fonts, license, copyright or author metadata.
