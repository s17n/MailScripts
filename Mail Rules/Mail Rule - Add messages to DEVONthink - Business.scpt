#@osa-lang:AppleScript
property pScriptName : "Mail Rule (Business)"

using terms from application "Mail"

	on perform mail action with messages theMessages for rule theRule

		set propertiesPath to POSIX path of (path to home folder) & ".applescript/properties-mailscripts.scpt"
		set mailscriptProperties to (load script propertiesPath)

		set mailLibraryPath to (the pMailLibraryPath of mailscriptProperties)
		set mailboxAccount to (the pMailboxAccount of mailscriptProperties)
		set mailboxArchiveFolder to (the pMailboxArchiveFolder of mailscriptProperties)
		set devonthinkDatabase to (the pDtImportDatabase of mailscriptProperties)
		set devonthinkInboxFolder to (the pDtImportFolder_1 of mailscriptProperties)
		set dtSortBySender to (the pDtSortBySender of mailscriptProperties)
		set mailLib to (load script mailLibraryPath)

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
