#@osa-lang:AppleScript
-- Note: This file needs to be saved to ~/.mailscripts/config.scpt.
--       Properties needs to be adjusted.

-- Path to the MailScripts folder
property pMailScriptsPath : "/Users/.../Projects/MailScripts"

-- Path to Database Configurations
property pDatabaseConfigurationFolder : "/Users/.../Library/Mobile Documents/com~apple~CloudDocs/MailScripts"

-- Path to exiftool
property pExiftool : "/opt/homebrew/bin/exiftool"

-- Mail Database
property pPrimaryEmailDatabase : "Mail"

-- Full qualified path to MailScript's Libraries - this doesn't needs to be changed
property pLogger : pMailScriptsPath & "/Libs/Logger.scpt"
property pBaseLibraryPath : pMailScriptsPath & "/Libs/BaseLibrary.scpt"
property pMailLibraryPath : pMailScriptsPath & "/Libs/MailLibrary.scpt"
property pDocLibraryPath : pMailScriptsPath & "/Libs/DocLibrary.scpt"
property pPopClipLibraryPath : pMailScriptsPath & "/Libs/PopClipLibrary.scpt"

property pLogLevel : 2 -- 1 DEBUG, 2 INFO, 3 ERROR
