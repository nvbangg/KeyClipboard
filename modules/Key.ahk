;Keyboard functions

; Add keyboard settings to GUI
addKeySettings(settingsGui, y) {
    global mouseEnabled, numLockEnabled

    settingsGui.Add("GroupBox", "x10 y" . y . " w380 h" . 80, "Keyboard Settings")
    settingsGui.Add("CheckBox", "x20 y" . (y + 20) . " vMouseClick Checked" . mouseEnabled, "Enable Mouse Clicks")
    settingsGui.Add("Text", "x+10 yp w200", "(RAlt: left click, RCtrl: right click)")
    settingsGui.Add("CheckBox", "x20 y" . (y + 40) . " vNumLock Checked" . numLockEnabled, "Always Enable Numlock")

    return y + 80 + 10
}

; Translate page in Chrome
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

; Update NumLock state based on settings
updateNumLock() {
    SetNumLockState(numLockEnabled ? "AlwaysOn" : "Default")
}

; Toggle always-on-top status for active window
toggleAlwaysOnTop() {
    WinSetAlwaysOnTop(-1, "A")  ; Use -1 instead of "Toggle" for toggling
    isAlwaysOnTop := WinGetExStyle("A") & 0x8  ; Check if the window is now always on top
    showNotification("Always On Top: " . (isAlwaysOnTop ? "Enabled" : "Disabled"))
}
