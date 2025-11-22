#@osa-lang:AppleScript
use AppleScript version "2.3" -- Mavericks (10.9) or later
use scripting additions
use framework "Foundation"
use framework "AppKit" -- for NSEvent

property pScriptName : "PopClipLib"
property baseLib : missing value

on initialize()
	set log_ctx to pScriptName & "." & "initialize"
	if baseLib is missing value then
		set mailscriptsConfig to load script (POSIX path of (path to home folder) & ".mailscripts/config.scpt")
		set baseLib to load script ((pBaseLibraryPath of mailscriptsConfig))
		tell baseLib to initialize()
		tell baseLib to debug(log_ctx, "baseLib initialized")
	else
		tell baseLib to debug(log_ctx, "baseLib already initialized")
	end if
end initialize

on setSubject(theText, theCallerScript)
	my initialize()
	set log_ctx to pScriptName & "." & "setSubject"
	tell baseLib to debug(log_ctx, "enter")

	-- Command key pressed?
	set cmdKeyStat to (((current application's NSEvent's modifierFlags()) div (current application's NSCommandKeyMask as integer)) mod 2) > 0

	tell application id "DNtp"
		set theRecord to content record
		set theCurrentSubject to get custom meta data for "Subject" from theRecord
		if theCurrentSubject is missing value then set theCurrentSubject to ""
		if cmdKeyStat then
			tell baseLib to debug(log_ctx, "cmdKeyStat cmd pressed")
		else
			set theTrimmedText to my trim(theText)
			set theSubjectTokenDelimiter to " "
			if (count of words of theCurrentSubject) = 1 then set theSubjectTokenDelimiter to ": "
			set theNewSubject to theCurrentSubject & theSubjectTokenDelimiter & theTrimmedText
		end if
		add custom meta data theNewSubject for "Subject" to theRecord
	end tell

	tell baseLib to debug(log_ctx, "exit")
end setSubject

on setSender(theText, theCallerScript)
	my initialize()
	set log_ctx to pScriptName & "." & "setSender"
	tell baseLib to debug(log_ctx, "enter")

	-- Command key pressed?
	set cmdKeyStat to (((current application's NSEvent's modifierFlags()) div (current application's NSCommandKeyMask as integer)) mod 2) > 0

	tell application id "DNtp"
		set theRecord to content record
		set theTrimmedText to my trim(theText)
		add custom meta data theTrimmedText for "Sender" to theRecord
	end tell

	tell baseLib to debug(log_ctx, "exit")
end setSender

-- https://www.macscripter.net/t/trim-remove-spaces/45457
on trim(theText)
	repeat until theText does not start with " "
		set theText to text 2 thru -1 of theText
	end repeat

	repeat until theText does not end with " "
		set theText to text 1 thru -2 of theText
	end repeat

	return theText
end trim