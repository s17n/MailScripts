#@osa-lang:AppleScript
property pScriptName : "PopClip SetSender"
property pMailScriptProperties : POSIX path of (path to home folder) & ".applescript/properties-mailscripts.scpt"

set scriptProperties to (load script pMailScriptProperties)
set popClipLibraryPath to (pPopClipLibraryPath of scriptProperties)
set popClipLibrary to (load script file popClipLibraryPath)
tell popClipLibrary to hello("{popclip text}")
