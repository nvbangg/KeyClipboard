; === CLIPBOARD MODULE ===

; Paste content
paste(content, useFormat := false) {
    global isFormatting
    isFormatting := true
    originalClip := ClipboardAll()

    if (useFormat = true)
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
pasteSelected(LV := 0, clipGui := 0, formatMode := 0, useSavedTab := false) {
    selectedItems := getSelectedItems(LV, useSavedTab)
    if (!IsObject(selectedItems) || selectedItems.Length < 1)
        return

    if (clipGui)
        clipGui.Destroy()

    if (formatMode = -1) {
        for index, item in selectedItems {
            paste(item.original)
            Send("{Enter}")
        }
        return
    }

    ; For normal text modes (plain or formatted)
    mergedItems := ""
    for index, item in selectedItems
        mergedItems .= item.text . (index < selectedItems.Length ? "`r`n" : "")

    if (formatMode = 1)
        paste(mergedItems, true)
    else
        paste(mergedItems, false)
}

; Paste item from history
pastePrev(offset := 0, formatMode := 0) {
    global historyTab

    if (historyTab.Length < offset + 1) {
        showNotification("Not enough items in clipboard history")
        return
    }

    item := historyTab[historyTab.Length - offset]
    if (formatMode == -1)
        paste(item.original)
    else
        paste(item.text, formatMode)
}

; Paste item from saved tab by position (position starts from 1)
pasteByPosition(position := 1, formatMode := 0) {
    global savedTab

    if (position < 1 || position > savedTab.Length) {
        showNotification("Position " . position . " does not exist in saved items")
        return
    }

    item := savedTab[position]
    if (formatMode == -1)
        paste(item.original)
    else
        paste(item.text, formatMode)
}

; Paste item from saved tab
pastePrevFromSaved(offset := 0, formatMode := 0) {
    global savedTab

    if (savedTab.Length < offset + 1) {
        showNotification("Not enough items in saved items list")
        return
    }

    item := savedTab[savedTab.Length - offset]
    if (formatMode == -1)
        paste(item.original)
    else
        paste(item.text, formatMode)
}

; Paste with specialized formatting options
pasteSpecific() {
    global historyTab

    if (historyTab.Length < 2) {
        showNotification("Not enough items in clipboard history")
        return
    }
    latest := historyTab[historyTab.Length].text
    beforeLatest := historyTab[historyTab.Length - 1].text
    content := beforeLatest . "_" . latest

    content := removeAccents(content)
    content := StrReplace(content, " ", "_")

    paste(content)
}

; Delete selected items (works for both clipboard and saved items)
deleteSelected(LV, clipGui := 0, useSavedTab := false) {
    global historyTab, savedTab
    if (!isListViewFocused()) {
        Send("{Delete}")
        return
    }

    selectedIndex := getSelectedIndex(LV)
    if (selectedIndex.Length = 0)
        return

    ; Sort selected items in descending order
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

    if (useSavedTab) {
        for i, item in selectedIndex
            savedTab.RemoveAt(item)
        ; Save changes after deleting items
        saveSavedItems()
    }
    else {
        for i, item in selectedIndex
            historyTab.RemoveAt(item)
    }
    updateLV(LV, "", useSavedTab)
}

clearClipboard(clipGui := 0, useSavedTab := false) {
    global historyTab, savedTab, clipGuiInstance

    ; Clear the items from the appropriate source
    if (useSavedTab) {
        savedTab := []
        saveSavedItems()
    }
    else
        historyTab := []

    ; Safely destroy passed GUI
    safeDestroyGui(clipGui)

    ; Also close the clipboard history window if it exists
    safeDestroyGui(clipGuiInstance)
    clipGuiInstance := 0

    showNotification("All " . (useSavedTab ? "saved items" : "clipboard items") . " have been cleared")
}

; Save edited content back (works for both clipboard and saved items)
saveContent(LV, contentViewer, clipGui, useSavedTab := false) {
    global historyTab, savedTab
    selectedItems := getSelectedIndex(LV)

    clipTab := useSavedTab ? savedTab : historyTab

    ; Check if we have valid items in both sources
    if (selectedItems.Length = 0 || clipTab.Length = 0) {
        updateLV(LV, "", useSavedTab)
        return
    }

    ; Check if the selected index is valid
    if (selectedItems.Length = 1) {
        if (selectedItems[1] > 0 && selectedItems[1] <= clipTab.Length) {
            ; Save new text content
            newText := contentViewer.Value
            clipTab[selectedItems[1]].text := newText
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

            ; Save changes if on saved tab
            if (useSavedTab)
                saveSavedItems()

            showNotification("Changes saved")
        } else {
            showNotification("Invalid item index")
        }
    } else {
        showNotification("Cannot save changes when multiple items are selected.")
        return
    }

    ; Update the correct global variable
    if (useSavedTab)
        savedTab := clipTab
    else
        historyTab := clipTab

    updateLV(LV, "", useSavedTab)
}

; Save items from clipboard to saved items
saveToSavedItems(LV := 0) {
    global historyTab, savedTab
    selectedItems := getSelectedItems(LV, false)

    if (!IsObject(selectedItems) || selectedItems.Length < 1)
        return

    for _, item in selectedItems {
        savedTab.Push({
            text: item.text,
            original: item.original
        })
    }

    ; Save to file after adding new items
    saveSavedItems()
    showNotification("Item" . (selectedItems.Length > 1 ? "s" : "") . " added to Saved Items")
}

; Save selected items to clipboard with optional formatting
saveToClipboard(LV := 0, formatTextEnable := false) {
    global historyTab
    selectedItems := getSelectedItems(LV, false)

    if (!IsObject(selectedItems) || selectedItems.Length < 1)
        return
    ; Number of items added
    addedCount := 0
    ; Process each item separately instead of merging them
    for _, item in selectedItems {
        ; New content after formatting (if needed)
        newText := formatTextEnable ? formatText(item.text) : item.text

        historyTab.Push({
            text: newText,
            original: item.original
        })

        addedCount++
    }

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

            LV.Modify(0, "-Select")

            loop addedCount {
                currentRow := startRow + A_Index - 1
                if (currentRow <= rowCount)
                    LV.Modify(currentRow, "Select")
            }

            LV.Modify(rowCount, "Focus Vis")

            if (contentViewer)
                updateContent(LV, contentViewer, false)
        }
    }

    showNotification(addedCount . " item(s) added to clipboard history")
}

; Creates a context menu from an array of menu items
createContextMenu(menuItems) {
    contextMenu := Menu()

    for item in menuItems {
        if (item.Length = 0)
            contextMenu.Add()  ; Add separator
        else
            contextMenu.Add(item[1], item[2])  ; Add label and callback
    }

    return contextMenu
}
