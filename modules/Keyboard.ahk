; Mouse and Keyboard functions

; Update NumLock state based on settings
UpdateNumLockState() {
    SetNumLockState(alwaysNumLockEnabled ? "AlwaysOn" : "Default")
}

GetKeySettingsHeight() {
    return 80
}

; Add keyboard settings to GUI
AddKeyboardSettings(settingsGui, y) {
    global mouseClickEnabled, alwaysNumLockEnabled

    settingsGui.Add("GroupBox", "x10 y" . y . " w380 h" . GetKeySettingsHeight(), "Keyboard Settings")
    settingsGui.Add("CheckBox", "x20 y" . (y + 20) . " vMouseClick Checked" . mouseClickEnabled, "Enable mouse clicks")
    settingsGui.Add("Text", "x+10 yp w200", "(RAlt: left click, RCtrl: right click)")
    settingsGui.Add("CheckBox", "x20 y" . (y + 40) . " vNumLock Checked" . alwaysNumLockEnabled,
    "Always enable Numlock")

    return y + GetKeySettingsHeight() + 10
}

; Handle keyboard shortcuts when mouseClickEnabled is true
#HotIf mouseClickEnabled
RAlt:: Click()
RCtrl:: Click("Right")
#HotIf

; Translate page in Chrome
#HotIf WinActive("ahk_exe chrome.exe")
CapsLock & t:: {
    BlockInput("On")
    MouseClick("Right")
    Sleep(50)
    Send("t")
    Sleep(50)
    Send("{Enter}")
    Sleep(50)
    MouseClick("Left")
    BlockInput("Off")
}
#HotIf