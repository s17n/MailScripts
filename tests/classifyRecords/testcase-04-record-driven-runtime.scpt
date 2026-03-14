#@osa-lang:AppleScript
use AppleScript version "2.4"
use framework "Foundation"
use scripting additions

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

on runDateTagsPilotScenario(docLib, theRecord)
	tell application id "DNtp"
		set theDatabase to database of theRecord
	end tell

	docLib's initializeDatabaseConfiguration(theDatabase)

	set classificationDateKey to docLib's pClassificationDate
	set hasClassificationDate to (classificationDateKey is not missing value and classificationDateKey is not "")
	my assertTrue(hasClassificationDate, "pClassificationDate must be configured for this test.")

	set dateDimensions to docLib's pDateDimensions
	my assertEquals((count of dateDimensions), 3, "pDateDimensions must contain exactly three entries: Year, Month, Day.")

	set yearDimension to first item of dateDimensions as text
	set monthDimension to second item of dateDimensions as text
	set dayDimension to third item of dateDimensions as text

	set beforeFields to docLib's fieldsFromTags(theRecord, false)
	my assertMissing((beforeFields's objectForKey:yearDimension), "Precondition failed: Year dimension is already set.")
	my assertMissing((beforeFields's objectForKey:monthDimension), "Precondition failed: Month dimension is already set.")
	my assertMissing((beforeFields's objectForKey:dayDimension), "Precondition failed: Day dimension is already set.")

	docLib's classifyRecords({theRecord})

	set afterFields to docLib's fieldsFromTags(theRecord, false)
	my assertNotMissing((afterFields's objectForKey:yearDimension), "Year dimension was not set after classifyRecords.")
	my assertNotMissing((afterFields's objectForKey:monthDimension), "Month dimension was not set after classifyRecords.")
	my assertNotMissing((afterFields's objectForKey:dayDimension), "Day dimension was not set after classifyRecords.")
end runDateTagsPilotScenario

on runScenarioById(docLib, theRecord, scenarioId)
	if scenarioId is "pilot-date-tags" then
		my runDateTagsPilotScenario(docLib, theRecord)
	else
		error "Unknown scenarioId: " & scenarioId
	end if
end runScenarioById

on runTestCase(docLib, testCase)
	set databaseName to databaseName of testCase
	set recordFilename to recordFilename of testCase
	set scenarioId to scenarioId of testCase
	set stepName to "resolve test case"

	set stepName to "validate recordFilename"
	my assertFilenameHasExtension(recordFilename, "recordFilename must include a file extension (e.g. .pdf).")
	set stepName to "find record by filename"
	set theRecord to my findRecordByFilenameInDatabase(recordFilename, databaseName)
	set stepName to "capture record type and tags"
	tell application id "DNtp"
		set theRecordType to type of theRecord
		set originalTags to tags of theRecord
	end tell
	my assertTrue(theRecordType is not «constant DtypDTgr» and theRecordType is not «constant DtypDTsg», "Resolved item must be a regular record.")

	try
		set stepName to "run scenario"
		my runScenarioById(docLib, theRecord, scenarioId)

		set stepName to "read trace metrics"
		my validateClassifyRecordsTraceMetrics(docLib)
	on error errMsg number errNum
		set failingStep to stepName
		try
			set stepName to "cleanup after failure"
			my restoreRecordTags(theRecord, originalTags)
		on error cleanupMsg number cleanupNum
			error "Test failed at step '" & failingStep & "' (" & errNum & "): " & errMsg & " | Cleanup failed at step 'cleanup after failure' (" & cleanupNum & "): " & cleanupMsg
		end try
		error "Test failed at step '" & failingStep & "' (" & errNum & "): " & errMsg
	end try

	try
		set stepName to "cleanup after success"
		my restoreRecordTags(theRecord, originalTags)
	on error cleanupMsg number cleanupNum
		error "Cleanup failed at step '" & stepName & "' (" & cleanupNum & "): " & cleanupMsg
	end try

	return "PASS [" & scenarioId & "] " & databaseName & " :: " & recordFilename
end runTestCase

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

set currentStep to "start"
set testCases to {{databaseName:"Dokumente-Steffen", recordFilename:"2026-03-08_Hallesche_Information.pdf", scenarioId:"pilot-date-tags"}}

set resultLines to {}
set failedCount to 0

try
	set currentStep to "resolve config path"
	set homePath to POSIX path of (path to home folder)
	set configPath to homePath & ".mailscripts/config.scpt"

	set currentStep to "load config"
	set config to load script configPath

	set currentStep to "load docLib"
	set docLib to load script (pDocLibraryPath of config)

	repeat with aTestCase in testCases
		set testCaseRecordFilename to recordFilename of aTestCase
		set testCaseScenarioId to scenarioId of aTestCase
		set currentStep to "run testcase '" & testCaseScenarioId & "' for record '" & testCaseRecordFilename & "'"
		try
			set end of resultLines to my runTestCase(docLib, aTestCase)
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
on error errMsg number errNum
	return "FAIL at step '" & currentStep & "' (" & errNum & "): " & errMsg
end try
