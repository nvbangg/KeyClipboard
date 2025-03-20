; === CLIP_UTILS MODULE ===

; Check if ListView has focus
isListViewFocused() {
    focusedHwnd := ControlGetFocus("A")
    focusedControl := ControlGetClassNN(focusedHwnd)
    return InStr(focusedControl, "SysListView32")
}

; Get selected items from ListView
getSelected(LV) {
    selectedItems := []
    rowNum := 0
    if (Type(LV) = "Array")
        return LV
    loop {
        rowNum := LV.GetNext(rowNum)
        if (!rowNum)
            break
        selectedItems.Push(Integer(LV.GetText(rowNum, 1)))
    }
    return selectedItems
}

; Process clipboard items for pasting
prepareClipItems(LV := 0) {
    global clipHistory
    if (clipHistory.Length = 0) {
        showNotification("No items in clipboard history")
        return []
    }

    contentItems := []
    firstItemIndex := 1
    if (LV) {
        selectedItems := getSelected(LV)
        if (selectedItems.Length = 0)
            return []
        firstItemIndex := selectedItems[1]
        contentItems.Capacity := selectedItems.Length
        for _, index in selectedItems
            contentItems.Push(clipHistory[index])
    }
    else
        contentItems := clipHistory.Clone()

    return contentItems
}

; Update ListView with clipboard history
updateLV(LV, clipHistoryGui := 0, searchText := "") {
    global clipHistory
    if (clipHistory.Length = 0) {
        if (clipHistoryGui) {
            clipHistoryGui.Destroy()
            showNotification("No items in clipboard history")
        }
        return
    }

    LV.Delete()
    filteredItems := filterClipboardItems(searchText)

    if (filteredItems.Length = 0 && searchText) {
        LV.Add(, "", "No matching items found")
        return
    }

    for index, content in filteredItems {
        displayContent := StrLen(content.text) > 100 ? SubStr(content.text, 1, 100) . "..." : content.text
        LV.Add(, content.originalIndex, displayContent)
    }

    LV.ModifyCol(1, "Integer")
}

; Update content viewer with selected item content
updateContent(LV, contentViewer) {
    global clipHistory
    selectedItems := getSelected(LV)
    if (selectedItems.Length = 0) {
        contentViewer.Value := ""
        return
    }

    if (selectedItems.Length > 1) {
        mergedItems := ""
        for index, itemIndex in selectedItems {
            mergedItems .= clipHistory[itemIndex].text .
                (index < selectedItems.Length ? "`r`n`r`n" : "")
        }
        contentViewer.Value := mergedItems
    } else
        contentViewer.Value := clipHistory[selectedItems[1]].text
}

; Filter clipboard items based on search text
filterClipboardItems(searchText := "") {
    global clipHistory
    if (searchText = "") {
        filteredItems := []
        for index, item in clipHistory {
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
    for index, item in clipHistory {
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
