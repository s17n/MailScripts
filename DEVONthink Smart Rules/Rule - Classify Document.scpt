#@osa-lang:AppleScript
property pScriptName : "Rule - Classify Document"

on performSmartRule(theRecords)

	set mailscriptsConfig to load script (POSIX path of (path to home folder) & ".mailscripts/config.scpt")
	set docLib to (load script (pDocLibraryPath of mailscriptsConfig))

	tell docLib to classifyDocuments(theRecords)

end performSmartRule

