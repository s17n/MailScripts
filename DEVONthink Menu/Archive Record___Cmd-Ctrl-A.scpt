#@osa-lang:AppleScript
property pScriptName : "Archive Records"

set mailscriptsConfig to load script (POSIX path of (path to home folder) & ".mailscripts/config.scpt")

tell application id "DNtp"
	set databaseName to name of current database
	set theSelection to selection
	if databaseName contains "Mail" then
		set mailLib to (load script (the pMailLibraryPath of mailscriptsConfig))
		tell mailLib to archiveRecords(theSelection, pScriptName)
	else
		set docLib to (load script (pDocLibraryPath of mailscriptsConfig))
		tell docLib to archiveRecords(theSelection, pScriptName)
	end if
end tell



