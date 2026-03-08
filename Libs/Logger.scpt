#@osa-lang:AppleScript
use AppleScript version "2.4"
use framework "Foundation"
use scripting additions

property pScriptName : "Logger"

property LOG_LEVEL : 2

property LOG_LEVEL_TRACE : 0
property LOG_LEVEL_DEBUG : 1
property LOG_LEVEL_INFO : 2
property LOG_LEVEL_WARN : 3

property pTraceMetricsEnabled : true
property pTraceCallStack : {}
property pTraceOperationStats : {}
property pLogFilePath : missing value

-- Initializes logger state from global configuration.
-- Parameters:
--    none.
-- Return: none (side effects only).
-- Adds timing values to an operation metric aggregate.
-- Parameters:
--    operationName:text operation identifier.
--    exclusiveMs:real exclusive runtime in ms.
--    inclusiveMs:real inclusive runtime in ms.
-- Return: none (side effects only).
on addTraceStat(operationName, exclusiveMs, inclusiveMs)
	set statsCount to count of pTraceOperationStats
	repeat with statIndex from 1 to statsCount
		set currentStat to item statIndex of pTraceOperationStats
		if operationName of currentStat is operationName then
			set updatedCallCount to (callCount of currentStat) + 1
			set updatedExclusiveTotal to (exclusiveTotalMs of currentStat) + exclusiveMs
			set updatedInclusiveTotal to (inclusiveTotalMs of currentStat) + inclusiveMs
			set updatedMaxExclusive to maxExclusiveMs of currentStat
			if exclusiveMs > updatedMaxExclusive then set updatedMaxExclusive to exclusiveMs
			set item statIndex of pTraceOperationStats to {operationName:operationName, callCount:updatedCallCount, exclusiveTotalMs:updatedExclusiveTotal, inclusiveTotalMs:updatedInclusiveTotal, maxExclusiveMs:updatedMaxExclusive}
			return
		end if
	end repeat
	set end of pTraceOperationStats to {operationName:operationName, callCount:1, exclusiveTotalMs:exclusiveMs, inclusiveTotalMs:inclusiveMs, maxExclusiveMs:exclusiveMs}
end addTraceStat

-- Appends a line to the configured log file path.
-- Parameters:
--    theLine:text line content to append.
-- Return: none (side effects only).
on appendToLogFile(theLine)
	if pLogFilePath is missing value then return
	set targetPath to pLogFilePath as text
	if targetPath is "" then return

	try
		set dirPath to do shell script "/usr/bin/dirname " & quoted form of targetPath
		do shell script "/bin/mkdir -p " & quoted form of dirPath & " && /usr/bin/printf '%s\\n' " & quoted form of (theLine as text) & " >> " & quoted form of targetPath
	end try
end appendToLogFile

-- Pushes an operation frame to the timing stack.
-- Parameters:
--    operationName:text operation identifier.
-- Return: none (side effects only).
on beginTraceOperation(operationName)
	set frame to {operationName:operationName, startMs:(my monotonicMs()), childMs:0.0}
	set end of pTraceCallStack to frame
end beginTraceOperation

-- Emits a debug-level log entry.
-- Parameters:
--    theMethod:text operation context.
--    theMessage:text message payload.
-- Return: none (side effects only).
on debug(theMethod, theMessage)
	if LOG_LEVEL ≤ LOG_LEVEL_DEBUG then
		my writeLog("DEBUG", theMethod, theMessage, missing value)
	end if
end debug

-- Emits a debug-level log entry bound to a record.
-- Parameters:
--    theRecord:DEVONthink record target context.
--    theMessage:text message payload.
-- Return: none (side effects only).
on debug_r(theRecord, theMessage)
	if LOG_LEVEL ≤ LOG_LEVEL_DEBUG then
		my writeLog("DEBUG", pScriptName, theMessage, theRecord)
	end if
end debug_r

-- Convenience wrapper for generic info display calls.
-- Parameters:
--    theMsg:text message payload.
--    theRecord:DEVONthink record|missing value optional record context.
-- Return: none (side effects only).
to display given msg:theMsg : "", record:theRecord : missing value
	my writeLog("INFO", pScriptName, theMsg, theRecord)
end display

-- Pops an operation frame and records inclusive/exclusive timings.
-- Parameters:
--    operationName:text operation identifier.
-- Return: none (side effects only).
on endTraceOperation(operationName)
	if (count of pTraceCallStack) is 0 then return

	set stackDepth to count of pTraceCallStack
	set theFrame to item stackDepth of pTraceCallStack
	if stackDepth is 1 then
		set pTraceCallStack to {}
	else
		set pTraceCallStack to items 1 thru (stackDepth - 1) of pTraceCallStack
	end if

	-- Keep stack robust when tracing messages become unbalanced.
	if operationName of theFrame is not operationName then return

	set endMs to my monotonicMs()
	set inclusiveMs to (endMs - (startMs of theFrame))
	if inclusiveMs < 0 then set inclusiveMs to 0

	set exclusiveMs to (inclusiveMs - (childMs of theFrame))
	if exclusiveMs < 0 then set exclusiveMs to 0

	my addTraceStat(operationName, exclusiveMs, inclusiveMs)

	if (count of pTraceCallStack) > 0 then
		set parentIndex to count of pTraceCallStack
		set parentFrame to item parentIndex of pTraceCallStack
		set updatedParentFrame to {operationName:(operationName of parentFrame), startMs:(startMs of parentFrame), childMs:((childMs of parentFrame) + inclusiveMs)}
		set item parentIndex of pTraceCallStack to updatedParentFrame
	end if
end endTraceOperation

-- Formats a number with a fixed fraction digit count.
-- Parameters:
--    theValue:number input value.
--    fractionDigits:integer fixed number of decimal places.
-- Return: text fixed decimal string.
on formatFixed(theValue, fractionDigits)
	set numberValue to current application's NSNumber's numberWithDouble:(theValue as real)
	set formatter to current application's NSNumberFormatter's new()
	formatter's setLocale:(current application's NSLocale's localeWithLocaleIdentifier:"en_US_POSIX")
	formatter's setMinimumFractionDigits:fractionDigits
	formatter's setMaximumFractionDigits:fractionDigits
	formatter's setUsesGroupingSeparator:false
	return (formatter's stringFromNumber:numberValue) as text
end formatFixed

-- Formats a number with exactly 1 fractional digit.
-- Parameters:
--    theValue:number input value.
-- Return: text fixed decimal string.
on formatFixed1(theValue)
	return my formatFixed(theValue, 1)
end formatFixed1

-- Formats a number with exactly 3 fractional digits.
-- Parameters:
--    theValue:number input value.
-- Return: text fixed decimal string.
on formatFixed3(theValue)
	return my formatFixed(theValue, 3)
end formatFixed3

-- Builds a single plain-text log line.
-- Parameters:
--    theLevel:text severity label.
--    theMethod:text operation context.
--    theMessage:text message payload.
--    theRecord:DEVONthink record|missing value optional record context.
-- Return: text formatted log line.
on formatLogLine(theLevel, theMethod, theMessage, theRecord)
	set logLine to (my isoTimestamp()) & " " & theLevel & " " & (theMethod as text) & " - " & (theMessage as text)
	if theRecord is not missing value then
		set logLine to logLine & " | record=" & (my safeToText(theRecord))
	end if
	return logLine
end formatLogLine

-- Returns current trace metric records.
-- Parameters:
--    none.
-- Return: list<record> aggregated operation metrics.
on getTraceMetrics()
	return pTraceOperationStats
end getTraceMetrics

-- Emits an info-level log entry.
-- Parameters:
--    theMethod:text operation context.
--    theMessage:text message payload.
-- Return: none (side effects only).
on info(theMethod, theMessage)
	if LOG_LEVEL ≤ LOG_LEVEL_INFO then
		my writeLog("INFO", theMethod, theMessage, missing value)
	end if
end info

-- Emits an info-level log entry bound to a record.
-- Parameters:
--    theRecord:DEVONthink record target context.
--    theMessage:text message payload.
-- Return: none (side effects only).
on info_r(theRecord, theMessage)
	if LOG_LEVEL ≤ LOG_LEVEL_INFO then
		my writeLog("INFO", pScriptName, theMessage, theRecord)
	end if
end info_r

on initialize()
	my debug(pScriptName, "initialize: enter")

	set mailscriptsConfig to load script (POSIX path of (path to home folder) & ".mailscripts/config.scpt")
	set LOG_LEVEL to (pLogLevel of mailscriptsConfig)
	try
		set pLogFilePath to (pLogFilePath of mailscriptsConfig)
	on error
		set pLogFilePath to "/tmp/mailscripts.log"
	end try
	set pLogFilePath to my resolveLogFilePath(pLogFilePath)

	my debug(pScriptName, "initialize: exit")
end initialize

-- Returns current timestamp in ISO-like format.
-- Parameters:
--    none.
-- Return: text timestamp value.
on isoTimestamp()
	return do shell script "/bin/date '+%Y-%m-%dT%H:%M:%S%z'"
end isoTimestamp

-- Logs metric totals and per-operation timing summary.
-- Parameters:
--    none.
-- Return: none (side effects only).
on logTraceMetrics()
	set logCtx to pScriptName & " > logTraceMetrics"
	set sortedStats to my sortedTraceStatsByExclusiveTotalMs()
	set totalOperations to count of sortedStats
	set totalCalls to 0
	set totalExclusiveMs to 0.0
	repeat with aStat in sortedStats
		set totalCalls to totalCalls + (callCount of aStat)
		set totalExclusiveMs to totalExclusiveMs + (exclusiveTotalMs of aStat)
	end repeat
	set totalExclusiveText to my formatFixed3(my roundTo3(totalExclusiveMs))
	my appendToLogFile(my formatLogLine("INFO", logCtx, "totals: operations=" & totalOperations & ", calls=" & totalCalls & ", exclusive_total_ms=" & totalExclusiveText, missing value))
	my appendToLogFile(my formatLogLine("INFO", logCtx, "Operation runtime summary (exclusive ms).", missing value))

	repeat with aStat in sortedStats
		set theStat to aStat
		set callCountValue to callCount of theStat
		set exclusiveTotalValue to my roundTo3(exclusiveTotalMs of theStat)
		set maxExclusiveValue to my roundTo3(maxExclusiveMs of theStat)
		set avgExclusiveValue to 0
		set sharePercentValue to 0
		if callCountValue > 0 then set avgExclusiveValue to my roundTo3((exclusiveTotalMs of theStat) / callCountValue)
		if totalExclusiveMs > 0 then set sharePercentValue to my roundTo1(((exclusiveTotalMs of theStat) / totalExclusiveMs) * 100.0)

		set exclusiveTotalText to my formatFixed3(exclusiveTotalValue)
		set avgExclusiveText to my formatFixed3(avgExclusiveValue)
		set maxExclusiveText to my formatFixed3(maxExclusiveValue)
		set sharePercentText to my formatFixed1(sharePercentValue)

		my appendToLogFile(my formatLogLine("INFO", logCtx, "share_percent=" & sharePercentText & "%, calls=" & callCountValue & ", exclusive_total_ms=" & exclusiveTotalText & ", avg_exclusive_ms=" & avgExclusiveText & ", max_exclusive_ms=" & maxExclusiveText & ", operation=" & (operationName of theStat), missing value))
	end repeat
end logTraceMetrics

-- Returns monotonic uptime in milliseconds.
-- Parameters:
--    none.
-- Return: real monotonic milliseconds value.
on monotonicMs()
	return ((current application's NSProcessInfo's processInfo()'s systemUptime()) * 1000.0) as real
end monotonicMs

-- Clears all collected trace metrics.
-- Parameters:
--    none.
-- Return: none (side effects only).
on resetTraceMetrics()
	set pTraceCallStack to {}
	set pTraceOperationStats to {}
end resetTraceMetrics

-- Resolves user-friendly log path tokens to POSIX path.
-- Parameters:
--    thePath:text|missing value configured path.
-- Return: text normalized path.
on resolveLogFilePath(thePath)
	if thePath is missing value then return "/tmp/mailscripts.log"
	set rawPath to thePath as text
	if rawPath is "" then return "/tmp/mailscripts.log"
	if rawPath starts with "~/" then
		set homePath to POSIX path of (path to home folder)
		return homePath & (text 3 thru -1 of rawPath)
	end if
	return rawPath
end resolveLogFilePath

-- Rounds a numeric value to 1 decimal place.
-- Parameters:
--    theValue:number input value.
-- Return: real rounded value.
on roundTo1(theValue)
	set scale to 10.0
	return ((round ((theValue as real) * scale)) / scale) as real
end roundTo1

-- Rounds a numeric value to 3 decimal places.
-- Parameters:
--    theValue:number input value.
-- Return: real rounded value.
on roundTo3(theValue)
	set scale to 1000.0
	return ((round ((theValue as real) * scale)) / scale) as real
end roundTo3

-- Safely converts arbitrary values to text for logging.
-- Parameters:
--    theValue:any value to stringify.
-- Return: text converted value or placeholder.
on safeToText(theValue)
	try
		return theValue as text
	on error
		return "<non-text-value>"
	end try
end safeToText

-- Sets active log verbosity level.
-- Parameters:
--    logLevel:integer target threshold (trace/debug/info/warn).
-- Return: none (side effects only).
on setLogLevel(logLevel)
	set LOG_LEVEL to logLevel
	my debug(pScriptName, "setLogLevel to " & logLevel)
end setLogLevel

-- Enables or disables runtime trace metrics aggregation.
-- Parameters:
--    theValue:boolean desired enable state.
-- Return: none (side effects only).
on setTraceMetricsEnabled(theValue)
	set pTraceMetricsEnabled to theValue as boolean
end setTraceMetricsEnabled

-- Logs the currently active log level.
-- Parameters:
--    none.
-- Return: none (side effects only).
on showLogLevel()
	set log_ctx to pScriptName & "." & "showLogLevel"
	my info(log_ctx, "Current log level is: " & LOG_LEVEL)
end showLogLevel

-- Sorts operation metrics ascending by operation name.
-- Parameters:
--    none.
-- Return: list<record> sorted metrics list.
on sortedTraceStatsByExclusiveTotalMs()
	set remainingStats to pTraceOperationStats
	set sortedStats to {}
	repeat while (count of remainingStats) > 0
		set maxIndex to 1
		set maxValue to exclusiveTotalMs of (item 1 of remainingStats)
		set statsCount to count of remainingStats
		repeat with statIndex from 2 to statsCount
			set candidateValue to exclusiveTotalMs of (item statIndex of remainingStats)
			if candidateValue > maxValue then
				set maxValue to candidateValue
				set maxIndex to statIndex
			end if
		end repeat

		set end of sortedStats to item maxIndex of remainingStats
		if statsCount is 1 then
			set remainingStats to {}
		else if maxIndex is 1 then
			set remainingStats to items 2 thru -1 of remainingStats
		else if maxIndex is statsCount then
			set remainingStats to items 1 thru (statsCount - 1) of remainingStats
		else
			set remainingStats to (items 1 thru (maxIndex - 1) of remainingStats) & (items (maxIndex + 1) thru -1 of remainingStats)
		end if
	end repeat
	return sortedStats
end sortedTraceStatsByExclusiveTotalMs

-- Checks whether text starts with a given prefix.
-- Parameters:
--    theText:text candidate text.
--    thePrefix:text prefix to test.
-- Return: boolean true when prefix matches.
on startsWith(theText, thePrefix)
	set textValue to theText as text
	set prefixValue to thePrefix as text
	set prefixLength to length of prefixValue
	if (length of textValue) < prefixLength then return false
	return (text 1 thru prefixLength of textValue) is prefixValue
end startsWith

-- Emits trace logging and updates optional trace metrics.
-- Parameters:
--    theMethod:text operation context.
--    theMessage:text trace payload.
-- Return: none (side effects only).
on trace(theMethod, theMessage)
	if pTraceMetricsEnabled then my updateTraceMetrics(theMethod, theMessage)
	if LOG_LEVEL ≤ LOG_LEVEL_TRACE then
		my writeLog("TRACE", theMethod, theMessage, missing value)
	end if
end trace

-- Extracts operation name from logger context text.
-- Parameters:
--    logCtx:text logger context.
-- Return: text computed operation name.
on traceOperationName(logCtx)
	set contextText to logCtx as text
	set splitToken to " > "
	if contextText contains splitToken then
		set splitOffset to offset of splitToken in contextText
		set opName to text (splitOffset + (length of splitToken)) thru -1 of contextText
	else
		set opName to contextText
	end if
	return my trimWhitespace(opName)
end traceOperationName

-- Trims leading and trailing whitespace from text.
-- Parameters:
--    theText:text input text value.
-- Return: text trimmed value.
on trimWhitespace(theText)
	set theNSString to current application's NSString's stringWithString:(theText as text)
	set theSet to current application's NSCharacterSet's whitespaceAndNewlineCharacterSet()
	return (theNSString's stringByTrimmingCharactersInSet:theSet) as text
end trimWhitespace

-- Interprets trace messages and updates enter/exit timing state.
-- Parameters:
--    logCtx:text logger context.
--    traceMessage:text message to classify.
-- Return: none (side effects only).
on updateTraceMetrics(logCtx, traceMessage)
	set messageText to traceMessage as text
	if my startsWith(messageText, "enter") or my startsWith(messageText, "entry") then
		my beginTraceOperation(my traceOperationName(logCtx))
	else if my startsWith(messageText, "exit") then
		my endTraceOperation(my traceOperationName(logCtx))
	end if
end updateTraceMetrics

-- Writes one log event to DEVONthink and file sink.
-- Parameters:
--    theLevel:text severity label.
--    theMethod:text operation context.
--    theMessage:text message payload.
--    theRecord:DEVONthink record|missing value optional record context.
-- Return: none (side effects only).
on writeLog(theLevel, theMethod, theMessage, theRecord)
	try
		tell application id "DNtp"
			if theRecord is missing value then
				log message (theLevel & ": " & theMethod) info theMessage
			else
				log message info theMessage record theRecord
			end if
		end tell
	end try

	my appendToLogFile(my formatLogLine(theLevel, theMethod, theMessage, theRecord))
end writeLog
