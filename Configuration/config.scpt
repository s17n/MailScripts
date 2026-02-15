#@osa-lang:AppleScript
-- NOTE: This file needs to be stored at ~/.mailscripts/config.scpt
--       Property pMailScriptsPath must be set to your installation folder.

-- Path to the MailScripts folder
property pMailScriptsPath : "/Users/.../Projects/MailScripts"

-- Database Configuration folder - per default this is MailScript's Configuration folder
property pDatabaseConfigurationFolder : pMailScriptsPath & "/Configuration"

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
