#@osa-lang:AppleScript
property pScriptName : "DocLibrary"
property pLogLevel : 2

property pDays : {}
property pMonths : {}
property pYears : {}
property pSenders : {}
property pSubjects : {}
property pContexts : {}
property pSentTag : "Postausgang"
property pCcTag : "In-Kopie"
property pNoSenderTag : "kein-Absender"

property pMonthsList : {"Januar", "Februar", "März", "April", "Mai", "Juni", "Juli", ¬
	"August", "September", "Oktober", "November", "Dezember"}

property pScoreThreshold : 0.05

property DEBUG : 1
property INFO : 2
property WARN : 3

on verifyTags(checkDate, checkSender, theScriptName)
	tell application id "DNtp"
		my initializeTagLists(get current database)
		set theRecords to contents of current database whose location begins with "/"
		my dtLog(INFO, theScriptName, "Verify records started - records: " & (length of theRecords as string))
		set issueRecords to 0
		set {issueRecords, issues} to {0, 0}
		repeat with aRecord in theRecords
			set {theYear, theMonth, theDay, theSender, theSubject, issueCount} to {null, null, null, null, null, 0}
			set theTags to tags of aRecord
			repeat with aTag in theTags
				if checkDate is true then
					if pDays contains aTag then
						if theDay is not null then
							my dtLogRecord(INFO, pScriptName, "Another 'day' tag found.", aRecord)
							set issueCount to issueCount + 1
						end if
						set theDay to aTag
					end if
					if pMonths contains aTag then
						if theMonth is not null then
							my dtLogRecord(INFO, pScriptName, "Another 'month' tag found.", aRecord)
							set issueCount to issueCount + 1
						end if
						set theMonth to aTag
					end if
					if pYears contains aTag then
						if theYear is not null then
							my dtLogRecord(INFO, pScriptName, "Another 'year' tag found.", aRecord)
							set issueCount to issueCount + 1
						end if
						set theYear to aTag
					end if
				end if
				if checkSender is true then
					if pSenders contains aTag then
						if theSender is not null then
							my dtLogRecord(INFO, pScriptName, "Another 'sender' tag found.", aRecord)
							set issueCount to issueCount + 1
						end if
						set theSender to aTag
					end if
				end if
			end repeat
			if checkDate is true then
				if theDay is null then
					my dtLogRecord(INFO, theScriptName, "Tag 'days' missing.", aRecord)
					set issueCount to issueCount + 1
				end if
				if theMonth is null then
					my dtLogRecord(INFO, theScriptName, "Tag 'month' missing.", aRecord)
					set issueCount to issueCount + 1
				end if
				if theYear is null then
					my dtLogRecord(INFO, theScriptName, "Tag 'year' missing.", aRecord)
					set issueCount to issueCount + 1
				end if
			end if
			if checkSender is true then
				if theSender is null then
					my dtLogRecord(INFO, theScriptName, "Tag 'sender' missing.", aRecord)
					set issueCount to issueCount + 1
				end if
			end if
			if issueCount > 0 then
				set issueRecords to issueRecords + 1
				set issues to issues + issueCount
			end if
		end repeat
		my dtLog(INFO, theScriptName, "Verify records finished - Issues: " & (issues as string) & ", Records: " & (issueRecords as string))
	end tell
end verifyTags

on importDocuments(theRecords)
	tell application id "DNtp"
		repeat with theRecord in theRecords
			set theDatabaseName to name of location group of theRecord
			set theDatabase to database theDatabaseName
			my initializeTagLists(theDatabase)
			my setDateTagsFromRecordName(theRecord)
			my setNonDateTagsFromCompareRecord(theRecord, theDatabase)
			set theRecordName to my renameAndUpdateCustomMetadata(theRecord)
			move record theRecord to incoming group of database theDatabaseName
			my dtLog(INFO, pScriptName & " - importDocuments", "Document imported - Record name: " & theRecordName)
		end repeat
	end tell
end importDocuments

on setCustomMetaData(theRecord, theYear, theMonth_MM, theDay, theSender, theSubject, theSentFlag, theCCFlag)
	my dtLog(INFO, pScriptName, theMonth_MM)
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
		my dtLog(DEBUG, pScriptName & " - setCustomMetaData", "cmdDate: " & cmdDate & ", cmdSender: " & cmdSender & ", cmdSubject: " & cmdSubject)
	end tell
end setCustomMetaData

-- Rename the given record based on it's tags and upate corresponding custom meta data.
-- Each tag added to the file name is prefixed with an underscore "_" except of the date tags.
-- Name format is: yyyy-MM-dd_[SENTFLAG|CCFLAG]_SENDER_[CONTEXT]_[SUBJECT].pdf
-- Mandatory tags: Year, Month, Day, Sender
-- Optional tags: Subject, Context, SentFlag
on renameAndUpdateCustomMetadata(theRecord)
	tell application id "DNtp"
		set {theYear, theMonth, theDay, theSender, theSubject, theContext, theSentFlag, theCCFlag} ¬
			to {null, null, null, null, null, null, false, false}
		set theTags to tags of theRecord
		repeat with aTag in theTags
			if pDays contains aTag then set theDay to aTag
			if pMonths contains aTag then
				set theMonth_MM to aTag
				set theMonth to my getMonthAsInteger(aTag as string)
			end if
			if pYears contains aTag then set theYear to aTag
			if pSenders contains aTag then set theSender to aTag
			if pSubjects contains aTag then set theSubject to aTag
			if pContexts contains aTag then set theContext to aTag
			if (aTag as string) is equal to pSentTag then set theSentFlag to true
			if (aTag as string) is equal to pCcTag then set theCCFlag to true
		end repeat
		if theYear is null or theMonth is null or theDay is null or theSender is null then
			my dtLogRecord(INFO, pScriptName & " - renameAndUpdateCustomMetadata", "Record can't renamed - missing tags.", theRecord)
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
			my dtLogRecord(INFO, pScriptName & " - renameAndUpdateCustomMetadata", "Record successfully renamed - old name was:  " & theOldRecordName, theRecord)
			return theRecordName
		end if
	end tell
end renameAndUpdateCustomMetadata

on tokenForFilename(theTagValue)
	return ("_" & theTagValue as string)
end tokenForFilename

on setDateTagsFromRecordName(theRecord)
	tell application id "DNtp"
		set theName to name of theRecord
		set theYear to (characters 1 thru 4 of theName) as string
		set theMonthAsString to (characters 6 thru 7 of theName) as string
		set theMonth to get item theMonthAsString of pMonthsList
		set theDay to (characters 9 thru 10 of theName) as string
		set tags of theRecord to tags of theRecord & {theYear, theMonth, theDay}
		my dtLog(DEBUG, pScriptName & " - setDateTagsFromRecordName", "Day: " & theDay & ", Month: " & theMonth & ", Year: " & theYear)
	end tell
end setDateTagsFromRecordName

on setNonDateTagsFromCompareRecord(theRecord, theDatabase)
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
					my dtLogRecord(INFO, "", "No tags copied - score of best compare record below threshold - score: " & (theScore as string), theRecord)
				end if
				exit repeat -- only first record needed
			end if
		end repeat
	end tell
end setNonDateTagsFromCompareRecord

on initializeTagLists(theDatabase)
	tell application id "DNtp"
		--my dtLog(DEBUG, "xxx", name of current database as string)
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
		my dtLog(DEBUG, pScriptName & " - initialize", "Database: " & name of theDatabase & ", Days: " & length of pDays & ", Months: " & length of pMonths & ", Years: " & length of pYears & ", Senders: " & length of pSenders & ", Subjects: " & length of pSubjects & ", Contexts: " & length of pContexts)
	end tell
end initializeTagLists

on createTagList(theTags, resultList)
	tell application id "DNtp"
		repeat with tagListItem in theTags
			set tagTypeOfTagListItem to tag type of tagListItem as string
			--display dialog name of tagListItem & ": " & tagTypeOfTagListItem
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

on getMonthAsInteger(pMonthAsString)
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
end getMonthAsInteger

on dtLog(theLogLevel, theScriptName, theInfo)
	tell application id "DNtp"
		if theLogLevel ≥ pLogLevel then log message theScriptName info theInfo --record null
	end tell
end dtLog

on dtLogRecord(theLogLevel, theScriptName, theInfo, theRecord)
	tell application id "DNtp"
		if theLogLevel ≥ pLogLevel then log message theScriptName info theInfo record theRecord
	end tell
end dtLogRecord

