#@osa-lang:AppleScript
use AppleScript version "2.3" -- Mavericks (10.9) or later
use scripting additions
use framework "Foundation"
use framework "AppKit" -- for NSEvent

property pScriptName : "PopClipLib"
property baseLib : missing value
property logger : missing value

on initialize()
	if logger is missing value then
		set config to load script (POSIX path of (path to home folder) & ".mailscripts/config.scpt")
		set logger to load script ((pMailScriptsPath of config) & "/Libs/Logger.scpt")
		tell logger to initialize()
	end if
	if baseLib is missing value then
		set config to load script (POSIX path of (path to home folder) & ".mailscripts/config.scpt")
		set baseLib to load script ((pMailScriptsPath of config) & "/Libs/BaseLibrary.scpt")
	end if
end initialize

on setSubject(theText, theCallerScript)
	my initialize()
	tell logger to debug(pScriptName, "setSubject: enter")

	-- Command key pressed?
	set cmdKeyStat to (((current application's NSEvent's modifierFlags()) div (current application's NSCommandKeyMask as integer)) mod 2) > 0

	tell application id "DNtp"
		set theRecord to content record
		set theCurrentSubject to get custom meta data for "Subject" from theRecord
		if theCurrentSubject is missing value then set theCurrentSubject to ""
		if cmdKeyStat then
			tell logger to debug(pScriptName, "cmdKeyStat cmd pressed")
		else
			tell baseLib to set theTrimmedText to trim(theText)
			set theSubjectTokenDelimiter to " "
			if (count of words of theCurrentSubject) = 1 then set theSubjectTokenDelimiter to ": "
			set theNewSubject to theCurrentSubject & theSubjectTokenDelimiter & theTrimmedText
		end if
		add custom meta data theNewSubject for "Subject" to theRecord
	end tell

	tell logger to debug(pScriptName, "setSubject: exit")
end setSubject

on setSender(theText, theCallerScript)
	my initialize()
	tell logger to debug(pScriptName, "setSender: enter")

	-- Command key pressed?
	set cmdKeyStat to (((current application's NSEvent's modifierFlags()) div (current application's NSCommandKeyMask as integer)) mod 2) > 0

	tell application id "DNtp"
		set theRecord to content record
		tell baseLib to set theTrimmedText to trim(theText)
		add custom meta data theTrimmedText for "Sender" to theRecord
	end tell

	tell logger to debug(pScriptName, "setSender: exit")
end setSender
