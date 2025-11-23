#@osa-lang:AppleScript
property pScriptName : "Classify Document"

set mailscriptsConfig to load script (POSIX path of (path to home folder) & ".mailscripts/config.scpt")
set docLib to (load script (pDocLibraryPath of mailscriptsConfig))
set mailLib to (load script (pMailLibraryPath of mailscriptsConfig))

tell application id "DNtp"

	set currentDatabase to current database
	set databaseName to name of current database
	set theSelection to the selection

	if databaseName contains "Mail" then
		tell mailLib to classifyMessages(theSelection)
	else
		tell docLib to classifyDocuments(theSelection)
	end if

end tell


