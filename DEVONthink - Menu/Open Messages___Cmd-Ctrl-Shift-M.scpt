#@osa-lang:AppleScript
property pScriptName : "Open Messages"

set propertiesPath to POSIX path of (path to home folder)
set propertiesPath to propertiesPath & ".applescript/properties-mailscripts.scpt"
set mailscriptProperties to (load script propertiesPath)

set mailLibraryPath to (the pMailLibraryPath of mailscriptProperties)
set mailLib to (load script file mailLibraryPath)

-- alle Projekte/Areas ermitteln
tell mailLib to set theProjects to getProjectsAndAreaTags()

-- die zum Record Tag passende Smart Group in neuem Fenster öffnen
tell application id "DNtp"
	set theRecord to first item of selected records
	set theTags to tags of theRecord
	repeat with theTag in theTags
		if theProjects contains theTag then
			set theMessages to first item of (search "m_" & theTag)
			open window for record theMessages
		end if
	end repeat
end tell

