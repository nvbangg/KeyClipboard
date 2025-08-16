initClipboard() {
    global historyTab := []
    global isProcessing := true
    tempClip := ClipboardAll()  ; Store current clipboard content

    A_Clipboard := "Initializing..."  ; Force clipboard change to ensure hook works
    ClipWait(0.2)
    A_Clipboard := tempClip  ; Restore original clipboard
    ClipWait(0.2)
    isProcessing := false

    loadSavedItems()
    updateClipboard(Type) {
        global maxHistoryCount

        if (isProcessing)
            return

        if (Type = 1 && A_Clipboard != "") {
            try {
                historyTab.Push({
                    text: A_Clipboard,
                    original: ClipboardAll()  ; Store raw clipboard with formatting
                })

                if (historyTab.Length > maxHistoryCount)
                    historyTab.RemoveAt(1)  ; Remove oldest item when limit reached
            }
        }
    }

    OnClipboardChange(updateClipboard, 1)  ; Register the clipboard change event handler
}

; Check if the ListView control has input focus
isListViewFocused() {
    focusedHwnd := ControlGetFocus("A")
    focusedControl := ControlGetClassNN(focusedHwnd)
    return InStr(focusedControl, "SysListView32")
}

; Check if the content viewer (Edit control) has input focus
isContentViewerFocused() {
    focusedHwnd := ControlGetFocus("A")
    focusedControl := ControlGetClassNN(focusedHwnd)
    return InStr(focusedControl, "Edit")
}

; Update global state tracking if content viewer has focus
updateContentViewerFocusState(isFocused) {
    global contentViewerIsFocused
    contentViewerIsFocused := isFocused
}

; Extract the index numbers of selected items from a ListView
getSelectedIndex(LV) {
    selectedIndex := []
    rowNum := 0

    if (Type(LV) = "Array")  ; If already an array, return as-is
        return LV

    loop {
        rowNum := LV.GetNext(rowNum)  ; Get next selected row
        if (!rowNum)
            break
        index := LV.GetText(rowNum, 1)  ; Get index number from first column
        if (index != "")
            selectedIndex.Push(Integer(index))
    }

    return selectedIndex
}

; Get the actual clipboard items for selected indexes
getSelectedItems(LV := 0, useSavedTab := false) {
    global historyTab, savedTab
    clipTab := useSavedTab ? savedTab : historyTab

    if (clipTab.Length = 0)
        return []

    selectedItems := []

    if (LV) {
        selectedIndex := getSelectedIndex(LV)

        if (selectedIndex.Length = 0)
            return []

        selectedItems.Capacity := selectedIndex.Length  ; Pre-allocate for performance

        for _, index in selectedIndex {
            if (index > 0 && index <= clipTab.Length)
                selectedItems.Push(clipTab[index])
        }
    } else {
        selectedItems := clipTab.Clone()  ; Get all items if no selection specified
    }

    return selectedItems
}

selectAllItems(LV, contentViewer) {
    if (!LV || LV.GetCount() == 0)
        return

    totalItems := LV.GetCount()
    selectedCount := 0
    rowNum := 0

    ; Count currently selected items
    loop {
        rowNum := LV.GetNext(rowNum)
        if (!rowNum)
            break
        selectedCount++
    }

    ; Toggle selection: deselect all if all are selected, otherwise select all
    if (selectedCount == totalItems) {
        LV.Modify(0, "-Select")  ; Deselect all
        contentViewer.Value := ""
    } else {
        if (!isListViewFocused())
            LV.Focus()
        LV.Modify(0, "Select")  ; Select all
        updateContent(LV, contentViewer)
    }
}

; Update ListView with filtered items based on search text
updateLV(LV, searchText := "", useSavedTab := false) {
    if (!LV || !LV.HasProp("Delete"))
        return

    filteredItems := filterItems(searchText, useSavedTab)  ; Get filtered items
    LV.Delete()  ; Clear ListView

    if (filteredItems.Length = 0)
        return

    ; Add each filtered item to ListView
    for index, content in filteredItems {
        displayText := RegExReplace(content.text, "[\r\n]+", "    ")  ; Replace line breaks for display

        ; Truncate long text for better display
        if (StrLen(displayText) > 100)
            filteredCaption := SubStr(displayText, 1, 100) . "..."
        else
            filteredCaption := displayText

        LV.Add(, content.originalIndex, filteredCaption)
    }

    LV.ModifyCol(1, "Integer")  ; Format first column as numbers
}

; Helper function to safely focus the ListView
focusListView(useSavedTab) {
    global historyLV, savedLV, clipGuiInstance

    try {
        if (!clipGuiInstance || !clipGuiInstance.Hwnd || !WinExist("ahk_id " . clipGuiInstance.Hwnd))
            return

        targetLV := useSavedTab ? savedLV : historyLV

        if (IsObject(targetLV) && targetLV.HasProp("Focus") && WinExist("ahk_id " . clipGuiInstance.Hwnd)) {
            WinActivate("ahk_id " . clipGuiInstance.Hwnd)
            Sleep(10)
            targetLV.Focus()
        }
    } catch Error as e {
    }
}

; Update content viewer with selected item(s)
updateContent(LV, contentViewer, useSavedTab := false) {
    global historyTab, savedTab
    clipTab := useSavedTab ? savedTab : historyTab

    if (!contentViewer || !contentViewer.HasProp("Value"))
        return

    selectedIndex := getSelectedIndex(LV)

    if (selectedIndex.Length = 0) {
        contentViewer.Value := ""
        return
    }

    ; Show single item if only one selected
    if (selectedIndex.Length = 1 && selectedIndex[1] <= clipTab.Length) {
        contentViewer.Value := clipTab[selectedIndex[1]].text
        return
    }

    ; Show multiple items with separators if multiple selected
    mergedItems := ""
    for index, itemIndex in selectedIndex {
        if (itemIndex > clipTab.Length)
            continue
        mergedItems .= clipTab[itemIndex].text . (index < selectedIndex.Length ? "`r`n`r`n" : "")
    }

    contentViewer.Value := mergedItems
}

; Filter clip items based on search text and update display
handleSearch(searchCtrl, useSavedTab := false) {
    if (useSavedTab) {
        updateLV(savedLV, searchCtrl.Value, true)
        updateContent(savedLV, savedViewer, true)
    } else {
        updateLV(historyLV, searchCtrl.Value, false)
        updateContent(historyLV, historyViewer, false)
    }
}

; Verify GUI can be opened and clipboard has content
checkClipInstance() {
    global historyTab, savedTab, clipGuiInstance

    if (historyTab.Length < 1 && savedTab.Length < 1) {
        showNotification("No items in clipboard history")
        return false
    }

    ; Ensure safer GUI destruction with explicit timer cleanup
    if (isGuiValid(clipGuiInstance)) {
        ; Cancel all active timers associated with the GUI
        static timerList := ["focusTimer"]
        for _, timerVar in timerList {
            try {
                if (%timerVar%) {
                    SetTimer(%timerVar%, 0)
                    %timerVar% := 0
                }
            } catch Error as e {
            }
        }
        destroyGui(clipGuiInstance)
    }

    clipGuiInstance := 0
    return true
}

; Update tab content when switching between History and Saved tabs
updateTabContent(tabIndex, clipGuiHwnd) {
    global historyLV, savedLV, historyViewer, savedViewer

    if (!WinExist("ahk_id " . clipGuiHwnd))
        return

    try {
        elements := getActiveTabElements({ Value: tabIndex })

        if (IsObject(elements.listView) && elements.listView.HasProp("GetCount")) {
            updateLV(elements.listView, "", elements.isSaved)
            lastRow := elements.listView.GetCount()

            if (lastRow > 0) {
                elements.listView.Modify(lastRow, "Select Focus Vis")  ; Select last item
                if (IsObject(elements.contentViewer))
                    updateContent(elements.listView, elements.contentViewer, elements.isSaved)
            }

            SetTimer(() => elements.listView.Focus(), -50)  ; Delayed focus for UI stability
        }
    } catch {
    }
}

; Handle tab switch events
onTabChange(ctrl, *) {
    global clipGuiInstance
    updateTabContent(ctrl.Value, IsObject(clipGuiInstance) ? clipGuiInstance.Hwnd : 0)
}

; Get UI controls for the currently active tab
getActiveTabElements(tabsObj) {
    global historyLV, savedLV, historyViewer, savedViewer

    if (tabsObj.Value = 1) {
        return { listView: historyLV, contentViewer: historyViewer, isSaved: false }
    } else {
        return { listView: savedLV, contentViewer: savedViewer, isSaved: true }
    }
}

createContextMenu(menuItems) {
    contextMenu := Menu()

    for item in menuItems {
        if (item.Length = 0)
            contextMenu.Add()  ; Add separator
        else
            contextMenu.Add(item[1], item[2])  ; Add menu item with handler
    }

    return contextMenu
}

; Execute clipboard actions based on user input (keyboard shortcuts)
execAction(action, clipGui) {
    elements := getActiveTabElements(tabs)

    if (action = "enter") {
        if (isListViewFocused())
            pasteSelected(elements.listView, clipGui, 0, elements.isSaved)
        else
            Send("{Enter}")  ; Pass through if not in list view
    }
    else if (action = "altUp")
        moveSelectedItem(elements.listView, elements.contentViewer, -1, elements.isSaved)  ; Move item up
    else if (action = "altDown")
        moveSelectedItem(elements.listView, elements.contentViewer, 1, elements.isSaved)  ; Move item down
    else if (action = "ctrlA") {
        if (isContentViewerFocused())
            Send("^a")  ; Select all text in content viewer
        else
            selectAllItems(elements.listView, elements.contentViewer)  ; Select all items in list
    }
    else if (action = "delete") {
        if (isContentViewerFocused())
            Send("{Delete}")  ; Pass through delete key
        else
            deleteSelected(elements.listView, clipGui, elements.isSaved)  ; Delete selected items
    }
}

; Setup keyboard shortcuts for clipboard manager window
setupClipboardEvents(clipGui) {
    closeCallback(*) => clipGui.Destroy()
    clipGui.OnEvent("Close", closeCallback)
    clipGui.OnEvent("Escape", closeCallback)

    HotIfWinActive("ahk_id " . clipGui.Hwnd)  ; Apply hotkeys only when clipboard window is active

    Hotkey "Enter", (*) => execAction("enter", clipGui)
    Hotkey "!Up", (*) => execAction("altUp", clipGui)
    Hotkey "!Down", (*) => execAction("altDown", clipGui)
    Hotkey "^a", (*) => execAction("ctrlA", clipGui)
    Hotkey "Delete", (*) => execAction("delete", clipGui)
    Hotkey "Escape", (*) => clipGui.Destroy()

    HotIf()
}

; Set active tab and focus on initial display
setInitialActiveTab(useSavedTab) {
    global historyTab, savedTab, historyLV, savedLV, historyViewer, savedViewer, tabs

    updateLV(historyLV, "", false)
    updateLV(savedLV, "", true)

    ; Determine which tab to show based on content and parameters
    if (useSavedTab && savedTab.Length > 0) {
        tabs.Value := 2  ; Switch to Saved tab
        focusLastItem(savedLV, savedViewer, true)
    } else if (historyTab.Length > 0) {
        focusLastItem(historyLV, historyViewer, false)
    } else if (savedTab.Length > 0) {
        tabs.Value := 2  ; Switch to Saved tab
        focusLastItem(savedLV, savedViewer, true)
    }
}

; Focus the most recent clipboard item
focusLastItem(LV, viewer, isSaved) {
    if (!isGuiValid(LV) || !LV.HasProp("GetCount"))
        return

    lastRow := LV.GetCount()
    if (lastRow > 0) {
        try {
            LV.Modify(lastRow, "Select Focus Vis")  ; Select, focus and make visible
            LV.Focus()
            if (isGuiValid(viewer))
                updateContent(LV, viewer, isSaved)

            ; Use a more robust timer that checks control validity
            SetTimer(() => safeFocus(LV), -50)
        } catch Error as e {
            ; Silently handle errors
        }
    }
}

; Helper function to safely focus ListView with error handling
safeFocus(control) {
    try {
        if (isGuiValid(control) && control.HasProp("Focus"))
            control.Focus()
    } catch Error as e {
        ; Silently handle errors
    }
}
