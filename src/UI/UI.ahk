#Include clip_UI.ahk

; Set up tray menu and icon click behavior
A_TrayMenu.Add("Settings (Caps+S)", showSettings)
A_TrayMenu.Add("Shortcuts", showShortcuts)
A_TrayMenu.Add("About", showAbout)
A_IconTip := "KeyClipboard - Double click to open settings"
A_TrayMenu.Click := 1
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
    yPos := addAppSettings(settingsGui, yPos)

    OnPresetChanged(ctrl, *) {
        selectedPreset := ctrl.Text
        initialPreset := currentPreset
        if (selectedPreset != initialPreset) {
            loadPreset(selectedPreset)
            destroyGui(settingsGui)
            showSettings()
        }
    }
    yPos := addPresetManagementSection(settingsGui, yPos,
        OnPresetChanged,
        DeleteCurrentPreset,
        (*) => CreateNewPreset())

    yPos := addFormatOptions(settingsGui, yPos)
    yPos := addFormatSpecificSection(settingsGui, yPos)

    CloseAndSave() {
        formData := settingsGui.Submit()
        saveSettings(formData)
        saveToCurrentPreset()
        settingsGui := cleanupGui(settingsGui)
        isCreating := false
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

showFormatSpecificSettings(*) {
    static formatSpecificGui := 0
    static isCreating := false
    if (isCreating)
        return
    isCreating := true
    formatSpecificGui := cleanupGui(formatSpecificGui)

    formatSpecificGui := Gui("+AlwaysOnTop +ToolWindow", "Format Specific Settings")
    formatSpecificGui.SetFont("s10")
    yPos := 10

    formatSpecificGui.Add("GroupBox", "x10 y" . yPos . " w350 h230", "Format Specific Options")
    yPos += 25
    formatSpecificGui.Add("CheckBox", "x20 y" . yPos . " vspecificUseBeforeLatest Checked" . specificUseBeforeLatest,
        "Include beforeLatest item (beforeLatest_latest)")
    yPos += 30

    checkboxOptions := [
        ["specificRemoveAccentsEnabled", specificRemoveAccentsEnabled, "Remove Accents"],
        ["specificNormSpaceEnabled", specificNormSpaceEnabled, "Normalize Spaces"],
        ["specificRemoveSpecialEnabled", specificRemoveSpecialEnabled, "Remove Special Characters (# *)"]
    ]

    for option in checkboxOptions {
        formatSpecificGui.Add("CheckBox", "x20 y" . yPos . " v" . option[1] . " Checked" . option[2], option[3])
        yPos += 25
    }
    yPos += 10

    dropdownOptions := [
        ["Line Break:", "specificLineOption", ["None", "Trim Lines", "Remove All Line Breaks"], specificLineOption],
        ["Text Case:", "specificCaseOption", ["None", "UPPERCASE", "lowercase", "Title Case", "Sentence case"],
        specificCaseOption],
        ["Word Separator:", "specificSeparatorOption", ["None", "Underscore (_)", "Hyphen (-)", "Remove Spaces"],
        specificSeparatorOption]
    ]

    for option in dropdownOptions {
        formatSpecificGui.Add("Text", "x20 y" . yPos . " w150", option[1])
        formatSpecificGui.Add("DropDownList", "x160 y" . (yPos - 3) . " w180 AltSubmit v" . option[2] . " Choose" . (
            option[4] + 1), option[3])
        yPos += 30
    }

    SaveFormatSpecific() {
        formData := formatSpecificGui.Submit()
        formatSpecificGui := cleanupGui(formatSpecificGui)
        saveFormatSpecificSettings(formData)
        isCreating := false
    }

    formatSpecificGui.Add("Button", "x130 y" . (yPos + 10) . " w100 Default", "Save")
    .OnEvent("Click", (*) => SaveFormatSpecific())
    formatSpecificGui.Show("w375 h" . (yPos + 50))
    closeEvents(formatSpecificGui, (*) => SaveFormatSpecific())
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
        "Version: 1.6.4.2`n" .
        "Date: 02/04/2025`n`n" .
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

    welcomeGui := showInfo("Welcome to KeyClipboard", welcomeText, 400)
}
