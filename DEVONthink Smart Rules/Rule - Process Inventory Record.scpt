#@osa-lang:AppleScript
property pScriptName : "Rule - Process Inventory Record"

on performSmartRule(theRecords)
	set mailscriptsConfig to load script (POSIX path of (path to home folder) & ".mailscripts/config.scpt")
	set docLib to (load script (pDocLibraryPath of mailscriptsConfig))

	tell application id "DNtp"
		set theDatabase to database of first item of theRecords
		tell docLib to processInventoryRecords(theRecords)
		tell docLib to classifyRecords(theDatabase, theRecords)
		tell docLib to updateRecordsMetadata(theDatabase, theRecords)
	end tell

end performSmartRule

tell application id "DNtp"
	set theSelection to selection
	my performSmartRule(theSelection)
end tell

