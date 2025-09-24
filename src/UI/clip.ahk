#Include UI_utils.ahk
#Include ../clipboard/actions.ahk
#Include ../clipboard/TabUtils.ahk
#Include ../clipboard/clip_utils.ahk
#Include ../clipboard/format.ahk
#Include ../clipboard/clip_storage.ahk
#Include ../clipboard/paste.ahk

showClipboard(useSaved := false) {
    global history, saved, clipGuiInstance, historyLV, savedLV, historyViewer, savedViewer, tabs
    global clipGuiActivated := false
    static focusTimer := 0

    if (focusTimer) {
        SetTimer(focusTimer, 0)
        focusTimer := 0
    }
    if (!checkInstance())
        return

    clipGui := Gui("+E0x08000000 +AlwaysOnTop", "Clipboard Manager")
    clipGuiInstance := clipGui
    clipGui.SetFont("s10")
    tabs := clipGui.Add("Tab3", "x5 y5 w710 h560", ["History", "Saved"])
    SendMessage(0x1329, 2, 0, tabs.hwnd)  ; Set tab size
    tabs.OnEvent("Change", onTabChange)

    buildTab(clipGui, tabs, false)
    buildTab(clipGui, tabs, true)
    setupEvents(clipGui)
    setActiveTab(useSaved)

    clipGui.Show("w720 h570")
    focusTimer := SetTimer(focusListView.Bind(useSaved), -100)
}

showHelp(*) {
    text :=
        "CLIPBOARD HISTORY USAGE GUIDE`n`n" .
        "• Double-click/ Enter: Paste selected items`n" .
        "• Ctrl+Click: Select multiple non-consecutive items`n" .
        "• Shift+Click: Select a range of items`n" .
        "• Ctrl+A: Select all items in the list`n" .
        "• Delete: Delete selected item(s)`n" .
        "• Alt+Up/Down: Move selected items up/down in the list`n" .
        "• Click/double-click column header to sort`n" .
        "• Ctrl+Tab: switch between open tabs`n" .
        "• Ctrl+S: save the current content being edited`n" .
        "• Right-click: Show context menu with more options`n`n"

    MsgBox(text, "Clipboard Help", "OK 262144") 
}

showMenu(LV, clipGui, Item, X, Y, useSaved := false) {
    global historyViewer, savedViewer

    if (Item = 0)  ; No item clicked
        return

    viewer := useSaved ? savedViewer : historyViewer
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
        pasteSubmenu.Push(["Paste with Enter", (*) => (pasteWithSeparator("{Enter}", "enterDelay", LV, clipGui, 0, useSaved))])
        menuItems.Push(["Paste", "", pasteSubmenu])

        pasteFormatSubmenu := []
        pasteFormatSubmenu.Push(["Paste Format", (*) => (pasteSelected(LV, clipGui, 1, useSaved))])
        pasteFormatSubmenu.Push(["Paste Format with Tab", (*) => (pasteWithSeparator("{Tab}", "tabDelay", LV, clipGui, 1, useSaved))])
        pasteFormatSubmenu.Push(["Paste Format with Enter", (*) => (pasteWithSeparator("{Enter}", "enterDelay", LV, clipGui, 1, useSaved))])
        menuItems.Push(["Paste Format", "", pasteFormatSubmenu])

        if (!useSaved) {
            pasteOriginalSubmenu := []
            pasteOriginalSubmenu.Push(["Paste Original", (*) => (pasteSelected(LV, clipGui, -1, useSaved))])
            pasteOriginalSubmenu.Push(["Paste Original with Tab", (*) => (pasteWithSeparator("{Tab}", "tabDelay", LV, clipGui, -1,
                useSaved))])
            pasteOriginalSubmenu.Push(["Paste Original with Enter", (*) => (pasteWithSeparator("{Enter}", "enterDelay", LV, clipGui, -1,
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
        menuItems.Push(["Add to History", "", addHistorySubmenu])
        menuItems.Push(["Replace with Format", (*) => replaceWithFormat(LV)])
    } else {
        menuItems.Push(["Add to History", (*) => addToTab(LV, false)])
    }
    menuItems.Push([])
    menuItems.Push(["Delete Item", (*) => deleteSelected(LV, clipGui, useSaved)])
    menuItems.Push(["Delete Others", (*) => deleteOthers(LV, useSaved)])

    contextMenu := createMenu(menuItems)
    CoordMode("Menu", "Screen")
    contextMenu.Show(mouseX, mouseY)
}

buildTab(clipGui, tabs, useSaved) {
    global historyLV, savedLV, historyViewer, savedViewer

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
    listView.ModifyCol(1, 50, "Integer")  ; Index column width
    listView.ModifyCol(2, 645)            ; Content column width

    viewer := clipGui.Add("Edit", "x10 y350 w700 h170 VScroll +Wrap", "")
    if (!useSaved) {
        historyLV := listView
        historyViewer := viewer
    } else {
        savedLV := listView
        savedViewer := viewer
    }

    ; Event handlers for search functionality
    SearchBoxChangeHandler(*) {
        search(searchBox, useSaved)
    }
    SearchBoxFocusHandler(*) {
        WinActivate("ahk_id " . clipGui.Hwnd)
        searchBox.Focus()
    }

    searchBox.OnEvent("Change", SearchBoxChangeHandler)
    searchBox.OnEvent("Focus", SearchBoxFocusHandler)
    selectAllBtn.OnEvent("Click", (*) => selectAllItems(listView, viewer))
    if (!useSaved)
        selectPinnedBtn.OnEvent("Click", (*) => selectPinnedItems(listView, viewer))
    listView.OnEvent("ContextMenu", (LV, Item, IsRightClick, X, Y) =>
        showMenu(LV, clipGui, Item, X, Y, useSaved))

    ListViewClickHandler(*) {
        if (!isValidGuiControl(listView, "GetNext"))
            return
        try {
            WinActivate("ahk_id " . clipGui.Hwnd)
            listView.Focus()
            Sleep(10)
            SetTimer(() => updateViewer(listView, viewer, useSaved), -50)
        } catch {
        }
    }
    listView.OnEvent("Click", ListViewClickHandler)

    ; Handle item selection changes
    ItemSelectHandler(*) {
        if (!isValidGuiControl(listView, "GetNext"))
            return
        try {
            WinActivate("ahk_id " . clipGui.Hwnd)
            SetTimer(() => updateViewer(listView, viewer, useSaved), -50)
        } catch {
        }
    }
    listView.OnEvent("ItemSelect", ItemSelectHandler)

    ItemFocusHandler(*) {
        if (!isValidGuiControl(listView, "GetNext"))
            return
        try {
            WinActivate("ahk_id " . clipGui.Hwnd)
            SetTimer(() => updateViewer(listView, viewer, useSaved), -50)
        } catch {
        }
    }
    listView.OnEvent("ItemFocus", ItemFocusHandler)

    DoubleClickHandler(*) {
        if (!isValidGuiControl(listView, "GetNext"))
            return
        
        try {
            WinActivate("ahk_id " . clipGui.Hwnd)
            pasteSelected(listView, clipGui, 0, useSaved)
        } catch {
        }
    }
    listView.OnEvent("DoubleClick", DoubleClickHandler)

    viewer.OnEvent("Focus", FocusCallback)
    FocusCallback(*) {
        try {
            WinActivate("ahk_id " . clipGui.Hwnd)
            setViewerFocus(true)

            elements := getTabElements(tabs)
            if (!elements.listView || !elements.viewer)
                return
                
            selectedIndex := getSelectedIndex(elements.listView)
            elements.viewer.Opt("-ReadOnly")
        } catch {
        }
    }
    LoseFocusCallback(*) {
        try {
            setViewerFocus(false)
        } catch {
        }
    }
    viewer.OnEvent("LoseFocus", LoseFocusCallback)

    actionBtns := [
        ["x150 y530 w120", "Save/Create", (*) => saveContent(listView, viewer, clipGui, useSaved)]
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
}
