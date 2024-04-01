

# PopClip DEVONthink perform search
name: DT Perform Search
icon: search filled S
#before: show-result
applescript: | # pipe character begins a multi-line string
  tell application id "DNtp"
    set search query of viewer windows to "\"{popclip text}\""
  end tell
# the above lines are indented with two spaces. no tabs allowed in YAML!

# PopClip DEVONthink open Actions record in new Window
name: DT Open Actions Window
icon: square filled A
#before: show-result
applescript: | # pipe character begins a multi-line string
  tell application id "DNtp"
    set theRecordName to "ACT {popclip text}.md"
    set theRecord to lookup records with file theRecordName
    open window for record first item of theRecord
  end tell
# the above lines are indented with two spaces. no tabs allowed in YAML!

