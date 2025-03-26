; === APP_FUNCTIONS MODULE ===

initSettings() {
    global firstRun, replaceWinClipboard, startWithWindows
    global removeAccentsEnabled, normSpaceEnabled, removeSpecialEnabled
    global lineOption, caseOption, separatorOption

    existFile(settingsFilePath)

    firstRun := readSetting("AppSettings", "firstRun", "1") = "1"
    replaceWinClipboard := readSetting("AppSettings", "replaceWinClipboard", "1") = "1"
    startWithWindows := readSetting("AppSettings", "startWithWindows", "1") = "1"

    removeAccentsEnabled := readSetting("FormatOptions", "removeAccentsEnabled", "0") = "1"
    normSpaceEnabled := readSetting("FormatOptions", "normSpaceEnabled", "1") = "1"
    removeSpecialEnabled := readSetting("FormatOptions", "removeSpecialEnabled", "0") = "1"

    lineOption := Integer(readSetting("FormatOptions", "lineOption", "1"))
    caseOption := Integer(readSetting("FormatOptions", "caseOption", "0"))
    separatorOption := Integer(readSetting("FormatOptions", "separatorOption", "0"))

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

saveSettings(savedValues) {
    global firstRun, replaceWinClipboard, startWithWindows
    global removeAccentsEnabled, normSpaceEnabled, removeSpecialEnabled
    global lineOption, caseOption, separatorOption

    existFile(settingsFilePath)

    replaceWinClipboard := !!savedValues.replaceWinClipboard
    startWithWindows := !!savedValues.startWithWindows

    removeAccentsEnabled := !!savedValues.removeAccentsEnabled
    normSpaceEnabled := !!savedValues.normSpaceEnabled
    removeSpecialEnabled := !!savedValues.removeSpecialEnabled

    lineOption := savedValues.lineOption - 1
    caseOption := savedValues.caseOption - 1
    separatorOption := savedValues.separatorOption - 1

    writeSetting("AppSettings", "replaceWinClipboard", replaceWinClipboard ? "1" : "0")
    writeSetting("AppSettings", "startWithWindows", startWithWindows ? "1" : "0")

    writeSetting("FormatOptions", "removeAccentsEnabled", removeAccentsEnabled ? "1" : "0")
    writeSetting("FormatOptions", "normSpaceEnabled", normSpaceEnabled ? "1" : "0")
    writeSetting("FormatOptions", "removeSpecialEnabled", removeSpecialEnabled ? "1" : "0")

    writeSetting("FormatOptions", "lineOption", lineOption)
    writeSetting("FormatOptions", "caseOption", caseOption)
    writeSetting("FormatOptions", "separatorOption", separatorOption)

    updateWinClipboardHotkey()
    updateStartupSetting()
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

addFormatOptions(settingsGui, yPos) {
    settingsGui.Add("GroupBox", "x10 y" . yPos . " w350 h200", "Format Options")

    checkboxOptions := [
        ["removeAccentsEnabled", removeAccentsEnabled, "Remove Accents"],
        ["normSpaceEnabled", normSpaceEnabled, "Normalize Spaces"],
        ["removeSpecialEnabled", removeSpecialEnabled, "Remove Special Characters (# *)"]
    ]
    yPos += 25

    for option in checkboxOptions {
        settingsGui.Add("CheckBox", "x20 y" . yPos . " v" . option[1] . " Checked" . option[2], option[3])
        yPos += 25
    }
    yPos += 10

    dropdownOptions := [
        ["Line Break:", "lineOption", ["None", "Trim Lines", "Remove All Line Breaks"], lineOption],
        ["Text Case:", "caseOption", ["None", "UPPERCASE", "lowercase", "Title Case", "Sentence case"], caseOption],
        ["Word Separator:", "separatorOption", ["None", "Underscore (_)", "Hyphen (-)", "Remove Spaces"],
        separatorOption]
    ]

    for option in dropdownOptions {
        settingsGui.Add("Text", "x20 y" . yPos . " w150", option[1])
        settingsGui.Add("DropDownList", "x160 y" . (yPos - 3) . " w180 AltSubmit v" . option[2] .
        " Choose" . (option[4] + 1), option[3])
        yPos += 30
    }

    return yPos + 15
}
