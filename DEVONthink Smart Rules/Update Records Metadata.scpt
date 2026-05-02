#@osa-lang:AppleScript
use AppleScript version "2.4"
use scripting additions

on configPath()
	return (POSIX path of (path to home folder)) & ".mailscripts/config.scpt"
end configPath

on performSmartRule(theRecords)
	my runCommand(theRecords, missing value)
end performSmartRule

on run argv
	my runCommand(missing value, argv)
end run

on runCommand(theRecords, argv)
	try
		set config to load script (my configPath())
		set docLib to load script (pDocLibraryPath of config)
		docLib's runSmartRuleCommand(theRecords, argv, "smart_update_metadata")
	on error errorMessage number errorNumber
		display alert "DEVONthink" message (errorMessage & " (" & errorNumber & ")") as warning
	end try
end runCommand



