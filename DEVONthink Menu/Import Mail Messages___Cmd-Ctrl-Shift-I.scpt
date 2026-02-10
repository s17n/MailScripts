#@osa-lang:AppleScript
property pScriptName : "Import Mail Messages"

property logger : missing value
property mailLib : missing value

on initialize(loggingContext, enforceInitialize)

	if enforceInitialize or logger is missing value then
		set config to load script (POSIX path of (path to home folder) & ".mailscripts/config.scpt")
		set docLib to load script pDocLibraryPath of config
		set mailLib to load script pMailLibraryPath of config
		set logger to load script pLogger of config
		tell logger to initialize()

	end if
	return pScriptName & " > " & loggingContext

end initialize

on importMailMessages()
	set logCtx to my initialize("importMailMessages", false)
	tell logger to debug(logCtx, "enter")


	set config to load script (POSIX path of (path to home folder) & ".mailscripts/config.scpt")
	set mailLib to load script pMailLibraryPath of config

	tell mailLib
		set theMessages to getMessagesFromInbox()
		importMessages(theMessages)
	end tell

	tell logger to debug(logCtx, "exit")
end importMailMessages

on run {}
	set logCtx to my initialize("run", true)
	tell logger to debug(logCtx, "enter")

	my importMailMessages()

	tell logger to debug(logCtx, "exit")
end run