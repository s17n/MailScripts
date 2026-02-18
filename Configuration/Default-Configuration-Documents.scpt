#@osa-lang:AppleScript
-- Dimensions
property pDimensionsHome : "/Tags"
property pDateDimensions : {"03 Year", "02 Month", "01 Day"} -- Reihenfolge ist wichtig: Jahr, Monat, Tag
property pCompareDimensions : {"04 Sender", "05 Subject", "06 Context"}

-- Date for auto-classificaton. Leave empty when auto-classification for date is not required.
property pClassificationDate : "DATE_DOCUMENT"

-- Filename format. Leave empty when filename is not required.
property pNameFormat : "[03 Year]-[02 Month]-[01 Day]_[04 Sender]_[05 Subject]"

property pCustomMetadataFields : {"Betrag", "Date", "Sender", "Subject"} -- Betrag muss als erstes stehen
property pCustomMetadataDimensions : {"", pDateDimensions, "04 Sender", "05 Subject"}
property pCustomMetadataTypes : {"AMOUNT", "DATE", "TEXT", "TEXT"}
property pCustomMetadataTemplates : {"", "", "[04 Sender]{Text}", "[05 Subject]{Text}{Amount}[06 Context][[09 Marker]]"}

property pCommentsFields : {"Sender", "Subject"}

-- VERIFICATION
property pVerifyDate : true
property pVerifySender : true
property pVerifySubject : true

--- OTHER
property pScoreThreshold : 0.25
property pAmountCategories : "Beleg Rechnung Quittung Kostenbescheid"
property pCustomMetadataFieldSeparator : ": "

property pMonths : {{"01", "Januar"}, {"02", "Februar"}, {"03", "März"}, {"04", "April"}, {"05", "Mai"}, {"06", "Juni"}, ¬
	{"07", "Juli"}, {"08", "August"}, {"09", "September"}, {"10", "Oktober"}, {"11", "November"}, {"12", "Dezember"}}

-- 0 TRACE, 1 DEBUG, 2 INFO, 3 ERROR
property pLogLevel : 2