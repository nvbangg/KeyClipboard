isValidGuiControl(control, prop := "") {
    try {
        if (!control || !control.Hwnd)
            return false
        return prop ? control.HasProp(prop) : true
    } catch {
        return false
    }
}

initClip() {
    global history := []
    global isProcessing := true
    tempClip := ClipboardAll()

    A_Clipboard := "Initializing..."  ; Force clipboard change to ensure hook works
    ClipWait(0.3)
    A_Clipboard := tempClip
    ClipWait(0.3)
    isProcessing := false

    loadSavedItems()
    updateClipboard(Type) {
        global historyLimit, monitorDelay
        Sleep(monitorDelay)
        if (isProcessing)
            return

        if (Type = 1 && A_Clipboard != "" && !DllCall("IsClipboardFormatAvailable", "UInt", 15)) {
            try {
                history.Push({ text: A_Clipboard, original: ClipboardAll(), pinned: false })
                if (history.Length > historyLimit)
                    history.RemoveAt(1)
            }
        }
    }

    OnClipboardChange(updateClipboard, 1)
}

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

updateClipTabReference(clipTab, useSaved) {
    global history, saved
    if (useSaved) {
        saved := clipTab
        saveSavedItems()
    } else
        history := clipTab
}

isFocusedControl(controlType) {
    try {
        hwnd := ControlGetFocus("A")
        if (!hwnd)
            return false
        control := ControlGetClassNN(hwnd)
        return InStr(control, controlType)
    } catch {
        return false
    }
}

setViewerFocus(isFocused) {
    global viewerFocused
    viewerFocused := isFocused
}

; Verify GUI can be opened and clipboard has content
checkInstance() {
    global history, saved, clipGuiInstance

    if (history.Length < 1 && saved.Length < 1) {
        showMsg("History empty")
        return false
    }

    if (isGuiValid(clipGuiInstance)) {
        static timerList := ["focusTimer"]
        for _, timerVar in timerList {
            try {
                if (%timerVar%) {
                    SetTimer(%timerVar%, 0)
                    %timerVar% := 0
                }
            }
        }
        destroyGui(clipGuiInstance)
    }

    clipGuiInstance := 0
    return true
}

execAction(action, clipGui) {
    elements := getTabElements(tabs)
    
    if (!elements.listView || !elements.viewer)
        return

    if (action = "enter") {
        if (isFocusedControl("SysListView32"))
            pasteSelected(elements.listView, clipGui, 0, elements.isSaved)
        else
            Send("{Enter}")
    }
    else if (action = "altUp")
        moveSelectedItems(elements.listView, elements.viewer, -1, elements.isSaved)  ; Move items up
    else if (action = "altDown")
        moveSelectedItems(elements.listView, elements.viewer, 1, elements.isSaved)  ; Move items down
    else if (action = "ctrlA") {
        if (isFocusedControl("Edit"))
            Send("^a")
        else
            selectAllItems(elements.listView, elements.viewer)
    }
    else if (action = "delete") {
        if (isFocusedControl("Edit"))
            Send("{Delete}")
        else
            deleteSelected(elements.listView, clipGui, elements.isSaved)
    }
    else if (action = "ctrlS") {
        if (isFocusedControl("Edit"))
            saveContent(elements.listView, elements.viewer, clipGui, elements.isSaved)
        else
            Send("^s")
    }
}

setupEvents(clipGui) {
    closeCallback(*) => clipGui.Destroy()
    clipGui.OnEvent("Close", closeCallback)
    clipGui.OnEvent("Escape", closeCallback)

    HotIfWinActive("ahk_id " . clipGui.Hwnd)  ; Apply hotkeys only when clipboard window is active

    Hotkey "Enter", (*) => execAction("enter", clipGui)
    Hotkey "!Up", (*) => execAction("altUp", clipGui)
    Hotkey "!Down", (*) => execAction("altDown", clipGui)
    Hotkey "^a", (*) => execAction("ctrlA", clipGui)
    Hotkey "^s", (*) => execAction("ctrlS", clipGui)
    Hotkey "Delete", (*) => execAction("delete", clipGui)
    Hotkey "Escape", (*) => clipGui.Destroy()

    HotIf()
}

sortArray(arr, direction := 1) {
    ; direction: 1 = ascending, -1 = descending
    n := arr.Length
    loop n - 1 {
        i := A_Index
        loop n - i {
            j := A_Index
            shouldSwap := direction = -1 ? (arr[j] < arr[j + 1]) : (arr[j] > arr[j + 1])
            if (shouldSwap) {
                temp := arr[j]
                arr[j] := arr[j + 1]
                arr[j + 1] := temp
            }
        }
    }
    return arr
}

onTabChange(ctrl, *) {
    global clipGuiInstance
    try {
        updateTab(ctrl.Value, IsObject(clipGuiInstance) ? clipGuiInstance.Hwnd : 0)
    } catch {
    }
}

setActiveTab(useSaved) {
    global history, saved, historyLV, savedLV, historyViewer, savedViewer, tabs
    loadSavedItems()
    
    updateLV(historyLV, "", false)
    updateLV(savedLV, "", true)

    if (useSaved && saved.Length > 0) {
        tabs.Value := 2
        SetTimer(() => focusLastItem(savedLV, savedViewer, true), -50)
    } else if (history.Length > 0) {
        tabs.Value := 1
        SetTimer(() => focusLastItem(historyLV, historyViewer, false), -50)
    } else if (saved.Length > 0) {
        tabs.Value := 2
        SetTimer(() => focusLastItem(savedLV, savedViewer, true), -50)
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
            focusLastItem(elements.listView, elements.viewer, elements.isSaved)
        }
    } catch {
    }
}

updateLV(LV, searchText := "", useSaved := false) {
    if (!isValidGuiControl(LV, "Delete"))
        return

    filteredItems := filterItems(searchText, useSaved)
    LV.Delete()

    if (filteredItems.Length = 0)
        return
    for index, content in filteredItems {
        displayText := formatDisplayText(content.text)
        
        if (!useSaved && content.HasProp("pinned") && content.pinned)
            displayText := "📌 " . displayText

        ; Truncate long text for better display
        if (StrLen(displayText) > 100)
            filteredCaption := SubStr(displayText, 1, 100) . "..."
        else
            filteredCaption := displayText

        LV.Add(, content.originalIndex, filteredCaption)
    }

    LV.ModifyCol(1, "Integer")  ; Format first column as numbers
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
            focusLastItem(targetLV, targetViewer, useSaved)
        }
    } catch {
    }
}

updateViewer(LV, viewer, useSaved := false) {
    if (!isValidGuiControl(viewer, "Value"))
        return
    if (!isValidGuiControl(LV, "GetNext"))
        return

    selectedIndex := getSelectedIndex(LV)
    if (selectedIndex.Length = 0) {
        try {
            viewer.Value := ""
        } catch {
        }
        return
    }

    clipTab := TabUtils.getTab(useSaved)
    try {
        if (selectedIndex.Length = 1 && selectedIndex[1] <= clipTab.Length) {
            viewer.Value := TabUtils.getText(clipTab[selectedIndex[1]], useSaved)
            return
        }

        mergedItems := ""
        for index, itemIndex in selectedIndex {
            if (itemIndex <= clipTab.Length) {
                itemText := TabUtils.getText(clipTab[itemIndex], useSaved)
                mergedItems .= itemText . (index < selectedIndex.Length ? "`r`n" : "")
            }
        }
        viewer.Value := mergedItems
    } catch {
    }
}

focusLastItem(LV, viewer, useSaved) {
    if (!isValidGuiControl(LV, "GetCount"))
        return

    lastRow := LV.GetCount()
    if (lastRow > 0) {
        try {
            LV.Modify(0, "-Select")
            LV.Modify(lastRow, "Select Focus Vis")
            LV.Focus()
            
            if (isValidGuiControl(viewer))
                SetTimer(() => (LV.Focus(), SetTimer(() => updateViewer(LV, viewer, useSaved), -10)), -50)
            SetTimer(() => focusIfValid(LV), -50)
        } catch {
        }
    }
}

focusIfValid(control) {
    if (isValidGuiControl(control, "Focus"))
        control.Focus()
}

selectRows(LV, indices, clearFirst := true) {
    if (clearFirst)
        LV.Modify(0, "-Select")
    for _, targetIndex in indices
        selectRowByIndex(LV, targetIndex, "Select")
    if (indices.Length > 0)
        selectRowByIndex(LV, indices[1], "Focus Vis")
}

selectRowByIndex(LV, targetIndex, modifyOptions := "Select Focus Vis") {
    loop LV.GetCount() {
        rowNum := A_Index
        if (Integer(LV.GetText(rowNum, 1)) = targetIndex) {
            LV.Modify(rowNum, modifyOptions)
            return rowNum
        }
    }
    return 0
}

getViewer(LV) {
    viewer := 0
    try {
        parentGui := GuiCtrlFromHwnd(LV.Hwnd).Gui
        if (parentGui)
            viewer := parentGui.FindControl("Edit1")
    }
    return viewer
}

getSelectedIndex(LV) {
    selectedIndex := []
    rowNum := 0
    if (Type(LV) = "Array")
        return LV
    
    if (!isValidGuiControl(LV, "GetNext"))
        return selectedIndex
    
    try {
        loop {
            rowNum := LV.GetNext(rowNum)
            if (!rowNum)
                break
            index := LV.GetText(rowNum, 1)
            if (index != "")
                selectedIndex.Push(Integer(index))
        }
    } catch {
    }
    return selectedIndex
}

getTabElements(tabsObj) {
    global historyLV, savedLV, historyViewer, savedViewer
    return (tabsObj.Value = 1) 
        ? { listView: historyLV, viewer: historyViewer, isSaved: false }
        : { listView: savedLV, viewer: savedViewer, isSaved: true }
}

validateAndCleanupGui(LV, clipGui, useSaved) {
    selectedItems := getSelected(LV, useSaved)
    if (!IsObject(selectedItems) || selectedItems.Length < 1) {
        if (LV = 0)
            showMsg(TabUtils.getName(useSaved) . " empty")
        return false
    }
    if (clipGui)
        clipGui.Destroy()
    return selectedItems
}

validateMinItems(clipTab, minCount, tabName) {
    if (clipTab.Length < minCount) {
        showMsg("Not enough items in " . tabName)
        return false
    }
    return true
}

updateLVWithNewItem(LV, clipTab, useSaved, message) {
    if (useSaved)
        saveSavedItems()
    updateLV(LV, "", useSaved)
    newIndex := clipTab.Length
    selectRowByIndex(LV, newIndex, "Select Focus Vis")
    showMsg(message)
}

updateItemInTab(clipTab, index, newText, useSaved) {
    if (useSaved) {
        clipTab[index] := newText
    } else {
        clipTab[index].text := newText
        clipTab[index].original := newText
    }
}

getSelected(LV := 0, useSaved := false) {
    clipTab := TabUtils.getTab(useSaved)

    if (clipTab.Length = 0)
        return []
    selectedItems := []

    if (LV) {
        selectedIndex := getSelectedIndex(LV)
        if (selectedIndex.Length = 0)
            return []

        selectedItems.Capacity := selectedIndex.Length
        for _, index in selectedIndex {
            if (index > 0 && index <= clipTab.Length) {
                item := clipTab[index]
                selectedItems.Push(useSaved ? { text: item, original: item } : item)
            }
        }
    } else {
        for _, item in clipTab
            selectedItems.Push(useSaved ? { text: item, original: item } : item)
    }

    return selectedItems
}