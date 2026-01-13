#Include UI_utils.ahk
#Include ../app/preset.ahk
#Include ../app/app_storage.ahk
#Include ../app/settings.ahk
#Include ../app/app_utils.ahk

A_TrayMenu.Add("Settings (CapsLock+S)", showSettings)
A_TrayMenu.Add("Shortcuts", showShortcuts)
A_TrayMenu.Add("About", showAbout)
A_IconTip := "KeyClipboard - Double click to open settings"
A_TrayMenu.Click := 1
A_TrayMenu.Default := "Settings (CapsLock+S)"

showSettings(*) {
    static settingsGui := 0
    destroyGui(settingsGui)
    settingsGui := Gui("+AlwaysOnTop +ToolWindow", "KeyClipboard - Settings")
    settingsGui.SetFont("s10")
    yPos := 10
    yPos := addAppSettings(settingsGui, yPos)
    yPos := addPresetManagement(settingsGui, yPos)
    yPos := addFormatOptions(settingsGui, yPos)

    settingsGui.Add("Button", "x20 y" . (yPos + 10) . " w90 Default", "Save")
    .OnEvent("Click", (*) => saveSettings(settingsGui))
    settingsGui.Add("Button", "x120 y" . (yPos + 10) . " w90", "Shortcuts")
    .OnEvent("Click", (*) => showShortcuts())
    settingsGui.Add("Button", "x220 y" . (yPos + 10) . " w90", "About")
    .OnEvent("Click", (*) => showAbout())
    settingsGui.Show("w345 h" . (yPos + 50))
    closeEvents(settingsGui, (*) => saveSettings(settingsGui))
}

showShortcuts(*) {
    text :=
        "• CapsLock+S: Show Settings`n" .
        "• CapsLock+Ctrl+S: Always-on-Top for active Window`n" .
        "• CapsLock+Alt+S: Switch to next preset`n`n" .
        "• CapsLock+C: Show History`n" .
        "• CapsLock+Ctrl+C: Clear History`n" .
        "• CapsLock+Alt+C: Show Saved Items`n`n" .
        "• CapsLock+A: Paste all History`n" .
        "• CapsLock+V: Paste second latest, Tab, then latest`n" .
        "• CapsLock+T: Paste all History with Tab separator`n" .
        "• CapsLock+E: Paste all History with Enter separator`n" .
        "• CapsLock(+Shift)+B: Paste 'second latest_latest'`n`n" .
        "• CapsLock+(Alt)+1-9,0: Paste by Index`n" .
        "• CapsLock+Shift+(Alt)+Num/A/V/T/E: Paste with Format`n" .
        "• CapsLock+Ctrl+(Alt)+Num/A/V/T/E: Paste from Saved Items`n"
    MsgBox(text, "Shortcuts - KeyClipboard", "OK 262144")
}

showAbout(*) {
    text :=
        "KeyClipboard`n" .
        "Version: 1.11.0`n" .
        "Date: 2026-01-13`n`n" .
        "Source: github.com/nvbangg/KeyClipboard`n" .
        "Click Yes to open"
    if (MsgBox(text, "About KeyClipboard", "YesNo 262144") == "Yes") ; 262144: AlwaysOnTop flag
        Run("https://github.com/nvbangg/KeyClipboard")
    else
        Run("https://www.youtube.com/watch?v=dQw4w9WgXcQ") ; Easter egg :)
}

addAppSettings(guiObj, yPos) {
    guiObj.Add("GroupBox", "x10 y" . yPos . " w320 h125", "App Settings")
    guiObj.Add("Checkbox", "x20 y" . (yPos + 20) . " w330 vreplaceWinClip",
    "Replace Windows Clipboard")
    .Value := replaceWinClip
    guiObj.Add("Checkbox", "x20 y" . (yPos + 45) . " w330 vautoStart",
    "Auto start with Windows")
    .Value := autoStart
    guiObj.Add("Checkbox", "x20 y" . (yPos + 70) . " w330 vshowCopied",
    "Show copy notification")
    .Value := showCopied
    guiObj.Add("Text", "x20 y" . (yPos + 100) . " w140", "History Limit:")
    guiObj.Add("DropDownList", "x110 y" . (yPos + 96) . " w70 vhistoryLimit Choose" .
    getHistoryLimit(historyLimit), ["50", "100", "200", "500", "1000"])
    guiObj.Add("Button", "x190 y" . (yPos + 94) . " w130 h25", "Advanced Settings")
    .OnEvent("Click", (*) => showAdvanced())

    return yPos + 135
}

addFormatOptions(settingsGui, yPos) {
    settingsGui.Add("GroupBox", "x10 y" . yPos . " w320 h170", "Format Options")

    checkboxOptions := [
        ["removeAccentsEnabled", removeAccentsEnabled, "Remove Accents"],
        ["removeSpecialEnabled", removeSpecialEnabled, "Remove Special Characters"]
    ]
    yPos += 25
    for option in checkboxOptions {
        settingsGui.Add("CheckBox", "x20 y" . yPos . " v" . option[1] . " Checked" . option[2], option[3])
        yPos += 25
    }
    yPos += 5

    dropdownOptions := [
        ["Line Break:", "lineOption", ["None", "Remove Empty Lines", "Remove Line Breaks"], lineOption],
        ["Text Case:", "caseOption", ["None", "UPPERCASE", "lowercase", "Title Case", "Sentence case"], caseOption],
        ["Word Separator:", "separatorOption", ["None", "Space ( )", "Underscore (_)", "Hyphen (-)", "Remove Spaces"],
        separatorOption]
    ]
    for option in dropdownOptions {
        settingsGui.Add("Text", "x20 y" . yPos . " w100", option[1])
        settingsGui.Add("DropDownList", "x140 y" . (yPos - 3) . " w170 AltSubmit v" . option[2] . " Choose" . (option[4
            ] + 1), option[3])
        yPos += 30
    }

    return yPos
}

addPresetManagement(settingsGui, yPos) {
    global presetList, currentPreset

    settingsGui.Add("Text", "x20 y" . (yPos + 8) . " w80", "Presets:")
    presetArray := []
    for _, name in presetList
        presetArray.Push(name)
    presetDropdown := settingsGui.Add("DropDownList", "x80 y" . (yPos + 5) . " w150 vSelectedPreset", presetArray)
    currentIndex := 1
    if (currentPreset != "" && presetArray.Length > 0) {
        for i, name in presetList {
            if (name = currentPreset) {
                currentIndex := i
                break
            }
        }
        if (currentIndex > presetArray.Length) {
            currentIndex := 1
        }
    }

    if (presetArray.Length > 0) {
        presetDropdown.Choose(currentIndex)
        initialPreset := presetDropdown.Text
        presetDropdown.OnEvent("Change", OnPresetChanged)
    }
    settingsGui.Add("Button", "x235 y" . (yPos + 4) . " w35 h25", "Del")
    .OnEvent("Click", (*) => deleteCurrentPreset(presetDropdown, settingsGui))
    settingsGui.Add("Button", "x275 y" . (yPos + 4) . " w45 h25", "New")
    .OnEvent("Click", (*) => createNewPreset(settingsGui))
    return yPos + 40

    ; Reload GUI when preset changes
    OnPresetChanged(ctrl, *) {
        selectedPreset := ctrl.Text
        if (selectedPreset != currentPreset) {
            saveSettings(settingsGui)
            writeConfig("Presets", "CurrentPreset", selectedPreset)
            readSettings()
            showSettings()
        }
    }
}

showAdvanced() {
    global monitorDelay, pasteDelay, restoreDelay
    global enterDelay, tabDelay, enterCount, tabCount

    advancedGui := Gui("+AlwaysOnTop +ToolWindow", "Advanced Settings")
    advancedGui.SetFont("s10")

    advancedGui.Add("Text", "x10 y10 w300 Center", "Advanced Configuration")
    yPos := 40

    advancedGui.Add("GroupBox", "x10 y" . yPos . " w300 h60", "Clipboard Monitor")
    advancedGui.Add("Text", "x20 y" . (yPos + 20) . " w150", "Monitor Delay:")
    advancedGui.Add("Edit", "x170 y" . (yPos + 17) . " w50 Number vmonitorDelay", monitorDelay)
    advancedGui.Add("Text", "x225 y" . (yPos + 20) . " w30", "ms")
    yPos += 70

    advancedGui.Add("GroupBox", "x10 y" . yPos . " w300 h85", "Paste Operations")
    advancedGui.Add("Text", "x20 y" . (yPos + 20) . " w150", "Action Delay:")
    advancedGui.Add("Edit", "x170 y" . (yPos + 17) . " w50 Number vpasteDelay", pasteDelay)
    advancedGui.Add("Text", "x225 y" . (yPos + 20) . " w30", "ms")

    advancedGui.Add("Text", "x20 y" . (yPos + 45) . " w150", "Restore Delay:")
    advancedGui.Add("Edit", "x170 y" . (yPos + 42) . " w50 Number vrestoreDelay", restoreDelay)
    advancedGui.Add("Text", "x225 y" . (yPos + 45) . " w30", "ms")
    yPos += 95

    advancedGui.Add("GroupBox", "x10 y" . yPos . " w300 h110", "Input Operations")
    advancedGui.Add("Text", "x20 y" . (yPos + 20) . " w150", "Enter Delay:")
    advancedGui.Add("Edit", "x170 y" . (yPos + 17) . " w50 Number venterDelay", enterDelay)
    advancedGui.Add("Text", "x225 y" . (yPos + 20) . " w30", "ms")

    advancedGui.Add("Text", "x20 y" . (yPos + 45) . " w150", "Tab Delay:")
    advancedGui.Add("Edit", "x170 y" . (yPos + 42) . " w50 Number vtabDelay", tabDelay)
    advancedGui.Add("Text", "x225 y" . (yPos + 45) . " w30", "ms")

    advancedGui.Add("Text", "x20 y" . (yPos + 70) . " w80", "Enter Count:")
    advancedGui.Add("Edit", "x100 y" . (yPos + 67) . " w30 Number venterCount", enterCount)
    advancedGui.Add("Text", "x140 y" . (yPos + 70) . " w80", "Tab Count:")
    advancedGui.Add("Edit", "x210 y" . (yPos + 67) . " w30 Number vtabCount", tabCount)
    advancedGui.Add("Text", "x250 y" . (yPos + 70) . " w50", "(0-10)")
    yPos += 120

    advancedGui.Add("Button", "x10 y" . (yPos + 10) . " w80 h30", "Reset").OnEvent("Click", (*) =>
        resetAdvanced(advancedGui))
    advancedGui.Add("Button", "x160 y" . (yPos + 10) . " w70 h30", "Apply").OnEvent("Click", (*) =>
        applyAdvanced(advancedGui))
    advancedGui.Add("Button", "x240 y" . (yPos + 10) . " w70 h30", "Close").OnEvent("Click", (*) => advancedGui.Destroy())

    advancedGui.Show("w320 h" . (yPos + 50))
}

welcome() {
    showSettings()

    text :=
        "KeyClipboard has been successfully installed!`n" .
        "A shortcut has been created on your desktop to open settings.`n`n" .
        "• CapsLock+C: Open Clipboard History`n" .
        "• CapsLock+S: Open Settings`n" .
        "• Double-click the tray icon in the system tray to open settings`n`n"
    MsgBox(text, "Welcome to KeyClipboard", "OK 262144")

    ; Create desktop shortcut
    try {
        desktopPath := A_Desktop
        shortcutPath := desktopPath . "\KeyClipboard.lnk"
        targetPath := A_ScriptFullPath
        workingDir := A_ScriptDir
        args := "settings"
        ; Create shortcut with icon and description
        iconPath := A_IsCompiled ? A_ScriptFullPath : A_ScriptDir . "\src\UI\icon.ico"
        FileCreateShortcut(targetPath, shortcutPath, workingDir, args,
            "KeyClipboard - Clipboard Manager", iconPath)
    } catch Error as e {
        OutputDebug("Failed to create desktop shortcut: " . e.Message)
    }
}
