# Wisp Rush playable characters v2 — Ilyra and Bram

> **Status:** ✅ visual direction approved by the owner on 2026-09-18 · runtime implementation pending

This is the authoritative source pack for two new cosmetic playable characters. Implement them in
this order: **Ilyra first, then Bram**. Both use the existing `WispPlayer` controller and must keep
identical gameplay collision, health, movement, damage, scoring and controls.

| Order | Character | Tier | Approved reference |
|---:|---|---|---|
| 1 | **Ilyra, the Astral Dancer** | Mythic | [`references/ilyra_concept.png`](references/ilyra_concept.png) |
| 2 | **Bram, the Rift Knight** | Legendary | [`references/bram_concept.png`](references/bram_concept.png) |

The reference sheets are concept art, not runtime textures. Never display or ship a complete sheet.
Implementation must first create clean isolated RGBA layers and deterministic extraction metadata,
following the existing v1 character pipeline.

## Character intent

### Ilyra — Mythic

- Complete four-armed humanoid with exactly two legs, two folding crescent fans, twin articulated
  braids, six skirt panels, four waist ribbons, three crown pieces and a cyan heart core.
- About 34 moving groups. The Mythic value comes from layered choreography and follow-through, not
  a larger hitbox or excessive particles.
- Four arms counter-pose; fans fold and counter-rotate; braids, ribbons and skirt panels use distinct
  delays; the dash forms a narrow spearhead and recovers in a circular fan flourish.

### Bram — Legendary

- Compact full-bodied knight with helmet/visor, torso/core, connected arms and legs, shield, short
  soul-blade and two cape panels.
- Noticeably simpler than Ilyra. Large armor shapes, readable weight and deliberate anticipation
  carry the quality rather than continuous secondary motion.
- Shield-first dash, sword attack accent, weighted boot landing, subtle visor/core and cape motion.

## Handoff

- [`IMPLEMENTATION_BRIEF.md`](IMPLEMENTATION_BRIEF.md) — authoritative technical and animation spec.
- [`CLAUDE_IMPLEMENTATION_PROMPT.md`](CLAUDE_IMPLEMENTATION_PROMPT.md) — ready-to-paste task prompt.
- [`GENERATION_PROMPTS.md`](GENERATION_PROMPTS.md) — exact prompts used to make the approved sheets.

