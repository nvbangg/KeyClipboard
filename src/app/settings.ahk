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

            timer := SetTimer(checkForWindowsClipboard, 500)
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

resetAdvanced(gui) {
    gui["monitorDelay"].Value := DEFAULT_SETTINGS()["monitorDelay"]
    gui["pasteDelay"].Value := DEFAULT_SETTINGS()["pasteDelay"]
    gui["restoreDelay"].Value := DEFAULT_SETTINGS()["restoreDelay"]
    gui["enterDelay"].Value := DEFAULT_SETTINGS()["enterDelay"]
    gui["tabDelay"].Value := DEFAULT_SETTINGS()["tabDelay"]
    gui["enterCount"].Value := DEFAULT_SETTINGS()["enterCount"]
    gui["tabCount"].Value := DEFAULT_SETTINGS()["tabCount"]
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

        saveSettings(, values)
        gui.Destroy()
        showMsg("Advanced settings saved")
    } catch Error as e {
        MsgBox("Failed to save settings: " . e.Message, "Error", "OK 262144")
    }
}
