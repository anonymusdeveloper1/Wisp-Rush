# Prompt for Claude

Implement the two owner-approved playable characters in Wisp Rush, strictly in this order:

1. **Ilyra, the Astral Dancer — Mythic**
2. **Bram, the Rift Knight — Legendary**

Start by reading `AGENTS.md` and its required project documentation, then read the complete approved
source pack at `concept_art/wisp_rush_playable_characters_v2/`, especially
`IMPLEMENTATION_BRIEF.md`. The approved visual references are
`references/ilyra_concept.png` and `references/bram_concept.png`; preserve those identities and do
not redesign them.

Fully implement and verify Ilyra before creating Bram's runtime files. If Ilyra is blocked, report
the blocker instead of skipping to Bram. Once Ilyra passes her art extraction, all 13 visual states,
targeted tests, Reduced Motion, Shop/Home previews and real GameWorld visual QA, implement Bram and
run the same gate, followed by the full regression/phone/performance pass.

Use the existing `PlayableCharacterVisual` architecture and existing Wisp controller. These are
presentation-only cosmetic rigs: identical controller, collision footprint, health, movement, dash,
damage, scoring, camera and controls. Never add physics/collision nodes to a visual rig. Reuse the
existing AnimationTree, `ChainSpring`, `RibbonChain`, preview, save and Shop systems instead of
building replacements.

The complete concept sheets must never be used in-game. Create clean transparent rig-source sheets,
extend the deterministic playable-character extraction pipeline without changing v1 output, and
extract isolated RGBA layers under `assets/art/characters/playable/ilyra/` and `bram/`. Do not ship
black/grey matte edges, clipped glow, rough geometry or placeholder art. If the approved sheets cannot
produce clean layers with the available tooling, stop and state the exact art blocker.

Ilyra must remain a complete four-armed, two-legged humanoid. Her Mythic rig should coordinate two
folding fans, four connected arm chains, twin articulated braids, six skirt panels, four waist
ribbons, three crown pieces and her heart core, with no snapping or detached anatomy. Use the state
beats and particle ceiling in the brief. Bram must remain a simpler full-bodied knight with connected
limbs, shield, short soul-blade and two cape panels; his quality comes from weight and anticipation,
not extra orbiters or effects.

Add `ilyra` and then `bram` to the existing FormData/catalog/save flow, raising the catalog count to
11. Keep both at 0 RP for review unless the owner provides prices. Add presentation-only typed tier
metadata: Ilyra is `MYTHIC`, Bram is `LEGENDARY`, existing characters default to `STANDARD`; show it
cleanly in the focused Shop character UI without changing gameplay.

Run the exact validation, tests, Godot play checks, screenshots/contact sheets, phone QA, benchmark
and documentation updates listed in `IMPLEMENTATION_BRIEF.md`. Preserve unrelated worktree changes.
Do not commit or push unless the owner explicitly asks. Finish with a concise report of files,
verification results and any remaining art/device limitations.

