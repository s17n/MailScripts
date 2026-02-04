#@osa-lang:AppleScript
property pScriptName : "Classify Document"

set config to load script (POSIX path of (path to home folder) & ".mailscripts/config.scpt")
set logger to load script ((pMailScriptsPath of config) & "/Libs/Logger.scpt")


tell logger
	initialize()
	showLogLevel()
end tell
