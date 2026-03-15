#@osa-lang:AppleScript
use AppleScript version "2.4"
use scripting additions

on hasWorkerFlag(theArgs)
	if class of theArgs is not list then return false
	repeat with anArg in theArgs
		try
			if (anArg as text) is "--worker" then return true
		end try
	end repeat
	return false
end hasWorkerFlag

on run argv
	if my hasWorkerFlag(argv) then
		my runCore()
	else
		try
			set selfPath to POSIX path of (path to me)
			do shell script ("/usr/bin/osascript -l AppleScript " & quoted form of selfPath & " --worker")
		on error errorMessage number errorNumber
			display alert "DEVONthink" message ("Failed to launch external worker: " & errorMessage & " (" & errorNumber & ")") as warning
		end try
	end if
end run

on runCore()
	set configPath to (POSIX path of (path to home folder)) & ".mailscripts/config.scpt"
	set config to load script configPath
	set docLib to load script (pDocLibraryPath of config)

	try
		tell application id "DNtp" to set theSelection to get selection
		if theSelection is {} then error "Please select some contents."

		docLib's classifyRecords(theSelection)
	on error errorMessage number errorNumber
		display alert "DEVONthink" message (errorMessage & " (" & errorNumber & ")") as warning
	end try
end runCore
