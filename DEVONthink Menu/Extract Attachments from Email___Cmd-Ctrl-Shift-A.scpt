#@osa-lang:AppleScript
property pScriptName : "Extract Attachments from Email"

set mailscriptsConfig to load script (POSIX path of (path to home folder) & ".mailscripts/config.scpt")

tell application "Mail"
	try
		set mailLibraryPath to (the pMailLibraryPath of mailscriptsConfig)

		set mailLib to (load script file mailLibraryPath)
		tell mailLib to extractAttachmentsFromEmail()

	on error error_message number error_number
		if error_number is not -128 then display alert "Mail" message error_message as warning
	end try
end tell

(*
tell application id "DNtp"
	set theSelection to the selection
	set tmpFolder to path to temporary items
	set tmpPath to POSIX path of tmpFolder

	repeat with theRecord in theSelection
		if (type of theRecord is unknown and path of theRecord ends with ".eml") or (type of the record is formatted note) then
			set theRTF to convert record theRecord to rich

			try
				if type of theRTF is rtfd then
					set thePath to path of theRTF
					set theGroup to parent 1 of theRecord

					tell application "Finder"
						set filelist to every file in ((POSIX file thePath) as alias)
						repeat with theFile in filelist
							set theAttachment to POSIX path of (theFile as string)

							if theAttachment ends with ".pdf" then
								-- Importing skips files inside the database package,
								-- therefore let's move them to a temporary folder first
								set theAttachment to move ((POSIX file theAttachment) as alias) to tmpFolder with replacing
								set theAttachment to POSIX path of (theAttachment as string)
								-- tell application id "DNtp" to import theAttachment to theGroup
								tell application id "DNtp"
									set theImportedRecord to import theAttachment to theGroup
									set creation date of theImportedRecord to get creation date of theRecord
									add custom meta data (get creation date of theRecord as string) for "Date" to theImportedRecord
								end tell
							end if
						end repeat
					end tell
				end if
			end try

			delete record theRTF
		end if
	end repeat
end tell

*)