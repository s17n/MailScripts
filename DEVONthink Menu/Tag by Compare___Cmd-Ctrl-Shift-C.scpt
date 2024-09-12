#@osa-lang:AppleScript
property pScriptName : "Tag by Compare"

set propertiesPath to POSIX path of (path to home folder) & ".applescript/properties-mailscripts.scpt"
set mailscriptProperties to (load script propertiesPath)

try

	tell application id "DNtp"

		set currentDatabase to current database
		set databaseName to name of current database
		set theSelection to the selection
		if databaseName contains "Mail" then
			set mailLibraryPath to (the pMailLibraryPath of mailscriptProperties)
			set mailLib to (load script mailLibraryPath)
			repeat with aRecord in theSelection
				tell mailLib to tagByCompareRecords(aRecord, pScriptName)
			end repeat
		else
			set docLibraryPath to (the pDocLibraryPath of mailscriptProperties)
			set docLib to (load script docLibraryPath)
			repeat with aRecord in theSelection
				tell docLib
					initializeTagLists(currentDatabase)
					setNonDateTagsFromCompareRecord(aRecord, currentDatabase)
				end tell
			end repeat
		end if
	end tell

on error error_message number error_number
	if error_number is not -128 then display alert "Mail" message error_message as warning
end try
