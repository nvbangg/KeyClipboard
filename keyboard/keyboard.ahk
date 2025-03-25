; === KEY MODULE ===

#Include key_functions.ahk

addKeySettings(settingsGui, y) {
    global mouseEnabled, numLockEnabled

    settingsGui.Add("GroupBox", "x10 y" . y . " w350 h95", "Keyboard Settings")
    settingsGui.Add("CheckBox", "x20 y" . (y + 20) . " vmouseEnabled Checked" . mouseEnabled, "Enable Mouse Clicks")
    settingsGui.Add("Text", "x40 y" . (y + 40) . " w350", "(RAlt: left click, RCtrl: right click)")
    settingsGui.Add("CheckBox", "x20 y" . (y + 65) . " vnumLockEnabled Checked" . numLockEnabled,
    "Always Enable Numlock")

    return y + 110
}
