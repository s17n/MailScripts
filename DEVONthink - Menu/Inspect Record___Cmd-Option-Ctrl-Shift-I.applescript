-- Import selected Mail messages to DEVONthink.


tell application id "DNtp"
	
	set theSelection to selection
	repeat with theRecord in theSelection
		try
			tell theRecord
				set {theId, theName, theFilename, theMetadata} Â
					to {the id, the name, the filename, the meta data}
			end tell
			display dialog "Record Data: " & (return) Â
				& "Name: " & theName & (return) Â
				& "Filename: " & theFilename & (return) Â
				& "Id: " & theId & (return) Â
				& "Metadata: " --& theMetadata
		on error error_message number error_number
			if error_number is not -128 then display alert "Devonthink" message error_message as warning
		end try
	end repeat
	
end tell
