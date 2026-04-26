# AGENTS.md

## SCPT Workflow (mandatory)

1. At the beginning of each new thread, verify that AppleScripts under `/src` are up to date by decompiling newer `.scpt` files into their matching `src/<same-path>.applescript` files. Prefer the local AppleScript source sync/decompile instructions when available.
2. `/src` is not versioned; it is a working source tree for AI coding agents only. The corresponding `.scpt` files are the versioned artifacts.
3. Always work on the source files under `/src`.
4. After source code changes, always update the corresponding `.scpt` file as well.
5. Keep handlers in each AppleScript file sorted alphabetically by handler name.

## Documentation Language (mandatory)

1. Write all documentation in English.
2. When updating existing documentation, translate affected German content to English.

## DEVONthink Automation Dictionary (mandatory)

1. For DEVONthink automation work, use `/Applications/DEVONthink.app/Contents/Resources/DEVONthink.sdef` as the primary AppleScript dictionary reference.
2. Verify DEVONthink commands, classes, properties, event codes, and terminology against this `.sdef` file before implementing or changing automation code.
3. Use targeted runtime probes such as `osascript` only to validate behavior that cannot be determined from the dictionary.
