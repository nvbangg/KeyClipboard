; Clip_utils

; Initialize and track clipboard
initClipboard() {
    global clipHistory := []
    OnClipboardChange(updateClipboard, 1)
}

; Process clipboard content changes
updateClipboard(Type) {
    global clipHistory, isFormatting
    if (isFormatting)
        return
    if (Type = 1 && A_Clipboard != "") {
        try {
            clipHistory.Push(A_Clipboard)
            if (clipHistory.Length > 100)
                clipHistory.RemoveAt(1)
        }
    }
}

; Populate the ListView with clipboard history items
updateLV(LV) {
    global clipHistory
    LV.Delete()
    for index, content in clipHistory {
        displayContent := StrLen(content) > 100 ? SubStr(content, 1, 100) . "..." : content
        LV.Add(, index, displayContent)
    }

    LV.ModifyCol(1, "Integer")
    LV.Modify(clipHistory.Length, "Select Focus")
}

; Update the content viewer with the content of selected items
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
            mergedItems .= itemIndex . "`r`n" .
                clipHistory[itemIndex] .
                (index < selectedItems.Length ? "`r`n`r`n" : "")
        }
        contentViewer.Value := mergedItems
    } else
        contentViewer.Value := clipHistory[selectedItems[1]]

}

saveContent(LV, contentViewer, clipHistoryGui, andPaste := false) {
    global clipHistory
    selectedItems := getSelected(LV)
    if (selectedItems.Length = 0)
        return
    ; Save changes if only one item is selected
    if (selectedItems.Length = 1) {
        clipHistory[selectedItems[1]] := contentViewer.Value

        if (!andPaste) {
            rowNum := 1
            loop LV.GetCount() {
                if (Integer(LV.GetText(rowNum, 1)) = selectedItems[1]) {
                    displayContent := StrLen(contentViewer.Value) > 100 ?
                        SubStr(contentViewer.Value, 1, 100) . "..." : contentViewer.Value
                    LV.Modify(rowNum, , selectedItems[1], displayContent)
                    break
                }
                rowNum++
            }
            showNotification("Changes saved")
        }
    } else if (!andPaste) {
        showNotification("Cannot save changes when multiple items are selected.")
        return
    }
    ; Paste functionality
    if (andPaste) {
        mergedItems := ""
        for index, item in selectedItems
            mergedItems .= clipHistory[item] . (index < selectedItems.Length ? "`r`n" : "")
        clipHistoryGui.Destroy()
        paste(mergedItems)
        return
    }
    updateLV(LV)
}

getAll(LV) {
    items := []
    rowCount := LV.GetCount()
    if (rowCount = 0)
        return items
    loop rowCount {
        rowNum := A_Index
        itemIndex := Integer(LV.GetText(rowNum, 1))
        items.Push(itemIndex)
    }
    return items
}

; Get all selected items in the ListView
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

paste(text, formatTextEnable := false) {
    global isFormatting, clipHistory
    isFormatting := true
    originalClip := ClipboardAll()

    if (formatTextEnable)
        text := formatText(text)
    A_Clipboard := text
    ClipWait(0.3)
    Send("^v")
    Sleep(50)

    ; Restore original clipboard
    A_Clipboard := originalClip
    ClipWait(0.3)
    Sleep(50)

    isFormatting := false
}

; Process clipboard items and return the merged content
processClipItems(LV := 0, formatTextEnable := false) {
    global clipHistory, beforeLatest_LatestEnabled
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
    ; If no ListView provided, use all items
    else
        contentItems := clipHistory.Clone()

    if (beforeLatest_LatestEnabled && formatTextEnable) {
        index := contentItems.Length
        while (index > 1) {
            contentItems[index] := contentItems[index - 1] . "_" . contentItems[index]
            index--
        }
        if (firstItemIndex > 1) {
            contentItems[1] := clipHistory[firstItemIndex - 1] . "_" . contentItems[1]
        }
    }
    return contentItems
}

; Paste clipboard items (selected or all)
pasteSelected(LV := 0, clipHistoryGui := 0, formatTextEnable := false) {
    contentItems := processClipItems(LV, formatTextEnable)
    if (!IsObject(contentItems) || contentItems.Length < 1)
        return
    mergedItems := ""
    for index, item in contentItems
        mergedItems .= item . (index < contentItems.Length ? "`r`n" : "")
    if (mergedItems != "") {
        if (clipHistoryGui)
            clipHistoryGui.Destroy()
        paste(mergedItems, formatTextEnable)
    }
}

; Merge selected items into clipboard history
saveToClipboard(LV := 0, formatTextEnable := false) {
    global isFormatting, clipHistory
    contentItems := processClipItems(LV, formatTextEnable)
    for _, item in contentItems {
        if (formatTextEnable)
            item := formatText(item)
        clipHistory.Push(item)
    }
    updateLV(LV)
}

; Delete selected item(s)
deleteSelected(LV, clipHistoryGui) {
    global clipHistory

    selectedItems := getSelected(LV)
    if (selectedItems.Length = 0)
        return
    ; Sort the selected items
    n := selectedItems.Length
    loop n - 1 {
        i := A_Index
        loop n - i {
            j := A_Index
            if (selectedItems[j] < selectedItems[j + 1]) {
                temp := selectedItems[j]
                selectedItems[j] := selectedItems[j + 1]
                selectedItems[j + 1] := temp
            }
        }
    }

    for i, item in selectedItems
        clipHistory.RemoveAt(item)
    updateLV(LV)
}

; Move selected item up or down in the clipboard history
moveSelectedItem(LV, contentViewer, direction) {
    global clipHistory

    selectedRow := LV.GetNext(0)
    if (!selectedRow)
        return

    ; Get the actual index in the clipHistory array
    currentIndex := Integer(LV.GetText(selectedRow, 1))
    targetIndex := currentIndex + direction

    if (targetIndex < 1 || targetIndex > clipHistory.Length)
        return

    ; Swap items in clipHistory array
    temp := clipHistory[currentIndex]
    clipHistory[currentIndex] := clipHistory[targetIndex]
    clipHistory[targetIndex] := temp

    updateLV(LV)
    LV.Modify(0, "-Select")

    ; Find and select the item at its new position
    loop LV.GetCount() {
        rowNum := A_Index
        itemIndex := Integer(LV.GetText(rowNum, 1))
        if (itemIndex = targetIndex) {
            LV.Modify(rowNum, "Select Focus Vis")
            break
        }
    }

    updateContent(LV, contentViewer)
}
