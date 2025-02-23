#@osa-lang:AppleScript
property pScriptName : "Copy Item Link as Markdown Link"

set mailscriptsConfig to load script (POSIX path of (path to home folder) & ".mailscripts/config.scpt")
set docLib to (load script (pDocLibraryPath of mailscriptsConfig))

tell application id "DNtp"
	set theDatabase to name of current database
	set theSelection to selection

	tell application id "DNtp"

		set theClipboardText to ""
		repeat with theRecord in theSelection
			set theMdLink to ""
			set theName to name of theRecord
			set theFilename to filename of theRecord
			set theType to type of theRecord
			set theReferenceURL to reference URL of theRecord
			set theURLParameter to ""
			set openExternally to "?openexternally=1"

			if theDatabase contains "Assets" then
				set theClipboardText to "Assets: "
				set theMdLink to theFilename

			else if theDatabase contains "Mail" then
				set theClipboardText to "Email: "
				tell theRecord
					set {theId, theName, theFilename, theMetadata} ¬
						to {the id, the name, the filename, the meta data}
					set {theAuthorEmail, theAuthorName, theSubject} ¬
						to {the kMDItemAuthorEmailAddresses of theMetadata, the kMDItemAuthors of theMetadata, the kMDItemSubject of theMetadata}
				end tell

				set the formattedDate to my format(get creation date of theRecord, true)
				set theMdLink to theMdLink & formattedDate & ": " & theAuthorName & ": " & theSubject

			else if (theDatabase contains "Dokumente") or (theDatabase contains "Beleg") then

				if (theDatabase contains "Dokumente") then
					set theClipboardText to "Dokument: "
				else if theDatabase contains "Beleg" then
					set theClipboardText to "Beleg: "
				end if
				set theDate to get custom meta data for "Date" from theRecord
				set theSender to get custom meta data for "Sender" from theRecord
				set theSubject to get custom meta data for "Subject" from theRecord

				set the formattedDate to my format(theDate, false)
				set theMdLink to theMdLink & formattedDate & ": " & theSender & ": " & theSubject
			end if

			if (theType as string) is not equal to "group" then
				set theURLParameter to openExternally
			end if
			set theClipboardText to theClipboardText & "[" & theMdLink & "](" & theReferenceURL & theURLParameter & ")"
		end repeat
		set the clipboard to {text:(theClipboardText as string), Unicode text:theClipboardText}
	end tell
end tell

on format(theDate, includeTime)
	set resultTime to ""
	if includeTime then
		set resultTime to resultTime & " "
		set resultTime to resultTime & zero_pad(hours of theDate as integer, 2)
		set resultTime to resultTime & ":"
		set resultTime to resultTime & zero_pad(minutes of theDate as integer, 2)
	end if
	set result to ""
	set result to result & zero_pad(day of theDate as integer, 2)
	set result to result & "."
	set result to result & zero_pad(month of theDate as integer, 2)
	set result to result & "."
	set result to result & characters 3 thru 4 of ((year of theDate as integer) as string)
	set result to result & resultTime
	return result
end format

-- https://gist.github.com/Glutexo/78c170e2e314f0eacc1a
on zero_pad(value, string_length)
	set string_zeroes to ""
	set digits_to_pad to string_length - (length of (value as string))
	if digits_to_pad > 0 then
		repeat digits_to_pad times
			set string_zeroes to string_zeroes & "0" as string
		end repeat
	end if
	set padded_value to string_zeroes & value as string
	return padded_value
end zero_pad

