#@osa-lang:AppleScript
-- Display infos for selected record in DEVONthink.

tell application id "DNtp"

	set theSelection to selection
	repeat with theRecord in theSelection
		try
			tell theRecord
				set {theId, theName, theFilename, theMetadata} ¬
					to {the id, the name, the filename, the meta data}
				set {theAuthorEmail, theAuthorName} ¬
					to {the kMDItemAuthorEmailAddresses of theMetadata, the kMDItemAuthors of theMetadata}
			end tell

			set theGroup to (name of location group of theRecord as string)
			tell application "Contacts"
				set theContactsGroup to null
				try
					set theContactsGroup to group theGroup
				on error error_message number error_number
					if error_number = -1728 then
						-- my dtLog(theCallerScript, "Kontaktgruppe nicht vorhanden.")
					else
						--my dtLog(theCallerScript, ((error_number as string) & " - " & error_message))
					end if
				end try
				set personsWithSameEmail to (every person whose value of emails contains theAuthorEmail)
				set firstPerson to first item of personsWithSameEmail
				set theGroups to groups of firstPerson
				set theGroupsAsString to ""
				repeat with theGroup in theGroups
					--					display dialog theGroup
					set theGroupsAsString to theGroupsAsString & (name of theGroup as string) & " "
				end repeat
			end tell

			display dialog "" & (return) ¬
				& "Record Data: " & (return) ¬
				& "      Id: " & theId & (return) ¬
				& "      Name: " & theName & (return) ¬
				& "      Filename: " & theFilename & (return) ¬
				& "      Meta data: " & (return) ¬
				& "            kMDItemAuthors: " & theAuthorName & (return) ¬
				& "            kMDItemAuthorEmailAddresses: " & theAuthorEmail & (return) ¬
				& "Contact Data: " & (return) ¬
				& "       Contacts: " & ((count of personsWithSameEmail) as string) & (return) ¬
				& "       Name (1st Contact): " & (name of firstPerson) & (return) ¬
				& "       Groups (1st Contact): " & theGroupsAsString ¬

		on error error_message number error_number
			if error_number is not -128 then display alert "Devonthink" message error_message as warning
		end try
	end repeat

end tell
