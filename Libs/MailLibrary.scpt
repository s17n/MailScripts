#@osa-lang:AppleScript
property pScriptName : "MailLibrary"

property baseLib : missing value

property pScoreThreshold : 0.15

on initialize()
	set log_ctx to pScriptName & "." & "initialize"
	if baseLib is missing value then
		set mailscriptsConfig to load script (POSIX path of (path to home folder) & ".mailscripts/config.scpt")
		set baseLib to load script ((pBaseLibraryPath of mailscriptsConfig))
		tell baseLib to initialize()
	end if
end initialize

on classifyMessages(theRecords)
	my initialize()
	set log_ctx to pScriptName & "." & "classifyMessages"
	tell baseLib to debug(log_ctx, "enter")
	tell application id "DNtp"
		set theDatabase to current database
		repeat with theRecord in theRecords
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
		end repeat
	end tell
	tell baseLib to debug(log_ctx, "exit")
end classifyMessages

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
			if (type of theRecord is unknown and path of theRecord ends with ".eml") or (type of record is formatted note) then
				set theRTF to convert record theRecord to rich

				try
					if type of theRTF is RTFD then
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
										set theImportedRecord to import path theAttachment to theGroup
										set theEmailCreationDate to get creation date of theRecord
										tell baseLib to set theCmdDate to formatDateWithDashes(theEmailCreationDate)
										--set theCmdDate to my formatDateWithDashes(theEmailCreationDate)
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
-- Die Zuordnung der Kontaktgruppe ergibt sich aus der 'location group' des records.
-- Parameter:
--    theRecords: records
--    theCallerScript: the caller script (for logging)
--
on addOrUpdateContactsByGroup(theRecords, theCallerScript)
	my initialize()
	set log_ctx to pScriptName & "." & "addOrUpdateContactsByGroup"
	tell baseLib to debug(log_ctx, "enter")
	tell application id "DNtp"

		repeat with theRecord in theRecords

			tell theRecord
				set {theId, theName, theFilename, theMetadata} ¬
					to {the id, the name, the filename, the meta data}
				set {theAuthorEmail, theAuthorName} ¬
					to {the kMDItemAuthorEmailAddresses of theMetadata, the kMDItemAuthors of theMetadata}
			end tell

			set theGroupName to name of location group of theRecord as string

			tell application "Contacts"

				-- Prüfen, ob die Gruppe existiert, sonst anlegen
				if not (exists group theGroupName) then
					make new group with properties {name:theGroupName}
				end if

				set theGroup to group theGroupName

				-- Alle Kontakte ermitteln, die diese Email-Adresse besitzen
				set theContacts to (every person whose value of emails contains theAuthorEmail)
				set countContacts to length of theContacts
				if countContacts = 0 then
					set newPerson to make new person with properties {last name:theAuthorName}
					make new email at end of emails of newPerson with properties {label:"default", value:theAuthorEmail}
					add newPerson to theGroup
					save
					tell baseLib to info(log_ctx, "Neuen Kontakt in Gruppe \"" & theGroupName & "\" erstellt (Last name: " & theAuthorName & ", Email: " & theAuthorEmail & ").")
				else if countContacts = 1 then
					set thePerson to first item of theContacts
					set oldGroups to groups of thePerson
					repeat with aOldGroup in oldGroups
						remove thePerson from aOldGroup
						tell baseLib to info(log_ctx, "Kontakt aus Gruppe \"" & (name of aOldGroup as text) & "\" entfernt.")
					end repeat
					add thePerson to theGroup
					tell baseLib to info(log_ctx, "Kontakt zur Gruppe \"" & (name of theGroup as text) & "\" hinzugefügt.")
					save
				else
					-- mehr als ein Contact mit dieser Email-Adresse
					display dialog (countContacts as text) & " Kontakte mit der gleichen eMail-Adresse vorhanden."
				end if
			end tell


		end repeat
	end tell
	tell baseLib to debug(log_ctx, "exit")
end addOrUpdateContactsByGroup

-- Importiert Mail Messages nach DEVONthink u. verschiebt sie anschließend in das Mailbox-Archiv.
-- Parameter:
--    theMessages : Die zu importierenden Messages.
--    theDatabase : DEVONthink Datenbank, in die importiert wird.
--    theDefaultImportFolder : DEVONthink Ordner in den importiert wird.
--    sortByEngagementGroup : Kennzeichen, ob die Messages in DEVONthink-Gruppen - identisch zu Contact-Gruppe der Sender-Adresse - verschoben werden soll.
--    theMailboxAccount : Mailbox Account
--    theArchiveFolder : Mailbox / Ordner in den die Messages nach dem Import verschoben werden sollen.
--
on addMessagesToDevonthink(theMessages, theDatabase, theDefaultImportFolder, sortByEngagementGroup, theMailboxAccount, theArchiveFolder, theCallerScript)
	my initialize()
	set log_ctx to pScriptName & "." & "addMessagesToDevonthink"
	tell baseLib to debug(log_ctx, "enter")
	tell application "Mail"
		repeat with theMessage in theMessages
			try
				tell theMessage
					set {theDateReceived, theDateSent, theSender, theSubject, theSource, theReadFlag} ¬
						to {the date received, the date sent, the sender, the subject, the source, the read status}
				end tell
				set senderAddress to extract address from sender of theMessage

				tell baseLib to set theName to format(theDateSent)
				if theSubject is equal to "" then set theSubject to "(no subject)"

				set theImportFolder to null
				if sortByEngagementGroup then
					set theImportSubFolder to my getContactGroupName(senderAddress)
					if theImportSubFolder is not null then
						set theImportFolder to "Inbox/" & theImportSubFolder
					end if
				end if
				if theImportFolder is null then
					set theImportFolder to "Inbox/" & theDefaultImportFolder
				end if

				set theArchiveFolderYYYYMM to ""
				tell application id "DNtp"
					set theGroup to incoming group of database theDatabase
					set theRecord to create record with {name:theName & ".eml", type:unknown, creation date:theDateSent, modification date:theDateReceived, URL:theSender, source:(theSource as string), unread:(not theReadFlag)} in theGroup
					perform smart rule trigger import event record theRecord
					set theImportFolder to create location theImportFolder in database theDatabase
					move record theRecord to theImportFolder

					set unread of theRecord to true
					my setCustomAttributes(theRecord, senderAddress)
					log message info "New Message received at:  " & theDateSent & " from: " & theSender record theRecord

					set theYear to rich texts 1 thru 4 of theName
					set theMonth to rich texts 5 thru 6 of theName
					set theArchiveFolderYYYYMM to theArchiveFolder & "/" & theYear & "/" & theMonth
				end tell

				set mailbox of theMessage to mailbox theArchiveFolderYYYYMM of account theMailboxAccount

			on error error_message number error_number
				if error_number is not -128 then display alert "Devonthink" message error_message as warning
				log message error_message
			end try
		end repeat
	end tell
	tell baseLib to debug(log_ctx, "exit")
end addMessagesToDevonthink

on getSender(theMetadata)
	my initialize()
	tell baseLib to debug(pScriptName & ". getSender", "enter")

	set {theSender, theFirstname, theLastname, theNickname} to {"", null, null, null}
	set theMailAddress to kMDItemAuthorEmailAddresses of theMetadata

	-- get names from first Contact with same email address
	tell application "Contacts"
		set personsWithSameEmailAddress to (every person whose value of emails contains theMailAddress)
		if length of personsWithSameEmailAddress > 0 then
			set firstPerson to first item of personsWithSameEmailAddress
			set theFirstname to first name of firstPerson
			set theLastname to last name of firstPerson
			set theNickname to nickname of firstPerson
		end if
	end tell

	if not (theNickname is null or theNickname is missing value or theNickname is "") then
		set theSender to theNickname
	else
		if not (theFirstname is null or theFirstname is missing value or theFirstname is "") then
			set theSender to theFirstname
		end if
		if not (theLastname is null or theLastname is missing value or theLastname is "") then
			tell baseLib to debug(pScriptName & ". getSender", "----> 2")
			if length of theSender > 0 then
				set theSender to theSender & " "
			end if
			set theSender to theSender & theLastname
		end if

		if theSender is null or length of theSender = 0 then
			try
				set theSender to kMDItemAuthors of theMetadata
			on error error_message number error_number
				if error_number is -1728 then
					set theSender to "(null)"
				else
					display alert "Devonthink" message error_message as warning
				end if
			end try
		end if
	end if
	tell baseLib to debug(pScriptName & ". getSender", "exit")
	return theSender
end getSender

on getSubject(theMetadata)
	my initialize()
	tell baseLib to debug(pScriptName & ". getSubject", "enter")

	try
		set theSubject to kMDItemSubject of theMetadata
	on error error_message number error_number
		if error_number is -1728 then
			set theSubject to "(null)"
		else
			display alert "Devonthink" message error_message as warning
		end if
	end try

	tell baseLib to debug(pScriptName & ". getSubject", "exit")
	return theSubject
end getSubject

on setCustomAttributes(theSelection)
	my initialize()
	tell baseLib to debug(pScriptName & ".setCustomAttributes", "enter")

	tell application id "DNtp"
		repeat with theRecord in theSelection

			set {theSender, theSubject} to {null, null}
			set theMetadata to meta data of theRecord

			set theSender to my getSender(theMetadata)
			set theSubject to my getSubject(theMetadata)

			add custom meta data theSender for "Sender" to theRecord
			add custom meta data theSubject for "Subject" to theRecord

			tell baseLib to info_r(theRecord, "Sender: " & theSender & "; Subject: " & theSubject)

		end repeat
	end tell
	tell baseLib to debug(pScriptName & ".setCustomAttributes", "exit")
end setCustomAttributes

on renameRecords(theSelection)
	my setCustomAttributes(theSelection)
end renameRecords

on renameRecords2(theSelection)
	my initialize()
	set log_ctx to pScriptName & "." & "renameRecords"
	tell baseLib to debug(log_ctx, "enter")
	tell application id "DNtp"
		repeat with theRecord in theSelection

			set {theSender, theSubject} to {null, null}
			set theMetadata to meta data of theRecord
			try
				set theSender to kMDItemAuthors of theMetadata
			on error error_message number error_number
				if error_number is -1728 then
					set theSender to "(null)"
				else
					display alert "Devonthink" message error_message as warning
				end if
			end try
			try
				set theSubject to kMDItemSubject of theMetadata
			on error error_message number error_number
				if error_number is -1728 then
					set theSubject to "(null)"
				else
					display alert "Devonthink" message error_message as warning
				end if
			end try

			add custom meta data theSender for "Sender" to theRecord
			add custom meta data theSubject for "Subject" to theRecord

			tell baseLib to info(log_ctx, "Sender: " & theSender & ", Subject: " & theSubject)
			if (name of theRecord contains "copy") then
				set creation date of theRecord to addition date of theRecord
			end if
			set creationDate to creation date of theRecord
			tell baseLib to set creationDateAsString to format(creationDate)
			set name of theRecord to creationDateAsString
		end repeat
	end tell
	tell baseLib to debug(log_ctx, "exit")
end renameRecords2

on getContactGroupName(theMailAddress)
	my initialize()
	set log_ctx to pScriptName & "." & "getContactGroupName"
	tell baseLib to debug(log_ctx, "enter")
	set theGroupName to null
	tell application "Contacts"
		--activate
		set personsWithSameEmailAddress to (every person whose value of emails contains theMailAddress)
		if length of personsWithSameEmailAddress > 0 then
			set firstPerson to first item of personsWithSameEmailAddress
			set theGroups to groups of firstPerson
			repeat with theGroup in theGroups
				set aGroupName to name of theGroup as string
				if (aGroupName is not null) and (aGroupName is not "card") then
					set theGroupName to aGroupName
					tell baseLib to info(log_ctx, "Contact group found: " & theGroupName)
				end if
			end repeat
		end if
		--close every window
	end tell
	tell baseLib to debug(log_ctx, "exit")
	return theGroupName
end getContactGroupName

on archiveRecords(theRecords, theCallerScript)
	my initialize()
	set log_ctx to pScriptName & "." & "archiveRecords"
	tell baseLib to debug(log_ctx, "enter")
	tell application id "DNtp"
		try
			repeat with theRecord in theRecords

				set creationDate to creation date of theRecord
				set recordIsEmail to (filename of theRecord ends with ".eml")

				set archiveFolder to ""
				if recordIsEmail then
					set archiveFolder to "/05 Mails"
					set modification date of theRecord to current date
					set locking of theRecord to true
				else
					set archiveFolder to "/06 Notes"
				end if

				tell baseLib to set creationDateAsString to format(creationDate)

				set theYear to rich texts 1 thru 4 of creationDateAsString
				set theMonth to rich texts 5 thru 6 of creationDateAsString
				set archiveFolder to archiveFolder & "/" & theYear & "/" & theMonth

				set theGroup to create location archiveFolder

				set theLocation to location of theRecord
				set theLoctionAsRecord to get record at theLocation
				move record theRecord from theLoctionAsRecord to theGroup

				tell baseLib to info(log_ctx, "Record " & name of theRecord & " archived to: " & archiveFolder)
			end repeat
		on error error_message number error_number
			if error_number is not -128 then display alert "Devonthink" message error_message as warning
		end try
	end tell
	tell baseLib to debug(log_ctx, "exit")
end archiveRecords
