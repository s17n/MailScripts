#@osa-lang:AppleScript
use framework "Foundation"
use scripting additions

property pScriptName : "BaseLibrary"

property logger : missing value

on initialize(loggingContext)
	if logger is missing value then
		set config to load script (POSIX path of (path to home folder) & ".mailscripts/config.scpt")
		set logger to load script ((pMailScriptsPath of config) & "/Libs/Logger.scpt")
		tell logger to initialize()
	end if
	return pScriptName & " > " & loggingContext
end initialize

on showLogLevel()
	my initialize()
	tell logger to info(pScriptName, "Current log level is: " & LOG_LEVEL)
end showLogLevel

on textBeforeFirstBracket(s)
	set logCtx to my initialize("textBeforeFirstBracket")
	tell logger to debug(logCtx, "enter => " & s)

	set p to offset of "[" in s
	if p > 0 then return text 1 thru (p - 1) of s

	tell logger to debug(logCtx, "exit => " & s)
	return s
end textBeforeFirstBracket

on text2List(theText, theDelimiter)
	set logCtx to my initialize("text2list")
	tell logger to debug(logCtx, "enter")

	-- Splitten
	set oldDelims to AppleScript's text item delimiters
	set AppleScript's text item delimiters to theDelimiter
	set rawItems to every text item of theText
	set AppleScript's text item delimiters to oldDelims

	-- Trimmen
	set trimmedItems to {}
	repeat with anItem in rawItems
		--set end of trimmedItems to my trim(anItem as text)
		set anItem to my textBeforeFirstBracket(anItem as text)
		set end of trimmedItems to my trim(anItem)
	end repeat

	tell logger to debug(logCtx, "exit =>" & trimmedItems)
	return trimmedItems
end text2List

on configValue(theFile, theKey)
	set logCtx to my initialize("configValue")
	tell logger to debug(logCtx, "enter => theFile: " & theFile & ", theKey: " & theKey)

	set jsonPath to POSIX path of theFile

	-- Datei laden
	set jsonData to current application's NSData's dataWithContentsOfFile:jsonPath

	-- JSON parsen
	set {jsonDict, theError} to current application's NSJSONSerialization's JSONObjectWithData:jsonData options:0 |error|:(reference)

	if jsonDict is missing value then error "JSON Parsing fehlgeschlagen"

	set theValue to jsonDict's objectForKey:theKey

	tell logger to debug(logCtx, "exit =>" & theValue)
	return theValue
end configValue

on decodeBase64(encodedString)
	set logCtx to my initialize("decodeBase64")
	tell logger to debug(logCtx, "enter => encodedString: " & encodedString)

	set decodedString to do shell script "echo " & quoted form of encodedString & " | base64 --decode"

	tell logger to debug(logCtx, "exit =>" & decodedString)
	return decodedString
end decodeBase64

-- https://www.macscripter.net/t/trim-remove-spaces/45457
on trim(theText)
	repeat until theText does not start with " "
		set theText to text 2 thru -1 of theText
	end repeat

	repeat until theText does not end with " "
		set theText to text 1 thru -2 of theText
	end repeat

	return theText
end trim

on replaceText(findText, replaceText, theText)
	set AppleScript's text item delimiters to findText
	set theItems to every text item of theText
	set AppleScript's text item delimiters to replaceText
	set newText to theItems as string
	set AppleScript's text item delimiters to ""
	return newText
end replaceText

-- https://gist.github.com/Glutexo/78c170e2e314f0eacc1a
on zero_pad(value, string_length)
	set string_zeroes to ""
	set digits_to_pad to string_length - (length of (value as string))
	if digits_to_pad > 0 then
		repeat digits_to_pad times
			set string_zeroes to string_zeroes & "0" as string
		end repeat
	end if
	set padded_value to string_zeroes & value as string
	return padded_value
end zero_pad

on formatDateWithDashes(theDate)
	set now to (theDate)

	set result to (year of now as integer) as string
	set result to result & "-"
	set result to result & zero_pad(month of now as integer, 2)
	set result to result & "-"
	set result to result & zero_pad(day of now as integer, 2)

	return result
end formatDateWithDashes

on format(theDate)
	set now to (theDate)

	set result to (year of now as integer) as string
	set result to result & ""
	set result to result & zero_pad(month of now as integer, 2)
	set result to result & ""
	set result to result & zero_pad(day of now as integer, 2)
	set result to result & "-"
	set result to result & zero_pad(hours of now as integer, 2)
	set result to result & ""
	set result to result & zero_pad(minutes of now as integer, 2)
	--set result to result & ":"
	--set result to result & zero_pad(seconds of now as integer, 2)

	return result
end format

on formatDateTime(theDate, includeTime)
	set logCtx to my initialize("formatDateTime")
	tell logger to debug(logCtx, "enter => " & theDate)

	set resultTime to ""
	if includeTime then
		set resultTime to resultTime & " "
		set resultTime to resultTime & zero_pad(hours of theDate as integer, 2)
		set resultTime to resultTime & ":"
		set resultTime to resultTime & zero_pad(minutes of theDate as integer, 2)
	end if
	set result to ""
	set result to result & zero_pad(day of theDate as integer, 2)
	set result to result & "."
	set result to result & zero_pad(month of theDate as integer, 2)
	set result to result & "."
	set result to result & characters 3 thru 4 of ((year of theDate as integer) as string)
	set result to result & resultTime

	tell logger to debug(logCtx, "exit => " & result)
	return result
end formatDateTime


-- https://apple.stackexchange.com/questions/106350/how-do-i-save-a-screenshot-with-the-iso-8601-date-format-with-applescript
on date_to_iso(dt)
	set {year:y, month:m, day:d} to dt
	set y to text 2 through -1 of ((y + 10000) as text)
	set m to text 2 through -1 of ((m + 100) as text)
	set d to text 2 through -1 of ((d + 100) as text)
	return y & "-" & m & "-" & d
end date_to_iso

on extentionOf(theFilename)
	set logCtx to my initialize("extentionOf")
	tell logger to debug(logCtx, "enter")

	set oldDelims to AppleScript's text item delimiters
	set AppleScript's text item delimiters to "."

	set theExtension to text item -1 of theFilename

	set AppleScript's text item delimiters to oldDelims

	tell logger to debug(logCtx, "exit => " & theExtension)
	return theExtension
end extentionOf

on isoStringToDate(isoString)
	set logCtx to my initialize("isoStringToDate")
	tell logger to debug(logCtx, "enter: " & isoString)

	set d to missing value
	if isoString is not missing value and isoString is not equal to "" then
		-- 1) Input säubern (CR/LF raus, sonst scheitert BSD date gern)
		set sClean to do shell script "printf %s " & quoted form of isoString & " | tr -d ''"

		-- 2) Unix-Sekunden ausrechnen (stderr mitnehmen!)
		set cmd to "date -j -f '%Y-%m-%d %H:%M:%S' " & quoted form of sClean & " +%s 2>&1"
		set out to do shell script cmd

		-- 3) Prüfen ob wirklich eine Zahl zurückkam
		try
			set unixTime to out as integer
		on error
			error "BSD date konnte nicht parsen. Ausgabe war: " & out
		end try

		-- 4) Unix-Epoch (1970) -> AppleScript-Date bauen, ohne Locale-Parsing:
		-- AppleScript kann Datum-Arithmetik sehr gut: baseDate + Sekunden
		set baseDate to current date
		set year of baseDate to 1904
		set month of baseDate to January
		set day of baseDate to 1
		set time of baseDate to 0

		-- Unix-Sekunden sind seit 1970; Differenz 1904->1970 = 2082844800 Sekunden
		set macSecondsSince1904 to unixTime + 2.0828448E+9
		set d to baseDate + macSecondsSince1904
	end if
	--display dialog ("Parsed date: " & (d as text)) buttons {"OK"}
	tell logger to debug(logCtx, "exit => d: " & d as text)
	return d
end isoStringToDate


