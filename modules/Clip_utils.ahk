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
            if (clipHistory.Length > 50)
                clipHistory.RemoveAt(1)
        }
    }
}

; Populate the ListView with clipboard history items
updateLV(LV) {
    global clipHistory
    for index, content in clipHistory {
        displayContent := StrLen(content) > 100 ? SubStr(content, 1, 100) . "..." : content
        LV.Add(, index, displayContent)
    }

    ; Set numeric sorting for column 1
    LV.ModifyCol(1, "Integer")
    LV.Modify(1, "Select Focus")
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

    ; Khôi phục clipboard gốc
    A_Clipboard := originalClip
    ClipWait(0.3)
    Sleep(50)

    isFormatting := false
}

; Paste clipboard items (selected or all)
pasteSelected(LV := 0, clipHistoryGui := 0, formatTextEnable := false) {
    global clipHistory, prefix_textEnabled
    contentPaste := []
    if (LV) {
        selectedItems := getSelected(LV)
        if (selectedItems.Length = 0)
            return
        for _, index in selectedItems
            contentPaste.Push(clipHistory[index])
        if (clipHistoryGui)
            clipHistoryGui.Destroy()
    }
    ; If no ListView provided, use all items
    else {
        if (clipHistory.Length = 0)
            return
        contentPaste := clipHistory.Clone()
    }

    if (prefix_textEnabled && formatTextEnable) {
        index := contentPaste.Length
        while (index > 1) {
            contentPaste[index] := contentPaste[index - 1] . "_" . contentPaste[index]
            index--
        }
    }

    mergedItems := ""
    for index, item in contentPaste
        mergedItems .= item . (index < contentPaste.Length ? "`r`n" : "")
    paste(mergedItems, formatTextEnable)
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
    try {
        loop {
            rowNum := LV.GetNext(rowNum)
            if (!rowNum)
                break
            selectedItems.Push(Integer(LV.GetText(rowNum, 1)))
        }
    } catch Error as e {
        MsgBox("Error in GetSelectedItems: " . e.Message)
        return []
    }
    return selectedItems
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
    LV.Delete()
    updateLV(LV)
}

; Update the content viewer with the content of selected items
updateContent(LV, contentViewer) {
    global clipHistory
    selectedItems := getSelected(LV)
    if (selectedItems.Length = 0) {
        contentViewer.Value := ""
        return
    }

    ; If multiple items are selected, show all their contents with separators
    if (selectedItems.Length > 1) {
        mergedItems := ""
        for index, itemIndex in selectedItems {
            mergedItems .= "--- Item " . itemIndex . " ---`r`n" .
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
                if Integer(LV.GetText(rowNum, 1)) = selectedItems[1] {
                    displayContent := StrLen(contentViewer.Value) > 100 ?
                        SubStr(contentViewer.Value, 1, 100) . "..." : contentViewer.Value
                    LV.Modify(rowNum, , selectedItems[1], displayContent)
                    break
                }
                rowNum++
            }
            showNotification("Changes saved to item #" . selectedItems[1])
        }
    } else if (!andPaste)
        showNotification("Cannot save changes when multiple items are selected.")

    ; Paste functionality
    if (andPaste) {
        clipHistoryGui.Destroy()
        mergedItems := ""
        for index, item in selectedItems
            mergedItems .= clipHistory[item] . (index < selectedItems.Length ? "`r`n" : "")
        paste(mergedItems)
    }
}
