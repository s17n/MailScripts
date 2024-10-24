#@osa-lang:AppleScript
property pScriptName : "Import Mail Messages"

set mailscriptsConfig to load script (POSIX path of (path to home folder) & ".mailscripts/config.scpt")

tell application "Mail"

	set mailLibraryPath to (the pMailLibraryPath of mailscriptsConfig)
	set mailboxAccount to (the pMailboxAccount of mailscriptsConfig)
	set mailboxImportFolder to (the pMailboxImportFolder of mailscriptsConfig)
	set mailboxArchiveFolder to (the pMailboxArchiveFolder of mailscriptsConfig)
	set devonthinkDatabase to (the pDtImportDatabase of mailscriptsConfig)
	set devonthinkInboxFolder to (the pDtImportFolder_1 of mailscriptsConfig)
	set dtSortBySender to (the pDtSortBySender of mailscriptsConfig)
	set mailLib to (load script mailLibraryPath)

	--try
	tell application id "DNtp"
		if not (exists current database) then error "No database is in use."
	end tell

	set theMessages to messages of mailbox mailboxImportFolder of account mailboxAccount

	tell mailLib to addMessagesToDevonthink(theMessages, devonthinkDatabase, devonthinkInboxFolder, dtSortBySender, mailboxAccount, mailboxArchiveFolder, pScriptName)

	--on error error_message number error_number
	-- if error_number is not -128 then display alert "Mail" message error_message as warning
	---tell mailLib to dtLog(pScriptName, ((error_number as string) & " - " & error_message))
	--end try

end tell
