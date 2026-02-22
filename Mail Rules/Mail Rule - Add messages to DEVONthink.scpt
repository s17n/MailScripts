#@osa-lang:AppleScript
property pScriptName : "Mail Rule"

using terms from application "Mail"

	on perform mail action with messages theMessages for rule theRule

		set config to load script (POSIX path of (path to home folder) & ".mailscripts/config.scpt")
		set docLib to load script pDocLibraryPath of config

		set theEmailDatabase to pPrimaryEmailDatabase of config
		tell docLib to importMailMessages(theEmailDatabase)

	end perform mail action with messages

end using terms from
