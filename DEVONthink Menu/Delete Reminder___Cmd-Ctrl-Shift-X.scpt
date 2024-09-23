#@osa-lang:AppleScript
property pScriptName : "Delete Reminders"

set mailscriptsConfig to load script (POSIX path of (path to home folder) & ".mailscripts/config.scpt")
set mailLib to (load script (pDocLibraryPath of mailscriptsConfig))

tell application id "DNtp"
	set theSelection to selection
	tell mailLib to deleteRemindersAndSetLabel(theSelection, pScriptName)
end tell
