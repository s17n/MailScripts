#@osa-lang:AppleScript
-- Launcher für MailLibrary.setGroupAsTag()

property pScriptName : "Tag by Group"

set propertiesPath to POSIX path of (path to home folder)
set propertiesPath to propertiesPath & ".applescript/properties-mailscripts.scpt"
set mailscriptProperties to (load script propertiesPath)

try
	set mailLibraryPath to (the pMailLibraryPath of mailscriptProperties)

	tell application id "DNtp" to set theSelection to the selection

	set mailLib to (load script file mailLibraryPath)
	tell mailLib to setGroupAsTag(theSelection, pScriptName)

on error error_message number error_number
	if error_number is not -128 then display alert "Mail" message error_message as warning
end try
