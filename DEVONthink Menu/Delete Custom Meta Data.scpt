#@osa-lang:AppleScript
on run

	tell application id "DNtp"

		set theSelection to selection
		repeat with aRecord in theSelection

			add custom meta data "" for "Date" to aRecord
			add custom meta data "" for "Sender" to aRecord

		end repeat

	end tell

end run