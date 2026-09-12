# Wisp Rush

Wisp Rush is a portrait, one-finger survival arcade game built with Godot **4.7.2** and typed
GDScript. Swipe to launch the Wisp in a straight line, slice enemies along the path, stop at the
physical screen edge and redirect before the soul chain fades.

## Current build

Milestone 2 is complete. The repository now contains a playable endless-run foundation:

- Full-bleed production-art Home and arena presentation.
- Touch swipe, mouse drag and WASD/arrow-key aiming.
- Release/Space dash with exact first-edge landing and inward correction at touched edges.
- Wall impact, short Wisp Focus slowdown and production Wisp animations.
- Threat-budgeted 22-second waves with 20 validated, mirrored/rotated formation templates.
- Soul Wisp, two-hit Shard Wraith and three-hit Bone Mote with warned actions.
- Split crystal, spike bloom and blade-ring hazards with swept dash interaction.
- Score, combo, multi-reap/rapid-redirect bonuses and working Pause/Resume/Home navigation.
- Three Soul Fragments, enemy contact, safe-edge reform, visible i-frames and death dissolve.
- Integrated first-run wall dash → single slice → triple reap lesson.
- Enemy XP, safe three-card choices and all eight functional run mutations.
- Separate Soul Shard drops/rewards plus score, best, wave, kill, chain and run Results statistics.

The three-phase Reaper, persistent save/forms and local daily/challenge systems are next; see
[docs/ROADMAP.md](docs/ROADMAP.md). This build is not yet the release-complete MVP.

## Run it

```bash
# Open the project in the editor
open -a ~/Desktop/Godot.app --args --path "$PWD" --editor

# Run the main scene
/Users/dimitarslezenkovski/Desktop/Godot.app/Contents/MacOS/Godot --path .

# Import, parse every game script, boot and refresh the project inventory
tools/validate.sh
```

Requirements: Godot 4.7.2 at `/Users/dimitarslezenkovski/Desktop/Godot.app`; Node.js 20+ for the
generated project map and Godot MCP server.

## Controls

| Action | Touch / mouse | Desktop keyboard |
|---|---|---|
| Aim | Hold and drag | Hold WASD or arrows |
| Rush | Release a valid drag | Space |
| Pause / back | Pause icon | Escape |

The swipe points in the travel direction. Swipe length only decides whether the gesture is valid;
it never changes speed, damage or distance.

## Verification

```bash
# Pure edge-intersection and swept-distance checks
/Users/dimitarslezenkovski/Desktop/Godot.app/Contents/MacOS/Godot \
  --headless --path . --script res://tools/godot/test_dash_geometry.gd

# Live dash → four kills → combo → wall landing and Pause/Resume check
/Users/dimitarslezenkovski/Desktop/Godot.app/Contents/MacOS/Godot \
  --headless --path . --script res://tools/godot/test_gameplay_slice.gd

# Home → Play/Pause/Home → Results → session-gated Restart check
/Users/dimitarslezenkovski/Desktop/Godot.app/Contents/MacOS/Godot \
  --headless --path . --script res://tools/godot/test_game_flow.gd

# Health component and live contact → i-frames → death → summary checks
/Users/dimitarslezenkovski/Desktop/Godot.app/Contents/MacOS/Godot \
  --headless --path . --script res://tools/godot/test_health_component.gd
/Users/dimitarslezenkovski/Desktop/Godot.app/Contents/MacOS/Godot \
  --headless --path . --script res://tools/godot/test_player_health_flow.gd

# Integrated wall dash → single slice → triple reap lesson
/Users/dimitarslezenkovski/Desktop/Godot.app/Contents/MacOS/Godot \
  --headless --path . --script res://tools/godot/test_tutorial_flow.gd

# Formation catalog/director and all three enemy families
/Users/dimitarslezenkovski/Desktop/Godot.app/Contents/MacOS/Godot \
  --headless --path . --script res://tools/godot/test_wave_director.gd
/Users/dimitarslezenkovski/Desktop/Godot.app/Contents/MacOS/Godot \
  --headless --path . --script res://tools/godot/test_enemy_families.gd

# Hazard state/geometry plus a live crystal-blocked dash
/Users/dimitarslezenkovski/Desktop/Godot.app/Contents/MacOS/Godot \
  --headless --path . --script res://tools/godot/test_hazards.gd
/Users/dimitarslezenkovski/Desktop/Godot.app/Contents/MacOS/Godot \
  --headless --path . --script res://tools/godot/test_hazard_gameplay.gd

# XP/choice rules and all eight live mutation effects
/Users/dimitarslezenkovski/Desktop/Godot.app/Contents/MacOS/Godot \
  --headless --path . --script res://tools/godot/test_run_progression.gd
/Users/dimitarslezenkovski/Desktop/Godot.app/Contents/MacOS/Godot \
  --headless --path . --script res://tools/godot/test_mutation_effects.gd

# Render a visual at the default debug size or a requested window aspect
tools/screenshot.sh res://scenes/gameplay/game_world.tscn 30 390x844
```

With `canvas_items` + `expand`, the screenshot PNG stays at the 1080×1920 design output while the
requested window aspect changes the live logical arena. The Godot log records that expanded size.

## Project orientation

Start with [AGENTS.md](AGENTS.md), then [docs/PROJECT_CONTEXT.md](docs/PROJECT_CONTEXT.md).

| Document | Purpose |
|---|---|
| [docs/GDD.md](docs/GDD.md) | Authoritative release-MVP design from the owner's v2 prompt |
| [docs/ROADMAP.md](docs/ROADMAP.md) | Current milestone and complete release sequence |
| [docs/ASSETS.md](docs/ASSETS.md) | Imported pack, provenance, naming and release-license risk |
| [docs/generated/PROJECT_MAP.md](docs/generated/PROJECT_MAP.md) | Generated exhaustive inventory |
| [docs/systems/](docs/systems/) | Per-system rules, API, tuning and test guidance |
| [docs/DEVLOG.md](docs/DEVLOG.md) | Newest-first work-session history |

## Release notes

Android/iOS export presets, final identifiers, signing and device builds belong to the release
milestone. The owner-supplied ZIP has no license/copyright file and no audio; both are explicitly
tracked in [docs/GDD.md](docs/GDD.md) §14 rather than being silently assumed.
