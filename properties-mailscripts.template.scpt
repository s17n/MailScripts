#@osa-lang:AppleScript
-- full qualified path to MailLibrary
property pMailLibraryPath : "Users:[Username]:Projects:AppleScripts:MailScripts:MailLibrary.scpt"

-- name of the mailbox account in Apple Mail used for import
property pMailboxAccount : "Google"

-- name of the mailbox folder from where the message will be imported in DEVONthink
property pMailboxImportFolder : "Zu archivieren"

-- the mailbox folder where the message will be moved into when imported in DEVONthink
property pMailboxArchiveFolder : "Archiviert"

-- the DEVONthink database the message will be imported into
property pDtImportDatabase : "Mail"

-- the DEVONthink folder the message will be filed; different folder for mail rules
property pDtImportFolder_1 : "Inbox"
property pDtImportFolder_2 : ""
property pDtImportFolder_3 : ""
property pDtImportFolder_4 : ""
property pDtImportFolder_5 : ""

property pDtArchiveRoot : ""

-- this string is used when the message subject is empty
property pNoSubjectString : "(no subject)"

property pDtSortBySender : false