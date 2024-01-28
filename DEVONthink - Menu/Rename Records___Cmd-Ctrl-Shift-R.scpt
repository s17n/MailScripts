#@osa-lang:AppleScript
property pScriptName : "Rename Records"

property pDocSciptsPropertiesPath : POSIX path of (path to home folder) & ".applescript/properties-docscripts.scpt"

on run

	set scptProp to (load script pDocSciptsPropertiesPath)
	set docLibraryPath to (the pDocLibraryPath of scptProp)
	set docLib to (load script file docLibraryPath)

	tell application id "DNtp"
		set theDatabase to get current database
		set theSelection to selection
		tell docLib
			initializeTagLists(theDatabase)
			repeat with aRecord in theSelection
				renameAndUpdateCustomMetadata(aRecord, pScriptName)
			end repeat
		end tell
	end tell

end run


