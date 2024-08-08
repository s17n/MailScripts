#@osa-lang:AppleScript
property pScriptName : "Create Markdown Record"

set propertiesPath to POSIX path of (path to home folder) & ".applescript/properties-mailscripts.scpt"
set mailscriptProperties to (load script propertiesPath)

set mailLibraryPath to (the pMailLibraryPath of mailscriptProperties)
set mailLib to (load script file mailLibraryPath)

set dateTime to do shell script "date +\"%Y%m%d-%H%M\""
set defaultMetadata to "subject: [subject]
author: [author]"

tell application id "DNtp"
	set theRecords to selection
	repeat with theRecord in theRecords
		tell mailLib to set theProject to getProject(theRecord)
	end repeat
	set theLocation to get record at "Inbox/fstar"
	set theRecord to create record with {name:dateTime, type:markdown, content:defaultMetadata, tags:theProject} in theLocation
end tell
