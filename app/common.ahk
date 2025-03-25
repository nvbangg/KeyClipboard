; === COMMON MODULE ===

existFile(filePath) {
    if !DirExist(dataDir) {
        DirCreate(dataDir)
    }
    if !FileExist(settingsFilePath) {
        FileAppend("", settingsFilePath)
    }
}

readSetting(section, key, defaultValue) {
    static settings := Map() ; Use a static map to cache settings
    fullKey := section . "_" . key ; Create a unique key

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

; Common GUI cleanup function
cleanupGui(guiObj) {
    if IsObject(guiObj) {
        guiObj.Destroy()
        return 0
    }
    return guiObj
}

; Common function to setup GUI events
closeEvents(guiObj, closeCallback) {
    guiObj.OnEvent("Escape", closeCallback)
    guiObj.OnEvent("Close", closeCallback)
}

; Creates a standard information dialog with OK button
createInfoDialog(title, content, width := 350, btnOpts := "") {
    static activeDialog := 0

    ; If we already have an active dialog
    if (IsObject(activeDialog)) {
        ; Check if the dialog still exists
        try {
            hwnd := activeDialog.Hwnd
            ; If it exists, bring it to the front
            WinActivate("ahk_id " hwnd)
            return activeDialog
        } catch {
            ; Dialog was destroyed externally, create a new one
            activeDialog := 0
        }
    }

    ; Create a new dialog
    infoGui := Gui("+AlwaysOnTop +ToolWindow", title)
    activeDialog := infoGui  ; Store reference to the new dialog

    infoGui.SetFont("s10")
    textControl := infoGui.Add("Text", "w" . width, content)
    textControl.GetPos(, , , &textHeight)

    buttonY := textHeight + 20

    if (btnOpts = "") {
        buttonX := width / 2 - 50  ; Button width is 100, center it
        btnOpts := "w100 x" . buttonX . " y" . buttonY
    }

    ; A helper function that will be called to clean up
    CleanupDialog(gui, *) {
        static dialogRef := &activeDialog
        %dialogRef% := 0  ; Access and modify the static variable reference
        gui.Destroy()
    }

    infoGui.Add("Button", btnOpts . " Default", "OK").OnEvent("Click", CleanupDialog.Bind(infoGui))
    infoGui.OnEvent("Escape", CleanupDialog.Bind(infoGui))
    infoGui.OnEvent("Close", CleanupDialog.Bind(infoGui))

    windowHeight := buttonY + 40  ; Add padding for button and borders
    infoGui.Show("w" . (width + 20) . " h" . windowHeight)
    return infoGui
}

; Creates a context menu from an array of menu items
createContextMenu(menuItems) {
    contextMenu := Menu()

    for item in menuItems {
        if (item.Length = 0)
            contextMenu.Add()  ; Add separator
        else
            contextMenu.Add(item[1], item[2])  ; Add label and callback
    }

    return contextMenu
}
