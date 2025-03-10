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

; Helper function to paste formatted text while preserving clipboard
PasteWithFormat(text, preserveClipboard := true) {
    global isFormatting

    isFormatting := true
    originalClip := preserveClipboard ? ClipboardAll() : ""

    A_Clipboard := text
    ClipWait(0.3)
    Send("^v")
    Sleep(100)

    if (preserveClipboard) {
        A_Clipboard := originalClip
        ClipWait(0.3)
        Sleep(100)
    }

    isFormatting := false
}

; Populate the ListView with clipboard history items
PopulateListView(LV) {
    global clipboardHistory

    for index, content in clipboardHistory {
        displayContent := StrLen(content) > 100 ? SubStr(content, 1, 100) . "..." : content
        LV.Add(, index, displayContent)
    }

    ; Set numeric sorting for column 1
    LV.ModifyCol(1, "Integer")

    LV.Modify(1, "Select Focus")
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

; Show context menu for right-click
ShowContextMenu(LV, clipHistoryGui, Item, IsRightClick, X, Y) {
    if (Item = 0)
        return

    selectedItems := GetSelectedItems(LV)
    if (selectedItems.Length = 0)
        return

    contextMenu := Menu()

    if (selectedItems.Length = 1) {
        contextMenu.Add("Paste", (*) => PasteSelected(LV, clipHistoryGui))
        contextMenu.Add("Format Paste", (*) => FormatPasteSelected(LV, clipHistoryGui))
    } else {
        contextMenu.Add("Paste Selected Items", (*) => PasteSelected(LV, clipHistoryGui))
        contextMenu.Add("Format Paste Selected Items", (*) => FormatPasteSelected(LV, clipHistoryGui))
    }

    contextMenu.Add()
    contextMenu.Add(selectedItems.Length > 1 ? "Delete Selected Items" : "Delete Item",
        (*) => DeleteSelected(LV, clipHistoryGui))
    contextMenu.Show(X, Y)
}

; Get all selected items in the ListView
GetSelectedItems(LV) {
    selectedItems := []
    rowNum := 0

    loop {
        rowNum := LV.GetNext(rowNum)
        if !rowNum
            break

        selectedItems.Push(Integer(LV.GetText(rowNum, 1)))
    }

    return selectedItems
}

; Paste selected item(s)
PasteSelected(LV, clipHistoryGui) {
    global clipboardHistory

    selectedItems := GetSelectedItems(LV)
    if (selectedItems.Length = 0)
        return

    clipHistoryGui.Destroy()

    combinedContent := ""
    for index, item in selectedItems {
        combinedContent .= clipboardHistory[item] . (index < selectedItems.Length ? "`r`n" : "")
    }

    PasteWithFormat(combinedContent)
}

; Get all items from ListView in display order
GetAllItemsFromListView(LV) {
    global clipboardHistory
    contentArray := []

    rowCount := LV.GetCount()
    loop rowCount {
        rowNum := A_Index
        itemIndex := Integer(LV.GetText(rowNum, 1))
        contentArray.Push(clipboardHistory[itemIndex])
    }

    return contentArray
}

; Format and paste selected item(s)
FormatPasteSelected(LV, clipHistoryGui) {
    global clipboardHistory, prefix_textEnabled

    selectedItems := GetSelectedItems(LV)
    if (selectedItems.Length = 0)
        return

    formattedContent := ""
    for i, item in selectedItems {
        text := clipboardHistory[item]
        prefix := (item > 1 && prefix_textEnabled) ? clipboardHistory[item - 1] : ""
        formattedText := FormatClipboardText(text, prefix)
        formattedContent .= formattedText . (i < selectedItems.Length ? "`r`n" : "")
    }

    clipHistoryGui.Destroy()
    PasteWithFormat(formattedContent)
}

; Format and paste all items
FormatPasteAllItems(LV, clipHistoryGui) {
    global clipboardHistory, prefix_textEnabled

    ; Get all items in ListView order with their potential prefixes
    itemData := GetAllItemsWithPrefixes(LV)

    ; Now it's safe to destroy the GUI
    clipHistoryGui.Destroy()

    ; Process the collected data
    formattedContent := ""
    for index, item in itemData {
        formattedText := FormatClipboardText(item.content, prefix_textEnabled ? item.prefix : "")
        formattedContent .= formattedText . (index < itemData.Length ? "`r`n" : "")
    }

    PasteWithFormat(formattedContent)
}

; Get all items from ListView with their prefixes
GetAllItemsWithPrefixes(LV) {
    global clipboardHistory
    itemData := []

    rowCount := LV.GetCount()
    loop rowCount {
        rowNum := A_Index
        itemIndex := Integer(LV.GetText(rowNum, 1))

        ; Get the prefix from the previous item in the list if available
        prevIndex := 0
        if (rowNum > 1) {
            prevIndex := Integer(LV.GetText(rowNum - 1, 1))
        }

        itemData.Push({
            content: clipboardHistory[itemIndex],
            prefix: prevIndex > 0 ? clipboardHistory[prevIndex] : ""
        })
    }

    return itemData
}

; Delete selected item(s)
DeleteSelected(LV, clipHistoryGui) {
    global clipboardHistory

    selectedItems := GetSelectedItems(LV)
    if (selectedItems.Length = 0)
        return

    ; Sort in descending order to avoid index issues when deleting
    DescendingSort(selectedItems)

    for i, item in selectedItems
        clipboardHistory.RemoveAt(item)

    ; Refresh the ListView
    LV.Delete()
    PopulateListView(LV)

    if (clipboardHistory.Length = 0) {
        clipHistoryGui.Destroy()
        ShowNotification("All items in clipboard history have been deleted.")
    } else {
        ShowNotification(selectedItems.Length > 1 ? "Selected items deleted." : "Selected item deleted.")
    }
}

; Paste all items with line breaks
PasteAllItems(LV, clipHistoryGui) {
    global clipboardHistory

    ; Get all items in ListView order BEFORE destroying the GUI
    contentArray := GetAllItemsFromListView(LV)

    ; Now it's safe to destroy the GUI
    clipHistoryGui.Destroy()

    ; Process the collected content
    combinedContent := ""
    for index, content in contentArray {
        combinedContent .= content . (index < contentArray.Length ? "`r`n" : "")
    }

    PasteWithFormat(combinedContent)
}

; Clear all clipboard history
ClearAllHistory(clipHistoryGui) {
    global clipboardHistory

    clipboardHistory := []
    clipHistoryGui.Destroy()
    ShowNotification("All items in clipboard history have been cleared.")
}