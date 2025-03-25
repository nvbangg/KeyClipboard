; === APP_FUNCTIONS MODULE ===

initSettings() {
    global mouseEnabled, numLockEnabled
    global removeAccentsEnabled, normSpaceEnabled, removeSpecialEnabled
    global lineOption, caseOption, separatorOption

    existFile(settingsFilePath)

    mouseEnabled := readSetting("Settings", "mouseEnabled", "0") = "1"
    numLockEnabled := readSetting("Settings", "numLockEnabled", "1") = "1"

    removeAccentsEnabled := readSetting("Settings", "removeAccentsEnabled", "0") = "1"
    normSpaceEnabled := readSetting("Settings", "normSpaceEnabled", "1") = "1"
    removeSpecialEnabled := readSetting("Settings", "removeSpecialEnabled", "0") = "1"

    lineOption := Integer(readSetting("Settings", "lineOption", "1"))
    caseOption := Integer(readSetting("Settings", "caseOption", "0"))
    separatorOption := Integer(readSetting("Settings", "separatorOption", "0"))

    updateNumLock()
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

    existFile(settingsFilePath)

    mouseEnabled := !!savedValues.mouseEnabled
    numLockEnabled := !!savedValues.numLockEnabled

    removeAccentsEnabled := !!savedValues.removeAccentsEnabled
    normSpaceEnabled := !!savedValues.normSpaceEnabled
    removeSpecialEnabled := !!savedValues.removeSpecialEnabled

    lineOption := savedValues.lineOption - 1
    caseOption := savedValues.caseOption - 1
    separatorOption := savedValues.separatorOption - 1

    writeSetting("Settings", "mouseEnabled", mouseEnabled ? "1" : "0")
    writeSetting("Settings", "numLockEnabled", numLockEnabled ? "1" : "0")
    writeSetting("Settings", "removeAccentsEnabled", removeAccentsEnabled ? "1" : "0")
    writeSetting("Settings", "normSpaceEnabled", normSpaceEnabled ? "1" : "0")
    writeSetting("Settings", "removeSpecialEnabled", removeSpecialEnabled ? "1" : "0")
    writeSetting("Settings", "lineOption", lineOption)
    writeSetting("Settings", "caseOption", caseOption)
    writeSetting("Settings", "separatorOption", separatorOption)

    updateNumLock()
}
