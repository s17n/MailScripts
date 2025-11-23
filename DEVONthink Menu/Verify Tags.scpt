#@osa-lang:AppleScript
property pScriptName : "Verify Tags"

set mailscriptsConfig to load script (POSIX path of (path to home folder) & ".mailscripts/config.scpt")
set docLib to (load script (pDocLibraryPath of mailscriptsConfig))

tell docLib
	initialize()
	verifyTags(true, true)
end tell


