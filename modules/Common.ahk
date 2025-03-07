; Common functions
global settingsFilePath := A_ScriptDir . "\data\settings.ini"

; Ensure the data file exists
EnsureDataFilesExist() {
    dataDir := A_ScriptDir . "\data"
    if !DirExist(dataDir) {
        DirCreate(dataDir)
    }
    if !FileExist(settingsFilePath) {
        FileAppend("", settingsFilePath)
    }
}

; Initialize settings
InitSettings() {
    global mouseClickEnabled, alwaysNumLockEnabled, formatCaseOption, formatSeparator, prefix_textEnabled
    EnsureDataFilesExist()

    mouseClickEnabled := IniRead(settingsFilePath, "Settings", "mouseClickEnabled", "0") = "1"
    alwaysNumLockEnabled := IniRead(settingsFilePath, "Settings", "alwaysNumLockEnabled", "1") = "1"
    prefix_textEnabled := IniRead(settingsFilePath, "Settings", "prefix_textEnabled", "1") = "1"
    formatCaseOption := Integer(IniRead(settingsFilePath, "Settings", "formatCaseOption", "3"))
    formatSeparator := Integer(IniRead(settingsFilePath, "Settings", "formatSeparator", "0"))

    UpdateNumLockState()
}

; Save all settings to INI file
SaveAllSettings(savedValues) {
    global mouseClickEnabled, alwaysNumLockEnabled, formatCaseOption, formatSeparator, prefix_textEnabled
    EnsureDataFilesExist()

    prefix_textEnabled := !!savedValues.prefix_textEnabled
    mouseClickEnabled := !!savedValues.MouseClick
    alwaysNumLockEnabled := !!savedValues.NumLock

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

    IniWrite(mouseClickEnabled ? "1" : "0", settingsFilePath, "Settings", "mouseClickEnabled")
    IniWrite(alwaysNumLockEnabled ? "1" : "0", settingsFilePath, "Settings", "alwaysNumLockEnabled")
    IniWrite(prefix_textEnabled ? "1" : "0", settingsFilePath, "Settings", "prefix_textEnabled")
    IniWrite(formatCaseOption, settingsFilePath, "Settings", "formatCaseOption")
    IniWrite(formatSeparator, settingsFilePath, "Settings", "formatSeparator")

    UpdateNumLockState()
}

; Display settings popup window
ShowSettingsPopup(*) {
    settingsGui := Gui(, "KeyClipboard - Settings")
    settingsGui.SetFont("s10")

    yPos := 10
    yPos := AddKeyboardSettings(settingsGui, yPos)
    yPos := AddClipboardSettings(settingsGui, yPos)

    settingsGui.Add("Button", "x20 y" . (yPos + 10) . " w100 Default", "Save").OnEvent("Click", SaveButtonClick)
    settingsGui.Add("Button", "x130 y" . (yPos + 10) . " w100", "Shortcuts").OnEvent("Click", (*) =>
        ShowKeyboardShortcuts())

    SaveButtonClick(*) {
        SaveAllSettings(settingsGui.Submit())
    }

    settingsGui.Show("w400 h" . (yPos + 50))
}

; Display a simple notification that auto-closes
ShowNotification(message, timeout := 1500) {
    notify := Gui("+AlwaysOnTop -Caption +ToolWindow")
    notify.SetFont("s10")
    notify.Add("Text", "w300", message)
    notify.Show("NoActivate")
    SetTimer(() => notify.Destroy(), -timeout)
}
