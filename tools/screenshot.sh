#!/usr/bin/env bash
# Render the game for N frames and save the last frame as logs/screenshot.png so an agent can
# look at it (Read the PNG). Opens a real window briefly — rendering needs a display, not --headless.
#   tools/screenshot.sh                                  main scene, 90 frames
#   tools/screenshot.sh res://scenes/player/player.tscn  a specific scene
#   tools/screenshot.sh res://scenes/main/main.tscn 300 390x844  settle at a phone QA size
# With canvas_items/expand, MovieWriter keeps the 1080×1920 design output while the requested
# window aspect changes the live logical arena; inspect the scene's resize log alongside the PNG.
set -uo pipefail
# Capture runs use user://test_runs/ instead of the owner's real save (SaveManager.uses_isolated_storage).
export WISP_ISOLATED_SAVE=1

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
GODOT="${GODOT_PATH:-/Users/dimitarslezenkovski/Desktop/Godot.app/Contents/MacOS/Godot}"
SCENE="${1:-}"
FRAMES="${2:-90}"
SIZE="${3:-${SCREENSHOT_SIZE:-540x960}}"
OUT_DIR="$ROOT/logs/frames"

rm -rf "$OUT_DIR" && mkdir -p "$OUT_DIR"
# --write-movie with a .png path writes one numbered PNG per frame at a fixed 60 FPS.
"$GODOT" --path "$ROOT" --resolution "$SIZE" --write-movie "$OUT_DIR/frame.png" \
  --quit-after "$FRAMES" ${SCENE:+"$SCENE"} \
  >"$ROOT/logs/screenshot.log" 2>&1

last="$(ls "$OUT_DIR"/frame*.png 2>/dev/null | sort | tail -n 1)"
if [[ -z "$last" ]]; then
  echo "No frames captured — see logs/screenshot.log" >&2
  exit 1
fi
cp "$last" "$ROOT/logs/screenshot.png"
rm -rf "$OUT_DIR"
echo "logs/screenshot.png ($SIZE, frame $FRAMES${SCENE:+ of $SCENE})"
