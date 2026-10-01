# Stitchwarden's Vigil — revised art sources

These pieces replace the mismatched board, doll, weapon and close jungle in the first layered implementation. The owner's `ChatGPT Image Sep 30, 2026, 01_04_52 AM.png` was the visual reference. Codex built-in ImageGen produced `backdrop.png`, `board.png`, `body.png`, `head.png`, `scythe.png`, `fire.png` and `floor.png`. The cloth, lantern, fog, wisp and bat PNGs came from the first Stitchwarden kit; its two cloth panels and their shader motion remain in use.

The generation prompts used these directions:

| Source | Prompt direction |
|---|---|
| `backdrop.png` | Recreate only the target's dark moonlit jungle ruins with distant broken towers, a right-side waterfall, sparse torches and a lower stone path; remove the doll, weapon, board and cloth, leaving an open center. Portrait 2D pixel art, limited palette, crisp grid, no blur, gradient, painterly or 3D rendering. |
| `board.png` | Isolate the target's narrow upright wood-and-stone board on transparency, with four amber lanterns and warm tan tiles. Subsequent edits widened the floor to five columns, shortened its empty length, and added irregular stitched wraps and moss. The runtime frame receives a mild top taper; the playable floor stays rectangular. |
| `body.png` | Extract the target's stitched cream hood, horizontal folded scarf, patched brown torso, strap, shoulder cloth and both dark gloves gripping an invisible top rail. Leave the hood cavity empty for a separate face. Transparent 2D pixel art. |
| `head.png` | Isolate only the round stitched burlap face, with the left X-button eye, glowing amber right eye and sewn mouth; no hood, scarf or body. Transparent 2D pixel art. |
| `scythe.png` | Isolate the complete dark ceremonial crescent scythe without fire, doll, hand or background. Transparent 2D pixel art. |
| `fire.png` | Isolate only a thin living orange flame tracing the scythe blade's outer curved edge, from its lower left tip toward the hub. Transparent 2D pixel art. |
| `floor.png` | Draw only a quiet rectangular tan limestone tile surface, five columns and ten rows, with subtle seams, cracks and wear, for gameplay beneath Wisp and enemies. 2D pixel art. |

`python concept_art/arenas_v2/stitchwarden_vigil/pack_vigil.py` builds the generated runtime PNGs, layered Godot scene, Shop still, thumbnail and review images. Runtime sprites have hard alpha, limited palettes and nearest filtering. The packer splits the board into a frame and an unobstructed 120 × 264-texel floor; the character and attacks use that exact floor rectangle for walls. The scythe and flame share a measured placement so the fire follows the outer blade from tip to hub. The generated scene uses the body texture twice: the main body hides the hood, and a hood-only copy shares `HeadRig` with the separate face. This turns the entire head, while the body shader moves the scarf, shoulder cloth and tunic and leaves the gloves on the rail. The two long cloth strips wave and respond to the doll's turn.
