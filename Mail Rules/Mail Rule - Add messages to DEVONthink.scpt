#@osa-lang:AppleScript
property pScriptName : "Mail Rule"
property mailscriptsConfig : POSIX path of (path to home folder) & ".mailscripts/config.scpt"

using terms from application "Mail"

	on perform mail action with messages theMessages for rule theRule

		delay 5

		set scptProp to (load script mailscriptsConfig)
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
			if messageCount > 1 then
				log message pScriptName info "Messages to import (delayed 5 sec): " & (messageCount as string)
			end if
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
".mailscripts/config.scpt"