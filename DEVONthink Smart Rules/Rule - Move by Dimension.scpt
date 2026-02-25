#@osa-lang:AppleScript
property pScriptName : "Rule - Move by Dimension"

on performSmartRule(theRecords)

	set mailscriptsConfig to load script (POSIX path of (path to home folder) & ".mailscripts/config.scpt")
	set docLib to (load script (pDocLibraryPath of mailscriptsConfig))

	tell docLib to moveByDimension(theRecords, "01 Project", "Inbox")

end performSmartRule

tell application id "DNtp"
	set theSelection to selection
	my performSmartRule(theSelection)
end tell

