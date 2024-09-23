#@osa-lang:AppleScript
property pScriptName : "Open Messages Record"

set mailscriptsConfig to load script (POSIX path of (path to home folder) & ".mailscripts/config.scpt")
set mailLib to (load script (pMailLibraryPath of mailscriptsConfig))

set type to "x-messages"
tell mailLib to openXTypeRecord(type, pScriptName)