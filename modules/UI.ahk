; UI - User Interface

mainMenu := Menu()
mainMenu.Add("Settings", ShowSettingsPopup)
mainMenu.Add("Shortcuts", ShowTips)
mainMenu.Add("About", ShowAbout)

A_TrayMenu.Add("Settings", ShowSettingsPopup)
A_TrayMenu.Add("Shortcuts", ShowTips)
A_TrayMenu.Add("About", ShowAbout)

A_IconTip := "QuickKit - Quick utility toolkit"

OnTrayIconClick(wParam, lParam, *) {
    ; nhấn chuột trái
    if (lParam = 0x0201) {
        CoordMode("Mouse", "Screen")
        MouseGetPos(&mX, &mY)
        mainMenu.Show(mX, mY)
        return 0 
    }
}

OnMessage(0x0404, OnTrayIconClick)  ; 0x0404 là WM_USER + 0x04 (thông báo tray icon)

; Shortcut to show settings popup
CapsLock & s::ShowSettingsPopup()

ShowSettingsPopup(*) {
    global mouseClickEnabled, alwaysNumLockEnabled, settingsFilePath
    
    settingsGui := Gui(, "QuickKit - Settings")
    settingsGui.SetFont("s10")
    
    settingsGui.Add("Text", "xm w400", "Options:")
    settingsGui.Add("CheckBox", "xm y+10 vMouseClick Checked" . mouseClickEnabled, "Enable mouse clicks")
    settingsGui.Add("Text", "x+10 yp w200", "(RAlt: left click, RCtrl: right click)")
    settingsGui.Add("CheckBox", "xm y+10 vNumLock Checked" . alwaysNumLockEnabled, "Always enable Numlock")
    
    settingsGui.Add("Button", "xm y+20 w100 Default", "Save").OnEvent("Click", SaveSettings)
    
    settingsGui.Show("w400 h150")
    
    SaveSettings(*) {
        savedValues := settingsGui.Submit()
        
        if (mouseClickEnabled != savedValues.MouseClick) {
            mouseClickEnabled := savedValues.MouseClick
            IniWrite(mouseClickEnabled ? "1" : "0", settingsFilePath, "MouseAndKey", "mouseClickEnabled")
        }
        
        if (alwaysNumLockEnabled != savedValues.NumLock) {
            alwaysNumLockEnabled := savedValues.NumLock
            IniWrite(alwaysNumLockEnabled ? "1" : "0", settingsFilePath, "MouseAndKey", "alwaysNumLockEnabled")
            UpdateNumLockState()
        }
    }
}

ShowAbout(*) {
    result := MsgBox("QuickKit`n`nVersion: 1.0`nSource: github.com/nvbangg/QuickKit`nVisit repository?", "About QuickKit", "YesNo")
    if (result = "Yes")
        Run("https://github.com/nvbangg/QuickKit")
}

ShowTips(*) {
    tipsText := "CapsLock+V: Paste previous clipboard`n"
    tipsText .= "CapsLock+F: Format when pasting`n"
    tipsText .= "CapsLock+T: Translate page (Chrome)`n"
    tipsText .= "CapsLock+S: Settings`n"
    
    MsgBox(tipsText, "Shortcuts - QuickKit", "Ok")
}
