#@osa-lang:AppleScript
property pScriptName : "Archive Records"
property logger : missing value
property mailLib : missing value
property docLib : missing value

on initialize()
	if logger is missing value then
		set config to load script (POSIX path of (path to home folder) & ".mailscripts/config.scpt")
		set logger to load script ((pMailScriptsPath of config) & "/Libs/Logger.scpt")
		tell logger to initialize()
	end if
	if mailLib is missing value then
		set config to load script (POSIX path of (path to home folder) & ".mailscripts/config.scpt")
		set mailLib to load script ((pMailScriptsPath of config) & "/Libs/MailLibrary.scpt")
	end if
	if docLib is missing value then
		set config to load script (POSIX path of (path to home folder) & ".mailscripts/config.scpt")
		set docLib to load script ((pMailScriptsPath of config) & "/Libs/DocLibrary.scpt")
	end if
end initialize

on archiveRecords()
	try
		tell logger to debug(pScriptName, "archiveRecords: enter")
		tell application id "DNtp"

			set theSelection to the selection
			if theSelection is {} then error "Please select some contents."

			set databaseName to name of current database

			if databaseName contains "Mail" then
				tell mailLib to archiveRecords(theSelection, pScriptName)
			else
				tell docLib to archiveRecords(theSelection, pScriptName)
			end if
		end tell
	on error error_message number error_number
		if the error_number is not -128 then
			try
				display alert "DEVONthink" message error_message as warning
			on error number error_number
				if error_number is -1708 then display dialog error_message buttons {"OK"} default button 1
			end try
		end if
	end try
	tell logger to debug(pScriptName, "archiveRecords: exit")
end archiveRecords

on run {}

	my initialize()
	my archiveRecords()

end run
