#@osa-lang:AppleScript
set configPath to (POSIX path of (path to home folder)) & ".mailscripts/config.scpt"
set config to load script configPath
set docLib to load script (pDocLibraryPath of config)
set traceName to "DEVONthink Menu/Open Context___Cmd-Option-Shift-6.scpt"
set traceStarted to false

try
	tell application id "DNtp" to set theSelection to every selected record

	set theSmartGroupSpecifier to {dimension:"06 Context", customMetadataField:"", smartgroupsFolder:"03 Resources/Context"}
	docLib's beginPerformanceTrace(traceName)
	set traceStarted to true
	docLib's openSmartGroup(theSmartGroupSpecifier, theSelection)
	docLib's finishPerformanceTrace(traceName)
	set traceStarted to false
on error errorMessage number errorNumber
	if traceStarted then
		try
			docLib's finishPerformanceTrace(traceName)
		end try
	end if
	display alert "DEVONthink" message (errorMessage & " (" & errorNumber & ")") as warning
end try
