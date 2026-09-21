#!/usr/bin/env bash
# Bring a rendered episode to the series' delivery loudness without touching the picture.
#   tools/video/master_export.sh IN.mp4 [OUT.mp4]
# Two-pass EBU R128: about -14.5 LUFS integrated, true peak <= -1 dBTP (recipe 7.4).
# Remotion mixes at the voice's own level (~-17.7 LUFS), so every export needs this pass.
set -euo pipefail
IN="$1"; OUT="${2:-${IN%.mp4}_master.mp4}"
TARGET_I=-14.5; TARGET_TP=-1.5; TARGET_LRA=11
M="$(ffmpeg -hide_banner -i "$IN" -af "loudnorm=I=$TARGET_I:TP=$TARGET_TP:LRA=$TARGET_LRA:print_format=json" -f null - 2>&1 | sed -n '/{/,/}/p')"
get() { echo "$M" | python -c "import sys,json;print(json.load(sys.stdin)['$1'])"; }
ffmpeg -y -hide_banner -loglevel error -i "$IN" \
  -af "loudnorm=I=$TARGET_I:TP=$TARGET_TP:LRA=$TARGET_LRA:measured_I=$(get input_i):measured_TP=$(get input_tp):measured_LRA=$(get input_lra):measured_thresh=$(get input_thresh):offset=$(get target_offset):linear=true:print_format=summary" \
  -c:v copy -c:a aac -b:a 256k -ar 48000 -movflags +faststart "$OUT"
echo "--- $OUT ---"
ffmpeg -hide_banner -i "$OUT" -af ebur128=peak=true -f null - 2>&1 | grep -A6 "Summary:" | grep -E "I:|Peak:"
