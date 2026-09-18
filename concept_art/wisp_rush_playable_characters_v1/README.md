# Playable character source art v1

This directory preserves the approved inputs for the three animated playable characters
([docs/systems/playable_character_visuals.md](../../docs/systems/playable_character_visuals.md),
[ADR-0015](../../docs/decisions/0015-animated-playable-characters.md)).

- `references/{veyra,rook,morrow}_concept.jpg` are the owner-supplied identity references (the three
  character sheets attached to the 2026-09-17 request).
- `assets/{veyra,rook,morrow}_rig_source.png` are the transparent layered source sheets generated
  with OpenAI's image-generation tool from those references.
- `GENERATION_PROMPT.md` records the exact generation request and cell order of each sheet.
- `tools/art/extract_playable_characters.py` isolates the runtime layers under
  `assets/art/characters/playable/<id>/` and prints the ribbon spines the rigs bend along.

The complete source sheets are never loaded by the game. Re-run the extractor after intentionally
replacing a sheet, inspect `logs/playable_characters/<id>_parts.png`, then paste the printed spines
into that character's rig scene.

## Generation brief

Each sheet is a clean 4-by-3 cutout-rig grid on a genuinely transparent background: an assembled
neutral front preview plus isolated parts, matching the reference's palette, materials and
silhouette, with real alpha and no labels, background, shadow, border or watermark.

| Character | Parts, in cell order |
|---|---|
| Veyra, the Last Wisp | preview · outer flame body · inner core · eyes · left fin · right fin · halo fragments · tail ribbon A · tail ribbon B · tail ribbon C · soul spark |
| Rook, the Bonewing | preview · shadow body · skull plate · left wing frame · right wing frame · left membrane · right membrane · paired feet · tail segment · crescent tail fin · dash streak · wing dust |
| Morrow, the Runebound | preview · cloak body · hood · mask · front cloak flap · left hand · right hand · rune stone · scarf ribbon A · scarf ribbon B · rune fragment · cloth wisp |

"Left" and "right" are the character's own sides: they face the camera, so a left wing or hand is on
screen right. The extractor splits Veyra's halo cell into two groups so each side floats on its own.
