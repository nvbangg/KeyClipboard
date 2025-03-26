; === APP_FUNCTIONS MODULE ===

initSettings() {
    global mouseEnabled, numLockEnabled
    global removeAccentsEnabled, normSpaceEnabled, removeSpecialEnabled
    global lineOption, caseOption, separatorOption
    global replaceWinClipboard, startWithWindows
    global firstRun

    existFile(settingsFilePath)

    mouseEnabled := readSetting("Settings", "mouseEnabled", "0") = "1"
    numLockEnabled := readSetting("Settings", "numLockEnabled", "1") = "1"

    removeAccentsEnabled := readSetting("Settings", "removeAccentsEnabled", "0") = "1"
    normSpaceEnabled := readSetting("Settings", "normSpaceEnabled", "1") = "1"
    removeSpecialEnabled := readSetting("Settings", "removeSpecialEnabled", "0") = "1"

    lineOption := Integer(readSetting("Settings", "lineOption", "1"))
    caseOption := Integer(readSetting("Settings", "caseOption", "0"))
    separatorOption := Integer(readSetting("Settings", "separatorOption", "0"))

    replaceWinClipboard := readSetting("AppSettings", "replaceWinClipboard", "1") = "1"
    startWithWindows := readSetting("AppSettings", "startWithWindows", "1") = "1"
    firstRun := readSetting("AppSettings", "firstRun", "1") = "1"

    updateNumLock()
    updateWinClipboardHotkey()
    updateStartupSetting()

    ; Show welcome message on first run
    if (firstRun) {
        showWelcomeMessage()
        createDesktopShortcut()
        writeSetting("AppSettings", "firstRun", "0")
    }
    if (replaceWinClipboard) {
        SetTimer(() => updateWinClipboardHotkey(), -1000)
    }
}

initCapsLockMonitor() {
    SetCapsLockState "AlwaysOff"
    ; Ensure CapsLock is off during startup
    loop 10 {
        SetTimer(() => SetCapsLockState("AlwaysOff"), -500 * A_Index)
    }
}

saveSettings(savedValues) {
    global mouseEnabled, numLockEnabled
    global removeAccentsEnabled, normSpaceEnabled, removeSpecialEnabled
    global lineOption, caseOption, separatorOption
    global replaceWinClipboard, startWithWindows

    existFile(settingsFilePath)

    mouseEnabled := !!savedValues.mouseEnabled
    numLockEnabled := !!savedValues.numLockEnabled

    removeAccentsEnabled := !!savedValues.removeAccentsEnabled
    normSpaceEnabled := !!savedValues.normSpaceEnabled
    removeSpecialEnabled := !!savedValues.removeSpecialEnabled

    lineOption := savedValues.lineOption - 1
    caseOption := savedValues.caseOption - 1
    separatorOption := savedValues.separatorOption - 1

    replaceWinClipboard := !!savedValues.replaceWinClipboard
    startWithWindows := !!savedValues.startWithWindows

    writeSetting("Settings", "mouseEnabled", mouseEnabled ? "1" : "0")
    writeSetting("Settings", "numLockEnabled", numLockEnabled ? "1" : "0")
    writeSetting("Settings", "removeAccentsEnabled", removeAccentsEnabled ? "1" : "0")
    writeSetting("Settings", "normSpaceEnabled", normSpaceEnabled ? "1" : "0")
    writeSetting("Settings", "removeSpecialEnabled", removeSpecialEnabled ? "1" : "0")
    writeSetting("Settings", "lineOption", lineOption)
    writeSetting("Settings", "caseOption", caseOption)
    writeSetting("Settings", "separatorOption", separatorOption)

    writeSetting("AppSettings", "replaceWinClipboard", replaceWinClipboard ? "1" : "0")
    writeSetting("AppSettings", "startWithWindows", startWithWindows ? "1" : "0")

    updateNumLock()
    updateWinClipboardHotkey()
    updateStartupSetting()
}

updateWinClipboardHotkey() {
    global replaceWinClipboard
    static hotkeyRegistered := false

    try {
        if (hotkeyRegistered) {
            Hotkey "#v", "Off"
            hotkeyRegistered := false
        }
    } catch {
        ; Ignore if hotkey wasn't previously registered
    }

    if (replaceWinClipboard) {
        try {
            ; Register with higher priority and make it persistent
            Hotkey "#v", WinVHandler, "On T3"
            hotkeyRegistered := true
            monitorWinClipboard()
        } catch Error as e {
            showInfo("Hotkey Error", "Failed to register Win+V hotkey:`n" . e.Message)
        }
    }
}

; Handler function for Win+V
WinVHandler(*) {
    BlockInput "On"
    Sleep 50
    BlockInput "Off"
    showClipboard()
}

; Monitor for Windows Clipboard and override it
monitorWinClipboard() {
    static timer := 0

    if (timer) {
        SetTimer timer, 0
        timer := 0
    }

    if (replaceWinClipboard) {
        checkForWindowsClipboard() {
            if WinExist("ahk_class Windows.UI.Core.CoreWindow ahk_exe ShellExperienceHost.exe") {
                WinClose
                Sleep 50
                showClipboard()
            }
        }
        timer := SetTimer(checkForWindowsClipboard, 100)
    }
}

addAppSettings(guiObj, yPos) {
    guiObj.Add("GroupBox", "x10 y" . yPos . " w350 h80", "App Settings")

    guiObj.Add("Checkbox", "x20 y" . (yPos + 20) . " w330 vReplaceWinClipboard",
    "Replace Windows Clipboard")
    .Value := replaceWinClipboard

    guiObj.Add("Checkbox", "x20 y" . (yPos + 45) . " w330 vStartWithWindows",
    "Start with Windows")
    .Value := startWithWindows

    return yPos + 90
}

updateStartupSetting() {
    global startWithWindows

    try {
        regKey := "HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Run"
        appName := "KeyClipboard"
        scriptPath := A_ScriptFullPath

        if (startWithWindows) {
            RegWrite(scriptPath, "REG_SZ", regKey, appName)
        } else {
            try {
                RegDelete(regKey, appName)
            } catch {
                ; Ignore if key doesn't exist
            }
        }
    } catch Error as e {
        showInfo("Startup Settings Error", "Failed to update startup settings:`n" . e.Message)
    }
}

showWelcomeMessage() {
    welcomeText :=
        "KeyClipboard has been successfully installed!`n`n" .
        "Quick Start Guide:`n`n" .
        "• CapsLock+C: Open Clipboard History`n" .
        "• CapsLock+S: Open Settings`n" .
        "• Double click on the tray icon to open settings`n`n" .
        "A shortcut has been created on your desktop to open settings.`n" .
        "Right-click the tray icon for more options."

    showInfo("Welcome to KeyClipboard", welcomeText, 450)
}

createDesktopShortcut() {
    try {
        desktopPath := A_Desktop
        shortcutPath := desktopPath . "\KeyClipboard.lnk"

        targetPath := A_ScriptFullPath
        workingDir := A_ScriptDir
        args := "settings"

        FileCreateShortcut(targetPath, shortcutPath, workingDir, args,
            "KeyClipboard - Clipboard Manager", A_ScriptDir . "app\app_icon.ico")
    } catch Error as e {
        OutputDebug("Failed to create desktop shortcut: " . e.Message)
    }
}
