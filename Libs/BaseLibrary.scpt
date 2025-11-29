#@osa-lang:AppleScript
property pScriptName : "BaseLibrary"

property LOG_LEVEL : 2

property LOG_LEVEL_DEBUG : 1
property LOG_LEVEL_INFO : 2
property LOG_LEVEL_WARN : 3

on initialize()
	set log_ctx to pScriptName & "." & "initialize"
	my debug(log_ctx, "enter")

	set mailscriptsConfig to load script (POSIX path of (path to home folder) & ".mailscripts/config.scpt")
	set LOG_LEVEL to (pLogLevel of mailscriptsConfig)

	my debug(log_ctx, "exit")
end initialize

on showLogLevel()
	set log_ctx to pScriptName & "." & "showLogLevel"
	my info(log_ctx, "Current log level is: " & LOG_LEVEL)
end showLogLevel

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

-- https://apple.stackexchange.com/questions/106350/how-do-i-save-a-screenshot-with-the-iso-8601-date-format-with-applescript
on date_to_iso(dt)
	set {year:y, month:m, day:d} to dt
	set y to text 2 through -1 of ((y + 10000) as text)
	set m to text 2 through -1 of ((m + 100) as text)
	set d to text 2 through -1 of ((d + 100) as text)
	return y & "-" & m & "-" & d
end date_to_iso

