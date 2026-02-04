#@osa-lang:AppleScript
property pScriptName : "Archive Records"

property logger : missing value
property mailLib : missing value
property docLib : missing value

on initialize(loggingContext, enforceInitialize)

	if enforceInitialize or logger is missing value then
		-- Configuration
		set config to load script (POSIX path of (path to home folder) & ".mailscripts/config.scpt")
		set mailScriptsDir to pMailScriptsPath of config

		-- Libraries & Logger
		set docLib to load script (mailScriptsDir & "/Libs/DocLibrary.scpt")
		set mailLib to load script (mailScriptsDir & "/Libs/MailLibrary.scpt")
		set logger to load script (mailScriptsDir & "/Libs/Logger.scpt")
		tell logger to initialize()
	end if
	return pScriptName & " > " & loggingContext

end initialize

on processRecords()
	set logCtx to my initialize("processRecords", false)
	tell logger to debug(logCtx, "enter")

	try
		tell application id "DNtp"
			set theSelection to the selection
			if theSelection is {} then error "Please select some contents."

			set databaseName to name of current database

			if databaseName contains "Mail" then
				mailLib's archiveRecords(theSelection, pScriptName)
			else
				docLib's archiveRecords(theSelection)
			end if
		end tell

	on error error_message number error_number
		tell logger to info(logCtx, (error_number as text) & ": " & error_message)
		display alert "DEVONthink" message error_message as warning
	end try

	tell logger to debug(logCtx, "exit")
end processRecords

on run {}
	set logCtx to my initialize("run", true)
	tell logger to debug(logCtx, "enter")

	my processRecords()

	tell logger to debug(logCtx, "exit")
end run
