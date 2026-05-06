#@osa-lang:AppleScript
use AppleScript version "2.4"
use framework "Foundation"
use scripting additions

property pScriptName : "DocLibrary"

property logger : missing value
property baseLib : missing value
property mailLib : missing value

property pIsInitialized : false
property pContentType : missing value
property pDimensionsDictionary : missing value
property pDimensionsConstraintsDictionary : missing value
property pDimensionsCachePath : missing value
property pUseDimensionsFilesystemCache : false
property pAmountFormatter : missing value
property tagAliases : missing value
property monthsByName : missing value
property monthsByDigit : missing value
property pIssueCount : 0
property pSmartGroupConditionCustomMetadata : "CustomMetadata"
property pSmartGroupConditionLabel : "Label"
property pSmartGroupConditionTags : "Tags"
property pPerformanceTraceManagedByCaller : false

--- DATABASE CONFIGURATION PROPERTIES: START

property pDatabaseConfigurationFolder : missing value

property pDimensionsHome : missing value
property pDimensionsConstraints : missing value
property pDateDimensions : missing value
property pCompareDimensions : missing value
property pCompareDimensionsScoreThreshold : missing value

property pClassificationDate : missing value

property pNameTemplate : missing value

property pCustomMetadataFields : missing value
property pCustomMetadataDimensions : missing value
property pCustomMetadataTypes : missing value
property pCustomMetadataTemplates : missing value
property pCustomMetadataFieldSeparator : missing value

property pCommentsFields : missing value

property pAmountLookupCategories : missing value
property pFilesHome : missing value
property pTagAliases : missing value

--- DATABASE CONFIGURATION PROPERTIES: END

property pExiftool : missing value

-- Typisierung: DEVONthink-Typen aus /Applications/DEVONthink v4.2.app/Contents/Resources/DEVONthink.sdef

-- Adds supplemental text to a configured custom metadata field.
-- Parameters:
--    theCustomMetadataField:text target custom metadata field name.
--    theText:text supplemental text to apply.
-- Return: none (side effects only).
on addTextToCustomMetadata(theCustomMetadataField, theText)
	set logCtx to my initialize(" addTextToCustomMetadata")
	logger's trace(logCtx, "enter > theCustomMetadataField: " & theCustomMetadataField & ", theText: " & theText)

	tell application id "DNtp"

		set theRecord to missing value
		set selectedRecords to selection
		if selectedRecords is not {} then set theRecord to first item of selectedRecords
		if theRecord is missing value then set theRecord to content record
		if theRecord is missing value then error "No current record selected."

		set theDatabase to database of theRecord
		if theDatabase is missing value then error "No database found for current record."

		my initializeDatabaseConfiguration(theDatabase)
		set tagFields to my fieldsFromTags(theRecord, false)

		set theAction to "ADD"
		tell baseLib to set theTimmedText to trim(theText)

		-- Command-Key
		set cmdKeyStat to (((current application's NSEvent's modifierFlags()) div ¬
			(current application's NSCommandKeyMask as integer)) mod 2) > 0
		if cmdKeyStat then set theAction to "REPLACE"

		set customMetadataFieldIndex to 0
		repeat with aCustomMetadataField in pCustomMetadataFields
			set customMetadataFieldIndex to customMetadataFieldIndex + 1
			if aCustomMetadataField as string is equal to theCustomMetadataField as string then exit repeat
		end repeat
		logger's debug(logCtx, "customMetadataFieldIndex: " & customMetadataFieldIndex)

		my setCustomMetadata(customMetadataFieldIndex, theRecord, tagFields, theTimmedText, theAction)

	end tell
	logger's trace(logCtx, "exit")
end addTextToCustomMetadata

-- Archives records to a destination resolved from configured placeholders.
-- Parameters:
--    theRecords:list<DEVONthink record (class 'record' / DTrc)> records to process.
-- Return: none (side effects only).
on archiveRecords(theRecords)
	set logCtx to my initialize("archiveRecords")
	logger's trace(logCtx, "enter")

	tell application id "DNtp"

		set theDatabase to database of first item of theRecords

		my initializeDatabaseConfiguration(theDatabase)
		set allDimensions to pDimensionsDictionary's allKeys()

		repeat with theRecord in theRecords

			set tagFields to my fieldsFromTags(theRecord, true)

			-- Replace placeholder
			set theFilesHome to my replaceDimensionPlaceholders(allDimensions, tagFields, pFilesHome)
			set theFilesHome to my replaceFieldPlaceholder("{Decades}", tagFields, theFilesHome)
			if pClassificationDate is not missing value and pClassificationDate is not "" and pDateDimensions is {} then
				set theClassificationDate to my getClassificationDate(theRecord, pClassificationDate)
				set theFilesHome to my replaceDatePlaceholder(theClassificationDate, theFilesHome)
			end if

			if theFilesHome contains "[" or the theFilesHome contains "{" then
				error "Record can't be archived due to existing placeholders in destination group name: " & theFilesHome
			else
				my moveRecord(theRecord, theFilesHome)
				set locking of theRecord to true
			end if
		end repeat
	end tell
	logger's trace(logCtx, "exit")
end archiveRecords

-- Starts a caller-managed performance trace run.
-- Parameters:
--    theTraceName:text human-readable caller/run name.
-- Return: none (side effects only).
on beginPerformanceTrace(theTraceName)
	set logCtx to my initialize("beginPerformanceTrace")
	set pPerformanceTraceManagedByCaller to true
	logger's resetTraceMetrics()
	logger's debug(logCtx, "Started performance trace: " & theTraceName)
end beginPerformanceTrace

-- Builds a dimension-to-cardinality dictionary from configuration data.
-- Parameters:
--    theConstraints:list<list{text,integer}> configured dimension cardinality constraints.
-- Return: NSMutableDictionary<text,integer> computed result.
on buildDimensionsConstraintsDictionary(theConstraints)
	set logCtx to my initialize("buildDimensionsConstraintsDictionary")
	logger's trace(logCtx, "enter")
	set constraintsDictionary to current application's NSMutableDictionary's dictionary()
	repeat with aDimensionConstraint in theConstraints
		set theDimensionName to first item of aDimensionConstraint as string
		set theCardinality to second item of aDimensionConstraint as integer
		(constraintsDictionary's setObject:theCardinality forKey:theDimensionName)
	end repeat
	logger's trace(logCtx, "exit")
	return constraintsDictionary
end buildDimensionsConstraintsDictionary

-- Builds month lookup dictionaries for number-to-name and name-to-number mapping.
-- Parameters:
--    theMonths:list<list{text,text}> configured month mapping pairs.
-- Return: list{NSMutableDictionary<text,text>, NSMutableDictionary<text,text>} computed result.
on buildMonthDictionaries(theMonths)
	set logCtx to my initialize("buildMonthDictionaries")
	logger's trace(logCtx, "enter")
	set byDigit to current application's NSMutableDictionary's dictionary()
	set byName to current application's NSMutableDictionary's dictionary()
	repeat with aMonth in theMonths
		set theNumber to first item of aMonth as string
		set theName to second item of aMonth as string
		(byDigit's setObject:theName forKey:theNumber)
		(byName's setObject:theNumber forKey:theName)
	end repeat
	logger's trace(logCtx, "exit")
	return {byDigit, byName}
end buildMonthDictionaries

-- Builds a tag-to-alias dictionary from configured alias pairs.
-- Parameters:
--    theTagAliases:list<list{text,text}> configured tag alias pairs.
-- Return: NSMutableDictionary<text,text> computed result.
on buildTagAliasDictionary(theTagAliases)
	set logCtx to my initialize("buildTagAliasDictionary")
	logger's trace(logCtx, "enter")
	set aliasesDictionary to current application's NSMutableDictionary's dictionary()
	repeat with aTagAlias in theTagAliases
		set theTag to first item of aTagAlias as string
		set theAlias to second item of aTagAlias as string
		(aliasesDictionary's setObject:theAlias forKey:theTag)
	end repeat
	logger's trace(logCtx, "exit")
	return aliasesDictionary
end buildTagAliasDictionary

-- Builds a dimension dictionary directly from DEVONthink tags.
-- Parameters:
--    theDatabase:DEVONthink database (class 'database' / DTkb) database context used by the operation.
-- Return: NSMutableDictionary<text,list<text>> computed result.
on buildDimensionsDictionaryFromDEVONthink(theDatabase)
	set logCtx to my initialize("buildDimensionsDictionaryFromDEVONthink")
	logger's trace(logCtx, "enter")

	set dimensionsDictionary to current application's NSMutableDictionary's dictionary()
	tell application id "DNtp"
		set dimensionHome to get record at pDimensionsHome in theDatabase
		set theDimensions to every child of dimensionHome
		repeat with aDimension in theDimensions
			set {dimensionName, dimensionChilds} to {name, every child} of aDimension
			set categories to my createTagList(dimensionChilds, {})
			(dimensionsDictionary's setObject:categories forKey:dimensionName)
			tell logger to debug(logCtx, "Dimension '" & dimensionName & "' refreshed with " & length of categories & " categories.")
		end repeat
	end tell

	logger's trace(logCtx, "exit")
	return dimensionsDictionary
end buildDimensionsDictionaryFromDEVONthink

-- Classifies records by date tags and compare-based dimension inference.
-- Parameters:
--    theRecords:list<DEVONthink record (class 'record' / DTrc)> records to process.
-- Return: none (side effects only).
on classifyRecords(theRecords)
	set logCtx to my initialize("classifyRecords")
	if not pPerformanceTraceManagedByCaller then logger's resetTraceMetrics()
	logger's trace(logCtx, "enter")
	-- set theRecords to my normalizeRecordsForProcessing(theRecords)

	tell application id "DNtp"
		-- try
		--    set theDatabase to current database
		-- on error
		set theDatabase to database of first item of theRecords
		-- end try

		my initializeDatabaseConfiguration(theDatabase)
		set {recordsSelected, recordsProcessed} to {0, 0}
		repeat with theRecord in theRecords
			set recordsSelected to recordsSelected + 1
			set recordsProcessed to recordsProcessed + 1

			set tagFields to my fieldsFromTags(theRecord, true)

			-- Date, wenn ClassificationDate gesetzt
			if pClassificationDate is not missing value and pClassificationDate is not "" then
				if length of pDateDimensions > 0 then
					my setDateTags(theRecord, tagFields, pClassificationDate)
				end if
			end if

			-- restliche Dimensionen
			repeat with aCompareDimension in pCompareDimensions
				my setTagFromCompareRecord(theRecord, theDatabase, tagFields, aCompareDimension)
			end repeat

		end repeat
		tell logger to info(logCtx, "Records selected: " & recordsSelected & ", Records processed:  " & recordsProcessed)
	end tell

	logger's trace(logCtx, "exit")
	if not pPerformanceTraceManagedByCaller then logger's logTraceMetrics()
end classifyRecords

-- Resolves the effective label for a record, optionally asking the user to choose one.
-- Parameters:
--    theRecord:DEVONthink record (class 'record' / DTrc) record used for lookup.
-- Return: record with labelIndex:integer and labelName:text, or missing value on cancel.
on chooseLabelInfoForRecord(theRecord)
	set logCtx to my initialize("chooseLabelInfoForRecord")
	logger's trace(logCtx, "enter")

	set labelIndex to 0
	set labelNames to {}

	tell application id "DNtp"
		if theRecord is not missing value then set labelIndex to label of theRecord
		set labelNames to label names
	end tell

	if labelNames is missing value or labelNames is {} then error "No DEVONthink labels are available."
	if labelIndex > 0 then
		if labelIndex > (count of labelNames) then error "Label index out of range: " & labelIndex
		set labelName to item labelIndex of labelNames as string
		logger's trace(logCtx, "exit")
		return {labelIndex:labelIndex, labelName:labelName}
	end if

	-- No label assigned: let the user pick one explicit label index from DEVONthink's label list.
	set chooserItems to {}
	repeat with labelListIndex from 1 to count of labelNames
		set end of chooserItems to ((labelListIndex as string) & "-" & (item labelListIndex of labelNames as string))
	end repeat

	tell application id "DNtp" to activate
	set selectedItems to choose from list chooserItems with title "Open Label Smart Group" with prompt "No label is assigned to the selected record. Choose a label." OK button name "Choose" cancel button name "Cancel" without multiple selections allowed
	if selectedItems is false then
		logger's info(logCtx, "Label chooser canceled.")
		logger's trace(logCtx, "exit")
		return missing value
	end if

	set selectedItemLabel to first item of selectedItems as string
	set selectedLabelIndex to 0
	repeat with labelListIndex from 1 to count of chooserItems
		if item labelListIndex of chooserItems as string is selectedItemLabel then
			set selectedLabelIndex to labelListIndex
			exit repeat
		end if
	end repeat
	if selectedLabelIndex is 0 then error "Failed to resolve selected label index."

	set selectedLabelName to item selectedLabelIndex of labelNames as string

	logger's trace(logCtx, "exit")
	return {labelIndex:selectedLabelIndex, labelName:selectedLabelName}
end chooseLabelInfoForRecord

-- Shows a chooser for existing smart groups in a configured smart groups folder.
-- Parameters:
--    smartgroupsFolder:text DEVONthink location path for smart groups.
--    theDatabase:DEVONthink database (class 'database' / DTkb) database context.
-- Return: DEVONthink record (class 'record' / DTrc)|missing value selected smart group or missing value on cancel.
on chooseSmartGroupFromFolder(smartgroupsFolder, theDatabase)
	set logCtx to my initialize("chooseSmartGroupFromFolder")
	logger's trace(logCtx, "enter > " & smartgroupsFolder)

	set chooserItems to {}
	set theSelectedSmartGroup to missing value

	-- Resolve the configured smart groups folder in the preferred database context.
	-- If the explicit context fails, retry with DEVONthink's default/current context.
	tell application id "DNtp"
		set theSmartGroupsRecord to missing value
		if theDatabase is missing value then
			set theSmartGroupsRecord to get record at smartgroupsFolder
		else
			try
				set theSmartGroupsRecord to get record at smartgroupsFolder in theDatabase
			on error
				set theSmartGroupsRecord to get record at smartgroupsFolder
			end try
		end if

		if theSmartGroupsRecord is missing value then error "Smart groups folder not found: " & smartgroupsFolder

		-- Build chooser labels from direct child smart groups only.
		repeat with aRecord in every child of theSmartGroupsRecord
			if type of aRecord is smart group then
				set end of chooserItems to (name of aRecord as string)
			end if
		end repeat
	end tell

	if chooserItems is {} then error "No smart groups found in folder '" & smartgroupsFolder & "'."

	-- Sort labels case-insensitively via shell `sort` and always restore TIDs.
	set oldTIDs to AppleScript's text item delimiters
	try
		set AppleScript's text item delimiters to linefeed
		set sortedText to do shell script "/usr/bin/printf %s " & quoted form of (chooserItems as text) & " | /usr/bin/sort -f"
		set chooserItems to paragraphs of sortedText
	on error errMsg number errNum
		set AppleScript's text item delimiters to oldTIDs
		error errMsg number errNum
	end try
	set AppleScript's text item delimiters to oldTIDs

	-- Let the user choose one smart group; cancel keeps behavior non-destructive.
	tell application id "DNtp" to activate
	set selectedItems to choose from list chooserItems with title "Open Smart Group" with prompt ("Choose a smart group in '" & smartgroupsFolder & "'.") without multiple selections allowed
	if selectedItems is false then
		logger's info(logCtx, "Smart group chooser canceled.")
		logger's trace(logCtx, "exit")
		return missing value
	end if

	-- Resolve the selected label back to its record object.
	set selectedItemLabel to first item of selectedItems
	tell application id "DNtp"
		repeat with aRecord in every child of theSmartGroupsRecord
			if type of aRecord is smart group and (name of aRecord as string) is selectedItemLabel then
				set theSelectedSmartGroup to aRecord
				exit repeat
			end if
		end repeat
	end tell
	if theSelectedSmartGroup is missing value then error "Failed to resolve selected smart group."

	logger's trace(logCtx, "exit")
	return theSelectedSmartGroup
end chooseSmartGroupFromFolder

-- Creates a sender smart group for the provided records.
-- Parameters:
--    theRecords:list<DEVONthink record (class 'record' / DTrc)> records to process.
--    theDatabaseName:text name of the target database.
-- Return: none (side effects only).
on createSmartGroupForSender(theRecords, theDatabaseName)
	set logCtx to my initialize("createSmartGroupForSender")
	logger's trace(logCtx, "enter > " & theDatabaseName)

	my initializeMailConfiguration(pDatabaseConfigurationFolder, theDatabaseName)

	mailLib's createSmartGroup(theRecords)

	logger's trace(logCtx, "exit")
end createSmartGroupForSender

-- Flattens hierarchical tags into a plain leaf-tag list.
-- Parameters:
--    theTags:list<DEVONthink child record (class 'child' / DTch)> tags to traverse and transform.
--    resultList:list<text> accumulator list for collected results.
-- Return: list<text> computed result.
on createTagList(theTags, resultList)
	set logCtx to my initialize("createTagList")
	logger's trace(logCtx, "enter")
	tell application id "DNtp"
		repeat with tagListItem in theTags
			set {theName, theTagType} to {name, tag type} of tagListItem
			if theTagType is ordinary tag then
				set end of resultList to theName
			else
				set resultList to my createTagList(every child of tagListItem, resultList)
			end if
		end repeat
	end tell
	logger's trace(logCtx, "exit")
	return resultList
end createTagList

-- Resolves the creation date from metadata with fallback handling.
-- Parameters:
--    theRecord:DEVONthink record (class 'record' / DTrc) record to process.
-- Return: date computed result.
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



-- Displays an informational notification for each record.
-- Parameters:
--    theRecords:list<DEVONthink record (class 'record' / DTrc)> records to process.
--    pMessagePrefix:text message prefix shown in notifications.
--    pFieldForMessage:text field name used to build notification text.
-- Return: none (side effects only).
on displayNotification(theRecords, pMessagePrefix, pFieldForMessage)
	set logCtx to my initialize("displayNotification")
	logger's trace(logCtx, "enter > displayNotification: " & pMessagePrefix)

	tell application id "DNtp"
		repeat with theRecord in theRecords
			set theValue to get custom meta data for pFieldForMessage from theRecord
			set theMessage to pMessagePrefix & theValue
			log message info theMessage record theRecord
		end repeat
	end tell

	logger's trace(logCtx, "exit")
end displayNotification

-- Ensures the configured smart groups folder exists.
-- Parameters:
--    smartgroupsFolder:text DEVONthink location path for smart groups.
--    theDatabase:DEVONthink database (class 'database' / DTkb) database context.
-- Return: DEVONthink record (class 'record' / DTrc) smart groups folder record.
on ensureSmartGroupsFolder(smartgroupsFolder, theDatabase)
	set logCtx to my initialize("ensureSmartGroupsFolder")
	logger's trace(logCtx, "enter > " & smartgroupsFolder)

	tell application id "DNtp"
		set theSmartGroupsRecord to get record at smartgroupsFolder in theDatabase
		if theSmartGroupsRecord is missing value then
			set theSmartGroupsRecord to create location smartgroupsFolder in theDatabase
		end if
	end tell

	logger's trace(logCtx, "exit")
	return theSmartGroupsRecord
end ensureSmartGroupsFolder

-- Checks whether all requested dimensions are present in the field dictionary.
-- Parameters:
--    theFields:NSMutableDictionary field dictionary used for value lookup.
--    theDimensions:list<text> dimension keys used for placeholder replacement.
-- Return: boolean computed result.
on existDimension(theFields, theDimensions)
	set logCtx to my initialize("existDimension")
	logger's trace(logCtx, "enter")

	repeat with aDimension in theDimensions
		set theValue to (theFields's objectForKey:aDimension)
		if theValue is missing value then
			logger's trace(logCtx, "No value found for dimension '" & aDimension & "'.")
			logger's trace(logCtx, "exit > false")
			return false
		end if
	end repeat

	logger's trace(logCtx, "exit > true")
	return true
end existDimension

-- Extracts user-provided custom text from a metadata command value.
-- Parameters:
--    currentValue:text|missing value current metadata value to parse.
-- Return: text computed result.
on extractCustomTextFromCmdValue(currentValue)
	set logCtx to my initialize("extractCustomTextFromCmdValue")
	logger's trace(logCtx, "enter > " & currentValue)

	set customText to ""
	if currentValue is not missing value then

		-- wenn Custom Text vorhanden ist parsen, sonst vorhanden Wert nehmen
		if currentValue contains pCustomMetadataFieldSeparator then

			-- rechten Teil neben pCustomMetadataFieldSeparator ermitteln
			tell baseLib to set fieldList to text2List(currentValue, pCustomMetadataFieldSeparator)
			if fieldList is not missing value and length of fieldList > 1 then
				set customText to second item of fieldList
			end if

			-- mögliche "[...]" Blöcke entfernen
			set customText to my removeTrailingBracketBlocks(customText)

		else
			-- Migrationsszenario bei EMAILS: wenn kein pCustomMetadataFieldSeparator vorhanden ist wird currentValue komplett übernommen
			if (count of words of currentValue) > 1 and pContentType is equal to "EMAILS" then
				logger's debug(logCtx, "Custom Text found but no pCustomMetadataFieldSeparator -> current value will be used")
				set customText to currentValue
			end if
		end if
	end if

	logger's trace(logCtx, "exit > " & customText)
	return customText
end extractCustomTextFromCmdValue

-- Derives normalized field values from record tags.
-- Parameters:
--    theRecord:DEVONthink record (class 'record' / DTrc) record to process.
--    interactiveMode:boolean whether interactive fallback handling is enabled.
-- Return: NSMutableDictionary<text, text|list<text>> computed result.
on fieldsFromTags(theRecord, interactiveMode)
	set logCtx to my initialize("fieldsFromTags")
	logger's trace(logCtx, "enter")

	set fields to current application's NSMutableDictionary's dictionary()
	tell application id "DNtp"

		set theTags to tags of theRecord
		repeat with aTag in theTags
			set theResult to my setField(aTag, fields, interactiveMode, theRecord)
			set hasFieldBeenSet to first item of theResult
			set fields to second item of theResult
			if not hasFieldBeenSet and interactiveMode then
				my handleUncategorizedTag(aTag)
				set fields to second item of my setField(aTag, fields, interactiveMode, theRecord)
			end if
		end repeat
	end tell

	logger's trace(logCtx, "exit")
	return fields
end fieldsFromTags

-- Finds an existing smart group or creates it with the requested predicate.
-- Parameters:
--    smartGroupInfo:record with value:text, conditionField:text, and optional queryValue:text.
--    customMetadataField:text custom metadata field used for metadata predicates.
--    smartgroupsFolder:text DEVONthink location path for smart groups.
--    theSmartGroupsRecord:DEVONthink record (class 'record' / DTrc) parent group.
--    theDatabase:DEVONthink database (class 'database' / DTkb) database context.
-- Return: DEVONthink record (class 'record' / DTrc) smart group record.
on findOrCreateSmartGroup(smartGroupInfo, customMetadataField, smartgroupsFolder, theSmartGroupsRecord, theDatabase)
	set logCtx to my initialize("findOrCreateSmartGroup")

	set theValue to value of smartGroupInfo
	set smartGroupConditionField to conditionField of smartGroupInfo
	set smartGroupQueryValue to theValue
	try
		set smartGroupQueryValue to queryValue of smartGroupInfo
	end try
	if smartGroupQueryValue is missing value then set smartGroupQueryValue to theValue
	set smartGroupQueryValue to smartGroupQueryValue as string
	set theSmartGroupLocation to smartgroupsFolder & "/" & theValue
	logger's trace(logCtx, "enter > " & theSmartGroupLocation)

	tell application id "DNtp"
		if not (exists record at theSmartGroupLocation in theDatabase) then
			if smartGroupConditionField is equal to pSmartGroupConditionTags then
				set theSmartGroup to create record with {name:theValue, record type:smart group, search predicates:"tags:" & smartGroupQueryValue} in theSmartGroupsRecord
			else if smartGroupConditionField is equal to pSmartGroupConditionCustomMetadata then
				set theSmartGroup to create record with {name:theValue, record type:smart group, search predicates:"md" & customMetadataField & ":" & smartGroupQueryValue} in theSmartGroupsRecord
			else if smartGroupConditionField is equal to pSmartGroupConditionLabel then
				set theSmartGroup to create record with {name:theValue, record type:smart group, search predicates:"label:" & smartGroupQueryValue} in theSmartGroupsRecord
			else
				error "Unsupported smart group condition field: " & smartGroupConditionField
			end if
			logger's info(logCtx, "Create smart group: " & theSmartGroupLocation)
		else
			set theSmartGroup to get record at theSmartGroupLocation in theDatabase
		end if
	end tell

	if theSmartGroup is missing value then error "No Smart Group found."

	logger's trace(logCtx, "exit")
	return theSmartGroup
end findOrCreateSmartGroup

-- Finishes a caller-managed performance trace run and writes metrics.
-- Parameters:
--    theTraceName:text human-readable caller/run name.
-- Return: none (side effects only).
on finishPerformanceTrace(theTraceName)
	set logCtx to my initialize("finishPerformanceTrace")
	logger's debug(logCtx, "Finished performance trace: " & theTraceName)
	logger's logTraceMetrics()
	set pPerformanceTraceManagedByCaller to false
end finishPerformanceTrace

-- Determines the effective date to use for classification.
-- Parameters:
--    theRecord:DEVONthink record (class 'record' / DTrc) record to process.
--    theClassificationDate:text configured classification date source.
-- Return: date computed result.
on getClassificationDate(theRecord, theClassificationDate)
	set logCtx to my initialize("getClassificationDate")
	logger's trace(logCtx, "enter")

	tell application id "DNtp"

		set theDate to missing value
		if theClassificationDate is equal to "DOCUMENT_CREATION_DATE" then

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

		else if theClassificationDate is equal to "RECORD_CREATION_DATE" then

			set theDate to creation date of theRecord

		else
			error "Unknown Classification Date Field Identifier: " & theClassificationDate
		end if

	end tell

	logger's trace(logCtx, "exit > " & theDate)
	return theDate
end getClassificationDate

-- Returns true when the argv list contains the worker flag.
-- Parameters:
--    theArgs:list command-line arguments passed to the script.
-- Return: boolean true when "--worker" is present.
on hasWorkerFlag(theArgs)
	if class of theArgs is not list then return false
	repeat with anArg in theArgs
		try
			if (anArg as text) is "--worker" then return true
		end try
	end repeat
	return false
end hasWorkerFlag

-- Handles interactive assignment for an uncategorized tag.
-- Parameters:
--    theTag:text tag value to evaluate.
-- Return: none (side effects only).
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

		tell application id "DNtp" to activate
		set theItem to choose from list sortedList ¬
			with title ("Uncategorized Tag: " & theTag) with prompt "The Tag '" & theTag & "' is not categorized yet. You can categorize it now to one of the following dimensions or leave it as is." default items {"05 Subject"} OK button name "Catagorize" cancel button name "Cancel" without multiple selections allowed

		-- Tag zu Categories der entsprechenden Dimension hinzufügen
		if theItem is not {} and theItem is not false then
			set theDimensionName to first item of theItem as string

			-- Dictionary
			set theCategories to (pDimensionsDictionary's objectForKey:theDimensionName) as list
			set end of theCategories to name of theUncategorizedRecord as string
			(pDimensionsDictionary's setObject:theCategories forKey:theDimensionName)
			my persistDimensionsCacheIfEnabled()

			-- Tag Group
			set theDimensionRecord to get record at pDimensionsHome & "/" & theDimensionName
			move record theUncategorizedRecord to theDimensionRecord
		end if

	end tell
	logger's trace(logCtx, "exit")
end handleUncategorizedTag

-- Imports inbox messages into the configured target database.
-- Parameters:
--    theDatabaseName:text name of the target database.
-- Return: none (side effects only).
on importMailMessages(theDatabaseName)
	set logCtx to my initialize("importMailMessages")
	logger's trace(logCtx, "enter > " & theDatabaseName)

	tell application id "DNtp"

		my initializeMailConfiguration(pDatabaseConfigurationFolder, theDatabaseName)

		set theMessages to mailLib's getInboxMessages()
		logger's debug(logCtx, "Number of Inbox Messages: " & length of theMessages)
		mailLib's importMessages(theMessages, theDatabaseName)

	end tell
	logger's trace(logCtx, "exit")
end importMailMessages

-- Returns true when the command should be wrapped in a performance trace.
-- Parameters:
--    commandKey:text logical DEVONthink menu command identifier.
-- Return: boolean trace flag.
on isTraceCommand(commandKey)
	if commandKey is "archive" then return true
	if commandKey is "import_mail" then return true
	if commandKey is "open_context" then return true
	if commandKey is "open_label" then return true
	if commandKey is "open_sender" then return true
	if commandKey is "open_subject" then return true
	if commandKey is "open_year" then return true
	if commandKey is "update_dimensions_cache" then return true
	if commandKey is "verify_records" then return true
	return false
end isTraceCommand

-- Initializes configuration and library dependencies for this module.
-- Parameters:
--    loggingContext:text context label used for logging.
-- Return: text computed result.
on initialize(loggingContext)
	set logCtx to pScriptName & " > initialize"

	if not pIsInitialized then

		-- Configuration
		set config to load script (POSIX path of (path to home folder) & ".mailscripts/config.scpt")
		set logger to load script pLogger of config
		tell logger to initialize()
		set baseLib to load script pBaseLibraryPath of config
		set mailLib to load script pMailLibraryPath of config

		set pDatabaseConfigurationFolder to pDatabaseConfigurationFolder of config
		set pExiftool to pExiftool of config

		set dtInfo to baseLib's getDEVONthinkRuntimeInfo()
		tell logger to debug(logCtx, "DEVONthink " & (applicationVersion of dtInfo))

		set pIsInitialized to true
		tell logger to debug(logCtx, "Initialization finished")
	end if
	return pScriptName & " > " & loggingContext
end initialize

-- Loads and applies database-specific configuration.
-- Parameters:
--    theDatabase:DEVONthink database (class 'database' / DTkb) database context used by the operation.
-- Return: none (side effects only).
on initializeDatabaseConfiguration(theDatabase)
	set logCtx to my initialize("initializeDatabaseConfiguration")
	logger's trace(logCtx, "enter")

	tell application id "DNtp" to set theDatabaseName to name of theDatabase

	set configurationFile to baseLib's loadConfiguration(pDatabaseConfigurationFolder, theDatabaseName)

	set pContentType to pContentType of configurationFile

	-- Logger
	set pLogLevel to pLogLevel of configurationFile
	logger's setLogLevel(pLogLevel)

	-- Dimensions
	set pDimensionsHome to pDimensionsHome of configurationFile
	set pUseDimensionsFilesystemCache to false
	try
		set pUseDimensionsFilesystemCache to pUseDimensionsFilesystemCache of configurationFile
	end try
	if pUseDimensionsFilesystemCache is true then
		set pDimensionsCachePath to baseLib's resolveDimensionsCachePath(configurationFile, theDatabaseName, pDatabaseConfigurationFolder)
	else
		set pDimensionsCachePath to missing value
	end if
	set pDateDimensions to pDateDimensions of configurationFile
	set pCompareDimensions to pCompareDimensions of configurationFile
	set pCompareDimensionsScoreThreshold to pCompareDimensionsScoreThreshold of configurationFile

	set pClassificationDate to pClassificationDate of configurationFile

	set pNameTemplate to pNameTemplate of configurationFile

	set pCustomMetadataFields to pCustomMetadataFields of configurationFile
	set pCustomMetadataDimensions to pCustomMetadataDimensions of configurationFile
	set pCustomMetadataTypes to pCustomMetadataTypes of configurationFile
	set pCustomMetadataTemplates to pCustomMetadataTemplates of configurationFile
	set pCustomMetadataFieldSeparator to pCustomMetadataFieldSeparator of configurationFile

	set pCommentsFields to pCommentsFields of configurationFile

	set pAmountLookupCategories to words of (pAmountLookupCategories of configurationFile)
	set pFilesHome to pFilesHome of configurationFile

	set pDimensionsConstraints to pDimensionsConstraints of configurationFile
	set pDimensionsConstraintsDictionary to my buildDimensionsConstraintsDictionary(pDimensionsConstraints)

	set pTagAliases to pTagAliases of configurationFile
	set tagAliases to my buildTagAliasDictionary(pTagAliases)

	set theMonths to pMonths of configurationFile
	set {monthsByDigit, monthsByName} to my buildMonthDictionaries(theMonths)

	set pAmountFormatter to current application's NSNumberFormatter's new()
	pAmountFormatter's setMinimumFractionDigits:2
	pAmountFormatter's setMaximumFractionDigits:2
	pAmountFormatter's setNumberStyle:(current application's NSNumberFormatterDecimalStyle)

	my initializeDimensions(theDatabase)

	if pContentType is equal to "EMAILS" then
		my initializeMailConfiguration(pDatabaseConfigurationFolder, theDatabaseName)
	end if

	logger's trace(logCtx, "exit")
end initializeDatabaseConfiguration

-- Loads dimension and category definitions into the in-memory cache.
-- Parameters:
--    theDatabase:DEVONthink database (class 'database' / DTkb) database context used by the operation.
-- Return: none (side effects only).
on initializeDimensions(theDatabase)
	set logCtx to my initialize("initializeDimensions")
	logger's trace(logCtx, "enter")

	if pUseDimensionsFilesystemCache is false then
		set pDimensionsDictionary to my buildDimensionsDictionaryFromDEVONthink(theDatabase)
		logger's debug(logCtx, "Dimensions loaded directly from DEVONthink.")
		logger's trace(logCtx, "exit")
		return
	end if

	if (baseLib's dimensionsCacheExists(pDimensionsCachePath)) is false then
		logger's info(logCtx, "Dimensions cache file missing. Creating: " & pDimensionsCachePath)
		my refreshDimensionsCache(theDatabase)
	end if

	try
		set pDimensionsDictionary to baseLib's readDimensionsCache(pDimensionsCachePath)
		logger's debug(logCtx, "Dimensions loaded from filesystem cache: " & pDimensionsCachePath)
	on error errMsg number errNum
		logger's info(logCtx, "Dimensions cache unavailable or invalid. Refreshing cache. Reason (" & errNum & "): " & errMsg)
		my refreshDimensionsCache(theDatabase)
		set pDimensionsDictionary to baseLib's readDimensionsCache(pDimensionsCachePath)
	end try

	logger's trace(logCtx, "exit")
end initializeDimensions

-- Initializes mail library configuration for a target database.
-- Parameters:
--    theDatabaseName:text name of the target database.
-- Return: text computed result.
on initializeMailConfiguration(theDatabaseConfigurationFolder, theDatabaseName)
	set logCtx to my initialize("initializeMailConfiguration")
	logger's trace(logCtx, "enter > " & theDatabaseName)
	mailLib's initializeDepencencies(logger, baseLib)
	mailLib's initializeMailConfiguration(theDatabaseConfigurationFolder, theDatabaseName)
	logger's trace(logCtx, "exit")
end initializeMailConfiguration

-- Relaunches the current script externally with worker flag.
-- Parameters:
--    scriptPath:text absolute script path.
-- Return: none (side effects only).
on launchWorker(scriptPath)
	do shell script ("/usr/bin/osascript -l AppleScript " & quoted form of scriptPath & " --worker")
end launchWorker

-- Relaunches the current smart-rule script externally with command key and record UUIDs.
-- Parameters:
--    scriptPath:text absolute script path.
--    commandKey:text logical smart-rule command identifier.
--    recordUUIDs:list<text> unique record identifiers.
-- Return: none (side effects only).
on launchWorkerForSmartRule(scriptPath, commandKey, recordUUIDs)
	set cmd to "/usr/bin/osascript -l AppleScript " & quoted form of scriptPath & " --worker --smart-rule-command " & quoted form of commandKey
	repeat with aUUID in recordUUIDs
		set cmd to cmd & " --record-uuid " & quoted form of (aUUID as text)
	end repeat
	do shell script cmd
end launchWorkerForSmartRule

-- Logs a validation issue and updates issue-tracking state.
-- Parameters:
--    theRecord:DEVONthink record (class 'record' / DTrc) record to process.
--    setRecordLabel:boolean whether to set a label on the record.
--    theMessage:text log message text.
-- Return: none (side effects only).
on logIssue(theRecord, setRecordLabel, theMessage)
	tell application id "DNtp"
		tell logger to info_r(theRecord, theMessage)
		set pIssueCount to pIssueCount + 1
		if setRecordLabel is true then
			set label of theRecord to 7
		end if
	end tell
end logIssue

-- Moves records into target groups based on a dimension value.
-- Parameters:
--    theRecords:list<DEVONthink record (class 'record' / DTrc)> records to process.
--    theDimension:text dimension key used for lookup and routing.
--    theFolderPrefix:text folder prefix used for target path resolution.
-- Return: none (side effects only).
on moveByDimension(theRecords, theDimension, theFolderPrefix)
	set logCtx to my initialize("moveByDimension")
	logger's trace(logCtx, "enter > theDimension: " & theDimension & "; theFolderPrefix: " & theFolderPrefix)

	tell application id "DNtp"

		set theDatabase to database of first item of theRecords
		my initializeDatabaseConfiguration(theDatabase)
		repeat with theRecord in theRecords

			set tagFields to my fieldsFromTags(theRecord, true)
			set theCategory to (tagFields's objectForKey:theDimension)

			if theCategory is not missing value and theCategory is not "" then
				set theDestinationFolderName to theFolderPrefix & "/" & theCategory as string
				my moveRecord(theRecord, theDestinationFolderName)
			end if

		end repeat
	end tell

	logger's trace(logCtx, "exit")
end moveByDimension

-- Moves selected tags into a child group named after the first character of the tag name.
-- DEVONthink-specific notes:
--    - Use `tag type` to distinguish tags from normal groups because `type` alone returns `group` for both.
--    - Use `location group` as the stable parent-group reference for selected tags.
-- Parameters:
--    theRecords:list<DEVONthink record (class 'record' / DTrc)> records to process.
-- Return: none (side effects only).
on moveByFirstCharacter(theRecords)
	set logCtx to my initialize("moveByFirstCharacter")
	logger's trace(logCtx, "enter")

	tell application id "DNtp"
		repeat with theRecord in theRecords
			set tagType to missing value
			try
				set tagType to tag type of theRecord
			end try

			if tagType is missing value then
				logger's info(logCtx, "Record skipped because it is not a tag: " & (name of theRecord as string))
			else
				set currentGroup to location group of theRecord
				if currentGroup is missing value then
					logger's info(logCtx, "Record skipped because no location group is available: " & (name of theRecord as string))
				else
					set recordName to name of theRecord as string
					set trimmedRecordName to baseLib's trim(recordName)
					if trimmedRecordName is "" then
						logger's info(logCtx, "Record skipped because it has no usable name: " & recordName)
					else
						set normalizedRecordName to ((current application's NSString's stringWithString:trimmedRecordName)'s uppercaseString()) as string
						set firstCharacter to rich texts 1 thru 1 of trimmedRecordName
						set firstCharacter to ((current application's NSString's stringWithString:firstCharacter)'s uppercaseString()) as string
						set currentGroupName to baseLib's trim(name of currentGroup as string)
						set currentGroupName to ((current application's NSString's stringWithString:currentGroupName)'s uppercaseString()) as string

						if currentGroupName is equal to firstCharacter then
							logger's debug(logCtx, "Record already located in matching subgroup: " & recordName)
						else if normalizedRecordName is equal to firstCharacter then
							logger's debug(logCtx, "Record skipped because it already looks like an alphabetical subgroup: " & recordName)
						else
							my moveRecordToChildGroupNamed(theRecord, currentGroup, firstCharacter)
						end if
					end if
				end if
			end if
		end repeat
	end tell

	logger's trace(logCtx, "exit")
end moveByFirstCharacter

-- Moves a record to a destination group and creates it if needed.
-- Parameters:
--    theRecord:DEVONthink record (class 'record' / DTrc) record to process.
--    theDestinationFolderName:text destination group name.
-- Return: none (side effects only).
on moveRecord(theRecord, theDestinationFolderName)
	set logCtx to my initialize("moveRecord")
	logger's trace(logCtx, "enter > theDestinationFolderName: " & theDestinationFolderName)

	tell application id "DNtp"

		set theDestinationFolder to get record at theDestinationFolderName in database of theRecord
		if theDestinationFolder is missing value then
			logger's info(logCtx, "Record will be moved to a group that doesn't exist yet and will be created now: " & theDestinationFolderName)
			set theDestinationFolder to create location theDestinationFolderName in database of theRecord
		end if
		logger's debug(logCtx, "Record moved from: " & location of theRecord & " to: " & theDestinationFolderName)
		move record theRecord from location group of theRecord to theDestinationFolder

	end tell

	logger's trace(logCtx, "exit")
end moveRecord

-- Moves a record into a named child group below a parent group and creates that child group if needed.
-- This is used by the first-character tag rule so the alphabet bucket is created on demand.
-- The alphabet bucket is a normal group inside the Tags hierarchy with `exclude from tagging`
-- enabled, matching the DEVONthink UI command "Exclude from Tagging".
-- Parameters:
--    theRecord:DEVONthink record (class 'record' / DTrc) record to process.
--    theParentGroup:DEVONthink group (class 'group' / DTgr) parent group used for child lookup.
--    theChildGroupName:text destination child group name.
-- Return: none (side effects only).
on moveRecordToChildGroupNamed(theRecord, theParentGroup, theChildGroupName)
	set logCtx to my initialize("moveRecordToChildGroupNamed")
	logger's trace(logCtx, "enter > theChildGroupName: " & theChildGroupName)

	tell application id "DNtp"
		set destinationGroup to missing value
		set normalizedChildGroupName to baseLib's trim(theChildGroupName as string)
		set normalizedChildGroupName to ((current application's NSString's stringWithString:normalizedChildGroupName)'s uppercaseString()) as string

		repeat with aChildRecord in every child of theParentGroup
			if type of aChildRecord is group then
				set candidateGroupName to baseLib's trim(name of aChildRecord as string)
				set candidateGroupName to ((current application's NSString's stringWithString:candidateGroupName)'s uppercaseString()) as string
				if candidateGroupName is equal to normalizedChildGroupName then
					set destinationGroup to aChildRecord
					exit repeat
				end if
			end if
		end repeat

		if destinationGroup is missing value then
			logger's info(logCtx, "Group will be created now: " & normalizedChildGroupName)
			set destinationGroup to create record with {name:normalizedChildGroupName, record type:group, exclude from tagging:true} in theParentGroup
		end if

		if exclude from tagging of destinationGroup is not true then set exclude from tagging of destinationGroup to true

		logger's debug(logCtx, "Record moved from group: " & (name of theParentGroup as string) & " to subgroup: " & normalizedChildGroupName)
		move record theRecord from theParentGroup to destinationGroup
	end tell

	logger's trace(logCtx, "exit")
end moveRecordToChildGroupNamed

-- Normalizes incoming record collections to a concrete non-empty list of DEVONthink records.
-- Parameters:
--    theRecords:any list-like record collection from menu handlers.
-- Return: list<DEVONthink record (class 'record' / DTrc)> normalized list.
on normalizeRecordsForProcessing(theRecords)
	if class of theRecords is list then
		set normalizedRecords to theRecords
	else
		try
			set normalizedRecords to theRecords as list
		on error
			set normalizedRecords to {}
		end try
	end if

	if (count of normalizedRecords) is 0 then error "Please select some contents."
	return normalizedRecords
end normalizeRecordsForProcessing

-- Opens or creates a smart group for the record label.
-- If the record has no label, the user can select one from DEVONthink label names.
-- Parameters:
--    theSmartGroupSpecifier:record with smartgroupsFolder:text.
--    theRecords:list<DEVONthink record (class 'record' / DTrc)> records used to derive label values.
-- Return: none (side effects only).
on openLabelSmartGroup(theSmartGroupSpecifier, theRecords)
	set logCtx to my initialize("openLabelSmartGroup")
	logger's trace(logCtx, "enter")
	set theRecords to my normalizeOptionalRecords(theRecords)

	set smartgroupsFolder to smartgroupsFolder of theSmartGroupSpecifier

	-- Interactive mode: no selection means pick an existing smart group from folder.
	if theRecords is {} then
		set theDatabase to missing value

		-- Resolve an active database robustly (current database first, then current group -> database).
		tell application id "DNtp"
			try
				set theDatabase to get current database
			end try
			if theDatabase is missing value then
				try
					set theCurrentGroup to get current group
					if theCurrentGroup is not missing value then set theDatabase to database of theCurrentGroup
				end try
			end if
		end tell
		if theDatabase is missing value then error "No current database available."

		set selectedSmartGroup to my chooseSmartGroupFromFolder(smartgroupsFolder, theDatabase)
		if selectedSmartGroup is missing value then
			logger's trace(logCtx, "exit")
			return
		end if

		tell application id "DNtp"
			open window for record selectedSmartGroup
		end tell

		logger's trace(logCtx, "exit")
		return
	end if

	-- Derived mode: exactly one source record is supported.
	if (count of theRecords) > 1 then error "openLabelSmartGroup expects zero or one record."

	set theRecord to first item of theRecords
	set labelInfo to my chooseLabelInfoForRecord(theRecord)
	if labelInfo is missing value then
		logger's trace(logCtx, "exit")
		return
	end if

	set labelIndex to labelIndex of labelInfo
	set labelName to labelName of labelInfo
	set smartGroupInfo to {value:labelName, queryValue:(labelIndex as string), conditionField:"Label"}

	tell application id "DNtp"
		set theDatabase to database of theRecord

		my initializeDatabaseConfiguration(theDatabase)
		set theSmartGroupsRecord to my ensureSmartGroupsFolder(smartgroupsFolder, theDatabase)
		set theSmartGroup to my findOrCreateSmartGroup(smartGroupInfo, "", smartgroupsFolder, theSmartGroupsRecord, theDatabase)
		open window for record theSmartGroup
	end tell

	logger's trace(logCtx, "exit")
end openLabelSmartGroup

-- Normalizes incoming record collections to a concrete list while allowing an empty result.
-- Parameters:
--    theRecords:any list-like record collection from menu handlers.
-- Return: list<DEVONthink record (class 'record' / DTrc)> normalized list (possibly empty).
on normalizeOptionalRecords(theRecords)
	if theRecords is missing value then return {}
	if class of theRecords is list then return theRecords
	try
		return theRecords as list
	on error
		return {}
	end try
end normalizeOptionalRecords

-- Opens or creates smart groups for the tag value derived from a configured dimension.
-- If the dimension value was not found and a customMetadataField is present, the smart group is created with custom metadata.
-- Parameters:
--    theSmartGroupSpecifier:record with dimension:text and smartgroupsFolder:text.
--    theRecords:list<DEVONthink record (class 'record' / DTrc)> records used to derive tag values.
-- Return: none (side effects only).
on openSmartGroup(theSmartGroupSpecifier, theRecords)
	set logCtx to my initialize("openSmartGroup")
	logger's trace(logCtx, "enter")

	set smartgroupsFolder to smartgroupsFolder of theSmartGroupSpecifier

	-- Interactive mode: no selection means pick an existing smart group from folder.
	if theRecords is {} then
		set theDatabase to my resolveActiveDatabase()
		if theDatabase is missing value then error "No current database available."

		set selectedSmartGroup to my chooseSmartGroupFromFolder(smartgroupsFolder, theDatabase)
		if selectedSmartGroup is missing value then
			logger's trace(logCtx, "exit")
			return
		end if

		tell application id "DNtp"
			open window for record selectedSmartGroup
		end tell

		logger's trace(logCtx, "exit")
		return
	end if

	-- Derived mode: exactly one source record is supported.
	if length of theRecords > 1 then error "openSmartGroup expects zero or one record."

	set theDimension to dimension of theSmartGroupSpecifier
	set customMetadataField to customMetadataField of theSmartGroupSpecifier
	logger's debug(logCtx, "theSmartGroupSpecifier > theDimension: " & theDimension & ", customMetadataField: " & customMetadataField & ", smartgroupsFolder: " & smartgroupsFolder)

	tell application id "DNtp"
		set theDatabase to database of first item of theRecords

		-- Resolve/create folder context and open/create the target smart group from derived value.
		my initializeDatabaseConfiguration(theDatabase)
		set theSmartGroupsRecord to my ensureSmartGroupsFolder(smartgroupsFolder, theDatabase)

		repeat with theRecord in theRecords
			set smartGroupInfo to my resolveSmartGroupInfoForRecord(theSmartGroupSpecifier, theRecord)
			set theSmartGroup to my findOrCreateSmartGroup(smartGroupInfo, customMetadataField, smartgroupsFolder, theSmartGroupsRecord, theDatabase)
			open window for record theSmartGroup
		end repeat
	end tell

	logger's trace(logCtx, "exit")
end openSmartGroup

-- Persists the current in-memory dimensions dictionary when filesystem caching is enabled.
-- Parameters: none.
-- Return: none (side effects only).
on persistDimensionsCacheIfEnabled()
	set logCtx to my initialize("persistDimensionsCacheIfEnabled")
	logger's trace(logCtx, "enter")

	if pUseDimensionsFilesystemCache is false then
		logger's debug(logCtx, "Dimensions filesystem cache disabled. Skipping persistence.")
		logger's trace(logCtx, "exit")
		return
	end if

	if pDimensionsCachePath is missing value or pDimensionsCachePath is "" then error "Dimensions cache path is not configured."

	logger's debug(logCtx, "Persisting dimensions cache to: " & pDimensionsCachePath)
	baseLib's writeDimensionsCache(pDimensionsCachePath, pDimensionsDictionary)

	logger's trace(logCtx, "exit")
end persistDimensionsCacheIfEnabled

-- Runs the standard document workflow for classification and metadata updates.
-- Parameters:
--    theRecords:list<DEVONthink record (class 'record' / DTrc)> records to process.
-- Return: none (side effects only).
on processDocuments(theRecords)
	set logCtx to my initialize("processDocuments")
	logger's trace(logCtx, "enter")

	logger's debug(logCtx, "Number of Records: " & length of theRecords)

	my classifyRecords(theRecords)
	my updateRecordsMetadata(theRecords)

	logger's trace(logCtx, "exit")
end processDocuments

-- Rebuilds dimensions from DEVONthink and writes the filesystem cache.
-- Parameters:
--    theDatabase:DEVONthink database (class 'database' / DTkb) database context used by the operation.
-- Return: none (side effects only).
on refreshDimensionsCache(theDatabase)
	set logCtx to my initialize("refreshDimensionsCache")
	logger's trace(logCtx, "enter")

	if pDimensionsCachePath is missing value or pDimensionsCachePath is "" then
		tell application id "DNtp" to set theDatabaseName to name of theDatabase
		set configurationFile to baseLib's loadConfiguration(pDatabaseConfigurationFolder, theDatabaseName)
		set pDimensionsCachePath to baseLib's resolveDimensionsCachePath(configurationFile, theDatabaseName, pDatabaseConfigurationFolder)
	end if

	set dimensionsDictionary to my buildDimensionsDictionaryFromDEVONthink(theDatabase)

	baseLib's writeDimensionsCache(pDimensionsCachePath, dimensionsDictionary)
	set pDimensionsDictionary to dimensionsDictionary

	logger's trace(logCtx, "exit")
end refreshDimensionsCache

-- Removes trailing bracket blocks from a string value.
-- Parameters:
--    theString:text string value to normalize.
-- Return: text computed result.
on removeTrailingBracketBlocks(theString)
	set logCtx to my initialize("removeTrailingBracketBlocks")
	logger's trace(logCtx, "enter > " & theString)

	set NSString to current application's NSString's stringWithString:theString

	-- rechts trimmen
	set trimmed to NSString's stringByTrimmingCharactersInSet:(current application's NSCharacterSet's whitespaceAndNewlineCharacterSet())

	-- [Text]-Blöcke am Ende entfernen (inkl. Leerzeichen davor)
	set cleaned to trimmed's stringByReplacingOccurrencesOfString:"(\\s*\\[[^\\[\\]]*\\])+$" withString:"" options:(current application's NSRegularExpressionSearch) range:{0, trimmed's |length|()}
	set cleaned to cleaned as text

	logger's trace(logCtx, "exit > " & cleaned)
	return cleaned
end removeTrailingBracketBlocks

-- Replaces date placeholders in a template string.
-- Parameters:
--    theDate:date date value used for placeholder replacement.
--    theTemplate:text template text containing placeholders.
-- Return: text computed result.
on replaceDatePlaceholder(theDate, theTemplate)
	set logCtx to my initialize("replaceDatePlaceholder")
	logger's trace(logCtx, "enter > theDate: " & theDate & "; theTemplate: " & theTemplate)

	set theModifiedTemplate to theTemplate
	if theTemplate contains "{Year}" or theTemplate contains "{Month}" or theTemplate contains "{Day}" then

		tell application id "DNtp"

			set theDay to my twoDigit(day of theDate)
			set theMonth to my twoDigit(month of theDate as integer)
			set theYear to year of theDate as rich text

			set theModifiedTemplate to my replaceText("{Year}", theYear, theModifiedTemplate)
			set theModifiedTemplate to my replaceText("{Month}", theMonth, theModifiedTemplate)
			set theModifiedTemplate to my replaceText("{Day}", theDay, theModifiedTemplate)

		end tell
	end if

	logger's trace(logCtx, "exit > " & theModifiedTemplate)
	return theModifiedTemplate
end replaceDatePlaceholder

-- Replaces dimension placeholders in a template string.
-- Parameters:
--    theDimensions:list<text> dimension keys used for placeholder replacement.
--    theFields:NSMutableDictionary field dictionary used for value lookup.
--    theTemplate:text template text containing placeholders.
-- Return: text computed result.
on replaceDimensionPlaceholders(theDimensions, theFields, theTemplate)
	set logCtx to my initialize("replaceDimensionPlaceholders")
	logger's trace(logCtx, "enter")

	set theModifiedTemplate to theTemplate
	repeat with aDimension in theDimensions

		if (theModifiedTemplate as string) contains ("[" & aDimension & "]" as string) then

			tell logger to debug(logCtx, "aDimension: " & aDimension)

			set theValue to (theFields's objectForKey:aDimension) as string

			-- Replace Month to double-digit
			set theReplacedValue to (monthsByName's objectForKey:theValue)
			if theReplacedValue is not missing value then set theValue to theReplacedValue as string

			if theValue is missing value then set theValue to ""
			set thePlaceholder to "[" & aDimension & "]"
			set theModifiedTemplate to my replaceText(thePlaceholder, theValue, theModifiedTemplate)
		end if
	end repeat

	logger's trace(logCtx, "exit > " & theModifiedTemplate)
	return theModifiedTemplate
end replaceDimensionPlaceholders

-- Replaces special field placeholders in a template string.
-- Parameters:
--    thePlaceholder:text placeholder token to replace.
--    theFields:NSMutableDictionary field dictionary used for value lookup.
--    theTemplate:text template text containing placeholders.
-- Return: text computed result.
on replaceFieldPlaceholder(thePlaceholder, theFields, theTemplate)
	set logCtx to my initialize("replaceFieldPlaceholder")
	logger's trace(logCtx, "enter")

	set theModifiedTemplate to theTemplate

	if thePlaceholder is equal to "{Decades}" then

		if (theTemplate as string) contains (thePlaceholder as string) then

			set theYear to theFields's objectForKey:(first item of pDateDimensions)

			set theYearAsInteger to theYear as integer
			set theValue to ""
			if theYearAsInteger ≥ 1990 and theYearAsInteger ≤ 1999 then
				set theValue to "1990-1999/"
			else if theYearAsInteger ≥ 2000 and theYearAsInteger ≤ 2009 then
				set theValue to "2000-2009/"
			else if theYearAsInteger ≥ 2010 and theYearAsInteger ≤ 2019 then
				set theValue to "2010-2019/"
			end if

			set theModifiedTemplate to my replaceText(thePlaceholder, theValue, theModifiedTemplate)
		end if

	end if

	logger's trace(logCtx, "exit > " & theModifiedTemplate)
	return theModifiedTemplate
end replaceFieldPlaceholder

-- Replaces all occurrences of a substring in a source string.
-- Parameters:
--    findText:text substring to search for.
--    replaceText:text replacement substring.
--    sourceText:text source text to transform.
-- Return: text computed result.
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

-- Extracts stable UUIDs from DEVONthink records for worker handoff.
-- Parameters:
--    theRecords:list<DEVONthink record (class 'record' / DTrc)> records to transform.
-- Return: list<text> UUID values.
on recordUUIDsFromRecords(theRecords)
	if class of theRecords is not list then return {}
	set recordUUIDs to {}
	tell application id "DNtp"
		repeat with theRecord in theRecords
			try
				set theUUID to uuid of theRecord
				if theUUID is not missing value and theUUID is not "" then set end of recordUUIDs to theUUID as rich text
			end try
		end repeat
	end tell
	return recordUUIDs
end recordUUIDsFromRecords

-- Resolves worker arguments back to DEVONthink record objects.
-- Parameters:
--    argv:list command-line arguments passed by AppleScript/osascript.
-- Return: list<DEVONthink record (class 'record' / DTrc)> records resolved from UUID flags.
on recordsFromWorkerArgs(argv)
	if class of argv is not list then return {}
	set recordUUIDs to {}
	set argCount to count of argv
	set argIndex to 1
	repeat while argIndex ≤ argCount
		set anArg to item argIndex of argv
		try
			set argText to anArg as text
		on error
			set argText to ""
		end try
		if argText is "--record-uuid" then
			set argIndex to argIndex + 1
			if argIndex ≤ argCount then set end of recordUUIDs to (item argIndex of argv as text)
		end if
		set argIndex to argIndex + 1
	end repeat

	if recordUUIDs is {} then return {}

	set resolvedRecords to {}
	tell application id "DNtp"
		repeat with aUUID in recordUUIDs
			try
				set theRecord to get record with uuid (aUUID as rich text)
				if theRecord is not missing value then set end of resolvedRecords to theRecord
			end try
		end repeat
	end tell
	return resolvedRecords
end recordsFromWorkerArgs

-- Central entrypoint for DEVONthink menu scripts with optional worker execution.
-- Parameters:
--    argv:list command-line arguments passed by AppleScript/osascript.
--    commandKey:text logical DEVONthink menu command identifier.
-- Return: none (side effects only).
on runCommand(argv, commandKey)
	set config to load script (POSIX path of (path to home folder) & ".mailscripts/config.scpt")

	if my shouldUseWorker(argv, config, commandKey) then
		set scriptPath to POSIX path of (path to me)
		my launchWorker(scriptPath)
		return
	end if

	set traceName to "DEVONthink Menu/" & commandKey
	set traceStarted to false
	try
		if my isTraceCommand(commandKey) then
			my beginPerformanceTrace(traceName)
			set traceStarted to true
		end if

		my runMenuCommand(commandKey, config)

		if traceStarted then
			my finishPerformanceTrace(traceName)
			set traceStarted to false
		end if
	on error errorMessage number errorNumber
		if traceStarted then
			try
				my finishPerformanceTrace(traceName)
			end try
		end if
		display alert "DEVONthink" message (errorMessage & " (" & errorNumber & ")") as warning
	end try
end runCommand

-- Executes one DEVONthink menu command by logical key.
-- Parameters:
--    commandKey:text logical DEVONthink menu command identifier.
--    config:script object loaded global config.
-- Return: none (side effects only).
on runMenuCommand(commandKey, config)
	set logCtx to my initialize("runMenuCommand")
	logger's trace(logCtx, "enter > " & commandKey)

	if commandKey is "archive" then
		set theSelection to my selectedRecordsOrError()
		my archiveRecords(theSelection)
	else if commandKey is "classify" then
		set theSelection to my selectedRecordsOrError()
		my classifyRecords(theSelection)
	else if commandKey is "import_mail" then
		my importMailMessages(pPrimaryEmailDatabase of config)
	else if commandKey is "open_context" then
		tell application id "DNtp"
			set theSelection to every selected record
		end tell
		set theSmartGroupSpecifier to {dimension:"06 Context", customMetadataField:"", smartgroupsFolder:"03 Resources/Context"}
		my openSmartGroup(theSmartGroupSpecifier, theSelection)
	else if commandKey is "open_label" then
		tell application id "DNtp"
			set theSelection to every selected record
		end tell
		set theSmartGroupSpecifier to {smartgroupsFolder:"03 Resources/Label"}
		my openLabelSmartGroup(theSmartGroupSpecifier, theSelection)
	else if commandKey is "open_sender" then
		tell application id "DNtp"
			set theSelection to every selected record
		end tell
		set theSmartGroupSpecifier to {dimension:"04 Sender", customMetadataField:"sender", smartgroupsFolder:"03 Resources/Sender"}
		my openSmartGroup(theSmartGroupSpecifier, theSelection)
	else if commandKey is "open_subject" then
		tell application id "DNtp"
			set theSelection to every selected record
		end tell
		set theSmartGroupSpecifier to {dimension:"05 Subject", customMetadataField:"subject", smartgroupsFolder:"03 Resources/Subject"}
		my openSmartGroup(theSmartGroupSpecifier, theSelection)
	else if commandKey is "open_year" then
		tell application id "DNtp"
			set theSelection to every selected record
		end tell
		set theSmartGroupSpecifier to {dimension:"03 Year", customMetadataField:"date", smartgroupsFolder:"03 Resources/Year"}
		my openSmartGroup(theSmartGroupSpecifier, theSelection)
	else if commandKey is "update_dimensions_cache" then
		set theDatabase to my resolveActiveDatabase()
		if theDatabase is missing value then error "No current database available."
		my updateDimensionsCache(theDatabase)
	else if commandKey is "update_metadata" then
		set theSelection to my selectedRecordsOrError()
		my updateRecordsMetadata(theSelection)
	else if commandKey is "verify_records" then
		my verifyTags("/05 Files")
	else
		error "Unsupported DEVONthink menu command: " & commandKey
	end if

	logger's trace(logCtx, "exit")
end runMenuCommand

-- Central entrypoint for DEVONthink smart-rule scripts with optional worker execution.
-- Parameters:
--    theRecords:list<DEVONthink record (class 'record' / DTrc)> records passed by performSmartRule.
--    argv:list command-line arguments passed by AppleScript/osascript.
--    commandKey:text logical smart-rule command identifier.
-- Return: none (side effects only).
on runSmartRuleCommand(theRecords, argv, commandKey)
	set config to load script (POSIX path of (path to home folder) & ".mailscripts/config.scpt")

	if my shouldUseWorker(argv, config, commandKey) then
		set recordUUIDs to my recordUUIDsFromRecords(theRecords)
		if recordUUIDs is {} then return
		set scriptPath to POSIX path of (path to me)
		my launchWorkerForSmartRule(scriptPath, commandKey, recordUUIDs)
		return
	end if

	set effectiveRecords to theRecords
	if class of effectiveRecords is not list then set effectiveRecords to my recordsFromWorkerArgs(argv)
	if class of effectiveRecords is not list then set effectiveRecords to {}

	my runSmartRuleCommandByKey(commandKey, effectiveRecords)
end runSmartRuleCommand

-- Executes one DEVONthink smart-rule command by logical key.
-- Parameters:
--    commandKey:text logical smart-rule command identifier.
--    theRecords:list<DEVONthink record (class 'record' / DTrc)> records to process.
-- Return: none (side effects only).
on runSmartRuleCommandByKey(commandKey, theRecords)
	if commandKey is "smart_classify" then
		my classifyRecords(theRecords)
		return
	end if
	if commandKey is "smart_process_documents" then
		my processDocuments(theRecords)
		return
	end if
	if commandKey is "smart_update_metadata" then
		my updateRecordsMetadata(theRecords)
		return
	end if
	error "Unknown smart-rule command key: " & commandKey
end runSmartRuleCommandByKey

-- Returns selected DEVONthink records as a concrete non-empty list.
-- Parameters: none.
-- Return: list<DEVONthink record (class 'record' / DTrc)> current selection.
on selectedRecordsOrError()
	tell application id "DNtp"
		set theSelection to every selected record
	end tell
	if (count of theSelection) is 0 then error "Please select some contents."
	return theSelection
end selectedRecordsOrError

-- Resolves the active DEVONthink database from current window context.
-- Parameters: none.
-- Return: DEVONthink database (class 'database' / DTkb)|missing value resolved database context.
on resolveActiveDatabase()
	set logCtx to my initialize("resolveActiveDatabase")
	logger's trace(logCtx, "enter")

	set theDatabase to missing value
	tell application id "DNtp"
		try
			set theDatabase to get current database
		end try
		if theDatabase is missing value then
			try
				set theCurrentGroup to get current group
				if theCurrentGroup is not missing value then set theDatabase to database of theCurrentGroup
			end try
		end if
	end tell

	logger's trace(logCtx, "exit")
	return theDatabase
end resolveActiveDatabase

-- Resolves the smart group value and predicate source for a record.
-- Parameters:
--    theSmartGroupSpecifier:record with dimension:text and customMetadataField:text.
--    theRecord:DEVONthink record (class 'record' / DTrc) record used for lookup.
-- Return: record with value:text and conditionField:text.
on resolveSmartGroupInfoForRecord(theSmartGroupSpecifier, theRecord)
	set logCtx to my initialize("resolveSmartGroupInfoForRecord")
	logger's trace(logCtx, "enter")

	set theDimension to dimension of theSmartGroupSpecifier
	set customMetadataField to customMetadataField of theSmartGroupSpecifier
	set smartGroupConditionField to pSmartGroupConditionTags

	set theFields to my fieldsFromTags(theRecord, true)
	set theValue to theFields's objectForKey:theDimension

	if theValue is missing value then
		tell application id "DNtp" to set theValue to get custom meta data for customMetadataField from theRecord
		set smartGroupConditionField to pSmartGroupConditionCustomMetadata
	end if

	if theValue is missing value then error "No value found for smart group dimension '" & theDimension & "' or custom metadata field '" & customMetadataField & "'."
	set theValue to theValue as string
	if theValue is "" or theValue is "missing value" then error "No value found for smart group dimension '" & theDimension & "' or custom metadata field '" & customMetadataField & "'."

	logger's debug(logCtx, "Smart group value: " & theValue & ", conditionField: " & smartGroupConditionField)
	logger's trace(logCtx, "exit")
	return {value:theValue, conditionField:smartGroupConditionField}
end resolveSmartGroupInfoForRecord

-- Computes and writes a custom metadata value when required.
-- Parameters:
--    theIndex:integer index of the configured metadata field.
--    theRecord:DEVONthink record (class 'record' / DTrc) record to process.
--    theFields:NSMutableDictionary field dictionary used for value lookup.
--    theSupplemental:text supplemental text value.
--    theSupplementalAction:text (ADD|REPLACE) supplemental merge mode.
-- Return: none (side effects only).
on setCustomMetadata(theIndex, theRecord, theFields, theSupplemental, theSupplementalAction)
	set logCtx to my initialize("setCustomMetadata")
	logger's trace(logCtx, "enter > theIndex: " & theIndex & "; theSupplemental: " & theSupplemental & "; theSupplementalAction: " & theSupplementalAction)

	set theField to item theIndex of pCustomMetadataFields
	set theDimension to item theIndex of pCustomMetadataDimensions
	set theType to item theIndex of pCustomMetadataTypes
	set theTemplate to item theIndex of pCustomMetadataTemplates
	logger's debug(logCtx, "theField: " & theField & "; theDimension: " & theDimension & "; theType: " & theType & "; theTemplate: " & theTemplate)

	tell application id "DNtp"
		set currentValue to get custom meta data for theField from theRecord
		set currentAmount to get custom meta data for first item of pCustomMetadataFields from theRecord
		if currentAmount is not missing value then set currentAmount to (pAmountFormatter's stringFromNumber:currentAmount) as rich text
	end tell

	set newValue to missing value
	if theType is equal to "DATE" then

		if currentValue is not missing value then
			set currentValue to baseLib's date_to_iso(currentValue)
		end if

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
				if pAmountLookupCategories contains aValue then
					tell application id "DNtp"
						set newValue to document amount of theRecord
					end tell
				end if
			end repeat
		end if

	else if theType is equal to "TEXT" then

		set newValue to currentValue

		set theCategory to theFields's objectForKey:theDimension
		if theCategory is missing value then set theCategory to ""
		set theCategory to my tagAlias(theCategory)

		-- Custom Metadata Value von Template initialisieren - nachfolgend werden alle Placeholder ersetzt
		set cmdValue to theTemplate

		-- Replace marker placeholder "[[...]]"
		repeat with aDimension in pDimensionsDictionary's allKeys()
			if (cmdValue as string) contains ("[[" & aDimension & "]]" as string) then
				set theReplaceText to ""
				set theTag to (theFields's objectForKey:aDimension)
				if theTag is missing value then
				else if (theTag's isKindOfClass:(current application's NSString)) as boolean then
					set theReplaceText to theReplaceText & "[" & my tagAlias(theTag) & "]"
				else if (theTag's isKindOfClass:(current application's NSArray)) as boolean then
					repeat with aTag in theTag
						set theReplaceText to theReplaceText & " [" & aTag & "]"
					end repeat
				end if
				set thePlaceholder to "[[" & aDimension & "]]"
				set cmdValue to my replaceText(thePlaceholder as string, theReplaceText as string, cmdValue as string)
			end if
		end repeat

		-- Replace category placeholder "[...]"
		repeat with aDimension in pDimensionsDictionary's allKeys()
			if (cmdValue as string) contains ("[" & aDimension & "]" as string) then
				set theReplaceText to my tagAlias((theFields's objectForKey:aDimension))
				if aDimension as string is equal to theDimension as string then
					set theReplaceText to theCategory
				else
					if theReplaceText is missing value then
						set theReplaceText to ""
					else
						set theReplaceText to "[" & theReplaceText & "]"
					end if
				end if
				set thePlaceholder to "[" & aDimension & "]"
				set cmdValue to my replaceText(thePlaceholder as string, theReplaceText as string, cmdValue as string)
			end if
		end repeat

		-- Replace custom text placeholder "{Text}"
		set customText to my extractCustomTextFromCmdValue(currentValue)
		if customText is equal to "" and pContentType is equal to "EMAILS" then
			set customText to mailLib's getCustomMetadata(theRecord, theField)
		end if

		-- Add new Custom Text (Supplemental) to the right-hand side
		if theSupplemental is not missing value and theSupplemental is not "" then
			if theSupplementalAction is not missing value and theSupplementalAction is equal to "REPLACE" then
				set customText to theSupplemental
			else
				if length of customText > 0 then
					set customText to customText & " "
				end if
				set customText to customText & theSupplemental
			end if
		end if

		-- Add field separator to custom text - only when custom text is set and a Dimension is set
		if length of customText > 0 and (count of words of cmdValue) > 1 then
			set customText to pCustomMetadataFieldSeparator & customText
		end if

		set cmdValue to my replaceText("{Text}", customText, cmdValue as string)

		-- Replace amount placeholder "{Amount}"
		set amountText to ""
		if currentAmount is not missing value then set amountText to "[EUR " & currentAmount & "]"
		set cmdValue to my replaceText("{Amount}", amountText, cmdValue as string)

		set newValue to cmdValue
	end if

	set newValue to baseLib's trim(newValue)
	set newValue to baseLib's collapseSpaces(newValue)
	if newValue as string is not equal to currentValue as string then
		tell logger to info_r(theRecord, "Field '" & theField & "' changed from: \"" & currentValue & "\" to: \"" & newValue & "\"")
		tell application id "DNtp"
			add custom meta data newValue for theField to theRecord
		end tell
	end if

	logger's trace(logCtx, "exit")
end setCustomMetadata

-- Ensures date tags are set from the selected classification date.
-- Parameters:
--    theRecord:DEVONthink record (class 'record' / DTrc) record to process.
--    theFields:NSMutableDictionary field dictionary used for value lookup.
--    theClassificationDate:text configured classification date source.
-- Return: none (side effects only).
on setDateTags(theRecord, theFields, theClassificationDate)
	set logCtx to my initialize("setDateTags")
	logger's trace(logCtx, "enter")

	set theYear to theFields's objectForKey:(first item of pDateDimensions)
	set theMonth to theFields's objectForKey:(second item of pDateDimensions)
	set theDay to theFields's objectForKey:(third item of pDateDimensions)
	-- logger's trace(logCtx, "theYear: " & theYear & ", theMonth: " & theMonth & ", theDay: " & theDay)

	-- Date Tags will not be set if Year, Month or Day is already set
	if theYear is not missing value or theMonth is not missing value or theDay is not missing value then

		if theYear is not missing value then tell logger to debug(logCtx, "Year already set to: " & theYear)
		if theMonth is not missing value then tell logger to debug(logCtx, "Month already set to: " & theMonth)
		if theDay is not missing value then tell logger to debug(logCtx, "Day already set to: " & theDay)
	else

		tell application id "DNtp"

			set theDate to my getClassificationDate(theRecord, theClassificationDate)
			set theDay to my twoDigit(day of theDate)
			set theMonth to my twoDigit(month of theDate as integer)
			set theYear to year of theDate as rich text

			set theMonthAsSting to (monthsByDigit's objectForKey:theMonth) as rich text
			set tags of theRecord to tags of theRecord & {theDay, theMonthAsSting, theYear}

		end tell

	end if

	logger's trace(logCtx, "exit")
end setDateTags

-- Assigns a tag to a matching dimension while enforcing cardinality rules.
-- Parameters:
--    theTag:text tag value to evaluate.
--    theFields:NSMutableDictionary field dictionary used for value lookup.
--    interactiveMode:boolean whether interactive fallback handling is enabled.
--    theRecord:DEVONthink record (class 'record' / DTrc) record to process.
-- Return: list{boolean, NSMutableDictionary} computed result.
on setField(theTag, theFields, interactiveMode, theRecord)
	set logCtx to my initialize("setField")
	logger's trace(logCtx, "entry > theTag: " & theTag)

	set hasFieldBeenSet to false
	tell application id "DNtp"

		set allDimensions to pDimensionsDictionary's allKeys()
		repeat with aDimension in allDimensions
			set categories to (pDimensionsDictionary's objectForKey:aDimension) as list
			if categories contains theTag then
				set theCardinality to (pDimensionsConstraintsDictionary's objectForKey:aDimension)
				logger's debug(logCtx, "theCardinality: " & theCardinality)

				set setCurrentValue to (theFields's objectForKey:aDimension)
				if setCurrentValue is missing value then
					(theFields's setObject:theTag forKey:aDimension)
				else
					if theCardinality is not missing value and theCardinality as integer > 0 then
						set theMessage to "Cardinality error at dimension '" & aDimension & "' for record: " & name of theRecord
						logger's info_r(theRecord, theMessage)
						if interactiveMode then error theMessage
					else
						(theFields's setObject:{setCurrentValue, theTag} forKey:aDimension)
					end if
				end if
				set hasFieldBeenSet to true
			end if
		end repeat

	end tell

	logger's trace(logCtx, "exit")
	return {hasFieldBeenSet, theFields}
end setField

-- Sets the record comment from a selected field value.
-- Parameters:
--    theField:text field name used for comment generation.
--    theRecord:DEVONthink record (class 'record' / DTrc) record to process.
-- Return: none (side effects only).
on setFinderComment(theField, theRecord)
	set logCtx to my initialize("setFinderComment")
	logger's trace(logCtx, "enter > " & theField)

	tell application id "DNtp"

		set theValue to get custom meta data for theField from theRecord

		if theValue is not missing value then
			set wordCount to count of words of theValue
			if wordCount > 1 then
				set finderComment to comment of theRecord
				if finderComment is not "" then
					set finderComment to finderComment & ", " & linefeed
				end if
				set finderComment to finderComment & theValue
				set comment of theRecord to finderComment
			end if
		end if

	end tell

	logger's trace(logCtx, "exit")
end setFinderComment

-- Computes and applies the record name from the configured template.
-- Parameters:
--    theRecord:DEVONthink record (class 'record' / DTrc) record to process.
--    theFields:NSMutableDictionary field dictionary used for value lookup.
-- Return: none (side effects only).
on setName(theRecord, theFields)
	set logCtx to my initialize("setName")
	logger's trace(logCtx, "enter")

	set allDimensions to pDimensionsDictionary's allKeys()
	set theName to my replaceDimensionPlaceholders(allDimensions, theFields, pNameTemplate)

	set currentName to name of theRecord
	if theName as string is not equal to currentName as string then
		tell logger to info_r(theRecord, "Name changed from: " & currentName & " to: " & theName)
		set name of theRecord to theName
	end if

	logger's trace(logCtx, "exit")
end setName

-- Generates and assigns a unique asset name.
-- Parameters:
--    theRecord:DEVONthink record (class 'record' / DTrc) record to process.
--    f:record/dictionary mit tagYear, tagMonth, tagDay, tagSender field record used for asset naming.
-- Return: none (side effects only).
on setNameForAsset(theRecord, f)
	set logCtx to my initialize("setNameForAsset")
	logger's trace(logCtx, "enter")

	set {logicalYear, logicalMonth, logicalDay, theSender} to {tagYear of f, tagMonth of f, tagDay of f, tagSender of f}
	set {theName, technicalDate, logicalDate} to {missing value, missing value, missing value}

	tell application id "DNtp"

		-- das technische Datum wird aus "Creation Date" ermittelt (Datum und Uhrzeit)
		tell baseLib to set technicalDate to format(my creationDateFromMetadata(theRecord))

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

-- Transfers a matching tag from the best compare record above threshold.
-- Parameters:
--    theRecord:DEVONthink record (class 'record' / DTrc) record to process.
--    theDatabase:DEVONthink database (class 'database' / DTkb) database context used by the operation.
--    theFields:NSMutableDictionary field dictionary used for value lookup.
--    theDimension:text dimension key used for lookup and routing.
-- Return: none (side effects only).
on setTagFromCompareRecord(theRecord, theDatabase, theFields, theDimension)
	set logCtx to my initialize("setTagFromCompareRecord")
	logger's trace(logCtx, "enter > theDimension: " & theDimension)

	set theValue to theFields's objectForKey:theDimension
	if theValue is not missing value then
		tell logger to debug(logCtx, "Dimension '" & theDimension & "' already set to: " & theValue)

	else
		tell application id "DNtp"

			set theComparedRecords to compare record theRecord to theDatabase
			repeat with aCompareRecord in theComparedRecords

				if location of aCompareRecord starts with "/05" and (uuid of theRecord is not equal to uuid of aCompareRecord) then
					set theScore to score of aCompareRecord
					if theScore < pCompareDimensionsScoreThreshold then
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

-- Returns true when a command should run in-process to keep chooser dialogs focused.
-- Parameters:
--    commandKey:text logical DEVONthink menu command identifier.
-- Return: boolean true when worker relaunch should be skipped.
on shouldRunInProcess(commandKey)
	-- `choose from list` dialogs can lose keyboard focus when executed via osascript worker.
	-- Keep interactive smart-group commands in-process to allow direct keyboard continuation.
	if commandKey is "open_context" then return true
	if commandKey is "open_label" then return true
	if commandKey is "open_sender" then return true
	if commandKey is "open_subject" then return true
	if commandKey is "open_year" then return true
	return false
end shouldRunInProcess

-- Evaluates global worker configuration and current invocation mode.
-- Parameters:
--    argv:list command-line arguments passed by AppleScript/osascript.
--    config:script object loaded global config.
--    commandKey:text logical DEVONthink menu command identifier.
-- Return: boolean true when worker relaunch should be used.
on shouldUseWorker(argv, config, commandKey)
	set useWorker to true
	try
		set useWorker to pUseWorker of config
	on error
		set useWorker to true
	end try
	if not useWorker then return false
	if my hasWorkerFlag(argv) then return false
	if my shouldRunInProcess(commandKey) then return false
	return true
end shouldUseWorker

-- Reads a subject value from metadata for supported records.
-- Parameters:
--    theRecord:DEVONthink record (class 'record' / DTrc) record to process.
--    theSender:text|missing value sender value used for metadata lookup.
-- Return: text|missing value computed result.
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

-- Returns the configured alias for a tag when available.
-- Parameters:
--    theTag:text tag value to evaluate.
-- Return: text computed result.
on tagAlias(theTag)
	set logCtx to my initialize("tagAlias")
	logger's trace(logCtx, "enter")

	set theValue to theTag
	set theAlias to (tagAliases's objectForKey:theTag)
	if theAlias is not missing value then
		set theValue to theAlias
	end if

	logger's trace(logCtx, "exit")
	return theValue
end tagAlias

-- Formats a value as a two-digit string.
-- Parameters:
--    d:integer|text value to format as two digits.
-- Return: text computed result.
on twoDigit(d)
	set logCtx to my initialize("twoDigit")
	logger's trace(logCtx, "enter")
	set theResult to text -2 thru -1 of ("00" & d)
	logger's trace(logCtx, "exit > " & theResult)
	return theResult
end twoDigit

-- Explicitly refreshes the dimensions cache for a database.
-- Parameters:
--    theDatabase:DEVONthink database (class 'database' / DTkb) target database.
-- Return: none (side effects only).
on updateDimensionsCache(theDatabase)
	set logCtx to my initialize("updateDimensionsCache")
	tell application id "DNtp" to set theDatabaseName to name of theDatabase
	logger's trace(logCtx, "enter > " & theDatabaseName)

	my initializeDatabaseConfiguration(theDatabase)
	my refreshDimensionsCache(theDatabase)

	logger's trace(logCtx, "exit")
end updateDimensionsCache

-- Updates record names, custom metadata, and comments from derived fields.
-- Parameters:
--    theRecords:list<DEVONthink record (class 'record' / DTrc)> records to process.
-- Return: none (side effects only).
on updateRecordsMetadata(theRecords)
	set logCtx to my initialize("updateRecordsMetadata")
	if not pPerformanceTraceManagedByCaller then logger's resetTraceMetrics()
	logger's trace(logCtx, "enter")

	tell application id "DNtp"

		set theDatabase to database of first item of theRecords

		my initializeDatabaseConfiguration(theDatabase)
		set {recordsSelected, recordsProcessed} to {0, 0}
		repeat with theRecord in theRecords
			set recordsSelected to recordsSelected + 1
			set tagFields to my fieldsFromTags(theRecord, true)

			if not my existDimension(tagFields, pDateDimensions) then
				tell logger to info_r(theRecord, "Can't update metadata due to missing Date tag(s).")
			else
				set recordsProcessed to recordsProcessed + 1

				-- Set Name
				if pNameTemplate is not missing value and pNameTemplate is not "" then
					my setName(theRecord, tagFields)
				end if

				-- Set Custom Metadata
				set customMetadataFieldIndex to 0
				repeat with aCustomMetadataField in pCustomMetadataFields
					set customMetadataFieldIndex to customMetadataFieldIndex + 1
					my setCustomMetadata(customMetadataFieldIndex, theRecord, tagFields, "", "")
				end repeat

				-- Set Comments
				if length of pCommentsFields > 0 then
					set comment of theRecord to ""
					repeat with aFinderCommentsField in pCommentsFields
						my setFinderComment(aFinderCommentsField, theRecord)
					end repeat
				end if
			end if
		end repeat

		tell logger to info(logCtx, "Records selected: " & recordsSelected & ", Records processed:  " & recordsProcessed)
	end tell

	logger's trace(logCtx, "exit")
	if not pPerformanceTraceManagedByCaller then logger's logTraceMetrics()
end updateRecordsMetadata

-- Validates tag consistency for records at a location and logs metrics.
-- Parameters:
--    theLocation:text (DEVONthink location prefix, z.B. '/05 Files') location prefix to validate.
-- Return: none (side effects only).
on verifyTags(theLocation)
	set logCtx to my initialize("verifyTags")
	logger's trace(logCtx, "enter")

	tell application id "DNtp"
		set currentDatabase to current database
		my initializeDatabaseConfiguration(currentDatabase)

		set theRecords to every content of currentDatabase whose location begins with theLocation
		tell logger to info(logCtx, "Verification started for Database: " & (name of currentDatabase as string) & ", Location: " & theLocation & ¬
			", Number of Records: " & (length of theRecords as string))

		set {issueRecords, issues, totalPages} to {0, 0, 0}
		repeat with theRecord in theRecords
			logger's debug(logCtx, " " & name of theRecord)

			set {theYear, theMonth, theDay, theSender, theSubject, pIssueCount} to {null, null, null, null, null, 0}
			if type of theRecord is PDF document then set totalPages to totalPages + (page count of theRecord)

			set theFields to my fieldsFromTags(theRecord, false)
			-- set allDimensionConstraints to pDimensionsConstraintsDictionary's allKeys()
			-- repeat with aDimensionName in allDimensionConstraints
			-- 	set theCardinality to (pConstraintsDictionary's objectForKey:aDimensionName)
			-- 	set theCategories to (theFields's objectForKey:aDimensionName)
			--
			-- 	if theCategories is missing value then
			-- 		my logIssue(theRecord, true, "No category found for dimension '" & theDimension & "'.")
			-- 	else
			-- 		if theCount = 1 then
			-- 			if not (theCategories's isKindOfClass:(current application's NSString)) as boolean then
			-- 				set logtext to theCategories as list
			-- 				my logIssue(theRecord, true, "More than 1 category found for dimension '" & theDimension & "': " & logtext)
			-- 			end if
			-- 			-- else if (setCategories's isKindOfClass:(current application's NSArray)) as boolean
			-- 		end if
			-- 	end if
			-- end repeat
			--
			-- if pIssueCount > 0 then
			-- 	set issueRecords to issueRecords + 1
			-- 	set issues to issues + pIssueCount
			-- end if
		end repeat
		tell logger to info(logCtx, "Verification finished - Records with Issues: " & issueRecords & ", Total Issues: " & issues & ", Total Pages (PDF only): " & totalPages)
	end tell
	logger's trace(logCtx, "exit")
end verifyTags
