#Include clip_utils.ahk
#Include clip_format.ahk
#Include clip_storage.ahk

paste(content, useFormat := false) {
    global isProcessing
    isProcessing := true
    originalClip := ClipboardAll()  ; Backup current clipboard

    if (useFormat = true)
        content := formatText(content)

    A_Clipboard := content
    ClipWait(0.3)
    Send("^v")
    Sleep(50)

    A_Clipboard := originalClip  ; Restore original clipboard
    ClipWait(0.3)
    Sleep(50)

    isProcessing := false
}

; Paste selected items from ListView with merge and format options
pasteSelected(LV := 0, clipGui := 0, formatMode := 0, useSavedTab := false) {
    selectedItems := getSelectedItems(LV, useSavedTab)
    if (!IsObject(selectedItems) || selectedItems.Length < 1)
        return

    if (clipGui)
        clipGui.Destroy()

    ; Format mode -1: paste original items individually with line breaks
    if (formatMode = -1) {
        for index, item in selectedItems {
            paste(item.original)
            Send("{Enter}")
        }
        return
    }

    ; Merge selected items with line breaks
    mergedItems := ""
    for index, item in selectedItems
        mergedItems .= item.text . (index < selectedItems.Length ? "`r`n" : "")

    if (formatMode = 1)
        paste(mergedItems, true)
    else
        paste(mergedItems, false)
}

; Paste previous item by offset (0=latest, 1=second latest, etc.)
pastePrev(offset := 0, formatMode := 0, useSavedTab := false) {
    global historyTab, savedTab

    clipTab := useSavedTab ? savedTab : historyTab
    tabName := useSavedTab ? "saved items list" : "clipboard history"

    if (clipTab.Length < offset + 1) {
        showNotification("Not enough items in " . tabName)
        return
    }

    item := clipTab[clipTab.Length - offset]  ; Get item from end (latest first)

    if (formatMode == -1)
        paste(item.original)  ; Paste without any formatting
    else
        paste(item.text, formatMode)  ; Paste with optional formatting
}

; Paste item by index with different behaviors for historyTab vs savedTab
; historyTab: index 1=latest (reverse), savedTab: index 1=first saved (direct)
pasteByIndex(index := 1, formatMode := 0, useSavedTab := false) {
    global historyTab, savedTab

    clipTab := useSavedTab ? savedTab : historyTab
    tabName := useSavedTab ? "saved items" : "clipboard history"

    if (index < 1 || index > clipTab.Length) {
        showNotification("Index " . index . " does not exist in " . tabName)
        return
    }

    if (useSavedTab) {
        item := clipTab[index]  ; Direct: 1=first saved, 2=second saved
    } else {
        item := clipTab[clipTab.Length - index + 1]  ; Reverse: 1=latest, 2=second latest
    }

    if (formatMode == -1)
        paste(item.original)
    else
        paste(item.text, formatMode)
}

; Paste first item, Tab, then second item (useful for forms)
pasteWithTab(formatMode := 0, useSavedTab := false) {
    global historyTab, savedTab

    clipTab := useSavedTab ? savedTab : historyTab
    tabName := useSavedTab ? "saved items list" : "clipboard history"

    if (clipTab.Length < 2) {
        showNotification("Not enough items in " . tabName)
        return
    }

    ; Different item selection logic for different data sources
    if (useSavedTab) {
        firstItem := clipTab[1]     ; First saved item
        secondItem := clipTab[2]    ; Second saved item
    } else {
        firstItem := clipTab[clipTab.Length]      ; Latest from history
        secondItem := clipTab[clipTab.Length - 1] ; Second latest from history
    }

    ; Paste first item
    if (formatMode == -1)
        paste(firstItem.original)
    else
        paste(firstItem.text, formatMode)
    
    Sleep(100)
    Send("{Tab}")
    
    ; Paste second item
    Sleep(100)
    if (formatMode == -1)
        paste(secondItem.original)
    else
        paste(secondItem.text, formatMode)
}

pasteWithBeforeLatest(formatLatest := false) {
    global historyTab

    if (historyTab.Length < 2) {
        showNotification("Not enough items in clipboard history")
        return
    }

    beforeLatest := historyTab[historyTab.Length - 1].text
    latest := historyTab[historyTab.Length].text
    if (formatLatest) {
        latest := formatText(latest)
    }
    content := beforeLatest . "_" . latest
    paste(content)
}

deleteSelected(LV, clipGui := 0, useSavedTab := false) {
    global historyTab, savedTab

    if (!isListViewFocused()) {
        Send("{Delete}")
        return
    }

    selectedIndex := getSelectedIndex(LV)
    if (selectedIndex.Length = 0)
        return

    ; Sort indices in descending order to avoid index shifting during deletion
    n := selectedIndex.Length
    loop n - 1 {
        i := A_Index
        loop n - i {
            j := A_Index
            if (selectedIndex[j] < selectedIndex[j + 1]) {
                temp := selectedIndex[j]
                selectedIndex[j] := selectedIndex[j + 1]
                selectedIndex[j + 1] := temp
            }
        }
    }

    ; Remove items from appropriate tab
    if (useSavedTab) {
        for _, item in selectedIndex
            savedTab.RemoveAt(item)
        saveSavedItems()
    }
    else {
        for i, item in selectedIndex
            historyTab.RemoveAt(item)
    }

    updateLV(LV, "", useSavedTab)

    ; Select last item after deletion
    rowCount := LV.GetCount()
    if (rowCount > 0) {
        LV.Modify(rowCount, "Select Focus Vis")
        LV.Focus()
        SetTimer(() => LV.Focus(), -50)  ; Ensure focus
    }
}

clearClipboard(clipGui := 0, useSavedTab := false) {
    global historyTab, savedTab, clipGuiInstance

    if (useSavedTab) {
        result := MsgBox("Are you sure you want to clear all saved items?",
            "Confirm Clear Saved Items", "YesNo 262144")

        if (result != "Yes")
            return

        savedTab := []
        saveSavedItems()
    }
    else
        historyTab := []

    destroyGui(clipGui)
    destroyGui(clipGuiInstance)
    clipGuiInstance := 0

    showNotification("All " . (useSavedTab ? "saved items" : "clipboard items") . " have been cleared")
}

; Save edited content from content viewer back to clipboard item
saveContent(LV, contentViewer, clipGui, useSavedTab := false) {
    global historyTab, savedTab

    selectedItems := getSelectedIndex(LV)
    clipTab := useSavedTab ? savedTab : historyTab

    if (selectedItems.Length = 0 || clipTab.Length = 0) {
        updateLV(LV, "", useSavedTab)
        return
    }

    ; Store original selection index to restore later
    originalIndex := selectedItems.Length = 1 ? selectedItems[1] : 0

    if (selectedItems.Length = 1 && selectedItems[1] > 0 && selectedItems[1] <= clipTab.Length) {
        newText := contentViewer.Value
        clipTab[selectedItems[1]].text := newText  ; Update item text

        ; Update ListView display
        rowNum := 1
        loop LV.GetCount() {
            if (Integer(LV.GetText(rowNum, 1)) = selectedItems[1]) {
                displayContent := StrLen(newText) > 100 ?
                    SubStr(newText, 1, 100) . "..." : newText
                LV.Modify(rowNum, , selectedItems[1], displayContent)
                break
            }
            rowNum++
        }

        if (useSavedTab)
            saveSavedItems()  ; Persist to file if saved items

        showNotification("Changes saved")
    }

    if (useSavedTab)
        savedTab := clipTab
    else
        historyTab := clipTab

    updateLV(LV, "", useSavedTab)

    if (originalIndex > 0) {
        ; Find the row with the same original index
        loop LV.GetCount() {
            rowNum := A_Index
            if (Integer(LV.GetText(rowNum, 1)) = originalIndex) {
                LV.Modify(rowNum, "Select Focus Vis")
                updateContent(LV, contentViewer, useSavedTab)  ; Refresh content viewer
                break
            }
        }
    }
}

saveToSavedItems(LV := 0) {
    global historyTab, savedTab

    selectedItems := getSelectedItems(LV, false)
    if (!IsObject(selectedItems) || selectedItems.Length < 1)
        return

    ; Copy items to saved list
    for _, item in selectedItems {
        savedTab.Push({
            text: item.text,
            original: item.original
        })
    }

    saveSavedItems()  ; Persist to file
    showNotification("Item" . (selectedItems.Length > 1 ? "s" : "") . " added to Saved Items")
}

saveToClipboard(LV := 0, formatTextEnable := false) {
    global historyTab

    selectedItems := getSelectedItems(LV, false)
    if (!IsObject(selectedItems) || selectedItems.Length < 1)
        return

    addedCount := 0
    for _, item in selectedItems {
        newText := formatTextEnable ? formatText(item.text) : item.text

        historyTab.Push({
            text: newText,
            original: item.original
        })

        addedCount++
    }

    ; Update ListView and select newly added items
    if (LV) {
        contentViewer := 0
        try {
            parentGui := GuiCtrlFromHwnd(LV.Hwnd).Gui
            if (parentGui)
                contentViewer := parentGui.FindControl("Edit1")  ; Find content viewer
        }
        updateLV(LV, "", false)  

        rowCount := LV.GetCount()
        if (rowCount > 0) {
            startRow := rowCount - addedCount + 1
            if (startRow < 1)
                startRow := 1

            LV.Modify(0, "-Select")  ; Clear all selections

            ; Select newly added items
            loop addedCount {
                currentRow := startRow + A_Index - 1
                if (currentRow <= rowCount)
                    LV.Modify(currentRow, "Select")
            }

            LV.Modify(rowCount, "Focus Vis")  ; Focus on last item

            if (contentViewer)
                updateContent(LV, contentViewer, false)  ; Update content viewer
        }
    }

    showNotification(addedCount . " item(s) added to clipboard history")
}

; Move selected item up or down in the list
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

    ; Check bounds
    if (targetIndex < 1 || targetIndex > clipTab.Length)
        return

    ; Swap items
    temp := clipTab[currentIndex]
    clipTab[currentIndex] := clipTab[targetIndex]
    clipTab[targetIndex] := temp

    if (useSavedTab) {
        savedTab := clipTab
        saveSavedItems()  ; Persist changes
    } else {
        historyTab := clipTab
    }

    ; Update ListView and select moved item
    updateLV(LV, "", useSavedTab)
    LV.Modify(0, "-Select")

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

; Filter items by search text (case-insensitive)
filterItems(searchText := "", useSavedTab := false) {
    global historyTab, savedTab
    clipTab := useSavedTab ? savedTab : historyTab
    filteredItems := []

    ; Return all items if no search text
    if (searchText = "") {
        for index, item in clipTab {
            filteredItems.Push({
                text: item.text,
                original: item.original,
                originalIndex: index
            })
        }
        return filteredItems
    }

    ; Search for items containing the search text (case-insensitive)
    searchTextLower := StrLower(searchText)
    for index, item in clipTab {
        if (item.HasProp("text") && item.text && InStr(StrLower(item.text), searchTextLower)) {
            filteredItems.Push({
                text: item.text,
                original: item.original,
                originalIndex: index
            })
        }
    }

    return filteredItems
}
