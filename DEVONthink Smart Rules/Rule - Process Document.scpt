#@osa-lang:AppleScript
property pScriptName : "Rule - Process Document"

on performSmartRule(theRecords)

	set mailscriptsConfig to load script (POSIX path of (path to home folder) & ".mailscripts/config.scpt")
	set docLib to (load script (pDocLibraryPath of mailscriptsConfig))

	set theDatabase to missing value
	tell application id "DNtp" to set theDatabase to database of first item of theRecords

	tell docLib to processDocuments(theDatabase, theRecords)

end performSmartRule

tell application id "DNtp"
	set theSelection to selection
	my performSmartRule(theSelection)
end tell

