#@osa-lang:AppleScript
property pContentType : "DOCUMENTS"

-- TAG GROUP NAMES
property pDayTagGroup : "01 Tag"
property pMonthTagGroup : "02 Monat"
property pYearTagGroup : "03 Jahr"
property pSenderTagGroup : "04 Sender"
property pSubjectTagGroup : "05 Subject"
property pContextTagGroup : "06 Context"

-- CLASSIFICATION
property pClassifyDate : true
property pClassificationDate : "DATE_DOCUMENT"

property pClassifySender : true
property pClassifySubject : true
property pClassifyContext : true

-- METADATA
property pMdSetName : true
property pNameFormat : "NAME_DOCUMENT"

property pMdSetCustomMetadata : true

property pMdSetFinderComments : true
property pFinderCommentsFormat : "FINDERCOMMENTS_DOCUMENT"

-- VERIFICATION
property pVerifyDate : true
property pVerifySender : true
property pVerifySubject : true

--- OTHER
property pScoreThreshold : 0.05
property pSentTag : "Postausgang"
property pCcTag : "In-Kopie"
property pSubjectsWithBetrag : "Beleg Rechnung Quittung"
property pCustomMetadataFieldSeparator : ": "

-- 1 DEBUG, 2 INFO, 3 ERROR
property pLogLevel : 2