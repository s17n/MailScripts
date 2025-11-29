#@osa-lang:AppleScript
property pScriptName : "Open Sender"
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
		set doclLib to load script ((pMailScriptsPath of config) & "/Libs/DocLibrary.scpt")
	end if
end initialize

on openSender()
	try
		tell logger to debug(pScriptName, "openSender: enter")
		tell application id "DNtp"

			set theSelection to the selection
			if theSelection is {} then error "Please select some contents."


			set theRecord to first item of theSelection

			set theSender to get custom meta data for "Sender" from theRecord
			set theSmartSearchRecord to get record at "/03 Resources/General/by Sender/" & theSender
			open window for record theSmartSearchRecord

			-- set root of main window 1 to "/03 Resources/General/by Sender/" & theSender
			-- open tab for record theSmartSearchRecord in window 1
			-- set selection of main window 1 to theSmartSearchRecord

			tell logger to debug(pScriptName, "Sender: " & theSender)

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
	tell logger to debug(pScriptName, "openSender: exit")
end openSender

on run {}

	my initialize()
	my openSender()

end run
