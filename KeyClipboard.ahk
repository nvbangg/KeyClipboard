; KeyClipboard - Keyboard + clipboard manager
#Requires AutoHotkey v2.0
#SingleInstance Force
#Include "modules\Common.ahk"
#Include "modules\Clip.ahk"
#Include "modules\Key.ahk"

; Initialize settings
InitSettings()

; Mouse click
#HotIf mouseClickEnabled
RAlt:: Click()
RCtrl:: Click("Right")
#HotIf

; Translate page in Chrome hotkey
#HotIf WinActive("ahk_exe chrome.exe")
CapsLock & t:: TranslatePageInChrome()
#HotIf

; Hotkeys
CapsLock & s:: ShowSettingsPopup()
CapsLock & v:: ShowClipboardHistory()
CapsLock & z:: PastePreviousClipboard()
CapsLock & f:: PasteWithCurrentFormat()

; UI
A_TrayMenu.Add("Settings (Caps+S)", ShowSettingsPopup)
A_TrayMenu.Add("Shortcuts", ShowKeyboardShortcuts)
A_TrayMenu.Add("About", ShowAbout)
A_IconTip := "KeyClipboard - Right click to see more"

ShowAbout(*) {
    result := MsgBox("KeyClipboard`n" .
        "Version: 1.2.1`n" .
        "Date: 07/03/2025`n" .
        "`nSource: github.com/nvbangg/KeyClipboard`n" .
        "Click Yes to open",
        "About KeyClipboard", "YesNo")
    if (result = "Yes")
        Run("https://github.com/nvbangg/KeyClipboard")
}
ShowKeyboardShortcuts(*) {
    MsgBox("CapsLock+S: Show Settings Popup`n" .
        "CapsLock+Z: Paste previous clipboard`n" .
        "CapsLock+V: Show Clipboard History`n" .
        "CapsLock+F: Format when pasting`n" .
        "CapsLock+T: Translate page in Chrome`n",
        "Shortcuts - KeyClipboard", "Ok")
}
