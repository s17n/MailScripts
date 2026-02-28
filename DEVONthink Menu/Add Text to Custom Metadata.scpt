#@osa-lang:AppleScript
set config to load script (POSIX path of (path to home folder) & ".mailscripts/config.scpt")
set docLib to load script pDocLibraryPath of config

try

	docLib's addTextToCustomMetadata("Subject", "Beispieltext")

on error error_message number error_number
	display alert "DEVONthink" message error_message as warning
end try
