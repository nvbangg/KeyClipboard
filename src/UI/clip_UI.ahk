showClipboard(useSavedTab := false) {
    global historyTab, savedTab, clipGuiInstance, historyLV, savedLV, historyViewer, savedViewer, tabs
    global clipGuiActivated := false
    static focusTimer := 0

    if (focusTimer) {
        SetTimer(focusTimer, 0)
        focusTimer := 0
    }

    if (!checkClipInstance())  
        return

    clipGui := Gui("+E0x08000000 +AlwaysOnTop", "Clipboard Manager")
    clipGuiInstance := clipGui
    clipGui.SetFont("s10")

    ; Create tab control with History and Saved tabs
    tabs := clipGui.Add("Tab3", "x5 y5 w710 h560", ["History", "Saved"])
    SendMessage(0x1329, 2, 0, tabs.hwnd)  ; Set tab size
    tabs.OnEvent("Change", onTabChange)

    buildTabUI(clipGui, tabs, false)  
    buildTabUI(clipGui, tabs, true)  

    setupClipboardEvents(clipGui)     
    setInitialActiveTab(useSavedTab)  

    clipGui.Show("w720 h570")
    focusTimer := SetTimer(focusListView.Bind(useSavedTab), -100)
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
        "• Click/double-click column header to sort`n" .
        "• Right-click: Show context menu with more options`n`n"

    showInfo("Clipboard Help", helpText, 350)
}

showContextMenu(LV, clipGui, Item, X, Y, useSavedTab := false) {
    if (Item = 0)  ; No item clicked
        return

    global historyViewer, savedViewer
    contentViewer := useSavedTab ? savedViewer : historyViewer

    LV.Focus()

    ; Get all currently selected rows
    selectedIndex := []
    rowNum := 0
    loop {
        rowNum := LV.GetNext(rowNum)
        if (!rowNum)
            break
        selectedIndex.Push(rowNum)
    }

    for _, rowNum in selectedIndex {
        LV.Modify(rowNum, "Select Focus")
    }

    CoordMode("Mouse", "Screen")
    MouseGetPos(&mouseX, &mouseY) 

    menuItems := [
        ["Paste", (*) => (pasteSelected(LV, clipGui, 0, useSavedTab))],
        ["Paste with Format", (*) => (pasteSelected(LV, clipGui, 1, useSavedTab))],
        ["Paste as Original", (*) => (pasteSelected(LV, clipGui, -1, useSavedTab))],
        [], 
        ["Paste with Tab", (*) => (pasteSelectedWithTab(LV, clipGui, 0, useSavedTab))],
        ["Paste with Tab + Format", (*) => (pasteSelectedWithTab(LV, clipGui, 1, useSavedTab))],
        ["Paste with Tab as Original", (*) => (pasteSelectedWithTab(LV, clipGui, -1, useSavedTab))]
    ]

    if (!useSavedTab) {
        menuItems.Push([])  ; Separator
        menuItems.Push(["Save to Saved Items", (*) => (saveToSavedItems(LV))])
        menuItems.Push(["Save Format to History", (*) => (saveToClipboard(LV, true))])
        menuItems.Push(["Split by Lines to History", (*) => (splitToLines(LV, false))])
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
    listView.ModifyCol(1, 50, "Integer")  ; Index column width
    listView.ModifyCol(2, 645)            ; Content column width

    contentViewer := clipGui.Add("Edit", "x10 y350 w700 h170 VScroll +Wrap", "")
    contentViewer.Opt("+ReadOnly")  ; Start in read-only mode

    if (!useSavedTab) {
        historyLV := listView
        historyViewer := contentViewer
    } else {
        savedLV := listView
        savedViewer := contentViewer
    }

    ; Event handlers for search functionality
    searchBoxChangeHandler(*) {
        handleSearch(searchBox, useSavedTab)  ; Filter items as user types
    }
    searchBoxFocusHandler(*) {
        WinActivate("ahk_id " . clipGui.Hwnd)
        searchBox.Focus()
    }

    searchBox.OnEvent("Change", searchBoxChangeHandler)
    searchBox.OnEvent("Focus", searchBoxFocusHandler)

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

    ; Handle item selection changes
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

        elements := getActiveTabElements(tabs)
        selectedIndex := getSelectedIndex(elements.listView)

        if (selectedIndex.Length = 1) {
            elements.contentViewer.Opt("-ReadOnly")  ; Allow editing single item
        } else {
            elements.contentViewer.Opt("+ReadOnly")  ; Read-only for multiple/no items
            if (selectedIndex.Length = 0)
                elements.listView.Focus()
        }
    }

    contentViewer.OnEvent("LoseFocus", (*) => updateContentViewerFocusState(false))

    actionBtns := [
        ["x150 y530 w120", "Save/Reload", (*) => saveContent(listView, contentViewer, clipGui, useSavedTab)]
    ]

    if (useSavedTab) {
        actionBtns.Push(["x280 y530 w120", "Clear All", (*) => clearClipboard(clipGui, true)])
    } else {
        actionBtns.Push(["x280 y530 w120", "Clear All", (*) => clearClipboard(clipGui, false)])
    }

    actionBtns.Push(["x410 y530 w120", "Help", (*) => showClipboardHelp()])

    ; Add all action buttons to the GUI
    for option in actionBtns {
        btn := clipGui.Add("Button", option[1], option[2])
        btn.OnEvent("Click", option[3])
    }
}
