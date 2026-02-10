#@osa-lang:AppleScript
property pScriptName : "Mail Rule (Business)"

using terms from application "Mail"

	on perform mail action with messages theMessages for rule theRule

		set config to load script (POSIX path of (path to home folder) & ".mailscripts/config.scpt")
		set mailLib to load script pMailLibraryPath of config
		tell mailLib to importMessages(theMessages)

	end perform mail action with messages

end using terms from
