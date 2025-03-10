; Clip_utils

; Initialize and track clipboard
InitClipboard() {
    global clipboardHistory := []
    OnClipboardChange(ClipChanged, 1)
}

; Process clipboard content changes
ClipChanged(Type) {
    global clipboardHistory, isFormatting

    if (isFormatting)
        return

    if (Type = 1 && A_Clipboard != "") {
        try {
            clipboardHistory.Push(A_Clipboard)
            if (clipboardHistory.Length > 50)
                clipboardHistory.RemoveAt(1)
        }
    }
}

; Populate the ListView with clipboard history items
UpdateLV(LV) {
    global clipboardHistory

    for index, content in clipboardHistory {
        displayContent := StrLen(content) > 100 ? SubStr(content, 1, 100) . "..." : content
        LV.Add(, index, displayContent)
    }

    ; Set numeric sorting for column 1
    LV.ModifyCol(1, "Integer")

    LV.Modify(1, "Select Focus")
}

Paste(text, formatText := false) {
    global isFormatting, prefix_textEnabled, clipboardHistory
    isFormatting := true
    originalClip := ClipboardAll()

    if (formatText) {
        if (prefix_textEnabled)
            prefix := clipboardHistory[clipboardHistory.Length - 1]
        else
            prefix := ""
        text := FormatText(text, prefix)
    }

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
PasteSelected(LV := 0, clipHistoryGui := 0, formatText := false) {
    global clipboardHistory
    contentToPaste := []
    if (LV) {
        selectedIndices := GetSelected(LV)
        if (selectedIndices.Length = 0)
            return
        for _, index in selectedIndices
            contentToPaste.Push(clipboardHistory[index])
        if (clipHistoryGui)
            clipHistoryGui.Destroy()
    }
    ; If no ListView provided, use all items
    else {
        if (clipboardHistory.Length = 0) {
            return
        }
        contentToPaste := clipboardHistory.Clone()
    }

    combinedContent := ""
    for index, content in contentToPaste
        combinedContent .= content . (index < contentToPaste.Length ? "`r`n" : "")

    Paste(combinedContent, formatText)
}

GetAll(LV) {
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

; Helper function to sort array in descending order
DescendingSort(array) {
    ; Manual bubble sort implementation for descending order
    n := array.Length
    loop n - 1 {
        i := A_Index
        loop n - i {
            j := A_Index
            if (array[j] < array[j + 1]) {
                temp := array[j]
                array[j] := array[j + 1]
                array[j + 1] := temp
            }
        }
    }
    return array
}

; Get all selected items in the ListView
GetSelected(LV) {
    selectedItems := []
    rowNum := 0

    if (Type(LV) = "Array") {
        return LV
    }
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
DeleteSelected(LV, clipHistoryGui) {
    global clipboardHistory

    selectedItems := GetSelected(LV)
    if (selectedItems.Length = 0)
        return

    ; Sort in descending order to avoid index issues when deleting
    DescendingSort(selectedItems)

    for i, item in selectedItems
        clipboardHistory.RemoveAt(item)

    ; Refresh the ListView
    LV.Delete()
    UpdateLV(LV)

    if (clipboardHistory.Length = 0) {
        clipHistoryGui.Destroy()
        ShowNotification("All items in clipboard history have been deleted.")
    } else {
        ShowNotification(selectedItems.Length > 1 ? "Selected items deleted." : "Selected item deleted.")
    }
}

; Clear all clipboard history
ClearAllHistory(clipHistoryGui) {
    global clipboardHistory

    clipboardHistory := []
    clipHistoryGui.Destroy()
    ShowNotification("All items in clipboard history have been cleared.")
}
; Update the content viewer with the content of selected items
UpdateContentViewer(LV, contentViewer) {
    global clipboardHistory

    selectedItems := GetSelected(LV)
    if (selectedItems.Length = 0) {
        contentViewer.Value := ""
        return
    }

    ; If multiple items are selected, show all their contents with separators
    if (selectedItems.Length > 1) {
        combinedContent := ""
        for index, itemIndex in selectedItems {
            combinedContent .= "--- Item " . itemIndex . " ---`r`n" .
                clipboardHistory[itemIndex] .
                (index < selectedItems.Length ? "`r`n`r`n" : "")
        }
        contentViewer.Value := combinedContent
    } else {
        ; Single item selected
        contentViewer.Value := clipboardHistory[selectedItems[1]]
    }
}

; Save changes from the content viewer back to the clipboard history
SaveContentChanges(LV, contentViewer, clipHistoryGui) {
    global clipboardHistory

    selectedItems := GetSelected(LV)
    if (selectedItems.Length = 0) {
        ShowNotification("Select an item to save changes.")
        return
    }

    ; If only one item is selected, save the changes directly
    if (selectedItems.Length = 1) {
        clipboardHistory[selectedItems[1]] := contentViewer.Value

        ; Update the ListView display for this item
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

        ShowNotification("Changes saved to item #" . selectedItems[1])
    } else {
        ; Multiple items selected - can't edit multiple items at once in this way
        ShowNotification("Cannot save changes when multiple items are selected.")
    }
}

; Save changes and then paste selected item(s)
SaveAndPasteSelected(LV, contentViewer, clipHistoryGui) {
    global clipboardHistory

    selectedItems := GetSelected(LV)
    if (selectedItems.Length = 0)
        return

    ; If only one item is selected, save the changes before pasting
    if (selectedItems.Length = 1) {
        clipboardHistory[selectedItems[1]] := contentViewer.Value
    }

    clipHistoryGui.Destroy()

    combinedContent := ""
    for index, item in selectedItems {
        combinedContent .= clipboardHistory[item] . (index < selectedItems.Length ? "`r`n" : "")
    }

    Paste(combinedContent)
}
