#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
"$ROOT_DIR/scripts/run-testcase.sh" \
  "testcase-05" \
  "$ROOT_DIR/tests/updateRecordsMetadata/testcase-05-updaterecordsmetadata.scpt" \
  --source "$ROOT_DIR/src/tests/updateRecordsMetadata/testcase-05-updaterecordsmetadata.applescript" \
  "$@"
