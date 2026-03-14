#@osa-lang:AppleScript
use AppleScript version "2.4"
use framework "Foundation"
use scripting additions

on assertFilenameHasExtension(recordFilename, messageText, testLib)
	testLib's assertTrue((recordFilename contains "."), messageText)
end assertFilenameHasExtension

on buildExpectedCommentFromFields(theRecord, commentFields)
	set expectedComment to ""

	tell application id "DNtp"
		repeat with aField in commentFields
			set fieldName to aField as rich text
			set theValue to get custom meta data for fieldName from theRecord
			if theValue is not missing value then
				set valueText to theValue as rich text
				if (count of words of valueText) > 1 then
					if expectedComment is not "" then set expectedComment to expectedComment & ", " & linefeed
					set expectedComment to expectedComment & valueText
				end if
			end if
		end repeat
	end tell

	return expectedComment
end buildExpectedCommentFromFields

on captureCustomMetadataValues(theRecord, fieldNames)
	set capturedValues to {}
	tell application id "DNtp"
		repeat with aField in fieldNames
			set fieldName to aField as rich text
			set fieldValue to get custom meta data for fieldName from theRecord
			set end of capturedValues to {fieldName:fieldName, fieldValue:fieldValue}
		end repeat
	end tell
	return capturedValues
end captureCustomMetadataValues

on findRecordByFilenameInDatabase(recordFilename, databaseName)
	set lookupName to my recordNameFromFilename(recordFilename)
	set matchingRecords to {}

	tell application id "DNtp"
		set lookupDatabase to missing value
		try
			set lookupDatabase to database databaseName
		on error
			error "No database found with exact name: " & databaseName
		end try

		set matchingRecords to every content of lookupDatabase whose name is lookupName
	end tell

	set matchesCount to count of matchingRecords
	if matchesCount is 0 then error "No record found in database '" & databaseName & "' for filename '" & recordFilename & "' (lookup name: '" & lookupName & "')."
	if matchesCount > 1 then error "Multiple records found in database '" & databaseName & "' for filename '" & recordFilename & "' (lookup name: '" & lookupName & "')."

	set matchedRecord to first item of matchingRecords
	tell application id "DNtp"
		set matchedFilename to filename of matchedRecord
	end tell
	if matchedFilename as text is not recordFilename then
		error "Found record by name '" & lookupName & "', but filename differs. Expected '" & recordFilename & "', got '" & matchedFilename & "'."
	end if

	return matchedRecord
end findRecordByFilenameInDatabase

on normalizeTagList(theTags)
	set normalizedTags to {}
	if theTags is missing value then return normalizedTags
	repeat with aTag in theTags
		set end of normalizedTags to aTag as text
	end repeat
	return normalizedTags
end normalizeTagList

on recordNameFromFilename(recordFilename)
	set filenameText to recordFilename as text
	if filenameText does not contain "." then return filenameText

	set previousDelimiters to AppleScript's text item delimiters
	set AppleScript's text item delimiters to "."
	set filenameItems to text items of filenameText
	set itemsCount to count of filenameItems
	if itemsCount ≤ 1 then
		set AppleScript's text item delimiters to previousDelimiters
		return filenameText
	end if
	set nameItems to items 1 thru (itemsCount - 1) of filenameItems
	set AppleScript's text item delimiters to "."
	set lookupName to nameItems as text
	set AppleScript's text item delimiters to previousDelimiters
	return lookupName
end recordNameFromFilename

on restoreCustomMetadataValues(theRecord, metadataValues)
	tell application id "DNtp"
		repeat with aMetadataEntry in metadataValues
			set fieldName to fieldName of aMetadataEntry
			set fieldValue to fieldValue of aMetadataEntry

			if fieldValue is missing value then
				try
					add custom meta data missing value for fieldName to theRecord
				on error
					add custom meta data "" for fieldName to theRecord
				end try
			else
				add custom meta data fieldValue for fieldName to theRecord
			end if
		end repeat
	end tell
end restoreCustomMetadataValues

on restoreRecordState(theRecord, savedState)
	set originalTags to originalTags of savedState
	set originalName to originalName of savedState
	set originalComment to originalComment of savedState
	set originalCustomMetadataValues to originalCustomMetadataValues of savedState

	my restoreRecordTags(theRecord, originalTags)
	my restoreCustomMetadataValues(theRecord, originalCustomMetadataValues)

	tell application id "DNtp"
		set name of theRecord to originalName
		set comment of theRecord to originalComment
	end tell
end restoreRecordState

on restoreRecordTags(theRecord, originalTags)
	tell application id "DNtp"
		set normalizedTags to my normalizeTagList(originalTags)

		try
			set tags of theRecord to normalizedTags
			return
		end try

		-- Fallback for unstable bulk tag assignment in some DEVONthink states.
		set tags of theRecord to {}
		repeat with aTag in normalizedTags
			try
				set tags of theRecord to (tags of theRecord) & (aTag as rich text)
			end try
		end repeat
	end tell
end restoreRecordTags

on runNameCommentsPilotScenario(docLib, testLib, theRecord)
	tell application id "DNtp"
		set theDatabase to database of theRecord
	end tell

	docLib's initializeDatabaseConfiguration(theDatabase)

	set nameTemplate to docLib's pNameTemplate
	testLib's assertTrue((nameTemplate is not missing value and nameTemplate is not ""), "pNameTemplate must be configured for this test.")

	set commentsFields to docLib's pCommentsFields
	testLib's assertTrue(((count of commentsFields) > 0), "pCommentsFields must not be empty for this test.")

	set dateDimensions to docLib's pDateDimensions
	testLib's assertEquals((count of dateDimensions), 3, "pDateDimensions must contain exactly three entries: Year, Month, Day.")

	set yearDimension to first item of dateDimensions as text
	set monthDimension to second item of dateDimensions as text
	set dayDimension to third item of dateDimensions as text

	set tagFields to docLib's fieldsFromTags(theRecord, false)
	testLib's assertNotMissing((tagFields's objectForKey:yearDimension), "Precondition failed: Year dimension is missing.")
	testLib's assertNotMissing((tagFields's objectForKey:monthDimension), "Precondition failed: Month dimension is missing.")
	testLib's assertNotMissing((tagFields's objectForKey:dayDimension), "Precondition failed: Day dimension is missing.")

	set allDimensions to docLib's pDimensionsDictionary's allKeys()
	set expectedName to docLib's replaceDimensionPlaceholders(allDimensions, tagFields, nameTemplate)

	set sentinelName to "TC05_SENTINEL_NAME"
	set sentinelComment to "TC05_SENTINEL_COMMENT"
	tell application id "DNtp"
		set name of theRecord to sentinelName
		set comment of theRecord to sentinelComment
	end tell

	docLib's updateRecordsMetadata({theRecord})

	tell application id "DNtp"
		set actualName to name of theRecord
		set actualComment to comment of theRecord
	end tell

	set expectedComment to my buildExpectedCommentFromFields(theRecord, commentsFields)

	testLib's assertTrue((actualName as text is not sentinelName), "Sentinel name was not overwritten by updateRecordsMetadata.")
	testLib's assertTrue((actualComment as text is not sentinelComment), "Sentinel comment was not overwritten by updateRecordsMetadata.")
	testLib's assertEquals((actualName as text), (expectedName as text), "Updated record name does not match pNameTemplate output.")
	testLib's assertEquals((actualComment as text), (expectedComment as text), "Updated record comment does not match pCommentsFields reconstruction.")
end runNameCommentsPilotScenario

on runScenarioById(docLib, testLib, theRecord, scenarioId)
	if scenarioId is "pilot-name-comments" then
		my runNameCommentsPilotScenario(docLib, testLib, theRecord)
	else
		error "Unknown scenarioId: " & scenarioId
	end if
end runScenarioById

on runTestCase(docLib, testLib, testCase)
	set databaseName to databaseName of testCase
	set recordFilename to recordFilename of testCase
	set scenarioId to scenarioId of testCase
	set stepName to "resolve test case"

	set stepName to "validate recordFilename"
	my assertFilenameHasExtension(recordFilename, "recordFilename must include a file extension (e.g. .pdf).", testLib)

	set stepName to "find record by filename"
	set theRecord to my findRecordByFilenameInDatabase(recordFilename, databaseName)

	set stepName to "validate record type"
	tell application id "DNtp"
		set theRecordType to type of theRecord
		set theDatabase to database of theRecord
		set originalName to name of theRecord
		set originalComment to comment of theRecord
		set originalTags to tags of theRecord
	end tell
	testLib's assertTrue(theRecordType is not «constant DtypDTgr» and theRecordType is not «constant DtypDTsg», "Resolved item must be a regular record.")

	set stepName to "capture custom metadata snapshot"
	docLib's initializeDatabaseConfiguration(theDatabase)
	set relevantMetadataFields to my uniqueTextList((docLib's pCustomMetadataFields), (docLib's pCommentsFields))
	set originalCustomMetadataValues to my captureCustomMetadataValues(theRecord, relevantMetadataFields)
	set savedState to {originalComment:originalComment, originalCustomMetadataValues:originalCustomMetadataValues, originalName:originalName, originalTags:originalTags}

	try
		set stepName to "run scenario"
		my runScenarioById(docLib, testLib, theRecord, scenarioId)
	on error errMsg number errNum
		set failingStep to stepName
		try
			set stepName to "cleanup after failure"
			my restoreRecordState(theRecord, savedState)
		on error cleanupMsg number cleanupNum
			error "Test failed at step '" & failingStep & "' (" & errNum & "): " & errMsg & " | Cleanup failed at step 'cleanup after failure' (" & cleanupNum & "): " & cleanupMsg
		end try
		error "Test failed at step '" & failingStep & "' (" & errNum & "): " & errMsg
	end try

	try
		set stepName to "cleanup after success"
		my restoreRecordState(theRecord, savedState)
	on error cleanupMsg number cleanupNum
		error "Cleanup failed at step '" & stepName & "' (" & cleanupNum & "): " & cleanupMsg
	end try

	return "PASS [" & scenarioId & "] " & databaseName & " :: " & recordFilename
end runTestCase

on uniqueTextList(primaryList, extraList)
	set mergedList to {}
	if primaryList is missing value then set primaryList to {}
	if extraList is missing value then set extraList to {}

	repeat with aValue in primaryList
		set textValue to aValue as text
		if mergedList does not contain textValue then set end of mergedList to textValue
	end repeat
	repeat with aValue in extraList
		set textValue to aValue as text
		if mergedList does not contain textValue then set end of mergedList to textValue
	end repeat

	return mergedList
end uniqueTextList

set currentStep to "start"

set resultLines to {}
set failedCount to 0

try
	set currentStep to "resolve config path"
	set homePath to POSIX path of (path to home folder)
	set configPath to homePath & ".mailscripts/config.scpt"

	set currentStep to "load config"
	set config to load script configPath

	set currentStep to "resolve mail scripts path"
	set mailScriptsPath to pMailScriptsPath of config
	set mailScriptsBasePath to mailScriptsPath as text
	if mailScriptsBasePath is "" then error "pMailScriptsPath in ~/.mailscripts/config.scpt must not be empty."
	if mailScriptsBasePath ends with "/" then set mailScriptsBasePath to text 1 thru -2 of mailScriptsBasePath

	set currentStep to "load docLib"
	set docLib to load script (pDocLibraryPath of config)

	set currentStep to "load testLib"
	set testLib to load script (mailScriptsBasePath & "/Libs/TestLib.scpt")

	set currentStep to "load test cases from json"
	set testCases to testLib's loadTestCase05Cases(mailScriptsPath)

	repeat with aTestCase in testCases
		set testCaseRecordFilename to recordFilename of aTestCase
		set testCaseScenarioId to scenarioId of aTestCase
		set currentStep to "run testcase '" & testCaseScenarioId & "' for record '" & testCaseRecordFilename & "'"
		try
			set end of resultLines to my runTestCase(docLib, testLib, aTestCase)
		on error errMsg number errNum
			set failedCount to failedCount + 1
			set end of resultLines to "FAIL [" & testCaseScenarioId & "] " & testCaseRecordFilename & " (" & errNum & "): " & errMsg
		end try
	end repeat

	set totalCount to count of testCases
	set passedCount to totalCount - failedCount
	set summaryLine to "TOTAL: " & totalCount & ", PASSED: " & passedCount & ", FAILED: " & failedCount
	set details to testLib's joinLines(resultLines)

	if failedCount is 0 then
		return "PASS: " & summaryLine & linefeed & details
	else
		return "FAIL: " & summaryLine & linefeed & details
	end if
on error errMsg number errNum
	return "FAIL at step '" & currentStep & "' (" & errNum & "): " & errMsg
end try
