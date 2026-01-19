#Include UI_utils.ahk
#Include ../clipboard/actions.ahk
#Include ../clipboard/TabUtils.ahk
#Include ../clipboard/clip_utils.ahk
#Include ../clipboard/format.ahk
#Include ../clipboard/clip_storage.ahk
#Include ../clipboard/paste.ahk

showClipboard(useSaved := false) {
    global history, saved, clipGuiInstance, tabs
    global clipGuiActivated := false
    global historyLV, savedLV, historyViewer, savedViewer

    if (history.Length < 1 && saved.Length < 1) {
        showMsg("History empty")
        return false
    }

    destroyGui(clipGuiInstance)
    clipGui := Gui("+E0x08000000 +AlwaysOnTop", "Clipboard Manager")
    clipGuiInstance := clipGui
    clipGui.SetFont("s10")
    tabs := clipGui.Add("Tab3", "x5 y5 w710 h560", ["History", "Saved"])
    SendMessage(0x1329, 2, 0, tabs.hwnd)  ; Set tab size
    tabs.OnEvent("Change", onTabChange)

    viewers := buildTab(clipGui, tabs, false)
    historyLV := viewers.listView
    historyViewer := viewers.viewer

    viewers := buildTab(clipGui, tabs, true)
    savedLV := viewers.listView
    savedViewer := viewers.viewer

    setupEvents(clipGui)
    setActiveTab(useSaved)

    clipGui.Show("w720 h570")
    SetTimer(focusListView.Bind(useSaved), -100)

    setupEvents(clipGui) {
        HotIfWinActive("ahk_id " . clipGui.Hwnd)  ; Apply hotkeys only when clipboard window is active

        Hotkey "Enter", (*) => execAction("enter", clipGui)
        Hotkey "+Enter", (*) => execAction("shiftEnter", clipGui)
        Hotkey "^Enter", (*) => execAction("ctrlEnter", clipGui)
        Hotkey "!Up", (*) => execAction("altUp", clipGui)
        Hotkey "!Down", (*) => execAction("altDown", clipGui)
        Hotkey "^a", (*) => execAction("ctrlA", clipGui)
        Hotkey "^s", (*) => execAction("ctrlS", clipGui)
        Hotkey "Delete", (*) => execAction("delete", clipGui)
        Hotkey "Escape", (*) => clipGui.Destroy()

        HotIf()
    }

    setActiveTab(useSaved) {
        global history, saved, historyLV, savedLV, historyViewer, savedViewer, tabs
        loadSavedItems()

        updateLV(historyLV, "", false)
        updateLV(savedLV, "", true)

        if (useSaved && saved.Length > 0) {
            tabs.Value := 2
            SetTimer(() => focusLastItem(savedLV, true), -50)
        } else if (history.Length > 0) {
            tabs.Value := 1
            SetTimer(() => focusLastItem(historyLV, false), -50)
        } else if (saved.Length > 0) {
            tabs.Value := 2
            SetTimer(() => focusLastItem(savedLV, true), -50)
        }
    }

    onTabChange(ctrl, *) {
        global clipGuiInstance
        try {
            updateTab(ctrl.Value, IsObject(clipGuiInstance) ? clipGuiInstance.Hwnd : 0)
        } catch {
        }
    }

    updateTab(tabIndex, clipGuiHwnd) {
        global historyLV, savedLV, historyViewer, savedViewer
        if (!WinExist("ahk_id " . clipGuiHwnd))
            return

        try {
            loadSavedItems()
            elements := getTabElements({ Value: tabIndex })
            if (IsObject(elements.listView) && elements.listView.HasProp("GetCount")) {
                updateLV(elements.listView, "", elements.isSaved)
                focusLastItem(elements.listView, elements.isSaved)
            }
        } catch {
        }
    }

    focusListView(useSaved) {
        global historyLV, savedLV, historyViewer, savedViewer, clipGuiInstance

        try {
            if (!clipGuiInstance || !clipGuiInstance.Hwnd || !WinExist("ahk_id " . clipGuiInstance.Hwnd))
                return

            targetLV := useSaved ? savedLV : historyLV
            targetViewer := useSaved ? savedViewer : historyViewer

            if (IsObject(targetLV) && targetLV.HasProp("Focus") && WinExist("ahk_id " . clipGuiInstance.Hwnd)) {
                WinActivate("ahk_id " . clipGuiInstance.Hwnd)
                Sleep(10)
                focusLastItem(targetLV, useSaved)
            }
        } catch {
        }
    }

}

showHelp(*) {
    text :=
        "CLIPBOARD HISTORY USAGE GUIDE`n`n" .
        "• Double-click/ Enter: Paste selected items`n" .
        "• Shift+Enter: Paste format (History only)`n" .
        "• Ctrl+Enter: Paste original (History only)`n" .
        "• Shift+Click: Select a range of items`n" .
        "• Ctrl+Click: Select multiple non-consecutive items`n" .
        "• Ctrl+A: Select all items in the list`n`n" .
        "• Delete: Delete selected item(s)`n" .
        "• Alt+Up/Down: Move selected items up/down in the list`n" .
        "• Click/double-click column header to sort`n" .
        "• Ctrl+Tab: switch between open tabs`n" .
        "• Ctrl+S: save the current content being edited`n" .
        "• Right-click: Show context menu with more options`n`n"

    MsgBox(text, "Clipboard Help", "OK 262144")
}

showMenu(LV, clipGui, Item, useSaved := false) {
    if (Item = 0)  ; No item clicked
        return
    LV.Focus()
    selectedIndex := []
    rowNum := 0
    loop {
        rowNum := LV.GetNext(rowNum)
        if (!rowNum)
            break
        selectedIndex.Push(rowNum)
    }

    for _, rowNum in selectedIndex
        LV.Modify(rowNum, "Select Focus")
    CoordMode("Mouse", "Screen")
    MouseGetPos(&mouseX, &mouseY)

    hasMultipleSelection := selectedIndex.Length > 1
    menuItems := []
    if (hasMultipleSelection) {
        pasteSubmenu := []
        pasteSubmenu.Push(["Paste", (*) => (pasteSelected(LV, clipGui, 0, useSaved))])
        pasteSubmenu.Push(["Paste with Tab", (*) => (pasteWithSeparator("{Tab}", "tabDelay", LV, clipGui, 0, useSaved))])
        pasteSubmenu.Push(["Paste with Enter", (*) => (pasteWithSeparator("{Enter}", "enterDelay", LV, clipGui, 0,
            useSaved))])
        menuItems.Push(["Paste", "", pasteSubmenu])

        pasteFormatSubmenu := []
        pasteFormatSubmenu.Push(["Paste Format", (*) => (pasteSelected(LV, clipGui, 1, useSaved))])
        pasteFormatSubmenu.Push(["Paste Format with Tab", (*) => (pasteWithSeparator("{Tab}", "tabDelay", LV, clipGui,
            1, useSaved))])
        pasteFormatSubmenu.Push(["Paste Format with Enter", (*) => (pasteWithSeparator("{Enter}", "enterDelay", LV,
            clipGui, 1, useSaved))])
        menuItems.Push(["Paste Format", "", pasteFormatSubmenu])

        if (!useSaved) {
            pasteOriginalSubmenu := []
            pasteOriginalSubmenu.Push(["Paste Original", (*) => (pasteSelected(LV, clipGui, -1, useSaved))])
            pasteOriginalSubmenu.Push(["Paste Original with Tab", (*) => (pasteWithSeparator("{Tab}", "tabDelay", LV,
                clipGui, -1,
                useSaved))])
            pasteOriginalSubmenu.Push(["Paste Original with Enter", (*) => (pasteWithSeparator("{Enter}", "enterDelay",
                LV, clipGui, -1,
                useSaved))])
            menuItems.Push(["Paste Original", "", pasteOriginalSubmenu])
        }
    } else {
        menuItems.Push(["Paste", (*) => (pasteSelected(LV, clipGui, 0, useSaved))])
        menuItems.Push(["Paste Format", (*) => (pasteSelected(LV, clipGui, 1, useSaved))])
        if (!useSaved)
            menuItems.Push(["Paste Original", (*) => (pasteSelected(LV, clipGui, -1, useSaved))])
    }

    menuItems.Push([])
    if (!useSaved) {
        selectedIndex := getSelectedIndex(LV)
        pinState := getPinState(selectedIndex)
        if (pinState = "unpinned")
            menuItems.Push(["Pin", (*) => setPinState(LV, true)])
        else
            menuItems.Push(["Unpin", (*) => setPinState(LV, false)])

        menuItems.Push(["Add to Saved", (*) => addToTab(LV, true)])
        addHistorySubmenu := []
        addHistorySubmenu.Push(["Add to History", (*) => (saveToClipboard(LV, false))])
        addHistorySubmenu.Push(["Add Format to History", (*) => (saveToClipboard(LV, true))])
        addHistorySubmenu.Push(["Add Split by Lines", (*) => splitToLines(LV)])
        addHistorySubmenu.Push(["Replace with Format", (*) => replaceWithFormat(LV)])
        menuItems.Push(["Add to History", "", addHistorySubmenu])
    } else {
        menuItems.Push(["Add to History", (*) => addToTab(LV, false)])
    }
    menuItems.Push([])
    sortSubmenu := []
    sortSubmenu.Push(["Move to Top", (*) => moveToTop(LV, useSaved)])
    sortSubmenu.Push(["Move to Bottom", (*) => moveToBottom(LV, useSaved)])
    if (selectedIndex.Length > 1)
        sortSubmenu.Push(["Reverse Order", (*) => reverseOrder(LV, useSaved)])
    menuItems.Push(["Sort Items", "", sortSubmenu])
    menuItems.Push(["Delete Item", (*) => deleteSelected(LV, clipGui, useSaved)])
    menuItems.Push(["Delete Others", (*) => deleteOthers(LV, useSaved)])

    contextMenu := createMenu(menuItems)
    CoordMode("Menu", "Screen")
    contextMenu.Show(mouseX, mouseY)

    createMenu(menuItems) {
        contextMenu := Menu()
        for item in menuItems {
            if (item.Length = 0)
                contextMenu.Add()
            else if (item.Length = 3 && IsObject(item[3])) {
                submenu := Menu()
                for subitem in item[3] {
                    if (subitem.Length = 0)
                        submenu.Add()
                    else
                        submenu.Add(subitem[1], subitem[2])
                }
                contextMenu.Add(item[1], submenu)
            } else
                contextMenu.Add(item[1], item[2])
        }
        return contextMenu
    }
}

buildTab(clipGui, tabs, useSaved) {
    tabs.UseTab(useSaved ? 2 : 1)

    selectAllBtn := clipGui.Add("Button", "x10 y35 w70", "Select All")
    if (!useSaved) {
        selectPinnedBtn := clipGui.Add("Button", "x90 y35 w100", "Select Pinned")
        clipGui.Add("Text", "x200 y42", "Search:")
        searchBox := clipGui.Add("Edit", "x250 y37 w485")
    } else {
        clipGui.Add("Text", "x90 y42", "Search:")
        searchBox := clipGui.Add("Edit", "x150 y37 w560")
    }
    listView := clipGui.Add("ListView", "x10 y70 w700 h270 Grid Multi", ["#", "Content"])
    listView.ModifyCol(1, 45, "Index")  ; Index column
    listView.ModifyCol(2, 645)          ; Content column

    localViewer := clipGui.Add("Edit", "x10 y350 w700 h170 VScroll +Wrap", "")

    searchBox.OnEvent("Focus", SearchBoxFocusHandler)
    searchBox.OnEvent("Change", (*) => search(searchBox, useSaved))
    selectAllBtn.OnEvent("Click", (*) => selectAllItems(listView))
    if (!useSaved)
        selectPinnedBtn.OnEvent("Click", (*) => selectPinnedItems(listView))
    listView.OnEvent("ContextMenu", ContextMenuHandler)
    listView.OnEvent("Click", LVClickHandler)
    listView.OnEvent("DoubleClick", DoubleClickHandler)

    actionBtns := [
        ["x150 y530 w120", "Save/Create", (*) => saveContent(listView, clipGui, useSaved)]
    ]
    if (useSaved)
        actionBtns.Push(["x280 y530 w120", "Clear All", (*) => clearClipboard(clipGui, true)])
    else
        actionBtns.Push(["x280 y530 w120", "Clear All", (*) => clearClipboard(clipGui, false)])
    actionBtns.Push(["x410 y530 w120", "Help", (*) => showHelp()])
    for option in actionBtns {
        btn := clipGui.Add("Button", option[1], option[2])
        btn.OnEvent("Click", option[3])
    }

    SearchBoxFocusHandler(*) {
        WinActivate("ahk_id " . clipGui.Hwnd)
        searchBox.Focus()
    }

    LVClickHandler(*) {
        if (!isValidGuiControl(listView, "GetNext"))
            return
        try {
            WinActivate("ahk_id " . clipGui.Hwnd)
            listView.Focus()
            updateViewer(useSaved)
        } catch {
        }
    }

    ContextMenuHandler(LV, Item, IsRightClick, X, Y) {
        if (!isValidGuiControl(listView, "GetNext"))
            return

        try {
            updateViewer(useSaved)
            showMenu(LV, clipGui, Item, useSaved)
        } catch {
        }
    }

    DoubleClickHandler(*) {
        if (!isValidGuiControl(listView, "GetNext"))
            return

        try {
            WinActivate("ahk_id " . clipGui.Hwnd)
            pasteSelected(listView, clipGui, 0, useSaved)
        } catch {
        }
    }

    return { listView: listView, viewer: localViewer }
}
