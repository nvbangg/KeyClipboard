; === KEY MODULE ===
; Functions for keyboard shortcuts and mouse emulation

addKeySettings(settingsGui, y) {
    global mouseEnabled, numLockEnabled

    settingsGui.Add("GroupBox", "x10 y" . y . " w350 h95", "Keyboard Settings")
    settingsGui.Add("CheckBox", "x20 y" . (y + 20) . " vmouseEnabled Checked" . mouseEnabled, "Enable Mouse Clicks")
    settingsGui.Add("Text", "x40 y" . (y + 40) . " w350", "(RAlt: left click, RCtrl: right click)")
    settingsGui.Add("CheckBox", "x20 y" . (y + 65) . " vnumLockEnabled Checked" . numLockEnabled,
    "Always Enable Numlock")

    return y + 110
}

; Chrome-specific translation shortcut
translateInChrome() {
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

; Toggle NumLock based on settings
updateNumLock() {
    SetNumLockState(numLockEnabled ? "AlwaysOn" : "Default")
}

; Toggle always-on-top for active window and show status notification
toggleAlwaysOnTop() {
    WinSetAlwaysOnTop(-1, "A")
    isAlwaysOnTop := WinGetExStyle("A") & 0x8
    showNotification("Always On Top: " . (isAlwaysOnTop ? "Enabled" : "Disabled"))
}
