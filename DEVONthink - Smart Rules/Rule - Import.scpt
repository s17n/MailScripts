#@osa-lang:AppleScript
property pScriptName : "Rule - Import Document"

property pDocSciptsPropertiesPath : POSIX path of (path to home folder) & ".applescript/properties-docscripts.scpt"

on performSmartRule(theRecords)

	set scptProp to (load script pDocSciptsPropertiesPath)
	set docLibraryPath to (the pDocLibraryPath of scptProp)
	set docLib to (load script file docLibraryPath)
	tell docLib to importDocuments(theRecords)

end performSmartRule

