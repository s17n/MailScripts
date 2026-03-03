#@osa-lang:AppleScript
property pContentType : "DOCUMENTS"

-- Root-Tag-Gruppe fuer Dimensionen; wird in initializeDimensions() geladen und in handleUncategorizedTag() als Zielpfad genutzt.
property pDimensionsHome : "/Tags"

-- Kardinalitaet je Dimension (Dimension, max. Anzahl Werte). In setField() wird > 0 als "nur ein Wert erlaubt" behandelt.
property pDimensionsConstraints : {{"01 Day", "1"}, {"02 Month", "1"}, {"03 Year", "1"}, {"04 Sender", "1"}, {"05 Subject", "1"}}

-- Datumsdimensionen in fixer Reihenfolge {Jahr, Monat, Tag}; wird in setDateTags(), setCustomMetadata(DATE), replaceFieldPlaceholder({Decades}) und Validierung genutzt.
property pDateDimensions : {"03 Year", "02 Month", "01 Day"}

-- Dimensionen, die in classifyRecords() via setTagFromCompareRecord() aus aehnlichen Records uebernommen werden, falls noch leer.
property pCompareDimensions : {"04 Sender", "05 Subject", "06 Context"}

-- Mindest-Score fuer Vergleichsrecords in setTagFromCompareRecord(); darunter werden keine Tags uebernommen.
property pCompareDimensionsScoreThreshold : 0.25

-- Datumsquelle fuer Auto-Klassifikation (getClassificationDate): DOCUMENT_CREATION_DATE | DATE_MODIFIED | DATE_CREATED | RECORD_CREATION_DATE; leer deaktiviert Datumsklassifikation.
property pClassificationDate : "DOCUMENT_CREATION_DATE"

-- Name-Template fuer setName(); Platzhalter [Dimension] werden ueber replaceDimensionPlaceholders() ersetzt; leer deaktiviert Umbenennung.
property pNameTemplate : "[03 Year]-[02 Month]-[01 Day]_[04 Sender]_[05 Subject]"

-- Custom-Metadata-Feldnamen; wird in updateRecordsMetadata() iteriert. Wichtig: erstes Feld wird in setCustomMetadata() als Betrag-Referenz verwendet.
property pCustomMetadataFields : {"Betrag", "Date", "Sender", "Subject"}

-- Dimensions-Mapping je Custom-Metadata-Feld (indexbasiert zu pCustomMetadataFields); bei DATE muss ein Triple {Jahr, Monat, Tag} sein.
property pCustomMetadataDimensions : {"", pDateDimensions, "04 Sender", "05 Subject"}

-- Typ je Custom-Metadata-Feld (indexbasiert): AMOUNT | DATE | TEXT; steuert Branching in setCustomMetadata().
property pCustomMetadataTypes : {"AMOUNT", "DATE", "TEXT", "TEXT"}

-- Template je Custom-Metadata-Feld (indexbasiert, v.a. fuer TEXT); unterstuetzt [Dimension], [[Dimension]], {Text}, {Amount}.
property pCustomMetadataTemplates : {"", "", "[04 Sender]{Text}", "[05 Subject]{Text}{Amount}[06 Context][[09 Marker]]"}

-- Trenner zwischen berechnetem Teil und Freitext in TEXT-Custom-Metadata; genutzt beim Parsen und Schreiben (extractCustomTextFromCmdValue/setCustomMetadata).
property pCustomMetadataFieldSeparator : ": "

-- Liste von Custom-Metadata-Feldern, die nach updateRecordsMetadata() in Kommentare kopiert werden (setFinderComment()).
property pCommentsFields : {"Sender", "Subject"}

-- Kategorien fuer Betrag-Autofill (AMOUNT), als String; wird per words of in Liste umgewandelt und gegen Tag-Werte geprueft.
property pAmountLookupCategories : "Rechnung"

-- Archiv-Zieltemplate fuer archiveRecords(); unterstuetzt [Dimension], {Decades} sowie optional {Year}/{Month}/{Day} (Fallback bei leerem pDateDimensions).
property pFilesHome : "/05 Files/{Decades}[03 Year]/[02 Month]"

-- Alias-Mapping Tag -> Kurztext; angewendet in tagAlias() fuer Namens-/Textaufbau in setCustomMetadata().
property pTagAliases : {{"analog", "A"}, {"digital", "D"}}

-- Monatsmapping {MM, Name}; wird in buildMonthDictionaries() fuer Umrechnung Name<->Nummer (replaceDimensionPlaceholders, setDateTags, DATE-Custom-Metadata) genutzt.
property pMonths : {{"01", "Januar"}, {"02", "Februar"}, {"03", "März"}, {"04", "April"}, {"05", "Mai"}, {"06", "Juni"}, ¬
	{"07", "Juli"}, {"08", "August"}, {"09", "September"}, {"10", "Oktober"}, {"11", "November"}, {"12", "Dezember"}}

-- Logger-Level fuer DocLibrary (initializeDatabaseConfiguration): 0 TRACE, 1 DEBUG, 2 INFO, 3 ERROR.
property pLogLevel : 2
