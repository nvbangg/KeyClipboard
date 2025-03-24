; === CLIP_UI MODULE ===

addClipSettings(settingsGui, yPos) {
    settingsGui.Add("GroupBox", "x10 y" . yPos . " w350 h200", "Format Options")
    yPos += 25
    settingsGui.Add("CheckBox", "x20 y" . yPos . " vremoveAccentsEnabled Checked" . removeAccentsEnabled,
        "Remove Accents")
    yPos += 25
    settingsGui.Add("CheckBox", "x20 y" . yPos . " vnormSpaceEnabled Checked" . normSpaceEnabled,
        "Normalize Spaces")
    yPos += 25
    settingsGui.Add("CheckBox", "x20 y" . yPos . " vremoveSpecialEnabled Checked" . removeSpecialEnabled,
        "Remove Special Characters (# *)")
    yPos += 35

    ; Text formatting options
    settingsGui.Add("Text", "x20 y" . yPos . " w150", "Line Break:")
    lineChoices := ["None", "Trim Lines", "Remove All Line Breaks"]
    settingsGui.Add("DropDownList", "x160 y" . (yPos - 3) . " w180 AltSubmit vlineOption Choose" . (
        lineOption + 1),
    lineChoices)
    yPos += 30

    settingsGui.Add("Text", "x20 y" . yPos . " w150", "Text Case:")
    caseChoices := ["None", "UPPERCASE", "lowercase", "Title Case", "Sentence case"]
    settingsGui.Add("DropDownList", "x160 y" . (yPos - 3) . " w180 AltSubmit vcaseOption Choose" . (caseOption +
        1),
    caseChoices)
    yPos += 30

    settingsGui.Add("Text", "x20 y" . yPos . " w150", "Word Separator:")
    separatorChoices := ["None", "Underscore (_)", "Hyphen (-)", "Remove Spaces"]
    settingsGui.Add("DropDownList", "x160 y" . (yPos - 3) . " w180 AltSubmit vseparatorOption Choose" . (
        separatorOption + 1),
    separatorChoices)
    yPos += 30

    return yPos + 15
}

showClipboard() {
    global historyTab, savedTab, clipGuiInstance

    ; Check if both clipHistory and savedItems are empty before creating GUI
    if (historyTab.Length < 1 && savedTab.Length < 1) {
        showNotification("No items in clipboard history")
        return
    }

    try {
        if (IsObject(clipGuiInstance) && clipGuiInstance.HasProp("Hwnd") && WinExist("ahk_id " .
            clipGuiInstance.Hwnd)) {
            clipGuiInstance.Destroy()
        }
    } catch {
        clipGuiInstance := 0
    }

    ; Always create GUI since we've verified there's at least one item
    clipGui := Gui(, "Clipboard Manager")
    clipGuiInstance := clipGui
    clipGui.SetFont("s10")

    ; Add tabs for History and Saved with equal width
    tabs := clipGui.Add("Tab3", "x5 y5 w710 h560", ["History", "Saved"])

    ; Set equal width for both tabs
    SendMessage(0x1329, 2, 0, tabs.hwnd)  ; TCM_SETMINTABWIDTH = 0x1329

    ; Add tab change event handler to reload data
    tabs.OnEvent("Change", onTabChange)

    ; --- History Tab ---
    tabs.UseTab(1)

    ; Add Select All button and search box
    selectAllBtn := clipGui.Add("Button", "x10 y35 w70", "Select All")
    clipGui.Add("Text", "x90 y40", "Search:")
    searchBox := clipGui.Add("Edit", "x150 y37 w560")
    searchBox.OnEvent("Change", onSearchChange)

    ; Create ListView for clipboard items
    historyLV := clipGui.Add("ListView", "x10 y70 w700 h270 Grid Multi", ["#", "Content"])
    historyLV.ModifyCol(1, 50, "Integer")
    historyLV.ModifyCol(2, 640)

    ; Add event handler for Select All button
    selectAllBtn.OnEvent("Click", (*) => selectAllItems(historyLV, historyViewer))

    historyLV.OnEvent("ContextMenu", (LV, Item, IsRightClick, X, Y) =>
        showContextMenu(LV, clipGui, Item, X, Y, false)) ; false = clipboard tab

    historyViewer := clipGui.Add("Edit", "x10 y350 w700 h170 VScroll HScroll", "")
    historyLV.OnEvent("ItemSelect", (LV, *) => updateContent(LV, historyViewer, false))
    historyLV.OnEvent("ItemFocus", (LV, *) => updateContent(LV, historyViewer, false))
    historyLV.OnEvent("DoubleClick", (*) => pasteSelected(historyLV, clipGui, 0, false))

    ; Add history tab action buttons
    historyBtns := [
        ["x150 y530 w120", "Save/Reload", (*) => saveContent(historyLV, historyViewer, clipGui, false)],
        ["x280 y530 w120", "Clear All", (*) => clearClipboard(clipGui, false)],
        ["x410 y530 w120", "Help", (*) => showClipboardHelp()]
    ]

    for option in historyBtns
        clipGui.Add("Button", option[1], option[2]).OnEvent("Click", option[3])

    ; --- Saved Items Tab ---
    tabs.UseTab(2)

    ; Add Select All button and search box for saved items
    savedSelectAllBtn := clipGui.Add("Button", "x10 y35 w70", "Select All")
    clipGui.Add("Text", "x90 y40", "Search:")
    savedSearchBox := clipGui.Add("Edit", "x150 y37 w560")
    savedSearchBox.OnEvent("Change", onSavedSearchChange)

    ; Create ListView for saved items
    savedLV := clipGui.Add("ListView", "x10 y70 w700 h270 Grid Multi", ["#", "Content"])
    savedLV.ModifyCol(1, 50, "Integer")
    savedLV.ModifyCol(2, 640)

    ; Add event handler for Select All button
    savedSelectAllBtn.OnEvent("Click", (*) => selectAllItems(savedLV, savedViewer))

    savedLV.OnEvent("ContextMenu", (LV, Item, IsRightClick, X, Y) =>
        showContextMenu(LV, clipGui, Item, X, Y, true)) ; true = saved items tab

    savedViewer := clipGui.Add("Edit", "x10 y350 w700 h170 VScroll HScroll", "")
    savedLV.OnEvent("ItemSelect", (LV, *) => updateContent(LV, savedViewer, true))
    savedLV.OnEvent("ItemFocus", (LV, *) => updateContent(LV, savedViewer, true))
    savedLV.OnEvent("DoubleClick", (*) => pasteSelected(savedLV, clipGui, 0, true))

    ; Add saved items tab action buttons
    savedBtns := [
        ["x150 y530 w120", "Save/Reload", (*) => saveContent(savedLV, savedViewer, clipGui, true)],
        ["x280 y530 w120", "Clear All", (*) => clearClipboard(clipGui, true)],
        ["x410 y530 w120", "Help", (*) => showClipboardHelp()]
    ]

    for option in savedBtns
        clipGui.Add("Button", option[1], option[2]).OnEvent("Click", option[3])

    ; Reset to first tab
    tabs.UseTab()

    clipGui.OnEvent("Close", (*) => clipGui.Destroy())
    clipGui.OnEvent("Escape", (*) => clipGui.Destroy())

    ; Special hotkeys when clipboard history is active
    HotIfWinActive("ahk_id " . clipGui.Hwnd)

    ; Define the hotkey handler functions
    enterHotkey(*) {
        if (tabs.Value = 1) {
            if (isListViewFocused())
                pasteSelected(historyLV, clipGui, 0, false) ; false = clipboard tab
            else
                Send("{Enter}")
        } else {
            if (isListViewFocused())
                pasteSelected(savedLV, clipGui, 0, true) ; true = saved items tab
            else
                Send("{Enter}")
        }
    }

    altUpHotkey(*) {
        if (tabs.Value = 1)
            moveSelectedItem(historyLV, historyViewer, -1, false) ; false = clipboard tab
        else
            moveSelectedItem(savedLV, savedViewer, -1, true) ; true = saved items tab
    }

    altDownHotkey(*) {
        if (tabs.Value = 1)
            moveSelectedItem(historyLV, historyViewer, 1, false) ; false = clipboard tab
        else
            moveSelectedItem(savedLV, savedViewer, 1, true) ; true = saved items tab
    }

    ctrlAHotkey(*) {
        if (tabs.Value = 1)
            selectAllItems(historyLV, historyViewer)
        else
            selectAllItems(savedLV, savedViewer)
    }

    deleteHotkey(*) {
        if (tabs.Value = 1)
            deleteSelected(historyLV, clipGui, false) ; false = clipboard tab
        else
            deleteSelected(savedLV, clipGui, true) ; true = saved items tab
    }

    ; Assign the hotkeys to their functions
    Hotkey "Enter", enterHotkey
    Hotkey "!Up", altUpHotkey
    Hotkey "!Down", altDownHotkey
    Hotkey "^a", ctrlAHotkey
    Hotkey "Delete", deleteHotkey
    HotIf()

    ; Update both ListViews
    updateLV(historyLV, "", false) ; false = clipboard tab
    updateLV(savedLV, "", true)    ; true = saved items tab

    ; Set initial tab based on content availability
    if (historyTab.Length > 0) {
        ; Safely check if historyLV still exists and has items
        try {
            if (IsObject(historyLV) && historyLV.HasProp("GetCount")) {
                lastHistoryRow := historyLV.GetCount()
                if (lastHistoryRow > 0) {
                    historyLV.Modify(lastHistoryRow, "Select Focus Vis")
                    updateContent(historyLV, historyViewer, false)
                }
            }
        } catch {
            ; Handle any errors accessing historyLV
        }

        ; Focus on clipboard history
        SetTimer(() => (IsObject(historyLV) ? historyLV.Focus() : 0), -50)
    } else if (savedTab.Length > 0) {
        tabs.Value := 2  ; Switch to Saved tab

        ; Focus on saved items
        try {
            if (IsObject(savedLV) && savedLV.HasProp("GetCount")) {
                lastSavedRow := savedLV.GetCount()
                if (lastSavedRow > 0) {
                    savedLV.Modify(lastSavedRow, "Select Focus Vis")
                    updateContent(savedLV, savedViewer, true)
                }
            }
        } catch {
            ; Handle any errors accessing savedLV
        }

        SetTimer(() => (IsObject(savedLV) ? savedLV.Focus() : 0), -50)
    }

    clipGui.Show("w720 h570")

    ; Tab change event handler - with safer control access
    onTabChange(ctrl, *) {
        tabValue := ctrl.Value

        ; Make sure the GUI still exists
        if (!WinExist("ahk_id " . clipGui.Hwnd))
            return

        try {
            if (tabValue = 1) {
                ; History tab selected - safely check controls exist first
                if (IsObject(historyLV) && historyLV.HasProp("GetCount")) {
                    updateLV(historyLV, "", false) ; false = clipboard tab
                    lastHistoryRow := historyLV.GetCount()
                    if (lastHistoryRow > 0) {
                        ; Always select and focus the last item
                        historyLV.Modify(lastHistoryRow, "Select Focus Vis")
                        if (IsObject(historyViewer))
                            updateContent(historyLV, historyViewer, false)
                    }
                    SetTimer(() => historyLV.Focus(), -50)
                }
            } else {
                ; Saved items tab selected - safely check controls exist first
                if (IsObject(savedLV) && savedLV.HasProp("GetCount")) {
                    updateLV(savedLV, "", true) ; true = saved items tab
                    lastSavedRow := savedLV.GetCount()
                    if (lastSavedRow > 0) {
                        ; Always select and focus the last item (not just the first)
                        savedLV.Modify(lastSavedRow, "Select Focus Vis")
                        if (IsObject(savedViewer))
                            updateContent(savedLV, savedViewer, true)
                    }
                    SetTimer(() => savedLV.Focus(), -50)
                }
            }
        } catch {
            ; Handle any errors accessing destroyed controls
        }
    }

    ; Handle search functionality
    onSearchChange(searchCtrl, *) {
        searchText := searchCtrl.Value
        updateLV(historyLV, searchText, false) ; false = clipboard tab
        updateContent(historyLV, historyViewer, false)
    }

    onSavedSearchChange(searchCtrl, *) {
        searchText := searchCtrl.Value
        updateLV(savedLV, searchText, true) ; true = saved items tab
        updateContent(savedLV, savedViewer, true)
    }
}

; Show clipboard usage instructions
showClipboardHelp(*) {
    helpGui := Gui("+AlwaysOnTop +ToolWindow", "Clipboard Help")
    helpGui.SetFont("s10")

    helpText :=
        "CLIPBOARD HISTORY USAGE GUIDE`n`n" .
        "• Double-click/ Enter: Paste selected items`n" .
        "• Ctrl+Click: Select multiple non-consecutive items`n" .
        "• Shift+Click: Select a range of items`n" .
        "• Ctrl+A: Select all items in the list`n" .
        "• Delete: Delete selected item(s)`n" .
        "• Alt+Up/Down: Move selected item up/down in the list`n" .
        "• Right-click: Show context menu with more options`n`n"

    helpGui.Add("Text", "w350", helpText)
    helpGui.Add("Button", "w100 x150 y180 Default", "OK").OnEvent("Click", (*) => helpGui.Destroy())

    helpGui.OnEvent("Escape", (*) => helpGui.Destroy())
    helpGui.OnEvent("Close", (*) => helpGui.Destroy())

    helpGui.Show()
}

; Context menu for clipboard and saved items
showContextMenu(LV, clipGui, Item, X, Y, useSavedTab := false) {
    if (Item = 0)
        return

    contentViewer := 0
    try contentViewer := useSavedTab = false ?
        clipGui.FindControl("Edit1") : clipGui.FindControl("Edit2")

    ; Create menu and add items
    contextMenu := Menu()

    ; Use simple arrow functions instead of nested function declarations
    contextMenu.Add("Paste", (*) => (pasteSelected(LV, clipGui, 0, useSavedTab)))
    contextMenu.Add("Paste with Format", (*) => (pasteSelected(LV, clipGui, 1, useSavedTab)))
    contextMenu.Add("Paste as Original", (*) => (pasteSelected(LV, clipGui, -1, useSavedTab)))

    if (!useSavedTab) { ; Only show these options for clipboard tab (not saved tab)
        contextMenu.Add()
        contextMenu.Add("Save to Saved Items", (*) => (saveToSavedItems(LV)))
        contextMenu.Add("Save Format to Clipboard", (*) => (saveToClipboard(LV, true)))
    }

    contextMenu.Add()
    contextMenu.Add("Delete Item", (*) => deleteSelected(LV, clipGui, useSavedTab))

    contextMenu.Show(X, Y)
}
