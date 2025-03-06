; KeyClipboard - Keyboard and clipboard utility
#Requires AutoHotkey v2.0
#SingleInstance Force

; Global settings
global mouseClickEnabled := false
global alwaysNumLockEnabled := true
global formatCaseOption := 3          ; 0=none, 1=UPPERCASE, 2=lowercase, 3=remove diacritics, 4=Title Case
global formatSeparator := 0           ; 0=none, 1=underscore, 2=hyphen, 3=no spaces
global prefix_textEnabled := true   ; Whether to use code filename format (prefix_text.)
global settingsFilePath := A_ScriptDir . "\data\settings.ini"

; Initialize settings when script starts
InitSettings() {
    global mouseClickEnabled, alwaysNumLockEnabled, formatCaseOption, formatSeparator, prefix_textEnabled,
        settingsFilePath

    if !FileExist(settingsFilePath) {
        FileAppend("", settingsFilePath)
    }
    mouseClickEnabled := IniRead(settingsFilePath, "Settings", "mouseClickEnabled", "0") = "1"
    alwaysNumLockEnabled := IniRead(settingsFilePath, "Settings", "alwaysNumLockEnabled", "1") = "1"
    prefix_textEnabled := IniRead(settingsFilePath, "Settings", "prefix_textEnabled", "1") = "1"
    formatCaseOption := Integer(IniRead(settingsFilePath, "Settings", "formatCaseOption", "3"))
    formatSeparator := Integer(IniRead(settingsFilePath, "Settings", "formatSeparator", "0"))

    UpdateNumLockState()
}

; Save all settings to INI file
SaveAllSettings(savedValues) {
    global mouseClickEnabled, alwaysNumLockEnabled, formatCaseOption, formatSeparator, prefix_textEnabled,
        settingsFilePath

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

; Module imports
#Include "modules\UI.ahk"
#Include "modules\Clipboard.ahk"
#Include "modules\Keyboard.ahk"