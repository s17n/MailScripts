#@osa-lang:AppleScript
property pScriptName : "Mail Rule"
property pMailPropertiesPath : POSIX path of (path to home folder) & ".applescript/properties-mailscripts.scpt"

using terms from application "Mail"

	on perform mail action with messages theMessages for rule theRule

		set scptProp to (load script pMailPropertiesPath)
		set mailLibraryPath to (the pMailLibraryPath of scptProp)
		set mailboxAccount to (the pMailboxAccount of scptProp)
		set mailboxArchiveFolder to (the pMailboxArchiveFolder of scptProp)
		set dtImportDatabase to (the pDtImportDatabase of scptProp)
		set dtImportFolder to (the pDtImportFolder_1 of scptProp)
		set dtSortBySender to (the pDtSortBySender of scptProp)

		set messageCount to count theMessages

		tell application id "DNtp"
			if not (exists current database) then error "No database is in use."
			set theGroup to incoming group of database dtImportDatabase
			log message pScriptName info "Messages to import: " & (messageCount as string)
		end tell

		set mailLib to (load script file mailLibraryPath)
		repeat with theMessage in theMessages
			try
				tell mailLib to addMessagesToDevonthink(theMessage, dtImportDatabase, dtImportFolder, dtSortBySender, mailboxAccount, mailboxArchiveFolder)
			on error error_message number error_number
				tell mailLib to dtLog(pScriptName, ((error_number as string) & " - " & error_message))
			end try
		end repeat

	end perform mail action with messages

end using terms from
