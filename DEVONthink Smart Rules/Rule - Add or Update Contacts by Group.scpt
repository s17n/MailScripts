#@osa-lang:AppleScript
-- Adds the author of the mail message to Contacts

property pScriptName : "Rule - Add/Update Contacts"

property mailscriptsConfig : POSIX path of (path to home folder) & ".mailscripts/config.scpt"

on performAction(theRecords)
	set scptProp to (load script mailscriptsConfig)
	set mailLibraryPath to (the pMailLibraryPath of scptProp)

	set mailLib to (load script mailLibraryPath)
	tell mailLib to addOrUpdateContactsByGroup(theRecords, pScriptName)
end performAction

on performSmartRule(theRecords)
	my performAction(theRecords)
end performSmartRule

on run {}
	tell application id "DNtp"
		set theSelection to selection
		my performAction(theSelection)
	end tell

end run