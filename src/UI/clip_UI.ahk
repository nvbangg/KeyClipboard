showClipboard(useSavedTab := false) {
    global historyTab, savedTab, clipGuiInstance, historyLV, savedLV, historyViewer, savedViewer, tabs
    global clipGuiActivated := false

    if (!checkClipInstance())
        return

    clipGui := Gui("+E0x08000000 +AlwaysOnTop", "Clipboard Manager")
    clipGuiInstance := clipGui
    clipGui.SetFont("s10")

    tabs := clipGui.Add("Tab3", "x5 y5 w710 h560", ["History", "Saved"])
    SendMessage(0x1329, 2, 0, tabs.hwnd)

    tabs.OnEvent("Change", onTabChange)

    buildTabUI(clipGui, tabs, false)
    buildTabUI(clipGui, tabs, true)

    ; tabs.UseTab() ; no need to call UseTab here

    clipGui.OnEvent("Close", (*) => clipGui.Destroy())
    clipGui.OnEvent("Escape", (*) => clipGui.Destroy())

    HotIfWinActive("ahk_id " . clipGui.Hwnd)

    enterHotkey(*) => execAction("enter", clipGui)
    altUpHotkey(*) => execAction("altUp", clipGui)
    altDownHotkey(*) => execAction("altDown", clipGui)
    ctrlAHotkey(*) => execAction("ctrlA", clipGui)
    deleteHotkey(*) => execAction("delete", clipGui)

    Hotkey "Enter", enterHotkey
    Hotkey "!Up", altUpHotkey
    Hotkey "!Down", altDownHotkey
    Hotkey "^a", ctrlAHotkey
    Hotkey "Delete", deleteHotkey
    HotIf()

    updateLV(historyLV, "", false)
    updateLV(savedLV, "", true)

    ; Set active tab based on parameter
    if (useSavedTab) {
        tabs.Value := 2
        if (savedTab.Length > 0) {
            lastRow := savedLV.GetCount()
            if (lastRow > 0) {
                savedLV.Modify(lastRow, "Select Focus Vis")
                savedLV.Focus()
                updateContent(savedLV, savedViewer, true)
                ; Set a timer to ensure ListView receives focus
                SetTimer(() => savedLV.Focus(), -50)
            }
        } else if (historyTab.Length > 0) {
            lastRow := historyLV.GetCount()
            if (lastRow > 0) {
                historyLV.Modify(lastRow, "Select Focus Vis")
                historyLV.Focus()
                updateContent(historyLV, historyViewer, false)
                ; Set a timer to ensure ListView receives focus
                SetTimer(() => historyLV.Focus(), -50)
            }
        }
    } else if (historyTab.Length > 0) {
        lastRow := historyLV.GetCount()
        if (lastRow > 0) {
            historyLV.Modify(lastRow, "Select Focus Vis")
            historyLV.Focus()
            updateContent(historyLV, historyViewer, false)
            ; Set a timer to ensure ListView receives focus
            SetTimer(() => historyLV.Focus(), -50)
        }
    } else if (savedTab.Length > 0) {
        tabs.Value := 2
        lastRow := savedLV.GetCount()
        if (lastRow > 0) {
            savedLV.Modify(lastRow, "Select Focus Vis")
            savedLV.Focus()
            updateContent(savedLV, savedViewer, true)
            ; Set a timer to ensure ListView receives focus
            SetTimer(() => savedLV.Focus(), -50)
        }
    }

    clipGui.Show("w720 h570")

    ; Focus the active ListView after the GUI is shown
    activeListView := useSavedTab ? savedLV : historyLV
    if (activeListView) {
        ; Use a short delay to ensure GUI is fully rendered before focusing
        SetTimer(() => activeListView.Focus(), -100)
    }
}

showClipboardHelp(*) {
    helpText :=
        "CLIPBOARD HISTORY USAGE GUIDE`n`n" .
        "• Double-click/ Enter: Paste selected items`n" .
        "• Ctrl+Click: Select multiple non-consecutive items`n" .
        "• Shift+Click: Select a range of items`n" .
        "• Ctrl+A: Select all items in the list`n" .
        "• Delete: Delete selected item(s)`n" .
        "• Alt+Up/Down: Move selected item up/down in the list`n" .
        "• Right-click: Show context menu with more options`n`n"

    showInfo("Clipboard Help", helpText, 350)
}

showContextMenu(LV, clipGui, Item, X, Y, useSavedTab := false) {
    if (Item = 0)
        return

    global historyViewer, savedViewer
    contentViewer := useSavedTab ? savedViewer : historyViewer

    ; Ensure LV is focused before showing the context menu
    LV.Focus()

    ; Preserve selection state by ensuring selected items remain focused
    selectedIndex := []
    rowNum := 0
    loop {
        rowNum := LV.GetNext(rowNum)
        if (!rowNum)
            break
        selectedIndex.Push(rowNum)
    }

    ; Re-apply Select and Focus to all selected items
    for _, rowNum in selectedIndex {
        LV.Modify(rowNum, "Select Focus")
    }

    CoordMode("Mouse", "Screen")
    MouseGetPos(&mouseX, &mouseY)

    menuItems := [
        ["Paste", (*) => (pasteSelected(LV, clipGui, 0, useSavedTab))],
        ["Paste with Format", (*) => (pasteSelected(LV, clipGui, 1, useSavedTab))],
        ["Paste as Original", (*) => (pasteSelected(LV, clipGui, -1, useSavedTab))]
    ]

    if (!useSavedTab) {
        menuItems.Push([])
        menuItems.Push(["Save to Saved Tab", (*) => (saveToSavedItems(LV))])
        menuItems.Push(["Save Format to Clipboard", (*) => (saveToClipboard(LV, true))])
    }

    menuItems.Push([])
    menuItems.Push(["Delete Item", (*) => deleteSelected(LV, clipGui, useSavedTab)])

    contextMenu := createContextMenu(menuItems)

    CoordMode("Menu", "Screen")
    contextMenu.Show(mouseX, mouseY)
}

buildTabUI(clipGui, tabs, useSavedTab) {
    global historyLV, savedLV, historyViewer, savedViewer

    tabs.UseTab(useSavedTab ? 2 : 1)
    selectAllBtn := clipGui.Add("Button", "x10 y35 w70", "Select All")
    clipGui.Add("Text", "x90 y40", "Search:")
    searchBox := clipGui.Add("Edit", "x150 y37 w560")

    listView := clipGui.Add("ListView", "x10 y70 w700 h270 Grid Multi", ["#", "Content"])
    listView.ModifyCol(1, 50, "Integer")
    listView.ModifyCol(2, 645)

    contentViewer := clipGui.Add("Edit", "x10 y350 w700 h170 VScroll +Wrap", "")

    if (!useSavedTab) {
        historyLV := listView
        historyViewer := contentViewer
    } else {
        savedLV := listView
        savedViewer := contentViewer
    }

    searchBox.OnEvent("Change", (*) => handleSearch(searchBox, useSavedTab))
    selectAllBtn.OnEvent("Click", (*) => selectAllItems(listView, contentViewer))

    listView.OnEvent("ContextMenu", (LV, Item, IsRightClick, X, Y) =>
        showContextMenu(LV, clipGui, Item, X, Y, useSavedTab))

    listViewClickHandler(*) {
        if (!listView || !listView.Hwnd) {
            return
        }
        try {
            WinActivate("ahk_id " . clipGui.Hwnd)
            listView.Focus()
            Sleep(10)
            updateContent(listView, contentViewer, useSavedTab)
        } catch Error as e {

        }
    }
    listView.OnEvent("Click", listViewClickHandler)

    itemSelectHandler(*) {
        if (!listView || !listView.Hwnd) {
            return
        }
        try {
            WinActivate("ahk_id " . clipGui.Hwnd)
            updateContent(listView, contentViewer, useSavedTab)
        } catch Error as e {

        }
    }
    listView.OnEvent("ItemSelect", itemSelectHandler)

    itemFocusHandler(*) {
        if (!listView || !listView.Hwnd) {
            return
        }
        try {
            WinActivate("ahk_id " . clipGui.Hwnd)
            updateContent(listView, contentViewer, useSavedTab)
        } catch Error as e {

        }
    }
    listView.OnEvent("ItemFocus", itemFocusHandler)

    doubleClickHandler(*) {
        if (!listView || !listView.Hwnd) {
            return
        }
        try {
            WinActivate("ahk_id " . clipGui.Hwnd)
            pasteSelected(listView, clipGui, 0, useSavedTab)
        } catch Error as e {

        }
    }
    listView.OnEvent("DoubleClick", doubleClickHandler)

    contentViewer.OnEvent("Focus", FocusCallback)
    FocusCallback(*) {
        WinActivate("ahk_id " . clipGui.Hwnd)
        updateContentViewerFocusState(true)
    }

    contentViewer.OnEvent("LoseFocus", (*) => updateContentViewerFocusState(false))
    actionBtns := [
        ["x150 y530 w120", "Save/Reload", (*) => saveContent(listView, contentViewer, clipGui, useSavedTab)]
    ]

    ; Clear All button with different behavior for History vs Saved tab
    if (useSavedTab) {
        actionBtns.Push(["x280 y530 w120", "Clear All", (*) => clearClipboard(clipGui, true)])
    } else {
        actionBtns.Push(["x280 y530 w120", "Clear All", (*) => clearClipboard(clipGui, false)])
    }

    actionBtns.Push(["x410 y530 w120", "Help", (*) => showClipboardHelp()])

    for option in actionBtns {
        btn := clipGui.Add("Button", option[1], option[2])
        btn.OnEvent("Click", option[3])
    }
}
