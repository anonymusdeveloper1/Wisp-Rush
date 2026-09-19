#!/usr/bin/env python3
"""Turn an approved character concept sheet into a transparent rig-source sheet.

The approved sheets under ``concept_art/wisp_rush_playable_characters_v2/references/`` are opaque
presentation art. ``tools/art/extract_playable_characters.py`` needs a *transparent* sheet, because
it isolates parts by alpha connected components. This tool produces that sheet without touching the
approved reference, so the extraction stays deterministic and re-runnable:

* ``matte`` - the reference already carries a per-subject alpha channel (Ilyra). Alpha is rescaled
  to full range and near-zero noise is dropped; the painted RGB is never altered.
* ``key`` - the reference is opaque on near-black (Bram). Background is the border-connected dark
  region, so charcoal *inside* a part stays solid; the glow that bleeds into the background keeps a
  luminance-proportional alpha instead of being clipped to a hard edge.

    python3 tools/art/make_rig_source.py            # every configured character
    python3 tools/art/make_rig_source.py ilyra      # only this one

Requirements: Python 3.7+, Pillow 9.5, numpy 1.21 and scipy 1.7.
"""
import sys
from pathlib import Path
from typing import Dict, List, Optional

import numpy as np
from PIL import Image
from scipy import ndimage

REPO = Path(__file__).resolve().parents[2]
PACK = REPO / "concept_art/wisp_rush_playable_characters_v2"

# mode: "matte" keeps an existing alpha channel, "key" lifts the subject off a near-black ground.
# key_floor: luminance (0..255) at which a keyed pixel becomes fully opaque; noise_floor: the sheet's
# black level, below which a keyed pixel is fully transparent.
SHEETS: Dict[str, Dict[str, object]] = {
	"ilyra": {"reference": "ilyra_concept.png", "mode": "matte", "noise_floor": 4},
	"bram": {"reference": "bram_concept.png", "mode": "key", "key_floor": 16, "noise_floor": 8},
}


def matte_alpha(image: Image.Image, noise_floor: int) -> np.ndarray:
	"""Rescale an existing subject matte to full range and drop near-zero speckle."""
	alpha = np.asarray(image.getchannel("A")).astype(np.float32)
	peak = float(alpha.max())
	if peak <= 0.0:
		raise RuntimeError("reference has an empty alpha channel; it is not a matted sheet")
	alpha = np.clip(alpha * (255.0 / peak), 0.0, 255.0)
	alpha[alpha < noise_floor] = 0.0
	return alpha.astype(np.uint8)


def key_alpha(image: Image.Image, key_floor: int, noise_floor: int) -> np.ndarray:
	"""Lift a subject off a near-black ground, keeping enclosed darks solid and glow soft.

	[param key_floor] is deliberately low: Bram's charcoal under-suit reads around luminance 30-60
	and reaches the sheet border through the gaps between his armour plates, so a generous threshold
	would punch holes straight through him. Only the last few near-black levels are treated as
	background, and the pockets that remain enclosed are filled back in.
	"""
	rgb = np.asarray(image.convert("RGB")).astype(np.int32)
	luminance = rgb.max(axis=2)
	labels, count = ndimage.label(luminance <= key_floor)
	if count == 0:
		return np.full(luminance.shape, 255, dtype=np.uint8)
	border = set(labels[0, :]) | set(labels[-1, :]) | set(labels[:, 0]) | set(labels[:, -1])
	border.discard(0)
	outside = np.isin(labels, list(border))
	# Pockets of near-black that the border never reached belong to the character, not the ground.
	outside &= ~ndimage.binary_fill_holes(~outside)
	alpha = np.full(luminance.shape, 255.0, dtype=np.float32)
	# Anti-aliased edges keep a soft alpha, but the ramp starts above the sheet's black-level noise:
	# ramping from zero would leave the whole background faintly opaque, and the extractor would then
	# read the background itself as one enormous painted component.
	span: float = float(max(1, key_floor - noise_floor))
	alpha[outside] = np.clip((luminance[outside] - noise_floor) * (255.0 / span), 0.0, 255.0)
	return alpha.astype(np.uint8)


def build(name: str) -> Path:
	spec = SHEETS[name]
	reference = PACK / "references" / str(spec["reference"])
	if not reference.exists():
		raise FileNotFoundError(reference)
	image = Image.open(reference).convert("RGBA")
	mode = str(spec["mode"])
	if mode == "matte":
		alpha = matte_alpha(image, int(spec.get("noise_floor", 4)))
	elif mode == "key":
		alpha = key_alpha(image, int(spec.get("key_floor", 16)), int(spec.get("noise_floor", 8)))
	else:
		raise SystemExit("Unknown mode %r for %s" % (mode, name))
	out = image.copy()
	out.putalpha(Image.fromarray(alpha, "L"))
	destination = PACK / "assets" / ("%s_rig_source.png" % name)
	destination.parent.mkdir(parents=True, exist_ok=True)
	out.save(destination, optimize=True)
	opaque = int((alpha >= 250).sum())
	clear = int((alpha == 0).sum())
	print(
		"RIG SOURCE: %s (%s) -> %s  opaque=%d clear=%d soft=%d"
		% (name, mode, destination.relative_to(REPO), opaque, clear, alpha.size - opaque - clear)
	)
	return destination


def main(names: Optional[List[str]] = None) -> None:
	for name in names or list(SHEETS):
		if name not in SHEETS:
			raise SystemExit("Unknown character %r (known: %s)" % (name, ", ".join(SHEETS)))
		build(name)


if __name__ == "__main__":
	main(sys.argv[1:])
