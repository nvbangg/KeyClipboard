DEFAULT_APP := {
    firstRun: "1",
    replaceWinClip: "1", 
    autoStart: "1",
    historyLimit: "100"
}

DEFAULT_ADVANCED := {
    monitorDelay: 100,
    pasteDelay: 50,
    restoreDelay: 100,
    enterDelay: 50,
    tabDelay: 50,
    enterCount: 1,
    tabCount: 1
}

DEFAULT_PRESET := {
    removeAccentsEnabled: "1",
    removeSpecialEnabled: "1",
    lineOption: "0",
    caseOption: "3", 
    separatorOption: "4"
}

initApp() {
    global firstRun, replaceWinClip, autoStart, historyLimit
    global currentPreset := "Default"
    global presetList, currentPreset
    
    existFile(settingsFilePath)
    readAppSettings()
    readAdvancedSettings()
    readPresetInit()
    
    updateWinClipHotkey()
    updateStartupSetting()

    if (firstRun)
        handleFirstRun()

    if (replaceWinClip)
        SetTimer(() => updateWinClipHotkey(), -1000)
}

existFile(filePath) {
    if !DirExist(dataDir)
        DirCreate(dataDir)
    if !FileExist(filePath)
        FileAppend("", filePath)
}

readSetting(section, key, defaultValue) {
    static settings := Map()

    if (section = "__CLEAR_CACHE__") {
        settings.Clear()
        return ""
    }
    
    fullKey := section . "_" . key
    if (!settings.Has(fullKey))
        settings[fullKey] := IniRead(settingsFilePath, section, key, defaultValue)
    return settings[fullKey]
}

writeSetting(section, key, value) {
    global settingsFilePath
    IniWrite(value, settingsFilePath, section, key)
    clearSettingFromCache(section, key)
}

readAppSettings() {
    global firstRun, replaceWinClip, autoStart, historyLimit
    firstRun := readSetting("AppSettings", "firstRun", DEFAULT_APP.firstRun) = "1"
    replaceWinClip := readSetting("AppSettings", "replaceWinClip", DEFAULT_APP.replaceWinClip) = "1"
    autoStart := readSetting("AppSettings", "autoStart", DEFAULT_APP.autoStart) = "1"
    historyLimit := Integer(readSetting("AppSettings", "historyLimit", DEFAULT_APP.historyLimit))
}

resetToDefaults() {
    global replaceWinClip, autoStart, historyLimit
    global removeAccentsEnabled, removeSpecialEnabled
    global lineOption, caseOption, separatorOption
    
    replaceWinClip := DEFAULT_APP.replaceWinClip = "1"
    autoStart := DEFAULT_APP.autoStart = "1"
    historyLimit := Integer(DEFAULT_APP.historyLimit)
    
    removeAccentsEnabled := DEFAULT_PRESET.removeAccentsEnabled = "1"
    removeSpecialEnabled := DEFAULT_PRESET.removeSpecialEnabled = "1"
    lineOption := Integer(DEFAULT_PRESET.lineOption)
    caseOption := Integer(DEFAULT_PRESET.caseOption)
    separatorOption := Integer(DEFAULT_PRESET.separatorOption)
}

handleFirstRun() {
    showSettings()
    showWelcome()
    createDesktopShortcut()
    
    writeSetting("AppSettings", "firstRun", "0")
    writeSetting("AppSettings", "replaceWinClip", DEFAULT_APP.replaceWinClip)
    writeSetting("AppSettings", "autoStart", DEFAULT_APP.autoStart)
    writeSetting("AppSettings", "historyLimit", DEFAULT_APP.historyLimit)
}

saveSettings(savedValues) {
    global replaceWinClip, autoStart, historyLimit
    global removeAccentsEnabled, removeSpecialEnabled
    global lineOption, caseOption, separatorOption, currentPreset

    existFile(settingsFilePath)

    replaceWinClip := !!savedValues.replaceWinClip
    autoStart := !!savedValues.autoStart
    historyLimit := Integer(savedValues.historyLimit)

    removeAccentsEnabled := !!savedValues.removeAccentsEnabled
    removeSpecialEnabled := !!savedValues.removeSpecialEnabled

    lineOption := savedValues.lineOption - 1
    caseOption := savedValues.caseOption - 1
    separatorOption := savedValues.separatorOption - 1

    writeSetting("AppSettings", "replaceWinClip", replaceWinClip ? "1" : "0")
    writeSetting("AppSettings", "autoStart", autoStart ? "1" : "0")
    writeSetting("AppSettings", "historyLimit", historyLimit)

    writePresetSettings("Preset_" . currentPreset)
    
    updateWinClipHotkey()
    updateStartupSetting()
}

readAdvancedSettings() {
    global monitorDelay, pasteDelay, restoreDelay
    global enterDelay, tabDelay, enterCount, tabCount
    
    monitorDelay := Integer(readSetting("AdvancedSettings", "monitorDelay", DEFAULT_ADVANCED.monitorDelay))
    pasteDelay := Integer(readSetting("AdvancedSettings", "pasteDelay", DEFAULT_ADVANCED.pasteDelay))
    restoreDelay := Integer(readSetting("AdvancedSettings", "restoreDelay", DEFAULT_ADVANCED.restoreDelay))
    enterDelay := Integer(readSetting("AdvancedSettings", "enterDelay", DEFAULT_ADVANCED.enterDelay))
    tabDelay := Integer(readSetting("AdvancedSettings", "tabDelay", DEFAULT_ADVANCED.tabDelay))
    enterCount := Integer(readSetting("AdvancedSettings", "enterCount", DEFAULT_ADVANCED.enterCount))
    tabCount := Integer(readSetting("AdvancedSettings", "tabCount", DEFAULT_ADVANCED.tabCount))
}

writeAdvancedSettings(values) {
    global monitorDelay, pasteDelay, restoreDelay
    global enterDelay, tabDelay, enterCount, tabCount
    
    monitorDelay := Integer(values.monitorDelay)
    pasteDelay := Integer(values.pasteDelay)
    restoreDelay := Integer(values.restoreDelay)
    enterDelay := Integer(values.enterDelay)
    tabDelay := Integer(values.tabDelay)
    enterCount := Integer(values.enterCount)
    tabCount := Integer(values.tabCount)
    
    writeSetting("AdvancedSettings", "monitorDelay", monitorDelay)
    writeSetting("AdvancedSettings", "pasteDelay", pasteDelay)
    writeSetting("AdvancedSettings", "restoreDelay", restoreDelay)
    writeSetting("AdvancedSettings", "enterDelay", enterDelay)
    writeSetting("AdvancedSettings", "tabDelay", tabDelay)
    writeSetting("AdvancedSettings", "enterCount", enterCount)
    writeSetting("AdvancedSettings", "tabCount", tabCount)
}

readPresetInit() {
    global presetList := []
    global currentPreset
    
    presetString := readSetting("Presets", "PresetList", "")
    if (presetString != "") {
        presetNames := StrSplit(presetString, ",")
        for _, name in presetNames {
            if (name != "")
                presetList.Push(name)
        }
    }
    
    currentPreset := readSetting("Presets", "CurrentPreset", "Default")
    if (!HasValue(presetList, "Default"))
        createDefaultPreset()
    if (!HasValue(presetList, currentPreset))
        currentPreset := "Default"
    
    readPreset(currentPreset)
}

readPreset(presetName) {
    global removeAccentsEnabled, removeSpecialEnabled
    global lineOption, caseOption, separatorOption
    global currentPreset

    clearSettingsCache()

    sectionName := "Preset_" . presetName
    
    removeAccentsEnabled := readSetting(sectionName, "removeAccentsEnabled", "0") = "1"
    removeSpecialEnabled := readSetting(sectionName, "removeSpecialEnabled", "0") = "1"
    lineOption := Integer(readSetting(sectionName, "lineOption", "1"))
    caseOption := Integer(readSetting(sectionName, "caseOption", "0"))
    separatorOption := Integer(readSetting(sectionName, "separatorOption", "0"))

    currentPreset := presetName
    writeSetting("Presets", "CurrentPreset", currentPreset)
}

writePresetSettings(sectionName) {
    global removeAccentsEnabled, removeSpecialEnabled
    global lineOption, caseOption, separatorOption
    
    writeSetting(sectionName, "removeAccentsEnabled", removeAccentsEnabled ? "1" : "0")
    writeSetting(sectionName, "removeSpecialEnabled", removeSpecialEnabled ? "1" : "0")
    writeSetting(sectionName, "lineOption", lineOption)
    writeSetting(sectionName, "caseOption", caseOption)
    writeSetting(sectionName, "separatorOption", separatorOption)
}

createDefaultPreset() {
    global presetList, currentPreset
    sectionName := "Preset_Default"
    
    for key, value in DEFAULT_PRESET.OwnProps()
        writeSetting(sectionName, key, value)

    presetList.Push("Default")
    writeSetting("Presets", "PresetList", Join(presetList, ","))
    currentPreset := "Default"
}

