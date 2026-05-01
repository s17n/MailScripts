#@osa-lang:AppleScript
set config to load script (POSIX path of (path to home folder) & ".mailscripts/config.scpt")
set docLib to load script pDocLibraryPath of config
set traceName to "DEVONthink Menu/Import Mail Messages___Cmd-Ctrl-Shift-I.scpt"
set traceStarted to false

try

	set theEmailDatabase to pPrimaryEmailDatabase of config
	docLib's beginPerformanceTrace(traceName)
	set traceStarted to true
	tell docLib to importMailMessages(theEmailDatabase)
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

