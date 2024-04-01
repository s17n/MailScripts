#@osa-lang:AppleScript
tell application id "DNtp"

	set theProjects to {}
	set theL1TagGroups to children of tags group of current database -- Level 1 Tag Groups: IBM, fstar
	repeat with theL1TagGroup in theL1TagGroups
		set theL2TagGroups to (get children of theL1TagGroup) -- Level 2 Tag Groups: 01_P, 02_A ...
		repeat with theL2TagGroup in theL2TagGroups
			if name of theL2TagGroup starts with "01" or name of theL2TagGroup starts with "02" then
				set theL3TagGroups to (get children of theL2TagGroup)
				repeat with theL3TagGroup in theL3TagGroups
					set end of theProjects to name of theL3TagGroup as string
				end repeat
			end if
		end repeat
	end repeat

	set theRecord to first item of selected records
	set theTags to tags of theRecord
	repeat with theTag in theTags
		if theProjects contains theTag then
			set theActionRecord to first item of (lookup records with file "a_" & theTag & ".md")
			open window for record theActionRecord
		end if
	end repeat

end tell

