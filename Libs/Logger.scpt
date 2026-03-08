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

on initialize()
	my debug(pScriptName, "initialize: enter")

	set mailscriptsConfig to load script (POSIX path of (path to home folder) & ".mailscripts/config.scpt")
	set LOG_LEVEL to (pLogLevel of mailscriptsConfig)

	my debug(pScriptName, "initialize: exit")
end initialize

on setLogLevel(logLevel)
	set LOG_LEVEL to logLevel
	my debug(pScriptName, "setLogLevel to " & logLevel)
end setLogLevel

on showLogLevel()
	set log_ctx to pScriptName & "." & "showLogLevel"
	my info(log_ctx, "Current log level is: " & LOG_LEVEL)
end showLogLevel

on trace(theMethod, theMessage)
	if pTraceMetricsEnabled then my updateTraceMetrics(theMethod, theMessage)
	if LOG_LEVEL ≤ LOG_LEVEL_TRACE then
		tell application id "DNtp" to log message "TRACE: " & theMethod info theMessage
	end if
end trace

on setTraceMetricsEnabled(theValue)
	set pTraceMetricsEnabled to theValue as boolean
end setTraceMetricsEnabled

on resetTraceMetrics()
	set pTraceCallStack to {}
	set pTraceOperationStats to {}
end resetTraceMetrics

on getTraceMetrics()
	return pTraceOperationStats
end getTraceMetrics

on logTraceMetrics()
	set logCtx to pScriptName & " > logTraceMetrics"
	my info(logCtx, "Operation runtime summary (exclusive ms).")
	set sortedStats to my sortedTraceStatsByExclusiveTotalMs()
	set totalExclusiveMs to 0.0
	repeat with aStat in sortedStats
		set totalExclusiveMs to totalExclusiveMs + (exclusiveTotalMs of aStat)
	end repeat
	set totalExclusiveMs to my roundTo3(totalExclusiveMs)

	repeat with aStat in sortedStats
		set theStat to aStat
		set callCountValue to callCount of theStat
		set exclusiveTotalValue to my roundTo3(exclusiveTotalMs of theStat)
		set maxExclusiveValue to my roundTo3(maxExclusiveMs of theStat)
		set avgExclusiveValue to 0
		set sharePercentValue to 0
		if callCountValue > 0 then set avgExclusiveValue to my roundTo3((exclusiveTotalMs of theStat) / callCountValue)
		if totalExclusiveMs > 0 then set sharePercentValue to my roundTo1(((exclusiveTotalMs of theStat) / totalExclusiveMs) * 100.0)
		my info(logCtx, "share_percent=" & sharePercentValue & "%, calls=" & callCountValue & ", exclusive_total_ms=" & exclusiveTotalValue & ", avg_exclusive_ms=" & avgExclusiveValue & ", max_exclusive_ms=" & maxExclusiveValue & ", operation=" & (operationName of theStat))
	end repeat
end logTraceMetrics

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

on updateTraceMetrics(logCtx, traceMessage)
	set messageText to traceMessage as text
	if my startsWith(messageText, "enter") or my startsWith(messageText, "entry") then
		my beginTraceOperation(my traceOperationName(logCtx))
	else if my startsWith(messageText, "exit") then
		my endTraceOperation(my traceOperationName(logCtx))
	end if
end updateTraceMetrics

on beginTraceOperation(operationName)
	set frame to {operationName:operationName, startMs:(my monotonicMs()), childMs:0.0}
	set end of pTraceCallStack to frame
end beginTraceOperation

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

on trimWhitespace(theText)
	set theNSString to current application's NSString's stringWithString:(theText as text)
	set theSet to current application's NSCharacterSet's whitespaceAndNewlineCharacterSet()
	return (theNSString's stringByTrimmingCharactersInSet:theSet) as text
end trimWhitespace

on startsWith(theText, thePrefix)
	set textValue to theText as text
	set prefixValue to thePrefix as text
	set prefixLength to length of prefixValue
	if (length of textValue) < prefixLength then return false
	return (text 1 thru prefixLength of textValue) is prefixValue
end startsWith

on monotonicMs()
	return ((current application's NSProcessInfo's processInfo()'s systemUptime()) * 1000.0) as real
end monotonicMs

on roundTo3(theValue)
	set scale to 1000.0
	return ((round ((theValue as real) * scale)) / scale) as real
end roundTo3

on roundTo1(theValue)
	set scale to 10.0
	return ((round ((theValue as real) * scale)) / scale) as real
end roundTo1

on debug(theMethod, theMessage)
	if LOG_LEVEL ≤ LOG_LEVEL_DEBUG then
		tell application id "DNtp" to log message "DEBUG: " & theMethod info theMessage
	end if
end debug

on info(theMethod, theMessage)
	if LOG_LEVEL ≤ LOG_LEVEL_INFO then
		tell application id "DNtp" to log message "INFO: " & theMethod info theMessage
	end if
end info

on debug_r(theRecord, theMessage)
	if LOG_LEVEL ≤ LOG_LEVEL_DEBUG then
		tell application id "DNtp" to log message info theMessage record theRecord
	end if
end debug_r

on info_r(theRecord, theMessage)
	if LOG_LEVEL ≤ LOG_LEVEL_INFO then
		tell application id "DNtp" to log message info theMessage record theRecord
	end if
end info_r

to display given msg:theMsg : "", record:theRecord : missing value
	tell application id "DNtp"
		if theRecord is missing value then
			log message "Info" info theMsg
		else
			log message info theMsg record theRecord
		end if
	end tell
end display
