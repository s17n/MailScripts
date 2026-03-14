#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage:
  run-testcase.sh <label> <compiled-script> [--source <source-script>] [--compile]
EOF
}

if [[ $# -lt 2 ]]; then
  usage >&2
  exit 2
fi

LABEL="$1"
COMPILED_SCRIPT="$2"
shift 2

SOURCE_SCRIPT=""
COMPILE_FIRST=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --source)
      if [[ $# -lt 2 ]]; then
        echo "[$LABEL] missing value for --source" >&2
        exit 2
      fi
      SOURCE_SCRIPT="$2"
      shift 2
      ;;
    --compile)
      COMPILE_FIRST=1
      shift
      ;;
    *)
      echo "[$LABEL] unknown argument: $1" >&2
      usage >&2
      exit 2
      ;;
  esac
done

if [[ $COMPILE_FIRST -eq 1 ]]; then
  if [[ -z "$SOURCE_SCRIPT" ]]; then
    echo "[$LABEL] --compile requires --source <source-script>" >&2
    exit 2
  fi
  if [[ ! -f "$SOURCE_SCRIPT" ]]; then
    echo "[$LABEL] source script not found: $SOURCE_SCRIPT" >&2
    exit 2
  fi
  echo "[$LABEL] compiling"
  osacompile -o "$COMPILED_SCRIPT" "$SOURCE_SCRIPT"
fi

if [[ ! -f "$COMPILED_SCRIPT" ]]; then
  echo "[$LABEL] compiled script not found: $COMPILED_SCRIPT" >&2
  exit 2
fi

echo "[$LABEL] running"
set +e
RUN_OUTPUT="$(osascript "$COMPILED_SCRIPT" 2>&1)"
OSASCRIPT_EXIT_CODE=$?
set -e

printf '%s\n' "$RUN_OUTPUT"

if [[ $OSASCRIPT_EXIT_CODE -ne 0 ]]; then
  echo "[$LABEL] osascript exited with code $OSASCRIPT_EXIT_CODE" >&2
  exit 2
fi

if printf '%s\n' "$RUN_OUTPUT" | grep -q '^PASS:'; then
  exit 0
fi

if printf '%s\n' "$RUN_OUTPUT" | grep -q '^FAIL'; then
  exit 1
fi

echo "[$LABEL] could not determine PASS/FAIL from output" >&2
exit 2
