#@osa-lang:AppleScript
property pScriptName : "Mail Rule (Business)"
property importDelay : 10
property logger : missing value

on initialize()
	if logger is missing value then
		set mailscriptsConfig to load script (POSIX path of (path to home folder) & ".mailscripts/config.scpt")
		set logger to load script ((pMailScriptsPath of mailscriptsConfig) & "/Libs/Logger.scpt")
		tell logger to initialize()
	end if
end initialize

on importMailMessages(theMessages)
	my initialize()
	tell logger to debug(pScriptName, "importMailMessages: enter")

	try
		tell application id "DNtp"
			if not (exists current database) then error "No database is in use."
		end tell


	on error error_message number error_number
		tell logger to info(pScriptName, "Error number: " & ((error_number as string) & ", Error Message: " & error_message))
	end try

	tell logger to debug(pScriptName, "importMailMessages: exit")
end importMailMessages

using terms from application "Mail"

	on perform mail action with messages theMessages for rule theRule

		my initialize()
		tell logger to debug(pScriptName, "perform mail action with messages: enter")

		tell logger to info(pScriptName, ((length of theMessages) as rich text) & " new message(s) received for import (import delayed for " & importDelay & " seconds).")
		delay importDelay

		set mailscriptsConfig to load script (POSIX path of (path to home folder) & ".mailscripts/config.scpt")
		set mailLib to load script ((pMailScriptsPath of mailscriptsConfig) & "/Libs/MailLibrary.scpt")
		set mailboxAccount to (the pMailboxAccount of mailscriptsConfig)
		set mailboxImportFolder to (the pMailboxImportFolder of mailscriptsConfig)
		set mailboxArchiveFolder to (the pMailboxArchiveFolder of mailscriptsConfig)
		set devonthinkDatabase to (the pDtImportDatabase of mailscriptsConfig)
		set devonthinkInboxFolder to (the pDtImportFolder_1 of mailscriptsConfig)
		set dtSortBySender to (the pDtSortBySender of mailscriptsConfig)

		tell mailLib to importMessages(theMessages, devonthinkDatabase, devonthinkInboxFolder, dtSortBySender, mailboxAccount, mailboxArchiveFolder, pScriptName)

		set theOldMessages to messages of mailbox mailboxImportFolder of account mailboxAccount
		if length of theOldMessages > 0 then
			tell logger to info(pScriptName, ((length of theMessages) as rich text) & " already received message(s) found for import.")
			tell mailLib to importMessages(theOldMessages, devonthinkDatabase, devonthinkInboxFolder, dtSortBySender, mailboxAccount, mailboxArchiveFolder, pScriptName)
		end if

		tell logger to debug(pScriptName, "perform mail action with messages: exit")
	end perform mail action with messages

end using terms from
