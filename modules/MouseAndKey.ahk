; Mouse and Keyboard functions

; Update NumLock state based on settings
UpdateNumLockState() {
    SetNumLockState(alwaysNumLockEnabled ? "AlwaysOn" : "Default")
}

GetMouseKeySettingsHeight() {
    return 80
}

; Add mouse and keyboard settings to GUI
AddMouseKeyboardSettings(settingsGui, y) {
    global mouseClickEnabled, alwaysNumLockEnabled
    
    settingsGui.Add("GroupBox", "x10 y" . y . " w380 h" . GetMouseKeySettingsHeight(), "Mouse & Keyboard")
    settingsGui.Add("CheckBox", "x20 y" . (y+20) . " vMouseClick Checked" . mouseClickEnabled, "Enable mouse clicks")
    settingsGui.Add("Text", "x+10 yp w200", "(RAlt: left click, RCtrl: right click)")
    settingsGui.Add("CheckBox", "x20 y" . (y+40) . " vNumLock Checked" . alwaysNumLockEnabled, "Always enable Numlock")
    
    return y + GetMouseKeySettingsHeight() + 10
}

; Handle keyboard shortcuts when mouseClickEnabled is true
#HotIf mouseClickEnabled
RAlt::Click()
RCtrl::Click("Right") 
#HotIf


