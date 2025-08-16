initSettings() {
    global firstRun, replaceWinClipboard, startWithWindows, maxHistoryCount
    global removeAccentsEnabled, normSpaceEnabled, removeSpecialEnabled
    global lineOption, caseOption, separatorOption

    global currentPreset := "Default"

    existFile(settingsFilePath)

    firstRun := readSetting("AppSettings", "firstRun", "1") = "1"
    replaceWinClipboard := readSetting("AppSettings", "replaceWinClipboard", "1") = "1"
    startWithWindows := readSetting("AppSettings", "startWithWindows", "1") = "1"
    maxHistoryCount := Integer(readSetting("AppSettings", "maxHistoryCount", "100"))

    loadPresetList()
    currentPreset := readSetting("Presets", "CurrentPreset", "Default")

    ; Create "Default" preset if it doesn't exist (first run)
    if (!HasValue(presetList, "Default")) {
        defaultPresetSection := "Preset_Default"

        writeSetting(defaultPresetSection, "removeAccentsEnabled", "0")
        writeSetting(defaultPresetSection, "normSpaceEnabled", "0")
        writeSetting(defaultPresetSection, "removeSpecialEnabled", "0")
        writeSetting(defaultPresetSection, "lineOption", "1")
        writeSetting(defaultPresetSection, "caseOption", "0")
        writeSetting(defaultPresetSection, "separatorOption", "0")


        presetList.Push("Default")
        writeSetting("Presets", "PresetList", Join(presetList, ","))
        currentPreset := "Default"
    }

    if (!HasValue(presetList, currentPreset)) {
        currentPreset := "Default"
    }

    loadPreset(currentPreset, false)
    updateWinClipboardHotkey()
    updateStartupSetting()

    if (firstRun) {
        showSettings()
        showWelcomeMessage()
        createDesktopShortcut()
        writeSetting("AppSettings", "firstRun", "0")
        writeSetting("AppSettings", "replaceWinClipboard", "1")
        writeSetting("AppSettings", "startWithWindows", "1")
        writeSetting("AppSettings", "maxHistoryCount", "100")
    }

    if (replaceWinClipboard) {
        SetTimer(() => updateWinClipboardHotkey(), -1000)
    }
}

saveSettings(savedValues) {
    global firstRun, replaceWinClipboard, startWithWindows, maxHistoryCount
    global removeAccentsEnabled, normSpaceEnabled, removeSpecialEnabled
    global lineOption, caseOption, separatorOption
    global currentPreset

    existFile(settingsFilePath)

    replaceWinClipboard := !!savedValues.replaceWinClipboard
    startWithWindows := !!savedValues.startWithWindows
    maxHistoryCount := Integer(savedValues.maxHistoryCount)

    removeAccentsEnabled := !!savedValues.removeAccentsEnabled
    normSpaceEnabled := !!savedValues.normSpaceEnabled
    removeSpecialEnabled := !!savedValues.removeSpecialEnabled

    lineOption := savedValues.lineOption - 1
    caseOption := savedValues.caseOption - 1
    separatorOption := savedValues.separatorOption - 1

    writeSetting("AppSettings", "replaceWinClipboard", replaceWinClipboard ? "1" : "0")
    writeSetting("AppSettings", "startWithWindows", startWithWindows ? "1" : "0")
    writeSetting("AppSettings", "maxHistoryCount", maxHistoryCount)

    sectionName := "Preset_" . currentPreset
    writeSetting(sectionName, "removeAccentsEnabled", removeAccentsEnabled ? "1" : "0")
    writeSetting(sectionName, "normSpaceEnabled", normSpaceEnabled ? "1" : "0")
    writeSetting(sectionName, "removeSpecialEnabled", removeSpecialEnabled ? "1" : "0")
    writeSetting(sectionName, "lineOption", lineOption)
    writeSetting(sectionName, "caseOption", caseOption)
    writeSetting(sectionName, "separatorOption", separatorOption)

    updateWinClipboardHotkey()
    updateStartupSetting()
}

addAppSettings(guiObj, yPos) {
    guiObj.Add("GroupBox", "x10 y" . yPos . " w350 h100", "App Settings")

    guiObj.Add("Checkbox", "x20 y" . (yPos + 20) . " w330 vReplaceWinClipboard",
    "Replace Windows Clipboard")
    .Value := replaceWinClipboard

    guiObj.Add("Checkbox", "x20 y" . (yPos + 45) . " w330 vStartWithWindows",
    "Start with Windows")
    .Value := startWithWindows

    guiObj.Add("Text", "x20 y" . (yPos + 70) . " w150", "Max History Items:")
    guiObj.Add("DropDownList", "x160 y" . (yPos + 67) . " w180 vMaxHistoryCount Choose" .
    getMaxHistoryIndex(maxHistoryCount), ["50", "100", "200", "500", "1000"])

    return yPos + 110
}

; Add text formatting options section to settings GUI
addFormatOptions(settingsGui, yPos) {
    settingsGui.Add("GroupBox", "x10 y" . yPos . " w350 h190", "Format Options")

    checkboxOptions := [
        ["removeAccentsEnabled", removeAccentsEnabled, "Remove Accents"],
        ["normSpaceEnabled", normSpaceEnabled, "Normalize Punctuation Spaces"],
        ["removeSpecialEnabled", removeSpecialEnabled, "Remove Special Characters (# *)"]
    ]
    yPos += 25

    for option in checkboxOptions {
        settingsGui.Add("CheckBox", "x20 y" . yPos . " v" . option[1] . " Checked" . option[2], option[3])
        yPos += 25
    }
    yPos += 5

    dropdownOptions := [
        ["Line Break:", "lineOption", ["None", "Trim Lines", "Remove All Line Breaks"], lineOption],
        ["Text Case:", "caseOption", ["None", "UPPERCASE", "lowercase", "Title Case", "Sentence case"], caseOption],
        ["Word Separator:", "separatorOption", ["None", "Underscore (_)", "Hyphen (-)", "Remove Spaces"],
        separatorOption]
    ]

    for option in dropdownOptions {
        settingsGui.Add("Text", "x20 y" . yPos . " w150", option[1])
        settingsGui.Add("DropDownList", "x160 y" . (yPos - 3) . " w180 AltSubmit v" . option[2] . " Choose" . (option[4
            ] + 1), option[3])
        yPos += 30
    }

    return yPos + 10
}

; Add preset management dropdown and buttons to settings GUI
addPresetManagementSection(settingsGui, yPos, presetChangedCallback, deletePresetCallback, createPresetCallback) {
    global presetList, currentPreset

    settingsGui.Add("Text", "x20 y" . (yPos + 3) . " w80", "Presets:")

    presetArray := []
    for _, name in presetList
        presetArray.Push(name)
    presetDropdown := settingsGui.Add("DropDownList", "x80 y" . (yPos) . " w180 vSelectedPreset", presetArray)
    currentIndex := 1
    if (currentPreset != "") {
        for i, name in presetList {
            if (name = currentPreset) {
                currentIndex := i
                break
            }
        }
    }
    presetDropdown.Choose(currentIndex)
    initialPreset := presetDropdown.Text
    presetDropdown.OnEvent("Change", presetChangedCallback)
    settingsGui.Add("Button", "x265 y" . (yPos - 1) . " w35 h25", "Del")
    .OnEvent("Click", (*) => deletePresetCallback(presetDropdown))
    settingsGui.Add("Button", "x305 y" . (yPos - 1) . " w45 h25", "New")
    .OnEvent("Click", createPresetCallback)

    return yPos + 40
}

savePresetSettings(sectionName) {
    global removeAccentsEnabled, normSpaceEnabled, removeSpecialEnabled
    global lineOption, caseOption, separatorOption

    writeSetting(sectionName, "removeAccentsEnabled", removeAccentsEnabled ? "1" : "0")
    writeSetting(sectionName, "normSpaceEnabled", normSpaceEnabled ? "1" : "0")
    writeSetting(sectionName, "removeSpecialEnabled", removeSpecialEnabled ? "1" : "0")
    writeSetting(sectionName, "lineOption", lineOption)
    writeSetting(sectionName, "caseOption", caseOption)
    writeSetting(sectionName, "separatorOption", separatorOption)
}

saveAsPreset(presetName) {
    global presetList, removeAccentsEnabled, normSpaceEnabled, removeSpecialEnabled
    global lineOption, caseOption, separatorOption
    global currentPreset

    sectionName := "Preset_" . presetName

    writeSetting(sectionName, "removeAccentsEnabled", removeAccentsEnabled ? "1" : "0")
    writeSetting(sectionName, "normSpaceEnabled", normSpaceEnabled ? "1" : "0")
    writeSetting(sectionName, "removeSpecialEnabled", removeSpecialEnabled ? "1" : "0")
    writeSetting(sectionName, "lineOption", lineOption)
    writeSetting(sectionName, "caseOption", caseOption)
    writeSetting(sectionName, "separatorOption", separatorOption)

    if (!HasValue(presetList, presetName)) {
        presetList.Push(presetName)
        writeSetting("Presets", "PresetList", Join(presetList, ","))
    }

    currentPreset := presetName
    writeSetting("Presets", "CurrentPreset", currentPreset)

    if (!HasValue(presetList, presetName)) {
        showNotification("Preset '" . presetName . "' created")
    }
}

loadPreset(presetName, showNotify := true) {
    global removeAccentsEnabled, normSpaceEnabled, removeSpecialEnabled
    global lineOption, caseOption, separatorOption
    global currentPreset

    sectionName := "Preset_" . presetName

    removeAccentsEnabled := readSetting(sectionName, "removeAccentsEnabled", "0") = "1"
    normSpaceEnabled := readSetting(sectionName, "normSpaceEnabled", "0") = "1"
    removeSpecialEnabled := readSetting(sectionName, "removeSpecialEnabled", "0") = "1"
    lineOption := Integer(readSetting(sectionName, "lineOption", "1"))
    caseOption := Integer(readSetting(sectionName, "caseOption", "0"))
    separatorOption := Integer(readSetting(sectionName, "separatorOption", "0"))

    ; Update current preset reference
    currentPreset := presetName
    writeSetting("Presets", "CurrentPreset", currentPreset)
}
