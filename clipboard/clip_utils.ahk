; === CLIP_UTILS MODULE ===

; Initialize clipboard history tracking
initClipboard() {
    global historyTab := []
    global isFormatting := true
    tempClip := ClipboardAll()

    A_Clipboard := "Initializing..."
    ClipWait(0.2)
    A_Clipboard := tempClip
    ClipWait(0.2)
    isFormatting := false

    loadSavedItems()

    ; Handle clipboard content changes
    updateClipboard(Type) {
        if (isFormatting)
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

; Check if ListView has focus
isListViewFocused() {
    focusedHwnd := ControlGetFocus("A")
    focusedControl := ControlGetClassNN(focusedHwnd)
    return InStr(focusedControl, "SysListView32")
}

; Get selected items from ListView
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
        if (index != "") ; Check for empty string before conversion
            selectedIndex.Push(Integer(index))
    }
    return selectedIndex
}

; Process clipboard items for pasting
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

; Update content viewer with selected item content
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

; Move selected item up or down (works for both clipboard and saved items)
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

; Filter items based on search text
filterItems(searchText := "", useSavedTab := false) {
    global historyTab, savedTab

    clipTab := useSavedTab ? savedTab : historyTab

    if (searchText = "") {
        filteredItems := []
        for index, item in clipTab {
            filteredItems.Push({
                text: item.text,
                original: item.original,
                originalIndex: index
            })
        }
        return filteredItems
    }

    filteredItems := []
    searchTextLower := StrLower(searchText)
    for index, item in clipTab {
        if (InStr(StrLower(item.text), searchTextLower)) {
            filteredItems.Push({
                text: item.text,
                original: item.original,
                originalIndex: index
            })
        }
    }

    return filteredItems
}
