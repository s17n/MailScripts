# AGENTS.md

## SCPT Workflow (mandatory)

1. `.scpt` files are the versioned repository artifacts and authoritative for commits.
2. `.applescript` files under `/src` are unversioned working sources for AI coding agents.
3. At the beginning of each new thread, verify that `/src` is up to date by decompiling newer `.scpt` files (or missing sources) into matching `src/<same-path>.applescript` files.
4. Make source code changes only in files under `/src`.
5. After source changes, always compile the corresponding `.scpt` file.
6. Keep handlers in each AppleScript file sorted alphabetically by handler name.

## Documentation Language (mandatory)

1. Write all documentation in English.
2. When updating existing documentation, translate affected German content to English.

## Code Documentation (mandatory)

1. For non-trivial handlers, add short comments for each functional block so the flow stays readable.
2. Do not comment every line; avoid obvious comments that only restate the code.
3. When behavior changes, update related comments in the same edit.

## DEVONthink Automation Dictionary (mandatory)

1. For DEVONthink automation work, use `/Applications/DEVONthink.app/Contents/Resources/DEVONthink.sdef` as the primary AppleScript dictionary reference.
2. Verify DEVONthink commands, classes, properties, event codes, and terminology against this `.sdef` file before implementing or changing automation code.
3. Use targeted runtime probes such as `osascript` only to validate behavior that cannot be determined from the dictionary.
