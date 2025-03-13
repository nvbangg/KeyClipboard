; Common functions
global settingsFilePath := A_ScriptDir . "\data\settings.ini"

; Ensure the data file exists
ensureFilesExist() {
    dataDir := A_ScriptDir . "\data"
    if !DirExist(dataDir) {
        DirCreate(dataDir)
    }
    if !FileExist(settingsFilePath) {
        FileAppend("", settingsFilePath)
    }
}

; Initialize settings
initSettings() {
    global mouseEnabled, numLockEnabled, formatCaseOption, formatSeparator, beforeLatest_LatestEnabled
    global removeDiacriticsEnabled, lineBreakOption, removeExcessiveSpacesEnabled
    ensureFilesExist()

    mouseEnabled := IniRead(settingsFilePath, "Settings", "mouseEnabled", "0") = "1"
    numLockEnabled := IniRead(settingsFilePath, "Settings", "numLockEnabled", "1") = "1"
    beforeLatest_LatestEnabled := IniRead(settingsFilePath, "Settings", "beforeLatest_LatestEnabled", "1") = "1"
    removeDiacriticsEnabled := IniRead(settingsFilePath, "Settings", "removeDiacriticsEnabled", "1") = "1"
    removeExcessiveSpacesEnabled := IniRead(settingsFilePath, "Settings", "removeExcessiveSpacesEnabled", "0") = "1"
    lineBreakOption := Integer(IniRead(settingsFilePath, "Settings", "lineBreakOption", "1"))
    formatCaseOption := Integer(IniRead(settingsFilePath, "Settings", "formatCaseOption", "0"))
    formatSeparator := Integer(IniRead(settingsFilePath, "Settings", "formatSeparator", "0"))

    updateNumLock()
}

; Toggle beforeLatest_Latest feature
toggleBeforeLatestLatest() {
    global beforeLatest_LatestEnabled, settingsFilePath
    beforeLatest_LatestEnabled := !beforeLatest_LatestEnabled
    IniWrite(beforeLatest_LatestEnabled ? "1" : "0", settingsFilePath, "Settings", "beforeLatest_LatestEnabled")
    showNotification("beforeLatest_Latest: " . (beforeLatest_LatestEnabled ? "Enabled" : "Disabled"))
}

; Save all settings to INI file
saveSettings(savedValues) {
    global mouseEnabled, numLockEnabled, formatCaseOption, formatSeparator, beforeLatest_LatestEnabled
    global removeDiacriticsEnabled, lineBreakOption, removeExcessiveSpacesEnabled
    ensureFilesExist()

    beforeLatest_LatestEnabled := !!savedValues.beforeLatest_LatestEnabled
    removeDiacriticsEnabled := !!savedValues.removeDiacriticsEnabled
    removeExcessiveSpacesEnabled := !!savedValues.removeExcessiveSpacesEnabled
    mouseEnabled := !!savedValues.MouseClick
    numLockEnabled := !!savedValues.NumLock

    ; Line break options
    if (savedValues.HasProp("LineBreakNone") && savedValues.LineBreakNone)
        lineBreakOption := 0
    else if (savedValues.HasProp("LineBreakRemoveExcessive") && savedValues.LineBreakRemoveExcessive)
        lineBreakOption := 1
    else if (savedValues.HasProp("LineBreakRemoveAll") && savedValues.LineBreakRemoveAll)
        lineBreakOption := 2

    ; Text case format options
    if (savedValues.HasProp("CaseNone") && savedValues.CaseNone)
        formatCaseOption := 0
    else if (savedValues.HasProp("CaseUpper") && savedValues.CaseUpper)
        formatCaseOption := 1
    else if (savedValues.HasProp("CaseLower") && savedValues.CaseLower)
        formatCaseOption := 2
    else if (savedValues.HasProp("CaseTitleCase") && savedValues.CaseTitleCase)
        formatCaseOption := 3
    else if (savedValues.HasProp("CaseSentence") && savedValues.CaseSentence)
        formatCaseOption := 4

    ; Word separator options
    if (savedValues.HasProp("SeparatorNone") && savedValues.SeparatorNone)
        formatSeparator := 0
    else if (savedValues.HasProp("SeparatorUnderscore") && savedValues.SeparatorUnderscore)
        formatSeparator := 1
    else if (savedValues.HasProp("SeparatorHyphen") && savedValues.SeparatorHyphen)
        formatSeparator := 2
    else if (savedValues.HasProp("SeparatorNoSpace") && savedValues.SeparatorNoSpace)
        formatSeparator := 3

    IniWrite(mouseEnabled ? "1" : "0", settingsFilePath, "Settings", "mouseEnabled")
    IniWrite(numLockEnabled ? "1" : "0", settingsFilePath, "Settings", "numLockEnabled")
    IniWrite(beforeLatest_LatestEnabled ? "1" : "0", settingsFilePath, "Settings", "beforeLatest_LatestEnabled")
    IniWrite(removeDiacriticsEnabled ? "1" : "0", settingsFilePath, "Settings", "removeDiacriticsEnabled")
    IniWrite(removeExcessiveSpacesEnabled ? "1" : "0", settingsFilePath, "Settings", "removeExcessiveSpacesEnabled")
    IniWrite(lineBreakOption, settingsFilePath, "Settings", "lineBreakOption")
    IniWrite(formatCaseOption, settingsFilePath, "Settings", "formatCaseOption")
    IniWrite(formatSeparator, settingsFilePath, "Settings", "formatSeparator")

    updateNumLock()
}

; Display settings popup window
showSettings(*) {
    static settingsGui := 0

    try {
        if IsObject(settingsGui) && settingsGui.HasProp("Hwnd")
            if WinExist("ahk_id " . settingsGui.Hwnd)
                settingsGui.Destroy()
    } catch {
        ; If any error occurs, just create a new GUI
    }

    settingsGui := Gui("+AlwaysOnTop +ToolWindow", "KeyClipboard - Settings")
    settingsGui.SetFont("s10")
    yPos := 10
    yPos := addKeySettings(settingsGui, yPos)
    yPos := addClipSettings(settingsGui, yPos)

    settingsGui.Add("Button", "x20 y" . (yPos + 10) . " w100 Default", "Save").OnEvent("Click", CloseSettingsGui)
    settingsGui.Add("Button", "x130 y" . (yPos + 10) . " w100", "Shortcuts").OnEvent("Click", (*) => showShortcuts())
    settingsGui.Add("Button", "x240 y" . (yPos + 10) . " w100", "About").OnEvent("Click", (*) => showAbout())

    settingsGui.Show("w400 h" . (yPos + 50))
    settingsGui.OnEvent("Escape", CloseSettingsGui)

    SetTimer(CheckSettingsOutsideClick, 100)

    ; Function to safely close the settings GUI
    CloseSettingsGui(*) {
        SetTimer(CheckSettingsOutsideClick, 0)
        saveSettings(settingsGui.Submit())
        if IsObject(settingsGui) {
            try settingsGui.Destroy()
            settingsGui := 0
        }
    }

    ; Function to check for outside clicks
    CheckSettingsOutsideClick() {
        static isDestroying := false

        ; Skip if we're already in the process of destroying or if GUI is gone
        if isDestroying || !IsObject(settingsGui)
            return

        try {
            if !settingsGui.HasProp("Hwnd") || !WinExist("ahk_id " . settingsGui.Hwnd) {
                SetTimer(CheckSettingsOutsideClick, 0)
                settingsGui := 0
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
                saveSettings(settingsGui.Submit())
                try settingsGui.Destroy()
                settingsGui := 0
                isDestroying := false
            }
        } catch {
            ; If any error occurs, stop the timer
            SetTimer(CheckSettingsOutsideClick, 0)
            settingsGui := 0
        }
    }
}

; Display a simple notification that auto-closes
showNotification(message, timeout := 1200) {
    notify := Gui("+AlwaysOnTop -Caption +ToolWindow")
    notify.SetFont("s12 bold")
    notify.Add("Text", "w300 Center", message)
    notify.Show("NoActivate")
    SetTimer(() => notify.Destroy(), -timeout)
}

; Function to check for outside clicks
CheckOutsideClick(shortcutsGui) {
    static isDestroying := false

    ; Skip if we're already in the process of destroying or if GUI is gone
    if isDestroying || !IsObject(shortcutsGui)
        return

    try {
        if !shortcutsGui.HasProp("Hwnd") || !WinExist("ahk_id " . shortcutsGui.Hwnd) {
            SetTimer () => CheckOutsideClick(shortcutsGui), 0
            return
        }

        mouseIsOutside := false
        MouseGetPos(, , &winUnderCursor)
        if winUnderCursor != shortcutsGui.Hwnd {
            mouseIsOutside := true
        }

        if mouseIsOutside && GetKeyState("LButton", "P") {
            isDestroying := true
            SetTimer () => CheckOutsideClick(shortcutsGui), 0
            try shortcutsGui.Destroy()
            isDestroying := false
        }
    } catch {
        ; If any error occurs, stop the timer
        SetTimer () => CheckOutsideClick(shortcutsGui), 0
    }
}
