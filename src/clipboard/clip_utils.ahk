initClipboard() {
    global historyTab := []
    global isProcessing := true
    tempClip := ClipboardAll()

    A_Clipboard := "Initializing..."
    ClipWait(0.2)
    A_Clipboard := tempClip
    ClipWait(0.2)
    isProcessing := false

    loadSavedItems()
    ; Register callback for clipboard content changes
    updateClipboard(Type) {
        if (isProcessing)
            return
        if (Type = 1 && A_Clipboard != "") {
            try {
                historyTab.Push({
                    text: A_Clipboard,
                    original: ClipboardAll()
                })
                if (historyTab.Length > 100)
                    historyTab.RemoveAt(1)
            }
        }
    }
    OnClipboardChange(updateClipboard, 1)
}

isListViewFocused() {
    focusedHwnd := ControlGetFocus("A")
    focusedControl := ControlGetClassNN(focusedHwnd)
    return InStr(focusedControl, "SysListView32")
}

getSelectedIndex(LV) {
    selectedIndex := []
    rowNum := 0
    if (Type(LV) = "Array")
        return LV
    loop {
        rowNum := LV.GetNext(rowNum)
        if (!rowNum)
            break

        index := LV.GetText(rowNum, 1)
        if (index != "")
            selectedIndex.Push(Integer(index))
    }
    return selectedIndex
}

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
        selectedItems.Capacity := selectedIndex.Length
        for _, index in selectedIndex {
            if (index > 0 && index <= clipTab.Length)
                selectedItems.Push(clipTab[index])
        }
    }
    else
        selectedItems := clipTab.Clone()

    return selectedItems
}

selectAllItems(LV, contentViewer) {
    if (!LV || LV.GetCount() == 0)
        return
    totalItems := LV.GetCount()
    selectedCount := 0
    rowNum := 0

    loop {
        rowNum := LV.GetNext(rowNum)
        if (!rowNum)
            break
        selectedCount++
    }
    ; Toggle selection based on current state
    if (selectedCount == totalItems) {
        LV.Modify(0, "-Select")
        contentViewer.Value := ""
    } else {
        if (!isListViewFocused())
            LV.Focus()
        LV.Modify(0, "Select")
        updateContent(LV, contentViewer)
    }
}

updateLV(LV, searchText := "", useSavedTab := false) {
    if (!LV || !LV.HasProp("Delete"))
        return
    filteredItems := filterItems(searchText, useSavedTab)
    LV.Delete()
    if (filteredItems.Length = 0)
        return

    filteredCaption := ""
    for index, content in filteredItems {
        ; Truncate display content if too long
        if (StrLen(content.text) > 100)
            filteredCaption := SubStr(content.text, 1, 100) . "..."
        else
            filteredCaption := content.text

        LV.Add(, content.originalIndex, filteredCaption)
    }
    LV.ModifyCol(1, "Integer")
}

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

    if (selectedIndex.Length > 1) {
        mergedItems := ""
        for index, itemIndex in selectedIndex {
            if (itemIndex > clipTab.Length)
                continue

            mergedItems .= clipTab[itemIndex].text .
                (index < selectedIndex.Length ? "`r`n`r`n" : "")
        }
        contentViewer.Value := mergedItems
    }
    else if (selectedIndex[1] > 0 && selectedIndex[1] <= clipTab.Length) {
        contentViewer.Value := clipTab[selectedIndex[1]].text
    }
    else {
        contentViewer.Value := ""
    }
}

moveSelectedItem(LV, contentViewer, direction, useSavedTab := false) {
    global historyTab, savedTab
    if (!isListViewFocused())
        return
    selectedRow := LV.GetNext(0)
    if (!selectedRow)
        return

    currentIndex := Integer(LV.GetText(selectedRow, 1))
    targetIndex := currentIndex + direction

    clipTab := useSavedTab ? savedTab : historyTab

    if (targetIndex < 1 || targetIndex > clipTab.Length)
        return
    ; Swap items in array
    temp := clipTab[currentIndex]
    clipTab[currentIndex] := clipTab[targetIndex]
    clipTab[targetIndex] := temp

    if (useSavedTab) {
        savedTab := clipTab
        saveSavedItems()
    }
    else
        historyTab := clipTab

    updateLV(LV, "", useSavedTab)
    LV.Modify(0, "-Select")
    ; Find and select moved item
    loop LV.GetCount() {
        rowNum := A_Index
        itemIndex := Integer(LV.GetText(rowNum, 1))
        if (itemIndex = targetIndex) {
            LV.Modify(rowNum, "Select Focus Vis")
            break
        }
    }
    updateContent(LV, contentViewer, useSavedTab)
}

filterItems(searchText := "", useSavedTab := false) {
    global historyTab, savedTab
    clipTab := useSavedTab ? savedTab : historyTab
    filteredItems := []
    searchTextLower := searchText ? StrLower(searchText) : ""

    for index, item in clipTab {
        if (searchText = "" || InStr(StrLower(item.text), searchTextLower)) {
            filteredItems.Push({
                text: item.text,
                original: item.original,
                originalIndex: index
            })
        }
    }

    return filteredItems
}

handleSearch(searchCtrl, useSavedTab := false) {
    if (useSavedTab) {
        updateLV(savedLV, searchCtrl.Value, true)
        updateContent(savedLV, savedViewer, true)
    } else {
        updateLV(historyLV, searchCtrl.Value, false)
        updateContent(historyLV, historyViewer, false)
    }
}

checkClipInstance() {
    global historyTab, savedTab, clipGuiInstance

    if (historyTab.Length < 1 && savedTab.Length < 1) {
        showNotification("No items in clipboard history")
        return false
    }

    destroyGui(clipGuiInstance)
    clipGuiInstance := 0

    return true
}

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
                elements.listView.Modify(lastRow, "Select Focus Vis")
                if (IsObject(elements.contentViewer))
                    updateContent(elements.listView, elements.contentViewer, elements.isSaved)
            }

            SetTimer(() => elements.listView.Focus(), -50)
        }
    } catch {
        ; Handle any errors accessing destroyed controls
    }
}

onTabChange(ctrl, *) {
    global clipGuiInstance
    updateTabContent(ctrl.Value, IsObject(clipGuiInstance) ? clipGuiInstance.Hwnd : 0)
}

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
            contextMenu.Add() ; Add separator
        else
            contextMenu.Add(item[1], item[2]) ; Add label and callback
    }

    return contextMenu
}

execAction(action, clipGui) {
    elements := getActiveTabElements(tabs)

    if (action = "enter") {
        if (isListViewFocused())
            pasteSelected(elements.listView, clipGui, 0, elements.isSaved)
        else
            Send("{Enter}")
    }
    else if (action = "altUp")
        moveSelectedItem(elements.listView, elements.contentViewer, -1, elements.isSaved)
    else if (action = "altDown")
        moveSelectedItem(elements.listView, elements.contentViewer, 1, elements.isSaved)
    else if (action = "ctrlA")
        selectAllItems(elements.listView, elements.contentViewer)
    else if (action = "delete")
        deleteSelected(elements.listView, clipGui, elements.isSaved)
}
