#@osa-lang:AppleScript
-- Import selected Mail messages to DEVONthink.


tell application id "DNtp"

	set theSelection to selection
	repeat with theRecord in theSelection
		try
			tell theRecord
				set {theId, theName, theFilename, theMetadata} ¬
					to {the id, the name, the filename, the meta data}
			end tell
			display dialog "Record Data: " & (return) ¬
				& "Name: " & theName & (return) ¬
				& "Filename: " & theFilename & (return) ¬
				& "Id: " & theId & (return) ¬
				& "Metadata: " --& theMetadata
		on error error_message number error_number
			if error_number is not -128 then display alert "Devonthink" message error_message as warning
		end try
	end repeat

end tell
