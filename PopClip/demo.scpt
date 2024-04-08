#@osa-lang:AppleScript
-- # PopClip LaunchBar example
-- name: MD Link
-- icon: MDL
-- after: show-result
-- language: applescript

tell application id "DNtp"
	set theRecord to first item of selected records
	set theDate to "09.04.2024 08:30" as string
	set theAlarmString to "The alarm string"
	tell theRecord to make new reminder with properties {schedule:once, alarm:notification, alarm string:theAlarmString, due date:theDate}
	set label of theRecord to 1
end tell
