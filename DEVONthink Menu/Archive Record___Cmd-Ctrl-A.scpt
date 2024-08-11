#@osa-lang:AppleScript
property pScriptName : "Archive Records"

property propertiesPath : POSIX path of (path to home folder) & ".applescript/properties-mailscripts.scpt"
set mailscriptProperties to (load script propertiesPath)

set mailLibraryPath to (the pMailLibraryPath of mailscriptProperties)
set mailLib to (load script file mailLibraryPath)

tell application id "DNtp"
	set databaseName to name of current database
	set theSelection to selection
	if databaseName contains "Mail" then
		tell mailLib to archiveRecords(theSelection, pScriptName)
	else
		tell mailLib to archiveRecords(theSelection, pScriptName)
	end if
end tell



