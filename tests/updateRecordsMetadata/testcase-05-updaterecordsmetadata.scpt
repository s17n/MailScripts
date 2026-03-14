#@osa-lang:AppleScript
use AppleScript version "2.4"
use framework "Foundation"
use scripting additions

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

on restoreRecordState(theRecord, savedState, testLib)
	set originalTags to originalTags of savedState
	set originalName to originalName of savedState
	set originalComment to originalComment of savedState
	set originalCustomMetadataValues to originalCustomMetadataValues of savedState

	testLib's restoreRecordTags(theRecord, originalTags)
	my restoreCustomMetadataValues(theRecord, originalCustomMetadataValues)

	tell application id "DNtp"
		set name of theRecord to originalName
		set comment of theRecord to originalComment
	end tell
end restoreRecordState

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

	testLib's assertFilenameHasExtension(recordFilename, "recordFilename must include a file extension (e.g. .pdf).")
	set theRecord to testLib's findRecordByFilenameInDatabase(recordFilename, databaseName)

	tell application id "DNtp"
		set theRecordType to type of theRecord
		set theDatabase to database of theRecord
		set originalName to name of theRecord
		set originalComment to comment of theRecord
		set originalTags to tags of theRecord
	end tell
	testLib's assertTrue(theRecordType is not «constant DtypDTgr» and theRecordType is not «constant DtypDTsg», "Resolved item must be a regular record.")

	docLib's initializeDatabaseConfiguration(theDatabase)
	set relevantMetadataFields to my uniqueTextList((docLib's pCustomMetadataFields), (docLib's pCommentsFields))
	set originalCustomMetadataValues to my captureCustomMetadataValues(theRecord, relevantMetadataFields)
	set savedState to {originalComment:originalComment, originalCustomMetadataValues:originalCustomMetadataValues, originalName:originalName, originalTags:originalTags}

	script runScript
		property owner : me
		property pDocLib : docLib
		property pScenarioId : scenarioId
		property pTestLib : testLib
		property pTheRecord : theRecord

		on execute()
			owner's runScenarioById(pDocLib, pTestLib, pTheRecord, pScenarioId)
		end execute
	end script

	script cleanupScript
		property owner : me
		property pSavedState : savedState
		property pTestLib : testLib
		property pTheRecord : theRecord

		on execute()
			owner's restoreRecordState(pTheRecord, pSavedState, pTestLib)
		end execute
	end script

	testLib's runWithCleanup(runScript, cleanupScript, "run scenario")
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

	script caseRunner
		property owner : me
		property pDocLib : docLib
		property pTestLib : testLib

		on runCase(testCase)
			return owner's runTestCase(pDocLib, pTestLib, testCase)
		end runCase
	end script

	return testLib's runCasesWithSummary(testCases, caseRunner)
on error errMsg number errNum
	return "FAIL at step '" & currentStep & "' (" & errNum & "): " & errMsg
end try
