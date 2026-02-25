#@osa-lang:AppleScript
property pScriptName : "Rule - Create Smart Group for Sender"

on performSmartRule(theRecords)

	set config to load script (POSIX path of (path to home folder) & ".mailscripts/config.scpt")
	set docLib to (load script (pDocLibraryPath of config))

	set theEmailDatabase to pPrimaryEmailDatabase of config
	tell docLib to createSmartGroupForSender(theRecords, theEmailDatabase)

end performSmartRule

tell application id "DNtp"
	set theSelection to selection
	my performSmartRule(theSelection)
end tell

