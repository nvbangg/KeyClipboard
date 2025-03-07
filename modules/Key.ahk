;Keyboard functions

; Add keyboard settings to GUI
AddKeyboardSettings(settingsGui, y) {
    global mouseClickEnabled, alwaysNumLockEnabled

    settingsGui.Add("GroupBox", "x10 y" . y . " w380 h" . 80, "Keyboard Settings")
    settingsGui.Add("CheckBox", "x20 y" . (y + 20) . " vMouseClick Checked" . mouseClickEnabled, "Enable mouse clicks")
    settingsGui.Add("Text", "x+10 yp w200", "(RAlt: left click, RCtrl: right click)")
    settingsGui.Add("CheckBox", "x20 y" . (y + 40) . " vNumLock Checked" . alwaysNumLockEnabled,
    "Always enable Numlock")

    return y + 80 + 10
}

; Translate page in Chrome
TranslatePageInChrome() {
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

; Update NumLock state based on settings
UpdateNumLockState() {
    SetNumLockState(alwaysNumLockEnabled ? "AlwaysOn" : "Default")
}
