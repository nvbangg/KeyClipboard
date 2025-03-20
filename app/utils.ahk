; === UTILS MODULE ===

ensureFilesExist() {
    dataDir := A_ScriptDir . "\data"
    if !DirExist(dataDir) {
        DirCreate(dataDir)
    }
    if !FileExist(settingsFilePath) {
        FileAppend("", settingsFilePath)
    }
}

; Loads settings from INI file into global variables
initSettings() {
    global mouseEnabled, numLockEnabled
    global removeAccentsEnabled, normSpaceEnabled, removeSpecialEnabled
    global lineOption, caseOption, separatorOption
    ensureFilesExist()

    mouseEnabled := IniRead(settingsFilePath, "Settings", "mouseEnabled", "0") = "1"
    numLockEnabled := IniRead(settingsFilePath, "Settings", "numLockEnabled", "1") = "1"

    removeAccentsEnabled := IniRead(settingsFilePath, "Settings", "removeAccentsEnabled", "0") = "1"
    normSpaceEnabled := IniRead(settingsFilePath, "Settings", "normSpaceEnabled", "1") = "1"
    removeSpecialEnabled := IniRead(settingsFilePath, "Settings", "removeSpecialEnabled", "0") = "1"

    lineOption := Integer(IniRead(settingsFilePath, "Settings", "lineOption", "1"))
    caseOption := Integer(IniRead(settingsFilePath, "Settings", "caseOption", "0"))
    separatorOption := Integer(IniRead(settingsFilePath, "Settings", "separatorOption", "0"))

    updateNumLock()
}

initCapsLockMonitor() {
    SetCapsLockState "AlwaysOff"
    ; Use a timer to monitor for the first 5 seconds
    loop 10 {
        SetTimer(() => SetCapsLockState("AlwaysOff"), -500 * A_Index)
    }
}

; Saves settings to INI file and updates global variables
saveSettings(savedValues) {
    global mouseEnabled, numLockEnabled
    global removeAccentsEnabled, normSpaceEnabled, removeSpecialEnabled
    global lineOption, caseOption, separatorOption
    ensureFilesExist()

    mouseEnabled := !!savedValues.mouseEnabled
    numLockEnabled := !!savedValues.numLockEnabled

    removeAccentsEnabled := !!savedValues.removeAccentsEnabled
    normSpaceEnabled := !!savedValues.normSpaceEnabled
    removeSpecialEnabled := !!savedValues.removeSpecialEnabled

    lineOption := savedValues.lineOption - 1
    caseOption := savedValues.caseOption - 1
    separatorOption := savedValues.separatorOption - 1

    IniWrite(mouseEnabled ? "1" : "0", settingsFilePath, "Settings", "mouseEnabled")
    IniWrite(numLockEnabled ? "1" : "0", settingsFilePath, "Settings", "numLockEnabled")

    IniWrite(removeAccentsEnabled ? "1" : "0", settingsFilePath, "Settings", "noAccentsEnabled")
    IniWrite(normSpaceEnabled ? "1" : "0", settingsFilePath, "Settings", "normSpaceEnabled")
    IniWrite(removeSpecialEnabled ? "1" : "0", settingsFilePath, "Settings", "removeSpecialEnabled")

    IniWrite(lineOption, settingsFilePath, "Settings", "lineOption")
    IniWrite(caseOption, settingsFilePath, "Settings", "caseOption")
    IniWrite(separatorOption, settingsFilePath, "Settings", "separatorOption")

    updateNumLock()
}

; Checks for clicks outside a GUI and closes it
CheckGuiOutsideClick(guiObj, saveSettingsOnClose := false) {
    static destroyingMap := Map()
    static dropdownActiveMap := Map()
    guiHwnd := 0
    try guiHwnd := guiObj.HasProp("Hwnd") ? guiObj.Hwnd : 0
    catch {
        SetTimer(() => CheckGuiOutsideClick(guiObj, saveSettingsOnClose), 0)
        return
    }

    ; Exit if invalid handle or already destroying
    if (!guiHwnd || !WinExist("ahk_id " . guiHwnd)) {
        SetTimer(() => CheckGuiOutsideClick(guiObj, saveSettingsOnClose), 0)
        return
    }

    ; Initialize tracking if needed
    if (!destroyingMap.Has(guiHwnd))
        destroyingMap[guiHwnd] := false
    if (!dropdownActiveMap.Has(guiHwnd))
        dropdownActiveMap[guiHwnd] := false
    if (destroyingMap[guiHwnd])
        return

    if (saveSettingsOnClose) {
        dropdownIsActive := WinExist("ahk_class ComboLBox") != 0
        if (dropdownIsActive) {
            dropdownActiveMap[guiHwnd] := true
            return
        } else if (dropdownActiveMap[guiHwnd]) {
            dropdownActiveMap[guiHwnd] := false
            Sleep(200)
            return
        }
    }

    ; Check for mouse position and clicks
    MouseGetPos(, , &winUnderCursor)
    if (winUnderCursor != guiHwnd && GetKeyState("LButton", "P")) {
        destroyingMap[guiHwnd] := true
        SetTimer(() => CheckGuiOutsideClick(guiObj, saveSettingsOnClose), 0)

        try {
            if (saveSettingsOnClose && guiObj.HasMethod("Submit"))
                saveSettings(guiObj.Submit())
            guiObj.Destroy()
        }

        destroyingMap[guiHwnd] := false
    }
}

showNotification(message, timeout := 1200) {
    notify := Gui("+AlwaysOnTop -Caption +ToolWindow")
    notify.SetFont("s12 bold")
    notify.Add("Text", "w300 Center", message)
    notify.Show("NoActivate")
    SetTimer(() => notify.Destroy(), -timeout)
}
