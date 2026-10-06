"""Copy a board's pixel-art pieces into the game (board arenas, ADR-0024, ADR-0025).

    python tools/art/make_board.py sci_fi_simulation_v1

Reads `concept_art/boards_v1/<id>/manifest.json` (written by Codex with the pieces, from that folder's
CODEX_PROMPT.md), checks every listed piece's size against it, and copies the runtime pieces
(`floor/`, `frame/`, `hud/`, `anim/`, `deco/`) unchanged to `assets/art/environment/boards/<id>/`,
where the board's `ArenaVisual` (SIMULATION's `SciFiBoardVisual`) loads them by name. The previews, review sheets and reference stay in
concept_art. Never hand-edit the outputs; re-run this.
"""
import json
import shutil
import sys
from pathlib import Path

from PIL import Image

REPO = Path(__file__).resolve().parents[2]
SOURCES = REPO / "concept_art/boards_v1"
OUTPUT = REPO / "assets/art/environment/boards"
RUNTIME_FOLDERS = ("floor", "frame", "hud", "anim", "deco")


def make_board(board_id: str) -> None:
	folder = SOURCES / board_id
	manifest = json.loads((folder / "manifest.json").read_text(encoding="utf-8"))
	target = OUTPUT / board_id
	copied = 0
	for entry in manifest["files"]:
		path = entry["path"]
		if path.split("/")[0] not in RUNTIME_FOLDERS:
			continue
		source = folder / path
		with Image.open(source) as image:
			if list(image.size) != list(entry["size"]):
				raise SystemExit("%s: %s is %s, the manifest says %s" % (
					board_id, path, list(image.size), entry["size"]))
		destination = target / path
		destination.parent.mkdir(parents=True, exist_ok=True)
		shutil.copyfile(source, destination)
		copied += 1
	print("BOARD: %s -> %s (%d pieces)" % (board_id, target.relative_to(REPO), copied))


if __name__ == "__main__":
	if len(sys.argv) != 2:
		raise SystemExit("usage: python tools/art/make_board.py <board id>")
	make_board(sys.argv[1])
