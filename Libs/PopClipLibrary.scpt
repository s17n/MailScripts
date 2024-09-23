#@osa-lang:AppleScript
use AppleScript version "2.3" -- Mavericks (10.9) or later
use scripting additions
use framework "Foundation"
use framework "AppKit" -- for NSEvent

on setSubject(theText, theCallerScript)

	-- Command key pressed?
	set cmdKeyStat to (((current application's NSEvent's modifierFlags()) div (current application's NSCommandKeyMask as integer)) mod 2) > 0

	tell application id "DNtp"
		set theRecord to content record
		set theOldSubject to get custom meta data for "Subject" from theRecord
		if cmdKeyStat then
			set theOldSubject to theText
		else
			set theTrimmedText to my trim(theText)
			set theSubjectTokenDelimiter to " "
			if (count of words of theOldSubject) = 1 then set theSubjectTokenDelimiter to " - "
			set theSubject to theOldSubject & theSubjectTokenDelimiter & theTrimmedText
		end if
		add custom meta data theSubject for "Subject" to theRecord
	end tell
end setSubject

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