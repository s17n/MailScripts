#@osa-lang:AppleScript
property pScriptName : "DocLibrary"

property baseLib : missing value

property pDays : {}
property pMonths : {}
property pYears : {}
property pSenders : {}
property pSubjects : {}
property pContexts : {}
property pSentTag : "Postausgang"
property pCcTag : "In-Kopie"
property pNoSenderTag : "kein-Absender"

property pMonthsList : {"Januar", "Februar", "März", "April", "Mai", "Juni", "Juli", "August", "September", "Oktober", "November", "Dezember"}

property pScoreThreshold : 0.05

on initialize()
	set log_ctx to pScriptName & "." & "initialize"
	if baseLib is missing value then
		set mailScriptsProperties to load script (POSIX path of (path to home folder) & ".applescript/properties-mailscripts.scpt")
		set baseLib to load script ((pMailScriptsPath of mailScriptsProperties) & "/BaseLibrary.scpt")
		tell baseLib to initialize()
		tell baseLib to debug(log_ctx, "baseLib initialized")
	else
		tell baseLib to debug(log_ctx, "baseLib already initialized")
	end if
end initialize

on showLogLevel()
	tell baseLib to showLogLevel()
end showLogLevel

on setBetrag(theRecords)
	my initialize()
	set log_ctx to pScriptName & "." & "setBetrag"
	tell baseLib to debug(log_ctx, "enter")
	repeat with theRecord in theRecords
		my setBetragForRecord(theRecord)
	end repeat
	tell baseLib to debug(log_ctx, "exit")
end setBetrag

on setBetragForRecord(theRecord)
	set log_ctx to pScriptName & "." & "setBetragForRecord"
	tell baseLib to debug(log_ctx, "enter")
	tell application id "DNtp"
		try
			set theDocumentAmount to document amount of theRecord
			add custom meta data theDocumentAmount for "Betrag" to theRecord
			tell baseLib to debug_r(theRecord, "Document amount: " & theDocumentAmount)
		on error number -2753
			tell baseLib to info_r(theRecord, "No 'document amount' found.")
		end try
	end tell
	tell baseLib to debug(log_ctx, "exit")
end setBetragForRecord

on classifyDocuments(theRecords)
	my initialize()
	set log_ctx to pScriptName & "." & "classifyDocuments"
	tell baseLib to debug(log_ctx, "enter")
	tell application id "DNtp"
		repeat with theRecord in theRecords
			set theDatabase to database of theRecord
			my initializeTagLists(theDatabase)
			my setDateTagsFromRecord(theRecord)
			my setNonDateTagsFromCompareRecord(theRecord, theDatabase)
			my setNameAndCustomMetadata(theRecord)
			if name of theDatabase contains "Belege" then
				my setBetragForRecord(theRecord)
			end if
			tell baseLib to info_r(theRecord, "Document classification finished.")
		end repeat
	end tell
	tell baseLib to debug(log_ctx, "exit")
end classifyDocuments

-- Renames the record based on it's tags and updates the custom meta data.
-- Name format is: yyyy-MM-dd_[SENTFLAG|CCFLAG]_SENDER_[CONTEXT]_[SUBJECT].pdf
-- Mandatory tags: Year, Month, Day, Sender
-- Optional tags: Subject, Context, SentFlag
on setNameAndCustomMetadata(theRecord)
	my initialize()
	set log_ctx to pScriptName & "." & "setNameAndCustomMetadata"
	tell baseLib to debug(log_ctx, "enter")
	tell application id "DNtp"
		set {theYear, theMonth, theDay, theSender, theSubject, theContext, theSentFlag, theCCFlag} ¬
			to {null, null, null, null, null, null, false, false}
		set theTags to tags of theRecord
		repeat with aTag in theTags
			if pDays contains aTag then set theDay to aTag
			if pMonths contains aTag then
				set theMonth to my getMonthAsPaddedNumber(aTag as string)
			end if
			if pYears contains aTag then set theYear to aTag
			if pSenders contains aTag then set theSender to aTag
			if pSubjects contains aTag then set theSubject to aTag
			if pContexts contains aTag then set theContext to aTag
			if (aTag as string) is equal to pSentTag then set theSentFlag to true
			if (aTag as string) is equal to pCcTag then set theCCFlag to true
		end repeat
		if theYear is null or theMonth is null or theDay is null or theSender is null then
			tell baseLib to info_r(theRecord, "Can't rename record - missing tags.")
		else
			set theOldRecordName to name of theRecord
			set theRecordName to theYear & "-" & theMonth & "-" & theDay
			if theSentFlag is true then set theRecordName to theRecordName & my tokenForFilename("AN")
			if theCCFlag is true then set theRecordName to theRecordName & my tokenForFilename("CC")
			if (theSender as string) is not equal to pNoSenderTag then set theRecordName to theRecordName & my tokenForFilename(theSender)
			if theContext is not null then set theRecordName to theRecordName & my tokenForFilename(theContext)
			if theSubject is not null then set theRecordName to theRecordName & my tokenForFilename(theSubject)
			set name of theRecord to theRecordName
			my setCustomMetaData(theRecord, theYear, theMonth, theDay, theSender, theSubject, theSentFlag, theCCFlag)
			tell baseLib to debug_r(theRecord, "Record renamed - old name was: " & theOldRecordName)
			return theRecordName
		end if
	end tell
	tell baseLib to debug(log_ctx, "exit")
end setNameAndCustomMetadata

on setCustomMetaData(theRecord, theYear, theMonth_MM, theDay, theSender, theSubject, theSentFlag, theCCFlag)
	set log_ctx to pScriptName & "." & "setCustomMetaData"
	tell baseLib to debug(log_ctx, "enter")
	tell application id "DNtp"
		set {cmdDate, cmdSender, cmdSubject} to {null, null, null}
		-- Date
		if theYear is not null and theMonth_MM is not null and theDay is not null then
			set cmdDate to theYear & "-" & theMonth_MM & "-" & theDay
			add custom meta data cmdDate for "Date" to theRecord
		end if
		-- Sender
		if theSender is not null then
			set cmdSender to ""
			if (theSender as string) is equal to pNoSenderTag then
				set cmdSender to "k.A."
			else
				if theSentFlag is true then set cmdSender to "An: "
				set cmdSender to cmdSender & theSender
				if theCCFlag is true then set cmdSender to cmdSender & " (in CC)"
			end if
			add custom meta data cmdSender for "Sender" to theRecord
		end if
		-- Subject
		if theSubject is not null then
			add custom meta data theSubject for "Subject" to theRecord
		end if
		tell baseLib to debug(log_ctx, "cmdDate: " & cmdDate & ", cmdSender: " & cmdSender & ", cmdSubject: " & cmdSubject)
	end tell
	tell baseLib to debug(log_ctx, "exit")
end setCustomMetaData

on archiveRecords(theRecords, theCallerScript)
	my initialize()
	tell application id "DNtp"
		try
			repeat with theRecord in theRecords

				set creationDate to get custom meta data for "Date" from theRecord
				if creationDate is missing value then
					display dialog "Can't archive record - custom meta data 'Date' not set"
				else

					tell baseLib to set creationDateAsString to format(creationDate)
					set theYear to texts 1 thru 4 of creationDateAsString
					set theMonth to texts 5 thru 6 of creationDateAsString

					set archiveFolder to "/05 Assets"
					set theYearAsInteger to theYear as integer
					if theYearAsInteger ≥ 2000 and theYearAsInteger ≤ 2009 then
						set archiveFolder to archiveFolder & "/2000-2009"
					else if theYearAsInteger ≥ 2010 and theYearAsInteger ≤ 2019 then
						set archiveFolder to archiveFolder & "/2010-2019"
					end if
					set archiveFolder to archiveFolder & "/" & theYear & "/" & theMonth
					set theGroup to create location archiveFolder
					move record theRecord to theGroup
					log message info "Record archived to: " & archiveFolder record theRecord
				end if
			end repeat
		on error error_message number error_number
			if error_number is not -128 then display alert "Devonthink" message error_message as warning
		end try

	end tell
end archiveRecords

on tokenForFilename(theTagValue)
	return ("_" & theTagValue as string)
end tokenForFilename

on setDateTagsFromRecord(theRecord)
	set log_ctx to pScriptName & "." & "setDateTagsFromRecord"
	tell baseLib to debug(log_ctx, "enter")
	tell application id "DNtp"
		try
			set theDocumentDate to newest document date of theRecord
			theDocumentDate
		on error number -2753
			tell baseLib to debug(log_ctx, "No 'newest document date' found, 'creation date' will be used instead.")
			set theDocumentDate to creation date of theRecord
		end try
		tell baseLib to set theDocumentDateAsString to date_to_iso(theDocumentDate)
		set theYear to (characters 1 thru 4 of theDocumentDateAsString) as string
		set theMonthAsString to (characters 6 thru 7 of theDocumentDateAsString) as string
		set theMonth to get item theMonthAsString of pMonthsList
		set theDay to (characters 9 thru 10 of theDocumentDateAsString) as string
		set tags of theRecord to tags of theRecord & {theYear, theMonth, theDay}
		tell baseLib to debug_r(theRecord, "Day: " & theDay & ", Month: " & theMonth & ", Year: " & theYear)
	end tell
	tell baseLib to debug(log_ctx, "exit")
end setDateTagsFromRecord

on setNonDateTagsFromCompareRecord(theRecord, theDatabase)
	set log_ctx to pScriptName & "." & "setNonDateTagsFromCompareRecord"
	tell baseLib to debug(log_ctx, "enter")
	tell application id "DNtp"
		set theTags to tags of theRecord
		set theComparedRecords to compare record theRecord to theDatabase
		repeat with aCompareRecord in theComparedRecords
			if location of aCompareRecord does not contain "Inbox" then
				set theScore to score of aCompareRecord
				if theScore ≥ pScoreThreshold then
					set theTags to tags of aCompareRecord
					set {nonDateTags, theSender, theSubject, theContext} to {{}, null, null, null}
					repeat with aTag in theTags
						if pSenders contains aTag then set theSender to aTag
						if pSubjects contains aTag then set theSubject to aTag
						if pContexts contains aTag then set theContext to aTag
					end repeat
					if theSender is not null then set end of nonDateTags to theSender
					if theSubject is not null then set end of nonDateTags to theSubject
					if theContext is not null then set end of nonDateTags to theContext
					set tags of theRecord to tags of theRecord & nonDateTags
				else
					tell baseLib to debug_r(theRecord, "No tags copied - score of best compare record below threshold - score: " & (theScore as string))
				end if
				exit repeat -- only first record needed
			end if
		end repeat
	end tell
	tell baseLib to debug(log_ctx, "exit")
end setNonDateTagsFromCompareRecord

on verifyTags(checkDate, checkSender)
	set log_ctx to pScriptName & "." & "verifyTags"
	tell baseLib to debug(log_ctx, "enter")
	tell application id "DNtp"
		set currentDatabase to current database
		my initializeTagLists(currentDatabase)
		set theRecords to contents of currentDatabase whose location begins with "/"
		tell baseLib to info(log_ctx, "Verify tags started for database: " & (name of currentDatabase as string) & ", number of records: " & (length of theRecords as string))
		set issueRecords to 0
		set {issueRecords, issues} to {0, 0}
		repeat with theRecord in theRecords
			set {theYear, theMonth, theDay, theSender, theSubject, issueCount} to {null, null, null, null, null, 0}
			set theTags to tags of theRecord
			repeat with aTag in theTags
				if checkDate is true then
					if pDays contains aTag then
						if theDay is not null then
							tell baseLib to info_r(theRecord, "Another tag of same type found for type: day")
							set issueCount to issueCount + 1
						end if
						set theDay to aTag
					end if
					if pMonths contains aTag then
						if theMonth is not null then
							tell baseLib to info_r(theRecord, "Another tag of same type found for type: month")
							set issueCount to issueCount + 1
						end if
						set theMonth to aTag
					end if
					if pYears contains aTag then
						if theYear is not null then
							tell baseLib to info_r(theRecord, "Another tag of same type found for type: year")
							set issueCount to issueCount + 1
						end if
						set theYear to aTag
					end if
				end if
				if checkSender is true then
					if pSenders contains aTag then
						if theSender is not null then
							tell baseLib to info_r(theRecord, "Another tag of same type found for type: sender")
							set issueCount to issueCount + 1
						end if
						set theSender to aTag
					end if
				end if
			end repeat
			if checkDate is true then
				if theDay is null then
					tell baseLib to info_r(theRecord, "Tag missing: day")
					set issueCount to issueCount + 1
				end if
				if theMonth is null then
					tell baseLib to info_r(theRecord, "Tag missing: month")
					set issueCount to issueCount + 1
				end if
				if theYear is null then
					tell baseLib to info_r(theRecord, "Tag missing: year")
					set issueCount to issueCount + 1
				end if
			end if
			if checkSender is true then
				if theSender is null then
					tell baseLib to info_r(theRecord, "Tag missing: sender")
					set issueCount to issueCount + 1
				end if
			end if
			if issueCount > 0 then
				set issueRecords to issueRecords + 1
				set issues to issues + issueCount
			end if
		end repeat
		tell baseLib to info(log_ctx, "Verify tags finished - Issues: " & (issues as string) & ", Records with issues: " & (issueRecords as string))
	end tell
	tell baseLib to debug(log_ctx, "exit")
end verifyTags

on initializeTagLists(theDatabase)
	my initialize()
	set log_ctx to pScriptName & "." & "initializeTagLists"
	tell application id "DNtp"
		tell baseLib to debug(log_ctx, "Initialize tag lists for database: " & name of theDatabase)
		set theTopLevelTagGroups to children of tags group of theDatabase --current database
		repeat with theTopLevelTagGroup in theTopLevelTagGroups
			set theChildren to get children of theTopLevelTagGroup
			if name of theTopLevelTagGroup starts with "01" then
				set pDays to my createTagList(theChildren, {})
			else if name of theTopLevelTagGroup starts with "02" then
				set pMonths to my createTagList(theChildren, {})
			else if name of theTopLevelTagGroup starts with "03" then
				set pYears to my createTagList(theChildren, {})
			else if name of theTopLevelTagGroup starts with "04" then
				set pSenders to my createTagList(theChildren, {})
			else if name of theTopLevelTagGroup starts with "05" then
				set pSubjects to my createTagList(theChildren, {})
			else if name of theTopLevelTagGroup starts with "06" then
				set pContexts to my createTagList(theChildren, {})
			end if
		end repeat
		tell baseLib to debug(log_ctx, "Initialize tag lists finished for database: " & name of theDatabase & ", Days: " & length of pDays & ", Months: " & length of pMonths & ", Years: " & length of pYears & ", Senders: " & length of pSenders & ", Subjects: " & length of pSubjects & ", Contexts: " & length of pContexts)
	end tell
end initializeTagLists

on createTagList(theTags, resultList)
	tell application id "DNtp"
		repeat with tagListItem in theTags
			set tagTypeOfTagListItem to tag type of tagListItem as string
			if tagTypeOfTagListItem is "ordinary tag" or tagTypeOfTagListItem is "«constant ****otag»" then
				set end of resultList to name of tagListItem as string
			else
				set resultList to my createTagList(children of tagListItem, resultList)
			end if
		end repeat
		return resultList
	end tell
	return resultList
end createTagList

on getMonthAsPaddedNumber(pMonthAsString)
	if pMonthAsString = "Januar" then
		return "01"
	else if pMonthAsString = "Februar" then
		return "02"
	else if pMonthAsString = "März" then
		return "03"
	else if pMonthAsString = "April" then
		return "04"
	else if pMonthAsString = "Mai" then
		return "05"
	else if pMonthAsString = "Juni" then
		return "06"
	else if pMonthAsString = "Juli" then
		return "07"
	else if pMonthAsString = "August" then
		return "08"
	else if pMonthAsString = "September" then
		return "09"
	else if pMonthAsString = "Oktober" then
		return "10"
	else if pMonthAsString = "November" then
		return "11"
	else if pMonthAsString = "Dezember" then
		return "12"
	end if
end getMonthAsPaddedNumber


