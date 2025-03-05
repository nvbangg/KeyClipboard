; QuickKit - Quick utility toolkit
#Requires AutoHotkey v2.0
#SingleInstance Force

; Global settings
global mouseClickEnabled := false
global alwaysNumLockEnabled := true
global settingsFilePath := A_ScriptDir . "\settings.ini"

LoadSettings()

LoadSettings() {
    global mouseClickEnabled, alwaysNumLockEnabled, settingsFilePath
    
    if FileExist(settingsFilePath) {
        mouseClickEnabled := IniRead(settingsFilePath, "MouseAndKey", "mouseClickEnabled", 0) = "1"
        alwaysNumLockEnabled := IniRead(settingsFilePath, "MouseAndKey", "alwaysNumLockEnabled", 0) = "1"
    } else {
        IniWrite("0", settingsFilePath, "MouseAndKey", "mouseClickEnabled")
        IniWrite("1", settingsFilePath, "MouseAndKey", "alwaysNumLockEnabled")
    }
}

; Module imports
#Include "modules\UI.ahk"
#Include "modules\Clipboard.ahk"
#Include "modules\MouseAndKey.ahk"
#Include "modules\Apps.ahk"
