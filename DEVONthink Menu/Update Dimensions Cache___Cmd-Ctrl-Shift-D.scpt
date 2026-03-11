#@osa-lang:AppleScript
set config to load script (POSIX path of (path to home folder) & ".mailscripts/config.scpt")
set docLib to load script pDocLibraryPath of config

try
	tell application id "DNtp"
		set theDatabaseName to name of current database
	end tell

	docLib's updateDimensionsCache(theDatabaseName)

on error error_message number error_number
	display alert "DEVONthink" message error_message as warning
end try

