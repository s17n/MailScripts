# DEVONthink Menu Worker Pattern

## Purpose

Some DEVONthink menu scripts are slow when executed directly inside DEVONthink because they trigger many AppleEvents.  
To reduce runtime, selected scripts use a wrapper/worker execution pattern.

The same performance problem is typically not observed when the script runs via `osascript`.  
Reason: AppleEvents are then handled as external process calls instead of in-process menu-script execution, which reduces overhead for event-heavy workflows.
This is an engineering inference from AppleEvent/OSA behavior and observed runtime in this project.

## Flow

1. DEVONthink runs the menu script (`.scpt`) without worker flag.
2. The script relaunches itself externally via:
   `/usr/bin/osascript -l AppleScript "<same-script-path>" --worker`
3. In worker mode (`--worker`), the script executes `runCore()`.
4. `runCore()` loads `~/.mailscripts/config.scpt`, resolves `DocLibrary.scpt`, reads `selection`, and executes the business handler.

## Script Structure

Each converted menu script follows this handler layout:

- `hasWorkerFlag(theArgs)`
- `run argv`
- `runCore()`

This keeps handlers alphabetically sorted and the runtime behavior consistent.

## Current Scripts Using This Pattern

- `DEVONthink Menu/Classify Records___Cmd-Ctrl-Shift-C.scpt`
- `DEVONthink Menu/Update Records Metadata___Cmd-Ctrl-Shift-U.scpt`
- `DEVONthink Menu/Archive Records___Cmd-Ctrl-Shift-A.scpt`

## Notes

- Error handling shows `display alert "DEVONthink"` with message and error number.
- `DocLibrary` remains unchanged; behavior changes are isolated to menu-script launch mechanics.

## Sources

- AppleScript Language Guide, Commands Reference (`do shell script`, `load script`, `get`): [developer.apple.com](https://developer.apple.com/library/archive/documentation/AppleScript/Conceptual/AppleScriptLangGuide/reference/ASLR_cmds.html)
- Mac Automation Scripting Guide, How Mac Scripting Works (OSA and Apple events as interprocess messages): [developer.apple.com](https://developer.apple.com/library/archive/documentation/LanguagesUtilities/Conceptual/MacAutomationScriptingGuide/HowMacScriptingWorks.html)
- Mac Automation Scripting Guide, Calling Command-Line Tools (`do shell script`, quoting, command execution): [developer.apple.com](https://developer.apple.com/library/archive/documentation/LanguagesUtilities/Conceptual/MacAutomationScriptingGuide/CallCommandLineUtilities.html)
