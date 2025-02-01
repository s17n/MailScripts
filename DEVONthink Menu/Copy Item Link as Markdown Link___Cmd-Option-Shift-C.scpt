#@osa-lang:AppleScript
property pScriptName : "Copy Item Link as Markdown Link"

set mailscriptsConfig to load script (POSIX path of (path to home folder) & ".mailscripts/config.scpt")
set docLib to (load script (pDocLibraryPath of mailscriptsConfig))

tell application id "DNtp"
	set theDatabase to name of current database
	set theSelection to selection

	tell application id "DNtp"

		set mdLink to ""
		repeat with theRecord in theSelection
			set theMarkdownText to ""
			set theName to name of theRecord
			set theReferenceURL to reference URL of theRecord
			set theReferenceURLParam to "?openexternally=1"

			if theDatabase contains "Mail" then

				tell theRecord
					set {theId, theName, theFilename, theMetadata} ¬
						to {the id, the name, the filename, the meta data}
					set {theAuthorEmail, theAuthorName, theSubject} ¬
						to {the kMDItemAuthorEmailAddresses of theMetadata, the kMDItemAuthors of theMetadata, the kMDItemSubject of theMetadata}
				end tell

				set the formattedDate to my format(get creation date of theRecord)
				set theMarkdownText to formattedDate & ": " & theAuthorName & ": " & theSubject

			else if theDatabase contains "Dokumente" then

				set theDate to get custom meta data for "Date" from theRecord
				set theSender to get custom meta data for "Sender" from theRecord
				set theSubject to get custom meta data for "Subject" from theRecord

				set the formattedDate to my format(theDate)
				set theMarkdownText to formattedDate & ": " & theSender & ": " & theSubject
			end if
			set mdLink to "[" & theMarkdownText & "](" & theReferenceURL & theReferenceURLParam & ")"
		end repeat
		set the clipboard to {text:(mdLink as string), Unicode text:mdLink}
	end tell
end tell

on format(theDate)
	set result to ""
	set result to result & zero_pad(day of theDate as integer, 2)
	set result to result & "."
	set result to result & zero_pad(month of theDate as integer, 2)
	set result to result & "."
	set result to result & (year of theDate as integer) as string
	set result to result & " "
	set result to result & zero_pad(hours of theDate as integer, 2)
	set result to result & ":"
	set result to result & zero_pad(minutes of theDate as integer, 2)
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

