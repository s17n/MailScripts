#@osa-lang:AppleScript
use AppleScript version "2.4"
use scripting additions

on configPath()
	return (POSIX path of (path to home folder)) & ".mailscripts/config.scpt"
end configPath

on run argv
	try
		set config to load script (my configPath())
		set docLib to load script (pDocLibraryPath of config)
		docLib's runCommand(argv, "update_dimensions_cache")
	on error errorMessage number errorNumber
		display alert "DEVONthink" message (errorMessage & " (" & errorNumber & ")") as warning
	end try
end run

