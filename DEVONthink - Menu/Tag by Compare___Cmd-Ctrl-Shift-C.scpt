#@osa-lang:AppleScript
property pScriptName : "Tag by Compare"

set propertiesPath to POSIX path of (path to home folder)
set propertiesPath to propertiesPath & ".applescript/properties-mailscripts.scpt"
set mailscriptProperties to (load script propertiesPath)

try
	set mailLibraryPath to (the pMailLibraryPath of mailscriptProperties)
	set mailLib to (load script file mailLibraryPath)

	tell application id "DNtp"
		set theSelection to the selection
		repeat with aRecord in theSelection
			tell mailLib to tagByCompareRecords(aRecord, pScriptName)
		end repeat
	end tell

on error error_message number error_number
	if error_number is not -128 then display alert "Mail" message error_message as warning
end try
