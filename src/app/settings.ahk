; === APP_FUNCTIONS MODULE ===

initSettings() {
    global firstRun, replaceWinClipboard, startWithWindows, maxHistoryCount
    global removeAccentsEnabled, normSpaceEnabled, removeSpecialEnabled
    global lineOption, caseOption, separatorOption
    global specificRemoveAccentsEnabled, specificNormSpaceEnabled, specificRemoveSpecialEnabled
    global specificLineOption, specificCaseOption, specificSeparatorOption
    global specificUseBeforeLatest
    global currentPreset := "Default"

    existFile(settingsFilePath)

    firstRun := readSetting("AppSettings", "firstRun", "1") = "1"
    replaceWinClipboard := readSetting("AppSettings", "replaceWinClipboard", "1") = "1"
    startWithWindows := readSetting("AppSettings", "startWithWindows", "1") = "1"
    maxHistoryCount := Integer(readSetting("AppSettings", "maxHistoryCount", "100"))

    loadPresetList()
    currentPreset := readSetting("Presets", "CurrentPreset", "Default")

    ; Ensure Default preset exists
    if (!HasValue(presetList, "Default")) {
        defaultPresetSection := "Preset_Default"

        writeSetting(defaultPresetSection, "removeAccentsEnabled", "0")
        writeSetting(defaultPresetSection, "normSpaceEnabled", "1")
        writeSetting(defaultPresetSection, "removeSpecialEnabled", "0")
        writeSetting(defaultPresetSection, "lineOption", "1")
        writeSetting(defaultPresetSection, "caseOption", "0")
        writeSetting(defaultPresetSection, "separatorOption", "0")

        writeSetting(defaultPresetSection, "specificUseBeforeLatest", "1")
        writeSetting(defaultPresetSection, "specificRemoveAccentsEnabled", "1")
        writeSetting(defaultPresetSection, "specificNormSpaceEnabled", "0")
        writeSetting(defaultPresetSection, "specificRemoveSpecialEnabled", "0")
        writeSetting(defaultPresetSection, "specificLineOption", "0")
        writeSetting(defaultPresetSection, "specificCaseOption", "3")
        writeSetting(defaultPresetSection, "specificSeparatorOption", "3")

        ; Add Default to preset list
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

saveFormatSpecificSettings(formData) {
    global specificRemoveAccentsEnabled, specificNormSpaceEnabled, specificRemoveSpecialEnabled
    global specificLineOption, specificCaseOption, specificSeparatorOption, specificUseBeforeLatest
    global currentPreset

    specificUseBeforeLatest := !!formData.specificUseBeforeLatest
    specificRemoveAccentsEnabled := !!formData.specificRemoveAccentsEnabled
    specificNormSpaceEnabled := !!formData.specificNormSpaceEnabled
    specificRemoveSpecialEnabled := !!formData.specificRemoveSpecialEnabled

    specificLineOption := formData.specificLineOption - 1
    specificCaseOption := formData.specificCaseOption - 1
    specificSeparatorOption := formData.specificSeparatorOption - 1

    sectionName := "Preset_" . currentPreset
    writeSetting(sectionName, "specificUseBeforeLatest", specificUseBeforeLatest ? "1" : "0")
    writeSetting(sectionName, "specificRemoveAccentsEnabled", specificRemoveAccentsEnabled ? "1" : "0")
    writeSetting(sectionName, "specificNormSpaceEnabled", specificNormSpaceEnabled ? "1" : "0")
    writeSetting(sectionName, "specificRemoveSpecialEnabled", specificRemoveSpecialEnabled ? "1" : "0")
    writeSetting(sectionName, "specificLineOption", specificLineOption)
    writeSetting(sectionName, "specificCaseOption", specificCaseOption)
    writeSetting(sectionName, "specificSeparatorOption", specificSeparatorOption)
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

addFormatOptions(settingsGui, yPos) {
    settingsGui.Add("GroupBox", "x10 y" . yPos . " w350 h190", "Format Options")

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

addFormatSpecificSection(settingsGui, yPos) {
    settingsGui.Add("GroupBox", "x10 y" . yPos . " w350 h55", "Format Specific Options (CapsLock + F)")
    settingsGui.Add("Text", "x20 y" . (yPos + 25) . " w230", "Click Edit to modify: ")
    settingsGui.Add("Button", "x150 y" . (yPos + 21) . " w50 h25", "Edit")
    .OnEvent("Click", (*) => showFormatSpecificSettings())

    return yPos + 60
}

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
    global specificUseBeforeLatest, specificRemoveAccentsEnabled, specificNormSpaceEnabled
    global specificRemoveSpecialEnabled, specificLineOption, specificCaseOption, specificSeparatorOption

    ; Save all Format Options and Format Specific Options
    writeSetting(sectionName, "removeAccentsEnabled", removeAccentsEnabled ? "1" : "0")
    writeSetting(sectionName, "normSpaceEnabled", normSpaceEnabled ? "1" : "0")
    writeSetting(sectionName, "removeSpecialEnabled", removeSpecialEnabled ? "1" : "0")
    writeSetting(sectionName, "lineOption", lineOption)
    writeSetting(sectionName, "caseOption", caseOption)
    writeSetting(sectionName, "separatorOption", separatorOption)

    writeSetting(sectionName, "specificUseBeforeLatest", specificUseBeforeLatest ? "1" : "0")
    writeSetting(sectionName, "specificRemoveAccentsEnabled", specificRemoveAccentsEnabled ? "1" : "0")
    writeSetting(sectionName, "specificNormSpaceEnabled", specificNormSpaceEnabled ? "1" : "0")
    writeSetting(sectionName, "specificRemoveSpecialEnabled", specificRemoveSpecialEnabled ? "1" : "0")
    writeSetting(sectionName, "specificLineOption", specificLineOption)
    writeSetting(sectionName, "specificCaseOption", specificCaseOption)
    writeSetting(sectionName, "specificSeparatorOption", specificSeparatorOption)
}

saveAsPreset(presetName) {
    global presetList, removeAccentsEnabled, normSpaceEnabled, removeSpecialEnabled
    global lineOption, caseOption, separatorOption
    global specificUseBeforeLatest, specificRemoveAccentsEnabled, specificNormSpaceEnabled
    global specificRemoveSpecialEnabled, specificLineOption, specificCaseOption, specificSeparatorOption
    global currentPreset

    ; Create preset section name
    sectionName := "Preset_" . presetName

    writeSetting(sectionName, "removeAccentsEnabled", removeAccentsEnabled ? "1" : "0")
    writeSetting(sectionName, "normSpaceEnabled", normSpaceEnabled ? "1" : "0")
    writeSetting(sectionName, "removeSpecialEnabled", removeSpecialEnabled ? "1" : "0")
    writeSetting(sectionName, "lineOption", lineOption)
    writeSetting(sectionName, "caseOption", caseOption)
    writeSetting(sectionName, "separatorOption", separatorOption)

    writeSetting(sectionName, "specificUseBeforeLatest", specificUseBeforeLatest ? "1" : "0")
    writeSetting(sectionName, "specificRemoveAccentsEnabled", specificRemoveAccentsEnabled ? "1" : "0")
    writeSetting(sectionName, "specificNormSpaceEnabled", specificNormSpaceEnabled ? "1" : "0")
    writeSetting(sectionName, "specificRemoveSpecialEnabled", specificRemoveSpecialEnabled ? "1" : "0")
    writeSetting(sectionName, "specificLineOption", specificLineOption)
    writeSetting(sectionName, "specificCaseOption", specificCaseOption)
    writeSetting(sectionName, "specificSeparatorOption", specificSeparatorOption)

    if (!HasValue(presetList, presetName)) {
        presetList.Push(presetName)
        writeSetting("Presets", "PresetList", Join(presetList, ","))
    }

    ; Set as current preset
    currentPreset := presetName
    writeSetting("Presets", "CurrentPreset", currentPreset)

    ; Only show notification for new presets, not when saving existing ones
    if (!HasValue(presetList, presetName)) {
        showNotification("Preset '" . presetName . "' created")
    }
}

loadPreset(presetName, showNotify := true) {
    global removeAccentsEnabled, normSpaceEnabled, removeSpecialEnabled
    global lineOption, caseOption, separatorOption
    global specificUseBeforeLatest, specificRemoveAccentsEnabled, specificNormSpaceEnabled
    global specificRemoveSpecialEnabled, specificLineOption, specificCaseOption, specificSeparatorOption
    global currentPreset

    sectionName := "Preset_" . presetName

    removeAccentsEnabled := readSetting(sectionName, "removeAccentsEnabled", "0") = "1"
    normSpaceEnabled := readSetting(sectionName, "normSpaceEnabled", "1") = "1"
    removeSpecialEnabled := readSetting(sectionName, "removeSpecialEnabled", "0") = "1"
    lineOption := Integer(readSetting(sectionName, "lineOption", "1"))
    caseOption := Integer(readSetting(sectionName, "caseOption", "0"))
    separatorOption := Integer(readSetting(sectionName, "separatorOption", "0"))

    specificUseBeforeLatest := readSetting(sectionName, "specificUseBeforeLatest", "1") = "1"
    specificRemoveAccentsEnabled := readSetting(sectionName, "specificRemoveAccentsEnabled", "1") = "1"
    specificNormSpaceEnabled := readSetting(sectionName, "specificNormSpaceEnabled", "0") = "1"
    specificRemoveSpecialEnabled := readSetting(sectionName, "specificRemoveSpecialEnabled", "0") = "1"
    specificLineOption := Integer(readSetting(sectionName, "specificLineOption", "0"))
    specificCaseOption := Integer(readSetting(sectionName, "specificCaseOption", "3"))
    specificSeparatorOption := Integer(readSetting(sectionName, "specificSeparatorOption", "3"))

    currentPreset := presetName
    writeSetting("Presets", "CurrentPreset", currentPreset)
}
