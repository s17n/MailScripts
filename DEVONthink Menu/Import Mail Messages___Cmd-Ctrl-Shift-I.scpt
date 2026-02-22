#@osa-lang:AppleScript
set config to load script (POSIX path of (path to home folder) & ".mailscripts/config.scpt")
set docLib to load script pDocLibraryPath of config

try

	set theEmailDatabase to pPrimaryEmailDatabase of config
	tell docLib to importMailMessages(theEmailDatabase)

on error error_message number error_number
	display alert "DEVONthink" message error_message as warning
end try

