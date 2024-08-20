#@osa-lang:AppleScript
property pScriptName : "New Markdown Record"

set propertiesPath to POSIX path of (path to home folder) & ".applescript/properties-mailscripts.scpt"
set mailscriptProperties to (load script propertiesPath)

set mailLibraryPath to (the pMailLibraryPath of mailscriptProperties)
set mailLib to (load script file mailLibraryPath)

set markdownMetadata to ""
set markdownMetadata to markdownMetadata & "subject: " & (the pDocsSubject of mailscriptProperties) & linefeed
set markdownMetadata to markdownMetadata & "author: " & (the pDocsAuthor of mailscriptProperties) & linefeed
set inboxFolder to (the pDtImportFolder_2 of mailscriptProperties)

set dateTime to do shell script "date +\"%Y%m%d-%H%M\""

tell application id "DNtp"
	set theProject to ""
	set theSelection to the selection
	if (count of theSelection) is 1 then
		set theSelectedRecord to item 1 of selected records
		tell mailLib to set theProject to getProject(theSelectedRecord)
	end if
	set theLocation to get record at "Inbox/" & inboxFolder
	set theNewRecord to create record with {name:dateTime, type:markdown, content:markdownMetadata, tags:theProject} in theLocation
	-- set theCurrentWindow to open window for record parent 1 of theNewRecord
	-- set selection of theCurrentWindow to {theNewRecord}
end tell
