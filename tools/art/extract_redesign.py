#!/usr/bin/env python3
"""Wisp Rush redesign v1 art extraction pipeline.

Slices the approved concept sheets in concept_art/wisp_rush_redesign_v1/assets into runtime
PNGs under assets/art, driven by tools/art/redesign_v1_slices.json. Sources are never modified.

Requirements: Python 3.7+, Pillow 9.5, numpy 1.21 (no other dependencies).

    python3 tools/art/extract_redesign.py                 # build everything + contact sheets
    python3 tools/art/extract_redesign.py --only wisp vfx # rebuild some groups
    python3 tools/art/extract_redesign.py --no-contact    # skip contact sheets

Cleanup modes (per sheet, see tools/art/README.md):
    alpha    - sheet already has alpha; segment it into connected components.
    black    - additive art on black; alpha = max(r,g,b), rgb unpremultiplied, then components.
    checker  - baked checkerboard; difference matting against the reconstructed checker.
    opaque   - full-frame plate; copied/resized as RGB.
"""
import argparse
import json
import os
import shutil
import sys
from typing import Dict, List, Optional, Tuple

import numpy as np
from PIL import Image, ImageDraw

REPO = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
CONFIG_DEFAULT = os.path.join(REPO, "tools", "art", "redesign_v1_slices.json")

Box = Tuple[int, int, int, int]


# --------------------------------------------------------------------------- basic helpers

def hex_rgb(value: str) -> Tuple[int, int, int]:
	value = value.lstrip("#")
	return (int(value[0:2], 16), int(value[2:4], 16), int(value[4:6], 16))


def load_rgba(path: str) -> np.ndarray:
	"""Returns float32 HxWx4: rgb 0..255 (straight), alpha 0..1."""
	im = Image.open(path).convert("RGBA")
	arr = np.asarray(im).astype(np.float32)
	arr[:, :, 3] /= 255.0
	return arr


def to_image(arr: np.ndarray) -> Image.Image:
	out = np.zeros(arr.shape, np.uint8)
	alpha = np.clip(arr[:, :, 3], 0.0, 1.0)
	out[:, :, :3] = np.clip(arr[:, :, :3] + 0.5, 0, 255).astype(np.uint8)
	out[:, :, 3] = np.clip(alpha * 255.0 + 0.5, 0, 255).astype(np.uint8)
	out[out[:, :, 3] == 0, :3] = 0
	return Image.fromarray(out, "RGBA")


def bbox(mask: np.ndarray) -> Optional[Box]:
	ys = np.nonzero(mask.any(axis=1))[0]
	xs = np.nonzero(mask.any(axis=0))[0]
	if len(xs) == 0:
		return None
	return (int(xs[0]), int(ys[0]), int(xs[-1]) + 1, int(ys[-1]) + 1)


def dilate(mask: np.ndarray, radius: int) -> np.ndarray:
	"""Binary dilation; alternates 4- and 8-neighbour steps for a roughly round footprint."""
	m = mask.copy()
	for i in range(int(radius)):
		n = m.copy()
		n[1:] |= m[:-1]
		n[:-1] |= m[1:]
		n[:, 1:] |= m[:, :-1]
		n[:, :-1] |= m[:, 1:]
		if i % 2 == 1:
			n[1:, 1:] |= m[:-1, :-1]
			n[:-1, :-1] |= m[1:, 1:]
			n[1:, :-1] |= m[:-1, 1:]
			n[:-1, 1:] |= m[1:, :-1]
		m = n
	return m


def box_mean(arr: np.ndarray, radius: int) -> np.ndarray:
	"""Mean over a (2r+1)^2 window (edges normalised by the valid pixel count)."""
	r = int(radius)

	def one(a2: np.ndarray) -> np.ndarray:
		h, w = a2.shape
		c = np.zeros((h + 1, w + 1), np.float64)
		c[1:, 1:] = np.cumsum(np.cumsum(a2, axis=0), axis=1)
		y0 = np.clip(np.arange(h) - r, 0, h)
		y1 = np.clip(np.arange(h) + r + 1, 0, h)
		x0 = np.clip(np.arange(w) - r, 0, w)
		x1 = np.clip(np.arange(w) + r + 1, 0, w)
		s = c[y1][:, x1] - c[y0][:, x1] - c[y1][:, x0] + c[y0][:, x0]
		n = (y1 - y0)[:, None] * (x1 - x0)[None, :]
		return (s / n).astype(np.float32)

	if arr.ndim == 2:
		return one(arr)
	return np.stack([one(arr[:, :, i]) for i in range(arr.shape[2])], axis=2)


def label(mask: np.ndarray) -> Tuple[np.ndarray, int]:
	"""8-connected component labelling (run-length union-find). 0 = background."""
	h, w = mask.shape
	pad = np.zeros((h, w + 2), np.int8)
	pad[:, 1:-1] = mask
	d = np.diff(pad, axis=1)
	ys, xs = np.nonzero(d == 1)
	_, xe = np.nonzero(d == -1)
	n = len(ys)
	lab = np.zeros((h, w), np.int32)
	if n == 0:
		return lab, 0
	ys_l = ys.tolist()
	xs_l = xs.tolist()
	xe_l = xe.tolist()
	row_start = np.searchsorted(ys, np.arange(h + 1)).tolist()
	parent = list(range(n))

	def find(i: int) -> int:
		root = i
		while parent[root] != root:
			root = parent[root]
		while parent[i] != root:
			parent[i], i = root, parent[i]
		return root

	for y in range(1, h):
		i, i1 = row_start[y - 1], row_start[y]
		j, j1 = row_start[y], row_start[y + 1]
		while i < i1 and j < j1:
			if xs_l[i] <= xe_l[j] and xs_l[j] <= xe_l[i]:
				ri, rj = find(i), find(j)
				if ri != rj:
					if ri < rj:
						parent[rj] = ri
					else:
						parent[ri] = rj
			if xe_l[i] < xe_l[j]:
				i += 1
			else:
				j += 1
	ids: Dict[int, int] = {}
	for k in range(n):
		root = find(k)
		idx = ids.get(root)
		if idx is None:
			idx = len(ids) + 1
			ids[root] = idx
		lab[ys_l[k], xs_l[k]:xe_l[k]] = idx
	return lab, len(ids)


class Segmentation:
	"""Global component labelling of one sheet's alpha."""

	def __init__(self, alpha: np.ndarray, seed: float, grow: int, cut: Optional[np.ndarray] = None) -> None:
		self.seed_mask = alpha > seed
		base = dilate(self.seed_mask, grow) if grow > 0 else self.seed_mask
		if cut is not None:
			base = base & ~cut
		lab, count = label(base)
		lab[~self.seed_mask] = 0
		if cut is not None:
			lab[cut] = 0
		self.lab = lab
		self.count = count
		flat = lab.ravel()
		self.area = np.bincount(flat, minlength=count + 1).astype(np.float64)
		yy, xx = np.indices(lab.shape)
		with np.errstate(invalid="ignore", divide="ignore"):
			self.cx = np.bincount(flat, weights=xx.ravel(), minlength=count + 1) / self.area
			self.cy = np.bincount(flat, weights=yy.ravel(), minlength=count + 1) / self.area
		self.area[0] = 0


# --------------------------------------------------------------------------- cleanup modes

def black_to_alpha(rgb: np.ndarray, floor: float) -> np.ndarray:
	"""Additive art on black -> straight alpha: alpha = max(r,g,b), rgb = rgb / alpha."""
	p = np.clip((rgb - floor) * (255.0 / (255.0 - floor)), 0.0, 255.0)
	alpha = p.max(axis=2) / 255.0
	out = np.zeros(rgb.shape[:2] + (4,), np.float32)
	safe = np.maximum(alpha, 1e-6)[:, :, None]
	out[:, :, :3] = np.clip(p / safe, 0.0, 255.0)
	out[:, :, 3] = alpha
	return out


def _grid_boundaries(cls: np.ndarray, axis: int) -> np.ndarray:
	"""Checker square boundaries along one axis, in half-pixel units (2*x = on pixel x)."""
	c = cls if axis == 1 else cls.T
	w = c.shape[1]
	hist = np.zeros(2 * w + 2, np.float64)
	direct = (c[:, :-1] * c[:, 1:]) < 0
	hist[1:2 * w - 1:2] += direct.sum(axis=0)
	mixed = (c[:, :-2] * c[:, 2:] < 0) & (c[:, 1:-1] == 0)
	hist[2:2 * w - 2:2] += mixed.sum(axis=0)
	sm = np.convolve(hist, [1, 2, 1], mode="same")
	thr = 0.2 * np.percentile(sm[sm > 0], 95)
	peaks = []
	pos = 0
	while pos < len(hist):
		if sm[pos] >= thr:
			end = pos
			while end + 1 < len(hist) and sm[end + 1] >= thr:
				end += 1
			seg = hist[pos:end + 1]
			if seg.sum() > 0:
				peaks.append(float((np.arange(pos, end + 1) * seg).sum() / seg.sum()))
			pos = end + 1
		else:
			pos += 1
	# Merge double detections (direct + mixed-pixel transitions of the same edge).
	merged: List[List[float]] = []
	for pk in peaks:
		weight = float(hist[int(round(pk))]) + 1.0
		if merged and pk - merged[-1][0] / merged[-1][1] < 6.0:
			merged[-1][0] += pk * weight
			merged[-1][1] += weight
		else:
			merged.append([pk * weight, weight])
	return np.array([m[0] / m[1] for m in merged]) / 2.0


def _strip_boundaries(lum: np.ndarray, mid: float, axis: int, border: int) -> np.ndarray:
	"""Square boundaries measured only in the clean border strips (the checker lines run
	straight across the sheet): sub-pixel mid-level crossings, clustered over the strip."""
	if axis == 1:
		rows = np.concatenate([lum[:border], lum[-border:]], axis=0)
	else:
		rows = np.concatenate([lum[:, :border], lum[:, -border:]], axis=1).T
	pos: List[float] = []
	for r in rows:
		d = r - mid
		xs = np.nonzero((d[:-1] * d[1:]) < 0)[0]
		for x in xs:
			pos.append(float(x) + float(d[x] / (d[x] - d[x + 1])))
	pos.sort()
	clusters: List[List[float]] = []
	for p in pos:
		if clusters and p - clusters[-1][-1] < 2.0:
			clusters[-1].append(p)
		else:
			clusters.append([p])
	need = 0.25 * len(rows)
	# A crossing at x + f lies between pixel centres x and x + 1 (pixel x spans [x - 0.5, x + 0.5]).
	return np.array([float(np.median(c)) for c in clusters if len(c) >= need])


def _regularise(bounds: np.ndarray, size: int) -> Tuple[np.ndarray, float]:
	"""Drops spurious boundaries and fills missing ones using the estimated square period."""
	gaps = np.diff(bounds)
	p0 = float(np.median(gaps))
	period = float(np.median(gaps[(gaps > 0.75 * p0) & (gaps < 1.5 * p0)]))
	out = [float(bounds[0])]
	for b in bounds[1:]:
		g = b - out[-1]
		if g < 0.7 * period:
			# Keep whichever of the two sits closer to one period after the boundary before.
			if len(out) >= 2 and abs((b - out[-2]) - period) < abs((out[-1] - out[-2]) - period):
				out[-1] = float(b)
			continue
		n = int(round(g / period))
		for k in range(1, n):
			out.append(out[-1] + (b - out[-1]) / (n - k + 1))
		out.append(float(b))
	while out[0] > 1.3 * period:
		out.insert(0, out[0] - period)
	while (size - 1) - out[-1] > 1.3 * period:
		out.append(out[-1] + period)
	return np.array(out), period


def _interval_index(bounds: np.ndarray, size: int) -> Tuple[np.ndarray, np.ndarray]:
	"""Square index of each pixel centre, and whether the pixel is clear of every boundary."""
	centres = np.arange(size, dtype=np.float64)
	idx = np.searchsorted(bounds, centres, side="right")
	dist = np.abs(centres[:, None] - bounds[None, :]).min(axis=1)
	return idx, dist >= 0.5


def _vote_parity(cls: np.ndarray, bx: np.ndarray, by: np.ndarray) -> Tuple[np.ndarray, np.ndarray, float]:
	"""Per-column / per-row square parity, corrected by majority vote against the visible
	checker so a single wrong boundary cannot flip the rest of the sheet."""
	ix, purex = _interval_index(bx, cls.shape[1])
	iy, purey = _interval_index(by, cls.shape[0])
	colpar = (np.arange(len(bx) + 1) % 2).astype(np.int8)
	rowpar = (np.arange(len(by) + 1) % 2).astype(np.int8)
	sel = (cls != 0) & purey[:, None] & purex[None, :]
	ys, xs = np.nonzero(sel)
	obs = cls[ys, xs] == 1
	cx, ry = ix[xs], iy[ys]
	agree_frac = 0.0
	for _ in range(4):
		for axis in (0, 1):
			par = colpar[cx] ^ rowpar[ry]
			light_is0 = obs[par == 0].mean() >= 0.5 if (par == 0).any() else True
			agree = ((par == 0) == light_is0) == obs
			keys, table = (cx, colpar) if axis == 0 else (ry, rowpar)
			n = np.bincount(keys, minlength=len(table))
			good = np.bincount(keys, weights=agree.astype(np.float64), minlength=len(table))
			flip = (n > 0) & (good < 0.5 * n)
			table[flip] ^= 1
		agree_frac = float(agree.mean())
	return colpar, rowpar, agree_frac


def _parity_fraction(bounds: np.ndarray, parity: np.ndarray, size: int) -> np.ndarray:
	"""Per pixel: fraction of the pixel span [x-0.5, x+0.5] lying in parity-0 squares."""
	edges = np.concatenate([[-1e9], bounds, [1e9]])
	out = np.zeros(size, np.float32)
	for x in range(size):
		lo, hi = x - 0.5, x + 0.5
		k = int(np.searchsorted(edges, lo, side="right")) - 1
		frac_even = 0.0
		cur = lo
		while cur < hi:
			nxt = min(hi, edges[k + 1])
			if parity[min(k, len(parity) - 1)] == 0:
				frac_even += nxt - cur
			cur = nxt
			k += 1
		out[x] = frac_even
	return out


def checker_matte(rgb: np.ndarray, p: dict, info: dict) -> np.ndarray:
	"""Removes a baked checkerboard by difference matting against the reconstructed checker."""
	h, w, _ = rgb.shape
	border = int(p.get("border", 24))
	strip = np.concatenate([rgb[:border].reshape(-1, 3), rgb[-border:].reshape(-1, 3),
		rgb[:, :border].reshape(-1, 3), rgb[:, -border:].reshape(-1, 3)])
	lum = strip.mean(axis=1)
	mid = lum.mean()
	light = strip[lum >= mid].mean(axis=0)
	dark = strip[lum < mid].mean(axis=0)
	tol_cls = float(p.get("class_tol", 22))
	d_light = np.abs(rgb - light).max(axis=2)
	d_dark = np.abs(rgb - dark).max(axis=2)
	cls = np.zeros((h, w), np.int8)
	cls[d_light < tol_cls] = 1
	cls[d_dark < tol_cls] = -1
	lum_full = rgb.mean(axis=2)
	mid_level = float(light.mean() + dark.mean()) / 2.0
	bx, period_x = _regularise(_strip_boundaries(lum_full, mid_level, 1, border), w)
	by, period_y = _regularise(_strip_boundaries(lum_full, mid_level, 0, border), h)
	colpar, rowpar, agreement = _vote_parity(cls, bx, by)
	px = _parity_fraction(bx, colpar, w)
	py = _parity_fraction(by, rowpar, h)
	t = px[None, :] * py[:, None] + (1 - px[None, :]) * (1 - py[:, None])  # fraction of tone T0
	pure0 = (t > 0.99) & (cls != 0)
	pure1 = (t < 0.01) & (cls != 0)
	t0_is_light = (cls[pure0] == 1).mean() >= 0.5
	# Local tone maps (tones drift slightly across generated sheets).
	win = int(p.get("tone_window", 48))
	tone = {}
	for key, pure, want in (("t0", pure0, 1 if t0_is_light else -1), ("t1", pure1, -1 if t0_is_light else 1)):
		sel = (pure & (cls == want)).astype(np.float32)
		num = box_mean(rgb * sel[:, :, None], win)
		den = box_mean(sel, win)[:, :, None]
		glob = rgb[sel > 0].mean(axis=0)
		num2 = box_mean(rgb * sel[:, :, None], win * 4)
		den2 = box_mean(sel, win * 4)[:, :, None]
		local = np.where(den > 0.02, num / np.maximum(den, 1e-6),
			np.where(den2 > 0.005, num2 / np.maximum(den2, 1e-6), glob))
		tone[key] = local.astype(np.float32)
	bg = t[:, :, None] * tone["t0"] + (1 - t[:, :, None]) * tone["t1"]
	diff = rgb - bg
	d = np.abs(diff).max(axis=2)
	denom = np.maximum(bg, 255.0 - bg).max(axis=2)
	a_min = np.clip(d / denom, 0.0, 1.0)
	# Local-contrast alpha: regress pixel colour on the checker pattern; the visible checker
	# amplitude equals (1 - alpha) * (T0 - T1).
	square = (period_x + period_y) / 2.0
	r = max(2, int(round(square)))
	s = t.astype(np.float32)
	es = box_mean(s, r)
	ess = box_mean(s * s, r)
	var = np.maximum(ess - es * es, 1e-4)
	ep = box_mean(rgb, r)
	eps = box_mean(rgb * s[:, :, None], r)
	slope = (eps - ep * es[:, :, None]) / var[:, :, None]
	amp = tone["t0"] - tone["t1"]
	proj = (slope * amp).sum(axis=2) / np.maximum((amp * amp).sum(axis=2), 1e-3)
	a_con = np.clip(1.0 - proj, 0.0, 1.0)
	a_con[var < 0.02] = a_min[var < 0.02]
	tol = float(p.get("match_tol", 20))
	match = d < tol
	lab, _ = label(match)
	edge_ids = np.unique(np.concatenate([lab[0], lab[-1], lab[:, 0], lab[:, -1]]))
	edge_ids = edge_ids[edge_ids > 0]
	flood = np.isin(lab, edge_ids)
	soft_t = float(p.get("soft_t", 0.15))
	alpha = np.where(a_min < soft_t, a_min, np.maximum(a_min, a_con))
	alpha[match & (a_con < 0.5)] = 0.0
	alpha[flood] = 0.0
	alpha[alpha < float(p.get("alpha_floor", 0.03))] = 0.0
	safe = np.maximum(alpha, 1e-6)[:, :, None]
	col = np.clip(bg + diff / safe, 0.0, 255.0)
	out = np.zeros((h, w, 4), np.float32)
	out[:, :, :3] = col
	out[:, :, 3] = alpha
	info["checker"] = {"light": [round(float(v), 1) for v in light], "dark": [round(float(v), 1) for v in dark],
		"square_px": round(square, 2), "cols": len(bx), "rows": len(by), "parity_agreement": round(agreement, 4),
		"border_alpha_mean": round(float(np.concatenate([alpha[:border].ravel(), alpha[-border:].ravel()]).mean()), 4)}
	return out


def max_filter(arr: np.ndarray, radius: int) -> np.ndarray:
	"""Grey-level dilation over a (2r+1)^2 square (edge-padded)."""
	r = int(radius)
	pad = np.pad(arr, r, mode="edge")
	out = arr.copy()
	h, w = arr.shape
	for dy in range(2 * r + 1):
		for dx in range(2 * r + 1):
			np.maximum(out, pad[dy:dy + h, dx:dx + w], out=out)
	return out


def checker_local_matte(rgb: np.ndarray, p: dict, info: dict) -> np.ndarray:
	"""Grid-free checker removal for hand-warped checkerboards (no global grid fits).

	Each pixel's checker tone comes from the sign of its local contrast along the dark->light
	tone axis (translucent glow keeps the checker visible as a relative modulation); visible
	checker pixels override the hint. Difference matting then runs against that tone."""
	h, w, _ = rgb.shape
	border = int(p.get("border", 24))
	strip = np.concatenate([rgb[:border].reshape(-1, 3), rgb[-border:].reshape(-1, 3),
		rgb[:, :border].reshape(-1, 3), rgb[:, -border:].reshape(-1, 3)])
	lum = strip.mean(axis=1)
	light = strip[lum >= lum.mean()].mean(axis=0)
	dark = strip[lum < lum.mean()].mean(axis=0)
	tol_cls = float(p.get("class_tol", 22))
	cls = np.zeros((h, w), np.int8)
	cls[np.abs(rgb - light).max(axis=2) < tol_cls] = 1
	cls[np.abs(rgb - dark).max(axis=2) < tol_cls] = -1
	win = int(p.get("tone_window", 48))

	def local_tone(sel: np.ndarray, glob: np.ndarray) -> np.ndarray:
		num = box_mean(rgb * sel[:, :, None], win)
		den = box_mean(sel, win)[:, :, None]
		num2 = box_mean(rgb * sel[:, :, None], win * 4)
		den2 = box_mean(sel, win * 4)[:, :, None]
		return np.where(den > 0.02, num / np.maximum(den, 1e-6),
			np.where(den2 > 0.005, num2 / np.maximum(den2, 1e-6), glob)).astype(np.float32)

	lt = local_tone((cls == 1).astype(np.float32), light)
	dk = local_tone((cls == -1).astype(np.float32), dark)
	amp = lt - dk
	amp2 = np.maximum((amp * amp).sum(axis=2), 1e-3)
	# Pixels on the dark..light segment are checker (including anti-aliased square edges).
	t = np.clip(((rgb - dk) * amp).sum(axis=2) / amp2, 0.0, 1.0)
	dseg = np.abs(rgb - (dk + t[:, :, None] * amp)).max(axis=2)
	bglike = dseg < float(p.get("match_tol", 14))
	# Checker tone hint from local contrast, 3x3 majority-smoothed; visible checker overrides.
	r = int(p.get("square", 9))
	s = ((rgb - box_mean(rgb, r)) * amp).sum(axis=2) / amp2
	hint = box_mean((s > 0).astype(np.float32), 1) > 0.5
	hint = np.where(cls == 1, True, np.where(cls == -1, False, hint))
	bg = np.where(hint[:, :, None], lt, dk)
	d = np.abs(rgb - bg).max(axis=2)
	denom = np.maximum(bg, 255.0 - bg).max(axis=2)
	a_min = np.clip(d / denom, 0.0, 1.0)
	lo, hi = float(p.get("boost_lo", 0.5)), float(p.get("boost_hi", 0.85))
	alpha = np.where(a_min < lo, a_min, np.minimum(1.0, lo + (a_min - lo) * (1.0 - lo) / (hi - lo)))
	# Local checker amplitude (grid-free): std of the tone-axis projection. Pure checker gives the
	# reference std, a translucent layer scales it by (1 - alpha) and smooth opaque art gives ~0.
	# It drives glows and opaque interiors (light art over the light tone); boosted difference
	# matting is kept only for crisp details that stand clearly above it.
	r2 = int(p.get("contrast_radius", 5))
	tp = ((rgb - dk) * amp).sum(axis=2) / amp2
	mt = box_mean(tp, r2)
	sd = np.sqrt(np.maximum(box_mean(tp * tp, r2) - mt * mt, 0.0))
	ref = float(np.median(np.concatenate([sd[:border].ravel(), sd[-border:].ravel()])))
	a_con = np.clip(1.0 - sd / max(ref, 1e-3), 0.0, 1.0)
	alpha = np.maximum(a_con, np.where(a_min > a_con + float(p.get("detail_margin", 0.3)), alpha, 0.0))
	# Checker regions: border-connected or large enclosed gaps -> transparent.
	lab, count = label(bglike)
	area = np.bincount(lab.ravel(), minlength=count + 1)
	area[0] = 0
	edge_ids = np.unique(np.concatenate([lab[0], lab[-1], lab[:, 0], lab[:, -1]]))
	big = area >= int(p.get("enclosed_min_area", 40))
	big[0] = False
	big[edge_ids] = True
	big[0] = False
	kill = big[lab]
	alpha[kill] = 0.0
	# Tiny grey specks enclosed by art are art (rock highlights): inherit neighbour alpha.
	small = bglike & ~kill
	if small.any():
		neigh = max_filter(np.where(small, 0.0, alpha).astype(np.float32), 2)
		alpha[small] = neigh[small]
		bg[small] = rgb[small]
	alpha[alpha < float(p.get("alpha_floor", 0.03))] = 0.0
	# Opaque light art (crystal facets) enclosed by solid outlines: holes in the solid mask that
	# show no checker at all are interior, not translucency -> fully opaque, original colour.
	filled = np.zeros((h, w), bool)
	if p.get("fill_holes", True):
		solid = alpha >= float(p.get("solid_t", 0.6))
		hl, hn = label(~solid)
		harea = np.bincount(hl.ravel(), minlength=hn + 1)
		has_bg = np.bincount(hl[kill], minlength=hn + 1) > 0
		ok = (harea <= int(p.get("hole_max", 3000))) & ~has_bg
		ok[np.unique(np.concatenate([hl[0], hl[-1], hl[:, 0], hl[:, -1]]))] = False
		ok[0] = False
		filled = ok[hl]
		alpha[filled] = 1.0
		bg[filled] = rgb[filled]
	safe = np.maximum(alpha, 1e-6)[:, :, None]
	f_pix = np.clip(bg + (rgb - bg) / safe, 0.0, 255.0)
	# Low-alpha glow colour from local means against the mean checker tone: no checker pattern.
	rc = int(p.get("square", 9))
	a_s = box_mean(a_con, rc)
	f_mean = np.clip((box_mean(rgb, rc) - (1.0 - a_s[:, :, None]) * 0.5 * (lt + dk)) / np.maximum(a_s, 1e-3)[:, :, None], 0.0, 255.0)
	wgt = np.clip((alpha - 0.3) / 0.4, 0.0, 1.0)
	wgt = np.where(a_s > 0.1, wgt, 1.0)[:, :, None]
	col = wgt * f_pix + (1.0 - wgt) * f_mean
	col[small] = rgb[small]
	out = np.zeros((h, w, 4), np.float32)
	out[:, :, :3] = col
	out[:, :, 3] = alpha
	info["contrast_ref_std"] = round(ref, 4)
	info["checker_local"] = {"light": [round(float(v), 1) for v in light], "dark": [round(float(v), 1) for v in dark],
		"border_alpha_mean": round(float(np.concatenate([alpha[:border].ravel(), alpha[-border:].ravel()]).mean()), 4),
		"enclosed_specks_kept": int(small.sum())}
	return out


# --------------------------------------------------------------------------- sheets

class Sheet:
	def __init__(self, name: str, spec: dict, source_dir: str) -> None:
		self.name = name
		self.spec = spec
		self.path = os.path.join(source_dir, spec["file"])
		self.info: dict = {}
		mode = spec.get("cleanup", "alpha")
		if mode == "opaque":
			self.rgba = None
			self.seg = None
			return
		if mode == "alpha":
			self.rgba = load_rgba(self.path)
		elif mode == "black":
			rgb = np.asarray(Image.open(self.path).convert("RGB")).astype(np.float32)
			self.rgba = black_to_alpha(rgb, float(spec.get("floor", 10)))
		elif mode == "checker":
			rgb = np.asarray(Image.open(self.path).convert("RGB")).astype(np.float32)
			self.rgba = checker_matte(rgb, spec, self.info)
		elif mode == "checker_local":
			rgb = np.asarray(Image.open(self.path).convert("RGB")).astype(np.float32)
			self.rgba = checker_local_matte(rgb, spec, self.info)
		else:
			raise ValueError("unknown cleanup mode %s" % mode)
		cut = self.row_cuts() if spec.get("cut_rows") else None
		self.seg = Segmentation(self.rgba[:, :, 3], float(spec.get("seed", 0.1)), int(spec.get("grow", 0)), cut)

	def row_cuts(self) -> np.ndarray:
		"""Cuts the labelling mask along the emptiest row near each internal grid row boundary
		(per grid column), so art that barely touches the cell below (beams, rings) separates."""
		a = self.rgba[:, :, 3]
		h, w = a.shape
		cols, rows = self.spec["grid"]
		win = int(self.spec.get("cut_window", 40))
		cut = np.zeros((h, w), bool)
		cuts = []
		for c in range(cols):
			x0, x1 = int(round(c * w / cols)), int(round((c + 1) * w / cols))
			for r in range(1, rows):
				by = int(round(r * h / rows))
				ys = np.arange(max(0, by - win), min(h, by + win))
				prof = a[ys, x0:x1].sum(axis=1)
				y = int(ys[int(np.argmin(prof))])
				cut[y, x0:x1] = True
				cuts.append([c, r, y, round(float(prof.min()), 1)])
		self.info["row_cuts"] = cuts
		return cut

	def cell_rect(self, index: int) -> Box:
		cols, rows = self.spec["grid"]
		h, w = self.rgba.shape[:2]
		cw, ch = w / cols, h / rows
		cx, cy = index % cols, index // cols
		return (int(round(cx * cw)), int(round(cy * ch)), int(round((cx + 1) * cw)), int(round((cy + 1) * ch)))

	def extract(self, item: dict) -> Tuple[np.ndarray, dict]:
		"""Returns the cleaned crop (HxWx4) for one item and a debug dict."""
		p = dict(self.spec)
		p.update(item.get("params", {}))
		# Optional hard clip window: re-segment only inside it (splits art that touches a neighbour).
		ox, oy = 0, 0
		src = self.rgba
		seg = self.seg
		if "clip" in item:
			ox, oy, cx1, cy1 = item["clip"]
			src = self.rgba[oy:cy1, ox:cx1]
			seg = Segmentation(src[:, :, 3], float(p.get("seed", 0.1)), int(p.get("grow", 0)))
		a = src[:, :, 3]
		h, w = a.shape
		min_area = float(p.get("min_area", 30))
		ids = np.arange(seg.count + 1)
		valid = (seg.area >= min_area) & (ids > 0)
		if "near" in item:
			nx, ny = item["near"]
			dist = np.hypot(seg.cx - (nx - ox), seg.cy - (ny - oy))
			dist[~valid] = np.inf
			rect = None
			cand = np.array([int(np.argmin(dist))])
		else:
			rect = tuple(item["rect"]) if "rect" in item else self.cell_rect(int(item["cell"]))
			lr = (rect[0] - ox, rect[1] - oy, rect[2] - ox, rect[3] - oy)
			inside = (seg.cx >= lr[0]) & (seg.cx < lr[2]) & (seg.cy >= lr[1]) & (seg.cy < lr[3])
			cand = np.nonzero(inside & valid)[0]
		if len(cand) == 0:
			raise RuntimeError("no components for %s" % item.get("out"))
		largest = cand[np.argmax(seg.area[cand])]
		keep_mode = p.get("keep", "all")
		if keep_mode == "all":
			frac = float(p.get("min_frac", 0.0))
			keep = [int(k) for k in cand if seg.area[k] >= frac * seg.area[largest]]
		else:
			keep = [int(largest)]
			attach = int(p.get("attach", 6))
			for _ in range(int(p.get("attach_passes", 3))):
				km = np.isin(seg.lab, keep)
				bb = bbox(km)
				x0, y0 = max(0, bb[0] - attach - 1), max(0, bb[1] - attach - 1)
				x1, y1 = min(w, bb[2] + attach + 1), min(h, bb[3] + attach + 1)
				near_mask = dilate(km[y0:y1, x0:x1], attach)
				touched = np.unique(seg.lab[y0:y1, x0:x1][near_mask])
				pool = set(int(k) for k in cand) if rect is not None else set(int(k) for k in touched)
				added = [int(k) for k in touched if k > 0 and int(k) in pool and int(k) not in keep
					and seg.area[k] >= float(p.get("attach_min_area", min_area))]
				if not added:
					break
				keep += added
		halo = int(p.get("halo", 4))
		km_full = np.isin(seg.lab, keep)
		bb = bbox(km_full)
		x0, y0 = max(0, bb[0] - halo - 2), max(0, bb[1] - halo - 2)
		x1, y1 = min(w, bb[2] + halo + 2), min(h, bb[3] + halo + 2)
		km = km_full[y0:y1, x0:x1]
		others = seg.seed_mask[y0:y1, x0:x1] & ~km
		if halo > 0:
			others = dilate(others, 1) & ~km
		region = dilate(km, halo) & (a[y0:y1, x0:x1] > float(p.get("low", 0.02))) & ~others
		region |= km
		crop = src[y0:y1, x0:x1].copy()
		crop[:, :, 3] *= region
		fb = bbox(crop[:, :, 3] > 0.0)
		crop = crop[fb[1]:fb[3], fb[0]:fb[2]]
		dbg = {"source": self.spec["file"], "rect": rect, "components": len(keep),
			"crop": [ox + x0 + fb[0], oy + y0 + fb[1], ox + x0 + fb[2], oy + y0 + fb[3]]}
		if "clip" in item:
			dbg["clip"] = list(item["clip"])
		if rect is not None:
			c = dbg["crop"]
			dbg["overflow"] = [max(0, rect[0] - c[0]), max(0, rect[1] - c[1]), max(0, c[2] - rect[2]), max(0, c[3] - rect[3])]
		return crop, dbg


# --------------------------------------------------------------------------- measurement / placement

def measure(arr: np.ndarray, thr: float = 0.125, min_frac: float = 0.01) -> Tuple[Optional[Box], Optional[Box]]:
	"""Robust content bbox (alpha > thr, specks dropped) and full bbox (alpha > 0.02)."""
	alpha = arr[:, :, 3]
	m = alpha > thr
	lab, count = label(m)
	if count == 0:
		return None, bbox(alpha > 0.02)
	area = np.bincount(lab.ravel(), minlength=count + 1)
	area[0] = 0
	keep = np.nonzero(area >= min_frac * area.max())[0]
	mb = bbox(np.isin(lab, keep))
	return mb, bbox(alpha > 0.02)


def place(crop: np.ndarray, canvas: Tuple[int, int], s: float, center: Tuple[float, float],
		mb: Box, fb: Box, margin: int) -> Tuple[Image.Image, dict]:
	W, H = canvas
	fbw, fbh = fb[2] - fb[0], fb[3] - fb[1]
	s_fit = min((W - 2 * margin) / fbw, (H - 2 * margin) / fbh)
	info = {"scale_wanted": round(s, 4)}
	if s > s_fit:
		info["clamped_scale"] = True
		s = s_fit
	mcx, mcy = (mb[0] + mb[2]) / 2.0, (mb[1] + mb[3]) / 2.0
	ox, oy = center[0] - s * mcx, center[1] - s * mcy
	fx0, fx1 = ox + s * fb[0], ox + s * fb[2]
	fy0, fy1 = oy + s * fb[1], oy + s * fb[3]
	shift = [0.0, 0.0]
	if fx0 < margin:
		shift[0] = margin - fx0
	elif fx1 > W - margin:
		shift[0] = (W - margin) - fx1
	if fy0 < margin:
		shift[1] = margin - fy0
	elif fy1 > H - margin:
		shift[1] = (H - margin) - fy1
	ox += shift[0]
	oy += shift[1]
	if abs(shift[0]) > 0.5 or abs(shift[1]) > 0.5:
		info["shifted"] = [round(shift[0], 1), round(shift[1], 1)]
	sub = crop[fb[1]:fb[3], fb[0]:fb[2]]
	nw, nh = max(1, int(round(fbw * s))), max(1, int(round(fbh * s))),
	img = to_image(sub).resize((nw, nh), Image.LANCZOS)
	out = Image.new("RGBA", (W, H), (0, 0, 0, 0))
	px, py = int(round(ox + s * fb[0])), int(round(oy + s * fb[1]))
	px = min(max(px, 0), W - nw)
	py = min(max(py, 0), H - nh)
	out.alpha_composite(img, (px, py))
	info["scale"] = round(s, 4)
	info["content_px"] = [nw, nh]
	return out, info


# --------------------------------------------------------------------------- pipeline

class Pipeline:
	def __init__(self, cfg: dict) -> None:
		self.cfg = cfg
		self.source_dir = os.path.join(REPO, cfg["source_dir"])
		self.legacy_dir = os.path.join(REPO, cfg["legacy_dir"])
		self.out_dir = os.path.join(REPO, cfg["out_dir"])
		self.report_dir = os.path.join(REPO, cfg["report_dir"])
		self.sheets: Dict[str, Sheet] = {}
		self.report: List[dict] = []
		self.group_summary: List[str] = []

	def sheet(self, name: str) -> Sheet:
		if name not in self.sheets:
			print("  loading sheet %s" % name, flush=True)
			self.sheets[name] = Sheet(name, self.cfg["sheets"][name], self.source_dir)
		return self.sheets[name]

	def legacy_path(self, rel: str) -> str:
		return os.path.join(self.legacy_dir, rel)

	def run_group(self, g: dict) -> None:
		name = g["name"]
		print("group %s" % name, flush=True)
		out_dir = g.get("dir", "")
		if g.get("mode") == "opaque":
			for it in g["items"]:
				self.copy_opaque(g, it, out_dir)
			return
		sheet = self.sheet(g["sheet"]) if "sheet" in g else None
		items = []
		for it in g["items"]:
			sh = self.sheet(it["sheet"]) if "sheet" in it else sheet
			if "file" in it:  # a whole standalone alpha image
				crop = load_rgba(os.path.join(self.source_dir, it["file"]))
				fbox = bbox(crop[:, :, 3] > 0.0)
				crop = crop[fbox[1]:fbox[3], fbox[0]:fbox[2]]
				dbg = {"source": it["file"]}
			else:
				crop, dbg = sh.extract(it)
			mb, fb = measure(crop)
			rel = os.path.join(out_dir, it["out"])
			leg = self.legacy_path(it.get("legacy", rel))
			legacy = None
			if os.path.exists(leg) and not it.get("no_legacy"):
				la = load_rgba(leg)
				lmb, _ = measure(la)
				legacy = {"size": (la.shape[1], la.shape[0]), "mb": lmb}
			reg = None
			if dbg.get("rect") is not None:
				reg = (dbg["crop"][0] + (mb[0] + mb[2]) / 2.0 - dbg["rect"][0], dbg["crop"][1] + (mb[1] + mb[3]) / 2.0 - dbg["rect"][1])
			items.append({"it": it, "crop": crop, "dbg": dbg, "mb": mb, "fb": fb, "rel": rel, "legacy": legacy, "reg": reg})
		by_out = {x["it"]["out"]: x for x in items}
		scale_mode = g.get("scale", "item")
		# group scale
		ratios = []
		for x in items:
			if x["legacy"] and (not g.get("scale_ref") or x["it"]["out"] in g["scale_ref"]):
				ratios.append((x["legacy"]["mb"][3] - x["legacy"]["mb"][1]) / float(x["mb"][3] - x["mb"][1]))
		group_s = float(np.median(ratios)) if ratios else float(g.get("factor", 1.0))
		leg_centres = [((x["legacy"]["mb"][0] + x["legacy"]["mb"][2]) / 2.0, (x["legacy"]["mb"][1] + x["legacy"]["mb"][3]) / 2.0)
			for x in items if x["legacy"]]
		median_centre = tuple(np.median(np.array(leg_centres), axis=0)) if leg_centres else None
		done: Dict[str, dict] = {}
		order = sorted(items, key=lambda x: 1 if "like" in x["it"] else 0)
		scales = []
		for x in order:
			it = x["it"]
			like = done.get(it.get("like", ""))
			# canvas
			cv = it.get("canvas", g.get("canvas", "legacy"))
			if cv == "legacy":
				if x["legacy"]:
					canvas = x["legacy"]["size"]
				elif like:
					canvas = like["canvas"]
				else:
					canvas = tuple(g["default_canvas"])
			elif cv == "trim":
				canvas = None
			else:
				canvas = tuple(cv)
			if canvas is not None and g.get("force_canvas"):
				canvas = tuple(g["force_canvas"])
			mbh = float(x["mb"][3] - x["mb"][1])
			mbw = float(x["mb"][2] - x["mb"][0])
			# scale
			if like is not None:
				s = like["s"] * (like["mbh"] / mbh if it.get("like_height") else 1.0)
			elif scale_mode == "item" and x["legacy"]:
				s = (x["legacy"]["mb"][3] - x["legacy"]["mb"][1]) / mbh
			elif scale_mode == "fit":
				bw, bh = g["box"]
				s = min(bw / mbw, bh / mbh)
			elif scale_mode == "native":
				s = float(g.get("factor", 1.0))
			else:
				s = group_s
			# canvas for trimmed outputs
			if canvas is None:
				pad = int(g.get("pad", 4))
				fbw, fbh = x["fb"][2] - x["fb"][0], x["fb"][3] - x["fb"][1]
				canvas = (int(round(fbw * s)) + 2 * pad, int(round(fbh * s)) + 2 * pad)
				fcx, fcy = (x["fb"][0] + x["fb"][2]) / 2.0, (x["fb"][1] + x["fb"][3]) / 2.0
				mcx, mcy = (x["mb"][0] + x["mb"][2]) / 2.0, (x["mb"][1] + x["mb"][3]) / 2.0
				center = (canvas[0] / 2.0 + (mcx - fcx) * s, canvas[1] / 2.0 + (mcy - fcy) * s)
			else:
				cmode = it.get("center", g.get("center", "legacy"))
				if isinstance(cmode, list):
					center = (float(cmode[0]), float(cmode[1]))
				elif like is not None and it.get("register") and x["reg"] and like["reg"]:
					# Same cell-relative registration as the item it is "like" (state variants).
					center = (like["center"][0] + s * (x["reg"][0] - like["reg"][0]),
						like["center"][1] + s * (x["reg"][1] - like["reg"][1]))
				elif cmode == "legacy" and x["legacy"]:
					lmb = x["legacy"]["mb"]
					center = ((lmb[0] + lmb[2]) / 2.0, (lmb[1] + lmb[3]) / 2.0)
				elif like is not None:
					center = like["center"]
				elif cmode in ("legacy", "median") and median_centre is not None:
					center = median_centre
				else:
					center = (canvas[0] / 2.0, canvas[1] / 2.0)
			img, pinfo = place(x["crop"], canvas, s, center, x["mb"], x["fb"], int(g.get("margin", 1)))
			done[it["out"]] = {"s": pinfo["scale"], "center": center, "canvas": canvas, "mbh": mbh, "reg": x["reg"]}
			scales.append(pinfo["scale"])
			self.write(img, x["rel"], g, it)
			rec = {"out": x["rel"], "canvas": list(canvas), "center": [round(c, 1) for c in center]}
			rec.update(x["dbg"])
			rec.update(pinfo)
			if x["legacy"]:
				rec["legacy_mb"] = list(x["legacy"]["mb"])
			self.report.append(rec)
			if pinfo.get("clamped_scale") or pinfo.get("shifted"):
				print("    note %s %s" % (x["rel"], {k: v for k, v in pinfo.items() if k in ("clamped_scale", "shifted", "scale_wanted", "scale")}))
		if scales:
			self.group_summary.append("%-18s mode=%-6s items=%2d scale median=%.3f min=%.3f max=%.3f" % (
				name, scale_mode, len(scales), float(np.median(scales)), min(scales), max(scales)))

	def write(self, img: Image.Image, rel: str, g: dict, it: dict) -> None:
		bgc = it.get("background", g.get("background"))
		variants = [(rel, bgc)]
		for extra in it.get("also", []):
			variants.append((os.path.join(os.path.dirname(rel), extra["out"]), extra.get("background")))
		for path_rel, colour in variants:
			path = os.path.join(self.out_dir, path_rel)
			os.makedirs(os.path.dirname(path), exist_ok=True)
			if colour:
				base = Image.new("RGBA", img.size, hex_rgb(colour) + (255,))
				base.alpha_composite(img)
				base.convert("RGB").save(path)
			else:
				img.save(path)
			self.copy_import(path_rel)

	def copy_opaque(self, g: dict, it: dict, out_dir: str) -> None:
		src = Image.open(os.path.join(self.source_dir, it["file"])).convert("RGB")
		rel = os.path.join(out_dir, it["out"])
		leg = self.legacy_path(rel)
		size = tuple(it["canvas"]) if "canvas" in it else (Image.open(leg).size if os.path.exists(leg) else src.size)
		if src.size != size:
			src = src.resize(size, Image.LANCZOS)
		path = os.path.join(self.out_dir, rel)
		os.makedirs(os.path.dirname(path), exist_ok=True)
		src.save(path)
		self.copy_import(rel)
		self.report.append({"out": rel, "source": it["file"], "canvas": list(size), "mode": "opaque"})

	def copy_import(self, rel: str) -> None:
		"""Keeps the legacy .import (and so the uid) for replaced files when it is missing."""
		dst = os.path.join(self.out_dir, rel) + ".import"
		src = self.legacy_path(rel) + ".import"
		if not os.path.exists(dst) and os.path.exists(src):
			shutil.copy2(src, dst)

	# ----------------------------------------------------------------------- contact sheets

	def contact_sheets(self, groups: List[dict]) -> None:
		tile = 168
		label_h = 14
		dark = hex_rgb("#111521") + (255,)
		light = (205, 208, 212, 255)
		for g in groups:
			rels = [os.path.join(g.get("dir", ""), it["out"]) for it in g["items"]]
			for it in g["items"]:
				for extra in it.get("also", []):
					rels.append(os.path.join(g.get("dir", ""), extra["out"]))
			cols = 3
			per_row = 4
			rows = (len(rels) + per_row - 1) // per_row
			W = per_row * cols * tile + (per_row - 1) * 10
			H = rows * (tile + label_h)
			sheet = Image.new("RGBA", (W, H), (60, 60, 66, 255))
			d = ImageDraw.Draw(sheet)
			for i, rel in enumerate(rels):
				gx = (i % per_row) * (cols * tile + 10)
				gy = (i // per_row) * (tile + label_h)
				new = Image.open(os.path.join(self.out_dir, rel)).convert("RGBA")
				leg_path = self.legacy_path(rel)
				panels = []
				if os.path.exists(leg_path):
					panels.append((Image.open(leg_path).convert("RGBA"), dark))
				else:
					panels.append((None, dark))
				panels.append((new, dark))
				panels.append((new, light))
				for j, (im, bgc) in enumerate(panels):
					x = gx + j * tile
					bgt = Image.new("RGBA", (tile, tile), bgc)
					if im is not None:
						t = im.copy()
						t.thumbnail((tile - 4, tile - 4), Image.LANCZOS)
						ox, oy = (tile - t.size[0]) // 2, (tile - t.size[1]) // 2
						bgt.alpha_composite(t, (ox, oy))
						ImageDraw.Draw(bgt).rectangle([ox - 1, oy - 1, ox + t.size[0], oy + t.size[1]], outline=(90, 90, 100, 255))
					else:
						ImageDraw.Draw(bgt).text((6, 6), "new", fill=(150, 150, 150, 255))
					sheet.alpha_composite(bgt, (x, gy))
				d.text((gx + 2, gy + tile + 1), os.path.basename(rel)[:60], fill=(255, 255, 255, 255))
			os.makedirs(self.report_dir, exist_ok=True)
			sheet.convert("RGB").save(os.path.join(self.report_dir, "contact_%s.png" % g["name"]))

	def write_report(self) -> None:
		os.makedirs(self.report_dir, exist_ok=True)
		with open(os.path.join(self.report_dir, "extract_report.json"), "w") as f:
			json.dump({"items": self.report, "sheets": {k: v.info for k, v in self.sheets.items() if v.info}}, f, indent=1)
		with open(os.path.join(self.report_dir, "scale_summary.txt"), "w") as f:
			f.write("\n".join(self.group_summary) + "\n")
		print("\n".join(self.group_summary))


def main() -> int:
	ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
	ap.add_argument("--config", default=CONFIG_DEFAULT)
	ap.add_argument("--only", nargs="*", help="group names to build")
	ap.add_argument("--no-contact", action="store_true")
	args = ap.parse_args()
	with open(args.config) as f:
		cfg = json.load(f)
	pipe = Pipeline(cfg)
	groups = [g for g in cfg["groups"] if not args.only or g["name"] in args.only]
	failed = []
	built = []
	for g in groups:
		try:
			pipe.run_group(g)
			built.append(g)
		except Exception as exc:  # keep building the other groups, fail at the end
			print("  FAILED group %s: %s" % (g["name"], exc), flush=True)
			failed.append(g["name"])
	pipe.write_report()
	if not args.no_contact:
		pipe.contact_sheets([g for g in built if g.get("mode") != "opaque"])
	if failed:
		print("FAILED groups: %s" % ", ".join(failed))
		return 1
	return 0


if __name__ == "__main__":
	sys.exit(main())
