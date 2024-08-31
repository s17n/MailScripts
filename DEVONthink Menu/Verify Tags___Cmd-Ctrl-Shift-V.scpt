#@osa-lang:AppleScript
property pScriptName : "Verify Tags"

set mailscriptProperties to load script (POSIX path of (path to home folder) & ".applescript/properties-mailscripts.scpt")
set docLib to (load script (pDocLibraryPath of mailscriptProperties))

tell docLib
	initialize()
	verifyTags(true, true)
end tell


