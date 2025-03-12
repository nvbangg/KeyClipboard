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
    ensureFilesExist()

    mouseEnabled := IniRead(settingsFilePath, "Settings", "mouseEnabled", "0") = "1"
    numLockEnabled := IniRead(settingsFilePath, "Settings", "numLockEnabled", "1") = "1"
    beforeLatest_LatestEnabled := IniRead(settingsFilePath, "Settings", "beforeLatest_LatestEnabled", "1") = "1"
    formatCaseOption := Integer(IniRead(settingsFilePath, "Settings", "formatCaseOption", "3"))
    formatSeparator := Integer(IniRead(settingsFilePath, "Settings", "formatSeparator", "0"))

    updateNumLock()
}

; Save all settings to INI file
saveSettings(savedValues) {
    global mouseEnabled, numLockEnabled, formatCaseOption, formatSeparator, beforeLatest_LatestEnabled
    ensureFilesExist()

    beforeLatest_LatestEnabled := !!savedValues.beforeLatest_LatestEnabled
    mouseEnabled := !!savedValues.MouseClick
    numLockEnabled := !!savedValues.NumLock

    ; Text case format options
    if (savedValues.HasProp("CaseNone") && savedValues.CaseNone)
        formatCaseOption := 0
    else if (savedValues.HasProp("CaseUpper") && savedValues.CaseUpper)
        formatCaseOption := 1
    else if (savedValues.HasProp("CaseLower") && savedValues.CaseLower)
        formatCaseOption := 2
    else if (savedValues.HasProp("CaseNoDiacritics") && savedValues.CaseNoDiacritics)
        formatCaseOption := 3
    else if (savedValues.HasProp("CaseTitleCase") && savedValues.CaseTitleCase)
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
    IniWrite(formatCaseOption, settingsFilePath, "Settings", "formatCaseOption")
    IniWrite(formatSeparator, settingsFilePath, "Settings", "formatSeparator")

    updateNumLock()
}

; Display settings popup window
showSettings(*) {
    settingsGui := Gui(, "KeyClipboard - Settings")
    settingsGui.SetFont("s10")
    yPos := 10
    yPos := addKeySettings(settingsGui, yPos)
    yPos := addClipSettings(settingsGui, yPos)

    settingsGui.Add("Button", "x20 y" . (yPos + 10) . " w100 Default", "Save").OnEvent("Click", saveButtonClick)
    settingsGui.Add("Button", "x130 y" . (yPos + 10) . " w100", "Shortcuts").OnEvent("Click", (*) => showShortcuts())
    saveButtonClick(*) {
        saveSettings(settingsGui.Submit())
    }

    settingsGui.Show("w400 h" . (yPos + 50))
}

; Display a simple notification that auto-closes
showNotification(message, timeout := 1200) {
    notify := Gui("+AlwaysOnTop -Caption +ToolWindow")
    notify.SetFont("s12 bold")
    notify.Add("Text", "w300 Center", message)
    notify.Show("NoActivate")
    SetTimer(() => notify.Destroy(), -timeout)
}
