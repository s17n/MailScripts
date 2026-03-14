#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
COMPILED_SCRIPT="$ROOT_DIR/tests/classifyRecords/testcase-04-classifyrecords.scpt"

if [[ ! -f "$COMPILED_SCRIPT" ]]; then
  echo "[testcase-04] compiled script not found: $COMPILED_SCRIPT" >&2
  exit 2
fi

echo "[testcase-04] running"
set +e
RUN_OUTPUT="$(osascript "$COMPILED_SCRIPT" 2>&1)"
OSASCRIPT_EXIT_CODE=$?
set -e

printf '%s\n' "$RUN_OUTPUT"

if [[ $OSASCRIPT_EXIT_CODE -ne 0 ]]; then
  echo "[testcase-04] osascript exited with code $OSASCRIPT_EXIT_CODE" >&2
  exit 2
fi

if printf '%s\n' "$RUN_OUTPUT" | grep -q '^PASS:'; then
  exit 0
fi

if printf '%s\n' "$RUN_OUTPUT" | grep -q '^FAIL'; then
  exit 1
fi

echo "[testcase-04] could not determine PASS/FAIL from output" >&2
exit 2
