#!/usr/bin/env bash
set -euo pipefail

mode="${1:---changed}"

if [[ "$mode" != "--changed" && "$mode" != "--stale" && "$mode" != "--all" ]]; then
  echo "Usage: $0 [--changed|--stale|--all]" >&2
  exit 2
fi

if [[ ! -d ".git" ]]; then
  echo "Run this script from the repository root." >&2
  exit 2
fi

tmp_paths="$(mktemp)"
tmp_refresh="$(mktemp)"
cleanup() {
  rm -f "$tmp_paths" "$tmp_refresh"
}
trap cleanup EXIT

refresh_one() {
  local rel="$1"
  local out

  [[ -f "$rel" ]] || return 0
  [[ "$rel" == *.scpt ]] || return 0

  out="src/${rel%.scpt}.applescript"
  mkdir -p "$(dirname "$out")"
  osadecompile "$rel" > "$out"
  printf '%s\n' "$out" >> "$tmp_refresh"
}

queue_changed_paths() {
  git ls-files -m -- '*.scpt' >> "$tmp_paths"
  git ls-files --others --exclude-standard -- '*.scpt' >> "$tmp_paths"
  git diff --name-only --cached -- '*.scpt' >> "$tmp_paths"
}

queue_all_paths() {
  find . -name '*.scpt' -print0 | while IFS= read -r -d '' f; do
    printf '%s\n' "${f#./}" >> "$tmp_paths"
  done
}

if [[ "$mode" == "--changed" ]]; then
  queue_changed_paths
  if [[ ! -s "$tmp_paths" ]]; then
    echo "No changed .scpt files detected."
    exit 0
  fi
  sort -u "$tmp_paths" | while IFS= read -r rel; do
    refresh_one "$rel"
  done
elif [[ "$mode" == "--all" ]]; then
  queue_all_paths
  sort -u "$tmp_paths" | while IFS= read -r rel; do
    refresh_one "$rel"
  done
else
  find . -name '*.scpt' -print0 | while IFS= read -r -d '' f; do
    rel="${f#./}"
    out="src/${rel%.scpt}.applescript"
    if [[ -f "$out" && "$out" -nt "$rel" ]]; then
      continue
    fi
    refresh_one "$rel"
  done
fi

if [[ ! -s "$tmp_refresh" ]]; then
  echo "No source files refreshed."
  exit 0
fi

count="$(wc -l < "$tmp_refresh" | tr -d '[:space:]')"
echo "Refreshed ${count} source file(s):"
cat "$tmp_refresh"
