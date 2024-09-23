#@osa-lang:AppleScript
-- Launcher für MailLibrary.addMessagesToDevonthink()

property pScriptName : "Add Messages to DEVONthink"

set mailscriptsConfig to load script (POSIX path of (path to home folder) & ".mailscripts/config.scpt")

tell application "Mail"
	try
		set mailLibraryPath to (the pMailLibraryPath of mailscriptProperties)
		set dtImportDatabase to (the pDtImportDatabase of mailscriptProperties)
		set dtImportFolder to (the pDtImportFolder_1 of mailscriptProperties)
		set mailboxAccount to (the pMailboxAccount of mailscriptProperties)
		set mailboxArchiveFolder to (the pMailboxArchiveFolder of mailscriptProperties)

		tell application id "DNtp"
			if not (exists current database) then error "No database is in use."
			set theGroup to incoming group of database dtImportDatabase
		end tell
		set theSelection to the selection
		if the length of theSelection is less than 1 then error "One or more messages must be selected."

		set mailLib to (load script file mailLibraryPath)
		tell mailLib to addMessagesToDevonthink(theSelection, dtImportDatabase, dtImportFolder, true, mailboxAccount, mailboxArchiveFolder)

	on error error_message number error_number
		if error_number is not -128 then display alert "Mail" message error_message as warning
	end try
end tell
".mailscripts/config.scpt"