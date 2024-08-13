#@osa-lang:AppleScript
property pScriptName : "Mail Library"

property pScoreThreshold : 0.25

on deleteRemindersAndSetLabel(theRecords, theCallerScript)
	tell application id "DNtp"
		try
			repeat with theRecord in theRecords
				set reminder of theRecord to missing value
				set label of theRecord to 2
				my dtLog(theCallerScript, "Reminder deleted: " & name of theRecord)
			end repeat
		on error error_message number error_number
			if error_number is not -128 then display alert "Devonthink" message error_message as warning
		end try
	end tell
end deleteRemindersAndSetLabel

on openXTypeRecord(theXType, theCallerScript)
	-- das zum Record Tag passende Actions File in neuem Fenster öffnen
	tell application id "DNtp"
		set theRecord to content record of think window 1
		if theRecord is missing value then
			delay 0.5
			set search query of viewer windows to "tags:" & theXType & ";"
			tell application "System Events"
				keystroke "f" using {command down, option down}
				keystroke (key code 124)
			end tell
		else
			set theProject to my getProject(theRecord)
			set theLookupRecords to lookup records with tags {theProject, theXType}
			if length of theLookupRecords = 0 then
				log message pScriptName info "No record(s) found for project '" & theProject & "' and type '" & theXType & "'."
			else
				if length of theLookupRecords > 1 then
					log message pScriptName info "More then one records found for project '" & theProject & "' and type '" & theXType & "'."
				else
					open window for record the first item of theLookupRecords
				end if
			end if
		end if
	end tell
end openXTypeRecord

on getProject(theRecord)
	set theProjects to my getProjectsAndAreaTags()
	tell application id "DNtp" to set theTags to tags of theRecord
	repeat with theTag in theTags
		if theProjects contains theTag then
			return theTag
		end if
	end repeat
end getProject

-- Hintergrund: Tags werden zur Basis-Klassifizierung (1. Ebene) und zur PARA-Klassifizierung (2. Ebene) verwendet (01_Projects, 02_Areas...)
--              Die Kennzeichung der konkreten (PARA-)Projekte/Areas erfolgt auf der 3. Ebene.
-- Die Methode liefert alle konkreten PARA-Projekte/-Areas - d.h. alle Tags der 3. Ebene - als Liste.
on getProjectsAndAreaTags()
	tell application id "DNtp"
		set theProjects to {}
		set theL1TagGroups to children of tags group of current database -- Level 1 Tag Groups: ...
		repeat with theL1TagGroup in theL1TagGroups
			set theL2TagGroups to (get children of theL1TagGroup) -- Level 2 Tag Groups: 01_P, 02_A ...
			repeat with theL2TagGroup in theL2TagGroups
				if name of theL2TagGroup starts with "01" or name of theL2TagGroup starts with "02" then
					set theL3TagGroups to (get children of theL2TagGroup)
					repeat with theL3TagGroup in theL3TagGroups
						-- set theName to name of theL3TagGroup
						-- set theType to type of theL3TagGroup as string
						-- set theTagType to tag type of theL3TagGroup
						if tag type of theL3TagGroup is not ordinary tag then
							set theL4TagGroups to (get children of theL3TagGroup)
							-- my dtLog("DEBUG", "Name: " & theName & ", Type: " & theType & ", Tag Type: " & theTagType)
							repeat with theL4TagGroup in theL4TagGroups
								set end of theProjects to name of theL4TagGroup as string
								-- my dtLog("DEBUG", "Added to projects list: " & name of theL4TagGroup)
							end repeat
						else
							set end of theProjects to name of theL3TagGroup as string
						end if
					end repeat
				end if
			end repeat
		end repeat
		return theProjects
	end tell
end getProjectsAndAreaTags

on tagByCompareRecords(theRecord, theCallerScript)
	tell application id "DNtp"
		set theDatabase to current database
		set theTags to tags of theRecord
		set theComparedRecords to compare record theRecord to theDatabase
		repeat with aCompareRecord in theComparedRecords
			if location of aCompareRecord does not contain "Inbox" then
				if score of aCompareRecord ≥ pScoreThreshold then
					set theTagsFromCompareRecord to tags of aCompareRecord
					set tags of theRecord to theTagsFromCompareRecord
					exit repeat
				end if
			end if
		end repeat
	end tell
end tagByCompareRecords

on setGroupAsTag(theRecords, theCallerScript)
	tell application id "DNtp"
		repeat with theRecord in theRecords
			set theGroup to (name of location group of theRecord as string)
			set tags of theRecord to theGroup
		end repeat
	end tell
end setGroupAsTag

on extractAttachmentsFromEmail()
	tell application id "DNtp"
		set theSelection to the selection
		set tmpFolder to path to temporary items
		set tmpPath to POSIX path of tmpFolder

		repeat with theRecord in theSelection
			if (type of theRecord is unknown and path of theRecord ends with ".eml") or (type of the record is formatted note) then
				set theRTF to convert record theRecord to rich

				try
					if type of theRTF is rtfd then
						set thePath to path of theRTF
						set theGroup to parent 1 of theRecord

						tell application "Finder"
							set filelist to every file in ((POSIX file thePath) as alias)
							repeat with theFile in filelist
								set theAttachment to POSIX path of (theFile as string)

								if theAttachment ends with ".pdf" then
									-- Importing skips files inside the database package,
									-- therefore let's move them to a temporary folder first
									set theAttachment to move ((POSIX file theAttachment) as alias) to tmpFolder with replacing
									set theAttachment to POSIX path of (theAttachment as string)
									-- tell application id "DNtp" to import theAttachment to theGroup
									tell application id "DNtp"
										set theImportedRecord to import theAttachment to theGroup
										set theEmailCreationDate to get creation date of theRecord
										set theCmdDate to my formatDateWithDashes(theEmailCreationDate)
										add custom meta data theCmdDate for "Date" to theImportedRecord
										set name of theImportedRecord to theCmdDate
										set creation date of theImportedRecord to theCreationDateOfTheEmail
									end tell
								end if
							end repeat
						end tell
					end if
				end try

				delete record theRTF
			end if
		end repeat
	end tell
end extractAttachmentsFromEmail

-- Erstellt für jeden Record (.eml) einen Kontakt und fügt diesen einer Kontaktgruppe hinzu
-- ODER aktualiserte die Kontaktgruppe des Kontakts - falls der Kontakt bereits existiert.
-- Die Kontaktgruppe muss bereits existieren.
-- Die Zuordnung der Kontaktgruppe ergibt sich aus der 'location group' des records in DEVONthink.
-- Parameter:
--    theRecords: records
--    theCallerScript: the caller script (for logging)
--
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
				else
					my dtLog(theCallerScript, "Contact not moved - more than one person with same email addess: " & length of personsWithSameEmail as string)
				end if
			end tell

		end repeat
	end tell
end addOrUpdateContactsByGroup

-- Importiert Mail Messages nach DEVONthink u. verschiebt sie anschließend in das Mailbox-Archiv.
-- Parameter:
--    theMessages : Die zu importierenden Messages.
--    theDatabase : DEVONthink Datenbank, in die importiert wird.
--    theImportBaseFolder : DEVONthink Ordner in den importiert wird.
--    sortBySender : Kennzeichen, ob die Messages in DEVONthink-Gruppen - identisch zu Contact-Gruppe der Sender-Adresse - verschoben werden soll.
--    theMailboxAccount : Mailbox Account
--    theArchiveFolder : Mailbox / Ordner in den die Messages nach dem Import verschoben werden sollen.
--
on addMessagesToDevonthink(theMessages, theDatabase, theImportBaseFolder, sortBySender, theMailboxAccount, theArchiveFolder)
	set logActionName to pScriptName & " - Import Message"
	set pNoSubjectString to "(no subject)"
	set theImportSubFolder to ""
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
				set senderAddress to extract address from sender of theMessage
				set theName to my format(theDateSent)
				if theSubject is equal to "" then set theSubject to pNoSubjectString

				set theImportFolder to theImportBaseFolder
				if sortBySender then
					set theImportSubFolder to my getContactGroupName(senderAddress)
					if theImportSubFolder is not null then
						set theImportFolder to "Inbox/" & theImportSubFolder
					end if
				end if

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

on renameRecords(theSelection)
	tell application id "DNtp"
		repeat with theRecord in theSelection
			set creationDate to my getCreationDate(theRecord)
			set oldName to name of theRecord
			set creationDateAsString to my format(creationDate)
			set name of theRecord to creationDateAsString
			log message info "Record renamed (old name: " & oldName & ")" record theRecord
		end repeat
	end tell
end renameRecords

on getCreationDate(theRecord)
	tell application id "DNtp"
		set creationDate to creation date of theRecord
		--if type of theRecord is markdown then
		--	set creationDate to addition date of theRecord
		--end if
		return creationDate
	end tell
end getCreationDate

on getContactGroupName(theMailAddress)
	tell application "Contacts"
		activate
		set theGroupName to null
		set personsWithSameEmailAddress to (every person whose value of emails contains theMailAddress)
		if length of personsWithSameEmailAddress > 0 then
			set firstPerson to first item of personsWithSameEmailAddress
			set theGroups to groups of firstPerson
			repeat with theGroup in theGroups
				set aGroupName to name of theGroup as string
				if (aGroupName is not null) and (aGroupName is not "card") then set theGroupName to aGroupName
			end repeat
		end if
		close every window
		return theGroupName
	end tell
end getContactGroupName

on archiveRecords(theRecords, theCallerScript)
	tell application id "DNtp"
		try
			-- my dtLog(theCallerScript, "Records to archive: " & (length of theRecords as string))
			repeat with theRecord in theRecords

				set creationDate to my getCreationDate(theRecord)
				set recordIsEmail to (filename of theRecord ends with ".eml")

				set archiveFolder to ""
				if recordIsEmail then
					set archiveFolder to "/Archive"
				else
					set archiveFolder to "/Assets"
				end if

				set creationDateAsString to my format(creationDate)
				set theYear to texts 1 thru 4 of creationDateAsString
				set theMonth to texts 5 thru 6 of creationDateAsString
				set archiveFolder to archiveFolder & "/" & theYear & "/" & theMonth

				set theGroup to create location archiveFolder
				move record theRecord to theGroup
				log message info "Record archived to: " & archiveFolder record theRecord

			end repeat
		on error error_message number error_number
			if error_number is not -128 then display alert "Devonthink" message error_message as warning
		end try
	end tell
end archiveRecords

--- Todo
-- Verschiebt die selektierten Records ins Archiv - abgelegt nach Erstellungsdatum.
-- Das Erstellungsdatum ist für:
--    - Dokumente/Belege (d.h. i.d.R. Papier-Dokumente): Custom Meta Data 'Date'
-- 	  - alle anderen Datenbanken: das technisches Erstellungsdatum (record creation date)
-- Die Ablage erfolgt für:
--    - Dokumente/Belege-Datenbanken in: /YYYY/mm (mit Sonderlocke pro Decade)
--    - alle E-Mails (".eml") in:        /Archive/YYYY/mm
--    - alle weitere basierend auf dem Tag:
--	     - Asset: 						 /Archive/Assets (externer Folder)
--		 - Article, Link, Audio, Video:  /Archive/Capture/YYYY/mm
--		 - alles andere  		 	     /Archive/Journal/YYYY/mm
on archiveNonMailRecords(theRecords, theCallerScript)
	tell application id "DNtp"
		try
			my dtLog(theCallerScript, "Records to archive: " & (length of theRecords as string))
			set theDatabaseName to name of current database as string
			repeat with aRecord in theRecords

				-- Record Datum ermitteln
				set creationDate to null
				if theDatabaseName contains "Dokumente" or theDatabaseName contains "Belege" then
					set creationDate to get custom meta data for "Date" from aRecord
				else
					set creationDate to creation date of aRecord
				end if
				if creationDate is missing value then
					display dialog "'Date' not set. Can't archive record"
				else

					set creationDateAsString to my format(creationDate)
					set theYear to texts 1 thru 4 of creationDateAsString
					set theMonth to texts 5 thru 6 of creationDateAsString

					-- Ablageort ermitteln
					set archiveFolder to ""

					-- Dokumente & Belege sind (noch) anders
					if theDatabaseName contains "Dokumente" or theDatabaseName contains "Belege" then
						set theYearAsInteger to theYear as integer
						if theYearAsInteger ≥ 2000 and theYearAsInteger ≤ 2009 then
							set archiveFolder to "/2000-2009"
						else if theYearAsInteger ≥ 2010 and theYearAsInteger ≤ 2019 then
							set archiveFolder to "/2010-2019"
						end if
						set archiveFolder to archiveFolder & "/" & theYear & "/" & theMonth
					else
						set archiveFolder to "/Archive"
						set theTags to the tags of aRecord
						if theTags contains "asset" then
							set archiveFolder to archiveFolder & "/Assets"
						else if theTags contains "Article" or theTags contains "Link" or theTags contains "Video" or theTags contains "Audio" then
							set archiveFolder to archiveFolder & "/Capture"
						else
							set recordIsAnEmail to (filename of aRecord ends with ".eml")
							if not recordIsAnEmail then
								set archiveFolder to archiveFolder & "/Journal"
							end if
						end if
						set archiveFolder to archiveFolder & "/" & theYear & "/" & theMonth
					end if
					set theGroup to create location archiveFolder
					move record aRecord to theGroup
				end if
			end repeat
		on error error_message number error_number
			if error_number is not -128 then display alert "Devonthink" message error_message as warning
		end try
	end tell
end archiveNonMailRecords

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

on formatDateWithDashes(theDate)
	set now to (theDate)

	set result to (year of now as integer) as string
	set result to result & "-"
	set result to result & zero_pad(month of now as integer, 2)
	set result to result & "-"
	set result to result & zero_pad(day of now as integer, 2)

	return result
end formatDateWithDashes

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