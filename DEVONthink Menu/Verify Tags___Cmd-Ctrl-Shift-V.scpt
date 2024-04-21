#@osa-lang:AppleScript
property pScriptName : "Verify Tags"

property pDocSciptsPropertiesPath : POSIX path of (path to home folder) & ".applescript/properties-docscripts.scpt"

on run

	set scptProp to (load script pDocSciptsPropertiesPath)
	set docLibraryPath to (the pDocLibraryPath of scptProp)
	set docLib to (load script file docLibraryPath)

	tell application id "DNtp"
		--set theSelection to selection
		tell docLib to verifyTags(true, true, pScriptName)
	end tell

end run


