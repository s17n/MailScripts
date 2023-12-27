#@osa-lang:AppleScript
property pScriptName : "Mail Library"

-- Erstellt für jeden Record (.eml) einen Kontakt und fügt diesen einer Kontaktgruppe hinzu
-- ODER aktualiserte die Kontaktgruppe des Kontakts - falls der Kontakt bereits existiert.
-- Die Kontaktgruppe muss bereits existieren. Die Zuordnung der Kontaktgruppe ergibt sich aus der 'location group' des records in DEVONthink.
--
-- kMDItemSubject
-- kMDItemAuthorEmailAddresses
-- kMDItemRecipientEmailAddresses

-- kMDItemRecipients
-- kMDItemAuthors
on addOrUpdateContactsByGroup(theRecords, theCallerScript)
	tell application id "DNtp"

		repeat with theRecord in theRecords

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
						my dtLog(theCallerScript, "Kontaktgruppe nicht vorhanden.")
					else
						my dtLog(theCallerScript, ((error_number as string) & " - " & error_message))
					end if
				end try
				set personsWithSameEmail to (every person whose value of emails contains theAuthorEmail)
				if length of personsWithSameEmail = 0 then
					set thePerson to make new person with properties {last name:theAuthorName}
					make new email at end of emails of thePerson with properties {label:"default", value:theAuthorEmail}
					if theContactsGroup is not null then
						add thePerson to theContactsGroup
					end if
					save
					my dtLog(theCallerScript, "Contact added - Last name: " & theAuthorName & ", email: " & theAuthorEmail & ", group: " & theGroup)
				else if length of personsWithSameEmail = 1 then
					set thePerson to first item of personsWithSameEmail
					set oldGroups to groups of thePerson
					repeat with aOldGroup in oldGroups
						remove thePerson from aOldGroup
					end repeat
					if theContactsGroup is not null then
						add thePerson to theContactsGroup
					end if
					save
					my dtLog(theCallerScript, "Contact moved - Last name: " & theAuthorName & ", email: " & theAuthorEmail & ", group: " & theGroup)
				end if
			end tell

		end repeat
	end tell
end addOrUpdateContactsByGroup

-- Importiert Mail Messages nach DEVONthink u. verschiebt sie anschließend in das Mailbox-Archiv.
-- 	theMessages : Die zu importierenden Messages.
--	theDatabase : DEVONthink Datenbank, in die importiert wird.
--	theImportFolder : DEVONthink Ordner in den importiert wird.
-- 	theMailboxAccount : Mailbox Account
--	theArchiveFolder : Mailbox / Ordner in den die Messages nach dem Import verschoben werden sollen.
on addMessagesToDevonthink(theMessages, theDatabase, theImportFolder, theMailboxAccount, theArchiveFolder)
	set logActionName to pScriptName & " - Import Message"
	set pNoSubjectString to "(no subject)"
	tell application id "DNtp"
		if not (exists current database) then error "No database is in use."
		set theGroup to incoming group of database theDatabase
	end tell
	tell application "Mail"
		repeat with theMessage in theMessages
			try
				tell theMessage
					set {theDateReceived, theDateSent, theSender, theSubject, theSource, theReadFlag} ¬
						to {the date received, the date sent, the sender, the subject, the source, the read status}
				end tell
				set theName to my format(theDateSent)
				if theSubject is equal to "" then set theSubject to pNoSubjectString
				tell application id "DNtp"
					set theRecord to create record with {name:theName & ".eml", type:unknown, creation date:theDateSent, modification date:theDateReceived, URL:theSender, source:(theSource as string), unread:(not theReadFlag)} in theGroup
					perform smart rule trigger import event record theRecord
					set theImportFolder to create location theImportFolder in database theDatabase
					move record theRecord to theImportFolder
					set unread of theRecord to true
					log message logActionName info "Received at:  " & theDateSent & " from: " & theSender record theRecord
				end tell
				set mailbox of theMessage to mailbox theArchiveFolder of account theMailboxAccount
			on error error_message number error_number
				if error_number is not -128 then display alert "Devonthink" message error_message as warning
				log message error_message
			end try
		end repeat
	end tell
end addMessagesToDevonthink

-- Verschiebt die in DEVONthink selektierten Records in die Archiv-Verzeichnisstruktur.
-- Für eml basierend auf 'creation date'
-- Für alle anderen Typem basierend auf dem Custom Meta Data "Date"
--	theRecords : Die zu archivierenden Records.
on archiveRecords(theRecords)
	tell application id "DNtp"
		try
			repeat with aRecord in theRecords
				set theTags to the tags of aRecord
				--if the length of theTags is greater than 0 then
				set creationDate to null
				if the filename of aRecord ends with ".eml" then
					set creationDate to creation date of aRecord
				else
					set creationDate to get custom meta data for "Date" from aRecord
					if creationDate is missing value then display dialog "Custom Meta Data 'Date' ist null - Record kann nicht verschoben werden."
				end if
				set creationDateAsString to my format(creationDate)
				set theYear to texts 1 thru 4 of creationDateAsString
				set theMonth to texts 5 thru 6 of creationDateAsString

				set archiveFolder to ""
				set theYearAsInteger to theYear as integer
				if theYearAsInteger ≥ 2000 and theYearAsInteger ≤ 2009 then
					set archiveFolder to archiveFolder & "/2000-2009"
				else if theYearAsInteger ≥ 2010 and theYearAsInteger ≤ 2019 then
					set archiveFolder to archiveFolder & "/2010-2019"
				end if
				set archiveFolder to archiveFolder & "/" & theYear & "/" & theMonth
				set theGroup to create location archiveFolder
				move record aRecord to theGroup
				--end if
			end repeat
		on error error_message number error_number
			if error_number is not -128 then display alert "Devonthink" message error_message as warning
		end try

	end tell
end archiveRecords

on renameMessages(theRecords)
	tell application id "DNtp"
		repeat with aRecord in theRecords
			set creationDate to creation date of aRecord
			set theName to my format(creationDate)
			set name of aRecord to (theName as string)
		end repeat
	end tell
end renameMessages

-- https://gist.github.com/Glutexo/78c170e2e314f0eacc1a
on zero_pad(value, string_length)
	set string_zeroes to ""
	set digits_to_pad to string_length - (length of (value as string))
	if digits_to_pad > 0 then
		repeat digits_to_pad times
			set string_zeroes to string_zeroes & "0" as string
		end repeat
	end if
	set padded_value to string_zeroes & value as string
	return padded_value
end zero_pad

on format(theDate)
	set now to (theDate)

	set result to (year of now as integer) as string
	set result to result & ""
	set result to result & zero_pad(month of now as integer, 2)
	set result to result & ""
	set result to result & zero_pad(day of now as integer, 2)
	set result to result & "-"
	set result to result & zero_pad(hours of now as integer, 2)
	set result to result & ""
	set result to result & zero_pad(minutes of now as integer, 2)
	--set result to result & ":"
	--set result to result & zero_pad(seconds of now as integer, 2)

	return result
end format

on dtLog(theScriptName, theInfo)
	tell application id "DNtp"
		log message theScriptName info theInfo
	end tell
end dtLog
