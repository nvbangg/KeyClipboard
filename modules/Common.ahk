; === COMMON MODULE ===

global settingsFilePath := A_ScriptDir . "\data\settings.ini"

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
initSettings()
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

showSettings(*) {
    static settingsGui := 0
    static isCreating := false
    if (isCreating)
        return
    isCreating := true

    ; Clean up any existing GUI
    try {
        if IsObject(settingsGui) && settingsGui.HasProp("Hwnd") {
            if WinExist("ahk_id " . settingsGui.Hwnd) {
                SetTimer(CheckSettingsOutsideClick, 0)
                settingsGui.Destroy()
            }
            settingsGui := 0
        }
    } catch {
        settingsGui := 0
    }

    ; Create new GUI
    try {
        settingsGui := Gui("+AlwaysOnTop +ToolWindow", "KeyClipboard - Settings")
        settingsGui.SetFont("s10")
        yPos := 10
        yPos := addKeySettings(settingsGui, yPos)
        yPos := addClipSettings(settingsGui, yPos)

        settingsGui.Add("Button", "x20 y" . (yPos + 10) . " w100 Default", "Save").OnEvent("Click", CloseSettingsGui)
        settingsGui.Add("Button", "x130 y" . (yPos + 10) . " w100", "Shortcuts").OnEvent("Click", (*) => showShortcuts())
        settingsGui.Add("Button", "x240 y" . (yPos + 10) . " w100", "About").OnEvent("Click", (*) => showAbout())
        settingsGui.Show("w375 h" . (yPos + 50))
        settingsGui.OnEvent("Escape", CloseSettingsGui)

        SetTimer(CheckSettingsOutsideClick, 100)
    } catch as e {
        MsgBox("Error creating settings: " . e.Message)
        settingsGui := 0
    }
    isCreating := false

    CloseSettingsGui(*) {
        SetTimer(CheckSettingsOutsideClick, 0)
        try {
            saveSettings(settingsGui.Submit())
            if IsObject(settingsGui) {
                settingsGui.Destroy()
                settingsGui := 0
            }
        } catch as e {
            MsgBox("Error closing settings: " . e.Message)
            settingsGui := 0
        }
    }

    CheckSettingsOutsideClick() {
        static isDestroying := false
        static isDropdownActive := false
        if isDestroying || !IsObject(settingsGui)
            return

        try {
            if !settingsGui.HasProp("Hwnd") || !WinExist("ahk_id " . settingsGui.Hwnd) {
                SetTimer(CheckSettingsOutsideClick, 0)
                settingsGui := 0
                return
            }

            dropdownIsActive := WinExist("ahk_class ComboLBox") != 0
            if (dropdownIsActive) {
                isDropdownActive := true
                return
            } else if (isDropdownActive) {
                isDropdownActive := false
                Sleep(200)
                return
            }

            mouseIsOutside := false
            MouseGetPos(, , &winUnderCursor)
            if winUnderCursor != settingsGui.Hwnd {
                mouseIsOutside := true
            }
            if mouseIsOutside && GetKeyState("LButton", "P") {
                isDestroying := true
                SetTimer(CheckSettingsOutsideClick, 0)
                try {
                    saveSettings(settingsGui.Submit())
                    settingsGui.Destroy()
                } catch {
                }
                settingsGui := 0
                isDestroying := false
            }
        } catch {
            SetTimer(CheckSettingsOutsideClick, 0)
            settingsGui := 0
        }
    }
}

showNotification(message, timeout := 1200) {
    notify := Gui("+AlwaysOnTop -Caption +ToolWindow")
    notify.SetFont("s12 bold")
    notify.Add("Text", "w300 Center", message)
    notify.Show("NoActivate")
    SetTimer(() => notify.Destroy(), -timeout)
}

; Checks for clicks outside a GUI and closes it if detected
CheckOutsideClick(shortcutsGui) {
    static isDestroying := false

    if isDestroying || !IsObject(shortcutsGui)
        return

    try {
        if !shortcutsGui.HasProp("Hwnd") || !WinExist("ahk_id " . shortcutsGui.Hwnd) {
            SetTimer(() => CheckOutsideClick(shortcutsGui), 0)
            return
        }

        mouseIsOutside := false
        MouseGetPos(, , &winUnderCursor)
        if winUnderCursor != shortcutsGui.Hwnd {
            mouseIsOutside := true
        }

        if mouseIsOutside && GetKeyState("LButton", "P") {
            isDestroying := true
            SetTimer(() => CheckOutsideClick(shortcutsGui), 0)
            try shortcutsGui.Destroy()
            isDestroying := false
        }
    } catch {
        SetTimer(() => CheckOutsideClick(shortcutsGui), 0)
    }
}
