; UI - User Interface - Quản lý menu và giao diện chung

A_TrayMenu.Add("Settings", ShowSettingsPopup)
A_TrayMenu.Add("Shortcuts", ShowTips)
A_TrayMenu.Add("About", ShowAbout)
A_IconTip := "QuickKit - Quick utility toolkit"

; Phím tắt mở cài đặt
CapsLock & s::ShowSettingsPopup()

ShowSettingsPopup(*) {
    ; Tạo GUI cài đặt
    settingsGui := Gui(, "QuickKit - Settings")
    settingsGui.SetFont("s10")
    
    ; Thêm các phần cài đặt từ các module khác
    yPos := 10
    yPos := AddMouseKeyboardSettings(settingsGui, yPos)  ; Hàm này được định nghĩa trong MouseAndKey.ahk
    yPos := AddClipboardSettings(settingsGui, yPos)
    
    ; Thêm nút lưu
    settingsGui.Add("Button", "x20 y" . (yPos+10) . " w100 Default", "Save").OnEvent("Click", SaveButtonClick)
    
    ; Hàm nội bộ để xử lý sự kiện click nút Save
    SaveButtonClick(*) {
        SaveAllSettings(settingsGui.Submit())
    }
    
    settingsGui.Show("w400 h" . (yPos + 50))
}

ShowAbout(*) {
    if (MsgBox("QuickKit`n`nVersion: 1.1`nSource: github.com/nvbangg/QuickKit`nVisit repository?", 
               "About QuickKit", "YesNo") = "Yes")
        Run("https://github.com/nvbangg/QuickKit")
}

ShowTips(*) {
    MsgBox("CapsLock+V: Paste previous clipboard`n" .
           "CapsLock+C: Show clipboard history`n" .
           "CapsLock+F: Format when pasting`n" .
           "CapsLock+F (double-press): Format settings`n" .
           "CapsLock+T: Translate page (Chrome)`n" .
           "CapsLock+S: Settings", 
           "Shortcuts - QuickKit", "Ok")
}