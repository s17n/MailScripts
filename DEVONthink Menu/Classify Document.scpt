#@osa-lang:AppleScript
property pScriptName : "Classify Document"

set mailscriptsConfig to load script (POSIX path of (path to home folder) & ".mailscripts/config.scpt")
set docLib to (load script (pDocLibraryPath of mailscriptsConfig))

tell application id "DNtp"
	set theSelection to selection
	tell docLib to classifyDocuments(theSelection)
end tell


