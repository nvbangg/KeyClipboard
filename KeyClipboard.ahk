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
CapsLock & s:: showSettings()
CapsLock & v:: showClipboard()
CapsLock & z:: pastePrevious()
CapsLock & f:: formatWhenPaste()
CapsLock & a:: pasteSelected()
CapsLock & c:: clearClipboard()

; UI
A_TrayMenu.Add("Settings (Caps+S)", showSettings)
A_TrayMenu.Add("Shortcuts", showShortcuts)
A_TrayMenu.Add("About", showAbout)
A_IconTip := "KeyClipboard - Right click to see more"

showAbout(*) {
    result := MsgBox("KeyClipboard`n" .
        "Version: 1.4.2`n" .
        "Date: 11/03/2025`n" .
        "`nSource: github.com/nvbangg/KeyClipboard`n" .
        "Click Yes to open",
        "About KeyClipboard", "YesNo")
    if (result = "Yes")
        Run("https://github.com/nvbangg/KeyClipboard")
    else
        Run("https://www.youtube.com/watch?v=dQw4w9WgXcQ")
}
showShortcuts(*) {
    MsgBox("CapsLock+S: Show Settings Popup`n" .
        "CapsLock+Z: Paste previous clipboard`n" .
        "CapsLock+V: Show Clipboard History`n" .
        "-Double click: Paste selected item`n" .
        "-Enter: Paste selected items`n" .
        "CapsLock+F: Format when pasting`n" .
        "CapsLock+A: Paste all clipboard items`n" .
        "CapsLock+C: Clear clipboard history`n" .
        "CapsLock+T: Translate page in Chrome`n",
        "Shortcuts - KeyClipboard", "Ok")
}
