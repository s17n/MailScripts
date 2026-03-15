#@osa-lang:AppleScript
set configPath to (POSIX path of (path to home folder)) & ".mailscripts/config.scpt"
set config to load script configPath
set docLib to load script (pDocLibraryPath of config)

try
	tell application id "DNtp" to set theSelection to get selection
	if theSelection is {} then error "Please select some contents."

	set theSmartGroupSpecifier to {customMetadataIdentifier:"sender", smartgroupsFolder:"03 Resources/Sender"}
	docLib's openCustomMetadataSmartGroup(theSmartGroupSpecifier, theSelection)
on error errorMessage number errorNumber
	display alert "DEVONthink" message (errorMessage & " (" & errorNumber & ")") as warning
end try
