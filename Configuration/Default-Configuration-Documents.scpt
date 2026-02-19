#@osa-lang:AppleScript
-- Dimensions
property pDimensionsHome : "/Tags"
property pDateDimensions : {"03 Year", "02 Month", "01 Day"} -- Reihenfolge ist wichtig: Jahr, Monat, Tag
property pCompareDimensions : {"04 Sender", "05 Subject", "06 Context"}
property pCompareDimensionsScoreThreshold : 0.25

-- Date for auto-classificaton. Leave empty when auto-classification for date is not required.
property pClassificationDate : "DATE_DOCUMENT"

-- Name format. Leave empty when filename doesn't needs to be set.
property pNameFormat : "[03 Year]-[02 Month]-[01 Day]_[04 Sender]_[05 Subject]"

-- Custom Metadata Definition
property pCustomMetadataFields : {"Betrag", "Date", "Sender", "Subject"} -- Betrag muss als erstes stehen
property pCustomMetadataDimensions : {"", pDateDimensions, "04 Sender", "05 Subject"}
property pCustomMetadataTypes : {"AMOUNT", "DATE", "TEXT", "TEXT"}
property pCustomMetadataTemplates : {"", "", "[04 Sender]{Text}", "[05 Subject]{Text}{Amount}[06 Context][[09 Marker]]"}
property pCustomMetadataFieldSeparator : ": "

-- Custom Metadata that will be copied into the Comments fields.
property pCommentsFields : {"Sender", "Subject"}

--- Other
property pAmountLookupCategories : "Rechnung"

property pFilesHome : "/05 Files/{Decades}[03 Year]/[02 Month]"

-- Verification
property pDimensionConstraints : {{"01 Day", "1"}, {"02 Month", "1"}, {"03 Year", "1"}, {"04 Sender", "1"}, {"05 Subject", "1"}}

property pTagAliases : {{"analog", "A"}, {"digital", "D"}}

property pMonths : {{"01", "Januar"}, {"02", "Februar"}, {"03", "März"}, {"04", "April"}, {"05", "Mai"}, {"06", "Juni"}, ¬
	{"07", "Juli"}, {"08", "August"}, {"09", "September"}, {"10", "Oktober"}, {"11", "November"}, {"12", "Dezember"}}

-- 0 TRACE, 1 DEBUG, 2 INFO, 3 ERROR
property pLogLevel : 2