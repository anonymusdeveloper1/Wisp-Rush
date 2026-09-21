# Noxen — rig source pack

**Noxen, the Veilflame** is the blue/cyan, handless creature approved from the final
`verdant_shade_v1` direction. He has no arms or conventional legs: his cloak fins, flame horns and
two root-like spectral ribbons carry the readable secondary motion.

## Source files

- `assembly/noxen_assembly_reference.png` — approved neutral silhouette and colour reference.
- `noxen_parts_sheet.png` — transparent twelve-part generation sheet.
- `extract_parts.py` — deterministic intake which creates `parts/noxen/` and its pivot manifest.
- `parts/noxen/` — versioned, per-part source consumed by `tools/art/extract_playable_characters.py`.

Regenerate in this order from the repository root:

```text
python concept_art/noxen_v1/extract_parts.py
python tools/art/extract_playable_characters.py noxen
python tools/art/build_character_rig.py noxen
```

The implementation is presentation-only. Noxen uses the same collision, movement and damage rules
as every other form.
