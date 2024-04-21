#@osa-lang:AppleScript
on hazelProcessFile(theFile, inputAttributes)

	set thePath to theFile as text

	set TID to text item delimiters
	set text item delimiters to {":"}
	set theFilename to last text item of thePath
	set text item delimiters to TID

	tell application id "DNtp"
		--	set theRecord to import theFile to preferred import destination
		--	perform smart rule trigger import event record theRecord
		log message theFilename info thePath
	end tell
	return true
end hazelProcessFile