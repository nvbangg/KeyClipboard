createNewPreset(settingsGui := 0) {
    InputBox := Gui("+AlwaysOnTop +ToolWindow", "Create New Preset")
    InputBox.SetFont("s10")
    InputBox.Add("Text", "x10 y10 w280", "Enter a name for this preset:")
    nameEdit := InputBox.Add("Edit", "x10 y35 w280 vPresetName")

    InputBox.Add("Button", "x100 y70 w100 Default", "Create")
    .OnEvent("Click", (*) => CreatePresetAndClose(InputBox))
    InputBox.Add("Button", "x210 y70 w80", "Cancel")
    .OnEvent("Click", (*) => InputBox.Destroy())
    closeEvents(InputBox, (*) => InputBox.Destroy())
    InputBox.Show("w300 h110")

    CreatePresetAndClose(inputGui) {
        presetName := inputGui["PresetName"].Value
        if (presetName != "") {
            saveAsPreset(presetName)
            inputGui.Destroy()
            if (isGuiValid(settingsGui))
                destroyGui(settingsGui)
            showSettings()
        } else
            showMsg("Please enter a preset name")
    }
}

deleteCurrentPreset(dropdown, settingsGui := 0) {
    global presetList, currentPreset
    presetToDelete := dropdown.Text

    if (presetToDelete = "Default") {
        showMsg("Cannot delete the Default preset")
        return
    }

    if (MsgBox("Confirm delete preset '" . presetToDelete . "'?",
        "Confirm Delete", "YesNo 262144") != "Yes")
        return

    if (!HasValue(presetList, presetToDelete)) {
        showMsg("Preset '" . presetToDelete . "' not found")
        return
    }
    
    IniDelete(settingsFilePath, "Preset_" . presetToDelete)
    
    newPresetList := []
    for _, name in presetList {
        if (name != presetToDelete)
            newPresetList.Push(name)
    }
    presetList := newPresetList
    writeSetting("Presets", "PresetList", Join(presetList, ","))

    if (currentPreset = presetToDelete) {
        currentPreset := "Default"
        writeSetting("Presets", "CurrentPreset", "Default")
        readPreset("Default")
    }

    if (isGuiValid(settingsGui))
        destroyGui(settingsGui)
    showSettings()
    showMsg("Preset '" . presetToDelete . "' deleted")
}

switchTabPreset() {
    global presetList, currentPreset

    if (presetList.Length < 2) {
        showMsg("Only one preset available")
        return
    }

    ; Close settings window if it's open to prevent data overwrite
    if (WinExist("KeyClipboard - Settings")) {
        WinClose("KeyClipboard - Settings")
        Sleep(50) ; Brief delay to ensure window is closed
    }

    currentIndex := 0
    for i, name in presetList {
        if (name = currentPreset) {
            currentIndex := i
            break
        }
    }

    nextIndex := (currentIndex = 0 || currentIndex = presetList.Length) ? 1 : currentIndex + 1
    nextPreset := presetList[nextIndex]
    readPreset(nextPreset)
    showMsg("Switched to preset: " . nextPreset)
}

saveAsPreset(presetName) {
    global lineOption, caseOption, separatorOption
    global currentPreset

    sectionName := "Preset_" . presetName
    writePresetSettings(sectionName)

    if (!HasValue(presetList, presetName)) {
        presetList.Push(presetName)
        writeSetting("Presets", "PresetList", Join(presetList, ","))
    }

    currentPreset := presetName
    writeSetting("Presets", "CurrentPreset", currentPreset)

    if (!HasValue(presetList, presetName))
        showMsg("Preset '" . presetName . "' created")
}

saveToCurrentPreset() {
    global currentPreset, removeAccentsEnabled, removeSpecialEnabled
    global lineOption, caseOption, separatorOption
    
    if (currentPreset != "") {
        sectionName := "Preset_" . currentPreset
        writePresetSettings(sectionName)
        writeSetting("Presets", "CurrentPreset", currentPreset)
    }
}