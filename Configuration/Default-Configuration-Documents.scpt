#@osa-lang:AppleScript
property pContentType : "DOCUMENTS"

-- Root tag group for dimensions; loaded in initializeDimensions() and used as target path in handleUncategorizedTag().
property pDimensionsHome : "/Tags"

-- Cardinality per dimension (dimension, max. number of values). In setField(), values greater than 0 mean "only one value allowed".
property pDimensionsConstraints : {{"01 Day", "1"}, {"02 Month", "1"}, {"03 Year", "1"}, {"04 Sender", "1"}, {"05 Subject", "1"}}

-- Date dimensions in fixed order {year, month, day}; used in setDateTags(), setCustomMetadata(DATE), replaceFieldPlaceholder({Decades}), and validation.
property pDateDimensions : {"03 Year", "02 Month", "01 Day"}

-- Dimensions copied from similar records in classifyRecords() via setTagFromCompareRecord() when still empty.
property pCompareDimensions : {"04 Sender", "05 Subject", "06 Context"}

-- Minimum score for compare records in setTagFromCompareRecord(); below this threshold no tags are copied.
property pCompareDimensionsScoreThreshold : 0.25

-- Date source for auto-classification (getClassificationDate): DOCUMENT_CREATION_DATE | DATE_MODIFIED | DATE_CREATED | RECORD_CREATION_DATE; empty disables date classification.
property pClassificationDate : "DOCUMENT_CREATION_DATE"

-- Name template for setName(); [Dimension] placeholders are replaced via replaceDimensionPlaceholders(); empty disables renaming.
property pNameTemplate : "[03 Year]-[02 Month]-[01 Day]_[04 Sender]_[05 Subject]"

-- Custom metadata field names; iterated in updateRecordsMetadata(). The first field is used as amount reference in setCustomMetadata().
property pCustomMetadataFields : {"Betrag", "Date", "Sender", "Subject"}

-- Dimension mapping per custom metadata field (index-aligned to pCustomMetadataFields); DATE entries must be a {year, month, day} triple.
property pCustomMetadataDimensions : {"", pDateDimensions, "04 Sender", "05 Subject"}

-- Type per custom metadata field (index-aligned): AMOUNT | DATE | TEXT; controls branching in setCustomMetadata().
property pCustomMetadataTypes : {"AMOUNT", "DATE", "TEXT", "TEXT"}

-- Template per custom metadata field (index-aligned, mainly for TEXT); supports [Dimension], [[Dimension]], {Text}, {Amount}.
property pCustomMetadataTemplates : {"", "", "[04 Sender]{Text}", "[05 Subject]{Text}{Amount}[06 Context][[09 Marker]]"}

-- Separator between computed content and free text in TEXT custom metadata; used for parsing and writing (extractCustomTextFromCmdValue/setCustomMetadata).
property pCustomMetadataFieldSeparator : ": "

-- Custom metadata fields copied into comments after updateRecordsMetadata() (setFinderComment()).
property pCommentsFields : {"Sender", "Subject"}

-- Dimension values enabling amount autofill (AMOUNT), as a string; converted with "words of" and checked against tag values.
property pAmountLookupDimensionValues : "Rechnung"

-- Archive target template for archiveRecords(); supports [Dimension], {Decades}, and optional {Year}/{Month}/{Day} (fallback when pDateDimensions is empty).
property pFilesHome : "/05 Files/{Decades}[03 Year]/[02 Month]"

-- Alias mapping tag -> short text; applied in tagAlias() for name/text composition in setCustomMetadata().
property pTagAliases : {{"analog", "A"}, {"digital", "D"}}

-- Month mapping {MM, name}; used in buildMonthDictionaries() to convert name <-> number (replaceDimensionPlaceholders, setDateTags, DATE custom metadata).
property pMonths : {{"01", "Januar"}, {"02", "Februar"}, {"03", "März"}, {"04", "April"}, {"05", "Mai"}, {"06", "Juni"}, ¬
	{"07", "Juli"}, {"08", "August"}, {"09", "September"}, {"10", "Oktober"}, {"11", "November"}, {"12", "Dezember"}}

-- Logger level for DocLibrary (initializeDatabaseConfiguration): 0 TRACE, 1 DEBUG, 2 INFO, 3 ERROR.
property pLogLevel : 2
