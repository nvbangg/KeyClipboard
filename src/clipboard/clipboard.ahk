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

    ; Format only the latest part using specific format options
    if (specificRemoveSpecialEnabled)
        latest := removeSpecial(latest)
    if (specificRemoveAccentsEnabled)
        latest := removeAccents(latest)
    if (specificNormSpaceEnabled)
        latest := normSpace(latest)

    ; Apply line break option
    switch specificLineOption {
        case 1: latest := trimLines(latest)
        case 2: latest := removeLineBreaks(latest)
    }

    ; Apply case option
    switch specificCaseOption {
        case 1: latest := StrUpper(latest)
        case 2: latest := StrLower(latest)
        case 3: latest := TitleCase(latest)
        case 4: latest := SentenceCase(latest)
    }

    ; Apply separator option
    switch specificSeparatorOption {
        case 1: latest := StrReplace(latest, " ", "_")
        case 2: latest := StrReplace(latest, " ", "-")
        case 3: latest := StrReplace(latest, " ", "")
    }

    ; Create content based on specificUseBeforeLatest setting
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
        for i, item in selectedIndex
            savedTab.RemoveAt(item)
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

    if (useSavedTab) {
        ; Add confirmation dialog when clearing Saved tab
        result := MsgBox("Are you sure you want to clear all saved items?",
            "Confirm Clear Saved Items", "YesNo 262144") ; YesNo with AlwaysOnTop flag

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

    if (selectedItems.Length = 1) {
        if (selectedItems[1] > 0 && selectedItems[1] <= clipTab.Length) {
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
        } else {
            showNotification("Invalid item index")
        }
    } else {
        showNotification("Cannot save changes when multiple items are selected.")
        return
    }

    if (useSavedTab)
        savedTab := clipTab
    else
        historyTab := clipTab

    updateLV(LV, "", useSavedTab)
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
