; KeyClipboard - An advanced clipboard manager and keyboard automation tool with flexible shortcuts and powerful features.
#Requires AutoHotkey v2.0
#SingleInstance Force
#Include "modules\Common.ahk"
#Include "modules\Clip.ahk"
#Include "modules\Key.ahk"

; Initialize settings
initSettings()

; Mouse click
#HotIf mouseEnabled
RAlt:: Click()
RCtrl:: Click("Right")
#HotIf

; Translate page in Chrome hotkey
#HotIf WinActive("ahk_exe chrome.exe")
CapsLock & t:: translateInChrome()
#HotIf

; Hotkeys
CapsLock & b:: pasteBeforeLatest() ;Paste the item before the latest
CapsLock & v:: pasteLatest()    ; Paste latest item from clipboard history
CapsLock & f:: formatWhenPaste() ; Paste latest item with format
CapsLock & a:: pasteSelected() ; Paste all clipboard items
Capslock & d:: pasteSelected(, , true) ; Paste all items with format
CapsLock & x:: clearClipboard()
CapsLock & c:: showClipboard()
CapsLock & s:: showSettings()
CapsLock & r:: toggleBeforeLatestLatest() ; Toggle beforeLatest_Latest feature

; UI
A_TrayMenu.Add("Settings (Caps+S)", showSettings)
A_TrayMenu.Add("Shortcuts", showShortcuts)
A_TrayMenu.Add("About", showAbout)
A_IconTip := "KeyClipboard - Right click to see more"

showAbout(*) {
    result := MsgBox("KeyClipboard`n" .
        "Version: 1.5.1`n" .
        "Date: 13/03/2025`n" .
        "`nSource: github.com/nvbangg/KeyClipboard`n" .
        "Click Yes to open",
        "About KeyClipboard", "YesNo")
    if (result = "Yes")
        Run("https://github.com/nvbangg/KeyClipboard")
    else
        Run("https://www.youtube.com/watch?v=dQw4w9WgXcQ")
    ;   =)))))
}

showShortcuts(*) {
    static shortcutsGui := 0

    try {
        if IsObject(shortcutsGui) && shortcutsGui.HasProp("Hwnd")
            if WinExist("ahk_id " . shortcutsGui.Hwnd)
                shortcutsGui.Destroy()
    } catch {
        ; If any error occurs, just create a new GUI
    }

    ; Create new GUI with appropriate options
    shortcutsGui := Gui("+AlwaysOnTop +ToolWindow")
    shortcutsGui.Title := "Shortcuts - KeyClipboard"
    shortcutsGui.SetFont("s10")
    shortcutsGui.OnEvent("Escape", CloseShortcutsGui)

    ; Add shortcuts text
    shortcutsGui.Add("Text", "w450",
        "CapsLock+S: Show Settings Popup`n" .
        "CapsLock+B: Paste the item before the latest`n" .
        "CapsLock+V: Paste latest item from clipboard history`n" .
        "CapsLock+F: Paste latest item with format`n" .
        "CapsLock+A: Paste all clipboard items`n" .
        "CapsLock+D: Paste all items with format`n" .
        "CapsLock+X: Clear clipboard history`n" .
        "CapsLock+C: Show Clipboard History`n" .
        "CapsLock+R: Toggle beforeLatest_Latest feature`n" .
        "   -Double click: Paste selected item`n" .
        "   -Enter: Paste selected items`n" .
        "   -Alt+Up/Down: Move selected item up/down in the list`n" .
        "MouseMode: Right Alt to Click/ Right Ctrl to Right Click`n" .
        "CapsLock+T: Translate page in Chrome")

    shortcutsGui.Add("Button", "Default w80", "OK").OnEvent("Click", CloseShortcutsGui)
    shortcutsGui.Show()

    ; Store a reference to the current GUI
    myGui := shortcutsGui  ; Create a local copy for the closure

    ; Set up timer with the GUI passed to the function
    SetTimer () => CheckOutsideClick(myGui), 100

    CloseShortcutsGui(*) {
        SetTimer () => CheckOutsideClick(myGui), 0
        if IsObject(shortcutsGui) {
            try shortcutsGui.Destroy()
            shortcutsGui := 0
        }
    }
}
