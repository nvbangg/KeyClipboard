; === KEY_FUNCTIONS MODULE ===

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

updateNumLock() {
    SetNumLockState(numLockEnabled ? "AlwaysOn" : "Default")
}

alwaysOnTop() {
    WinSetAlwaysOnTop(-1, "A")
    isAlwaysOnTop := WinGetExStyle("A") & 0x8
    showNotification("Always On Top: " . (isAlwaysOnTop ? "Enabled" : "Disabled"))
}
