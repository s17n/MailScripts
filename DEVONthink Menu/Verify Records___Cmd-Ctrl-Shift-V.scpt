#@osa-lang:AppleScript
property pScriptName : "Verify Tags"

set mailscriptsConfig to load script (POSIX path of (path to home folder) & ".mailscripts/config.scpt")
set docLib to (load script (pDocLibraryPath of mailscriptsConfig))

try
	-- set locationSuffix to "2010-2019/2015/11" -- issue, record lag in 05 in zwei Foldern
	set theLocation to "/05 Files"

	tell docLib to verifyTags(theLocation)

on error error_message number error_number
	display alert "DEVONthink" message error_message as warning
end try
