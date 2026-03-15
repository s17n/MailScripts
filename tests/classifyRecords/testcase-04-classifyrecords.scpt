#@osa-lang:AppleScript
use AppleScript version "2.4"
use framework "Foundation"
use scripting additions

on runDateTagsPilotScenario(docLib, testLib, theRecord)
	tell application id "DNtp"
		set theDatabase to database of theRecord
	end tell

	docLib's initializeDatabaseConfiguration(theDatabase)

	set classificationDateKey to docLib's pClassificationDate
	set hasClassificationDate to (classificationDateKey is not missing value and classificationDateKey is not "")
	testLib's assertTrue(hasClassificationDate, "pClassificationDate must be configured for this test.")

	set dateDimensions to docLib's pDateDimensions
	testLib's assertEquals((count of dateDimensions), 3, "pDateDimensions must contain exactly three entries: Year, Month, Day.")

	set yearDimension to first item of dateDimensions as text
	set monthDimension to second item of dateDimensions as text
	set dayDimension to third item of dateDimensions as text

	set beforeFields to docLib's fieldsFromTags(theRecord, false)
	set yearValue to beforeFields's objectForKey:yearDimension
	set monthValue to beforeFields's objectForKey:monthDimension
	set dayValue to beforeFields's objectForKey:dayDimension
	set hasCleanPreconditions to (yearValue is missing value and monthValue is missing value and dayValue is missing value)

	-- Ensure deterministic preconditions for fixtures that already contain date tags.
	if hasCleanPreconditions is false then
		set tagsToRemove to {}
		if yearValue is not missing value then set end of tagsToRemove to yearValue as text
		if monthValue is not missing value then set end of tagsToRemove to monthValue as text
		if dayValue is not missing value then set end of tagsToRemove to dayValue as text

		tell application id "DNtp"
			set currentTags to tags of theRecord
		end tell

		set filteredTags to {}
		repeat with aTag in currentTags
			set tagText to aTag as text
			if tagsToRemove does not contain tagText then set end of filteredTags to tagText
		end repeat

		tell application id "DNtp"
			set tags of theRecord to filteredTags
		end tell

		set beforeFields to docLib's fieldsFromTags(theRecord, false)
		set yearValue to beforeFields's objectForKey:yearDimension
		set monthValue to beforeFields's objectForKey:monthDimension
		set dayValue to beforeFields's objectForKey:dayDimension
		set hasCleanPreconditions to (yearValue is missing value and monthValue is missing value and dayValue is missing value)
	end if

	if hasCleanPreconditions then
		testLib's assertMissing((beforeFields's objectForKey:yearDimension), "Precondition failed: Year dimension is already set.")
		testLib's assertMissing((beforeFields's objectForKey:monthDimension), "Precondition failed: Month dimension is already set.")
		testLib's assertMissing((beforeFields's objectForKey:dayDimension), "Precondition failed: Day dimension is already set.")
	end if

	docLib's classifyRecords({theRecord})

	set afterFields to docLib's fieldsFromTags(theRecord, false)
	testLib's assertNotMissing((afterFields's objectForKey:yearDimension), "Year dimension was not set after classifyRecords.")
	testLib's assertNotMissing((afterFields's objectForKey:monthDimension), "Month dimension was not set after classifyRecords.")
	testLib's assertNotMissing((afterFields's objectForKey:dayDimension), "Day dimension was not set after classifyRecords.")
end runDateTagsPilotScenario

on runScenarioById(docLib, testLib, theRecord, scenarioId)
	if scenarioId is "pilot-date-tags" then
		my runDateTagsPilotScenario(docLib, testLib, theRecord)
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
		set originalTags to tags of theRecord
	end tell
	testLib's assertTrue(theRecordType is not «constant DtypDTgr» and theRecordType is not «constant DtypDTsg», "Resolved item must be a regular record.")

	script runScript
		property owner : me
		property pDocLib : docLib
		property pScenarioId : scenarioId
		property pTestLib : testLib
		property pTheRecord : theRecord

		on execute()
			owner's runScenarioById(pDocLib, pTestLib, pTheRecord, pScenarioId)
			pTestLib's validateClassifyRecordsTraceMetrics(pDocLib)
		end execute
	end script

	script cleanupScript
		property pOriginalTags : originalTags
		property pTestLib : testLib
		property pTheRecord : theRecord

		on execute()
			pTestLib's restoreRecordTags(pTheRecord, pOriginalTags)
		end execute
	end script

	testLib's runWithCleanup(runScript, cleanupScript, "run scenario")
	return "PASS [" & scenarioId & "] " & databaseName & " :: " & recordFilename
end runTestCase

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
	set testCases to testLib's loadTestCase04Cases(mailScriptsPath)

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
