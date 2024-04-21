#@osa-lang:AppleScript
property pScriptName : "Open Messages"

set propertiesPath to POSIX path of (path to home folder)
set propertiesPath to propertiesPath & ".applescript/properties-mailscripts.scpt"
set mailscriptProperties to (load script propertiesPath)

set mailLibraryPath to (the pMailLibraryPath of mailscriptProperties)
set mailLib to (load script file mailLibraryPath)

-- alle Projekte/Areas ermitteln
tell mailLib to set theProjects to getProjectsAndAreaTags()

-- das zum Record Tag passende Actions File in neuem Fenster öffnen
tell application id "DNtp"
	set theRecord to first item of selected records
	set theTags to tags of theRecord
	repeat with theTag in theTags
		if theProjects contains theTag then
			set theActionRecord to first item of (lookup records with file "a_" & theTag & ".md")
			open window for record theActionRecord
		end if
	end repeat
end tell

