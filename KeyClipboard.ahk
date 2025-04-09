; A Powerful Clipboard to replace Windows Clipboard with convenient Keyboard shortcut!

#Include src\app\app.ahk
#Include src\clipboard\clipboard.ahk
#Include src\UI\UI.ahk

global dataDir := A_ScriptDir . "\data"
global settingsFilePath := A_ScriptDir . "\data\config.ini"
global savedFilePath := A_ScriptDir . "\data\savedHistory.ini"
global historyTab := []
global savedTab := []
global isProcessing := false
global originalClip := ""
global clipGuiInstance := 0
global contentViewerIsFocused := false

initSettings()
initCapsLockMonitor()
initClipboard()

; Check for command-line parameter to open settings
if (A_Args.Length > 0 && A_Args[1] = "settings") {
    SetTimer(showSettings, -200)
}

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
+s:: alwaysOnTop()
Tab & s:: switchTabPreset()     ; Cycle to next preset in the list
c:: showClipboard()
Tab & c:: showClipboard(true)   ; Open clipboard Saved tab
+c:: clearClipboard()
f:: pasteSpecific()

v:: pastePrev(0)                ; Paste latest item
+v:: pastePrev(0, 1)            ; Paste latest item with format
^v:: pastePrev(0, -1)           ; Paste latest item as original
Tab & v:: pastePrev(0, 0, true) ; Paste latest item from saved tab
b:: pastePrev(1)                ; Paste the item before the latest
+b:: pastePrev(1, 1)            ; Paste the item before the latest with format
^b:: pastePrev(1, -1)           ; Paste the item before the latest as original
Tab & b:: pastePrev(1, 0, true) ; Paste the item before the latest from saved tab
a:: pasteSelected()             ; Paste all clipboard items
+a:: pasteSelected(, , 1)       ; Paste all clipboard items with format
^a:: pasteSelected(, , -1)      ; Paste all clipboard items as original
Tab & a:: pasteSelected(, , 0, true) ; Paste all saved items

; Hotkeys to paste items by position from saved tab (1-9)
1:: pasteByPosition(1)
2:: pasteByPosition(2)
3:: pasteByPosition(3)
4:: pasteByPosition(4)
5:: pasteByPosition(5)
6:: pasteByPosition(6)
7:: pasteByPosition(7)
8:: pasteByPosition(8)
9:: pasteByPosition(9)

#HotIf