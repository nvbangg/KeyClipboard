alwaysOnTop() {
    WinSetAlwaysOnTop(-1, "A")
    isAlwaysOnTop := WinGetExStyle("A") & 0x8
    processName := WinGetProcessName("A")
    appName := RegExReplace(processName, "\.exe$", "")
    showMsg("Pin " . appName . ": " . (isAlwaysOnTop ? "Enabled" : "Disabled"))
}

updateWinClipHotkey() {
    global replaceWinClip
    static hotkeyRegistered := false
    static timer := 0
    
    try {
        if (hotkeyRegistered) {
            Hotkey "#v", "Off"
            hotkeyRegistered := false
        }
    }
    if (timer) {
        SetTimer timer, 0
        timer := 0
    }

    ; Register our custom Win+V handler if replacement is enabled
    if (replaceWinClip) {
        try {
            Hotkey "#v", WinVHandler, "On T3"
            hotkeyRegistered := true
            
            WinVHandler(*) {
                BlockInput "On"
                Sleep 50
                BlockInput "Off"
                showClipboard()
            }
            ; Monitor Windows clipboard function
            checkForWindowsClipboard() {
                if WinExist("ahk_class Windows.UI.Core.CoreWindow ahk_exe ShellExperienceHost.exe") {
                    WinClose
                    Sleep 50
                    showClipboard()
                }
            }
            
            timer := SetTimer(checkForWindowsClipboard, 100)
        } catch Error as e {
            MsgBox("Failed to register Win+V hotkey:`n" . e.Message, "Hotkey Error", "OK 262144")
        }
    }
}

updateStartupSetting() {
    global autoStart
    try {
        regKey := "HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Run"
        appName := "KeyClipboard"
        scriptPath := A_ScriptFullPath
        if (autoStart)
            RegWrite(scriptPath, "REG_SZ", regKey, appName)
        else try RegDelete(regKey, appName)
    } catch Error as e {
        MsgBox("Failed to update startup settings:`n" . e.Message, "Startup Settings Error", "OK 262144")
    }
}

createDesktopShortcut() {
    try {
        desktopPath := A_Desktop
        shortcutPath := desktopPath . "\KeyClipboard.lnk"
        targetPath := A_ScriptFullPath
        workingDir := A_ScriptDir
        args := "settings"
        ; Create shortcut with icon and description
        FileCreateShortcut(targetPath, shortcutPath, workingDir, args,
            "KeyClipboard - Clipboard Manager", A_ScriptDir . "app\app_icon.ico")
    } catch Error as e {
        OutputDebug("Failed to create desktop shortcut: " . e.Message)
    }
}

resetAdvanced(gui) {
    gui["monitorDelay"].Value := 100
    gui["pasteDelay"].Value := 50
    gui["restoreDelay"].Value := 100
    gui["enterDelay"].Value := 50
    gui["tabDelay"].Value := 50
    gui["enterCount"].Value := 1
    gui["tabCount"].Value := 1
}

applyAdvanced(gui) {
    try {
        values := {
            monitorDelay: gui["monitorDelay"].Value,
            pasteDelay: gui["pasteDelay"].Value,
            restoreDelay: gui["restoreDelay"].Value,
            enterDelay: gui["enterDelay"].Value,
            tabDelay: gui["tabDelay"].Value,
            enterCount: gui["enterCount"].Value,
            tabCount: gui["tabCount"].Value
        }

        for key, value in values.OwnProps() {
            if (key = "enterCount" || key = "tabCount") {
                if (!IsInteger(value) || value < 0 || value > 10) {
                    MsgBox("Enter/Tab count must be 0-10", "Invalid Input", "OK 262144")
                    return
                }
            } else {
                if (!IsInteger(value) || value < 0 || value > 5000) {
                    MsgBox("Delays must be 0-5000 ms", "Invalid Input", "OK 262144")
                    return
                }
            }
        }

        existFile(settingsFilePath)
        writeAdvancedSettings(values)
        gui.Destroy()
        showMsg("Advanced settings saved")
    } catch Error as e {
        MsgBox("Failed to save settings: " . e.Message, "Error", "OK 262144")
    }
}
