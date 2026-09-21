#!/usr/bin/env bash
# Watch a video as a contact sheet, so an agent can Read the PNG and see the cut.
#   tools/video/contact_sheet.sh IN.mp4 OUT.png [COLS] [ROWS] [START] [END]
# Samples COLS*ROWS frames evenly between START and END and prints the timestamp grid.
# Notes for this machine: ffmpeg is a native Windows build, so it cannot read Git Bash's /tmp
# paths — the scratch dir is kept inside the repo. drawtext segfaults here (fontconfig), so
# timestamps are printed rather than burned in.
set -uo pipefail
IN="$1"; OUT="${2:-logs/video/sheet.png}"; COLS="${3:-5}"; ROWS="${4:-4}"
DUR="$(ffprobe -v error -show_entries format=duration -of csv=p=0 "$IN")"
START="${5:-0}"; END="${6:-$DUR}"
N=$((COLS*ROWS))
TMP="logs/video/.sheet_tmp"
rm -rf "$TMP"; mkdir -p "$TMP" "$(dirname "$OUT")"
LABELS=""
for i in $(seq 0 $((N-1))); do
  T="$(python -c "print(round($START + $i*(($END-$START)/max(1,$N-1)), 2))")"
  ffmpeg -y -ss "$T" -i "$IN" -frames:v 1 -update 1 -vf "scale=300:-1" "$TMP/$(printf '%03d' "$i").png" >/dev/null 2>&1
  LABELS="$LABELS $T"
  if [ $(( (i+1) % COLS )) -eq 0 ]; then LABELS="$LABELS\n"; fi
done
ffmpeg -y -i "$TMP/%03d.png" -filter_complex "tile=${COLS}x${ROWS}:margin=6:padding=6:color=#111521" -frames:v 1 -update 1 "$OUT" >/dev/null 2>&1
rm -rf "$TMP"
echo "$OUT  ($N frames, ${START}s → ${END}s of ${DUR}s)"
printf "timestamps (row-major):\n$LABELS\n"
