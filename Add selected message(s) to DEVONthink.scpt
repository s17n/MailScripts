#@osa-lang:AppleScript
-- Import selected Mail messages to DEVONthink.

set propertiesPath to POSIX path of (path to home folder)
set propertiesPath to propertiesPath & ".applescript/properties-mailscripts.scpt"
set mailscriptProperties to (load script propertiesPath)

tell application "Mail"
	try
		set mailLibraryPath to (the pMailLibraryPath of mailscriptProperties)
		set dtImportDatabase to (the pDtImportDatabase of mailscriptProperties)
		set dtImportFolder to (the pDtImportFolder_1 of mailscriptProperties)
		set mailboxAccount to (the pMailboxAccount of mailscriptProperties)
		set mailboxArchiveFolder to (the pMailboxArchiveFolder of mailscriptProperties)

		--display dialog "MailLibraryPath: " & mailLibraryPath & (return) & ¬
		--	"dtImportDatabase: " & dtImportDatabase & (return) & ¬
		--	"dtImportFolder: " & dtImportFolder & (return) & ¬
		--	"mailboxAccount: " & mailboxAccount & (return) & ¬
		-- 	"mailboxArchiveFolder: " & mailboxArchiveFolder

		tell application id "DNtp"
			if not (exists current database) then error "No database is in use."
			set theGroup to incoming group of database dtImportDatabase
		end tell
		set theSelection to the selection
		if the length of theSelection is less than 1 then error "One or more messages must be selected."

		set mailLib to (load script file mailLibraryPath)
		tell mailLib to addMessagesToDevonthink(theSelection, dtImportDatabase, dtImportFolder, mailboxAccount, mailboxArchiveFolder)

	on error error_message number error_number
		if error_number is not -128 then display alert "Mail" message error_message as warning
	end try
end tell
