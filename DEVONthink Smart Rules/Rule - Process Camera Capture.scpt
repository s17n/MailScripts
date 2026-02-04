#@osa-lang:AppleScript
property pScriptName : "Rule - Process Camera Capture"

on performSmartRule(theRecords)
	set mailscriptsConfig to load script (POSIX path of (path to home folder) & ".mailscripts/config.scpt")
	set docLib to (load script (pDocLibraryPath of mailscriptsConfig))

	tell application id "DNtp"
		set theDatabase to database of first item of theRecords
		tell docLib to processCameraCapture(theRecords)
		tell docLib to classifyRecords(theDatabase, theRecords)
		tell docLib to setNameAndUpdateMetadata(theDatabase, theRecords)
		synchronize database theDatabase
	end tell

end performSmartRule

tell application id "DNtp"
	set theSelection to selection
	my performSmartRule(theSelection)
end tell

