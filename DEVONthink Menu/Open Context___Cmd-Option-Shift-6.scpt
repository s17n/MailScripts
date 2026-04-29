#@osa-lang:AppleScript
set configPath to (POSIX path of (path to home folder)) & ".mailscripts/config.scpt"
set config to load script configPath
set docLib to load script (pDocLibraryPath of config)

try
	tell application id "DNtp" to set theSelection to every selected record

	set theSmartGroupSpecifier to {dimension:"06 Context", customMetadataField:"", smartgroupsFolder:"03 Resources/Context"}
	docLib's openSmartGroup(theSmartGroupSpecifier, theSelection)
on error errorMessage number errorNumber
	display alert "DEVONthink" message (errorMessage & " (" & errorNumber & ")") as warning
end try
