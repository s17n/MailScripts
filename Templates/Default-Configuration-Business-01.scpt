#@osa-lang:AppleScript
property pContentType : "ASSETS"

-- TAG GROUP NAMES
property pDayTagGroup : "01 Tag"
property pMonthTagGroup : "02 Monat"
property pYearTagGroup : "03 Jahr"
property pSenderTagGroup : "04 Sender"
property pSubjectTagGroup : "05 Subject"
property pContextTagGroup : "06 Context"

-- CLASSIFICATION
property pClassifyDate : true
property pClassificationDate : "DATE_MODIFIED"

property pClassifySender : false
property pClassifySubject : false
property pClassifyContext : false

-- METADATA
property pMdSetName : false
property pNameFormat : ""

property pMdSetCustomMetadata : true

property pMdSetFinderComments : false
property pFinderCommentsFormat : ""

-- VERIFICATION

property pVerifyDate : true
property pVerifySender : false
property pVerifySubject : false

-- LOG LEVEL: 1: DEBUG, 2: INFO, 3: ERROR
property pLogLevel : 2
