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

on loadConfiguration(theDatabaseConfigurationFolder, theDatabaseName)
	set logCtx to my initialize("loadConfiguration")
	logger's trace(logCtx, "enter")

	set databaseConfigurationFilename to theDatabaseConfigurationFolder & "/Database-" & theDatabaseName & ".scpt"

	try
		set databaseConfiguration to load script databaseConfigurationFilename
	on error
		error "Database configuration file not found. Expected database configuration file: " & databaseConfigurationFilename
	end try

	set configurationFilename to pConfigurationFile of databaseConfiguration
	try
		set configurationFile to load script (theDatabaseConfigurationFolder & "/" & configurationFilename)
	on error
		error "Configuration file not found. Expected configuration file: " & configurationFilename
	end try

	logger's debug(logCtx, "Configuration file: " & configurationFilename)
	logger's trace(logCtx, "exit")
	return configurationFile
end loadConfiguration

-- Resolves dimensions cache path from configuration with a safe default.
-- Parameters:
--    configurationFile:script object loaded from database configuration.
--    theDatabaseName:text target database name.
--    theDatabaseConfigurationFolder:text base folder for database configurations.
-- Return: text computed cache path.
on resolveDimensionsCachePath(configurationFile, theDatabaseName, theDatabaseConfigurationFolder)
	set logCtx to my initialize("resolveDimensionsCachePath")
	logger's trace(logCtx, "enter")

	try
		set configuredPath to pDimensionsCachePath of configurationFile
		if configuredPath is not missing value and configuredPath is not "" then
			logger's debug(logCtx, "Using configured dimensions cache path: " & configuredPath)
			logger's trace(logCtx, "exit")
			return configuredPath
		end if
	end try

	set sanitizedDatabaseName to my sanitizeFilename(theDatabaseName as string)
	set defaultPath to theDatabaseConfigurationFolder & "/cache/dimensions-" & sanitizedDatabaseName & ".json"
	logger's debug(logCtx, "Using default dimensions cache path: " & defaultPath)
	logger's trace(logCtx, "exit")
	return defaultPath
end resolveDimensionsCachePath

-- Returns true when the dimensions cache file already exists.
-- Parameters:
--    cachePath:text absolute file path to the dimensions cache JSON file.
-- Return: boolean computed result.
on dimensionsCacheExists(cachePath)
	if cachePath is missing value or cachePath is "" then return false
	set fm to current application's NSFileManager's defaultManager()
	return (fm's fileExistsAtPath:cachePath) as boolean
end dimensionsCacheExists

-- Loads dimensions from a JSON cache file.
-- Parameters:
--    cachePath:text absolute file path to the dimensions cache JSON file.
-- Return: NSMutableDictionary<text,list<text>> computed result.
on readDimensionsCache(cachePath)
	set logCtx to my initialize("readDimensionsCache")
	logger's trace(logCtx, "enter")

	if cachePath is missing value or cachePath is "" then error "Dimensions cache path is not configured."

	set fm to current application's NSFileManager's defaultManager()
	if (fm's fileExistsAtPath:cachePath) as boolean is false then error "Dimensions cache file not found at: " & cachePath

	set jsonData to current application's NSData's dataWithContentsOfFile:cachePath
	if jsonData is missing value then error "Cannot read dimensions cache file: " & cachePath

	set {payload, parseError} to current application's NSJSONSerialization's JSONObjectWithData:jsonData options:0 |error|:(reference)
	if payload is missing value then error "Failed to parse dimensions cache JSON at: " & cachePath

	set dimensionsPayload to payload's objectForKey:"dimensions"
	if dimensionsPayload is missing value then error "Dimensions cache JSON does not contain key 'dimensions'."

	logger's trace(logCtx, "exit")
	return current application's NSMutableDictionary's dictionaryWithDictionary:dimensionsPayload
end readDimensionsCache

-- Writes dimensions to a JSON cache file and creates parent directories when needed.
-- Parameters:
--    cachePath:text absolute file path to the dimensions cache JSON file.
--    dimensionsDictionary:NSMutableDictionary<text,list<text>> dimensions to persist.
-- Return: none (side effects only).
on writeDimensionsCache(cachePath, dimensionsDictionary)
	set logCtx to my initialize("writeDimensionsCache")
	logger's trace(logCtx, "enter")

	if cachePath is missing value or cachePath is "" then error "Dimensions cache path is not configured."

	set cachePathNSString to current application's NSString's stringWithString:cachePath
	set cacheDirPath to cachePathNSString's stringByDeletingLastPathComponent()
	set fm to current application's NSFileManager's defaultManager()

	set {dirOk, dirError} to fm's createDirectoryAtPath:cacheDirPath withIntermediateDirectories:true attributes:(missing value) |error|:(reference)
	if (dirOk as boolean) is false then error "Failed to create cache directory: " & (cacheDirPath as text)

	set payload to current application's NSMutableDictionary's dictionary()
	(payload's setObject:1 forKey:"version")
	(payload's setObject:(current application's NSDate's |date|()'s description()) forKey:"updatedAt")
	(payload's setObject:dimensionsDictionary forKey:"dimensions")

	set {jsonData, jsonError} to current application's NSJSONSerialization's dataWithJSONObject:payload options:(current application's NSJSONWritingPrettyPrinted) |error|:(reference)
	if jsonData is missing value then error "Failed to serialize dimensions cache JSON."

	set writeOk to jsonData's writeToFile:cachePath atomically:true
	if (writeOk as boolean) is false then error "Failed to write dimensions cache file: " & cachePath

	logger's trace(logCtx, "exit")
end writeDimensionsCache

-- Replaces unsafe filename characters for cache file generation.
-- Parameters:
--    rawName:text input text.
-- Return: text safe filename segment.
on sanitizeFilename(rawName)
	set safeName to rawName as string
	set safeName to my replaceText("/", "_", safeName)
	set safeName to my replaceText(":", "_", safeName)
	set safeName to my replaceText("\\", "_", safeName)
	set safeName to my replaceText(" ", "_", safeName)
	return safeName
end sanitizeFilename


on showLogLevel()
	my initialize()
	tell logger to info(pScriptName, "Current log level is: " & LOG_LEVEL)
end showLogLevel

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
		set anItem to anItem as text
		set end of trimmedItems to my trim(anItem)
	end repeat

	tell logger to debug(logCtx, "exit =>" & trimmedItems)
	return trimmedItems
end text2List

on textBeforeFirstBracket(s)
	set logCtx to my initialize("textBeforeFirstBracket")
	tell logger to debug(logCtx, "enter => " & s)

	set p to offset of "[" in s
	tell logger to info(logCtx, "p: " & p)
	if p > 0 then
		if p > 1 then
			set s to text 1 thru (p - 1) of s
		else
			set s to ""
		end if
	end if
	tell logger to debug(logCtx, "exit => " & s)
	return s
end textBeforeFirstBracket

-- https://www.macscripter.net/t/trim-remove-spaces/45457
on trim(theText)
	set logCtx to my initialize("trim")
	tell logger to debug(logCtx, "enter => '" & theText & "'")

	try
		repeat until theText does not start with " "
			set theText to text 2 thru -1 of theText
		end repeat

		repeat until theText does not end with " "
			set theText to text 1 thru -2 of theText
		end repeat

	on error error_message number error_number
		-- tell logger to info(logCtx, (error_number as text) & ": " & error_message)
		set theText to ""
	end try

	tell logger to debug(logCtx, "exit => '" & theText & "'")
	return theText
end trim

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

-- Returns runtime details about the DEVONthink app resolved via bundle identifier.
-- Return: record {application:text, applicationName:text, version:text, applicationVersion:text, bundleIdentifier:text, applicationPath:text}
on getDEVONthinkRuntimeInfo()
	set logCtx to my initialize("getDEVONthinkRuntimeInfo")
	tell logger to debug(logCtx, "enter")

	set preferredBundleIdentifiers to {"com.devon-technologies.think", "com.devon-technologies.think3", "com.devon-technologies.thinkpro2", "DNtp"}
	set plistCandidates to {"/Applications/DEVONthink.app/Contents/Info.plist", "/Applications/Setapp/DEVONthink.app/Contents/Info.plist", "/Applications/DEVONthink 3.app/Contents/Info.plist"}
	set plistSuffix to "/Contents/Info.plist"
	set theBundleIdentifier to item 1 of preferredBundleIdentifiers
	set theApplicationName to "DEVONthink"
	set theVersion to ""
	set theApplicationPath to ""

	try
		repeat with candidateIdentifier in preferredBundleIdentifiers
			try
				tell application id (candidateIdentifier as text)
					set queriedApplicationName to name as text
					set queriedVersion to version as text
				end tell

				if queriedApplicationName is not "" and queriedApplicationName is not "application" and queriedApplicationName is not "missing value" and queriedApplicationName is not "null" and queriedApplicationName is not "(null)" then
					set theApplicationName to queriedApplicationName
				end if

				if queriedVersion is not "" and queriedVersion is not "version" and queriedVersion is not "missing value" and queriedVersion is not "null" and queriedVersion is not "(null)" then
					set theVersion to queriedVersion
					set theBundleIdentifier to candidateIdentifier as text
					exit repeat
				end if
			end try
		end repeat

		set fm to current application's NSFileManager's defaultManager()
		repeat with plistCandidate in plistCandidates
			set plistPath to plistCandidate as text
			if (fm's fileExistsAtPath:plistPath) as boolean then
				if theApplicationPath is "" and plistPath ends with plistSuffix then
					set theApplicationPath to text 1 thru ((length of plistPath) - (length of plistSuffix)) of plistPath
				end if

				if theVersion is "" or theVersion is "version" or theVersion is "missing value" or theVersion is "null" or theVersion is "(null)" then
					try
						set theVersion to do shell script "/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' " & quoted form of plistPath
					on error
						try
							set theVersion to do shell script "/usr/libexec/PlistBuddy -c 'Print :CFBundleVersion' " & quoted form of plistPath
						end try
					end try
				end if

				try
					set theBundleIdentifier to do shell script "/usr/libexec/PlistBuddy -c 'Print :CFBundleIdentifier' " & quoted form of plistPath
				end try

				try
					set theApplicationName to do shell script "/usr/libexec/PlistBuddy -c 'Print :CFBundleName' " & quoted form of plistPath
				end try

				exit repeat
			end if
		end repeat

		set theVersion to do shell script "printf %s " & quoted form of (theVersion as text) & " | tr -d '\\r\\n\\t'"
		set theVersion to my trim(theVersion)
		if theVersion is "" or theVersion is "version" or theVersion is "missing value" or theVersion is "null" or theVersion is "(null)" then set theVersion to "unknown"

		set theApplicationName to do shell script "printf %s " & quoted form of (theApplicationName as text) & " | tr -d '\\r\\n\\t'"
		set theApplicationName to my trim(theApplicationName)
		if theApplicationName is "" or theApplicationName is "application" or theApplicationName is "missing value" or theApplicationName is "null" or theApplicationName is "(null)" then set theApplicationName to "DEVONthink"

		set theBundleIdentifier to do shell script "printf %s " & quoted form of (theBundleIdentifier as text) & " | tr -d '\\r\\n\\t'"
		set theBundleIdentifier to my trim(theBundleIdentifier)
		if theBundleIdentifier is "" then set theBundleIdentifier to "com.devon-technologies.think"

		set runtimeInfo to {application:theApplicationName as text, applicationName:theApplicationName as text, version:theVersion as text, applicationVersion:theVersion as text, bundleIdentifier:theBundleIdentifier, applicationPath:theApplicationPath as text}
		tell logger to debug(logCtx, "exit => " & theApplicationName & " " & theVersion)
		return runtimeInfo
	on error error_message number error_number
		error "DEVONthink runtime information is unavailable (" & error_number & "): " & error_message
	end try
end getDEVONthinkRuntimeInfo


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
