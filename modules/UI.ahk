; UI - User Interface

A_TrayMenu.Add("Settings", ShowSettingsPopup)
A_TrayMenu.Add("Shortcuts", ShowTips)
A_TrayMenu.Add("About", ShowAbout)
A_IconTip := "QuickKit - Right click to see more"

; Settings shortcut
CapsLock & s::ShowSettingsPopup()

; Display settings popup window
ShowSettingsPopup(*) {
    settingsGui := Gui(, "QuickKit - Settings")
    settingsGui.SetFont("s10")
    
    yPos := 10
    yPos := AddMouseKeyboardSettings(settingsGui, yPos)
    yPos := AddClipboardSettings(settingsGui, yPos)
    
    settingsGui.Add("Button", "x20 y" . (yPos+10) . " w100 Default", "Save").OnEvent("Click", SaveButtonClick)
    
    SaveButtonClick(*) {
        SaveAllSettings(settingsGui.Submit())
    }
    
    settingsGui.Show("w400 h" . (yPos + 50))
}

ShowAbout(*) {
    if (MsgBox("QuickKit`n`nVersion: 1.1`nDate: 06/03/2025`nSource: github.com/nvbangg/QuickKit`nVisit repository?", 
               "About QuickKit", "YesNo") = "Yes")
        Run("https://github.com/nvbangg/QuickKit")
}

ShowTips(*) {
    MsgBox("CapsLock+S: Settings`n" .
           "CapsLock+Z: Paste previous clipboard`n" .
           "CapsLock+V (same Win+V): Show clipboard history`n" .
           "CapsLock+F: Format when pasting`n" .
           "CapsLock+T: Translate page (Chrome)`n",
           "Shortcuts - QuickKit", "Ok")
}