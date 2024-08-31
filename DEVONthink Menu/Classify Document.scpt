#@osa-lang:AppleScript
property pScriptName : "Classify Document"

set mailscriptProperties to load script (POSIX path of (path to home folder) & ".applescript/properties-mailscripts.scpt")
set docLib to (load script (pDocLibraryPath of mailscriptProperties))

tell application id "DNtp"
	set theSelection to selection
	tell docLib to classifyDocuments(theSelection)
end tell


