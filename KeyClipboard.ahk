; KeyClipboard - Keyboard + clipboard mânager
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
A_TrayMenu.Add("Settings", ShowSettingsPopup)
A_TrayMenu.Add("Shortcuts", ShowKeyboardShortcuts)
A_TrayMenu.Add("About", ShowAbout)
A_IconTip := "KeyClipboard - Right click to see more"
ShowAbout(*) {
    if (MsgBox(
        "KeyClipboard`n`nVersion: 1.2`nDate: 06/03/2025`nSource: github.com/nvbangg/KeyClipboard`nVisit repository?",
        "About KeyClipboard", "YesNo") = "Yes")
        Run("https://github.com/nvbangg/KeyClipboard")
}
ShowKeyboardShortcuts(*) {
    MsgBox("CapsLock+S: Settings`n" .
        "CapsLock+Z: Paste previous clipboard`n" .
        "CapsLock+V: Show clipboard history`n" .
        "CapsLock+F: Format when pasting`n" .
        "CapsLock+T: Translate page (Chrome)`n",
        "Shortcuts - KeyClipboard", "Ok")
}
