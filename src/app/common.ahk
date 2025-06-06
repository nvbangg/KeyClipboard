; Ensure settings file exists, creating it if necessary
existFile(filePath) {
    if !DirExist(dataDir) {
        DirCreate(dataDir)
    }
    if !FileExist(filePath) {
        FileAppend("", filePath)
    }
}

readSetting(section, key, defaultValue) {
    static settings := Map() ; Cache settings for performance
    fullKey := section . "_" . key

    if (!settings.Has(fullKey)) {
        settings[fullKey] := IniRead(settingsFilePath, section, key, defaultValue)
    }
    return settings[fullKey]
}

writeSetting(section, key, value) {
    global settingsFilePath
    IniWrite(value, settingsFilePath, section, key)
}

showNotification(message, timeout := 1300) {
    notify := Gui("+AlwaysOnTop -Caption +ToolWindow")
    notify.SetFont("s12 bold")
    notify.Add("Text", "w300 Center", message)
    notify.Show("NoActivate")
    SetTimer(() => notify.Destroy(), -timeout)
}

cleanupGui(guiObj) {
    if IsObject(guiObj) {
        guiObj.Destroy()
        return 0
    }
    return guiObj
}

; Setup standard close events (Escape key and X button)
closeEvents(guiObj, closeCallback) {
    guiObj.OnEvent("Escape", closeCallback)
    guiObj.OnEvent("Close", closeCallback)
}

; Show information dialog with auto-sized content
showInfo(title, content, width := 350, btnOpts := "") {
    static activeDialog := 0

    if (activateExistingGui(activeDialog))
        return activeDialog

    infoGui := Gui("+AlwaysOnTop +ToolWindow", title)
    activeDialog := infoGui

    infoGui.SetFont("s10")
    textControl := infoGui.Add("Text", "w" . width, content)
    textControl.GetPos(, , , &textHeight)

    buttonY := textHeight + 20

    if (btnOpts = "") {
        buttonX := width / 2 - 50
        btnOpts := "w100 x" . buttonX . " y" . buttonY
    }

    CleanupDialog(gui, *) {
        static dialogRef := &activeDialog
        %dialogRef% := 0
        gui.Destroy()
    }

    infoGui.Add("Button", btnOpts . " Default", "OK").OnEvent("Click", CleanupDialog.Bind(infoGui))
    infoGui.OnEvent("Escape", CleanupDialog.Bind(infoGui))
    infoGui.OnEvent("Close", CleanupDialog.Bind(infoGui))

    windowHeight := buttonY + 40
    infoGui.Show("w" . (width + 20) . " h" . windowHeight)
    return infoGui
}

isGuiValid(guiObj) {
    try {
        return IsObject(guiObj) && guiObj.HasProp("Hwnd") && WinExist("ahk_id " . guiObj.Hwnd)
    } catch {
        return false
    }
}

activateExistingGui(guiObj) {
    if (isGuiValid(guiObj)) {
        hwnd := guiObj.Hwnd
        WinActivate("ahk_id " . hwnd)
        return true
    }
    return false
}

destroyGui(guiObj) {
    if (isGuiValid(guiObj)) {
        guiObj.Destroy()
        return true
    }
    return false
}

CreateNewPreset(settingsGui := 0) {
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
        } else {
            showNotification("Please enter a preset name")
        }
    }
}

DeleteCurrentPreset(dropdown, settingsGui := 0) {
    presetToDelete := dropdown.Text

    if (presetToDelete = "Default") {
        showNotification("Cannot delete the Default preset")
        return
    }
    result := MsgBox("Are you sure you want to delete preset '" . presetToDelete . "'?",
        "Confirm Delete", "YesNo 262144")

    if (result = "Yes") {
        deletePreset(presetToDelete)
        if (isGuiValid(settingsGui))
            destroyGui(settingsGui)
        showSettings()
    }
}

loadPresetList() {
    global presetList := []
    presetString := readSetting("Presets", "PresetList", "")
    if (presetString != "") {
        presetNames := StrSplit(presetString, ",")
        for _, name in presetNames {
            if (name != "")
                presetList.Push(name)
        }
    }
}

saveToCurrentPreset() {
    global currentPreset
    if (currentPreset != "") {
        savePresetSettings("Preset_" . currentPreset)
        writeSetting("Presets", "CurrentPreset", currentPreset)
    }
}

HasValue(arr, val) {
    for i, v in arr {
        if (v = val)
            return true
    }
    return false
}

Join(arr, delimiter) {
    result := ""
    for i, v in arr {
        if (i > 1)
            result .= delimiter
        result .= v
    }
    return result
}

deletePreset(presetName) {
    global presetList, currentPreset

    if (!HasValue(presetList, presetName)) {
        showNotification("Preset '" . presetName . "' not found")
        return
    }
    if (presetName = "Default") {
        showNotification("Cannot delete the Default preset")
        return
    }
    sectionName := "Preset_" . presetName
    IniDelete(settingsFilePath, sectionName)

    newPresetList := []
    for _, name in presetList {
        if (name != presetName)
            newPresetList.Push(name)
    }
    presetList := newPresetList
    writeSetting("Presets", "PresetList", Join(presetList, ","))
    if (currentPreset = presetName) {
        currentPreset := "Default"
        writeSetting("Presets", "CurrentPreset", "Default")
        loadPreset("Default")
    }

    showNotification("Preset '" . presetName . "' deleted")
}

switchTabPreset() {
    global presetList, currentPreset

    if (presetList.Length < 2) {
        showNotification("Only one preset available")
        return
    }

    currentIndex := 0
    for i, name in presetList {
        if (name = currentPreset) {
            currentIndex := i
            break
        }
    }

    if (currentIndex = 0 || currentIndex = presetList.Length) {
        nextIndex := 1
    } else {
        nextIndex := currentIndex + 1
    }

    nextPreset := presetList[nextIndex]
    loadPreset(nextPreset, true)
    showNotification("Switched to preset: " . nextPreset)
}

getMaxHistoryIndex(value) {
    switch value {
        case 50: return 1
        case 100: return 2
        case 200: return 3
        case 500: return 4
        case 1000: return 5
        default: return 2  ; Default to 100
    }
}

AddCheckboxGroup(gui, yPos, options) {
    for option in options {
        gui.Add("CheckBox", "x20 y" . yPos . " v" . option[1] . " Checked" . option[2], option[3])
        yPos += 25
    }
    return yPos + 10
}

AddDropdownGroup(gui, yPos, options) {
    for option in options {
        gui.Add("Text", "x20 y" . yPos . " w150", option[1])
        gui.Add("DropDownList", "x160 y" . (yPos - 3) . " w180 AltSubmit v" . option[2] . " Choose" . (
            option[4] + 1), option[3])
        yPos += 30
    }
    return yPos
}
