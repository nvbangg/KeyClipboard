; KeyClipboard - Powerful Clipboard manager and Keyboard automation tool with flexible Shortcuts

#SingleInstance Force
#Include app\utils.ahk
#Include app\UI.ahk
#Include clipboard\clipboard.ahk
#Include keyboard\keyboard.ahk

; === INIT ===
global settingsFilePath := A_ScriptDir . "\data\settings.ini"
initSettings()
initCapsLockMonitor()
initClipboard()

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

; === HOTKEYS ===
#HotIf mouseEnabled
RAlt:: Click()           ; Right Alt to left click
RCtrl:: Click("Right")   ; Right Ctrl to right click
#HotIf

#HotIf WinActive("ahk_exe chrome.exe")
CapsLock & t:: translateInChrome()
#HotIf

CapsLock & s:: showSettings()
CapsLock & f:: pasteSpecific() ; Paste combining previous and current item

#HotIf GetKeyState("CapsLock", "P")
Space & t:: alwaysOnTop() ; Toggle Always-on-Top for active Window
c:: showClipboard()
Space & c:: clearClipboard()

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

; Hotkeys for clipboard history paste
v:: pastePrev(0)                ; Paste latest item from clipboard history
Space & v:: pastePrev(0, 1)     ; Paste latest item with format
+v:: pastePrev(0, -1)           ; Paste latest item as original
^v:: pastePrevFromSaved(0)      ; Paste latest item from saved tab
b:: pastePrev(1)                ; Paste the item before the latest
Space & b:: pastePrev(1, 1)     ; Paste the item before the latest with format
+b:: pastePrev(1, -1)           ; Paste the item before the latest as original
^b:: pastePrevFromSaved(1)      ; Paste the item before the latest from saved tab
a:: pasteSelected()             ; Paste all clipboard items
Space & a:: pasteSelected(, , 1) ; Paste all clipboard items with format
+a:: pasteSelected(, , -1)      ; Paste all clipboard items as original
^a:: pasteSelected(, , 0, true) ; Paste all saved items

#HotIf