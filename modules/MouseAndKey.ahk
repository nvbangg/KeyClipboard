; Mouse and Keyboard - Xử lý tính năng chuột và bàn phím

; Cập nhật trạng thái NumLock
UpdateNumLockState() {
    SetNumLockState(alwaysNumLockEnabled ? "AlwaysOn" : "Default")
}

; Trả về chiều cao cần thiết cho phần cài đặt chuột và bàn phím
GetMouseKeySettingsHeight() {
    return 80  ; Chiều cao GroupBox
}

; Thêm phần cài đặt chuột và bàn phím vào GUI
AddMouseKeyboardSettings(settingsGui, y) {
    global mouseClickEnabled, alwaysNumLockEnabled
    
    ; Thêm GroupBox và các phần tử
    settingsGui.Add("GroupBox", "x10 y" . y . " w380 h" . GetMouseKeySettingsHeight(), "Mouse & Keyboard")
    settingsGui.Add("CheckBox", "x20 y" . (y+20) . " vMouseClick Checked" . mouseClickEnabled, "Enable mouse clicks")
    settingsGui.Add("Text", "x+10 yp w200", "(RAlt: left click, RCtrl: right click)")
    settingsGui.Add("CheckBox", "x20 y" . (y+40) . " vNumLock Checked" . alwaysNumLockEnabled, "Always enable Numlock")
    
    ; Trả về vị trí y mới (y + chiều cao + khoảng cách)
    return y + GetMouseKeySettingsHeight() + 10
}

; Xử lý các phím tắt khi mouseClickEnabled = true
#HotIf mouseClickEnabled
RAlt::Click()
RCtrl::Click("Right") 
#HotIf


