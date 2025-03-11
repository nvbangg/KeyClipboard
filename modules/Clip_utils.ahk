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

Paste(text, formatTextEnable := false) {
    global isFormatting, clipboardHistory
    isFormatting := true
    originalClip := ClipboardAll()

    if (formatTextEnable)
        text := FormatText(text)
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
PasteSelected(LV := 0, clipHistoryGui := 0, formatTextEnable := false) {
    global clipboardHistory, prefix_textEnabled
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
        if (clipboardHistory.Length = 0)
            return
        contentToPaste := clipboardHistory.Clone()
    }

    if (prefix_textEnabled && formatTextEnable) {
        index := contentToPaste.Length
        while (index > 1) {
            contentToPaste[index] := contentToPaste[index - 1] . "_" . contentToPaste[index]
            index--
        }
    }
    combinedContent := ""
    for index, content in contentToPaste
        combinedContent .= content . (index < contentToPaste.Length ? "`r`n" : "")
    Paste(combinedContent, formatTextEnable)
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
        clipboardHistory.RemoveAt(item)

    LV.Delete()
    UpdateLV(LV)
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
        return
    }

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
        ShowNotification("Cannot save changes when multiple items are selected.")
    }
}

; Save changes and then paste selected item(s)
SaveAndPasteSelected(LV, contentViewer, clipHistoryGui) {
    global clipboardHistory

    selectedItems := GetSelected(LV)
    if (selectedItems.Length = 0)
        return

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
