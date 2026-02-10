#@osa-lang:AppleScript
property pScriptName : "MailLibrary"

property baseLib : missing value
property logger : missing value

property pDatabaseConfigurationFolder : missing value

property pPrimaryEmailDatabase : missing value

property pMailboxAccount : missing value
property pMailboxImportFolder : missing value
property pMailboxArchiveFolder : missing value
property pDevonthinkInboxFolder : missing value
property pDevonthinkSortBySender : missing value
property pDelayBeforeImport : 0

property pScoreThreshold : 0.15

property pIsInitialized : false

on initialize(loggingContext)
	set logCtx to pScriptName & " > initialize"

	if not pIsInitialized then

		set config to load script (POSIX path of (path to home folder) & ".mailscripts/config.scpt")
		set logger to load script pLogger of config
		tell logger to initialize()
		set baseLib to load script pBaseLibraryPath of config

		set pDatabaseConfigurationFolder to pDatabaseConfigurationFolder of config
		set pPrimaryEmailDatabase to pPrimaryEmailDatabase of config

		set pIsInitialized to true
		tell logger to debug(logCtx, "Initialization finished")
	end if
	return pScriptName & " > " & loggingContext
end initialize

on initializeDatabaseConfiguration(theRule)
	set logCtx to my initialize("initializeDatabaseConfiguration")
	tell logger to debug(logCtx, "enter")

	set databaseConfigurationFilename to pDatabaseConfigurationFolder & "/Database-Configuration-" & pPrimaryEmailDatabase & ".scpt"
	set databaseConfiguration to load script databaseConfigurationFilename
	tell logger to debug(logCtx, "databaseConfigurationFilename: " & databaseConfigurationFilename)

	set pMailboxAccount to pMailboxAccount of databaseConfiguration
	set pMailboxImportFolder to pMailboxImportFolder of databaseConfiguration
	set pMailboxArchiveFolder to pMailboxArchiveFolder of databaseConfiguration
	set pDevonthinkInboxFolder to pDtImportFolder_1 of databaseConfiguration
	set pDevonthinkSortBySender to pDevonthinkSortBySender of databaseConfiguration
	set pDelayBeforeImport to pDelayBeforeImport of databaseConfiguration

	-- LOGGER
	set pLogLevel to pLogLevel of databaseConfiguration
	logger's setLogLevel(pLogLevel)

	tell logger to debug(logCtx, "exit")
end initializeDatabaseConfiguration

on importMessages(theMessages)
	set logCtx to my initialize("importMessages")
	tell logger to debug(logCtx, "enter")

	my initializeDatabaseConfiguration("")

	tell application "Mail"

		delay pDelayBeforeImport
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
				if pDevonthinkSortBySender then
					set theImportSubFolder to my getContactGroupName(senderAddress)
					if theImportSubFolder is not null then
						set theImportFolder to "Inbox/" & theImportSubFolder
					end if
				end if
				if theImportFolder is null then
					set theImportFolder to "Inbox/" & pDevonthinkInboxFolder
				end if

				tell application id "DNtp"
					set theGroup to incoming group of database pPrimaryEmailDatabase
					set theRecord to create record with {name:theName & ".eml", type:unknown, creation date:theDateSent, modification date:theDateReceived, URL:theSender, source:(theSource as string), unread:(not theReadFlag)} in theGroup
					perform smart rule trigger import event record theRecord
					set theImportFolder to create location theImportFolder in database pPrimaryEmailDatabase
					move record theRecord to theImportFolder

					my setCustomAttributes(theRecord, senderAddress)

					set theSender to get custom meta data for "Sender" from theRecord
					tell baseLib to set theSenderEncoded to replaceText("/", "\\/", theSender)
					set unread of theRecord to not (exists record at "07 Miscellaneous/Configuration/Import as Read/" & theSenderEncoded)

					tell logger to info_r(theRecord, "New Message imported - received at:  " & theDateSent & " from: " & theSender)
				end tell

				-- Archiv-Folder zusammenbauen
				set theArchiveFolder to ""
				set theYear to rich text 1 thru 4 of theName
				set theMonth to rich text 5 thru 6 of theName
				if pMailboxAccount = "Google" then
					set theArchiveFolder to pMailboxArchiveFolder & "/" & theYear
				else
					set theArchiveFolder to pMailboxArchiveFolder
				end if

				tell logger to debug(logCtx, "theArchiveFolder: " & theArchiveFolder)

				-- Email als gelesen markieren und ins Archiv verschieben
				set read status of theMessage to true
				set mailbox of theMessage to mailbox theArchiveFolder of account pMailboxAccount

			on error error_message number error_number
				if error_number is not -128 then display alert "Devonthink" message error_message as warning
				tell logger to error (error_number & " - " & error_message)
			end try
		end repeat

		logger's info(logCtx, "Messages imported: " & length of theMessages)
		-- set theOldMessages to messages of mailbox mailboxImportFolder of account mailboxAccount
		-- if length of theOldMessages > 0 then
		--	tell logger to info(pScriptName, ((length of theMessages) as rich text) & " already received message(s) found for import.")
		--	tell mailLib to importMessages(theOldMessages, devonthinkDatabase, devonthinkInboxFolder, dtSortBySender, mailboxAccount, mailboxArchiveFolder, pScriptName)
		--end if

	end tell

	tell logger to debug(logCtx, "exit")
end importMessages

on getMessagesFromInbox()
	set logCtx to my initialize("getMessagesFromInbox")
	tell logger to debug(logCtx, "enter")

	my initializeDatabaseConfiguration("")

	tell application id "com.apple.mail" to set theMessages to messages of mailbox pMailboxImportFolder of account pMailboxAccount

	tell logger to debug(logCtx, "exit")
	return theMessages
end getMessagesFromInbox

on classifyMessages(theRecords)
	my initialize()
	tell logger to debug(pScriptName, "classifyMessages.enter")
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
	tell logger to debug(pScriptName, "classifyMessages.exit")
end classifyMessages

on createSmartGroup(theRecords)
	my initialize()
	tell logger to debug(pScriptName, "createSmartGroup: enter")
	tell application id "DNtp"
		repeat with theRecord in theRecords

			set theSender to get custom meta data for "Sender" from theRecord
			tell baseLib to set theSenderEncoded to replaceText("/", "\\/", theSender)

			set theMetadata to meta data of theRecord
			set theEmailAddress to kMDItemAuthorEmailAddresses of theMetadata
			tell logger to debug(pScriptName, "createSmartGroup: theSender: " & theSender & ", theEmailAddress: " & theEmailAddress)

			-- Erstelle Smartgroup für Sender
			if (exists record at "03 Resources/General/by Sender/" & theSenderEncoded) or ¬
				(exists record at "03 Resources/General/by Sender (FID)/" & theSenderEncoded) then
				tell logger to debug_r(theRecord, "Smartgroup already exists for Sender: " & theSender)
			else

				set theGroup to get record at "03 Resources/General/by Sender"
				set theSmartGroup to create record with {name:theSender, URL:theEmailAddress, record type:smart group, search predicates:"mdsender:" & theSender} in theGroup
				tell logger to info_r(theRecord, "Smartgroup created for Sender: " & theSender)
			end if

			-- Erstelle Smartgroup für Email-Adresse
			if (exists record at "03 Resources/General/by Email/" & theEmailAddress) then
				tell logger to debug_r(theRecord, "Smartgroup already exists for Email: " & theEmailAddress)
			else

				set theGroup to get record at "03 Resources/General/by Email"
				set theSmartGroup to create record with {name:theEmailAddress, URL:theEmailAddress, record type:smart group, search predicates:"kMDItemAuthorEmailAddresses:" & theEmailAddress} ¬
					in theGroup
				tell logger to info_r(theRecord, "Smartgroup created for Email: " & theEmailAddress)
			end if
		end repeat
	end tell
	tell logger to debug(pScriptName, "createSmartGroup: exit")
end createSmartGroup

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
	tell logger to debug(pScriptName, "addOrUpdateContactsByGroup: enter")
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
				tell logger to info(pScriptName, "Anzahl Kontakte mit Email-Adresse \"" & theAuthorEmail & "\": " & countContacts)
				if countContacts = 0 then
					set newPerson to make new person with properties {last name:theAuthorName}
					make new email at end of emails of newPerson with properties {label:"default", value:theAuthorEmail}
					add newPerson to theGroup
					save
					tell logger to info(pScriptName, "Neuen Kontakt in Gruppe \"" & theGroupName & "\" erstellt (Last name: " & theAuthorName & ", Email: " & theAuthorEmail & ").")
				else if countContacts = 1 then
					set thePerson to first item of theContacts
					set oldGroups to groups of thePerson
					repeat with aOldGroup in oldGroups
						remove thePerson from aOldGroup
						tell logger to info(pScriptName, "Kontakt \"" & theAuthorName & "\" aus Gruppe \"" & (name of aOldGroup as text) & "\" entfernt.")
					end repeat
					add thePerson to theGroup
					tell logger to info(pScriptName, "Kontakt \"" & theAuthorName & "\" zur Gruppe \"" & (name of theGroup as text) & "\" hinzugefügt.")
					save
				else
					-- mehr als ein Contact mit dieser Email-Adresse
					display dialog (countContacts as text) & " Kontakte mit der gleichen eMail-Adresse vorhanden."
				end if
			end tell


		end repeat
	end tell
	tell logger to debug(pScriptName, "addOrUpdateContactsByGroup: exit")
end addOrUpdateContactsByGroup


on getSender(theMetadata)
	set logCtx to my initialize("getSender")
	tell logger to debug(logCtx, "enter")

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
					set theSender to theMailAddress -- "(null)"
				else
					display alert "Devonthink" message error_message as warning
				end if
			end try
		end if
	end if
	tell logger to debug(logCtx, "exit")
	return theSender
end getSender

on getSubject(theMetadata)
	set logCtx to my initialize("getSubject")
	tell logger to debug(logCtx, "enter")

	try
		set theSubject to kMDItemSubject of theMetadata
	on error error_message number error_number
		if error_number is -1728 then
			set theSubject to "(null)"
		else
			display alert "Devonthink" message error_message as warning
		end if
	end try

	tell logger to debug(logCtx, "exit")
	return theSubject
end getSubject

on setCustomAttributes(theSelection)
	set logCtx to my initialize("setCustomAttributes")
	tell logger to debug(logCtx, "enter")

	tell application id "DNtp"
		repeat with theRecord in theSelection

			set {theSender, theSubject} to {null, null}
			set theMetadata to meta data of theRecord

			set theSender to my getSender(theMetadata)
			set theSubject to my getSubject(theMetadata)

			add custom meta data theSender for "Sender" to theRecord
			add custom meta data theSubject for "Subject" to theRecord

			tell logger to debug_r(theRecord, "Sender: " & theSender & "; Subject: " & theSubject)

		end repeat
	end tell
	tell logger to debug(logCtx, "exit")
end setCustomAttributes

on renameRecords(theSelection)
	my setCustomAttributes(theSelection)
end renameRecords

on getContactGroupName(theMailAddress)
	set logCtx to my initialize("getContactGroupName")
	tell logger to debug(logCtx, "enter")

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
					tell logger to debug(pScriptName, "Contact group found: " & theGroupName)
				end if
			end repeat
		end if
		--close every window
	end tell

	tell logger to debug(logCtx, "exit")
	return theGroupName
end getContactGroupName

on archiveRecords(theRecords, theCallerScript)
	my initialize()
	tell logger to debug(pScriptName, "archiveRecords: enter")
	tell application id "DNtp"
		try
			repeat with theRecord in theRecords

				set creationDate to creation date of theRecord
				set recordIsEmail to (filename of theRecord ends with ".eml")

				set archiveFolder to ""
				if recordIsEmail then
					set archiveFolder to "/05 Files"
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

				tell logger to info_r(theRecord, "Record archived")
			end repeat
		on error error_message number error_number
			if error_number is not -128 then display alert "Devonthink" message error_message as warning
		end try
	end tell
	tell logger to debug(pScriptName, "archiveRecords: exit")
end archiveRecords

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

