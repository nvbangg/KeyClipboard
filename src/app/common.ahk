existFile(filePath) {
    if !DirExist(dataDir) {
        DirCreate(dataDir)
    }
    if !FileExist(settingsFilePath) {
        FileAppend("", settingsFilePath)
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

showNotification(message, timeout := 1200) {
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

closeEvents(guiObj, closeCallback) {
    guiObj.OnEvent("Escape", closeCallback)
    guiObj.OnEvent("Close", closeCallback)
}

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

    ; Helper to properly clean up dialog references
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
