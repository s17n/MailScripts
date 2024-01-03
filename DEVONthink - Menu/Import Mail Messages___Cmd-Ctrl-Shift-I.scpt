#@osa-lang:AppleScript
-- Import selected Mail messages to DEVONthink.

property pScriptName : "Import Mail Messages"
property pMailPropertiesPath : POSIX path of (path to home folder) & ".applescript/properties-mailscripts.scpt"

tell application "Mail"
	try
		set scptProp to (load script pMailPropertiesPath)
		set mailLibraryPath to (the pMailLibraryPath of scptProp)
		set mailboxAccount to (the pMailboxAccount of scptProp)
		set mailboxImportFolder to (the pMailboxImportFolder of scptProp)
		set mailboxArchiveFolder to (the pMailboxArchiveFolder of scptProp)
		set dtImportDatabase to (the pDtImportDatabase of scptProp)
		set dtImportFolder to (the pDtImportFolder_1 of scptProp)

		set messageCount to count messages of mailbox mailboxImportFolder of account mailboxAccount

		tell application id "DNtp"
			if not (exists current database) then error "No database is in use."
			set theGroup to incoming group of database dtImportDatabase

			if messageCount = 0 then
				log message pScriptName info "No mail messages to import."
			else
				log message pScriptName info "Messages to import: " & (messageCount as string)
			end if
		end tell

		set mailLib to (load script file mailLibraryPath)
		repeat with i from 1 to messageCount by 1
			set theMessage to message 1 of mailbox "Zu archivieren" of account mailboxAccount
			tell mailLib to addMessagesToDevonthink(theMessage, dtImportDatabase, dtImportFolder, false, mailboxAccount, mailboxArchiveFolder)
		end repeat

	on error error_message number error_number
		if error_number is not -128 then display alert "Mail" message error_message as warning
	end try
end tell
