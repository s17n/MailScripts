#@osa-lang:AppleScript
use AppleScript version "2.4"
use scripting additions

on configPath()
	return (POSIX path of (path to home folder)) & ".mailscripts/config.scpt"
end configPath

on run argv
	try
		set config to load script (my configPath())
		set logger to load script ((pMailScriptsPath of config) & "/Libs/Logger.scpt")
		tell logger to initialize()

		set chooserItems to {"0 TRACE", "1 DEBUG", "2 INFO", "3 ERROR", "Reset to config.scpt"}
		set selectedItems to choose from list chooserItems with title "Set Log Level" with prompt "Choose the effective runtime log level." without multiple selections allowed
		if selectedItems is false then return

		set selectedItem to first item of selectedItems as text
		if selectedItem is "Reset to config.scpt" then
			tell logger to removeLogLevelOverride()
		else
			tell logger to saveLogLevelOverride(first word of selectedItem)
		end if

		tell logger to initialize()
		tell logger to showLogLevel()
	on error errorMessage number errorNumber
		display alert "DEVONthink" message (errorMessage & " (" & errorNumber & ")") as warning
	end try
end run
