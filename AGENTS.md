# AGENTS.md

## SCPT Workflow (verbindlich)

1. Vor jeder Bearbeitung alle `.scpt`-Dateien nach `./src` decompilieren.
2. Änderungen erfolgen auf den decompilierten Quellen in `./src`.
3. Nach jeder Code-Anpassung alle bearbeiteten Quellen wieder zu `.scpt` kompilieren.
4. Der Ordner `./src` ist ein lokales Arbeitsartefakt und darf nicht in Git eingecheckt werden.

## Hinweise

- Git-Filter (`osagitfilter`) bleibt für `.scpt` aktiv.
- Bei Bedarf nach Setup-Änderungen einmal `git add --renormalize .` ausführen.
