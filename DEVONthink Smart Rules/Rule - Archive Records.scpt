#@osa-lang:AppleScript
property pScriptName : "Rule - Archive Records"

property mailscriptsConfig : POSIX path of (path to home folder) & ".mailscripts/config.scpt"

on performSmartRule(theRecords)

	set scptProp to (load script mailscriptsConfig)
	set mailLibraryPath to (the pMailLibraryPath of scptProp)
	set archiveRoot to (the pDtArchiveRoot of scptProp)

	set mailLib to (load script file mailLibraryPath)
	tell mailLib to archiveRecords(archiveRoot, theRecords, pScriptName)

end performSmartRule

