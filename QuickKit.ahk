; QuickKit - Quick utility toolkit
#Requires AutoHotkey v2.0
#SingleInstance Force

; Global settings
global mouseClickEnabled := false
global alwaysNumLockEnabled := true
global pasteFormatMode := 1
global settingsFilePath := A_ScriptDir . "\data\settings.ini"

; Initialize settings when script starts
InitSettings()
InitSettings() {
    global mouseClickEnabled, alwaysNumLockEnabled, pasteFormatMode, settingsFilePath
    
    if !FileExist(settingsFilePath) {
        FileAppend("", settingsFilePath)
    }
    mouseClickEnabled := IniRead(settingsFilePath, "Settings", "mouseClickEnabled", "0") = "1"
    alwaysNumLockEnabled := IniRead(settingsFilePath, "Settings", "alwaysNumLockEnabled", "1") = "1"
    pasteFormatMode := Integer(IniRead(settingsFilePath, "Settings", "pasteFormatMode", "1"))
    
    UpdateNumLockState()
}

; Save all settings to INI file
SaveAllSettings(savedValues) {
    global mouseClickEnabled, alwaysNumLockEnabled, pasteFormatMode, settingsFilePath
    
    mouseClickEnabled := !!savedValues.MouseClick
    alwaysNumLockEnabled := !!savedValues.NumLock
    
    if (savedValues.HasProp("FormatOption4") && savedValues.FormatOption4)
        pasteFormatMode := 4
    else if (savedValues.HasProp("FormatOption3") && savedValues.FormatOption3)
        pasteFormatMode := 3
    else if (savedValues.HasProp("FormatOption2") && savedValues.FormatOption2)
        pasteFormatMode := 2
    else
        pasteFormatMode := 1
    
    IniWrite(mouseClickEnabled ? "1" : "0", settingsFilePath, "Settings", "mouseClickEnabled")
    IniWrite(alwaysNumLockEnabled ? "1" : "0", settingsFilePath, "Settings", "alwaysNumLockEnabled")
    IniWrite(pasteFormatMode, settingsFilePath, "Settings", "pasteFormatMode")
    
    UpdateNumLockState()
}

; Module imports
#Include "modules\UI.ahk"
#Include "modules\Clipboard.ahk"
#Include "modules\MouseAndKey.ahk"
#Include "modules\Apps.ahk"
