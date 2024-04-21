#@osa-lang:AppleScript
property pScriptName : "Archive Record"

property pMailPropertiesPath : POSIX path of (path to home folder) & ".applescript/properties-mailscripts.scpt"

on run

	set scptProp to (load script pMailPropertiesPath)
	set mailLibraryPath to (the pMailLibraryPath of scptProp)
	set archiveRoot to (the pDtArchiveRoot of scptProp)

	set mailLib to (load script file mailLibraryPath)
	tell application id "DNtp"
		set theSelection to selection
		tell mailLib to archiveRecords(archiveRoot, theSelection, pScriptName)
	end tell

end run


