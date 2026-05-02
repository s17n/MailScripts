# DEVONthink Worker Pattern

## Purpose

Some DEVONthink menu scripts are slow when executed directly inside DEVONthink because they trigger many AppleEvents.  
To reduce runtime, DEVONthink scripts in this project use a centralized wrapper/worker execution pattern in `DocLibrary`.

The same performance problem is typically not observed when the script runs via `osascript`.  
Reason: AppleEvents are then handled as external process calls instead of in-process menu-script execution, which reduces overhead for event-heavy workflows.
This is an engineering inference from AppleEvent/OSA behavior and observed runtime in this project.

## Global toggle

Worker usage is controlled globally via `~/.mailscripts/config.scpt`:

```applescript
property pUseWorker : true
```

- `true`: worker-capable scripts relaunch through `osascript ... --worker` and execute in the external worker process.
- `false`: scripts execute directly without relaunch.

## Menu Script Flow

1. DEVONthink runs a menu script (`.scpt`) and calls `docLib's runCommand(argv, "<commandKey>")`.
2. `runCommand` loads `~/.mailscripts/config.scpt` and evaluates `pUseWorker`.
3. If worker mode is enabled and `argv` does not contain `--worker`, `runCommand` relaunches the current script externally via:
   `/usr/bin/osascript -l AppleScript "<same-script-path>" --worker`
4. In worker mode (`--worker`) or with `pUseWorker : false`, `runCommand` dispatches the command key to the business handler.
5. For selected commands, `runCommand` wraps execution with performance tracing.

For handlers that support an empty selection (for example smart-group navigation commands), the fallback behavior is implemented inside the library handler itself.

## Smart Rule Flow

1. DEVONthink runs a smart rule (`performSmartRule(theRecords)`).
2. The wrapper calls `docLib's runSmartRuleCommand(theRecords, argv, "<commandKey>")`.
3. If worker mode is enabled and the invocation is not already a worker call (`--worker`), `runSmartRuleCommand`:
   - extracts stable record UUIDs from `theRecords`
   - relaunches the same script as:
     `/usr/bin/osascript -l AppleScript "<same-script-path>" --worker --smart-rule-command "<commandKey>" --record-uuid "<uuid>" ...`
4. In worker mode (or when `pUseWorker` is `false`), `runSmartRuleCommand` resolves records from `--record-uuid` arguments and dispatches by smart-rule command key.

## Script Structure

Each converted DEVONthink menu script uses a minimal wrapper:

- `run argv`
- `configPath()`

Each converted DEVONthink smart rule script uses:

- `performSmartRule(theRecords)`
- `run argv`
- `runCommand(theRecords, argv)`

The worker logic and command dispatch are centralized in `DocLibrary`:

- `runCommand(argv, commandKey)`
- `runMenuCommand(commandKey, config)`
- `runSmartRuleCommand(theRecords, argv, commandKey)`
- `runSmartRuleCommandByKey(commandKey, theRecords)`
- `shouldUseWorker(argv, config)`
- `hasWorkerFlag(theArgs)`
- `recordUUIDsFromRecords(theRecords)`
- `recordsFromWorkerArgs(argv)`

## Menu Command Keys

The following logical command keys are currently used:

- `archive`
- `classify`
- `import_mail`
- `open_context`
- `open_label`
- `open_sender`
- `open_subject`
- `open_year`
- `update_dimensions_cache`
- `update_metadata`
- `verify_records`

## Smart Rule Command Keys

The following smart-rule command keys are currently used:

- `smart_classify`
- `smart_process_documents`
- `smart_update_metadata`

## Sources

- AppleScript Language Guide, Commands Reference (`do shell script`, `load script`, `get`): [developer.apple.com](https://developer.apple.com/library/archive/documentation/AppleScript/Conceptual/AppleScriptLangGuide/reference/ASLR_cmds.html)
- Mac Automation Scripting Guide, How Mac Scripting Works (OSA and Apple events as interprocess messages): [developer.apple.com](https://developer.apple.com/library/archive/documentation/LanguagesUtilities/Conceptual/MacAutomationScriptingGuide/HowMacScriptingWorks.html)
- Mac Automation Scripting Guide, Calling Command-Line Tools (`do shell script`, quoting, command execution): [developer.apple.com](https://developer.apple.com/library/archive/documentation/LanguagesUtilities/Conceptual/MacAutomationScriptingGuide/CallCommandLineUtilities.html)
