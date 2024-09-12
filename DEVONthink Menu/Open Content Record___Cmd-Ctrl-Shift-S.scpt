#@osa-lang:AppleScript
property pScriptName : "Open Content Record"

set mailscriptProperties to load script (POSIX path of (path to home folder) & ".applescript/properties-mailscripts.scpt")
set mailLib to (load script (pMailLibraryPath of mailscriptProperties))

set type to "x-content"
tell mailLib to openXTypeRecord(type, pScriptName)