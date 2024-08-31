#@osa-lang:AppleScript
property pScriptName : "Rename Records"

set mailscriptProperties to load script (POSIX path of (path to home folder) & ".applescript/properties-mailscripts.scpt")
set docLib to (load script (pDocLibraryPath of mailscriptProperties))
set mailLib to (load script (pMailLibraryPath of mailscriptProperties))

tell application id "DNtp"

	set currentDatabase to current database
	set databaseName to name of current database
	set theSelection to selection
	if databaseName contains "Mail" then
		tell mailLib to renameRecords(theSelection)
	else
		tell docLib
			initializeTagLists(currentDatabase)
			repeat with aRecord in theSelection
				setNameAndCustomMetadata(aRecord)
			end repeat
		end tell
	end if
end tell


