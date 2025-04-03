#Include common.ahk
#Include settings.ahk

alwaysOnTop() {
    WinSetAlwaysOnTop(-1, "A")
    isAlwaysOnTop := WinGetExStyle("A") & 0x8
    windowTitle := WinGetTitle("A")

    ; Get the process name (application name)
    processName := WinGetProcessName("A")
    appName := RegExReplace(processName, "\.exe$", "")

    if (StrLen(windowTitle) > 40)
        windowTitle := SubStr(windowTitle, 1, 37) . "..."
    showNotification("Always On Top: " . appName . " - " . (isAlwaysOnTop ? "Enabled" : "Disabled") .
    "`n" . windowTitle)
}

initCapsLockMonitor() {
    SetCapsLockState "AlwaysOff"
    ; Ensure CapsLock is off during startup
    loop 10 {
        SetTimer(() => SetCapsLockState("AlwaysOff"), -500 * A_Index)
    }
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
