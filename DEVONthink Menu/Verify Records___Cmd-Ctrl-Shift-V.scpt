#@osa-lang:AppleScript
set mailscriptsConfig to load script (POSIX path of (path to home folder) & ".mailscripts/config.scpt")
set docLib to (load script (pDocLibraryPath of mailscriptsConfig))
set traceName to "DEVONthink Menu/Verify Records___Cmd-Ctrl-Shift-V.scpt"
set traceStarted to false

try
	-- set locationSuffix to "2010-2019/2015/11" -- issue, record lag in 05 in zwei Foldern
	set theLocation to "/05 Files"
	docLib's beginPerformanceTrace(traceName)
	set traceStarted to true
	tell docLib to verifyTags(theLocation)
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
