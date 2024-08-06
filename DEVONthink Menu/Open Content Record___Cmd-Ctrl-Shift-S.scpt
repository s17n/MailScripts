#@osa-lang:AppleScript
property pScriptName : "Open Content Record"

set propertiesPath to POSIX path of (path to home folder) & ".applescript/properties-mailscripts.scpt"
set mailscriptProperties to (load script propertiesPath)

set mailLibraryPath to (the pMailLibraryPath of mailscriptProperties)
set mailLib to (load script file mailLibraryPath)

set type to "x-content"
tell mailLib to openXTypeRecord(type, pScriptName)