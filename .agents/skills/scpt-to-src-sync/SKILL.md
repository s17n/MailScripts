---
name: scpt-to-src-sync
description: Automatically refresh ignored AppleScript sources under /src from changed versioned .scpt files. Use when manual .scpt edits happen in parallel or before working on AppleScript sources.
---

# SCPT To SRC Sync

1. Before reading or editing AppleScript sources, run `bash scripts/sync-scpt-to-src.sh --changed`.
2. If no `.scpt` changes are detected by Git but `/src` may still be stale, run `bash scripts/sync-scpt-to-src.sh --stale`.
3. Use `bash scripts/sync-scpt-to-src.sh --all` only when a full rebuild of `/src` is needed.
4. Treat `/src` as ignored working sources only; do not stage `/src`.

## Commands

From the repository root:

```bash
bash .agents/skills/scpt-to-src-sync/scripts/sync-scpt-to-src.sh --changed
```

```bash
bash .agents/skills/scpt-to-src-sync/scripts/sync-scpt-to-src.sh --stale
```

```bash
bash .agents/skills/scpt-to-src-sync/scripts/sync-scpt-to-src.sh --all
```
