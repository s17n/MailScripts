#@osa-lang:AppleScript
property pScriptName : "Copy Location"

set mailscriptsConfig to load script (POSIX path of (path to home folder) & ".mailscripts/config.scpt")
set docLib to (load script (pDocLibraryPath of mailscriptsConfig))

tell application id "DNtp"
	set theDatabase to name of current database
	set theSelection to selection

	tell application id "DNtp"

		set theClipboardText to ""
		repeat with theRecord in theSelection
			set theLocation to location of theRecord
			set theName to name of theRecord
			set theLength to page count of theRecord
			set theTags to tags of theRecord
			set theClipboardText to theClipboardText & theLocation ¬
				& "|" & theName ¬
				& "|" & theTags ¬
				& "|" & (theLength as string)
			set theClipboardText to theClipboardText & linefeed
		end repeat

		-- display dialog theClipboardText
		set the clipboard to {rich text:(theClipboardText as string), Unicode text:theClipboardText}
	end tell
end tell

