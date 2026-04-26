---
name: applescript-src-sync
description: Maintain ignored AppleScript source files under /src as the editing baseline for versioned .scpt files. Use when creating, updating, reviewing, or refactoring AppleScripts so edits happen in src/*.applescript and changed files are recompiled to matching *.scpt files.
---

# AppleScript Source Sync

1. Discover the relevant script files before work.
2. Verify `/src` is current by decompiling only newer `.scpt` files, or `.scpt` files whose matching `/src` source is missing.
3. Edit only `src/*.applescript` files.
4. Recompile every changed `src/*.applescript` back to its matching versioned `*.scpt`.
5. Verify compile success for each changed script before finishing.
6. Do not stage `/src`; it is an ignored working source tree for AI coding agents only.

## Path Mapping

- Source path: `src/<relative/path/to/file>.applescript`
- Compiled path: `<relative/path/to/file>.scpt` (versioned artifact)
- Example: `src/Libs/DocLibrary.applescript` -> `Libs/DocLibrary.scpt`

## Commands

Refresh only stale or missing sources from compiled files:

```bash
find . -name '*.scpt' -print0 | while IFS= read -r -d '' f; do
  rel="${f#./}"
  out="src/${rel%.scpt}.applescript"
  if [ -f "$out" ] && [ "$out" -nt "$rel" ]; then
    continue
  fi
  mkdir -p "$(dirname "$out")"
  osadecompile "$rel" > "$out"
done
```

Compile one changed source:

```bash
osacompile -o "Libs/DocLibrary.scpt" "src/Libs/DocLibrary.applescript"
```

Compile all changed sources under `src`:

```bash
find src -name '*.applescript' -print0 | while IFS= read -r -d '' s; do
  rel="${s#src/}"
  out="${rel%.applescript}.scpt"
  mkdir -p "$(dirname "$out")"
  osacompile -o "$out" "$s"
done
```
