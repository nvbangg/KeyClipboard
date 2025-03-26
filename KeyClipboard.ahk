; KeyClipboard - Powerful Clipboard manager and Keyboard automation tool with flexible Shortcuts

; === INIT ===
#Include app\common.ahk
#Include app\app_functions.ahk
#Include clipboard\clipboard.ahk
#Include keyboard\keyboard.ahk
global dataDir := A_ScriptDir . "\data"
global settingsFilePath := A_ScriptDir . "\data\settings.ini"
initSettings()
initCapsLockMonitor()
initClipboard()

; === HOTKEYS ===
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
^v:: pastePrev(0, 0, true)      ; Paste latest item from saved tab
b:: pastePrev(1)                ; Paste the item before the latest
Space & b:: pastePrev(1, 1)     ; Paste the item before the latest with format
+b:: pastePrev(1, -1)           ; Paste the item before the latest as original
^b:: pastePrev(1, 0, true)      ; Paste the item before the latest from saved tab
a:: pasteSelected()             ; Paste all clipboard items
Space & a:: pasteSelected(, , 1) ; Paste all clipboard items with format
+a:: pasteSelected(, , -1)      ; Paste all clipboard items as original
^a:: pasteSelected(, , 0, true) ; Paste all saved items

#HotIf

;=== UI ===

A_TrayMenu.Add("Settings (Caps+S)", showSettings)
A_TrayMenu.Add("Shortcuts", showShortcuts)
A_TrayMenu.Add("About", showAbout)
A_IconTip := "KeyClipboard - Right click to see more"

showSettings(*) {
    static settingsGui := 0
    static isCreating := false
    if (isCreating)
        return
    isCreating := true
    settingsGui := cleanupGui(settingsGui)

    settingsGui := Gui("+AlwaysOnTop +ToolWindow", "KeyClipboard - Settings")
    settingsGui.SetFont("s10")
    yPos := 10

    ; Use the new function for App Settings
    yPos := addAppSettings(settingsGui, yPos)

    yPos := addKeySettings(settingsGui, yPos)
    yPos := addFormatOptions(settingsGui, yPos)

    ; Helper function for saving and closing
    CloseAndSave() {
        formData := settingsGui.Submit()
        settingsGui := cleanupGui(settingsGui)
        saveSettings(formData)
    }

    settingsGui.Add("Button", "x20 y" . (yPos + 10) . " w100 Default", "Save")
    .OnEvent("Click", (*) => CloseAndSave())
    settingsGui.Add("Button", "x130 y" . (yPos + 10) . " w100", "Shortcuts")
    .OnEvent("Click", (*) => showShortcuts())
    settingsGui.Add("Button", "x240 y" . (yPos + 10) . " w100", "About")
    .OnEvent("Click", (*) => showAbout())

    settingsGui.Show("w375 h" . (yPos + 50))
    closeEvents(settingsGui, (*) => CloseAndSave())
    isCreating := false
}

showShortcuts(*) {
    shortcutsText :=
        "• CapsLock+S: Show Settings Popup`n" .
        "• CapsLock+T: Translate page in Chrome`n" .
        "• CapsLock+Space+T: Always-on-Top for active Window`n" .
        "• CapsLock+C: Show Clipboard History`n" .
        "• CapsLock+Space+C: Clear Clipboard History`n" .
        "• CapsLock+F: Paste combining previous and current item`n`n" .
        "• CapsLock+V: Paste latest item from clipboard history`n" .
        "• CapsLock+B: Paste the item before the latest`n" .
        "• CapsLock+A: Paste all clipboard items`n" .
        "• CapsLock+Space+V/B/A: Paste item(s) with Format`n" .
        "• CapsLock+Shift+V/B/A: Paste item(s) as Original`n" .
        "• CapsLock+Ctrl+V/B/A: Paste item(s) from Saved tab`n" .
        "• CapsLock+1-9: Paste item by position from saved tab`n"

    showInfo("Shortcuts - KeyClipboard", shortcutsText, 375)
}

showAbout(*) {
    aboutText :=
        "KeyClipboard`n" .
        "Version: 1.6.2`n" .
        "Date: 26/03/2025`n`n" .
        "Source: github.com/nvbangg/KeyClipboard`n" .
        "Click Yes to open"

    result := MsgBox(aboutText, "About KeyClipboard", "YesNo 262144")  ; YesNo with AlwaysOnTop flag

    if (result == "Yes") {
        try {
            Run("https://github.com/nvbangg/KeyClipboard")
        } catch Error as e {
        }
    } else if (result == "No") {
        try {
            Run("https://www.youtube.com/watch?v=dQw4w9WgXcQ") ; =)))))
        } catch Error as e {
        }
    }
}
