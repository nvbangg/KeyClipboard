; Clip_utils

; Initialize clipboard history tracking
initClipboard() {
    global clipHistory := []
    OnClipboardChange(updateClipboard, 1)
}

; Handle clipboard content changes
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

; Update ListView with clipboard history
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
            mergedItems .= itemIndex . "`r`n" .
                clipHistory[itemIndex] .
                (index < selectedItems.Length ? "`r`n`r`n" : "")
        }
        contentViewer.Value := mergedItems
    } else
        contentViewer.Value := clipHistory[selectedItems[1]]
}

; Save edited content back to clipboard history
saveContent(LV, contentViewer, clipHistoryGui, andPaste := false) {
    global clipHistory
    selectedItems := getSelected(LV)
    if (selectedItems.Length = 0)
        return

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

; Get all items in the ListView
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

; Paste text to active window
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

; Process clipboard items for pasting
prepareClipItems(LV := 0, formatTextEnable := false) {
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

; Paste selected clipboard items
pasteSelected(LV := 0, clipHistoryGui := 0, formatTextEnable := false) {
    contentItems := prepareClipItems(LV, formatTextEnable)
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
    contentItems := prepareClipItems(LV, formatTextEnable)
    for _, item in contentItems {
        if (formatTextEnable)
            item := formatText(item)
        clipHistory.Push(item)
    }
    updateLV(LV)
}

; Delete selected clipboard history items
deleteSelected(LV, clipHistoryGui) {
    global clipHistory

    selectedItems := getSelected(LV)
    if (selectedItems.Length = 0)
        return

    ; Sort selected items in descending order
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

; Move selected item up or down in clipboard history
moveSelectedItem(LV, contentViewer, direction) {
    global clipHistory

    selectedRow := LV.GetNext(0)
    if (!selectedRow)
        return

    currentIndex := Integer(LV.GetText(selectedRow, 1))
    targetIndex := currentIndex + direction

    if (targetIndex < 1 || targetIndex > clipHistory.Length)
        return

    ; Swap items
    temp := clipHistory[currentIndex]
    clipHistory[currentIndex] := clipHistory[targetIndex]
    clipHistory[targetIndex] := temp

    updateLV(LV)
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

    updateContent(LV, contentViewer)
}
