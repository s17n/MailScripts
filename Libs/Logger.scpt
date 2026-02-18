#@osa-lang:AppleScript
property pScriptName : "Logger"

property LOG_LEVEL : 2

property LOG_LEVEL_TRACE : 0
property LOG_LEVEL_DEBUG : 1
property LOG_LEVEL_INFO : 2
property LOG_LEVEL_WARN : 3

on initialize()
	my debug(pScriptName, "initialize: enter")

	set mailscriptsConfig to load script (POSIX path of (path to home folder) & ".mailscripts/config.scpt")
	set LOG_LEVEL to (pLogLevel of mailscriptsConfig)

	my debug(pScriptName, "initialize: exit")
end initialize

on setLogLevel(logLevel)
	set LOG_LEVEL to logLevel
	my debug(pScriptName, "setLogLevel to " & logLevel)
end setLogLevel

on showLogLevel()
	set log_ctx to pScriptName & "." & "showLogLevel"
	my info(log_ctx, "Current log level is: " & LOG_LEVEL)
end showLogLevel

on trace(theMethod, theMessage)
	if LOG_LEVEL ≤ LOG_LEVEL_TRACE then
		tell application id "DNtp" to log message "TRACE: " & theMethod info theMessage
	end if
end trace

on debug(theMethod, theMessage)
	if LOG_LEVEL ≤ LOG_LEVEL_DEBUG then
		tell application id "DNtp" to log message "DEBUG: " & theMethod info theMessage
	end if
end debug

on info(theMethod, theMessage)
	if LOG_LEVEL ≤ LOG_LEVEL_INFO then
		tell application id "DNtp" to log message "INFO: " & theMethod info theMessage
	end if
end info

on debug_r(theRecord, theMessage)
	if LOG_LEVEL ≤ LOG_LEVEL_DEBUG then
		tell application id "DNtp" to log message info theMessage record theRecord
	end if
end debug_r

on info_r(theRecord, theMessage)
	if LOG_LEVEL ≤ LOG_LEVEL_INFO then
		tell application id "DNtp" to log message info theMessage record theRecord
	end if
end info_r

to display given msg:theMsg : "", record:theRecord : missing value
	tell application id "DNtp"
		if theRecord is missing value then
			log message "Info" info theMsg
		else
			log message info theMsg record theRecord
		end if
	end tell
end display
