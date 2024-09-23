#@osa-lang:AppleScript
-- Adds the author of the mail message to Contacts

property pScriptName : "Rule - Set Tag by Group"

property pMailPropertiesPath : POSIX path of (path to home folder) & ".mailscripts/config.scpt"

on performSmartRule(theRecords)

	set scptProp to (load script pMailPropertiesPath)
	set mailLibraryPath to (the pMailLibraryPath of scptProp)

	set mailLib to (load script file mailLibraryPath)
	tell mailLib to setGroupAsTag(theRecords, pScriptName)

end performSmartRule

".mailscripts/config.scpt"