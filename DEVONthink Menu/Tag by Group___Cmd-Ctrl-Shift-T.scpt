#@osa-lang:AppleScript
-- Launcher für MailLibrary.setGroupAsTag()

property pScriptName : "Tag by Group"

set mailscriptsConfig to load script (POSIX path of (path to home folder) & ".mailscripts/config.scpt")

try
	set mailLibraryPath to (the pMailLibraryPath of mailscriptsConfig)

	tell application id "DNtp" to set theSelection to the selection

	set mailLib to (load script file mailLibraryPath)
	tell mailLib to setGroupAsTag(theSelection, pScriptName)

on error error_message number error_number
	if error_number is not -128 then display alert "Mail" message error_message as warning
end try
