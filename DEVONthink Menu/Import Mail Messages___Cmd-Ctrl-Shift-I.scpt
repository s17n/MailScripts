#@osa-lang:AppleScript
property pScriptName : "Import Mail Messages"

property logger : missing value

on initialize()
	if logger is missing value then
		set mailscriptsConfig to load script (POSIX path of (path to home folder) & ".mailscripts/config.scpt")
		set logger to load script ((pMailScriptsPath of mailscriptsConfig) & "/Libs/Logger.scpt")
		tell logger to initialize()
	end if
end initialize

on importMailMessages()
	my initialize()
	tell logger to debug(pScriptName, "importMailMessages: enter")

	set mailscriptsConfig to load script (POSIX path of (path to home folder) & ".mailscripts/config.scpt")
	set mailLib to load script ((pMailScriptsPath of mailscriptsConfig) & "/Libs/MailLibrary.scpt")
	set mailboxAccount to (the pMailboxAccount of mailscriptsConfig)
	set mailboxImportFolder to (the pMailboxImportFolder of mailscriptsConfig)
	set mailboxArchiveFolder to (the pMailboxArchiveFolder of mailscriptsConfig)
	set devonthinkDatabase to (the pDtImportDatabase of mailscriptsConfig)
	set devonthinkInboxFolder to (the pDtImportFolder_1 of mailscriptsConfig)
	set dtSortBySender to (the pDtSortBySender of mailscriptsConfig)

	tell application id "DNtp"
		if not (exists current database) then error "No database is in use."
	end tell

	tell application "Mail" to set theMessages to messages of mailbox mailboxImportFolder of account mailboxAccount

	tell mailLib to importMessages(theMessages, devonthinkDatabase, devonthinkInboxFolder, dtSortBySender, mailboxAccount, mailboxArchiveFolder, pScriptName)

	tell logger to debug(pScriptName, "importMailMessages: exit")
end importMailMessages

on run {}

	my initialize()
	my importMailMessages()

end run