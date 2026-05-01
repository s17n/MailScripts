#@osa-lang:AppleScript
set config to load script (POSIX path of (path to home folder) & ".mailscripts/config.scpt")
set docLib to load script pDocLibraryPath of config
set traceName to "DEVONthink Menu/Update Dimensions Cache___Cmd-Ctrl-Shift-D.scpt"
set traceStarted to false

try
	tell application id "DNtp"
		set theDatabaseName to name of current database
	end tell

	docLib's beginPerformanceTrace(traceName)
	set traceStarted to true
	docLib's updateDimensionsCache(theDatabaseName)
	docLib's finishPerformanceTrace(traceName)
	set traceStarted to false

on error error_message number error_number
	if traceStarted then
		try
			docLib's finishPerformanceTrace(traceName)
		end try
	end if
	display alert "DEVONthink" message error_message as warning
end try

