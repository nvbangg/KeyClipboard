; === CLIPBOARD MODULE ===

#Include clip_utils.ahk
#Include clip_format.ahk
#Include clip_UI.ahk
global clipHistory := []             ; Stores clipboard history items
global isFormatting := false         ; Flag for formatting in progress
global originalClip := ""            ; Stores original clipboard content
global clipHistoryGuiInstance := 0   ; Reference to clipboard history GUI

; Initialize clipboard history tracking
initClipboard() {
    global clipHistory := []
    global isFormatting := false
    isFormatting := true
    tempClip := ClipboardAll()

    A_Clipboard := "Initializing..."
    ClipWait(0.2)
    A_Clipboard := tempClip
    ClipWait(0.2)
    isFormatting := false

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
    OnClipboardChange(updateClipboard, 1)
}

; Paste content
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

selectAllItems(LV, contentViewer) {
    if (!LV || LV.GetCount() == 0)
        return

    ; Count total items and selected items
    totalItems := LV.GetCount()
    selectedCount := 0
    rowNum := 0

    ; Count selected items
    loop {
        rowNum := LV.GetNext(rowNum)
        if (!rowNum)
            break
        selectedCount++
    }

    ; Toggle selection based on current state
    if (selectedCount == totalItems) {
        ; If all items are selected, deselect all
        LV.Modify(0, "-Select")
        contentViewer.Value := ""  ; Clear the content viewer
    } else {
        ; If not all items are selected, select all
        if (!isListViewFocused())
            LV.Focus()
        LV.Modify(0, "Select")

        ; Update content viewer with all selected items
        updateContent(LV, contentViewer)
    }
}

deleteSelected(LV, clipHistoryGui := 0) {
    global clipHistory
    if (!isListViewFocused()) {
        Send("{Delete}")
        return
    }

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

    updateLV(LV, clipHistoryGui)
}

clearClipboard(clipHistoryGui := 0) {
    global clipHistoryGuiInstance

    ; Close clipboard history window if it's open
    try {
        if (IsObject(clipHistoryGuiInstance) && clipHistoryGuiInstance.HasProp("Hwnd") &&
        WinExist("ahk_id " . clipHistoryGuiInstance.Hwnd)) {
            clipHistoryGuiInstance.Destroy()
            clipHistoryGuiInstance := 0
        }
    } catch {
        ; Handle any errors silently
    }

    ; Also close the GUI passed as parameter if any
    if (clipHistoryGui)
        clipHistoryGui.Destroy()

    global clipHistory
    clipHistory := []
    showNotification("All items have been cleared")
}

; Save edited content back to clipboard history
saveContent(LV, contentViewer, clipHistoryGui) {
    global clipHistory
    selectedItems := getSelected(LV)
    if (selectedItems.Length = 0) {
        updateLV(LV, clipHistoryGui)
        return
    }

    if (selectedItems.Length = 1) {
        clipHistory[selectedItems[1]].text := contentViewer.Value
        ; Note: Original format is not updated when text is edited

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
    } else {
        showNotification("Cannot save changes when multiple items are selected.")
        return
    }

    updateLV(LV, clipHistoryGui)
}

; Merge selected items into clipboard history
saveToClipboard(LV := 0, formatTextEnable := false) {
    global clipHistory
    contentItems := prepareClipItems(LV)

    for _, item in contentItems {
        if (formatTextEnable) {
            formattedText := formatText(item.text)
            clipHistory.Push({
                text: formattedText,
                original: item.original  ; Keep the original formatting
            })
        } else {
            clipHistory.Push({
                text: item.text,
                original: item.original
            })
        }
    }

    updateLV(LV)
}

moveSelectedItem(LV, contentViewer, direction) {
    global clipHistory
    if (!isListViewFocused())
        return
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
