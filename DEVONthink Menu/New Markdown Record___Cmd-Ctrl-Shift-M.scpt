#@osa-lang:AppleScript
property pScriptName : "New Markdown Record"

set mailscriptsConfig to load script (POSIX path of (path to home folder) & ".mailscripts/config.scpt")

set mailLibraryPath to (the pMailLibraryPath of mailscriptsConfig)
set mailLib to (load script mailLibraryPath)

set markdownMetadata to ""
set markdownMetadata to markdownMetadata & "subject: " & (the pDocsSubject of mailscriptsConfig) & linefeed
set markdownMetadata to markdownMetadata & "author: " & (the pDocsAuthor of mailscriptsConfig) & linefeed
--set inboxFolder to (the pDtImportFolder_2 of mailscriptsConfig)

set dateTime to do shell script "date +\"%Y%m%d-%H%M\""

tell application id "DNtp"
	set theProject to ""
	set theSelection to the selection

	set theLocation to get record at "Inbox"
	if (count of theSelection) is 1 then
		set theSelectedRecord to item 1 of selected records

		set theLocationAsString to location of theSelectedRecord
		set theLocation to get record at theLocationAsString

		--tell mailLib to set theProject to getProject(theSelectedRecord)
	end if

	--set theNewRecord to create record with {name:dateTime, type:markdown, content:markdownMetadata, tags:theProject} in theLocation
	set theNewRecord to create record with {name:dateTime, type:markdown, content:markdownMetadata} in theLocation
end tell
