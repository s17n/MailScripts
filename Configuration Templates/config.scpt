#@osa-lang:AppleScript
-- NOTE: This file needs to be saved to ~/.mailscripts/config.scpt
--       and properties needs to be checked and adjusted.

-- Path to the MailScripts folder
property pMailScriptsPath : "/Users/.../Projects/MailScripts"

-- Database Configuration folder
property pDatabaseConfigurationFolder : "/Users/.../Library/Mobile Documents/com~apple~CloudDocs/MailScripts"

-- Path to exiftool
property pExiftool : "/opt/homebrew/bin/exiftool"

-- Mail Database (only needed for content type EMAILS)
property pPrimaryEmailDatabase : "Mail"

-- Full qualified path to MailScript's Libraries - usually this doesn't needs to be changed
property pLogger : pMailScriptsPath & "/Libs/Logger.scpt"
property pBaseLibraryPath : pMailScriptsPath & "/Libs/BaseLibrary.scpt"
property pMailLibraryPath : pMailScriptsPath & "/Libs/MailLibrary.scpt"
property pDocLibraryPath : pMailScriptsPath & "/Libs/DocLibrary.scpt"
property pPopClipLibraryPath : pMailScriptsPath & "/Libs/PopClipLibrary.scpt"

-- Default Log Level - 1 DEBUG, 2 INFO, 3 ERROR
property pLogLevel : 2
