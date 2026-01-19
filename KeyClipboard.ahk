#SingleInstance Force
#Include src/UI/app.ahk
#Include src/UI/clip.ahk

global dataDir := A_ScriptDir . "\data"
global SETTINGS_PATH := A_ScriptDir . "\data\settings.ini"
global SAVED_PATH := A_ScriptDir . "\data\saved.ini"
global history := []
global saved := []
global isProcessing := false
global clipGuiInstance := 0

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

1:: pasteIndex(-1)
!1:: pasteIndex(1)
+1:: pasteIndex(-1, 1)
+!1:: pasteIndex(1, 1)
^1:: pasteIndex(-1, , true)
^!1:: pasteIndex(1, , true)

2:: pasteIndex(-2)
+2:: pasteIndex(-2, 1)
^2:: pasteIndex(-2, , true)
!2:: pasteIndex(2)
^!2:: pasteIndex(2, , true)
+!2:: pasteIndex(2, 1)

3:: pasteIndex(-3)
+3:: pasteIndex(-3, 1)
^3:: pasteIndex(-3, , true)
!3:: pasteIndex(3)
^!3:: pasteIndex(3, , true)
+!3:: pasteIndex(3, 1)

4:: pasteIndex(-4)
+4:: pasteIndex(-4, 1)
^4:: pasteIndex(-4, , true)
!4:: pasteIndex(4)
^!4:: pasteIndex(4, , true)
+!4:: pasteIndex(4, 1)

5:: pasteIndex(-5)
+5:: pasteIndex(-5, 1)
^5:: pasteIndex(-5, , true)
!5:: pasteIndex(5)
^!5:: pasteIndex(5, , true)
+!5:: pasteIndex(5, 1)

6:: pasteIndex(-6)
+6:: pasteIndex(-6, 1)
^6:: pasteIndex(-6, , true)
!6:: pasteIndex(6)
^!6:: pasteIndex(6, , true)
+!6:: pasteIndex(6, 1)

7:: pasteIndex(-7)
+7:: pasteIndex(-7, 1)
^7:: pasteIndex(-7, , true)
!7:: pasteIndex(7)
^!7:: pasteIndex(7, , true)
+!7:: pasteIndex(7, 1)

8:: pasteIndex(-8)
+8:: pasteIndex(-8, 1)
^8:: pasteIndex(-8, , true)
!8:: pasteIndex(8)
^!8:: pasteIndex(8, , true)
+!8:: pasteIndex(8, 1)

9:: pasteIndex(-9)
+9:: pasteIndex(-9, 1)
^9:: pasteIndex(-9, , true)
!9:: pasteIndex(9)
^!9:: pasteIndex(9, , true)
+!9:: pasteIndex(9, 1)

0:: pasteIndex(-10)
+0:: pasteIndex(-10, 1)
^0:: pasteIndex(-10, , true)
!0:: pasteIndex(10)
^!0:: pasteIndex(10, , true)
+!0:: pasteIndex(10, 1)

; Paste all
a:: pasteSelected()
+a:: pasteSelected(, , 1)
^a:: pasteSelected(, , , true)

t:: pasteWithSeparator("{Tab}", "tabDelay")
+t:: pasteWithSeparator("{Tab}", "tabDelay", , , 1)
^t:: pasteWithSeparator("{Tab}", "tabDelay", , , , true)

e:: pasteWithSeparator("{Enter}", "enterDelay")
+e:: pasteWithSeparator("{Enter}", "enterDelay", , , 1)
^e:: pasteWithSeparator("{Enter}", "enterDelay", , , , true)

v:: pasteWithTab()           ; Paste item 2, tab, then item 1
+v:: pasteWithTab(1)
^v:: pasteWithTab(, true)
!v:: pasteWithTab(, , true)
^!v:: pasteWithTab(, true, true)

b:: pasteWithBeforeLatest()  ; Paste "beforeLatest_latest"
+b:: pasteWithBeforeLatest(true)

#HotIf