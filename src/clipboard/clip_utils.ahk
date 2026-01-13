initClip() {
    global history := []
    global isProcessing := true
    try {
        A_Clipboard := "Initializing..."  ; Force clipboard change to ensure hook works
        ClipWait(0.3)
        A_Clipboard := ""
    } catch {
    }
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
                if (showCopied)
                    showMsg("Copied", 400)
            }
        }
    }

    OnClipboardChange(updateClipboard, 1)
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
    else if (action = "shiftEnter") {
        if (isFocusedControl("SysListView32") && !elements.isSaved)
            pasteSelected(elements.listView, clipGui, 1, elements.isSaved)
        else
            Send("+{Enter}")
    }
    else if (action = "ctrlEnter") {
        if (isFocusedControl("SysListView32") && !elements.isSaved)
            pasteSelected(elements.listView, clipGui, -1, elements.isSaved)
        else
            Send("^{Enter}")
    }
    else if (action = "altUp")
        moveSelectedItems(elements.listView, -1, elements.isSaved)
    else if (action = "altDown")
        moveSelectedItems(elements.listView, 1, elements.isSaved)
    else if (action = "ctrlA") {
        if (isFocusedControl("Edit"))
            Send("^a")
        else
            selectAllItems(elements.listView)
    }
    else if (action = "delete") {
        if (isFocusedControl("Edit"))
            Send("{Delete}")
        else
            deleteSelected(elements.listView, clipGui, elements.isSaved)
    }
    else if (action = "ctrlS") {
        if (isFocusedControl("Edit"))
            saveContent(elements.listView, clipGui, elements.isSaved)
        else
            Send("^s")
    }
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

focusLastItem(LV, useSaved) {
    if (!isValidGuiControl(LV, "GetCount"))
        return

    lastRow := LV.GetCount()
    if (lastRow > 0) {
        try {
            LV.Modify(0, "-Select")
            LV.Modify(lastRow, "Select Focus Vis")
            LV.Focus()
            updateViewer(useSaved)
        } catch {
        }
    }
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

getSelectedItems(LV, clipGui, useSaved) {
    clipTab := TabUtils.getTab(useSaved)

    if (clipTab.Length = 0) {
        if (LV = 0)
            showMsg(TabUtils.getName(useSaved) . " empty")
        return false
    }

    selectedItems := []
    if (LV) {
        selectedIndex := getSelectedIndex(LV)
        if (selectedIndex.Length = 0)
            return false

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
    if (selectedItems.Length < 1)
        return false

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

isValidGuiControl(control, prop := "") {
    try {
        if (!control || !control.Hwnd)
            return false
        return prop ? control.HasProp(prop) : true
    } catch {
        return false
    }
}

updateViewer(useSaved := false) {
    global historyViewer, savedViewer, historyLV, savedLV
    viewer := useSaved ? savedViewer : historyViewer
    LV := useSaved ? savedLV : historyLV

    if (!isValidGuiControl(viewer, "Value") || !isValidGuiControl(LV, "GetNext"))
        return

    selectedIndex := getSelectedIndex(LV)
    if (selectedIndex.Length = 0) {
        viewer.Value := ""
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
