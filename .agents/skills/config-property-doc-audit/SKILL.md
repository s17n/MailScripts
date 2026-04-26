---
name: config-property-doc-audit
description: Audit whether properties from Default-Configuration-Documents.scpt and Default-Configuration-Emails.scpt are documented in classification-system.md, custom-metadata-additions.md, name-and-file-documents.md, configuration.md, or configuration-email.md, and verify descriptions match implementation.
---

# Config Property Documentation Audit

Use this skill when the user asks to validate configuration property documentation coverage and implementation alignment.

## Inputs

- Source config files:
  - `src/Configuration/Default-Configuration-Documents.applescript`
  - `src/Configuration/Default-Configuration-Emails.applescript`
- Target documentation files:
  - `Docs/classification-system.md`
  - `Docs/custom-metadata-additions.md`
  - `Docs/name-and-file-documents.md`
  - `Docs/configuration.md`
  - `Docs/configuration-email.md`
- Implementation references:
  - `src/Libs/DocLibrary.applescript`
  - `src/Libs/MailLibrary.applescript`
  - related caller scripts where needed (mail rules, DEVONthink menu/smart rules)

## Workflow

1. Extract all `property p...` names from both source config files.
2. Check whether each property name appears in at least one target documentation file.
3. For each documented property, verify the description against implementation usage.
4. Report missing properties, mismatched descriptions, and notable implementation inconsistencies.

## Output Contract

- If properties are missing: list exact property names.
- If descriptions are inaccurate: list exact properties and explain the mismatch in one line each.
- If updates are needed: ask for confirmation before editing any documentation.
- If no gaps exist: explicitly state that coverage and description alignment are complete.

## Suggested Commands

List config properties:

```bash
rg -o 'property\s+(p[A-Za-z0-9_]+)' src/Configuration/Default-Configuration-Documents.applescript src/Configuration/Default-Configuration-Emails.applescript -r '$1' | sort -u
```

Find property mentions in docs:

```bash
rg -n 'p[A-Za-z0-9_]+' Docs/classification-system.md Docs/custom-metadata-additions.md Docs/name-and-file-documents.md Docs/configuration.md Docs/configuration-email.md
```

Trace implementation usage:

```bash
rg -n 'p[A-Za-z0-9_]+' src/Libs/DocLibrary.applescript src/Libs/MailLibrary.applescript src/Mail\ Rules/*.applescript src/DEVONthink\ Menu/*.applescript src/DEVONthink\ Smart\ Rules/*.applescript
```
