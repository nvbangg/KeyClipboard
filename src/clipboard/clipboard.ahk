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
    Sleep(100)

    isProcessing := false
}

pasteSelected(LV := 0, clipGui := 0, formatMode := 0, useSavedTab := false) {
    selectedItems := getSelectedItems(LV, useSavedTab)
    if (!IsObject(selectedItems) || selectedItems.Length < 1) {
        if (LV = 0)
            showNotification((useSavedTab ? "Saved items" : "History") . " empty")
        return
    }

    if (clipGui)
        clipGui.Destroy()

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

; Paste selected items with Tab separator between each item
pasteSelectedWithTab(LV := 0, clipGui := 0, formatMode := 0, useSavedTab := false) {
    selectedItems := getSelectedItems(LV, useSavedTab)
    if (!IsObject(selectedItems) || selectedItems.Length < 1) {
        if (LV = 0)
            showNotification((useSavedTab ? "Saved items" : "History") . " empty")
        return
    }
    if (clipGui)
        clipGui.Destroy()

    ; Paste each selected item with Tab separator
    for index, item in selectedItems {
        if (index > 1)
            Send("{Tab}")

        if (formatMode == -1)
            paste(item.original)
        else
            paste(item.text, formatMode)
    }
}

; historyTab: index 1=latest, savedTab: index 1=first saved
pasteIndex(index := 1, formatMode := 0, useSavedTab := false) {
    global historyTab, savedTab

    clipTab := useSavedTab ? savedTab : historyTab

    if (index < 1 || index > clipTab.Length) {
        showNotification("Not exist in " . (useSavedTab ? "saved items" : "history"))
        return
    }

    if (useSavedTab)
        item := clipTab[index]  ; Direct: 1=first saved, 2=second saved
    else
        item := clipTab[clipTab.Length - index + 1]  ; Reverse: 1=latest, 2=second latest

    if (formatMode == -1)
        paste(item.original)
    else
        paste(item.text, formatMode)
}

; Paste second latest item, Tab, then latest item
pasteWithTab(formatMode := 0, useSavedTab := false) {
    global historyTab, savedTab

    clipTab := useSavedTab ? savedTab : historyTab

    if (clipTab.Length < 2) {
        showNotification("Not enough items in " . (useSavedTab ? "saved items" : "history"))
        return
    }

    if (useSavedTab) {
        firstItem := clipTab[1]   ; First saved item
        secondItem := clipTab[2]  ; Second saved item
    } else {
        firstItem := clipTab[clipTab.Length - 1]  ; Second latest
        secondItem := clipTab[clipTab.Length]     ; Latest
    }

    if (formatMode == -1)
        paste(firstItem.original)
    else
        paste(firstItem.text, formatMode)

    Send("{Tab}")

    if (formatMode == -1)
        paste(secondItem.original)
    else
        paste(secondItem.text, formatMode)
}

pasteWithBeforeLatest(formatLatest := false) {
    global historyTab

    if (historyTab.Length < 2) {
        showNotification("Not enough items in history")
        return
    }

    beforeLatest := historyTab[historyTab.Length - 1].text
    latest := historyTab[historyTab.Length].text
    if (formatLatest)
        latest := formatText(latest)
    paste(beforeLatest . "_" . latest)
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

    ; Sort
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

    showNotification("All " . (useSavedTab ? "saved items" : "history") . " have been cleared")
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
            saveSavedItems()

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

    saveSavedItems()
    showNotification("Added to Saved Items")
}

; Split selected items by lines and add as a new item
splitToLines(LV := 0, useSavedTab := false) {
    global historyTab, savedTab

    selectedItems := getSelectedItems(LV, useSavedTab)
    if (!IsObject(selectedItems) || selectedItems.Length < 1)
        return

    targetTab := useSavedTab ? savedTab : historyTab
    addedCount := 0

    for _, item in selectedItems {
        lines := StrSplit(item.text, "`n", "`r")
        
        for _, line in lines {
            trimmedLine := Trim(line)
            if (trimmedLine != "") {
                targetTab.Push({
                    text: trimmedLine,
                    original: trimmedLine  
                })
                addedCount++
            }
        }
    }

    if (useSavedTab)
        saveSavedItems()

    if (LV) {
        updateLV(LV, "", useSavedTab)
        
        rowCount := LV.GetCount()
        if (rowCount > 0 && addedCount > 0) {
            startRow := rowCount - addedCount + 1
            if (startRow < 1)
                startRow := 1

            LV.Modify(0, "-Select")  

            ; Select newly added items
            loop addedCount {
                currentRow := startRow + A_Index - 1
                if (currentRow <= rowCount)
                    LV.Modify(currentRow, "Select")
            }

            LV.Modify(rowCount, "Focus Vis") 
        }
    }

    showNotification(addedCount . " lines added to " . (useSavedTab ? "saved items" : "history"))
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
                contentViewer := parentGui.FindControl("Edit1")
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
                updateContent(LV, contentViewer, false)
        }
    }

    showNotification("Added to history")
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
        saveSavedItems()
    } else {
        historyTab := clipTab
    }

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

; Filter items by search text
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

    ; Search for items containing the search text
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
