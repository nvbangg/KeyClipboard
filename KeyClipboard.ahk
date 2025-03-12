; KeyClipboard - Keyboard + clipboard manager
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

; UI
A_TrayMenu.Add("Settings (Caps+S)", showSettings)
A_TrayMenu.Add("Shortcuts", showShortcuts)
A_TrayMenu.Add("About", showAbout)
A_IconTip := "KeyClipboard - Right click to see more"

showAbout(*) {
    result := MsgBox("KeyClipboard`n" .
        "Version: 1.5`n" .
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
    MsgBox("CapsLock+S: Show Settings Popup`n" .
        "CapsLock+B: Paste the item before the latest`n" .
        "CapsLock+V: Paste latest item from clipboard history`n" .
        "CapsLock+F: Paste latest item with format`n" .
        "CapsLock+A: Paste all clipboard items`n" .
        "CapsLock+D: Paste all items with format`n" .
        "CapsLock+X: Clear clipboard history`n" .
        "CapsLock+C: Show Clipboard History`n" .
        "   -Double click: Paste selected item`n" .
        "   -Enter: Paste selected items`n" .
        "   -Alt+Up/Down: Move selected item up/down in the list`n" .
        "MouseMode: Right Alt to Click/ Right Ctrl to Right Click`n" .
        "CapsLock+T: Translate page in Chrome`n",
        "Shortcuts - KeyClipboard", "Ok")
}
