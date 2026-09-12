#!/usr/bin/env bash
# QA matrix: captures key screens at every GDD §12 QA aspect ratio and builds one contact sheet per
# screen: logs/qa/<screen>_sheet.png, sizes left→right in SIZES order. Opens real windows briefly.
#   tools/qa_matrix.sh                  all screens
#   tools/qa_matrix.sh settings pause   selected screens
# Exits 1 if any capture failed or logged script errors (see logs/qa/<screen>_<size>.log).
set -uo pipefail
# Captures use user://test_runs/ instead of the owner's real save.
export WISP_ISOLATED_SAVE=1

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
GODOT="${GODOT_PATH:-/Users/dimitarslezenkovski/Desktop/Godot.app/Contents/MacOS/Godot}"
OUT="$ROOT/logs/qa"
mkdir -p "$OUT"

# Phones only — the owner targets mobile phones; tablets and desktop are not release targets.
# 320×568, 360×800, 375×812, 390×844, and 412×915 scaled to 860 px tall so the window fits a
# laptop display (the layout only sees the aspect ratio).
SIZES=(320x568 360x800 375x812 390x844 387x860)
SCREENS=(home forms daily stats settings results game pause upgrade tutorial)
[[ $# -gt 0 ]] && SCREENS=("$@")

status=0
for screen in "${SCREENS[@]}"; do
  shots=()
  for size in "${SIZES[@]}"; do
    png="$OUT/${screen}_${size}.png"
    log="$OUT/${screen}_${size}.log"
    rm -f "$png"
    perl -e 'alarm shift; exec @ARGV' 90 "$GODOT" --path "$ROOT" --resolution "$size" \
      --script res://tools/godot/qa_capture.gd -- "$screen" "$png" >"$log" 2>&1
    if grep -qE "SCRIPT ERROR|ERROR:" "$log" || [[ ! -f "$png" ]]; then
      echo "  ✗ $screen @ $size — see logs/qa/${screen}_${size}.log"
      status=1
    fi
    [[ -f "$png" ]] && shots+=("$png")
  done
  "$GODOT" --headless --path "$ROOT" --script res://tools/godot/qa_contact_sheet.gd \
    -- "$OUT/${screen}_sheet.png" "${shots[@]}" >/dev/null 2>&1
  echo "sheet: logs/qa/${screen}_sheet.png (${#shots[@]}/${#SIZES[@]} sizes)"
done
exit $status
