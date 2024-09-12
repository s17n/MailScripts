#@osa-lang:AppleScript
property pScriptName : "Delete Reminders"

set mailscriptProperties to load script (POSIX path of (path to home folder) & ".applescript/properties-mailscripts.scpt")
set mailLib to (load script (pDocLibraryPath of mailscriptProperties))

tell application id "DNtp"
	set theSelection to selection
	tell mailLib to deleteRemindersAndSetLabel(theSelection, pScriptName)
end tell

