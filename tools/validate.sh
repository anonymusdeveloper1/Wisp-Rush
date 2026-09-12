#!/usr/bin/env bash
# Headless health check for the Godot project. Run from anywhere:
#   tools/validate.sh              import -> parse every script -> boot main scene -> refresh project map
#   FRAMES=600 tools/validate.sh   boot the main scene for more frames (default 120)
#   GODOT_PATH=/path/to/Godot tools/validate.sh
# Exits 1 if Godot reports script / parse / load errors. Full logs land in logs/ (git-ignored).
set -uo pipefail
# Boot runs use user://test_runs/ instead of the owner's real save (SaveManager.uses_isolated_storage).
export WISP_ISOLATED_SAVE=1

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
GODOT="${GODOT_PATH:-/Users/dimitarslezenkovski/Desktop/Godot.app/Contents/MacOS/Godot}"
FRAMES="${FRAMES:-120}"
LOGS="$ROOT/logs"
mkdir -p "$LOGS"

if [[ ! -x "$GODOT" ]]; then
  echo "Godot binary not found at: $GODOT (set GODOT_PATH)" >&2
  exit 2
fi

status=0

# run <log-name> <godot args...> — runs Godot headless against the project, logging to logs/<name>.log
run() {
  local name="$1"; shift
  printf '==> %-14s' "$name"
  "$GODOT" --headless --path "$ROOT" "$@" >"$LOGS/$name.log" 2>&1
  local code=$?
  if [[ $code -eq 0 ]]; then echo "exit 0"; else echo "exit $code"; status=1; fi
}

run import --import
run check_scripts --script res://tools/godot/check_scripts.gd
run boot --quit-after "$FRAMES"

# Godot often exits 0 even when scripts fail, so scan the logs too.
PATTERN='SCRIPT ERROR|Parse Error|CHECK FAILED|Failed to load|Failed loading resource|Cannot open file|ERROR:'
if grep -nE "$PATTERN" "$LOGS"/import.log "$LOGS"/check_scripts.log "$LOGS"/boot.log >"$LOGS/errors.log"; then
  status=1
  echo
  echo "Errors found (full list: logs/errors.log):"
  head -n 40 "$LOGS/errors.log"
fi

echo
grep -h "check_scripts:" "$LOGS/check_scripts.log" || true
grep -h "\[Main\] boot ok" "$LOGS/boot.log" || true

if command -v node >/dev/null 2>&1; then
  printf '==> %-14s' "project_map"
  node "$ROOT/tools/project_map.mjs" && echo "updated docs/generated/PROJECT_MAP.md"
else
  echo "WARN: node not found; skipped project map refresh" >&2
fi

echo
if [[ $status -eq 0 ]]; then echo "VALIDATE: OK"; else echo "VALIDATE: FAILED"; fi
exit $status
