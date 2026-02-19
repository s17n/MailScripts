#@osa-lang:AppleScript
use AppleScript version "2.4"
use framework "Foundation"
use scripting additions

property pScriptName : "DocLibrary"

property logger : missing value
property baseLib : missing value

property pIsInitialized : false
property pDimensionsDictionary : missing value
property pAmountFormatter : missing value
property pIssueCount : 0

--- DATABASE CONFIGURATION PROPERTIES: START

-- Dimensions
property pDimensionsHome : missing value
property pDateDimensions : missing value
property pCompareDimensions : missing value

property pClassificationDate : missing value

property pNameFormat : missing value

property pCustomMetadataFields : missing value
property pCustomMetadataDimensions : missing value
property pCustomMetadataTypes : missing value
property pCustomMetadataTemplates : missing value

property pCommentsFields : missing value

-- Verification
property pVerificationFields : missing value

--- Other
property pScoreThreshold : missing value
property pAmountCategories : missing value
property pCustomMetadataFieldSeparator : missing value

--- DATABASE CONFIGURATION PROPERTIES: END

property pDays : missing value
property pMonths : missing value
property pYears : missing value
property pSenders : missing value
property pSubjects : missing value
property pContexts : missing value
property pMarkers : missing value


property monthsByName : missing value
property monthsByDigit : missing value

property pAssetsBaseFolder : missing value
property pAblageLookupLocation : missing value
property pAblageLatestFolder : missing value

property pCaptureContextConfig : missing value
property pFolderConfig : missing value

property pCameraCaptureSender : missing value
property pCameraCaptureSubject : missing value

property pAblageSender : missing value
property pAblageSubject : missing value

property pObjectSender : missing value
property pObjectSubject : missing value


property pDatabaseConfigurationFolder : missing value
property pExiftool : missing value

on initialize(loggingContext)
	set logCtx to pScriptName & " > initialize"

	if not pIsInitialized then

		-- Configuration
		set config to load script (POSIX path of (path to home folder) & ".mailscripts/config.scpt")
		set logger to load script pLogger of config
		tell logger to initialize()
		set baseLib to load script (pBaseLibraryPath of config)

		set pDatabaseConfigurationFolder to pDatabaseConfigurationFolder of config
		set pExiftool to pExiftool of config

		set pIsInitialized to true
		tell logger to debug(logCtx, "Initialization finished")
	end if
	return pScriptName & " > " & loggingContext
end initialize

on initializeDatabaseConfiguration(theDatabase)
	set logCtx to my initialize("initializeDatabaseConfiguration")
	logger's trace(logCtx, "enter")

	tell application id "DNtp"
		set databaseName to name of theDatabase
	end tell

	set databaseConfigurationFilename to pDatabaseConfigurationFolder & "/Database-Configuration-" & databaseName & ".scpt"
	set databaseConfiguration to load script databaseConfigurationFilename
	set databaseContentType to pContentType of databaseConfiguration
	set defaultConfigurationName to pDefaultConfiguration of databaseConfiguration
	set defaultConfiguration to load script (pDatabaseConfigurationFolder & "/" & defaultConfigurationName)

	-- Dimensions
	set pDimensionsHome to pDimensionsHome of defaultConfiguration
	set pDateDimensions to pDateDimensions of defaultConfiguration
	set pCompareDimensions to pCompareDimensions of defaultConfiguration

	-- Date for auto-classificaton. Leave empty when auto-classification for date is not required.
	set pClassificationDate to pClassificationDate of defaultConfiguration

	-- Filename format. Leave empty when filename is not required.
	set pNameFormat to pNameFormat of defaultConfiguration

	set pCustomMetadataFields to pCustomMetadataFields of defaultConfiguration
	set pCustomMetadataDimensions to pCustomMetadataDimensions of defaultConfiguration
	set pCustomMetadataTypes to pCustomMetadataTypes of defaultConfiguration
	set pCustomMetadataTemplates to pCustomMetadataTemplates of defaultConfiguration

	set pCommentsFields to pCommentsFields of defaultConfiguration

	-- Verification
	set pVerificationFields to pVerificationFields of defaultConfiguration

	-- Other
	set pScoreThreshold to pScoreThreshold of defaultConfiguration
	set pAmountCategories to words of (pAmountCategories of defaultConfiguration)
	set pCustomMetadataFieldSeparator to pCustomMetadataFieldSeparator of defaultConfiguration

	set theMonths to pMonths of defaultConfiguration
	set monthsByDigit to current application's NSMutableDictionary's dictionary()
	set monthsByName to current application's NSMutableDictionary's dictionary()
	repeat with aMonth in theMonths
		set theNumber to first item of aMonth as string
		set theName to second item of aMonth as string
		logger's debug(logCtx, "theNumber: " & theNumber)
		(monthsByDigit's setObject:theName forKey:theNumber)
		(monthsByName's setObject:theNumber forKey:theName)
	end repeat

	-- Logger
	set pLogLevel to pLogLevel of defaultConfiguration
	logger's setLogLevel(pLogLevel)

	if databaseContentType is equal to "DOCUMENTS" then

	else if databaseContentType is equal to "BUSINESS-01" then

	else if databaseContentType is equal to "ASSETS" then

		set pAssetsBaseFolder to pAssetsBaseFolder of defaultConfiguration
		set pAblageLookupLocation to pAblageLookupLocation of defaultConfiguration
		set pAblageLatestFolder to pAblageLatestFolder of defaultConfiguration
		set pCaptureContextConfig to pCaptureContextConfig of defaultConfiguration
		set pCameraCaptureSender to pCameraCaptureSender of defaultConfiguration
		set pCameraCaptureSubject to pCameraCaptureSubject of defaultConfiguration
		set pAblageSender to pAblageSender of defaultConfiguration
		set pAblageSubject to pAblageSubject of defaultConfiguration
		set pObjectSender to pObjectSender of defaultConfiguration
		set pObjectSubject to pObjectSubject of defaultConfiguration

	end if

	set pAmountFormatter to current application's NSNumberFormatter's new()
	pAmountFormatter's setMinimumFractionDigits:2
	pAmountFormatter's setMaximumFractionDigits:2
	pAmountFormatter's setNumberStyle:(current application's NSNumberFormatterDecimalStyle)

	my initializeDimensions(theDatabase)

	logger's trace(logCtx, "exit")
end initializeDatabaseConfiguration

on initializeDimensions(theDatabase)
	set logCtx to my initialize("initializeDimensions")
	logger's trace(logCtx, "enter")

	set pDimensionsDictionary to current application's NSMutableDictionary's dictionary()
	tell application id "DNtp"

		set dimensionHome to get record at pDimensionsHome
		set theDimensions to children of dimensionHome
		repeat with aDimension in theDimensions

			set dimensionName to name of aDimension
			set categories to my createTagList(get children of aDimension, {})
			(pDimensionsDictionary's setObject:categories forKey:dimensionName)

			tell logger to debug(logCtx, "Dimension '" & dimensionName & "' initialized with " & length of categories & " categories.")
		end repeat

	end tell

	logger's trace(logCtx, "exit")
end initializeDimensions

on createTagList(theTags, resultList)
	tell application id "DNtp"
		repeat with tagListItem in theTags
			set theTagType to tag type of tagListItem
			if theTagType is ordinary tag then
				set resultList to my addToTagList(resultList, tagListItem)
			else
				set resultList to my createTagList(children of tagListItem, resultList)
			end if
		end repeat
		return resultList
	end tell
	return resultList
end createTagList

on addToTagList(theTagList, theRecord)
	set end of theTagList to name of theRecord as string
	return theTagList
end addToTagList


-- Vorverarbeitung für Camera-Captures. Klassifizierung und Metadaten-Verarbeitung muss folgen.
-- Aufbau des Dateinamen:
--   [1]         [2]  [3]    [4]     [5]          [6]
--   [Timestamp]_DNtp_Assets_Capture_[KontextKey]_[Description, Base64-encoded].extension
-- Beispiel:
--   20260117-111824_DNtp_Assets_Capture_00_RGFzIGlzdCBub2NoIG1hbCBlaW4gQmVpc3BpZWx0ZXh0
--
on processCameraCapture(theRecords)
	set logCtx to my initialize("processCameraCapture")
	logger's trace(logCtx, "enter")

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

	logger's trace(logCtx, "exit")
end processCameraCapture

-- Vorverarbeitung für Ablage/Objekt-Records. Klassifizierung und Metadaten-Verarbeitung muss folgen.
-- Aufbau des Dateinamen:
--   [1]         [2]  [3]    [4]   [5]               [6]
--   [Timestamp]_DNtp_Assets_[F|I]_[Name-der-Ablage]_[Description, Base64-encoded].extension
--
on processInventoryRecords(theRecords)
	set logCtx to my initialize("processInventoryRecords")
	logger's trace(logCtx, "enter")

	tell application id "DNtp"
		repeat with theRecord in theRecords

			set theName to name of theRecord
			set theTags to missing value
			tell baseLib to set theAction to fourth item of text2List(theName, "_")
			tell baseLib to set theFolderName to fifth item of text2List(theName, "_")
			set theFolder to my getFolderRecord(theFolderName)

			if theAction is equal to "F" then -- Folder (Ablage)
				set theTags to {pAblageSender, pAblageSubject}

				-- latest.txt
				set filePath to pAssetsBaseFolder & "/" & pAblageLatestFolder & "/" & theFolderName
				set theReferenceURL to reference URL of theRecord

				do shell script "mkdir -p " & quoted form of filePath
				do shell script "printf " & quoted form of theReferenceURL & " > " & quoted form of filePath & "/latest.txt"

				-- Subject
				add custom meta data pCustomMetadataFieldSeparator & theFolderName for "Subject" to theRecord

				-- Itemlink (optional, wenn gesetzt)
				set abgelegtInUuid to get custom meta data for "itemlink" from theFolder
				if abgelegtInUuid is not missing value then
					set abgelegtInFolder to get record with uuid abgelegtInUuid
					add custom meta data reference URL of abgelegtInFolder for "itemlink" to theRecord
				end if

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

	logger's trace(logCtx, "exit")
end processInventoryRecords

on getFolderRecord(theName)
	set logCtx to my initialize("getFolderRecord")
	logger's trace(logCtx, "enter => " & theName)

	tell application id "DNtp"

		set theRecord to get record at pAblageLookupLocation & theName
		if theRecord is missing value then error "Ablage '" & theName & "' not found at '" & pAblageLookupLocation & "'."

	end tell

	logger's trace(logCtx, "exit")
	return theRecord
end getFolderRecord

on processDocuments(theDatabase, theRecords)
	set logCtx to my initialize("processDocuments")
	logger's trace(logCtx, "enter")

	my classifyRecords(theDatabase, theRecords)
	my updateRecordsMetadata(theDatabase, theRecords)

	logger's trace(logCtx, "exit")
end processDocuments

on classifyRecords(theDatabase, theRecords)
	set logCtx to my initialize("classifyRecords")
	logger's trace(logCtx, "enter")

	tell application id "DNtp"

		my initializeDatabaseConfiguration(theDatabase)
		set {recordsSelected, recordsProcessed} to {0, 0}
		repeat with theRecord in theRecords
			set recordsSelected to recordsSelected + 1
			if type of theRecord is not group and type of theRecord is not smart group then
				set recordsProcessed to recordsProcessed + 1

				set tagFields to my fieldsFromTags(theRecord)

				-- Date, wenn ClassificationDate gesetzt
				if pClassificationDate is not missing value and pClassificationDate is not "" then
					my setDateTags(theRecord, tagFields, pClassificationDate)
				end if

				-- restliche Dimensionen
				repeat with aCompareDimension in pCompareDimensions
					my setTagFromCompareRecord(theRecord, theDatabase, tagFields, aCompareDimension)
				end repeat

			end if
		end repeat
		tell logger to info(logCtx, "Records selected: " & recordsSelected & ", Records processed:  " & recordsProcessed)
	end tell

	logger's trace(logCtx, "exit")
end classifyRecords


on updateRecordsMetadata(theDatabase, theRecords)
	set logCtx to my initialize("updateRecordsMetadata")
	logger's trace(logCtx, "enter")

	tell application id "DNtp"

		my initializeDatabaseConfiguration(theDatabase)
		set {recordsSelected, recordsProcessed} to {0, 0}
		repeat with theRecord in theRecords
			set recordsSelected to recordsSelected + 1
			if type of theRecord is group or type of theRecord is smart group then
				my setFinderComment(theRecord, null, null)
			else
				set tagFields to my fieldsFromTags(theRecord)

				if not my existDimension(tagFields, pDateDimensions) then
					tell logger to info_r(theRecord, "Can't update metadata due to missing Date tag(s).")
				else
					set recordsProcessed to recordsProcessed + 1

					-- Set Name
					if pNameFormat is not missing value and pNameFormat is not "" then
						my setName(theRecord, tagFields)
					end if

					-- Set Custom Metadata
					set customMetadataFieldIndex to 0
					repeat with aCustomMetadataField in pCustomMetadataFields
						set customMetadataFieldIndex to customMetadataFieldIndex + 1
						my setCustomMetadata(customMetadataFieldIndex, theRecord, tagFields)
					end repeat

					-- Set Comments
					if length of pCommentsFields > 0 then
						set comment of theRecord to ""
						repeat with aFinderCommentsField in pCommentsFields
							my setFinderComment(aFinderCommentsField, theRecord)
						end repeat
					end if
				end if
			end if
		end repeat

		tell logger to info(logCtx, "Records selected: " & recordsSelected & ", Records processed:  " & recordsProcessed)
	end tell

	logger's trace(logCtx, "exit")
end updateRecordsMetadata

on existDimension(theFields, theDimensions)
	set logCtx to my initialize("existDimension")
	logger's trace(logCtx, "enter")

	repeat with aDimension in theDimensions
		set theValue to (theFields's objectForKey:aDimension)
		if theValue is missing value then
			logger's trace(logCtx, "No value found for dimension '" & aDimensions & "'.")
			logger's trace(logCtx, "exit > false")
			return false
		end if
	end repeat

	logger's trace(logCtx, "exit > true")
	return true
end existDimension

on fieldsFromTags(theRecord)
	set logCtx to my initialize("fieldsFromTags")
	logger's trace(logCtx, "enter")

	set fields to current application's NSMutableDictionary's dictionary()
	tell application id "DNtp"

		set theTags to tags of theRecord
		repeat with aTag in theTags
			set theResult to my setField(aTag, fields)
			set hasFieldBeenSet to first item of theResult
			set fields to second item of theResult
			if not hasFieldBeenSet then
				my handleUncategorizedTag(aTag)
				set fields to second item of my setField(aTag, fields)
			end if
		end repeat
	end tell

	logger's trace(logCtx, "exit")
	return fields
end fieldsFromTags

on setField(theTag, theFields)
	set logCtx to my initialize("setField")
	logger's trace(logCtx, "entry")

	set hasFieldBeenSet to false
	tell application id "DNtp"

		set allDimensions to pDimensionsDictionary's allKeys()
		repeat with aDimension in allDimensions
			set categories to (pDimensionsDictionary's objectForKey:aDimension) as list
			if categories contains theTag then
				set setCurrentValue to (theFields's objectForKey:aDimension)
				if setCurrentValue is missing value then
					(theFields's setObject:theTag forKey:aDimension)
				else
					(theFields's setObject:{setCurrentValue, theTag} forKey:aDimension)
				end if
				set hasFieldBeenSet to true
			end if
		end repeat

	end tell

	logger's trace(logCtx, "exit")
	return {hasFieldBeenSet, theFields}
end setField

on handleUncategorizedTag(theTag)
	set logCtx to my initialize("handleUncategorizedTag")
	logger's trace(logCtx, "enter")

	tell application id "DNtp"

		set theUncategorizedRecord to get record at "/Tags/" & theTag

		set allKeysAsList to {}
		repeat with aKey in pDimensionsDictionary's allKeys()
			if aKey as string is not equal to theTag as string then
				set end of allKeysAsList to aKey as string
			end if
		end repeat

		set sortedList to (current application's NSArray's arrayWithArray:allKeysAsList)'s ¬
			sortedArrayUsingSelector:"localizedCaseInsensitiveCompare:"
		set sortedList to sortedList as list

		set theItem to choose from list sortedList ¬
			with title "Uncategorized Tag: " & theTag with prompt "The Tag '" & theTag & "' is not categorized yet. You can categorize it now to one of the following dimensions or leave it as is." default items "05 Subject" OK button name "Catagorize" cancel button name "Cancel" without multiple selections allowed

		-- Tag zu Categories der entsprechenden Dimension hinzufügen
		if theItem is not {} and theItem is not false then

			-- Dictionary
			set theCategories to (pDimensionsDictionary's objectForKey:theItem) as list
			set end of theCategories to name of theUncategorizedRecord as string
			(pDimensionsDictionary's setObject:theCategories forKey:theItem)

			-- Tag Group
			set theDimensionRecord to get record at pDimensionsHome & "/" & theItem
			move record theUncategorizedRecord to theDimensionRecord
		end if

	end tell
	logger's trace(logCtx, "exit")
end handleUncategorizedTag


on setName(theRecord, theFields)
	set logCtx to my initialize("setName")
	logger's trace(logCtx, "enter")


	set theName to pNameFormat

	set allDimensions to pDimensionsDictionary's allKeys()
	repeat with aDimension in allDimensions

		if (theName as string) contains ("[" & aDimension & "]" as string) then

			tell logger to debug(logCtx, "aDimension: " & aDimension)

			set theValue to (theFields's objectForKey:aDimension) as string

			-- Replace Month to double-digit
			set theReplacedValue to (monthsByName's objectForKey:theValue)
			if theReplacedValue is not missing value then set theValue to theReplacedValue as string

			if theValue is missing value then set theValue to ""
			set thePlaceholder to "[" & aDimension & "]"
			set theName to my replaceText(thePlaceholder, theValue, theName)
		end if
	end repeat

	set currentName to name of theRecord
	if theName as string is not equal to currentName as string then
		tell logger to info_r(theRecord, "Name changed from: " & currentName & " to: " & theName)
		set name of theRecord to theName
	end if

	logger's trace(logCtx, "exit")
end setName

on creationDateFromMetadata(theRecord)
	set logCtx to my initialize("creationDateFromMetadata")
	logger's trace(logCtx, "enter")

	set {creationDate, pdfCreateDate, pdfCreateDateString} to {missing value, missing value, missing value}
	tell application id "DNtp"

		if kind of theRecord contains "PDF" then

			set pdfPath to path of theRecord
			set command to pExiftool & " -s -s -s -CreateDate -d '%Y-%m-%d %H:%M:%S' " & quoted form of pdfPath
			try
				set pdfCreateDateString to do shell script command
			on error errMsg number errNum
				error "ExifTool-Aufruf fehlgeschlagen (" & errNum & "): " & errMsg
			end try
			tell baseLib to set creationDate to isoStringToDate(pdfCreateDateString)

		end if

		if creationDate is missing value then set creationDate to creation date of theRecord
	end tell

	logger's trace(logCtx, "exit => creationDate: " & creationDate)
	return creationDate
end creationDateFromMetadata

on setNameForAsset(theRecord, f)
	set logCtx to my initialize("setNameForAsset")
	logger's trace(logCtx, "enter")

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
			tell the logger to trace(logCtx, "theEvaluationFilename: " & theEvaluationFilename)
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

	logger's trace(logCtx, "exit")
end setNameForAsset

on setFinderComment(theField, theRecord)
	set logCtx to my initialize("setFinderComment")
	logger's trace(logCtx, "enter > " & theField)

	tell application id "DNtp"

		set theValue to get custom meta data for theField from theRecord

		set wordCount to count of words of theValue
		if wordCount > 1 then
			set finderComment to comment of theRecord
			if finderComment is not "" then
				set finderComment to finderComment & ", " & linefeed
			end if
			set finderComment to theValue
			set comment of theRecord to finderComment
		end if

	end tell

	logger's trace(logCtx, "exit")
end setFinderComment

on replaceText(findText, replaceText, sourceText)
	set logCtx to my initialize("replaceText")
	logger's trace(logCtx, "enter > " & findText & ", " & replaceText & ", " & sourceText)

	set oldTIDs to AppleScript's text item delimiters
	set AppleScript's text item delimiters to findText
	set textItems to text items of sourceText
	set AppleScript's text item delimiters to replaceText
	set newText to textItems as text
	set AppleScript's text item delimiters to oldTIDs

	logger's trace(logCtx, "exit > " & newText)
	return newText
end replaceText

on setCustomMetadata(theIndex, theRecord, theFields)
	set logCtx to my initialize("setCustomMetadata")
	logger's trace(logCtx, "enter > " & theIndex)

	set theField to item theIndex of pCustomMetadataFields
	set theDimension to item theIndex of pCustomMetadataDimensions
	set theType to item theIndex of pCustomMetadataTypes
	set theTemplate to item theIndex of pCustomMetadataTemplates

	tell application id "DNtp"
		set currentValue to get custom meta data for theField from theRecord
		set currentAmount to get custom meta data for first item of pCustomMetadataFields from theRecord
		if currentAmount is not missing value then set currentAmount to (pAmountFormatter's stringFromNumber:currentAmount) as rich text
	end tell

	set newValue to missing value
	if theType is equal to "DATE" then

		set currentValue to baseLib's date_to_iso(currentValue)

		set theYearDimension to first item of theDimension
		set theMonthDimension to second item of theDimension
		set theDayDimension to third item of theDimension

		set theYear to theFields's objectForKey:theYearDimension
		set theMonth to theFields's objectForKey:theMonthDimension
		set theMonth to monthsByName's objectForKey:theMonth
		set theDay to theFields's objectForKey:theDayDimension

		set newValue to (theYear as string) & "-" & (theMonth as string) & "-" & (theDay as string)

	else if theType is equal to "AMOUNT" then

		set newValue to currentValue
		if currentValue is missing value then

			set allValues to theFields's allValues()
			repeat with aValue in allValues
				if pAmountCategories contains aValue then
					tell application id "DNtp"
						set newValue to document amount of theRecord
					end tell
				end if
			end repeat
		end if

	else if theType is equal to "TEXT" then

		set theCategory to theFields's objectForKey:theDimension
		if theCategory is missing value then set theCategory to ""

		set theModifiedTemplate to theTemplate

		repeat with aDimension in pDimensionsDictionary's allKeys()
			if (theModifiedTemplate as string) contains ("[[" & aDimension & "]]" as string) then
				set theReplaceText to ""
				set theTag to (theFields's objectForKey:aDimension)
				if theTag is missing value then
				else if (theTag's isKindOfClass:(current application's NSString)) as boolean then
					set theReplaceText to theReplaceText & " [" & theTag & "]"
				else if (theTag's isKindOfClass:(current application's NSArray)) as boolean then
					repeat with aTag in theTag
						set theReplaceText to theReplaceText & " [" & aTag & "]"
					end repeat
				end if
				set thePlaceholder to "[[" & aDimension & "]]"
				set theModifiedTemplate to my replaceText(thePlaceholder as string, theReplaceText as string, theModifiedTemplate as string)
			end if
		end repeat

		repeat with aDimension in pDimensionsDictionary's allKeys()
			if (theModifiedTemplate as string) contains ("[" & aDimension & "]" as string) then
				set theReplaceText to (theFields's objectForKey:aDimension)
				if aDimension as string is equal to theDimension as string then
					set theReplaceText to theCategory
				else
					if theReplaceText is missing value then
						set theReplaceText to ""
					else
						set theReplaceText to " [" & theReplaceText & "]"
					end if
				end if
				set thePlaceholder to "[" & aDimension & "]"
				set theModifiedTemplate to my replaceText(thePlaceholder as string, theReplaceText as string, theModifiedTemplate as string)
			end if
		end repeat
		logger's trace(logCtx, "theModifiedTemplate " & theModifiedTemplate)

		-- Current Value parsen
		set {fieldList, secondValue} to {missing value, missing value}
		if currentValue is not missing value then tell baseLib to set fieldList to text2List(currentValue, pCustomMetadataFieldSeparator)
		if fieldList is not missing value and length of fieldList > 1 then set secondValue to second item of fieldList

		set customText to ""
		if secondValue is not missing value and secondValue is not "" then
			set customText to pCustomMetadataFieldSeparator & secondValue
		end if
		set theModifiedTemplate to my replaceText("{Text}", customText, theModifiedTemplate as string)

		set amountText to ""
		if currentAmount is not missing value then set amountText to " [EUR " & currentAmount & "]"
		set theModifiedTemplate to my replaceText("{Amount}", amountText, theModifiedTemplate as string)

		set newValue to theModifiedTemplate
	end if

	if newValue is not equal to currentValue then
		tell logger to info_r(theRecord, "Field '" & theField & "' changed from: " & currentValue & " to: " & newValue)
		tell application id "DNtp"
			add custom meta data newValue for theField to theRecord
		end tell
	end if

	logger's trace(logCtx, "exit")
end setCustomMetadata

on addSubjectText(additionalText)
	set logCtx to my initialize("addSubjectText")
	logger's trace(logCtx, "enter: additionalText: " & additionalText)

	tell application id "DNtp"

		my initializeTagLists(current database)
		set theRecord to content record

		tell baseLib to set additionalText to trim(additionalText)

		set f to my fieldsFromTags(theRecord)
		set newValue to my subjectText(theRecord, f, additionalText)
		add custom meta data newValue for "Subject" to theRecord

	end tell
	logger's trace(logCtx, "exit")
end addSubjectText


on subjectFromMetadata(theRecord, theSender)
	set logCtx to my initialize("subjectFromMetadata")
	logger's trace(logCtx, "enter")

	set subjectFromPdfTitle to missing value
	tell application id "DNtp"

		if kind of theRecord contains "PDF" then

			set pdfPath to path of theRecord
			set cmd to pExiftool & " -s -s -s -Title " & quoted form of pdfPath
			try
				set subjectFromPdfTitle to do shell script cmd
			on error errMsg number errNum
				error "ExifTool-Aufruf fehlgeschlagen (" & errNum & "): " & errMsg
			end try
		end if

	end tell

	logger's trace(logCtx, "exit => subjectFromPdfTitle: " & subjectFromPdfTitle)
	return subjectFromPdfTitle
end subjectFromMetadata

on archiveRecords(theRecords)
	set logCtx to my initialize("archiveRecords")
	logger's trace(logCtx, "enter")

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
	logger's trace(logCtx, "exit")
end archiveRecords

on setDateTags(theRecord, theFields, theClassificationDate)
	set logCtx to my initialize("setDateTags")
	logger's trace(logCtx, "enter")

	set theYear to theFields's objectForKey:(first item of pDateDimensions)
	set theMonth to theFields's objectForKey:(second item of pDateDimensions)
	set theDay to theFields's objectForKey:(third item of pDateDimensions)
	-- tell logger to trace(logCtx, "theYear: " & theYear & ", theMonth: " & theMonth & ", theDay: " & theDay)

	-- Date Tags will not be set if Year, Month or Day is already set
	if theYear is not missing value or theMonth is not missing value or theDay is not missing value then

		if theYear is missing value then tell logger to debug(logCtx, "Year already set to: " & theYear)
		if theMonth is missing value then tell logger to debug(logCtx, "Month already set to: " & theMonth)
		if theDay is missing value then tell logger to debug(logCtx, "Day already set to: " & theDay)
	else

		tell application id "DNtp"

			set theDate to missing value

			if theClassificationDate is equal to "DATE_DOCUMENT" then

				try
					set theDate to document date of theRecord
					if theDate is missing value then
						tell logger to info(logCtx, "No 'document date' found, 'creation date' will be used instead.")
						set theDate to creation date of theRecord
					end if
				on error number -2753
					tell logger to info(logCtx, "No 'document date' found, 'creation date' will be used instead.")
					set theDate to creation date of theRecord
				end try

			else if theClassificationDate is equal to "DATE_MODIFIED" then

				set recordName to name of theRecord
				set theDate to modification date of theRecord

			else if theClassificationDate is equal to "DATE_CREATED" then

				set recordName to name of theRecord
				set theDate to my creationDateFromMetadata(theRecord)

			else
				error "Unknown Classification Date Field Identifier: " & pClassificationDate
			end if

			-- tell baseLib to set theDateAsString to date_to_iso(theDate)
			tell logger to debug(logCtx, "theDate: " & theDate)

			set theDay to my twoDigit(day of theDate)
			set theMonth to my twoDigit(month of theDate as integer)
			set theYear to year of theDate as rich text

			set theMonthAsSting to (monthsByDigit's objectForKey:theMonth) as rich text
			set tags of theRecord to tags of theRecord & {theDay, theMonthAsSting, theYear}

		end tell

	end if

	logger's trace(logCtx, "exit")
end setDateTags

on twoDigit(d)
	return text -2 thru -1 of ("00" & d)
end twoDigit

on setTagFromCompareRecord(theRecord, theDatabase, theFields, theDimension)
	set logCtx to my initialize("setTagFromCompareRecord")
	logger's trace(logCtx, "enter")

	set theValue to theFields's objectForKey:theDimension
	if theValue is not missing value then
		tell logger to debug(logCtx, "Dimension '" & theDimension & "' already set to: " & theValue)

	else
		tell application id "DNtp"

			set theComparedRecords to compare record theRecord to theDatabase
			repeat with aCompareRecord in theComparedRecords

				if location of aCompareRecord starts with "/05" and (uuid of theRecord is not equal to uuid of aCompareRecord) then
					set theScore to score of aCompareRecord
					if theScore < pScoreThreshold then
						tell logger to debug_r(theRecord, "No tags copied - score of best compare record below threshold - score: " & (theScore as string))
					else
						set theCompareRecordTags to tags of aCompareRecord
						set theTag to missing value

						set categories to (pDimensionsDictionary's objectForKey:theDimension) as list

						repeat with aCompareRecordTag in theCompareRecordTags
							if categories contains aCompareRecordTag then set theTag to aCompareRecordTag
						end repeat
						if theTag is not missing value then
							tell logger to debug(logCtx, "theTag: " & theTag)
							set tags of theRecord to tags of theRecord & theTag
						end if
					end if
					exit repeat -- only first record needed
				end if
			end repeat
		end tell
	end if

	logger's trace(logCtx, "exit")
end setTagFromCompareRecord

on verifyTags(locationSuffix)
	set logCtx to my initialize("verifyTags")
	logger's trace(logCtx, "enter")

	tell application id "DNtp"
		set currentDatabase to current database
		my initializeDatabaseConfiguration(currentDatabase)

		set theLocation to "/05 Files"
		if locationSuffix is not null then set theLocation to theLocation & "/" & locationSuffix
		set theRecords to contents of currentDatabase whose location begins with theLocation
		tell logger to info(logCtx, "Verification started for Database: " & (name of currentDatabase as string) & ", Location: " & theLocation & ¬
			", Date: " & pVerifyDate & ", Sender: " & pVerifySender & ", Subject: " & pVerifySubject & ". Number of Records: " & (length of theRecords as string))

		set {issueRecords, issues, totalPages} to {0, 0, 0}
		repeat with theRecord in theRecords
			set {theYear, theMonth, theDay, theSender, theSubject, pIssueCount} to {null, null, null, null, null, 0}
			if type of theRecord is PDF document then set totalPages to totalPages + (page count of theRecord)

			set theTags to tags of theRecord
			set theSenderText to get custom meta data for "Sender" from theRecord
			set theSubjectText to get custom meta data for "Subject" from theRecord
			repeat with aTag in theTags
				if pVerifyDate then
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
				if pVerifySender then
					if pSenders contains aTag then
						if theSender is not null then my logIssue(theRecord, true, "Another tag of same type found for type: Sender")
						set theSender to aTag
					end if
				end if
				if pVerifySubject then
					if pSubjects contains aTag then
						if theSubject is not null then my logIssue(theRecord, true, "Another tag of same type found for type: Subject")
						set theSubject to aTag
					end if
				end if
			end repeat
			if pVerifyDate then
				if theDay is null then my logIssue(theRecord, true, "Missing tag: Day")
				if theMonth is null then my logIssue(theRecord, true, "Missing tag: Month")
				if theYear is null then my logIssue(theRecord, true, "Missing tag: Year")
			end if
			if pVerifySender is true then
				if theSender is null then my logIssue(theRecord, true, "Tag missing: Sender")
				if theSenderText is not missing value and theSenderText as rich text does not start with theSender as rich text then
					my logIssue(theRecord, true, "Issue with Sender - Tag and Field doesn't match. Tag: " & theSender & ", Field: " & theSenderText)
				end if
			end if
			if pVerifySubject is true then
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
		tell logger to info(logCtx, "Verification finished - Records with Issues: " & issueRecords & ", Total Issues: " & issues & ", Total Pages (PDF only): " & totalPages)
	end tell
	logger's trace(logCtx, "exit")
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
