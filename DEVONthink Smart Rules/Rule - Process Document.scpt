#@osa-lang:AppleScript
property pScriptName : "Rule - Process Document"

on performSmartRule(theRecords)

	set mailscriptsConfig to load script (POSIX path of (path to home folder) & ".mailscripts/config.scpt")
	set docLib to (load script (pDocLibraryPath of mailscriptsConfig))

	tell docLib to processDocuments(theRecords)

end performSmartRule

tell application id "DNtp"
	set theSelection to selection
	my performSmartRule(theSelection)
end tell

