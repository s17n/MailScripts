#@osa-lang:AppleScript
property pScriptName : "PopClipLibrary"

use AppleScript version "2.4"
use scripting additions
use framework "Foundation"
use framework "AppKit" -- for NSEvent

property logger : missing value
property docLib : missing value
property baseLib : missing value

on initialize(loggingContext, enforceInitialize)

	if enforceInitialize or logger is missing value then
		-- Configuration
		set config to load script (POSIX path of (path to home folder) & ".mailscripts/config.scpt")
		set mailScriptsDir to pMailScriptsPath of config

		-- Logger & BaseLib
		set docLib to load script (mailScriptsDir & "/Libs/DocLibrary.scpt")
		set logger to load script (mailScriptsDir & "/Libs/Logger.scpt")
		tell logger to initialize()
		set baseLib to load script (mailScriptsDir & "/Libs/BaseLibrary.scpt")

	end if
	return pScriptName & " > " & loggingContext

end initialize

on setSubject(theText, theCallerScript)
	set logCtx to my initialize("setSubject", true)
	tell logger to debug(logCtx, "enter => " & theText)

	-- Command key pressed?
	set cmdKeyStat to (((current application's NSEvent's modifierFlags()) div (current application's NSCommandKeyMask as integer)) mod 2) > 0

	tell docLib to addSubjectText(theText)

	tell logger to debug(logCtx, "exit")
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
