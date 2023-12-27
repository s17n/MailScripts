#@osa-lang:AppleScript
-- Adds the author of the mail message to Contacts

property pScriptName : "Rule - Add/Update Contacts"

property pMailPropertiesPath : POSIX path of (path to home folder) & ".applescript/properties-mailscripts.scpt"

on performSmartRule(theRecords)

	set scptProp to (load script pMailPropertiesPath)
	set mailLibraryPath to (the pMailLibraryPath of scptProp)

	set mailLib to (load script file mailLibraryPath)
	tell mailLib to addOrUpdateContactsByGroup(theRecords, pScriptName)

end performSmartRule

