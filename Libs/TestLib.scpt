#@osa-lang:AppleScript
use AppleScript version "2.4"
use framework "Foundation"
use scripting additions

property pScriptName : "TestLib"

on assertEquals(actualValue, expectedValue, messageText)
	if actualValue is not expectedValue then error "Assertion failed: " & messageText & " (expected: " & expectedValue & ", actual: " & actualValue & ")."
end assertEquals

on assertFilenameHasExtension(recordFilename, messageText)
	my assertTrue((recordFilename contains "."), messageText)
end assertFilenameHasExtension

on assertGreaterThanZero(valueToCheck, messageText)
	if valueToCheck is missing value then error "Assertion failed: " & messageText & " (value is missing)."
	set numericValue to valueToCheck as real
	if numericValue ≤ 0 then error "Assertion failed: " & messageText & " (value: " & numericValue & ")."
end assertGreaterThanZero

on assertMissing(valueToCheck, messageText)
	if valueToCheck is not missing value then error "Assertion failed: " & messageText
end assertMissing

on assertNotMissing(valueToCheck, messageText)
	if valueToCheck is missing value then error "Assertion failed: " & messageText
end assertNotMissing

on assertTrue(conditionValue, messageText)
	if conditionValue is not true then error "Assertion failed: " & messageText
end assertTrue

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

on findTraceMetricByOperationName(metrics, operationName)
	repeat with aMetric in metrics
		if operationName of aMetric is operationName then return aMetric
	end repeat
	return missing value
end findTraceMetricByOperationName

on joinLines(theLines)
	set previousDelimiters to AppleScript's text item delimiters
	set AppleScript's text item delimiters to linefeed
	set joinedText to theLines as text
	set AppleScript's text item delimiters to previousDelimiters
	return joinedText
end joinLines

on jsonPathFromMailScriptsPath(mailScriptsPath, relativePath)
	set basePath to mailScriptsPath as text
	if basePath is "" then error "pMailScriptsPath in ~/.mailscripts/config.scpt must not be empty."
	if basePath ends with "/" then set basePath to text 1 thru -2 of basePath
	return basePath & "/" & relativePath
end jsonPathFromMailScriptsPath

on loadTestCase04Cases(mailScriptsPath)
	return my loadTestCases(mailScriptsPath, "Configuration/tests/testcase-04-classifyrecords-cases.json")
end loadTestCase04Cases

on loadTestCase05Cases(mailScriptsPath)
	return my loadTestCases(mailScriptsPath, "Configuration/tests/testcase-05-updaterecordsmetadata-cases.json")
end loadTestCase05Cases

on loadTestCases(mailScriptsPath, relativeJsonPath)
	set jsonPath to my jsonPathFromMailScriptsPath(mailScriptsPath, relativeJsonPath)
	set fileManager to current application's NSFileManager's defaultManager()
	if ((fileManager's fileExistsAtPath:jsonPath) as boolean) is false then error "JSON file not found: " & jsonPath

	set readError to reference
	set readResult to current application's NSString's stringWithContentsOfFile:jsonPath encoding:(current application's NSUTF8StringEncoding) |error|:readError
	set jsonText to item 1 of readResult
	if jsonText is missing value then
		set readMessage to "Unknown read error."
		if (readError's contents) is not missing value then set readMessage to ((readError's contents)'s localizedDescription()) as text
		error "Failed to read JSON file '" & jsonPath & "': " & readMessage
	end if

	set jsonData to jsonText's dataUsingEncoding:(current application's NSUTF8StringEncoding)
	set parseError to reference
	set parseResult to current application's NSJSONSerialization's JSONObjectWithData:jsonData options:0 |error|:parseError
	set jsonRoot to item 1 of parseResult
	if jsonRoot is missing value then
		set parseMessage to "Unknown parse error."
		if (parseError's contents) is not missing value then set parseMessage to ((parseError's contents)'s localizedDescription()) as text
		error "Failed to parse JSON file '" & jsonPath & "': " & parseMessage
	end if

	if ((jsonRoot's isKindOfClass:(current application's NSArray)) as boolean) is false then error "Invalid JSON schema in '" & jsonPath & "': root must be an array."

	set rawTestCases to jsonRoot as list
	set parsedTestCases to {}
	set caseIndex to 0
	repeat with rawCase in rawTestCases
		set caseIndex to caseIndex + 1
		set caseRecord to contents of rawCase
		if class of caseRecord is not record then error "Invalid JSON schema in '" & jsonPath & "': test case #" & caseIndex & " must be an object."

		try
			set databaseNameRawValue to databaseName of caseRecord
		on error
			set databaseNameRawValue to missing value
		end try
		try
			set recordFilenameRawValue to recordFilename of caseRecord
		on error
			set recordFilenameRawValue to missing value
		end try
		try
			set scenarioIdRawValue to scenarioId of caseRecord
		on error
			set scenarioIdRawValue to missing value
		end try

		set databaseName to my nonEmptyTextFromJsonValue(databaseNameRawValue, "databaseName", caseIndex, jsonPath)
		set recordFilename to my nonEmptyTextFromJsonValue(recordFilenameRawValue, "recordFilename", caseIndex, jsonPath)
		set scenarioId to my nonEmptyTextFromJsonValue(scenarioIdRawValue, "scenarioId", caseIndex, jsonPath)

		set end of parsedTestCases to {databaseName:databaseName, recordFilename:recordFilename, scenarioId:scenarioId}
	end repeat

	if (count of parsedTestCases) is 0 then error "Invalid JSON schema in '" & jsonPath & "': test case array is empty."
	return parsedTestCases
end loadTestCases

on nonEmptyTextFromJsonValue(jsonValue, fieldName, caseIndex, jsonPath)
	if jsonValue is missing value then error "Invalid JSON schema in '" & jsonPath & "': test case #" & caseIndex & " is missing field '" & fieldName & "'."
	if class of jsonValue is not text then error "Invalid JSON schema in '" & jsonPath & "': field '" & fieldName & "' in test case #" & caseIndex & " must be a string."

	set rawText to jsonValue as text
	set trimmedText to ((current application's NSString's stringWithString:rawText)'s stringByTrimmingCharactersInSet:(current application's NSCharacterSet's whitespaceAndNewlineCharacterSet())) as text
	if trimmedText is "" then error "Invalid JSON schema in '" & jsonPath & "': field '" & fieldName & "' in test case #" & caseIndex & " must not be empty."
	return trimmedText
end nonEmptyTextFromJsonValue

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
	try
		set filenameItems to text items of filenameText
		set itemsCount to count of filenameItems
		if itemsCount ≤ 1 then return filenameText
		set nameItems to items 1 thru (itemsCount - 1) of filenameItems
		set lookupName to nameItems as text
	on error errMsg number errNum
		set AppleScript's text item delimiters to previousDelimiters
		error errMsg number errNum
	end try
	set AppleScript's text item delimiters to previousDelimiters
	return lookupName
end recordNameFromFilename

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

on runCasesWithSummary(testCases, caseRunner)
	set resultLines to {}
	set failedCount to 0

	repeat with aTestCase in testCases
		set testCaseRecord to contents of aTestCase
		set testCaseRecordFilename to recordFilename of testCaseRecord
		set testCaseScenarioId to scenarioId of testCaseRecord
		try
			set end of resultLines to caseRunner's runCase(testCaseRecord)
		on error errMsg number errNum
			set failedCount to failedCount + 1
			set end of resultLines to "FAIL [" & testCaseScenarioId & "] " & testCaseRecordFilename & " (" & errNum & "): " & errMsg
		end try
	end repeat

	set totalCount to count of testCases
	set passedCount to totalCount - failedCount
	set summaryLine to "TOTAL: " & totalCount & ", PASSED: " & passedCount & ", FAILED: " & failedCount
	set details to my joinLines(resultLines)

	if failedCount is 0 then
		return "PASS: " & summaryLine & linefeed & details
	else
		return "FAIL: " & summaryLine & linefeed & details
	end if
end runCasesWithSummary

on runWithCleanup(runScript, cleanupScript, failureStepName)
	try
		runScript's execute()
	on error errMsg number errNum
		try
			cleanupScript's execute()
		on error cleanupMsg number cleanupNum
			error "Test failed at step '" & failureStepName & "' (" & errNum & "): " & errMsg & " | Cleanup failed at step 'cleanup after failure' (" & cleanupNum & "): " & cleanupMsg
		end try
		error "Test failed at step '" & failureStepName & "' (" & errNum & "): " & errMsg
	end try

	try
		cleanupScript's execute()
	on error cleanupMsg number cleanupNum
		error "Cleanup failed at step 'cleanup after success' (" & cleanupNum & "): " & cleanupMsg
	end try
end runWithCleanup

on validateClassifyRecordsTraceMetrics(docLib)
	set loggerInstance to docLib's logger
	my assertNotMissing(loggerInstance, "docLib logger is not initialized.")

	set metrics to loggerInstance's getTraceMetrics()
	set classifyMetric to my findTraceMetricByOperationName(metrics, "classifyRecords")
	my assertNotMissing(classifyMetric, "Trace metric for operation 'classifyRecords' was not found.")
	my assertEquals((callCount of classifyMetric), 1, "Trace metric callCount must be 1.")
	my assertGreaterThanZero((exclusiveTotalMs of classifyMetric), "Trace metric exclusiveTotalMs must be > 0.")
	my assertGreaterThanZero((inclusiveTotalMs of classifyMetric), "Trace metric inclusiveTotalMs must be > 0.")
end validateClassifyRecordsTraceMetrics
