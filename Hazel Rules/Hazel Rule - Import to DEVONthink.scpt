#@osa-lang:AppleScript

on hazelProcessFile(theFile, inputAttributes)
	set thePath to theFile as text
	tell application id "DNtp"
		set theRecord to import path theFile to preferred import destination
		perform smart rule trigger import event record theRecord
	end tell
	return true
end hazelProcessFile