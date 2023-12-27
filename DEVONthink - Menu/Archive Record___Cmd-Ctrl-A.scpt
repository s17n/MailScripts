#@osa-lang:AppleScript


on run

	set propertiesPath to POSIX path of (path to home folder)
	set propertiesPath to propertiesPath & ".applescript/properties-mailscripts.scpt"
	set mailscriptProperties to (load script propertiesPath)

	set mailLibraryPath to (the pMailLibraryPath of mailscriptProperties)
	set mailLib to (load script file mailLibraryPath)

	tell application id "DNtp"
		set theSelection to selection
		tell mailLib to archiveRecords(theSelection)
	end tell

end run


