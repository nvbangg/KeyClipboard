; UI - User Interface

A_TrayMenu.Add("Settings", ShowSettingsPopup)
A_TrayMenu.Add("Shortcuts", ShowKeyboardShortcuts)
A_TrayMenu.Add("About", ShowAbout)
A_IconTip := "KeyClipboard - Right click to see more"

; Settings shortcut
CapsLock & s:: ShowSettingsPopup()

; Display settings popup window
ShowSettingsPopup(*) {
    settingsGui := Gui(, "KeyClipboard - Settings")
    settingsGui.SetFont("s10")

    yPos := 10
    yPos := AddKeyboardSettings(settingsGui, yPos)
    yPos := AddClipboardSettings(settingsGui, yPos)

    settingsGui.Add("Button", "x20 y" . (yPos + 10) . " w100 Default", "Save").OnEvent("Click", SaveButtonClick)
    settingsGui.Add("Button", "x130 y" . (yPos + 10) . " w100", "Shortcuts").OnEvent("Click", (*) =>
        ShowKeyboardShortcuts())

    SaveButtonClick(*) {
        SaveAllSettings(settingsGui.Submit())
    }

    settingsGui.Show("w400 h" . (yPos + 50))
}

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
