#@osa-lang:AppleScript
property pScriptName : "Open Action Record"

set mailscriptProperties to load script (POSIX path of (path to home folder) & ".applescript/properties-mailscripts.scpt")
set mailLib to (load script (pMailLibraryPath of mailscriptProperties))

set type to "x-action"
tell mailLib to openXTypeRecord(type, pScriptName)