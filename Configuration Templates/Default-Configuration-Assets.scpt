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
property pClassificationDate : "DATE_CREATED"

property pClassifySender : false
property pClassifySubject : false
property pClassifyContext : false

-- METADATA
property pMdSetName : true
property pNameFormat : "NAME_ASSET"

property pMdSetCustomMetadata : true

property pMdSetFinderComments : true
property pFinderCommentsFormat : "FINDERCOMMENTS_ASSET"

-- VERIFICATION
property pVerifyDate : true
property pVerifySender : true
property pVerifySubject : false

-- OTHER
property pAssetsBaseFolder : "/Users/.../Library/Mobile Documents/com~apple~CloudDocs/Assets"
property pAblageLatestFolder : "10 Inventory"
property pAblageLookupLocation : "/02 Areas/Ablage/[alle]/"

property pCameraCaptureSender : "Camera-C2"
property pCameraCaptureSubject : "Capture"

property pAblageSender : "Camera-C2"
property pAblageSubject : "Ablage"

property pObjectSender : "Camera-C2"
property pObjectSubject : "Objekt"

property pCaptureContextConfig : "/Users/.../Library/Mobile Documents/com~apple~CloudDocs/Assets/09 Configuration/capture-contexts.json"

property pFolderConfig : "/Users/.../Library/Mobile Documents/com~apple~CloudDocs/Assets/09 Configuration/ablage-itemlinks.json"

-- 1 DEBUG, 2 INFO, 3 ERROR
property pLogLevel : 2
