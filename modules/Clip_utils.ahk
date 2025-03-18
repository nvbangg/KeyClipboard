; === Clip_utils Module ===

paste(content, formatEnabled := false) {
    global isFormatting
    isFormatting := true
    originalClip := ClipboardAll()

    if (formatEnabled = true)
        content := formatText(content)

    A_Clipboard := content
    ClipWait(0.3)
    Send("^v")
    Sleep(50)

    ; Restore original clipboard
    A_Clipboard := originalClip
    ClipWait(0.3)
    Sleep(50)

    isFormatting := false
}

; formatMode: -1 = original, 0 = plain text, 1 = format text
pasteSelected(LV := 0, clipHistoryGui := 0, formatMode := 0) {
    contentItems := prepareClipItems(LV)
    if (!IsObject(contentItems) || contentItems.Length < 1)
        return
    if (clipHistoryGui)
        clipHistoryGui.Destroy()

    if (formatMode = -1) {
        for index, item in contentItems {
            paste(item.original)
            Send("{Enter}")
        }
        return
    }

    mergedItems := ""
    for index, item in contentItems
        mergedItems .= item.text . (index < contentItems.Length ? "`r`n" : "")

    paste(mergedItems, formatMode)
}

; Paste item from history
pastePrev(offset := 0, formatMode := 0) {
    global clipHistory

    if (clipHistory.Length < offset + 1) {
        showNotification("Not enough items in clipboard history")
        return
    }

    item := clipHistory[clipHistory.Length - offset]
    if (formatMode == -1)
        paste(item.original)
    else
        paste(item.text, formatMode)
}

; Paste with specialized formatting options
pasteSpecific() {
    global clipHistory

    if (clipHistory.Length < 2) {
        showNotification("Not enough items in clipboard history")
        return
    }
    latest := clipHistory[clipHistory.Length].text
    beforeLatest := clipHistory[clipHistory.Length - 1].text
    content := beforeLatest . "_" . latest

    content := removeAccents(content)

    paste(content)
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

; Initialize clipboard history tracking
initClipboard()
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
            clipHistory.Push({
                text: A_Clipboard,
                original: ClipboardAll()
            })
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
        displayContent := StrLen(content.text) > 100 ? SubStr(content.text, 1, 100) . "..." : content.text
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
                clipHistory[itemIndex].text .
                (index < selectedItems.Length ? "`r`n`r`n" : "")
        }
        contentViewer.Value := mergedItems
    } else
        contentViewer.Value := clipHistory[selectedItems[1]].text
}

; Save edited content back to clipboard history
saveContent(LV, contentViewer, clipHistoryGui, andPaste := false) {
    global clipHistory
    selectedItems := getSelected(LV)
    if (selectedItems.Length = 0)
        return

    if (selectedItems.Length = 1) {
        clipHistory[selectedItems[1]].text := contentViewer.Value
        ; Note: Original format is not updated when text is edited

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
            mergedItems .= clipHistory[item].text . (index < selectedItems.Length ? "`r`n" : "")
        clipHistoryGui.Destroy()
        paste(mergedItems)
        return
    }
    updateLV(LV)
}

; Merge selected items into clipboard history
saveToClipboard(LV := 0, formatTextEnable := false) {
    global isFormatting, clipHistory
    contentItems := prepareClipItems(LV)
    for _, item in contentItems {
        if (formatTextEnable) {
            formattedText := formatText(item.text)
            clipHistory.Push({
                text: formattedText,
                original: ClipboardAll(formattedText)
            })
        } else {
            clipHistory.Push(item)
        }
    }
    updateLV(LV)
}

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

deleteSelected(LV) {
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

clearClipboard(clipHistoryGui := 0) {
    if (clipHistoryGui)
        clipHistoryGui.Destroy()
    global clipHistory
    clipHistory := []
    showNotification("All items have been cleared")
}
