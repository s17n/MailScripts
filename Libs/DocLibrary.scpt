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
property pAmountFormatter : missing value
property tagAliases : missing value
property monthsByName : missing value
property monthsByDigit : missing value
property pIssueCount : 0

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

-- Operation: addTextToCustomMetadata
-- Kurzbeschreibung: Fuegt Zusatztext in ein konfiguriertes Custom-Metadata-Feld ein oder ersetzt ihn.
-- Parameter: theCustomMetadataField:text
-- Parameter: theText:text
-- Rueckgabe: kein Rueckgabewert (Seiteneffekte)
on addTextToCustomMetadata(theCustomMetadataField, theText)
	set logCtx to my initialize(" addTextToCustomMetadata")
	logger's trace(logCtx, "enter > theCustomMetadataField: " & theCustomMetadataField & ", theText: " & theText)

	tell application id "DNtp"

		set theDatabase to current database
		my initializeDatabaseConfiguration(theDatabase)

		set theRecord to content record
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

-- Operation: addToTagList
-- Kurzbeschreibung: Fuegt den Namen eines Tag-Records an eine Ergebnisliste an.
-- Parameter: theTagList:list<text>
-- Parameter: theRecord:DEVONthink record (class 'record' / DTrc)
-- Rueckgabe: list<text>
on addToTagList(theTagList, theRecord)
	set end of theTagList to name of theRecord as string
	return theTagList
end addToTagList

-- Operation: archiveRecords
-- Kurzbeschreibung: Ermittelt Archivziel aus Platzhaltern, verschiebt Record und markiert ihn als gesperrt.
-- Parameter: theRecords:list<DEVONthink record (class 'record' / DTrc)>
-- Rueckgabe: kein Rueckgabewert (Seiteneffekte)
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

-- Operation: buildDimensionsConstraintsDictionary
-- Kurzbeschreibung: Baut ein Dictionary mit Dimension -> Kardinalitaet aus der Konfigurationsliste.
-- Parameter: theConstraints:list<list{text,integer}>
-- Rueckgabe: NSMutableDictionary<text,integer>
on buildDimensionsConstraintsDictionary(theConstraints)
	set constraintsDictionary to current application's NSMutableDictionary's dictionary()
	repeat with aDimensionConstraint in theConstraints
		set theDimensionName to first item of aDimensionConstraint as string
		set theCardinality to second item of aDimensionConstraint as integer
		(constraintsDictionary's setObject:theCardinality forKey:theDimensionName)
	end repeat
	return constraintsDictionary
end buildDimensionsConstraintsDictionary

-- Operation: buildMonthDictionaries
-- Kurzbeschreibung: Erzeugt beide Monats-Mappings (Nummer->Name und Name->Nummer).
-- Parameter: theMonths:list<list{text,text}>
-- Rueckgabe: list{NSMutableDictionary<text,text>, NSMutableDictionary<text,text>}
on buildMonthDictionaries(theMonths)
	set byDigit to current application's NSMutableDictionary's dictionary()
	set byName to current application's NSMutableDictionary's dictionary()
	repeat with aMonth in theMonths
		set theNumber to first item of aMonth as string
		set theName to second item of aMonth as string
		(byDigit's setObject:theName forKey:theNumber)
		(byName's setObject:theNumber forKey:theName)
	end repeat
	return {byDigit, byName}
end buildMonthDictionaries

-- Operation: buildTagAliasDictionary
-- Kurzbeschreibung: Baut ein Dictionary mit Tag -> Alias aus den konfigurierten Tag-Alias-Paaren.
-- Parameter: theTagAliases:list<list{text,text}>
-- Rueckgabe: NSMutableDictionary<text,text>
on buildTagAliasDictionary(theTagAliases)
	set aliasesDictionary to current application's NSMutableDictionary's dictionary()
	repeat with aTagAlias in theTagAliases
		set theTag to first item of aTagAlias as string
		set theAlias to second item of aTagAlias as string
		(aliasesDictionary's setObject:theAlias forKey:theTag)
	end repeat
	return aliasesDictionary
end buildTagAliasDictionary

-- Operation: classifyRecords
-- Kurzbeschreibung: Klassifiziert Records durch Datumstags und Vergleich mit aehnlichen Records.
-- Parameter: theRecords:list<DEVONthink record (class 'record' / DTrc)>
-- Rueckgabe: kein Rueckgabewert (Seiteneffekte)
on classifyRecords(theRecords)
	set logCtx to my initialize("classifyRecords")
	logger's trace(logCtx, "enter")

	tell application id "DNtp"

		set theDatabase to database of first item of theRecords

		my initializeDatabaseConfiguration(theDatabase)
		set {recordsSelected, recordsProcessed} to {0, 0}
		repeat with theRecord in theRecords
			set recordsSelected to recordsSelected + 1
			if type of theRecord is not group and type of theRecord is not smart group then
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

			end if
		end repeat
		tell logger to info(logCtx, "Records selected: " & recordsSelected & ", Records processed:  " & recordsProcessed)
	end tell

	logger's trace(logCtx, "exit")
end classifyRecords

-- Operation: createSmartGroupForSender
-- Kurzbeschreibung: Initialisiert MailLibrary und erstellt eine Sender-Smart-Group fuer gegebene Records.
-- Parameter: theRecords:list<DEVONthink record (class 'record' / DTrc)>
-- Parameter: theDatabaseName:text
-- Rueckgabe: kein Rueckgabewert (Seiteneffekte)
on createSmartGroupForSender(theRecords, theDatabaseName)
	set logCtx to my initialize("createSmartGroupForSender")
	logger's trace(logCtx, "enter > " & theDatabaseName)

	my initializeMailLibrary(theDatabaseName)

	mailLib's createSmartGroup(theRecords)

	logger's trace(logCtx, "exit")
end createSmartGroupForSender

-- Operation: createTagList
-- Kurzbeschreibung: Traversiert Tag-Hierarchien rekursiv und sammelt Blatt-Tags als flache Liste.
-- Parameter: theTags:list<DEVONthink child record (class 'child' / DTch)>
-- Parameter: resultList:list<text>
-- Rueckgabe: list<text>
on createTagList(theTags, resultList)
	tell application id "DNtp"
		repeat with tagListItem in theTags
			set theTagType to tag type of tagListItem
			if theTagType is ordinary tag then
				set resultList to my addToTagList(resultList, tagListItem)
			else
				set resultList to my createTagList(every child of tagListItem, resultList)
			end if
		end repeat
		return resultList
	end tell
	return resultList
end createTagList

-- Operation: creationDateFromMetadata
-- Kurzbeschreibung: Liest das Erstellungsdatum (bei PDF ueber ExifTool) mit Fallback auf Record-Erstellungsdatum.
-- Parameter: theRecord:DEVONthink record (class 'record' / DTrc)
-- Rueckgabe: date
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

-- Operation: databaseConfigurationPath
-- Kurzbeschreibung: Erzeugt den Dateipfad zur datenbankspezifischen Konfigurationsdatei.
-- Parameter: theDatabaseName:text
-- Rueckgabe: text
on databaseConfigurationPath(theDatabaseName)
	return pDatabaseConfigurationFolder & "/Database-Configuration-" & theDatabaseName & ".scpt"
end databaseConfigurationPath

-- Operation: displayNotification
-- Kurzbeschreibung: Zeigt pro Record eine Info-Benachrichtigung mit einem Feldwert an.
-- Parameter: theRecords:list<DEVONthink record (class 'record' / DTrc)>
-- Parameter: pMessagePrefix:text
-- Parameter: pFieldForMessage:text
-- Rueckgabe: kein Rueckgabewert (Seiteneffekte)
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

-- Operation: existDimension
-- Kurzbeschreibung: Prueft, ob fuer alle angeforderten Dimensionen Werte vorhanden sind.
-- Parameter: theFields:NSMutableDictionary
-- Parameter: theDimensions:list<text>
-- Rueckgabe: boolean
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

-- Operation: extractCustomTextFromCmdValue
-- Kurzbeschreibung: Extrahiert den frei eingegebenen Textanteil aus einem Custom-Metadata-Wert.
-- Parameter: currentValue:text|missing value
-- Rueckgabe: text
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

-- Operation: fieldsFromTags
-- Kurzbeschreibung: Leitet aus den Record-Tags ein Dictionary mit Dimensionen und Werten ab.
-- Parameter: theRecord:DEVONthink record (class 'record' / DTrc)
-- Parameter: interactiveMode:boolean
-- Rueckgabe: NSMutableDictionary<text, text|list<text>>
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

-- Operation: getClassificationDate
-- Kurzbeschreibung: Ermittelt das fuer die Klassifikation zu verwendende Datum gemaess Konfiguration.
-- Parameter: theRecord:DEVONthink record (class 'record' / DTrc)
-- Parameter: theClassificationDate:text
-- Rueckgabe: date
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
			error "Unknown Classification Date Field Identifier: " & pClassificationDate
		end if

	end tell

	logger's trace(logCtx, "exit > " & theDate)
	return theDate
end getClassificationDate

-- Operation: handleUncategorizedTag
-- Kurzbeschreibung: Bietet interaktiv an, ein nicht zugeordnetes Tag einer Dimension zuzuordnen.
-- Parameter: theTag:text
-- Rueckgabe: kein Rueckgabewert (Seiteneffekte)
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

-- Operation: importMailMessages
-- Kurzbeschreibung: Liest Inbox-Nachrichten ueber MailLibrary und importiert sie in die Ziel-Datenbank.
-- Parameter: theDatabaseName:text
-- Rueckgabe: kein Rueckgabewert (Seiteneffekte)
on importMailMessages(theDatabaseName)
	set logCtx to my initialize("importMailMessages")
	logger's trace(logCtx, "enter > " & theDatabaseName)

	tell application id "DNtp"

		my initializeMailLibrary(theDatabaseName)

		set theMessages to mailLib's getInboxMessages()
		logger's debug(logCtx, "Number of Inbox Messages: " & length of theMessages)
		mailLib's importMessages(theMessages, theDatabaseName)

	end tell
	logger's trace(logCtx, "exit")
end importMailMessages

-- Operation: initialize
-- Kurzbeschreibung: Initialisiert Konfiguration und Bibliotheksreferenzen einmalig und liefert den Logging-Kontext.
-- Parameter: loggingContext:text
-- Rueckgabe: text
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

		set pIsInitialized to true
		tell logger to debug(logCtx, "Initialization finished")
	end if
	return pScriptName & " > " & loggingContext
end initialize

-- Operation: initializeDatabaseConfiguration
-- Kurzbeschreibung: Laedt Datenbank- und Default-Konfiguration, setzt Modul-Properties und initialisiert Dimensionen.
-- Parameter: theDatabase:DEVONthink database (class 'database' / DTkb)
-- Rueckgabe: kein Rueckgabewert (Seiteneffekte)
on initializeDatabaseConfiguration(theDatabase)
	set logCtx to my initialize("initializeDatabaseConfiguration")
	logger's trace(logCtx, "enter")

	tell application id "DNtp" to set theDatabaseName to name of theDatabase

	set databaseConfigPath to my databaseConfigurationPath(theDatabaseName)
	set databaseConfiguration to load script databaseConfigPath
	set pContentType to pContentType of databaseConfiguration
	set defaultConfigurationName to pDefaultConfiguration of databaseConfiguration
	set defaultConfiguration to load script (pDatabaseConfigurationFolder & "/" & defaultConfigurationName)

	-- Logger
	set pLogLevel to pLogLevel of defaultConfiguration
	logger's setLogLevel(pLogLevel)

	-- Dimensions
	set pDimensionsHome to pDimensionsHome of defaultConfiguration
	set pDateDimensions to pDateDimensions of defaultConfiguration
	set pCompareDimensions to pCompareDimensions of defaultConfiguration
	set pCompareDimensionsScoreThreshold to pCompareDimensionsScoreThreshold of defaultConfiguration

	set pClassificationDate to pClassificationDate of defaultConfiguration

	set pNameTemplate to pNameTemplate of defaultConfiguration

	set pCustomMetadataFields to pCustomMetadataFields of defaultConfiguration
	set pCustomMetadataDimensions to pCustomMetadataDimensions of defaultConfiguration
	set pCustomMetadataTypes to pCustomMetadataTypes of defaultConfiguration
	set pCustomMetadataTemplates to pCustomMetadataTemplates of defaultConfiguration
	set pCustomMetadataFieldSeparator to pCustomMetadataFieldSeparator of defaultConfiguration

	set pCommentsFields to pCommentsFields of defaultConfiguration

	set pAmountLookupCategories to words of (pAmountLookupCategories of defaultConfiguration)
	set pFilesHome to pFilesHome of defaultConfiguration

	set pDimensionsConstraints to pDimensionsConstraints of defaultConfiguration
	set pDimensionsConstraintsDictionary to my buildDimensionsConstraintsDictionary(pDimensionsConstraints)

	set pTagAliases to pTagAliases of defaultConfiguration
	set tagAliases to my buildTagAliasDictionary(pTagAliases)

	set theMonths to pMonths of defaultConfiguration
	set {monthsByDigit, monthsByName} to my buildMonthDictionaries(theMonths)

	set pAmountFormatter to current application's NSNumberFormatter's new()
	pAmountFormatter's setMinimumFractionDigits:2
	pAmountFormatter's setMaximumFractionDigits:2
	pAmountFormatter's setNumberStyle:(current application's NSNumberFormatterDecimalStyle)

	my initializeDimensions(theDatabase)

	if pContentType is equal to "EMAILS" then
		my initializeMailLibrary(theDatabaseName)
	end if

	logger's trace(logCtx, "exit")
end initializeDatabaseConfiguration

-- Operation: initializeDimensions
-- Kurzbeschreibung: Laedt alle Dimensionen und Kategorien der Datenbank in den In-Memory-Cache.
-- Parameter: theDatabase:DEVONthink database (class 'database' / DTkb)
-- Rueckgabe: kein Rueckgabewert (Seiteneffekte)
on initializeDimensions(theDatabase)
	set logCtx to my initialize("initializeDimensions")
	logger's trace(logCtx, "enter")

	set pDimensionsDictionary to current application's NSMutableDictionary's dictionary()
	tell application id "DNtp"

		set dimensionHome to get record at pDimensionsHome in theDatabase
		set theDimensions to every child of dimensionHome
		repeat with aDimension in theDimensions

			set dimensionName to name of aDimension
			set categories to my createTagList(get every child of aDimension, {})
			(pDimensionsDictionary's setObject:categories forKey:dimensionName)

			tell logger to debug(logCtx, "Dimension '" & dimensionName & "' initialized with " & length of categories & " categories.")
		end repeat

	end tell

	logger's trace(logCtx, "exit")
end initializeDimensions

-- Operation: initializeMailLibrary
-- Kurzbeschreibung: Initialisiert MailLibrary-Abhaengigkeiten und laedt deren Datenbankkonfiguration.
-- Parameter: theDatabaseName:text
-- Rueckgabe: text
on initializeMailLibrary(theDatabaseName)
	mailLib's initializeDepencencies(logger, baseLib)
	set databaseConfigPath to my databaseConfigurationPath(theDatabaseName)
	mailLib's initializeDatabaseConfiguration(databaseConfigPath)
	return databaseConfigPath
end initializeMailLibrary

-- Operation: logIssue
-- Kurzbeschreibung: Protokolliert einen Validierungsfehler, zaehlt ihn und setzt optional ein Label.
-- Parameter: theRecord:DEVONthink record (class 'record' / DTrc)
-- Parameter: setRecordLabel:boolean
-- Parameter: theMessage:text
-- Rueckgabe: kein Rueckgabewert (Seiteneffekte)
on logIssue(theRecord, setRecordLabel, theMessage)
	tell application id "DNtp"
		tell logger to info_r(theRecord, theMessage)
		set pIssueCount to pIssueCount + 1
		if setRecordLabel is true then
			set label of theRecord to 7
		end if
	end tell
end logIssue

-- Operation: moveByDimension
-- Kurzbeschreibung: Verschiebt Records in Zielgruppen auf Basis einer ermittelten Dimensions-Kategorie.
-- Parameter: theRecords:list<DEVONthink record (class 'record' / DTrc)>
-- Parameter: theDimension:text
-- Parameter: theFolderPrefix:text
-- Rueckgabe: kein Rueckgabewert (Seiteneffekte)
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

-- Operation: moveRecord
-- Kurzbeschreibung: Verschiebt einen Record in eine Zielgruppe und legt die Gruppe bei Bedarf an.
-- Parameter: theRecord:DEVONthink record (class 'record' / DTrc)
-- Parameter: theDestinationFolderName:text
-- Rueckgabe: kein Rueckgabewert (Seiteneffekte)
on moveRecord(theRecord, theDestinationFolderName)
	set logCtx to my initialize("moveRecord")
	logger's trace(logCtx, "enter > theDestinationFolderName: " & theDestinationFolderName)

	tell application id "DNtp"

		set theDestinationFolder to get record at theDestinationFolderName
		if theDestinationFolder is missing value then
			logger's info(logCtx, "Record will be moved to a group that doesn't exist yet and will be created now: " & theDestinationFolderName)
			set theDestinationFolder to create location theDestinationFolderName
		end if
		logger's debug(logCtx, "Record moved from: " & location of theRecord & " to: " & theDestinationFolderName)
		move record theRecord from location group of theRecord to theDestinationFolder

	end tell

	logger's trace(logCtx, "exit")
end moveRecord

-- Operation: processDocuments
-- Kurzbeschreibung: Fuehrt den Standard-Workflow aus: Klassifikation und Metadatenaktualisierung.
-- Parameter: theRecords:list<DEVONthink record (class 'record' / DTrc)>
-- Rueckgabe: kein Rueckgabewert (Seiteneffekte)
on processDocuments(theRecords)
	set logCtx to my initialize("processDocuments")
	logger's trace(logCtx, "enter")

	logger's debug(logCtx, "Number of Records: " & length of theRecords)

	my classifyRecords(theRecords)
	my updateRecordsMetadata(theRecords)

	logger's trace(logCtx, "exit")
end processDocuments

-- Operation: removeTrailingBracketBlocks
-- Kurzbeschreibung: Entfernt am String-Ende angehaengte Klammerbloecke wie [..].
-- Parameter: theString:text
-- Rueckgabe: text
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

-- Operation: replaceDatePlaceholder
-- Kurzbeschreibung: Ersetzt Datums-Platzhalter {Year}, {Month}, {Day} in einem Template.
-- Parameter: theDate:date
-- Parameter: theTemplate:text
-- Rueckgabe: text
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

-- Operation: replaceDimensionPlaceholders
-- Kurzbeschreibung: Ersetzt Dimensions-Platzhalter [Dimension] in einem Template.
-- Parameter: theDimensions:list<text>
-- Parameter: theFields:NSMutableDictionary
-- Parameter: theTemplate:text
-- Rueckgabe: text
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

-- Operation: replaceFieldPlaceholder
-- Kurzbeschreibung: Ersetzt spezielle Feld-Platzhalter wie {Decades} in einem Template.
-- Parameter: thePlaceholder:text
-- Parameter: theFields:NSMutableDictionary
-- Parameter: theTemplate:text
-- Rueckgabe: text
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

-- Operation: replaceText
-- Kurzbeschreibung: Ersetzt alle Vorkommen eines Teilstrings in einem Quelltext.
-- Parameter: findText:text
-- Parameter: replaceText:text
-- Parameter: sourceText:text
-- Rueckgabe: text
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

-- Operation: setCustomMetadata
-- Kurzbeschreibung: Berechnet den Zielwert fuer ein Custom-Metadata-Feld und schreibt ihn bei Aenderung.
-- Parameter: theIndex:integer
-- Parameter: theRecord:DEVONthink record (class 'record' / DTrc)
-- Parameter: theFields:NSMutableDictionary
-- Parameter: theSupplemental:text
-- Parameter: theSupplementalAction:text (ADD|REPLACE)
-- Rueckgabe: kein Rueckgabewert (Seiteneffekte)
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
					set theReplaceText to theReplaceText & " [" & my tagAlias(theTag) & "]"
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
		if currentAmount is not missing value then set amountText to " [EUR " & currentAmount & "]"
		set cmdValue to my replaceText("{Amount}", amountText, cmdValue as string)

		set newValue to cmdValue
	end if

	if newValue is not equal to currentValue then
		tell logger to info_r(theRecord, "Field '" & theField & "' changed from: " & currentValue & " to: " & newValue)
		tell application id "DNtp"
			add custom meta data newValue for theField to theRecord
		end tell
	end if

	logger's trace(logCtx, "exit")
end setCustomMetadata

-- Operation: setDateTags
-- Kurzbeschreibung: Setzt Jahr/Monat/Tag-Tags anhand des Klassifikationsdatums, wenn sie noch fehlen.
-- Parameter: theRecord:DEVONthink record (class 'record' / DTrc)
-- Parameter: theFields:NSMutableDictionary
-- Parameter: theClassificationDate:text
-- Rueckgabe: kein Rueckgabewert (Seiteneffekte)
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

-- Operation: setField
-- Kurzbeschreibung: Ordnet ein Tag einer passenden Dimension zu und prueft dabei die Kardinalitaet.
-- Parameter: theTag:text
-- Parameter: theFields:NSMutableDictionary
-- Parameter: interactiveMode:boolean
-- Parameter: theRecord:DEVONthink record (class 'record' / DTrc)
-- Rueckgabe: list{boolean, NSMutableDictionary}
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
					end if
					(theFields's setObject:{setCurrentValue, theTag} forKey:aDimension)
				end if
				set hasFieldBeenSet to true
			end if
		end repeat

	end tell

	logger's trace(logCtx, "exit")
	return {hasFieldBeenSet, theFields}
end setField

-- Operation: setFinderComment
-- Kurzbeschreibung: Uebernimmt einen Feldwert in den Kommentar des Records.
-- Parameter: theField:text
-- Parameter: theRecord:DEVONthink record (class 'record' / DTrc)
-- Rueckgabe: kein Rueckgabewert (Seiteneffekte)
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
			set finderComment to finderComment & theValue
			set comment of theRecord to finderComment
		end if

	end tell

	logger's trace(logCtx, "exit")
end setFinderComment

-- Operation: setName
-- Kurzbeschreibung: Berechnet den Record-Namen aus dem Namens-Template und setzt ihn bei Aenderung.
-- Parameter: theRecord:DEVONthink record (class 'record' / DTrc)
-- Parameter: theFields:NSMutableDictionary
-- Rueckgabe: kein Rueckgabewert (Seiteneffekte)
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

-- Operation: setNameForAsset
-- Kurzbeschreibung: Vergibt einen eindeutigen Asset-Namen aus Datumskomponenten und laufender Nummer.
-- Parameter: theRecord:DEVONthink record (class 'record' / DTrc)
-- Parameter: f:record/dictionary mit tagYear, tagMonth, tagDay, tagSender
-- Rueckgabe: kein Rueckgabewert (Seiteneffekte)
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

-- Operation: setTagFromCompareRecord
-- Kurzbeschreibung: Uebernimmt ein passendes Tag aus dem besten Vergleichsrecord oberhalb des Schwellwerts.
-- Parameter: theRecord:DEVONthink record (class 'record' / DTrc)
-- Parameter: theDatabase:DEVONthink database (class 'database' / DTkb)
-- Parameter: theFields:NSMutableDictionary
-- Parameter: theDimension:text
-- Rueckgabe: kein Rueckgabewert (Seiteneffekte)
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
-- Operation: subjectFromMetadata
-- Kurzbeschreibung: Liest bei PDF-Dateien den Titel aus Metadaten als Betreff.
-- Parameter: theRecord:DEVONthink record (class 'record' / DTrc)
-- Parameter: theSender:text|missing value
-- Rueckgabe: text|missing value
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

-- Operation: tagAlias
-- Kurzbeschreibung: Liefert fuer ein Tag den Alias, falls einer konfiguriert ist.
-- Parameter: theTag:text
-- Rueckgabe: text
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

-- Operation: twoDigit
-- Kurzbeschreibung: Formatiert einen Wert als zweistellige Zeichenkette.
-- Parameter: d:integer|text
-- Rueckgabe: text
on twoDigit(d)
	return text -2 thru -1 of ("00" & d)
end twoDigit

-- Operation: updateRecordsMetadata
-- Kurzbeschreibung: Aktualisiert Name, Custom Metadata und Kommentare basierend auf ermittelten Feldern.
-- Parameter: theRecords:list<DEVONthink record (class 'record' / DTrc)>
-- Rueckgabe: kein Rueckgabewert (Seiteneffekte)
on updateRecordsMetadata(theRecords)
	set logCtx to my initialize("updateRecordsMetadata")
	logger's trace(logCtx, "enter")

	tell application id "DNtp"

		set theDatabase to database of first item of theRecords

		my initializeDatabaseConfiguration(theDatabase)
		set {recordsSelected, recordsProcessed} to {0, 0}
		repeat with theRecord in theRecords
			set recordsSelected to recordsSelected + 1
			if type of theRecord is group or type of theRecord is smart group then
				set comment of theRecord to ""
			else
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
			end if
		end repeat

		tell logger to info(logCtx, "Records selected: " & recordsSelected & ", Records processed:  " & recordsProcessed)
	end tell

	logger's trace(logCtx, "exit")
end updateRecordsMetadata

-- Operation: verifyTags
-- Kurzbeschreibung: Prueft Records an einer Location auf Tag-Konsistenz und protokolliert Kennzahlen.
-- Parameter: theLocation:text (DEVONthink location prefix, z.B. '/05 Files')
-- Rueckgabe: kein Rueckgabewert (Seiteneffekte)
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

