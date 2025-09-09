#Include clip_UI.ahk

; System Tray Configuration
A_TrayMenu.Add("Settings (Caps+S)", showSettings)
A_TrayMenu.Add("Shortcuts", showShortcuts)
A_TrayMenu.Add("About", showAbout)
A_IconTip := "KeyClipboard - Double click to open settings"
A_TrayMenu.Click := 1  ; Single click to activate
A_TrayMenu.Default := "Settings (Caps+S)"  ; Default action on double-click

showSettings(*) {
    static settingsGui := 0
    static isCreating := false

    ; Prevent multiple instances
    if (isCreating)
        return

    isCreating := true
    settingsGui := cleanupGui(settingsGui)

    settingsGui := Gui("+AlwaysOnTop +ToolWindow", "KeyClipboard - Settings")
    settingsGui.SetFont("s10")
    yPos := 10

    ; Add application settings section
    yPos := addAppSettings(settingsGui, yPos)

    ; Handle preset dropdown changes - reload GUI when preset changes
    OnPresetChanged(ctrl, *) {
        selectedPreset := ctrl.Text
        initialPreset := currentPreset
        if (selectedPreset != initialPreset) {
            loadPreset(selectedPreset)
            destroyGui(settingsGui)
            showSettings()
        }
    }

    ; Add preset management and format options sections
    yPos := addPresetManagementSection(settingsGui, yPos, OnPresetChanged, DeleteCurrentPreset, (*) => CreateNewPreset())
    yPos := addFormatOptions(settingsGui, yPos)

    CloseAndSave(*) {
        local guiRef := settingsGui
        local isCreatingRef := &isCreating

        try {
            if (isGuiValid(guiRef)) {
                formData := guiRef.Submit()  ; Get all form values
                saveSettings(formData)       ; Save to settings file
                saveToCurrentPreset()        ; Update current preset
                settingsGui := cleanupGui(guiRef)
            }
        } catch Error as e {
        }

        %isCreatingRef% := false  ; Reset creation flag
    }

    ; Add control buttons at bottom of GUI
    settingsGui.Add("Button", "x20 y" . (yPos + 10) . " w100 Default", "Save")
    .OnEvent("Click", CloseAndSave)
    settingsGui.Add("Button", "x130 y" . (yPos + 10) . " w100", "Shortcuts")
    .OnEvent("Click", (*) => showShortcuts())
    settingsGui.Add("Button", "x240 y" . (yPos + 10) . " w100", "About")
    .OnEvent("Click", (*) => showAbout())

    settingsGui.Show("w375 h" . (yPos + 50))
    closeEvents(settingsGui, CloseAndSave)  ; Setup ESC and X button handlers
    isCreating := false
}

; Display keyboard shortcuts help dialog
showShortcuts(*) {
    shortcutsText :=
        "• CapsLock+S (or E): Show Settings`n" .
        "• CapsLock+Shift+S (or E): Always-on-Top for active Window`n" .
        "• CapsLock+Tab(or Alt)+S (or E): Switch to next preset`n`n" .
        "• CapsLock+C: Show Clipboard History`n" .
        "• CapsLock+Shift+C: Clear Clipboard History`n" .
        "• CapsLock+Tab(or Alt)+C: Show Saved Items tab`n`n" .
        "• CapsLock+V: Paste latest item`n" .
        "• CapsLock+B: Paste second latest item`n" .
        "• CapsLock+A: Paste all clipboard items`n`n" .
        "• CapsLock+1-9,0: Paste by position`n" .
        "• CapsLock+T: Paste latest, Tab, then second latest`n" .
        "• CapsLock+F: Paste 'second latest_latest'`n`n" .
        "• CapsLock+Shift+V/B/A/T/Num/F: Paste with Format`n" .
        "• CapsLock+Ctrl+V/B/A/T/Num: Paste as Original`n" .
        "• CapsLock+Tab(or Alt)+V/B/A/T/Num: Paste from Saved Tab`n"
        

    showInfo("Shortcuts - KeyClipboard", shortcutsText, 425)
}

showAbout(*) {
    aboutText :=
        "KeyClipboard`n" .
        "Version: 1.7.1`n" .
        "Date: 09/09/2025`n`n" .
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
            Run("https://www.youtube.com/watch?v=dQw4w9WgXcQ") ; Easter egg :)
        } catch Error as e {
        }
    }
}

showWelcomeMessage() {
    welcomeText :=
        "KeyClipboard has been successfully installed!`n" .
        "A shortcut has been created on your desktop to open settings.`n`n" .
        "• CapsLock+C: Open Clipboard History`n" .
        "• CapsLock+S: Open Settings`n" .
        "• Double-click the tray icon in the system tray to open settings`n`n"

    welcomeGui := showInfo("Welcome to KeyClipboard", welcomeText, 400)
}
