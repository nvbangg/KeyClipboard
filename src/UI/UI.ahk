#Include clip_UI.ahk

; Set up tray menu and icon click behavior
A_TrayMenu.Add("Settings (Caps+S)", showSettings)
A_TrayMenu.Add("Shortcuts", showShortcuts)
A_TrayMenu.Add("About", showAbout)
A_IconTip := "KeyClipboard - Double click to open settings"

; Configure tray icon to show settings on left click
A_TrayMenu.Click := 1  ; 1 means single click
A_TrayMenu.Default := "Settings (Caps+S)"

showSettings(*) {
    static settingsGui := 0
    static isCreating := false
    if (isCreating)
        return
    isCreating := true
    settingsGui := cleanupGui(settingsGui)

    settingsGui := Gui("+AlwaysOnTop +ToolWindow", "KeyClipboard - Settings")
    settingsGui.SetFont("s10")
    yPos := 10

    ; Use the new function for App Settings
    yPos := addAppSettings(settingsGui, yPos)

    ; Keyboard settings removed

    yPos := addFormatOptions(settingsGui, yPos)

    ; Helper function for saving and closing
    CloseAndSave() {
        formData := settingsGui.Submit()
        settingsGui := cleanupGui(settingsGui)
        saveSettings(formData)
    }

    settingsGui.Add("Button", "x20 y" . (yPos + 10) . " w100 Default", "Save")
    .OnEvent("Click", (*) => CloseAndSave())
    settingsGui.Add("Button", "x130 y" . (yPos + 10) . " w100", "Shortcuts")
    .OnEvent("Click", (*) => showShortcuts())
    settingsGui.Add("Button", "x240 y" . (yPos + 10) . " w100", "About")
    .OnEvent("Click", (*) => showAbout())

    settingsGui.Show("w375 h" . (yPos + 50))
    closeEvents(settingsGui, (*) => CloseAndSave())
    isCreating := false
}

showShortcuts(*) {
    shortcutsText :=
        "• CapsLock+S: Show Settings Popup`n" .
        "• CapsLock+Shift+S: Always-on-Top for active Window`n" .
        "• CapsLock+C: Show Clipboard History`n" .
        "• CapsLock+Tab+C: Show Clipboard Saved tab`n" .
        "• CapsLock+Shift+C: Clear Clipboard History`n" .
        "• CapsLock+F: Paste combining previous and current item`n`n" .
        "• CapsLock+V: Paste latest item from clipboard history`n" .
        "• CapsLock+B: Paste the item before the latest`n" .
        "• CapsLock+A: Paste all clipboard items`n" .
        "• CapsLock+Shift+V/B/A: Paste item(s) with Format`n" .
        "• CapsLock+Ctrl+V/B/A: Paste item(s) as Original`n" .
        "• CapsLock+Tab+V/B/A: Paste item(s) from Saved tab`n" .
        "• CapsLock+1-9: Paste item by position from saved tab`n"

    showInfo("Shortcuts - KeyClipboard", shortcutsText, 375)
}

showAbout(*) {
    aboutText :=
        "KeyClipboard`n" .
        "Version: 1.6.3.3`n" .
        "Date: 01/04/2025`n`n" .
        "Source: github.com/nvbangg/KeyClipboard`n" .
        "Click Yes to open"

    result := MsgBox(aboutText, "About KeyClipboard", "YesNo 262144")  ; YesNo with AlwaysOnTop flag

    if (result == "Yes") {
        try {
            Run("https://github.com/nvbangg/KeyClipboard")
        } catch Error as e {
        }
    } else if (result == "No") {
        try {
            Run("https://www.youtube.com/watch?v=dQw4w9WgXcQ") ; =)))))
        } catch Error as e {
        }
    }
}

showWelcomeMessage() {
    welcomeText :=
        "KeyClipboard has been successfully installed!`n" .
        "A shortcut has been created on your desktop to open settings.`n`n" .
        "• CapsLock+C: Open Clipboard History`n" .
        "• CapsLock+Tab+C: Open Clipboard Saved tab`n" .
        "• CapsLock+S: Open Settings`n" .
        "• Double-click the tray icon in the system tray to open settings`n`n"
    showInfo("Welcome to KeyClipboard", welcomeText, 400)
}
