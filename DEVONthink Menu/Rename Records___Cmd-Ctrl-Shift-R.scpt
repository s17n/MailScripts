#@osa-lang:AppleScript
property pScriptName : "Rename Records"

property propertiesPath : POSIX path of (path to home folder) & ".applescript/properties-mailscripts.scpt"
set mailscriptProperties to (load script propertiesPath)

set mailLibraryPath to (the pMailLibraryPath of mailscriptProperties)
set mailLib to (load script file mailLibraryPath)

set docLibraryPath to (the pDocLibraryPath of mailscriptProperties)
set docLib to (load script file docLibraryPath)

tell application id "DNtp"

	set databaseName to name of current database
	set theSelection to selection
	if databaseName contains "Mail" then
		tell mailLib to renameRecords(theSelection)
	else
		tell docLib
			initializeTagLists(theDatabase)
			repeat with aRecord in theSelection
				renameAndUpdateCustomMetadata(aRecord, pScriptName)
			end repeat
		end tell
	end if
end tell


