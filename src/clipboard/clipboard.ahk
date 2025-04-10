#Include clip_utils.ahk
#Include clip_format.ahk
#Include clip_storage.ahk

paste(content, useFormat := false) {
    global isProcessing
    isProcessing := true
    originalClip := ClipboardAll()

    if (useFormat = true)
        content := formatText(content)

    A_Clipboard := content
    ClipWait(0.3)
    Send("^v")
    Sleep(50)

    A_Clipboard := originalClip
    ClipWait(0.3)
    Sleep(50)

    isProcessing := false
}

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

    mergedItems := ""
    for index, item in selectedItems
        mergedItems .= item.text . (index < selectedItems.Length ? "`r`n" : "")

    if (formatMode = 1)
        paste(mergedItems, true)
    else
        paste(mergedItems, false)
}

pastePrev(offset := 0, formatMode := 0, useSavedTab := false) {
    global historyTab, savedTab

    clipTab := useSavedTab ? savedTab : historyTab
    tabName := useSavedTab ? "saved items list" : "clipboard history"

    if (clipTab.Length < offset + 1) {
        showNotification("Not enough items in " . tabName)
        return
    }

    item := clipTab[clipTab.Length - offset]

    if (formatMode == -1)
        paste(item.original)
    else
        paste(item.text, formatMode)
}

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

pasteSpecific() {
    global historyTab
    global specificRemoveAccentsEnabled, specificNormSpaceEnabled, specificRemoveSpecialEnabled
    global specificLineOption, specificCaseOption, specificSeparatorOption, specificUseBeforeLatest

    if (historyTab.Length < 2) {
        showNotification("Not enough items in clipboard history")
        return
    }

    latest := historyTab[historyTab.Length].text
    beforeLatest := historyTab[historyTab.Length - 1].text

    if (specificRemoveSpecialEnabled)
        latest := removeSpecial(latest)
    if (specificRemoveAccentsEnabled)
        latest := removeAccents(latest)
    if (specificNormSpaceEnabled)
        latest := normSpace(latest)

    switch specificLineOption {
        case 1: latest := trimLines(latest)
        case 2: latest := removeLineBreaks(latest)
    }

    switch specificCaseOption {
        case 1: latest := StrUpper(latest)
        case 2: latest := StrLower(latest)
        case 3: latest := TitleCase(latest)
        case 4: latest := SentenceCase(latest)
    }

    switch specificSeparatorOption {
        case 1: latest := StrReplace(latest, " ", "_")
        case 2: latest := StrReplace(latest, " ", "-")
        case 3: latest := StrReplace(latest, " ", "")
    }

    content := specificUseBeforeLatest ? (beforeLatest . "_" . latest) : latest

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
        for _, item in selectedIndex
            savedTab.RemoveAt(item)
        saveSavedItems()
    }
    else {
        for i, item in selectedIndex
            historyTab.RemoveAt(item)
    }

    updateLV(LV, "", useSavedTab)

    rowCount := LV.GetCount()
    if (rowCount > 0) {
        LV.Modify(rowCount, "Select Focus Vis")
        LV.Focus()
        SetTimer(() => LV.Focus(), -50)
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

        if (useSavedTab)
            saveSavedItems()

        showNotification("Changes saved")
    }

    if (useSavedTab)
        savedTab := clipTab
    else
        historyTab := clipTab

    ; Update ListView with all items
    updateLV(LV, "", useSavedTab)

    ; Restore selection to original item if it existed
    if (originalIndex > 0) {
        ; Find the row with the same original index
        loop LV.GetCount() {
            rowNum := A_Index
            if (Integer(LV.GetText(rowNum, 1)) = originalIndex) {
                LV.Modify(rowNum, "Select Focus Vis")
                updateContent(LV, contentViewer, useSavedTab)
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

    for _, item in selectedItems {
        savedTab.Push({
            text: item.text,
            original: item.original
        })
    }

    saveSavedItems()
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

    if (targetIndex < 1 || targetIndex > clipTab.Length)
        return

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

filterItems(searchText := "", useSavedTab := false) {
    global historyTab, savedTab
    clipTab := useSavedTab ? savedTab : historyTab
    filteredItems := []

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
