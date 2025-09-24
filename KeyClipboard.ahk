#Include src/UI/app.ahk
#Include src/UI/clip.ahk

global dataDir := A_ScriptDir . "\data"
global settingsFilePath := A_ScriptDir . "\data\config.ini"
global savedFilePath := A_ScriptDir . "\data\savedHistory.ini"
global history := []
global saved := []

global isProcessing := false
global originalClip := ""
global clipGuiInstance := 0
global viewerFocused := false
global enterCount := 1
global tabCount := 1

initApp()
initClip()

; Check for command-line parameter to open settings
if (A_Args.Length > 0 && A_Args[1] = "settings") {
    SetTimer(showSettings, -200)
}

; CapsLock behavior: single press toggles caps
*CapsLock::
{
    KeyWait "CapsLock"
    if (A_PriorKey = "CapsLock" && A_ThisHotkey = "*CapsLock") {
        Sleep(20)
        if GetKeyState("CapsLock", "T")
            SetCapsLockState "AlwaysOff"
        else
            SetCapsLockState "AlwaysOn"
    }
}

#HotIf GetKeyState("CapsLock", "P")
s:: showSettings()
^s:: alwaysOnTop()
!s:: switchTabPreset()
c:: showClipboard()
^c:: showClipboard(true)
!c:: clearClipboard()

; pasteIndex(index, formatMode, useSaved)
1:: pasteIndex(1)               ; Index latest from history
+1:: pasteIndex(1, 1)           ; Paste format
^1:: pasteIndex(1, 0, true)     ; Index 1 from saved
!1:: pasteIndex(1, -1)          ; Paste original

2:: pasteIndex(2)
+2:: pasteIndex(2, 1)
^2:: pasteIndex(2, 0, true)
!2:: pasteIndex(2, -1)

3:: pasteIndex(3)
+3:: pasteIndex(3, 1)
^3:: pasteIndex(3, 0, true)
!3:: pasteIndex(3, -1)

4:: pasteIndex(4)
+4:: pasteIndex(4, 1)
^4:: pasteIndex(4, 0, true)
!4:: pasteIndex(4, -1)

5:: pasteIndex(5)
+5:: pasteIndex(5, 1)
^5:: pasteIndex(5, 0, true)
!5:: pasteIndex(5, -1)

6:: pasteIndex(6)
+6:: pasteIndex(6, 1)
^6:: pasteIndex(6, 0, true)
!6:: pasteIndex(6, -1)

7:: pasteIndex(7)
+7:: pasteIndex(7, 1)
^7:: pasteIndex(7, 0, true)
!7:: pasteIndex(7, -1)

8:: pasteIndex(8)
+8:: pasteIndex(8, 1)
^8:: pasteIndex(8, 0, true)
!8:: pasteIndex(8, -1)

9:: pasteIndex(9)
+9:: pasteIndex(9, 1)
^9:: pasteIndex(9, 0, true)
!9:: pasteIndex(9, -1)

0:: pasteIndex(10)
+0:: pasteIndex(10, 1)
^0:: pasteIndex(10, 0, true)
!0:: pasteIndex(10, -1)

; Paste all
a:: pasteSelected()
+a:: pasteSelected(, , 1)
^a:: pasteSelected(, , 0, true)
!a:: pasteSelected(, , -1)

t:: pasteWithSeparator("{Tab}", "tabDelay")
+t:: pasteWithSeparator("{Tab}", "tabDelay", , , 1)
^t:: pasteWithSeparator("{Tab}", "tabDelay", , , 0, true)
!t:: pasteWithSeparator("{Tab}", "tabDelay", , , -1)

e:: pasteWithSeparator("{Enter}", "enterDelay")
+e:: pasteWithSeparator("{Enter}", "enterDelay", , , 1)
^e:: pasteWithSeparator("{Enter}", "enterDelay", , , 0, true)
!e:: pasteWithSeparator("{Enter}", "enterDelay", , , -1)

v:: pasteWithTab()           ; Paste item 2, tab, then item 1
+v:: pasteWithTab(1)
^v:: pasteWithTab(0, true)
!v:: pasteWithTab(-1)

b:: pasteWithBeforeLatest()  ; Paste "beforeLatest_latest"
+b:: pasteWithBeforeLatest(true)

#HotIf