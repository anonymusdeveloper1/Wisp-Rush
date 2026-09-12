#!/usr/bin/env bash
# Run every headless test script (tools/godot/test_*.gd) with a per-test timeout.
#   tools/run_tests.sh                  all tests
#   tools/run_tests.sh save            only tests whose name contains "save"
#   TEST_TIMEOUT=60 tools/run_tests.sh
# A test passes when Godot exits 0 and logs no "SCRIPT ERROR" / "ERROR:" lines. Tests must end with
# quit(failures); a test that never quits (e.g. a script error aborted it first) is killed and fails.
# Logs: logs/tests/<name>.log (git-ignored).
set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
GODOT="${GODOT_PATH:-/Users/dimitarslezenkovski/Desktop/Godot.app/Contents/MacOS/Godot}"
TIMEOUT="${TEST_TIMEOUT:-120}"
FILTER="${1:-}"
mkdir -p "$ROOT/logs/tests"

pass=0
fail=0
for test in "$ROOT"/tools/godot/test_*.gd; do
  name="$(basename "$test" .gd)"
  [[ -n "$FILTER" && "$name" != *"$FILTER"* ]] && continue
  log="$ROOT/logs/tests/$name.log"
  # perl alarm is a portable timeout (macOS ships no `timeout`); SIGALRM exits with 142.
  perl -e 'alarm shift; exec @ARGV' "$TIMEOUT" \
    "$GODOT" --headless --path "$ROOT" --script "res://tools/godot/$name.gd" >"$log" 2>&1
  code=$?
  if [[ $code -eq 0 ]] && ! grep -qE "SCRIPT ERROR|ERROR:" "$log"; then
    pass=$((pass + 1))
    printf 'PASS  %s\n' "$name"
  else
    fail=$((fail + 1))
    reason="exit $code"
    [[ $code -eq 142 ]] && reason="timed out after ${TIMEOUT}s"
    printf 'FAIL  %s (%s) — logs/tests/%s.log\n' "$name" "$reason" "$name"
    grep -E "SCRIPT ERROR|ERROR:" "$log" | head -n 5 | sed 's/^/      /'
  fi
done

echo
echo "TESTS: $pass passed, $fail failed"
[[ $fail -eq 0 ]]
