#@osa-lang:AppleScript
property pScriptName : "Open Journal"

set propertiesPath to POSIX path of (path to home folder)
set propertiesPath to propertiesPath & ".applescript/properties-mailscripts.scpt"
set mailscriptProperties to (load script propertiesPath)

set mailLibraryPath to (the pMailLibraryPath of mailscriptProperties)
set mailLib to (load script file mailLibraryPath)

-- alle Projekte/Areas ermitteln
tell mailLib to set theProjects to getProjectsAndAreaTags()

-- den zum Record Tag passenden Journal Folder ("Journal/[project/area tag]") in neuem Fenster öffnen
tell application id "DNtp"
	--set theRecord to first item of selected records
	set theRecord to content record of think window 1
	set theTags to tags of theRecord
	repeat with theTag in theTags
		if theProjects contains theTag then
			set theJournalGroup to get record at "/Journal/" & theTag
			-- Work around bis alle Journal Groups umbenannt sind (eindeutiger Name & über WikiLinks referenzierbar -  "j_[projekt]")
			if theJournalGroup is missing value then
				set theJournalGroup to get record at "/Journal/j_" & theTag
			end if
			open window for record theJournalGroup
		end if
	end repeat
end tell
