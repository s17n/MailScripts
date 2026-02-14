#@osa-lang:AppleScript
property pContentType : "EMAILS"

-- name of the mailbox account in Apple Mail used for import
property pMailboxAccount : "Google"

-- name of the mailbox folder from where the message will be imported in DEVONthink
property pMailboxImportFolder : "INBOX"

-- the mailbox folder where the message will be moved into when imported in DEVONthink
property pMailboxArchiveFolder : "Archiv"

-- the DEVONthink database the message will be imported into
property pDtImportDatabase : "Mail"

-- the DEVONthink folder the message will be filed; different folder for mail rules
property pDtImportFolder_1 : ""
property pDtImportFolder_2 : ""
property pDtImportFolder_3 : ""
property pDtImportFolder_4 : ""
property pDtImportFolder_5 : ""

property pDtArchiveRoot : ""

-- used when a message subject is empty
property pNoSubjectString : "(no subject)"

property pDelayBeforeImport : 5

-- sort message by senders contact group
property pDtSortBySender : false

-- 1 DEBUG, 2 INFO, 3 ERROR
property pLogLevel : 2
