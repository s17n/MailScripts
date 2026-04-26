---
name: decompile
description: Refresh outdated AppleScript source files under /src from their corresponding versioned .scpt files.
---

# Decompile

1. Find all versioned `.scpt` files whose modification time is newer than the matching ignored source file under `/src`, or whose matching source file is missing.
2. Decompile only those `.scpt` files to `src/<same-path>.applescript`.
3. Keep `/src` as an ignored working source tree for AI coding agents; do not stage it.
4. Report which `.applescript` files were refreshed.
