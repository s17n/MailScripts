#@osa-lang:AppleScript
property pScriptName : "Open Content Record"

set mailscriptsConfig to load script (POSIX path of (path to home folder) & ".mailscripts/config.scpt")
set mailLib to (load script (pMailLibraryPath of mailscriptsConfig))

set type to "x-content"
tell mailLib to openXTypeRecord(type, pScriptName)