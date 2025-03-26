; === APP_FUNCTIONS MODULE ===

initSettings() {
    global mouseEnabled, numLockEnabled
    global removeAccentsEnabled, normSpaceEnabled, removeSpecialEnabled
    global lineOption, caseOption, separatorOption
    global replaceWinClipboard, startWithWindows

    existFile(settingsFilePath)

    mouseEnabled := readSetting("Settings", "mouseEnabled", "0") = "1"
    numLockEnabled := readSetting("Settings", "numLockEnabled", "1") = "1"

    removeAccentsEnabled := readSetting("Settings", "removeAccentsEnabled", "0") = "1"
    normSpaceEnabled := readSetting("Settings", "normSpaceEnabled", "1") = "1"
    removeSpecialEnabled := readSetting("Settings", "removeSpecialEnabled", "0") = "1"

    lineOption := Integer(readSetting("Settings", "lineOption", "1"))
    caseOption := Integer(readSetting("Settings", "caseOption", "0"))
    separatorOption := Integer(readSetting("Settings", "separatorOption", "0"))

    replaceWinClipboard := readSetting("AppSettings", "replaceWinClipboard", "1") = "1"
    startWithWindows := readSetting("AppSettings", "startWithWindows", "1") = "1"

    updateNumLock()
    updateWinClipboardHotkey()
    updateStartupSetting()
}

initCapsLockMonitor() {
    SetCapsLockState "AlwaysOff"
    ; Ensure CapsLock is off during startup
    loop 10 {
        SetTimer(() => SetCapsLockState("AlwaysOff"), -500 * A_Index)
    }
}

saveSettings(savedValues) {
    global mouseEnabled, numLockEnabled
    global removeAccentsEnabled, normSpaceEnabled, removeSpecialEnabled
    global lineOption, caseOption, separatorOption
    global replaceWinClipboard, startWithWindows

    existFile(settingsFilePath)

    mouseEnabled := !!savedValues.mouseEnabled
    numLockEnabled := !!savedValues.numLockEnabled

    removeAccentsEnabled := !!savedValues.removeAccentsEnabled
    normSpaceEnabled := !!savedValues.normSpaceEnabled
    removeSpecialEnabled := !!savedValues.removeSpecialEnabled

    lineOption := savedValues.lineOption - 1
    caseOption := savedValues.caseOption - 1
    separatorOption := savedValues.separatorOption - 1

    replaceWinClipboard := !!savedValues.replaceWinClipboard
    startWithWindows := !!savedValues.startWithWindows

    writeSetting("Settings", "mouseEnabled", mouseEnabled ? "1" : "0")
    writeSetting("Settings", "numLockEnabled", numLockEnabled ? "1" : "0")
    writeSetting("Settings", "removeAccentsEnabled", removeAccentsEnabled ? "1" : "0")
    writeSetting("Settings", "normSpaceEnabled", normSpaceEnabled ? "1" : "0")
    writeSetting("Settings", "removeSpecialEnabled", removeSpecialEnabled ? "1" : "0")
    writeSetting("Settings", "lineOption", lineOption)
    writeSetting("Settings", "caseOption", caseOption)
    writeSetting("Settings", "separatorOption", separatorOption)

    writeSetting("AppSettings", "replaceWinClipboard", replaceWinClipboard ? "1" : "0")
    writeSetting("AppSettings", "startWithWindows", startWithWindows ? "1" : "0")

    updateNumLock()
    updateWinClipboardHotkey()
    updateStartupSetting()
}

updateWinClipboardHotkey() {
    global replaceWinClipboard

    try {
        Hotkey "#v", "Off"
    } catch {
        ; Ignore if hotkey wasn't previously registered
    }

    if (replaceWinClipboard) {
        try {
            Hotkey "#v", (*) => showClipboard()
            ; showNotification("Windows Clipboard replaced with KeyClipboard")
        } catch Error as e {
            showInfo("Hotkey Error", "Failed to register Win+V hotkey:`n" . e.Message)
        }
    }
}

addAppSettings(guiObj, yPos) {
    guiObj.Add("GroupBox", "x10 y" . yPos . " w350 h80", "App Settings")

    guiObj.Add("Checkbox", "x20 y" . (yPos + 20) . " w330 vReplaceWinClipboard",
    "Replace Windows Clipboard")
    .Value := replaceWinClipboard

    guiObj.Add("Checkbox", "x20 y" . (yPos + 45) . " w330 vStartWithWindows",
    "Start with Windows")
    .Value := startWithWindows

    return yPos + 90
}

updateStartupSetting() {
    global startWithWindows

    try {
        regKey := "HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Run"
        appName := "KeyClipboard"
        scriptPath := A_ScriptFullPath

        if (startWithWindows) {
            RegWrite(scriptPath, "REG_SZ", regKey, appName)
        } else {
            try {
                RegDelete(regKey, appName)
            } catch {
                ; Ignore if key doesn't exist
            }
        }
    } catch Error as e {
        showInfo("Startup Settings Error", "Failed to update startup settings:`n" . e.Message)
    }
}
