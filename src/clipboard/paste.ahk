paste(content, useFormat := false) {
    global isProcessing, pasteDelay, restoreDelay
    isProcessing := true
    originalClip := ClipboardAll()  ; Backup current clipboard

    if (useFormat = true)
        content := formatText(content)

    A_Clipboard := content
    ClipWait(0.3)
    Send("^v")
    Sleep(pasteDelay)

    A_Clipboard := originalClip  ; Restore original clipboard
    ClipWait(0.3)
    Sleep(restoreDelay)

    isProcessing := false
}

pasteSelected(LV := 0, clipGui := 0, formatMode := 0, useSaved := false) {
    global enterDelay, enterCount
    selectedItems := getSelectedItems(LV, clipGui, useSaved)
    if (!selectedItems)
        return

    if (formatMode = -1) {
        for index, item in selectedItems {
            paste(item.original)
            loop enterCount {
                Send("{Enter}")
                Sleep(enterDelay)
            }
        }
        return
    }

    mergedItems := ""
    for index, item in selectedItems
        mergedItems .= item.text . (index < selectedItems.Length ? "`r`n" : "")
    paste(mergedItems, formatMode = 1)
}

; Unified function for pasting with separator
pasteWithSeparator(separator, delayVar, LV := 0, clipGui := 0, formatMode := 0, useSaved := false) {
    global enterCount, tabCount
    selectedItems := getSelectedItems(LV, clipGui, useSaved)
    if (!selectedItems)
        return

    for index, item in selectedItems {
        if (index > 1) {
            if (separator = "{Enter}") {
                loop enterCount {
                    Send("{Enter}")
                    Sleep(%delayVar%)
                }
            } else if (separator = "{Tab}") {
                loop tabCount {
                    Send("{Tab}")
                    Sleep(%delayVar%)
                }
            } else {
                Send(separator)
                Sleep(%delayVar%)
            }
        }
        TabUtils.pasteItem(item, formatMode, useSaved)
    }
}

pasteIndex(index := 1, formatMode := 0, useSaved := false) {
    clipTab := TabUtils.getTab(useSaved)

    actualIndex := index > 0 ? index : clipTab.Length + index + 1
    if (actualIndex < 1 || actualIndex > clipTab.Length) {
        showMsg("Not exist in " . TabUtils.getName(useSaved))
        return
    }

    item := TabUtils.getItem(clipTab, index)
    TabUtils.pasteItem(item, formatMode, useSaved)
}

; Paste second latest item, Tab, then latest item
pasteWithTab(formatMode := 0, useSaved := false) {
    global tabDelay, tabCount
    clipTab := TabUtils.getTab(useSaved)
    if (!validateMinItems(clipTab, 2, TabUtils.getName(useSaved)))
        return

    firstItem := TabUtils.getItem(clipTab, -2)
    secondItem := TabUtils.getItem(clipTab, -1)

    TabUtils.pasteItem(firstItem, formatMode, useSaved)
    loop tabCount {
        Send("{Tab}")
        Sleep(tabDelay)
    }
    TabUtils.pasteItem(secondItem, formatMode, useSaved)
}

pasteWithBeforeLatest(formatLatest := false) {
    global history
    if (!validateMinItems(history, 2, "history"))
        return

    beforeLatest := history[history.Length - 1].text
    latest := history[history.Length].text
    if (formatLatest)
        latest := formatText(latest)
    paste(beforeLatest . "_" . latest)
}
