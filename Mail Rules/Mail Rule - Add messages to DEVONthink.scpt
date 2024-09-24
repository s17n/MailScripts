#@osa-lang:AppleScript
property pScriptName : "Mail Rule"

using terms from application "Mail"

	on perform mail action with messages theMessages for rule theRule

		set mailscriptsConfig to load script (POSIX path of (path to home folder) & ".mailscripts/config.scpt")

		set mailLib to load script (pMailLibraryPath of mailscriptsConfig)
		set mailboxAccount to (the pMailboxAccount of mailscriptsConfig)
		set mailboxArchiveFolder to (the pMailboxArchiveFolder of mailscriptsConfig)
		set devonthinkDatabase to (the pDtImportDatabase of mailscriptsConfig)
		set devonthinkInboxFolder to (the pDtImportFolder_1 of mailscriptsConfig)
		set dtSortBySender to (the pDtSortBySender of mailscriptsConfig)

		try
			tell application id "DNtp"
				if not (exists current database) then error "No database is in use."
			end tell

			tell mailLib to addMessagesToDevonthink(theMessages, devonthinkDatabase, devonthinkInboxFolder, dtSortBySender, mailboxAccount, mailboxArchiveFolder, pScriptName)

		on error error_message number error_number
			tell mailLib to dtLog(pScriptName, ((error_number as string) & " - " & error_message))
		end try

	end perform mail action with messages

end using terms from