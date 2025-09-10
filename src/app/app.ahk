#Include common.ahk
#Include settings.ahk

alwaysOnTop() {
    WinSetAlwaysOnTop(-1, "A")
    isAlwaysOnTop := WinGetExStyle("A") & 0x8

    processName := WinGetProcessName("A")
    appName := RegExReplace(processName, "\.exe$", "")

    showNotification("Pin " . appName . ": " . (isAlwaysOnTop ? "Enabled" : "Disabled"))
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
    }

    ; Register our custom Win+V handler if replacement is enabled
    if (replaceWinClipboard) {
        try {
            Hotkey "#v", WinVHandler, "On T3"
            hotkeyRegistered := true
            monitorWinClipboard()  
        } catch Error as e {
            showInfo("Hotkey Error", "Failed to register Win+V hotkey:`n" . e.Message)
        }
    }
}

WinVHandler(*) {
    BlockInput "On"
    Sleep 50
    BlockInput "Off"
    showClipboard()
}

monitorWinClipboard() {
    static timer := 0
    ; Clear any existing timer
    if (timer) {
        SetTimer timer, 0
        timer := 0
    }

    if (replaceWinClipboard) {
        checkForWindowsClipboard() {
            if WinExist("ahk_class Windows.UI.Core.CoreWindow ahk_exe ShellExperienceHost.exe") {
                WinClose         ; Close Windows clipboard
                Sleep 50         
                showClipboard()  
            }
        }
        timer := SetTimer(checkForWindowsClipboard, 100)  ; Monitor every 100ms
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

        ; Create shortcut with icon and description
        FileCreateShortcut(targetPath, shortcutPath, workingDir, args,
            "KeyClipboard - Clipboard Manager", A_ScriptDir . "app\app_icon.ico")
    } catch Error as e {
        OutputDebug("Failed to create desktop shortcut: " . e.Message)
    }
}
