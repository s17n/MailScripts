#@osa-lang:AppleScript
property pScriptName : "Set Betrag"

set mailscriptsConfig to load script (POSIX path of (path to home folder) & ".mailscripts/config.scpt")
set docLib to (load script (pDocLibraryPath of mailscriptsConfig))

tell application id "DNtp"
	set theSelection to selection
	tell docLib to setBetrag(theSelection)
end tell


