#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
"$ROOT_DIR/scripts/run-testcase.sh" \
  "testcase-04" \
  "$ROOT_DIR/tests/classifyRecords/testcase-04-classifyrecords.scpt" \
  --source "$ROOT_DIR/src/tests/classifyRecords/testcase-04-classifyrecords.applescript" \
  "$@"
