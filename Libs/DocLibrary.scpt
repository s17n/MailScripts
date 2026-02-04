#@osa-lang:AppleScript
use AppleScript version "2.4"
use framework "Foundation"
use scripting additions

property pScriptName : "DocLibrary"

property logger : missing value
property baseLib : missing value

property pDays : missing value
property pMonths : missing value
property pYears : missing value
property pSenders : missing value
property pSubjects : missing value
property pContexts : missing value
property pSentTag : missing value
property pCcTag : missing value
property pScoreThreshold : missing value

property pWorkflowScriptsBaseFolder : missing value
property pSubjectsWithBetrag : missing value

property pCustomMetadataFieldSeparator : missing value

property monthsByName : missing value
property monthsByDigit : missing value

property pAssetsBaseFolder : missing value

property pCaptureContextConfig : missing value
property pFolderConfig : missing value

property pCameraCaptureSender : missing value
property pCameraCaptureSubject : missing value

property pAblageSender : missing value
property pAblageSubject : missing value

property pObjectSender : missing value
property pObjectSubject : missing value

property pIssueCount : 0

property pIsInitialized : false

on initialize(loggingContext)
	set logCtx to pScriptName & " > initialize"

	if pIsInitialized then

		tell logger to debug(logCtx, "Already initialized.")
	else

		-- Configuration
		set config to load script (POSIX path of (path to home folder) & ".mailscripts/config.scpt")
		set mailScriptsDir to pMailScriptsPath of config

		-- Logger & BaseLib
		set logger to load script (mailScriptsDir & "/Libs/Logger.scpt")
		tell logger to initialize()
		set baseLib to load script (mailScriptsDir & "/Libs/BaseLibrary.scpt")

		-- Properties
		set pWorkflowScriptsBaseFolder to mailScriptsDir & "/../WorkflowScripts/"
		set pCaptureContextConfig to pCaptureContextConfig of config
		set pFolderConfig to pFolderConfig of config
		set pCustomMetadataFieldSeparator to pCustomMetadataFieldSeparator of config
		set pScoreThreshold to pScoreThreshold of config
		set pSentTag to pSentTag of config
		set pCcTag to pCcTag of config

		set pAssetsBaseFolder to pAssetsBaseFolder of config
		set pCameraCaptureSender to pCameraCaptureSender of config
		set pCameraCaptureSubject to pCameraCaptureSubject of config
		set pAblageSender to pAblageSender of config
		set pAblageSubject to pAblageSubject of config
		set pObjectSender to pObjectSender of config
		set pObjectSubject to pObjectSubject of config

		my initializeMonthsDict()
		set pSubjectsWithBetrag to words of (pSubjectsWithBetrag of config)

		set pIsInitialized to true
		tell logger to debug(logCtx, "Initialization finished")
	end if
	return pScriptName & " > " & loggingContext
end initialize

-- Vorverarbeitung für Camera-Captures. Klassifizierung und Metadaten-Verarbeitung muss folgen.
-- Aufbau des Dateinamen:
--   [1]         [2]  [3]    [4]     [5]          [6]
--   [Timestamp]_DNtp_Assets_Capture_[KontextKey]_[Description, Base64-encoded].extension
-- Beispiel:
--   20260117-111824_DNtp_Assets_Capture_00_RGFzIGlzdCBub2NoIG1hbCBlaW4gQmVpc3BpZWx0ZXh0
--
on processCameraCapture(theRecords)
	set logCtx to my initialize("processCameraCapture")
	tell logger to debug(logCtx, "enter")

	tell application id "DNtp"
		repeat with theRecord in theRecords

			set theName to name of theRecord
			tell baseLib to set theContextKey to fifth item of text2List(theName, "_")
			tell baseLib to set theSubjectB64 to sixth item of text2List(theName, "_")
			tell logger to debug(logCtx, "theSubject: " & theSubject & ", theContextKey: " & theContextKey & ", theSubjectB64: " & theSubjectB64)

			tell baseLib to set theContext to configValue(pCaptureContextConfig, theContextKey)
			tell baseLib to set theSubjectText to decodeBase64(theSubjectB64)
			tell logger to debug(logCtx, "theContext: " & theContext & ", theSubjectText: " & theSubjectText)

			set tags of theRecord to {pCameraCaptureSubject, pCameraCaptureSender}
			if theContextKey is not "00" then set tags of theRecord to tags of theRecord & {(theContext as string)}
			add custom meta data pCustomMetadataFieldSeparator & theSubjectText for "Subject" to theRecord

		end repeat
	end tell

	tell logger to debug(logCtx, "exit")
end processCameraCapture

-- Vorverarbeitung für Ablage/Objekt-Records. Klassifizierung und Metadaten-Verarbeitung muss folgen.
-- Aufbau des Dateinamen:
--   [1]         [2]  [3]    [4]   [5]               [6]
--   [Timestamp]_DNtp_Assets_[F|I]_[Name-der-Ablage]_[Description, Base64-encoded].extension
--
on processInventoryRecords(theRecords)
	set logCtx to my initialize("processInventoryRecords")
	tell logger to debug(logCtx, "enter")

	tell application id "DNtp"
		repeat with theRecord in theRecords

			set theName to name of theRecord
			set theTags to missing value
			tell baseLib to set theAction to fourth item of text2List(theName, "_")
			tell baseLib to set theFolderName to fifth item of text2List(theName, "_")
			set theFolder to get record at "/02 Areas/Ablage/[alle]/" & theFolderName

			if theAction is equal to "F" then -- Folder (Ablage)
				set theTags to {pAblageSender, pAblageSubject}

				-- Set filename for latest.txt
				set filePath to pAssetsBaseFolder & "/10 Inventory/" & theFolderName
				set theReferenceURL to reference URL of theRecord
				do shell script "mkdir -p " & quoted form of filePath
				do shell script "printf " & quoted form of theReferenceURL & " > " & quoted form of filePath & "/latest.txt"

				set abgelegtIn to get custom meta data for "itemlink" from theFolder
				set theAbgelegtInFolder to get record with uuid my getUuidFromItemLink(abgelegtIn)

				add custom meta data pCustomMetadataFieldSeparator & theFolderName for "Subject" to theRecord
				add custom meta data reference URL of theAbgelegtInFolder for "itemlink" to theRecord
			else if theAction is equal to "I" then -- Item (Objekt)
				set theTags to {pObjectSender, pObjectSubject}

				tell baseLib to set theSubjectB64 to sixth item of text2List(theName, "_")
				tell baseLib to set theSubjectText to decodeBase64(theSubjectB64)

				add custom meta data pCustomMetadataFieldSeparator & theSubjectText for "Subject" to theRecord
				add custom meta data reference URL of theFolder for "itemlink" to theRecord
			end if
			set tags of theRecord to theTags
		end repeat
	end tell

	tell logger to debug(logCtx, "exit")
end processInventoryRecords

on processDocuments(theDatabase, theRecords)
	set logCtx to my initialize("processDocuments")
	tell logger to debug(logCtx, "enter")

	my classifyRecords(theDatabase, theRecords)
	my updateRecordsMetadata(theDatabase, theRecords)

	tell logger to debug(logCtx, "exit")
end processDocuments

on classifyRecords(theDatabase, theRecords)
	set logCtx to my initialize("classifyRecords")
	tell logger to debug(logCtx, "enter")

	tell application id "DNtp"
		my initializeTagLists(theDatabase)
		set {recordsSelected, recordsProcessed} to {0, 0}
		repeat with theRecord in theRecords
			set recordsSelected to recordsSelected + 1
			if type of theRecord is not group and type of theRecord is not smart group then
				set recordsProcessed to recordsProcessed + 1
				set tagFields to my fieldsFromTags(theRecord)
				if name of theDatabase contains "Assets" then
					my setDateTagsFromCreationDate(theRecord, tagFields)
				else if name of theDatabase contains "Dokumente" or ¬
					name of theDatabase contains "Belege" then
					my setDateTagsFromDocumentDate(theRecord, tagFields)
					my setNonDateTagsFromCompareRecord(theRecord, theDatabase, tagFields)
				end if
			end if
		end repeat
		tell logger to info(logCtx, "Records selected: " & recordsSelected & ", Records processed:  " & recordsProcessed)
	end tell

	tell logger to debug(logCtx, "exit")
end classifyRecords


on updateRecordsMetadata(theDatabase, theRecords)
	set logCtx to my initialize("updateRecordsMetadata")
	tell logger to debug(logCtx, "enter")

	tell application id "DNtp"
		set databaseName to name of theDatabase
		my initializeTagLists(theDatabase)
		set {recordsSelected, recordsProcessed} to {0, 0}
		repeat with theRecord in theRecords
			set recordsSelected to recordsSelected + 1
			if type of theRecord is group or type of theRecord is smart group then
				my setFinderComment(theRecord, null, null)
			else
				set tagFields to my fieldsFromTags(theRecord)

				-- erforderliche Tags: Year, Month, Day
				if (tagYear of tagFields is null) or (tagMonth of tagFields is null) or (tagDay of tagFields is null) then
					tell logger to info_r(theRecord, "Can't update metadata due to missing Date tag(s).")
				else
					set recordsProcessed to recordsProcessed + 1
					if databaseName contains "Assets" then
						-- set oldRecordName to name of theRecord
						my setNameForAsset(theRecord, tagFields)
						my setCustomMetaData(theRecord, tagFields)
						my setFinderComment(theRecord, "Asset", tagFields)
						-- my updateIndexFile(theRecord, tagFields, oldRecordName)

					else if databaseName contains "Dokumente" or databaseName contains "Belege" then
						my setNameForDocument(theRecord, tagFields)
						my setCustomMetaData(theRecord, tagFields)
						my setFinderComment(theRecord, "Dokument", tagFields)
					end if

				end if
			end if

		end repeat

		do shell script pWorkflowScriptsBaseFolder & "/update-monthly-index-files/update-monthly-index-files.sh " & ¬
			quoted form of pAssetsBaseFolder & "/06 Index"

		tell logger to info(logCtx, "Records selected: " & recordsSelected & ", Records processed:  " & recordsProcessed)
	end tell

	tell logger to debug(logCtx, "exit")
end updateRecordsMetadata



on fieldsFromTags(theRecord)
	set logCtx to my initialize("fieldsFromTags")
	tell logger to debug(logCtx, "enter")

	set fields to null
	set {theYear, theMonth, theDay, theSender, theSubject, theContext, theSentFlag, theCCFlag} ¬
		to {null, null, null, null, null, null, false, false}

	tell application id "DNtp"

		set theTags to tags of theRecord
		repeat with aTag in theTags
			if pDays contains aTag then set theDay to aTag
			if pMonths contains aTag then set theMonth to (monthsByName's objectForKey:aTag) as string
			if pYears contains aTag then set theYear to aTag
			if pSenders contains aTag then set theSender to aTag as string
			if pSubjects contains aTag then set theSubject to aTag
			if pContexts contains aTag then set theContext to aTag
			if (aTag as string) is equal to pSentTag then set theSentFlag to true
			if (aTag as string) is equal to pCcTag then set theCCFlag to true
		end repeat
		set fields to {tagYear:theYear, tagMonth:theMonth, tagDay:theDay, tagSender:theSender, tagSubject:theSubject, tagContext:theContext, tagSent:theSentFlag, tagCC:theCCFlag}
	end tell

	tell logger to debug(logCtx, "fieldsFromTags =>  tagYear: " & tagYear of fields & ", tagMonth: " & tagMonth of fields & ", tagDay: " & tagDay of fields & ", tagSender: " & tagSender of fields & ", tagSubject: " & tagSubject of fields & ", tagContext: " & tagContext of fields & ", tagSent: " & tagSent of fields & ", tagCC: " & tagCC of fields)
	tell logger to debug(logCtx, "fieldsFromTags: exit")

	return fields
end fieldsFromTags

on setNameForDocument(theRecord, f)
	set logCtx to my initialize("setNameForDocument")
	tell logger to debug(logCtx, "enter")

	set {theYear, theMonth, theDay, theSender, theSubject, theContext, theSent, theCC} ¬
		to {tagYear of f, tagMonth of f, tagDay of f, tagSender of f, tagSubject of f, tagContext of f, tagSent of f, tagCC of f}

	set theName to theYear & "-" & theMonth & "-" & theDay
	if theSent is true then set theName to theName & my tokenForFilename("AN")
	if theCC is true then set theName to theName & my tokenForFilename("CC")
	if theSender is not null then set theName to theName & my tokenForFilename(theSender)
	-- if theContext is not null then set theName to theName & my tokenForFilename(theContext)
	if theSubject is not null then set theName to theName & my tokenForFilename(theSubject)

	set currentName to name of theRecord
	if theName as string is not equal to currentName as string then
		tell logger to info_r(theRecord, "Name changed from: " & currentName & " to: " & theName)
		set name of theRecord to theName
	end if

	tell logger to debug(logCtx, "exit")
end setNameForDocument

on creationDateFromMetadata(theRecord, theSender)
	set logCtx to my initialize("creationDateFromMetadata")
	tell logger to debug(logCtx, "enter")

	set {creationDate, pdfCreateDate, pdfCreateDateString} to {missing value, missing value, missing value}
	tell application id "DNtp"

		-- if theSender contains "C1" then

		if kind of theRecord contains "PDF" then

			set pdfPath to path of theRecord
			set command to "/opt/homebrew/bin/exiftool -s -s -s -CreateDate -d '%Y-%m-%d %H:%M:%S' " & quoted form of pdfPath
			try
				set pdfCreateDateString to do shell script command
			on error errMsg number errNum
				error "ExifTool-Aufruf fehlgeschlagen (" & errNum & "): " & errMsg
			end try
			tell baseLib to set creationDate to isoStringToDate(pdfCreateDateString)

		end if

		-- end if
		if creationDate is missing value then set creationDate to creation date of theRecord
	end tell

	tell logger to debug(logCtx, "exit => creationDate: " & creationDate)
	return creationDate
end creationDateFromMetadata

on setNameForAsset(theRecord, f)
	set logCtx to my initialize("setNameForAsset")
	tell logger to debug(logCtx, "enter")

	set {logicalYear, logicalMonth, logicalDay, theSender} to {tagYear of f, tagMonth of f, tagDay of f, tagSender of f}
	set {theName, technicalDate, logicalDate} to {missing value, missing value, missing value}

	tell application id "DNtp"

		-- das technische Datum wird aus "Creation Date" ermittelt (Datum und Uhrzeit)
		tell baseLib to set technicalDate to format(my creationDateFromMetadata(theRecord, theSender))

		-- das logische Datum wird aus den Tags ermittelt (nur Datum)
		if logicalYear is not missing value and logicalMonth is not missing value and logicalDay is not missing value then
			set logicalDate to logicalYear & logicalMonth & logicalDay & "-0000"
		end if

		-- wenn technisches und logisches Datum identisch sind wird das technische Datum verwendet, sonst das logische
		set theName to technicalDate
		if logicalDate is not missing value then
			if not (rich texts 1 thru 8 of logicalDate = rich texts 1 thru 8 of technicalDate) then
				set theName to logicalDate
				tell logger to debug(logCtx, "Use logical date as name of the record: " & logicalDate)
			end if
		end if

		-- prüfen, ob ein Dateiname passend zum Namen möglich ist (das geht nur, wenn der Dateiname noch nicht existiert)
		-- falls bereits eine Datei mit dem Namen existiert wird die laufende Nummer um 1 erhöht
		set currentFilename to filename of theRecord
		tell baseLib to set theExtension to extentionOf(currentFilename)
		set {incrementalCounter, availableNumber} to {0, missing value}
		repeat while (availableNumber is missing value and incrementalCounter < 100)
			set theEvaluationFilename to theName & "-" & my twoDigit(incrementalCounter) & "." & theExtension
			tell the logger to debug(logCtx, "theEvaluationFilename: " & theEvaluationFilename)
			if not (exists record with file theEvaluationFilename) then
				set availableNumber to my twoDigit(incrementalCounter)
				tell logger to debug(logCtx, "No record found with this ending number - set availableNumber to: " & availableNumber)
			else
				if currentFilename = theEvaluationFilename then
					set availableNumber to my twoDigit(incrementalCounter)
					tell logger to debug(logCtx, "Record found, but it's the current record -  set availableNumber to: " & availableNumber)
				else
					set incrementalCounter to incrementalCounter + 1
				end if
			end if
		end repeat
		set theName to theName & "-" & availableNumber

		set name of theRecord to theName
	end tell

	tell logger to debug(logCtx, "exit")
end setNameForAsset

on updateIndexFile(theRecord, f, oldName)
	set logCtx to my initialize("updateIndexFile")
	tell logger to debug(logCtx, "enter")

	set {theYear, theMonth, theDay, theSubject, theContext} to {tagYear of f, tagMonth of f, tagDay of f, tagSubject of f, tagContext of f}
	set {oldYear, oldMonth} to {missing value, missing value}
	if length of oldName ≥ 6 then
		set {oldYear, oldMonth} to {text 1 thru 4 of oldName, text 5 thru 6 of oldName}
	end if

	tell application id "DNtp"
		set theUUID to uuid of theRecord

		set theFileame to filename of theRecord
		set theName to name of theRecord
		set theReferenceURL to reference URL of theRecord

		set theSender to get custom meta data for "Sender" from theRecord
		set theSubjectText to get custom meta data for "Subject" from theRecord

		set theSubjectValue to theSubjectText

		set dataviewKey to theSubject & ":: "
		set datum to theYear & "-" & theMonth & "-" & theDay
		if theYear as integer ≥ 2025 then set datum to "[[" & datum & "]]"
		set mdText to ""
		if theContext is not null and length of theContext > 0 then set mdText to mdText & "\\[" & theContext & "\\]"
		if theSubjectValue is not null and length of theSubjectValue > 0 then
			if length of mdText > 0 then set mdText to mdText & pCustomMetadataFieldSeparator & theSubjectValue
		end if
		set mdURL to theReferenceURL & "?openexternally=1"

		set revealText to "[⛭](" & theReferenceURL & "&reveal=1)"

		set theContent to "- " & dataviewKey & datum & ": [" & mdText & "](" & mdURL & ")" & " " & revealText

		set indexBaseDir to pAssetsBaseFolder & "/06 Index"
		set indexPath to indexBaseDir & "/" & theYear & "/" & theMonth
		set indexFile to indexPath & "/" & theFileame & ".md"
		set updateEvent to indexBaseDir & "/Updates/" & theYear & theMonth
		set updateEventRemove to indexBaseDir & "/Updates/" & oldYear & oldMonth

		tell logger to debug(logCtx, "theContent: " & theContent & ", indexFile: " & indexFile)

		-- alle Index File mit der UUID löschen (sonst bleiben bei Änderungen am Dateiname alte Dateien erhalten)
		do shell script "grep -rl --null -F " & theUUID & " " & quoted form of indexBaseDir & " | xargs -0 rm --"

		-- Verzeichnis und Index File erstellen
		do shell script "mkdir -p " & quoted form of indexPath
		do shell script "echo " & quoted form of theContent & " > " & quoted form of indexFile

		-- Update Events erstellen
		do shell script "touch " & quoted form of updateEvent
		do shell script "touch " & quoted form of updateEventRemove
	end tell

	tell logger to debug(logCtx, "exit")
end updateIndexFile

on setFinderComment(theRecord, theFormat, f)
	set logCtx to my initialize("setFinderComment")
	tell logger to debug(logCtx, "enter: theFormat: " & theFormat)

	tell application id "DNtp"

		set theSenderText to get custom meta data for "Sender" from theRecord
		set theSubjectText to get custom meta data for "Subject" from theRecord
		set theBetrag to get custom meta data for "Betrag" from theRecord
		set theItemLinkText to get custom meta data for "Itemlink" from theRecord

		if type of theRecord is group or type of theRecord is smart group then
			set finderComment to theSubjectText
		else
			set {theSenderTag, theSubjectTag, theContextTag} to {tagSender of f, tagSubject of f, tagContext of f}
			set finderComment to ""

			if theFormat = "Asset" then
				if theSubjectText is not missing value then
					if finderComment is not "" then set finderComment to finderComment & ", " & linefeed
					set finderComment to theSubjectText
				end if
				if theItemLinkText is not missing value then
					if finderComment is not "" then set finderComment to finderComment & ", " & linefeed
					set finderComment to finderComment & "Abgelegt in: " & my getNameByItemLink(theItemLinkText)
				end if
			else if theFormat = "Dokument" then
				if theSenderTag as string is not equal to theSenderText then
					if finderComment is not "" then set finderComment to finderComment & ", " & linefeed
					set finderComment to finderComment & theSenderText as string
				end if
				if theSubjectTag as string is not equal to theSubjectText then
					if finderComment is not "" then set finderComment to finderComment & ", " & linefeed
					set finderComment to finderComment & theSubjectText as string
				end if
				--				if theBetrag is not missing value then
				--					if finderComment is not "" then set finderComment to finderComment & ", " & linefeed
				--					set finderComment to finderComment & "Betrag: " & (theBetrag as string)
				--				end if
			end if
		end if
		set comment of theRecord to finderComment
	end tell

	tell logger to debug(logCtx, "exit")
end setFinderComment

on getNameByItemLink(theItemLink)
	set logCtx to my initialize("getNameByItemLink")
	tell logger to debug(logCtx, "enter")

	tell application id "DNtp"
		set theFolder to get record with uuid my getUuidFromItemLink(theItemLink)
		set theFolderName to name of theFolder
	end tell

	tell logger to debug(logCtx, "exit => " & theFolderName)
	return theFolderName
end getNameByItemLink

on getUuidFromItemLink(theItemLink)
	set logCtx to my initialize("getUuidFromItemLink")
	tell logger to debug(logCtx, "enter -> " & theItemLink)

	set thelink to theItemLink as string
	set theUUID to missing value
	tell application id "DNtp"
		set theUUID to rich texts 21 thru -1 of thelink
	end tell

	tell logger to debug(logCtx, "exit => " & theUUID)
	return theUUID
end getUuidFromItemLink

on valueFromCustomMetadataField(theRecord, theTag, theCustomMetadataField)
	set logCtx to my initialize("valueFromCustomMetadataField")
	tell logger to debug(logCtx, "enter: theCustomMetadataField: " & theCustomMetadataField)

	set newValue to missing value
	tell application id "DNtp"

		set currentValue to get custom meta data for theCustomMetadataField from theRecord

		-- Current Value parsen
		set {fieldList, firstValue, secondValue} to {missing value, missing value, missing value}
		if currentValue is not missing value then tell baseLib to set fieldList to text2List(currentValue, pCustomMetadataFieldSeparator)
		if fieldList is not missing value and length of fieldList > 0 then set firstValue to first item of fieldList
		if fieldList is not missing value and length of fieldList > 1 then set secondValue to second item of fieldList

		-- New Value erstellen
		set newValue to theTag
		if secondValue is not missing value then
			set newValue to newValue & pCustomMetadataFieldSeparator & secondValue
		end if
	end tell

	tell logger to debug(logCtx, "exit => " & newValue)
	return newValue
end valueFromCustomMetadataField

on setCustomMetaData(theRecord, f)
	set logCtx to my initialize("setCustomMetaData")
	tell logger to debug(logCtx, "enter")

	set {theYear, theMonth, theDay, theSenderTag, theSubjectTag, theContext, theSentFlag, theCCFlag} ¬
		to {tagYear of f, tagMonth of f, tagDay of f, tagSender of f, tagSubject of f, tagContext of f, tagSent of f, tagCC of f}

	tell application id "DNtp"

		-- DATE
		if theYear is not null and theMonth is not null and theDay is not null then

			set currentValue to get custom meta data for "Date" from theRecord
			if currentValue is not missing value then set currentValue to baseLib's date_to_iso(currentValue)
			set newValue to theYear & "-" & theMonth & "-" & theDay

			if newValue is not equal to currentValue then
				tell logger to info_r(theRecord, "Field 'Date' changed from: " & currentValue & " to: " & newValue)
				add custom meta data newValue for "Date" to theRecord
			end if
		end if

		-- SENDER
		if theSenderTag is not null then

			set currentValue to get custom meta data for "Sender" from theRecord
			set newValue to my valueFromCustomMetadataField(theRecord, theSenderTag, "Sender")
			if newValue as string is not equal to currentValue as string then
				tell logger to info_r(theRecord, "Field 'Sender' changed from: " & currentValue & " to: " & newValue)
				add custom meta data newValue for "Sender" to theRecord
			end if
		end if

		-- BETRAG
		if my isBetragRequired(theRecord, theSubjectTag) then
			set theDocumentAmount to document amount of theRecord
			if theDocumentAmount is not missing value then
				add custom meta data theDocumentAmount for "Betrag" to theRecord
			end if
		end if

		-- SUBJECT
		if theSubjectTag is not null then
			set newValue to my subjectText(theRecord, f, "")
			add custom meta data newValue for "Subject" to theRecord
		end if

	end tell
	tell logger to debug(logCtx, "exit")
end setCustomMetaData

on subjectText(theRecord, f, additionalText)
	set logCtx to my initialize("subjectText")
	tell logger to debug(logCtx, "enter")

	set {theYear, theMonth, theDay, theSenderTag, theSubjectTag, theContext, theSentFlag, theCCFlag} ¬
		to {tagYear of f, tagMonth of f, tagDay of f, tagSender of f, tagSubject of f, tagContext of f, tagSent of f, tagCC of f}

	set newValue to missing value
	tell application id "DNtp"
		set currentValue to get custom meta data for "Subject" from theRecord
		set betrag to get custom meta data for "Betrag" from theRecord

		-- Subject noch nicht gesetzt ist -> versuchen den Subject-Text initial aus den (PDF-)Metadaten auszulesen
		if currentValue is missing value then
			set newValue to theSubjectTag
			set subjectFromMetadata to my subjectFromMetadata(theRecord, theSubjectTag)
			if subjectFromMetadata is not missing value and subjectFromMetadata is not equal to "" then
				set newValue to newValue & pCustomMetadataFieldSeparator & subjectFromMetadata
			end if
		else
			set newValue to my valueFromCustomMetadataField(theRecord, theSubjectTag, "Subject")
		end if

		if additionalText is not missing value and length of additionalText > 0 then
			if newValue is not missing value and length of additionalText > 0 then
				if not my hasCustomText(newValue) then set newValue to newValue & ":"
				set newValue to newValue & " " & additionalText
			end if
		end if
		set addtitionalTags to ""
		if betrag is not missing value then set addtitionalTags to addtitionalTags & "[EUR " & betrag & "]"
		if theContext is not null then set addtitionalTags to addtitionalTags & "[" & theContext & "]"
		if theSentFlag is not null and theSentFlag is true then set addtitionalTags to addtitionalTags & "[Sent]"
		if theCCFlag is not null and theCCFlag is true then set addtitionalTags to addtitionalTags & "[CC]"
		if length of addtitionalTags > 0 then set newValue to newValue & " " & addtitionalTags

		if newValue as string is not equal to currentValue as string then
			tell logger to info_r(theRecord, "Field 'Subject' changed from: " & currentValue & " to: " & newValue)
		end if
	end tell

	tell logger to debug(logCtx, "exit => " & newValue)
	return newValue
end subjectText

on addSubjectText(additionalText)
	set logCtx to my initialize("addSubjectText")
	tell logger to debug(logCtx, "enter: additionalText: " & additionalText)

	tell application id "DNtp"

		my initializeTagLists(current database)
		set theRecord to content record

		tell baseLib to set additionalText to trim(additionalText)

		set f to my fieldsFromTags(theRecord)
		set newValue to my subjectText(theRecord, f, additionalText)
		add custom meta data newValue for "Subject" to theRecord

	end tell
	tell logger to debug(logCtx, "exit")
end addSubjectText

on hasCustomText(theString)
	set p to offset of ":" in theString
	if p > 0 then
		return true
	else
		return false
	end if
end hasCustomText

on isBetragRequired(theRecord, theSubjectTag)
	set logCtx to my initialize("isBetragRequired")
	tell logger to debug(logCtx, "enter")

	set theResult to false
	tell application id "DNtp"

		if theSubjectTag is in pSubjectsWithBetrag then
			set currentValue to get custom meta data for "Betrag" from theRecord
			if currentValue is missing value then set theResult to true
		end if

	end tell

	tell logger to debug(logCtx, "exit => " & theResult)
	return theResult
end isBetragRequired

on subjectFromMetadata(theRecord, theSender)
	set logCtx to my initialize("subjectFromMetadata")
	tell logger to debug(logCtx, "enter")

	set subjectFromPdfTitle to missing value
	tell application id "DNtp"

		-- if theSender contains "C1" then

		if kind of theRecord contains "PDF" then

			set pdfPath to path of theRecord
			set cmd to "/opt/homebrew/bin/exiftool -s -s -s -Title " & quoted form of pdfPath
			try
				set subjectFromPdfTitle to do shell script cmd
			on error errMsg number errNum
				error "ExifTool-Aufruf fehlgeschlagen (" & errNum & "): " & errMsg
			end try
		end if

		-- end if
	end tell

	tell logger to debug(logCtx, "exit => subjectFromPdfTitle: " & subjectFromPdfTitle)
	return subjectFromPdfTitle
end subjectFromMetadata

on addReferenceToDailyNote(theRecord, f)
	set logCtx to my initialize("addReferenceToDailyNote")
	tell logger to debug(logCtx, "enter")

	set {theYear, theMonth, theDay, theSender, theSubject} ¬
		to {tagYear of f, tagMonth of f, tagDay of f, tagSender of f, tagSubject of f}
	set theDate to theYear & "-" & theMonth & "-" & theDay
	set theDataviewKey to theSender
	if theSubject is not null then set theDataviewKey to theDataviewKey & "-" & the theSubject

	tell application id "DNtp"
		set theName to name of theRecord
		set theFilename to filename of theRecord
		set theType to type of theRecord
		set theReferenceURL to reference URL of theRecord
		set theURLParameter to ""
		set openExternally to "?openexternally=1"

		set theSender to get custom meta data for "Sender" from theRecord
		set theSubject to get custom meta data for "Subject" from theRecord

		set mdText to theSubject
		set mdURL to theReferenceURL
		if (theType as string) is not equal to "group" then set mdURL to mdURL & openExternally
		set mdLink to "[" & mdText & "](" & mdURL & ")"

		do shell script pWorkflowScriptsBaseFolder & "/add-reference-to-daily-note/add-reference-to-daily-note-2.sh " & ¬
			" --date=" & theDate & ¬
			" --entry=\"" & mdLink & "\"" & ¬
			" --dvKey=" & theDataviewKey
	end tell

	tell logger to debug(logCtx, "exit")
end addReferenceToDailyNote

on archiveRecords(theRecords)
	set logCtx to my initialize("archiveRecords")
	tell logger to debug(logCtx, "enter")

	tell application id "DNtp"
		try
			set defaultAblage to missing value
			set configRecords to lookup records with file "Default-Ablage.txt"
			repeat with theRecord in (configRecords)
				set defaultAblage to plain text of theRecord
			end repeat

			repeat with theRecord in theRecords

				set creationDate to get custom meta data for "Date" from theRecord
				if creationDate is missing value then
					display dialog "Can't archive record - custom meta data 'Date' not set"
				else

					set ablage to get custom meta data for "itemlink" from theRecord
					if ablage is missing value and defaultAblage is not missing value then ¬
						add custom meta data defaultAblage for "itemlink" to theRecord

					tell baseLib to set creationDateAsString to format(creationDate)
					set theYear to rich texts 1 thru 4 of creationDateAsString
					set theMonth to rich texts 5 thru 6 of creationDateAsString

					set archiveFolder to "/05 Files"
					set theYearAsInteger to theYear as integer
					if theYearAsInteger ≥ 1990 and theYearAsInteger ≤ 1999 then
						set archiveFolder to archiveFolder & "/1990-1999"
					else if theYearAsInteger ≥ 2000 and theYearAsInteger ≤ 2009 then
						set archiveFolder to archiveFolder & "/2000-2009"
					else if theYearAsInteger ≥ 2010 and theYearAsInteger ≤ 2019 then
						set archiveFolder to archiveFolder & "/2010-2019"
					end if
					set archiveFolder to archiveFolder & "/" & theYear & "/" & theMonth
					set theArchive to create location archiveFolder

					set locking of theRecord to true
					set theLocationGroup to location group of theRecord
					move record theRecord from location group of theRecord to theArchive
					tell logger to info_r(theRecord, "Record archived from: ../" & name of theLocationGroup & " to: " & archiveFolder)

				end if
			end repeat
		on error error_message number error_number
			if error_number is not -128 then display alert "Devonthink" message error_message as warning
		end try

	end tell
	tell logger to debug(logCtx, "exit")
end archiveRecords

on tokenForFilename(theTagValue)
	return ("_" & theTagValue as string)
end tokenForFilename

on setDateTagsFromDocumentDate(theRecord, f)
	set logCtx to my initialize("setDateTagsFromDocumentDate")
	tell logger to debug(logCtx, "enter")

	set {theYear, theMonth, theDay} ¬
		to {tagYear of f, tagMonth of f, tagDay of f}

	if theYear is not null then tell logger to debug(logCtx, "Nothing to do for Year - tag already set to: " & theYear)
	if theMonth is not null then tell logger to debug(logCtx, "Nothing to do for Month - tag already set to: " & theMonth)
	if theDay is not null then tell logger to debug(logCtx, "Nothing to do for Day - tag already set to: " & theDay)

	tell application id "DNtp"
		set theDocumentDate to missing value
		try
			set theDocumentDate to document date of theRecord
			if theDocumentDate is missing value then
				set theDocumentDate to creation date of theRecord
			end if
		on error number -2753
			tell logger to info(logCtx, "No 'document date' found, 'creation date' will be used instead.")
			set theDocumentDate to creation date of theRecord
		end try
		tell baseLib to set theDocumentDateAsString to date_to_iso(theDocumentDate)
		tell logger to debug(logCtx, "theDocumentDateAsString: " & theDocumentDateAsString)
		if theYear is null then
			set theYear to (characters 1 thru 4 of theDocumentDateAsString) as string
			set tags of theRecord to tags of theRecord & theYear
		end if
		if theMonth is null then
			set theMonth to (characters 6 thru 7 of theDocumentDateAsString) as string
			set theMonthAsString to (monthsByDigit's objectForKey:theMonth) as string
			set tags of theRecord to tags of theRecord & theMonthAsString
		end if
		if theDay is null then
			set theDay to (characters 9 thru 10 of theDocumentDateAsString) as string
			set tags of theRecord to tags of theRecord & theDay
		end if
	end tell

	tell logger to debug(logCtx, "exit")
end setDateTagsFromDocumentDate


on setDateTagsFromCreationDate(theRecord, f)
	set logCtx to my initialize("setDateTagsFromCreationDate")
	tell logger to debug(logCtx, "enter")

	set {theYear, theMonth, theDay, theSender} ¬
		to {tagYear of f, tagMonth of f, tagDay of f, tagSender of f}

	if theYear is not null or theMonth is not null or theDay is not null then
		tell logger to debug(logCtx, "Nothing to do, date already set.")
	else
		tell application id "DNtp"

			set recordName to name of theRecord
			set creationDate to my creationDateFromMetadata(theRecord, theSender)
			set theDay to my twoDigit(day of creationDate)
			set theMonth to my twoDigit(month of creationDate as integer)
			set theYear to year of creationDate as rich text

			set theMonthAsSting to (monthsByDigit's objectForKey:theMonth) as rich text
			set tags of theRecord to tags of theRecord & {theDay, theMonthAsSting, theYear}
		end tell
	end if

	tell logger to debug(logCtx, "exit")
end setDateTagsFromCreationDate

on twoDigit(d)
	return text -2 thru -1 of ("00" & d)
end twoDigit

on setNonDateTagsFromCompareRecord(theRecord, theDatabase, f)
	set logCtx to my initialize("setNonDateTagsFromCompareRecord")
	tell logger to debug(logCtx, "enter")

	set {theExistingSender, theExistingSubject, theExistingContext} ¬
		to {tagSender of f, tagSubject of f, tagContext of f}

	if theExistingSender is not null then tell logger to debug(logCtx, "Nothing to do for Sender - tag already set to: " & theExistingSender)
	if theExistingSubject is not null then tell logger to debug(logCtx, "Nothing to do for Subject - tag already set to: " & theExistingSubject)
	if theExistingContext is not null then tell logger to debug(logCtx, "Nothing to do for Context - tag already set to: " & theExistingContext)

	tell application id "DNtp"

		set theComparedRecords to compare record theRecord to theDatabase
		repeat with aCompareRecord in theComparedRecords

			if location of aCompareRecord starts with "/05" and (uuid of theRecord is not equal to uuid of aCompareRecord) then
				set theScore to score of aCompareRecord
				if theScore < pScoreThreshold then
					tell logger to debug_r(theRecord, "No tags copied - score of best compare record below threshold - score: " & (theScore as string))
				else
					set theCompareRecordTags to tags of aCompareRecord
					set {theSender, theSubject, theContext} to {null, null, null}
					repeat with aCompareRecordTag in theCompareRecordTags
						if pSenders contains aCompareRecordTag then set theSender to aCompareRecordTag
						if pSubjects contains aCompareRecordTag then set theSubject to aCompareRecordTag
						if pContexts contains aCompareRecordTag then set theContext to aCompareRecordTag
					end repeat
					if theExistingSender is null and theSender is not null then
						-- logger to debug(logCtx, "Sender Tag set to: ")
						set tags of theRecord to tags of theRecord & theSender
					end if
					if theExistingSubject is null and theSubject is not null then
						set tags of theRecord to tags of theRecord & theSubject
						--logger to debug(logCtx, "Subject Tags set to: " & name of theSubject)
					end if
					if theExistingContext is null and theContext is not null then
						set tags of theRecord to tags of theRecord & theContext
						--logger to debug(logCtx, "Context Tags set to: " & name of theContext)
					end if
				end if
				exit repeat -- only first record needed
			end if
		end repeat
	end tell

	tell logger to debug(logCtx, "exit")
end setNonDateTagsFromCompareRecord



on verifyTags(checkDate, checkSender, checkSubject, locationSuffix)
	set logCtx to my initialize("verifyTags")
	tell logger to debug(logCtx, "enter")

	tell application id "DNtp"
		set currentDatabase to current database
		my initializeTagLists(currentDatabase)

		set theLocation to "/05 Files"
		if locationSuffix is not null then set theLocation to theLocation & "/" & locationSuffix
		set theRecords to contents of currentDatabase whose location begins with theLocation
		tell logger to info(logCtx, "Verification started for Database: " & (name of currentDatabase as string) & " and Location: " & theLocation & ". " & ¬
			"Number of Records: " & (length of theRecords as string))

		set {issueRecords, issues, totalPages} to {0, 0, 0}
		repeat with theRecord in theRecords
			set {theYear, theMonth, theDay, theSender, theSubject, pIssueCount} to {null, null, null, null, null, 0}
			if type of theRecord is PDF document then set totalPages to totalPages + (page count of theRecord)

			set theTags to tags of theRecord
			set theSenderText to get custom meta data for "Sender" from theRecord
			set theSubjectText to get custom meta data for "Subject" from theRecord
			repeat with aTag in theTags
				if checkDate is true then
					if pDays contains aTag then
						if theDay is not null then my logIssue(theRecord, true, "Another tag of same type found for type: Day")
						set theDay to aTag
					end if
					if pMonths contains aTag then
						if theMonth is not null then my logIssue(theRecord, true, "Another tag of same type found for type: Month")
						set theMonth to aTag
					end if
					if pYears contains aTag then
						if theYear is not null then my logIssue(theRecord, true, "Another tag of same type found for type: Year")
						set theYear to aTag
					end if
				end if
				if checkSender is true then
					if pSenders contains aTag then
						if theSender is not null then my logIssue(theRecord, true, "Another tag of same type found for type: Sender")
						set theSender to aTag
					end if
				end if
				if checkSubject is true then
					if pSubjects contains aTag then
						if theSubject is not null then my logIssue(theRecord, true, "Another tag of same type found for type: Subject")
						set theSubject to aTag
					end if
				end if
			end repeat
			if checkDate is true then
				if theDay is null then my logIssue(theRecord, true, "Missing tag: Day")
				if theMonth is null then my logIssue(theRecord, true, "Missing tag: Month")
				if theYear is null then my logIssue(theRecord, true, "Missing tag: Year")
			end if
			if checkSender is true then
				if theSender is null then my logIssue(theRecord, true, "Tag missing: Sender")
				if theSenderText is not missing value and theSenderText as rich text does not start with theSender as rich text then
					my logIssue(theRecord, true, "Issue with Sender - Tag and Field doesn't match. Tag: " & theSender & ", Field: " & theSenderText)
				end if
			end if
			if checkSubject is true then
				if theSubject is null then logIssue(theRecord, true, "Tag missing: Subject")
				if theSubjectText is not missing value and length of theSubjectText > 0 then

					set oldTIDs to AppleScript's text item delimiters
					set AppleScript's text item delimiters to space
					set wordList to text items of theSubjectText
					set AppleScript's text item delimiters to oldTIDs

					if (count of wordList) > 1 then
						set firstWord to item 1 of wordList
						set secondWord to item 2 of wordList
						-- Bedingungen prüfen
						if firstWord does not end with ":" and secondWord does not start with "[" then
							my logIssue(theRecord, true, "Issue with Subject - Missing ':' character in SubjectText: " & theSubjectText)
						end if
					end if

				end if
			end if
			if pIssueCount > 0 then
				set issueRecords to issueRecords + 1
				set issues to issues + pIssueCount
			end if

		end repeat
		tell logger to info(logCtx, "Verify Tags finished - Records with issues: " & issueRecords & " Total Issues: " & issues & " Total Pages: " & totalPages)
	end tell
	tell logger to debug(logCtx, "exit")
end verifyTags

on logIssue(theRecord, setRecordLabel, theMessage)
	tell application id "DNtp"
		tell logger to info_r(theRecord, theMessage)
		set pIssueCount to pIssueCount + 1
		if setRecordLabel is true then
			set label of theRecord to 7
		end if
	end tell
end logIssue

on initializeTagLists(theDatabase)
	set logCtx to my initialize("initializeTagLists")
	tell logger to debug(logCtx, "enter")

	tell application id "DNtp"
		tell logger to debug(logCtx, "Initialize tag lists for database: " & name of theDatabase)
		set theTopLevelTagGroups to children of tags group of theDatabase --current database
		repeat with theTopLevelTagGroup in theTopLevelTagGroups
			set theChildren to get children of theTopLevelTagGroup
			if name of theTopLevelTagGroup starts with "01" then
				set pDays to my createTagList(theChildren, {})
			else if name of theTopLevelTagGroup starts with "02" then
				set pMonths to my createTagList(theChildren, {})
			else if name of theTopLevelTagGroup starts with "03" then
				set pYears to my createTagList(theChildren, {})
			else if name of theTopLevelTagGroup starts with "04" then
				set pSenders to my createTagList(theChildren, {})
			else if name of theTopLevelTagGroup starts with "05" then
				set pSubjects to my createTagList(theChildren, {})
			else if name of theTopLevelTagGroup starts with "06" then
				set pContexts to my createTagList(theChildren, {})
			end if
		end repeat
		tell logger to debug(logCtx, "Initialize tag lists finished for database: " & name of theDatabase & ", Days: " & length of pDays & ", Months: " & length of pMonths & ", Years: " & length of pYears & ", Senders: " & length of pSenders & ", Subjects: " & length of pSubjects & ", Contexts: " & length of pContexts)
	end tell
	tell logger to debug(logCtx, "exit")
end initializeTagLists

on createTagList(theTags, resultList)
	--set logCtx to my initialize("createTagList")

	tell application id "DNtp"
		repeat with tagListItem in theTags
			--set tagTypeOfTagListItem to tag type of tagListItem as string
			set theTagType to tag type of tagListItem
			if theTagType is ordinary tag then
				set end of resultList to name of tagListItem as string
			else
				set resultList to my createTagList(children of tagListItem, resultList)
			end if
		end repeat
		return resultList
	end tell

	return resultList
end createTagList

on initializeMonthsDict()

	set monthsByDigit to current application's NSMutableDictionary's dictionary()
	monthsByDigit's setObject:"Januar" forKey:"01"
	monthsByDigit's setObject:"Februar" forKey:"02"
	monthsByDigit's setObject:"März" forKey:"03"
	monthsByDigit's setObject:"April" forKey:"04"
	monthsByDigit's setObject:"Mai" forKey:"05"
	monthsByDigit's setObject:"Juni" forKey:"06"
	monthsByDigit's setObject:"Juli" forKey:"07"
	monthsByDigit's setObject:"August" forKey:"08"
	monthsByDigit's setObject:"September" forKey:"09"
	monthsByDigit's setObject:"Oktober" forKey:"10"
	monthsByDigit's setObject:"November" forKey:"11"
	monthsByDigit's setObject:"Dezember" forKey:"12"

	set monthsByName to my reverseDictionary(monthsByDigit)
end initializeMonthsDict

on reverseDictionary(origDict)
	set reversedDict to current application's NSMutableDictionary's dictionary()

	set allKeys to origDict's allKeys()
	repeat with aKey in allKeys
		set aValue to (origDict's objectForKey:aKey)
		(reversedDict's setObject:(aKey) forKey:(aValue))
	end repeat

	return reversedDict
end reverseDictionary

