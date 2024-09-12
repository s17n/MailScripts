#@osa-lang:AppleScript
property pScriptName : "Open Messages Record"

set mailscriptProperties to load script (POSIX path of (path to home folder) & ".applescript/properties-mailscripts.scpt")
set mailLib to (load script (pMailLibraryPath of mailscriptProperties))

set type to "x-messages"
tell mailLib to openXTypeRecord(type, pScriptName)