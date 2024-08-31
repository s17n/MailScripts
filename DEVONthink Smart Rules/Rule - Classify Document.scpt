#@osa-lang:AppleScript
property pScriptName : "Rule - Classify Document"

on performSmartRule(theRecords)

	set mailscriptProperties to load script (POSIX path of (path to home folder) & ".applescript/properties-mailscripts.scpt")
	set docLib to (load script (pDocLibraryPath of mailscriptProperties))

	tell docLib to classifyDocuments(theRecords)

end performSmartRule

