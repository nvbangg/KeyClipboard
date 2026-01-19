initApp() {
    readSettings()
    saveSettings()
    updateStartupSetting()

    if (firstRun) {
        writeConfig("AppSettings", "firstRun", "0")
        writeConfig("Presets", "PresetList", join(presetList, ","))
        writeConfig("Presets", "CurrentPreset", currentPreset)
        welcome()
    }
    if (replaceWinClip)
        updateWinClipHotkey()
}

existFile(filePath) {
    if !DirExist(dataDir)
        DirCreate(dataDir)
    if !FileExist(filePath)
        FileAppend("", filePath)
}

DEFAULT_SETTINGS() {
    return Map(
        "firstRun", "1",
        "replaceWinClip", "1",
        "autoStart", "1",
        "showCopied", "0",
        "historyLimit", "100",
        "removeAccentsEnabled", "1",
        "removeSpecialEnabled", "1",
        "lineOption", "0",
        "caseOption", "3",
        "separatorOption", "4",
        "PresetList", "Default",
        "CurrentPreset", "Default",
        "monitorDelay", "100",
        "pasteDelay", "50",
        "restoreDelay", "100",
        "enterDelay", "50",
        "tabDelay", "50",
        "enterCount", "1",
        "tabCount", "1"
    )
}

readConfig(section, key) {
    return IniRead(SETTINGS_PATH, section, key, DEFAULT_SETTINGS()[key])
}

writeConfig(section, key, value) {
    IniWrite(value, SETTINGS_PATH, section, key)
}

readSettings() {
    existFile(SETTINGS_PATH)

    global firstRun := readConfig("AppSettings", "firstRun") = "1"
    global replaceWinClip := readConfig("AppSettings", "replaceWinClip") = "1"
    global autoStart := readConfig("AppSettings", "autoStart") = "1"
    global showCopied := readConfig("AppSettings", "showCopied") = "1"
    global historyLimit := Integer(readConfig("AppSettings", "historyLimit"))
    updateWinClipHotkey()
    updateStartupSetting()

    global presetList := StrSplit(readConfig("Presets", "PresetList"), ",")
    global currentPreset := readConfig("Presets", "CurrentPreset")

    sectionName := "Preset_" . currentPreset
    global removeAccentsEnabled := readConfig(sectionName, "removeAccentsEnabled") = "1"
    global removeSpecialEnabled := readConfig(sectionName, "removeSpecialEnabled") = "1"
    global lineOption := Integer(readConfig(sectionName, "lineOption"))
    global caseOption := Integer(readConfig(sectionName, "caseOption"))
    global separatorOption := Integer(readConfig(sectionName, "separatorOption"))

    global monitorDelay := Integer(readConfig("AdvancedSettings", "monitorDelay"))
    global pasteDelay := Integer(readConfig("AdvancedSettings", "pasteDelay"))
    global restoreDelay := Integer(readConfig("AdvancedSettings", "restoreDelay"))
    global enterDelay := Integer(readConfig("AdvancedSettings", "enterDelay"))
    global tabDelay := Integer(readConfig("AdvancedSettings", "tabDelay"))
    global enterCount := Integer(readConfig("AdvancedSettings", "enterCount"))
    global tabCount := Integer(readConfig("AdvancedSettings", "tabCount"))
}

saveSettings(settingsGui := 0, advancedValues := 0) {
    existFile(SETTINGS_PATH)
    global currentPreset, presetList

    if (settingsGui) {
        settingsValues := settingsGui.Submit()
        oldReplaceWinClip := replaceWinClip
        global replaceWinClip := !!settingsValues.replaceWinClip
        global autoStart := !!settingsValues.autoStart
        global showCopied := !!settingsValues.showCopied
        global historyLimit := Integer(settingsValues.historyLimit)

        global removeAccentsEnabled := !!settingsValues.removeAccentsEnabled
        global removeSpecialEnabled := !!settingsValues.removeSpecialEnabled
        global lineOption := settingsValues.lineOption - 1
        global caseOption := settingsValues.caseOption - 1
        global separatorOption := settingsValues.separatorOption - 1

        if (oldReplaceWinClip != replaceWinClip)
            updateWinClipHotkey()

        destroyGui(settingsGui)
    }

    if (advancedValues) {
        global monitorDelay := Integer(advancedValues.monitorDelay)
        global pasteDelay := Integer(advancedValues.pasteDelay)
        global restoreDelay := Integer(advancedValues.restoreDelay)
        global enterDelay := Integer(advancedValues.enterDelay)
        global tabDelay := Integer(advancedValues.tabDelay)
        global enterCount := Integer(advancedValues.enterCount)
        global tabCount := Integer(advancedValues.tabCount)
    }

    writeConfig("AppSettings", "replaceWinClip", replaceWinClip ? "1" : "0")
    writeConfig("AppSettings", "autoStart", autoStart ? "1" : "0")
    writeConfig("AppSettings", "showCopied", showCopied ? "1" : "0")
    writeConfig("AppSettings", "historyLimit", historyLimit)

    sectionName := "Preset_" . currentPreset
    writeConfig(sectionName, "removeAccentsEnabled", removeAccentsEnabled ? "1" : "0")
    writeConfig(sectionName, "removeSpecialEnabled", removeSpecialEnabled ? "1" : "0")
    writeConfig(sectionName, "lineOption", lineOption)
    writeConfig(sectionName, "caseOption", caseOption)
    writeConfig(sectionName, "separatorOption", separatorOption)

    writeConfig("AdvancedSettings", "monitorDelay", monitorDelay)
    writeConfig("AdvancedSettings", "pasteDelay", pasteDelay)
    writeConfig("AdvancedSettings", "restoreDelay", restoreDelay)
    writeConfig("AdvancedSettings", "enterDelay", enterDelay)
    writeConfig("AdvancedSettings", "tabDelay", tabDelay)
    writeConfig("AdvancedSettings", "enterCount", enterCount)
    writeConfig("AdvancedSettings", "tabCount", tabCount)
}
