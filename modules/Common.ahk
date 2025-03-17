global settingsFilePath := A_ScriptDir . "\data\settings.ini"

; Ensures required directories and files exist
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
    global mouseEnabled, numLockEnabled, removeSpecialEnabled
    global noAccentsEnabled, normSpaceEnabled, lineBreakOption, formatCaseOption, formatSeparator
    ensureFilesExist()

    mouseEnabled := IniRead(settingsFilePath, "Settings", "mouseEnabled", "0") = "1"
    numLockEnabled := IniRead(settingsFilePath, "Settings", "numLockEnabled", "1") = "1"
    removeSpecialEnabled := IniRead(settingsFilePath, "Settings", "removeSpecialEnabled", "1") = "1"

    noAccentsEnabled := IniRead(settingsFilePath, "Settings", "noAccentsEnabled", "0") = "1"
    normSpaceEnabled := IniRead(settingsFilePath, "Settings", "normSpaceEnabled", "0") = "1"
    lineBreakOption := Integer(IniRead(settingsFilePath, "Settings", "lineBreakOption", "1"))
    formatCaseOption := Integer(IniRead(settingsFilePath, "Settings", "formatCaseOption", "0"))
    formatSeparator := Integer(IniRead(settingsFilePath, "Settings", "formatSeparator", "0"))

    updateNumLock()
}

; Saves settings to INI file and updates global variables
saveSettings(savedValues) {
    global mouseEnabled, numLockEnabled, noAccentsEnabled, normSpaceEnabled
    global lineBreakOption, formatCaseOption, formatSeparator, removeSpecialEnabled
    ensureFilesExist()

    mouseEnabled := !!savedValues.mouseEnabled
    numLockEnabled := !!savedValues.numLockEnabled
    removeSpecialEnabled := !!savedValues.removeSpecialEnabled

    noAccentsEnabled := !!savedValues.noAccentsEnabled
    normSpaceEnabled := !!savedValues.normSpaceEnabled
    lineBreakOption := savedValues.LineBreakOption - 1
    formatCaseOption := savedValues.CaseOption - 1
    formatSeparator := savedValues.SeparatorOption - 1

    IniWrite(mouseEnabled ? "1" : "0", settingsFilePath, "Settings", "mouseEnabled")
    IniWrite(numLockEnabled ? "1" : "0", settingsFilePath, "Settings", "numLockEnabled")
    IniWrite(removeSpecialEnabled ? "1" : "0", settingsFilePath, "Settings", "removeSpecialEnabled")

    IniWrite(noAccentsEnabled ? "1" : "0", settingsFilePath, "Settings", "noAccentsEnabled")
    IniWrite(normSpaceEnabled ? "1" : "0", settingsFilePath, "Settings", "normSpaceEnabled")
    IniWrite(lineBreakOption, settingsFilePath, "Settings", "lineBreakOption")
    IniWrite(formatCaseOption, settingsFilePath, "Settings", "formatCaseOption")
    IniWrite(formatSeparator, settingsFilePath, "Settings", "formatSeparator")

    updateNumLock()
}

; Creates and displays the settings GUI
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

        ; Initialize position tracking
        yPos := 10

        ; Add settings sections
        yPos := addKeySettings(settingsGui, yPos)
        yPos := addClipSettings(settingsGui, yPos)

        ; Add buttons
        settingsGui.Add("Button", "x20 y" . (yPos + 10) . " w100 Default", "Save").OnEvent("Click", CloseSettingsGui)
        settingsGui.Add("Button", "x130 y" . (yPos + 10) . " w100", "Shortcuts").OnEvent("Click", (*) => showShortcuts())
        settingsGui.Add("Button", "x240 y" . (yPos + 10) . " w100", "About").OnEvent("Click", (*) => showAbout())

        ; Show the GUI
        settingsGui.Show("w375 h" . (yPos + 50))
        settingsGui.OnEvent("Escape", CloseSettingsGui)

        ; Start checking for outside clicks
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

; Shows a temporary notification popup
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
